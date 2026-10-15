import 'package:flutter/material.dart';

/// Centralized Design Tokens for Livocal.
/// Provides consistent radius, spacing, and elevation scales across the entire application.
class AppRadius {
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  static const double small = radiusSm;
  static const double medium = radiusMd;
  static const double large = radiusLg;
  static const double extraLarge = radiusXl;

  static const BorderRadius xs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius full = BorderRadius.all(Radius.circular(radiusFull));

  static const Radius rXs = Radius.circular(radiusXs);
  static const Radius rSm = Radius.circular(radiusSm);
  static const Radius rMd = Radius.circular(radiusMd);
  static const Radius rLg = Radius.circular(radiusLg);
  static const Radius rXl = Radius.circular(radiusXl);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static const double extraSmall = xs;
  static const double small = sm;
  static const double medium = md;
  static const double large = lg;
  static const double extraLarge = xl;

  // Convenient vertical spacing widgets
  static const verticalXs = SizedBox(height: xs);
  static const verticalSm = SizedBox(height: sm);
  static const verticalMd = SizedBox(height: md);
  static const verticalLg = SizedBox(height: lg);
  static const verticalXl = SizedBox(height: xl);
  static const verticalXxl = SizedBox(height: xxl);

  // Convenient horizontal spacing widgets
  static const horizontalXs = SizedBox(width: xs);
  static const horizontalSm = SizedBox(width: sm);
  static const horizontalMd = SizedBox(width: md);
  static const horizontalLg = SizedBox(width: lg);
  static const horizontalXl = SizedBox(width: xl);
  static const horizontalXxl = SizedBox(width: xxl);

  // Consistent Insets
  static const EdgeInsets insetAllSm = EdgeInsets.all(sm);
  static const EdgeInsets insetAllMd = EdgeInsets.all(md);
  static const EdgeInsets insetAllLg = EdgeInsets.all(lg);
  static const EdgeInsets insetAllXl = EdgeInsets.all(xl);

  static const EdgeInsets insetHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets insetHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets insetHLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets insetHXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets insetVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets insetVMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets insetVLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets insetVXl = EdgeInsets.symmetric(vertical: xl);
}

class AppElevation {
  static const double flat = 0.0;
  static const double low = 1.0;
  static const double medium = 3.0;
  static const double high = 6.0;
}
