import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';

/// Livocal's chat canvas: a deep ink (dark) or soft white (light) base with
/// two very low-opacity indigo/aqua blooms. Replaces the WhatsApp doodle
/// wallpaper for the default theme while staying quiet enough to read on.
class ChatBackdrop extends StatelessWidget {
  final Widget child;

  const ChatBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [Color(0xFF0A0F1E), Color(0xFF0C1322), Color(0xFF090D18)]
          : const [Color(0xFFF8F9FE), Color(0xFFF3F5FC), Color(0xFFF8F9FE)],
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: baseGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: _Bloom(
              color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.10),
              size: 340,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _Bloom(
              color: AppColors.accent.withValues(alpha: isDark ? 0.14 : 0.08),
              size: 380,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  final Color color;
  final double size;

  const _Bloom({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
