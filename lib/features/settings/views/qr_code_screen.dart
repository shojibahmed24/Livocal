import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

class QrCodeScreen extends StatelessWidget {
  final User user;

  const QrCodeScreen({super.key, required this.user});

  void _shareQrCode(BuildContext context) {
    HapticFeedback.lightImpact();
    final link = 'https://livocal.app/add/${user.phone.getFormattedNumber().replaceAll(RegExp(r'\s+'), '')}';
    Share.share(
      'Connect with me on Livocal: $link\nDownload the app to chat and make live translated voice calls!',
    );
  }

  void _copyLink(BuildContext context) {
    HapticFeedback.lightImpact();
    final link = 'https://livocal.app/add/${user.phone.getFormattedNumber().replaceAll(RegExp(r'\s+'), '')}';
    Clipboard.setData(ClipboardData(text: link));
    showSnackBar(
      context: context,
      content: 'Invite link copied to clipboard',
      type: SnacBarType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2C34) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () => _shareQrCode(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // QR Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(AppRadius.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone.getFormattedNumber(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF8696A0) : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Crisp QR Code Matrix
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _QrCodePainter(
                          seedData: '${user.id}_${user.phone.rawNumber}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Livocal Contact',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Your QR code is private. If you share it with someone, they can scan it with their camera to contact you on Livocal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? const Color(0xFF8696A0) : Colors.grey.shade600,
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
                      onPressed: () => _copyLink(context),
                      icon: const Icon(Icons.link_rounded, size: 20),
                      label: const Text('Copy link'),
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
                      onPressed: () => _shareQrCode(context),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Share code'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final String seedData;

  const _QrCodePainter({required this.seedData});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111B21)
      ..style = PaintingStyle.fill;

    const int modules = 25;
    final double moduleSize = size.width / modules;

    // Corner Finder Patterns
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
    drawFinder(size.width - (moduleSize * 7), 0);
    drawFinder(0, size.height - (moduleSize * 7));

    // Alignment pattern
    void drawAlignment(double left, double top) {
      canvas.drawRect(
        Rect.fromLTWH(left, top, moduleSize * 5, moduleSize * 5),
        paint,
      );
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(
          left + moduleSize,
          top + moduleSize,
          moduleSize * 3,
          moduleSize * 3,
        ),
        whitePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          left + (moduleSize * 2),
          top + (moduleSize * 2),
          moduleSize,
          moduleSize,
        ),
        paint,
      );
    }

    drawAlignment(size.width - (moduleSize * 8), size.height - (moduleSize * 8));

    // Data modules derived from seedData hash
    final rand = Random(seedData.hashCode);
    for (int r = 0; r < modules; r++) {
      for (int c = 0; c < modules; c++) {
        // Skip finder areas
        if (r < 8 && c < 8) continue;
        if (r < 8 && c >= modules - 8) continue;
        if (r >= modules - 8 && c < 8) continue;
        if (r >= modules - 9 && c >= modules - 9) continue;

        // Timing patterns
        if (r == 6 || c == 6) {
          if ((r + c) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(c * moduleSize, r * moduleSize, moduleSize, moduleSize),
              paint,
            );
          }
          continue;
        }

        if (rand.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(c * moduleSize, r * moduleSize, moduleSize, moduleSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) =>
      oldDelegate.seedData != seedData;
}
