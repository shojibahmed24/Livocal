import 'package:flutter/material.dart';

/// Centralized brand colors for Livocal.
///
/// Livocal's identity is built around a deep "ink" canvas, an electric indigo
/// primary and an aqua accent that represents live AI translation. This is
/// intentionally distinct from the green WhatsApp palette the app started from.
class AppColors {
  // Brand — electric indigo + aqua.
  static const Color primary = Color(0xFF5B6CF9);
  static const Color primaryLight = Color(0xFF8B98FF);
  static const Color primaryDark = Color(0xFF3F4ED8);
  static const Color primaryContainerLight = Color(0xFFE4E7FF);
  static const Color primaryContainerDark = Color(0xFF1B2350);
  static const Color accent = Color(0xFF00D4C8);
  static const Color accentDark = Color(0xFF00A79E);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  // Dark theme palette — deep ink instead of WhatsApp charcoal.
  static const Color darkBackground = Color(0xFF0A0F1E);
  static const Color darkSurface = Color(0xFF121A2B);
  static const Color darkSurfaceContainer = Color(0xFF16203A);
  static const Color darkSurfaceContainerHigh = Color(0xFF1E2A47);
  static const Color darkDivider = Color(0xFF22304D);
  static const Color darkTextPrimary = Color(0xFFE8ECF7);
  static const Color darkTextSecondary = Color(0xFF8A96B2);
  static const Color darkIcon = Color(0xFF8A96B2);
  static const Color darkIncomingBubble = Color(0xFF16203A);
  static const Color darkOutgoingBubble = Color(0xFF3F4ED8);

  // Light theme palette.
  static const Color lightBackground = Color(0xFFF7F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFEEF1FA);
  static const Color lightSurfaceContainerHigh = Color(0xFFE3E8F5);
  static const Color lightDivider = Color(0xFFDDE3F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF5B6785);
  static const Color lightIcon = Color(0xFF5B6785);
  static const Color lightIncomingBubble = Color(0xFFFFFFFF);
  static const Color lightOutgoingBubble = Color(0xFFDDE2FF);

  // Accents & system feedback.
  static const Color error = Color(0xFFFF5C7A);
  static const Color errorLight = Color(0xFFD92D4E);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFFB020);
  static const Color info = Color(0xFF4CC3FF);
  static const Color grey = Color(0xFF8A96B2);
}
