import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

/// Shared shell for incoming / outgoing / active voice calls.
///
/// Brand rules:
/// - deep-ink gradient in dark mode, soft indigo-tinted canvas in light mode
/// - electric indigo primary + aqua accent for the AI translation identity
/// - one information hierarchy: trust badge -> identity -> status -> content
class CallScaffold extends StatelessWidget {
  final String peerName;
  final String peerAvatar;
  final String? peerPhone;
  final String statusText;
  final String? badgeText;
  final IconData? badgeIcon;
  final Animation<double>? pulseAnimation;
  final Widget? middleWidget;
  final Widget bottomWidget;
  final List<Widget>? topActions;
  final Widget? subStatus;

  const CallScaffold({
    super.key,
    required this.peerName,
    required this.peerAvatar,
    this.peerPhone,
    required this.statusText,
    this.badgeText,
    this.badgeIcon,
    this.pulseAnimation,
    this.middleWidget,
    required this.bottomWidget,
    this.topActions,
    this.subStatus,
  });

  static String getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildAvatar(double size, bool isDark) {
    if (peerAvatar.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.55),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 26,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: peerAvatar,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialsAvatar(size, isDark),
            errorWidget: (_, __, ___) => _initialsAvatar(size, isDark),
          ),
        ),
      );
    }
    return _initialsAvatar(size, isDark);
  }

  Widget _initialsAvatar(double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        getInitials(peerName),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _ring(double diameter, Color color, double width) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: width),
      ),
    );
  }

  Widget _buildPulsingAvatar(double size, bool isDark) {
    final avatar = _buildAvatar(size, isDark);
    // Fixed box: the pulse rings used to be painted outside the Stack bounds
    // and overlapped the chips above and the pill below.
    final box = size * 1.66;

    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 1.6,
            height: size * 1.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.16),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          if (pulseAnimation != null)
            AnimatedBuilder(
              animation: pulseAnimation!,
              builder: (context, child) {
                final scale = 1.0 + (pulseAnimation!.value * 0.08);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _ring(
                      size * 1.52 * scale,
                      AppColors.accent.withValues(alpha: 0.20),
                      1.4,
                    ),
                    _ring(
                      size * 1.26 * scale,
                      AppColors.primary.withValues(alpha: 0.30),
                      1.8,
                    ),
                  ],
                );
              },
            ),
          avatar,
        ],
      ),
    );
  }

  Widget _buildBadge(bool isDark) {
    final fg = isDark ? AppColors.accent : AppColors.primaryDark;
    final bg = isDark
        ? AppColors.primary.withValues(alpha: 0.16)
        : AppColors.primaryContainerLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.full,
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon ?? Icons.lock_outline_rounded,
            color: fg,
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              badgeText ?? 'Livocal Secure Call',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final gradientColors = isDark
        ? const [Color(0xFF0A0F1E), Color(0xFF121A2B), Color(0xFF0A0F1E)]
        : const [Color(0xFFF7F8FC), Color(0xFFE9EDFF), Color(0xFFF7F8FC)];

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 650;
              final avatarSize = compact ? 104.0 : 132.0;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
                      children: [
                        Flexible(child: _buildBadge(isDark)),
                        const Spacer(),
                        if (topActions != null) ...topActions!,
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      peerName,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: compact ? 26 : 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (peerPhone != null && peerPhone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      peerPhone!,
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.accent : AppColors.primary)
                          .withValues(alpha: 0.12),
                      borderRadius: AppRadius.full,
                      border: Border.all(
                        color: (isDark ? AppColors.accent : AppColors.primary)
                            .withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDark ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          statusText,
                          style: TextStyle(
                            color:
                                isDark ? AppColors.accent : AppColors.primary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (subStatus != null) ...[
                    const SizedBox(height: 8),
                    subStatus!,
                  ],
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            _buildPulsingAvatar(avatarSize, isDark),
                            if (middleWidget != null) ...[
                              const SizedBox(height: 22),
                              middleWidget!,
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  bottomWidget,
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
