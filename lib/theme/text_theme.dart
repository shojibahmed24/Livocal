import 'package:flutter/material.dart';

/// Livocal type scale.
///
/// Manrope carries headings and numbers (geometric, good at large sizes);
/// Inter carries body copy (neutral, excellent at small sizes). Both ship as
/// variable fonts in `assets/fonts` and are declared in `pubspec.yaml`.
class CustomTextTheme {
  static const String display = 'Manrope';
  static const String body = 'Inter';

  final titleLarge = const TextStyle(
    fontFamily: display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  );

  final titleMedium = const TextStyle(
    fontFamily: display,
    fontSize: 17.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
  );

  final labelLarge = const TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.3,
  );

  final subtitle1 = const TextStyle(
    fontFamily: body,
    fontSize: 15,
    height: 1.4,
  );

  final subtitle2 = const TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 1.4,
  );

  final bodyText1 = const TextStyle(
    fontFamily: body,
    fontSize: 16,
    height: 1.4,
  );

  final bodyText2 = const TextStyle(
    fontFamily: body,
    fontSize: 15,
    height: 1.4,
  );

  final caption = const TextStyle(
    fontFamily: body,
    fontSize: 12,
    height: 1.35,
  );

  final bold = const TextStyle(
    fontFamily: display,
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );
}
