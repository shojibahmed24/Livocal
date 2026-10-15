import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';

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

  Widget _buildAvatar() {
    if (peerAvatar.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF1F2C34),
        backgroundImage: CachedNetworkImageProvider(peerAvatar),
      );
    }

    final initials = getInitials(peerName);
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00B386),
            Color(0xFF007A5C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3300B386),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPulsingAvatar() {
    final avatar = _buildAvatar();
    if (pulseAnimation == null) return avatar;

    return AnimatedBuilder(
      animation: pulseAnimation!,
      builder: (context, child) {
        final scale = 1.0 + (pulseAnimation!.value * 0.12);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale * 1.2,
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            Transform.scale(
              scale: scale,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
              ),
            ),
            avatar,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0C2A24),
              Color(0xFF0B141A),
              Color(0xFF070D11),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Security / Encryption Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badgeIcon ?? Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeText ?? 'Livocal End-to-End Encrypted',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Peer Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  peerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
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
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                statusText,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildPulsingAvatar(),
              const Spacer(),
              if (middleWidget != null) middleWidget!,
              const SizedBox(height: 16),
              bottomWidget,
            ],
          ),
        ),
      ),
    );
  }
}
