import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography: Fraunces for headings, Work Sans for body/UI.
abstract final class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.fraunces(
        fontSize: 34,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.forestDark,
      );

  static TextStyle get displayMedium => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: AppColors.forestDark,
      );

  static TextStyle get headlineLarge => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: AppColors.forestDark,
      );

  static TextStyle get headlineMedium => GoogleFonts.fraunces(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.forestDark,
      );

  static TextStyle get headlineSmall => GoogleFonts.fraunces(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.forestDark,
      );

  static TextStyle get titleLarge => GoogleFonts.fraunces(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.forestDark,
      );

  static TextStyle get titleMedium => GoogleFonts.workSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.forestDark,
      );

  static TextStyle get titleSmall => GoogleFonts.workSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.forestDark,
      );

  static TextStyle get bodyLarge => GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.inkMuted,
      );

  static TextStyle get bodyMedium => GoogleFonts.workSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.65,
        color: AppColors.inkMuted,
      );

  static TextStyle get bodySmall => GoogleFonts.workSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: AppColors.inkMuted,
      );

  static TextStyle get labelLarge => GoogleFonts.workSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.ink,
      );

  static TextStyle get labelMedium => GoogleFonts.workSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.forestDark,
      );

  static TextStyle get labelSmall => GoogleFonts.workSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.inkMuted,
      );

  static TextStyle get sectionTitle => GoogleFonts.fraunces(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.forestDark,
      );

  static TextStyle get eyebrow => GoogleFonts.workSans(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.3,
        color: AppColors.ochreDark,
      );
}
