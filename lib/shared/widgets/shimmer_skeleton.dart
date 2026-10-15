import 'package:flutter/material.dart';
import 'package:livocal/theme/app_tokens.dart';

/// Lightweight, 60fps pulsing shimmer container respecting light and dark themes.
/// Requires zero third-party dependencies and runs completely on the Flutter engine.
class AppShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final ShapeBorder shape;
  final BorderRadius? borderRadius;
  final Widget? child;

  const AppShimmer({
    super.key,
    this.width,
    this.height,
    this.shape = const RoundedRectangleBorder(),
    this.borderRadius,
    this.child,
  });

  const AppShimmer.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        shape = const CircleBorder(),
        borderRadius = null,
        child = null;

  const AppShimmer.rectangular({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  })  : shape = const RoundedRectangleBorder(),
        child = null;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF1E2A30)
        : const Color(0xFFE5E7EB);
    final highlightColor = isDark
        ? const Color(0xFF2A3942)
        : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = Color.lerp(baseColor, highlightColor, _animation.value);

        if (widget.shape is CircleBorder) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: widget.child,
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppRadius.sm,
            color: color,
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer skeleton for the Home Chat List while messages load from Isar/Firestore.
class ChatListShimmerSkeleton extends StatelessWidget {
  const ChatListShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar circle
              AppShimmer.circular(size: 52),
              SizedBox(width: AppSpacing.md),
              // Name and preview lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmer.rectangular(width: 140, height: 14),
                    SizedBox(height: AppSpacing.xs + 2),
                    AppShimmer.rectangular(width: 210, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              // Time and badge skeleton
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppShimmer.rectangular(width: 44, height: 11),
                  SizedBox(height: AppSpacing.xs + 2),
                  AppShimmer.circular(size: 16),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shimmer skeleton for the Chat Screen message bubbles while message stream connects.
class ChatBubbleShimmerSkeleton extends StatelessWidget {
  const ChatBubbleShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      children: [
        // Security header skeleton
        Center(
          child: AppShimmer(
            width: screenWidth * 0.72,
            height: 38,
            borderRadius: AppRadius.md,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Incoming bubble 1
        Align(
          alignment: Alignment.centerLeft,
          child: AppShimmer(
            width: screenWidth * 0.58,
            height: 52,
            borderRadius: const BorderRadius.only(
              topLeft: AppRadius.rXs,
              topRight: AppRadius.rMd,
              bottomLeft: AppRadius.rMd,
              bottomRight: AppRadius.rMd,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Outgoing bubble 1
        Align(
          alignment: Alignment.centerRight,
          child: AppShimmer(
            width: screenWidth * 0.65,
            height: 64,
            borderRadius: const BorderRadius.only(
              topLeft: AppRadius.rMd,
              topRight: AppRadius.rXs,
              bottomLeft: AppRadius.rMd,
              bottomRight: AppRadius.rMd,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Incoming bubble 2 (shorter)
        Align(
          alignment: Alignment.centerLeft,
          child: AppShimmer(
            width: screenWidth * 0.42,
            height: 44,
            borderRadius: const BorderRadius.only(
              topLeft: AppRadius.rXs,
              topRight: AppRadius.rMd,
              bottomLeft: AppRadius.rMd,
              bottomRight: AppRadius.rMd,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Outgoing bubble 2
        Align(
          alignment: Alignment.centerRight,
          child: AppShimmer(
            width: screenWidth * 0.50,
            height: 48,
            borderRadius: const BorderRadius.only(
              topLeft: AppRadius.rMd,
              topRight: AppRadius.rXs,
              bottomLeft: AppRadius.rMd,
              bottomRight: AppRadius.rMd,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Incoming bubble 3 (media-sized)
        Align(
          alignment: Alignment.centerLeft,
          child: AppShimmer(
            width: screenWidth * 0.68,
            height: 120,
            borderRadius: const BorderRadius.only(
              topLeft: AppRadius.rXs,
              topRight: AppRadius.rMd,
              bottomLeft: AppRadius.rMd,
              bottomRight: AppRadius.rMd,
            ),
          ),
        ),
      ],
    );
  }
}
