import 'package:flutter/material.dart';

/// Swipe a chat bubble horizontally to reply to it, the way most messengers
/// behave. The bubble follows the finger up to [maxDrag], a reply arrow fades
/// in behind it, and releasing past [threshold] calls [onReply].
///
/// The gesture only claims horizontal drags, so vertical list scrolling and the
/// bubble's own long-press menu keep working.
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool enabled;
  final double threshold;
  final double maxDrag;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
    this.threshold = 56,
    this.maxDrag = 84,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> {
  double _drag = 0;
  bool _dragging = false;
  bool _fired = false;

  void _onStart(DragStartDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _dragging = true;
      _fired = false;
    });
  }

  void _onUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _drag = (_drag + details.delta.dx).clamp(-widget.maxDrag, widget.maxDrag);
    });
  }

  void _onEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    final shouldReply = _drag.abs() >= widget.threshold;
    setState(() {
      _dragging = false;
      _drag = 0;
    });
    if (shouldReply && !_fired) {
      _fired = true;
      widget.onReply();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_drag.abs() / widget.threshold).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onStart,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: () {
        setState(() {
          _dragging = false;
          _drag = 0;
        });
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: _drag >= 0
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Opacity(
                    opacity: progress,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: isDark ? 0.22 : 0.14),
                      ),
                      child: Icon(
                        Icons.reply_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration:
                _dragging ? Duration.zero : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_drag, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
