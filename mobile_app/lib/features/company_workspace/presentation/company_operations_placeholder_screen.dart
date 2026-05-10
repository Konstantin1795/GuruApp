import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_card.dart';

class CompanyOperationsPlaceholderScreen extends StatelessWidget {
  const CompanyOperationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(child: Text(context.l10n.operationsPlaceholder)),
      ],
    );
  }
}
