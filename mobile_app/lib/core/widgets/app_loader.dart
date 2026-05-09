import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered loading indicator in GURU accent color.
///
/// Use inside [Scaffold.body] or inside a [SliverFillRemaining]
/// for full-screen loading states.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.accent,
        strokeWidth: 2.5,
      ),
    );
  }
}
