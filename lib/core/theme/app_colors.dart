import 'package:flutter/material.dart';

/// Brand tokens from `mobile_app_ui.html` (forest + ochre).
abstract final class AppColors {
  static const Color forest = Color(0xFF1E3A2B);
  static const Color forestDark = Color(0xFF132A1E);
  static const Color sage = Color(0xFF7C9473);
  static const Color sageLight = Color(0xFFE7ECE0);
  static const Color paper = Color(0xFFF3F5EF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ochre = Color(0xFFC08A34);
  static const Color ochreDark = Color(0xFF96691F);
  static const Color ink = Color(0xFF1B231C);
  static const Color inkMuted = Color(0xFF5C6B5C);
  static const Color line = Color(0xFFDDE3D6);
  static const Color danger = Color(0xFFB4482F);

  // Aliases used across the existing codebase.
  static const Color primary = forest;
  static const Color primaryDark = forestDark;
  static const Color primaryLight = sage;
  static const Color secondary = forestDark;
  static const Color accent = ochre;

  static const Color background = paper;
  static const Color surface = card;
  static const Color surfaceMuted = sageLight;

  static const Color textPrimary = ink;
  static const Color textSecondary = inkMuted;
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFF9AA8A1);

  static const Color border = line;
  static const Color divider = line;

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = ochreDark;
  static const Color error = danger;
  static const Color info = Color(0xFF0277BD);

  static const Color overlay = Color(0x66000000);

  /// Accent thumb colors for list/carousel placeholders.
  static const List<Color> thumbPalette = [
    Color(0xFFC7A15A),
    Color(0xFFA7716A),
    Color(0xFF8FA1C4),
    Color(0xFF9FB48B),
    Color(0xFFC79A6A),
    Color(0xFFB08585),
    Color(0xFF7C9473),
    Color(0xFFA98FB0),
  ];
}
