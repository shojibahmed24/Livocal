import 'package:flutter/material.dart';

/// Centralized Brand Colors for Livocal.
/// Single source of truth for all brand and theme colors.
class AppColors {
  // Brand Emerald Green - Livocal's unique identity (distinct from WhatsApp teal)
  static const Color primary = Color(0xFF00B386);
  static const Color primaryLight = Color(0xFF26C49B);
  static const Color primaryDark = Color(0xFF008F6B);
  static const Color primaryContainerLight = Color(0xFFD6F5EC);
  static const Color primaryContainerDark = Color(0xFF004D38);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF111B21);
  static const Color darkSurface = Color(0xFF1F2C34);
  static const Color darkSurfaceContainer = Color(0xFF202C33);
  static const Color darkSurfaceContainerHigh = Color(0xFF2A3942);
  static const Color darkDivider = Color(0xFF252D32);
  static const Color darkTextPrimary = Color(0xFFE9EDEF);
  static const Color darkTextSecondary = Color(0xFF8696A0);
  static const Color darkIcon = Color(0xFF8594A3);
  static const Color darkIncomingBubble = Color(0xFF1F2C33);
  static const Color darkOutgoingBubble = Color(0xFF005C4B);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F8FA);
  static const Color lightSurfaceContainer = Color(0xFFF0F2F5);
  static const Color lightSurfaceContainerHigh = Color(0xFFE9EDEF);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF111B21);
  static const Color lightTextSecondary = Color(0xFF667781);
  static const Color lightIcon = Color(0xFF54656F);
  static const Color lightIncomingBubble = Color(0xFFFFFFFF);
  static const Color lightOutgoingBubble = Color(0xFFD9FDD3);

  // Accents & System Feedback
  static const Color error = Color(0xFFF15C6D);
  static const Color errorLight = Color(0xFFD32F2F);
  static const Color success = Color(0xFF00B386);
  static const Color warning = Color(0xFFFFD279);
  static const Color info = Color(0xFF53BDEB);
  static const Color grey = Color(0xFF8696A0);
}
