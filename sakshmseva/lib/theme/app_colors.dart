import 'package:flutter/material.dart';

/// SakshmSeva Gujarat – Color Tokens
/// Government-grade palette: Deep Green + Beige + Muted Gold
abstract class AppColors {
  // ── Primary ──────────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF2E7D32);
  static const Color primaryGreenDark = Color(0xFF145214);
  static const Color primaryGreenSurface = Color(0xFFE8F5E9);

  // ── Background ───────────────────────────────────────────────────────
  static const Color backgroundBeige = Color(0xFFF5F0E8);
  static const Color backgroundWhite = Color(0xFFFAF9F6);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // ── Accent ───────────────────────────────────────────────────────────
  static const Color accentGold = Color(0xFFBFA14A);
  static const Color accentGoldLight = Color(0xFFD4B96A);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status ───────────────────────────────────────────────────────────
  static const Color statusOpen = Color(0xFF2E7D32);
  static const Color statusClosingSoon = Color(0xFFE65100);
  static const Color statusOngoing = Color(0xFF1565C0);
  static const Color statusClosed = Color(0xFF757575);

  // ── Error / Success ──────────────────────────────────────────────────
  static const Color error = Color(0xFFC62828);
  static const Color success = Color(0xFF1B5E20);
  static const Color warning = Color(0xFFF57F17);

  // ── Divider / Border ─────────────────────────────────────────────────
  static const Color divider = Color(0xFFE0D8C8);
  static const Color border = Color(0xFFD0C9B8);

  // ── Category Colors ──────────────────────────────────────────────────
  static const Color catAgriculture = Color(0xFF33691E);
  static const Color catEducation = Color(0xFF1565C0);
  static const Color catHealthcare = Color(0xFFC62828);
  static const Color catHousing = Color(0xFF6A1B9A);
  static const Color catWomen = Color(0xFFAD1457);
  static const Color catEnvironment = Color(0xFF00695C);
}
