import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standard screen wrapper for GURU.
///
/// Provides a blurred AppBar with optional identity row ([headerUserName] /
/// [headerRoleLabel]), then [title] and optional context [subtitle],
/// consistent action icons and [bottomNavigationBar] slot.
class AppScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? headerUserName;
  final String? headerRoleLabel;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.headerUserName,
    this.headerRoleLabel,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  Widget _appBarTitle() {
    final name = headerUserName?.trim() ?? '';
    final role = headerRoleLabel?.trim() ?? '';
    final hasIdentity = name.isNotEmpty || role.isNotEmpty;
    final sub = subtitle?.trim();

    if (hasIdentity) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (name.isNotEmpty)
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              if (role.isNotEmpty) ...[
                if (name.isNotEmpty) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    role,
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.screenTitle),
          if (sub != null && sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      );
    }

    if (sub != null && sub.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(sub, style: AppTextStyles.label),
          const SizedBox(height: 1),
          Text(title, style: AppTextStyles.screenTitle),
        ],
      );
    }

    return Text(title, style: AppTextStyles.screenTitle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(
        title: _appBarTitle(),
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
