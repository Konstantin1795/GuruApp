import 'package:flutter/material.dart';

/// Single source of truth for all colors in the GURU app.
/// Accent is teal/cyan — the visual identity of the product.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color accent       = Color(0xFF00D6C9);
  static const Color accentDim    = Color(0x2900D6C9); // ~16 %
  static const Color accentBorder = Color(0x4000D6C9); // ~25 %

  // ── Background / Surface ───────────────────────────────────────────────────
  static const Color bg      = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF0F141B);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // 60 %
  static const Color textDisabled  = Color(0x40FFFFFF); // 25 %
  static const Color textHint      = Color(0x66FFFFFF); // 40 %

  // ── Border ─────────────────────────────────────────────────────────────────
  static const Color border      = Color(0x1AFFFFFF); // 10 %
  static const Color borderFocus = accent;

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color error   = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFFB347);

  // ── Card gradient stops ────────────────────────────────────────────────────
  static Color cardGradientStart = Colors.white.withValues(alpha: 0.09);
  static Color cardGradientEnd   = accent.withValues(alpha: 0.05);
}
