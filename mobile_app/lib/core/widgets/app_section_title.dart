import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Section-label widget used to divide content into named groups.
///
/// Renders the [title] in uppercase with the standard [AppTextStyles.sectionTitle] style.
///
/// Example:
/// ```dart
/// const AppSectionTitle(title: 'Личные средства'),
/// const SizedBox(height: 10),
/// ...cards...
/// ```
class AppSectionTitle extends StatelessWidget {
  final String title;

  const AppSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.sectionTitle,
    );
  }
}
