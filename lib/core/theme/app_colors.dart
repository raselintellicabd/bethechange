import 'package:flutter/material.dart';

/// Brand tokens from Be-The-Change-Health web (`statics/css/style.css` `:root`).
abstract final class AppColors {
  // Canonical Django / web tokens.
  static const Color brandPrimary = Color(0xFF308CA0);
  static const Color brandPrimaryDark = Color(0xFF267A8C);
  static const Color brandNavy = Color(0xFF003048);
  static const Color brandAccent = Color(0xFFA2C08A);
  static const Color brandText = Color(0xFF434549);
  static const Color brandTextLight = Color(0xFF666666);
  static const Color brandBg = Color(0xFFFFFFFF);
  static const Color brandBgLight = Color(0xFFF9F9FB);
  static const Color brandBgGray = Color(0xFFF2F3F5);

  // Supporting tokens from static-fixes / admin CSS.
  static const Color brandBorder = Color(0xFFE4E9EC);
  static const Color brandMutedSurface = Color(0xFFE8F4F6);
  static const Color brandDanger = Color(0xFFDD464C);

  // Names used across the Flutter UI (mapped to Django palette).
  static const Color forest = brandNavy;
  static const Color forestDark = brandNavy;
  static const Color sage = brandAccent;
  static const Color sageLight = brandMutedSurface;
  static const Color paper = brandBgLight;
  static const Color card = brandBg;
  static const Color ochre = brandPrimary;
  static const Color ochreDark = brandPrimaryDark;
  static const Color ink = brandText;
  static const Color inkMuted = brandTextLight;
  static const Color line = brandBorder;
  static const Color danger = brandDanger;

  // Aliases used across the existing codebase.
  static const Color primary = brandPrimary;
  static const Color primaryDark = brandPrimaryDark;
  static const Color primaryLight = brandAccent;
  static const Color secondary = brandNavy;
  static const Color accent = brandAccent;

  static const Color background = paper;
  static const Color surface = card;
  static const Color surfaceMuted = sageLight;

  static const Color textPrimary = ink;
  static const Color textSecondary = inkMuted;
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFF959EA9);

  static const Color border = line;
  static const Color divider = line;

  static const Color success = Color(0xFF65BC7B);
  static const Color warning = brandPrimaryDark;
  static const Color error = danger;
  static const Color info = brandPrimary;

  static const Color overlay = Color(0x66000000);

  /// Accent thumb colors aligned to the Django teal / sage / navy family.
  static const List<Color> thumbPalette = [
    Color(0xFF308CA0),
    Color(0xFFA2C08A),
    Color(0xFF65BC7B),
    Color(0xFF267A8C),
    Color(0xFF003048),
    Color(0xFF1A6B7C),
    Color(0xFFC5DDE3),
    Color(0xFF7BA8B5),
  ];
}
