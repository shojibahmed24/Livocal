import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livocal/theme/app_colors.dart';

class SwipeToAnswer extends StatefulWidget {
  final VoidCallback onAnswer;
  final VoidCallback onDecline;
  final String label;

  const SwipeToAnswer({
    super.key,
    required this.onAnswer,
    required this.onDecline,
    this.label = 'Swipe to answer',
  });

  @override
  State<SwipeToAnswer> createState() => _SwipeToAnswerState();
}

class _SwipeToAnswerState extends State<SwipeToAnswer> {
  double _dragPosition = 0.0;
  bool _confirmed = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_confirmed) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_confirmed) return;
    if (_dragPosition >= maxDrag * 0.72) {
      setState(() {
        _dragPosition = maxDrag;
        _confirmed = true;
      });
      HapticFeedback.heavyImpact();
      widget.onAnswer();
    } else {
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double sliderHeight = 60.0;
    const double thumbSize = 52.0;
    const double thumbPadding = 4.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decline Button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onDecline();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66E53935),
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Decline',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Swipe to Answer Track
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxDrag = constraints.maxWidth - thumbSize - (thumbPadding * 2);

                return Container(
                  height: sliderHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18252D),
                    borderRadius: BorderRadius.circular(sliderHeight / 2),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Track shimmer text
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 24),
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: (1.0 - (_dragPosition / maxDrag).clamp(0.0, 1.0)) * 0.85,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppColors.primary.withValues(
                                alpha: (1.0 - (_dragPosition / maxDrag).clamp(0.0, 1.0)) * 0.85,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Draggable Thumb
                      Positioned(
                        left: thumbPadding + _dragPosition,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) =>
                              _onHorizontalDragUpdate(details, maxDrag),
                          onHorizontalDragEnd: (details) =>
                              _onHorizontalDragEnd(details, maxDrag),
                          child: Container(
                            width: thumbSize,
                            height: thumbSize,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
