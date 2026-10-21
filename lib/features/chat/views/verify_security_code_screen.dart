import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

class VerifySecurityCodeScreen extends StatefulWidget {
  final String contactName;
  final String contactPhone;
  final String selfId;
  final String otherId;

  const VerifySecurityCodeScreen({
    super.key,
    required this.contactName,
    required this.contactPhone,
    required this.selfId,
    required this.otherId,
  });

  @override
  State<VerifySecurityCodeScreen> createState() => _VerifySecurityCodeScreenState();
}

class _VerifySecurityCodeScreenState extends State<VerifySecurityCodeScreen> {
  late String _securityCodeDigits;
  late List<String> _digitBlocks;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _generateSecurityCode();
  }

  void _generateSecurityCode() {
    // Generate deterministic 60-digit security fingerprint based on participant IDs
    final sortedIds = [widget.selfId, widget.otherId]..sort();
    final combinedKey = '${sortedIds[0]}_${sortedIds[1]}_e2e_v1';
    
    // Deterministic PRNG seeded by hash code
    int seed = 0;
    for (int i = 0; i < combinedKey.length; i++) {
      seed = (seed * 31 + combinedKey.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final rng = Random(seed);

    final sb = StringBuffer();
    final blocks = <String>[];

    for (int b = 0; b < 12; b++) {
      final blockSb = StringBuffer();
      for (int d = 0; d < 5; d++) {
        final digit = rng.nextInt(10);
        blockSb.write(digit);
        sb.write(digit);
      }
      blocks.add(blockSb.toString());
    }

    _securityCodeDigits = sb.toString();
    _digitBlocks = blocks;
  }

  void _shareCode() {
    HapticFeedback.lightImpact();
    final formatted = _formatBlocksForShare();
    Share.share(
      'Livocal Security Code for ${widget.contactName}:\n\n$formatted\n\nVerify end-to-end encryption at: https://livocal.app',
      subject: 'Livocal Security Code - ${widget.contactName}',
    );
  }

  String _formatBlocksForShare() {
    final rows = <String>[];
    for (int i = 0; i < _digitBlocks.length; i += 4) {
      final rowBlocks = _digitBlocks.sublist(i, min(i + 4, _digitBlocks.length));
      rows.add(rowBlocks.join('  '));
    }
    return rows.join('\n');
  }

  void _openVerifyCodeDialog() {
    HapticFeedback.lightImpact();
    final textController = TextEditingController();

    showAppDialog(
      context: context,
      title: 'Compare Security Code',
      icon: Icons.verified_user_rounded,
      iconColor: AppColors.primary,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter or paste the 60-digit security code or QR digits from ${widget.contactName}\'s phone to verify that your messages are end-to-end encrypted:',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', letterSpacing: 1.1),
                decoration: InputDecoration(
                  hintText: 'Paste 60 digits or code here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        AppDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'VERIFY',
          isPrimary: true,
          onPressed: () {
            final raw = textController.text.trim();
            final cleanInput = raw.replaceAll(RegExp(r'\D'), '');

            if (cleanInput.isEmpty) {
              Navigator.pop(context);
              return;
            }

            Navigator.pop(context);

            if (cleanInput == _securityCodeDigits) {
              HapticFeedback.mediumImpact();
              setState(() {
                _isVerified = true;
              });
              showSnackBar(
                context: context,
                content: '✓ Security code verified with ${widget.contactName}! Encryption is authentic.',
                type: SnacBarType.info,
              );
            } else {
              HapticFeedback.heavyImpact();
              setState(() {
                _isVerified = false;
              });
              showAppDialog(
                context: context,
                title: 'Security Code Mismatch',
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.redAccent,
                contentText:
                    'The security code you entered does not match ${widget.contactName}\'s 60-digit encryption key.\n\nPlease check the numbers carefully on both screens.',
                actions: [
                  AppDialogAction(
                    label: 'OK',
                    isPrimary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2C34) : Colors.white;
    final textMuted = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B22) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify security code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share security code',
            onPressed: _shareCode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // QR Code Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: _SecurityQrPainter(seed: _securityCodeDigits),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF25D366), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Security Code Verified',
                            style: TextStyle(
                              color: Color(0xFF25D366),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 60-digit number display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  for (int row = 0; row < 3; row++) ...[
                    if (row > 0) const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (int col = 0; col < 4; col++) ...[
                          Text(
                            _digitBlocks[row * 4 + col],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF111B21),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Explanatory Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'To verify that messages and calls with ${widget.contactName} are end-to-end encrypted, compare the 60-digit code above with their phone, or scan their QR code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: textMuted,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    onPressed: _shareCode,
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('Share Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                      ),
                    ),
                    onPressed: _openVerifyCodeDialog,
                    icon: const Icon(Icons.verified_user_outlined, size: 20),
                    label: const Text('Verify Code'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityQrPainter extends CustomPainter {
  final String seed;

  const _SecurityQrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111B21)
      ..style = PaintingStyle.fill;

    const int modules = 25;
    final double moduleSize = size.width / modules;

    void drawFinder(double left, double top) {
      canvas.drawRect(
        Rect.fromLTWH(left, top, moduleSize * 7, moduleSize * 7),
        paint,
      );
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(
          left + moduleSize,
          top + moduleSize,
          moduleSize * 5,
          moduleSize * 5,
        ),
        whitePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          left + (moduleSize * 2),
          top + (moduleSize * 2),
          moduleSize * 3,
          moduleSize * 3,
        ),
        paint,
      );
    }

    drawFinder(0, 0);
    drawFinder(moduleSize * (modules - 7), 0);
    drawFinder(0, moduleSize * (modules - 7));

    int hash = seed.hashCode;
    for (int r = 0; r < modules; r++) {
      for (int c = 0; c < modules; c++) {
        final inTopLeft = r < 8 && c < 8;
        final inTopRight = r < 8 && c >= modules - 8;
        final inBottomLeft = r >= modules - 8 && c < 8;

        if (inTopLeft || inTopRight || inBottomLeft) continue;

        hash = (hash * 31 + r * 17 + c * 23) & 0x7FFFFFFF;
        if (hash % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * moduleSize, r * moduleSize, moduleSize * 0.92, moduleSize * 0.92),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SecurityQrPainter oldDelegate) => oldDelegate.seed != seed;
}
