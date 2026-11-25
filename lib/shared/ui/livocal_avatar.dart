import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:livocal/shared/utils/text_safe.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/text_theme.dart';

enum AvatarRing { none, brand, online, status }

/// One avatar for the whole app: initials fallback, deterministic colour,
/// optional brand/online/status ring, cached network image.
class LivocalAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final AvatarRing ring;
  final bool online;

  const LivocalAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.ring = AvatarRing.none,
    this.online = false,
  });

  static const _palette = [
    AppColors.primary,
    Color(0xFF1E88E5),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
    Color(0xFF00897B),
    Color(0xFF3949AB),
    Color(0xFF43A047),
  ];

  String get _initials => initialsOf(name);

  Color get _fallbackColor => _palette[name.hashCode.abs() % _palette.length];

  Widget get _core {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: (size * 2.5).round(),
                placeholder: (_, __) => Container(color: _fallbackColor),
                errorWidget: (_, __, ___) => _initialsCircle,
              )
            : _initialsCircle,
      ),
    );
  }

  Widget get _initialsCircle => Container(
        color: _fallbackColor,
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: TextStyle(
            fontFamily: CustomTextTheme.display,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (ring == AvatarRing.none && !online) return _core;

    final ringGradient = switch (ring) {
      AvatarRing.brand => AppColors.brandGradient,
      AvatarRing.status => const LinearGradient(
          colors: [AppColors.accent, AppColors.primary],
        ),
      _ => null,
    };

    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ringGradient,
              border: ringGradient == null
                  ? Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : AppColors.lightDivider,
                      width: 1.5,
                    )
                  : null,
            ),
            child: _core,
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
