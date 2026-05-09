import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standard screen wrapper for GURU.
///
/// Provides a blurred AppBar with [title] / optional [subtitle],
/// consistent action icons and [bottomNavigationBar] slot.
class AppScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(
        title: subtitle == null
            ? Text(title, style: AppTextStyles.screenTitle)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle!,
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 1),
                  Text(title, style: AppTextStyles.screenTitle),
                ],
              ),
        actions: actions,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              color: AppColors.bg.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}
