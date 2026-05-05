import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// SakshmSeva Gujarat – Typography System
abstract class AppTextStyles {
  static TextStyle get _base => GoogleFonts.inter(
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      );

  // ── Display ──────────────────────────────────────────────────────────
  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  // ── Headline ─────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headlineMedium => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headlineSmall => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  // ── Title ─────────────────────────────────────────────────────────────
  static TextStyle get titleLarge => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      );

  // ── Body ──────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── Label ────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      );

  // ── Special ──────────────────────────────────────────────────────────
  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  static TextStyle get schemeBenefit => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryGreen,
      );

  static TextStyle get categoryTag => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get splashTitle => GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
        letterSpacing: 0.5,
      );
}
