import 'package:flutter/material.dart';
import 'package:livocal/features/status/models/status_model.dart';
import 'package:livocal/features/status/services/status_service.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/snackbars.dart';

class TextStatusComposerScreen extends StatefulWidget {
  final User user;
  const TextStatusComposerScreen({super.key, required this.user});

  @override
  State<TextStatusComposerScreen> createState() =>
      _TextStatusComposerScreenState();
}

class _TextStatusComposerScreenState extends State<TextStatusComposerScreen> {
  final TextEditingController _textController = TextEditingController();
  int _colorIndex = 0;
  bool _isPosting = false;

  final List<int> _backgroundColors = [
    0xFF00B386, // Livocal Brand Emerald Green
    0xFF6B46C1, // Royal Purple
    0xFFD53F8C, // Vibrant Pink
    0xFFDD6B20, // Vivid Orange
    0xFF3182CE, // Ocean Blue
    0xFF54656F, // Dark Slate
    0xFFE53E3E, // Crimson
  ];

  void _cycleColor() {
    setState(() {
      _colorIndex = (_colorIndex + 1) % _backgroundColors.length;
    });
  }

  Future<void> _submitStatus() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final status = StatusModel(
        id: 'status_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.user.id,
        userName: widget.user.name,
        userAvatar: widget.user.avatarUrl,
        text: text,
        colorValue: _backgroundColors[_colorIndex],
        timestamp: DateTime.now(),
      );

      await StatusService.postStatus(status);

      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Status posted successfully',
          type: SnacBarType.info,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('TextStatusComposer post status error: $e');
      if (mounted) {
        setState(() => _isPosting = false);
        showSnackBar(
          context: context,
          content: 'Failed to post status: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = Color(_backgroundColors[_colorIndex]);

    return Scaffold(
      backgroundColor: currentColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Top action bar
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.palette_outlined,
                            color: Colors.white, size: 28),
                        onPressed: _cycleColor,
                        tooltip: 'Change color',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Center text field
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Type a status',
                    hintStyle: TextStyle(
                      color: Colors.white60,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Bottom send button
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _isPosting ? null : _submitStatus,
                child: _isPosting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(Icons.send, color: currentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
