import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

double _appBarToolbarHeight({
  required bool hasIdentity,
  required bool hasSubtitle,
}) {
  // Высота только под реальный текст + небольшой отступ; большое значение даёт «дыру» под подзаголовком
  // из‑за вертикального центрирования title в AppBar.
  if (!hasIdentity) {
    if (hasSubtitle) return 76;
    return kToolbarHeight;
  }
  if (hasSubtitle) return 130;
  return 102;
}

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
    final subStyle = AppTextStyles.label.copyWith(
      color: AppColors.textSecondary,
      fontSize: 13,
      height: 1.25,
    );

    if (hasIdentity) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (name.isNotEmpty)
                Text(
                  name,
                  style: AppTextStyles.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (role.isNotEmpty) ...[
                if (name.isNotEmpty) const SizedBox(height: 2),
                Text(
                  role,
                  style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Text(title, style: AppTextStyles.screenTitle),
              if (sub != null && sub.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: subStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (sub != null && sub.isNotEmpty) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sub,
                style: subStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              const SizedBox(height: 2),
              Text(title, style: AppTextStyles.screenTitle),
            ],
          ),
        ),
      );
    }

    return Text(title, style: AppTextStyles.screenTitle);
  }

  double _toolbarHeight() {
    final name = headerUserName?.trim() ?? '';
    final role = headerRoleLabel?.trim() ?? '';
    final hasIdentity = name.isNotEmpty || role.isNotEmpty;
    final sub = subtitle?.trim();
    return _appBarToolbarHeight(
      hasIdentity: hasIdentity,
      hasSubtitle: sub != null && sub.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // При edge-to-edge padding.top может быть 0, а viewPadding — нет: контент уезжает под статус-бар / вырез.
    final extraTop = math.max(0.0, mq.viewPadding.top - mq.padding.top);
    final extraLeft = math.max(0.0, mq.viewPadding.left - mq.padding.left);
    final extraRight = math.max(0.0, mq.viewPadding.right - mq.padding.right);

    Widget content = Scaffold(
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(
        toolbarHeight: _toolbarHeight(),
        title: _appBarTitle(),
        actions: actions,
        // Явно обрезаем размытие границами AppBar — без этого blur может визуально «тянуться»
        // к статус-бару на части устройств.
        clipBehavior: Clip.hardEdge,
        flexibleSpace: ClipRect(
          clipBehavior: Clip.hardEdge,
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

    if (extraTop > 0 || extraLeft > 0 || extraRight > 0) {
      content = Padding(
        padding: EdgeInsets.only(
          top: extraTop,
          left: extraLeft,
          right: extraRight,
        ),
        child: content,
      );
    }

    return content;
  }
}
