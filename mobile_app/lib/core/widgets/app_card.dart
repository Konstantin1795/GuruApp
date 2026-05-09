import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Glass-morphism card — the primary surface component of GURU.
///
/// Use [onTap] to make the card tappable.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Override default border radius (default = [AppRadii.xxl]).
  final double? radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppRadii.xxl;

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: AppColors.border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardGradientStart,
                AppColors.cardGradientEnd,
              ],
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return glass;

    return InkWell(
      borderRadius: BorderRadius.circular(r),
      onTap: onTap,
      child: glass,
    );
  }
}
