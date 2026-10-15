import 'package:flutter/material.dart';
import 'package:livocal/theme/theme.dart';

class LabelledButton extends StatelessWidget {
  const LabelledButton({
    super.key,
    this.radius = 28.0,
    this.backgroundColor = Colors.white,
    required this.onTap,
    required this.label,
    required this.child,
  });

  final double radius;
  final Color? backgroundColor;
  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor ?? Colors.black,
              child: child,
            ),
            const SizedBox(height: 8.0),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).custom.colorTheme.greyColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
