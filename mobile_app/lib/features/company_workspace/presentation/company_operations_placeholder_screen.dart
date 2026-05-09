import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';

class CompanyOperationsPlaceholderScreen extends StatelessWidget {
  const CompanyOperationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        AppCard(
          child: Text(
            'Операции (плейсхолдер).\n\n'
            'По ТЗ операции/кошельки пока не реализуем — здесь будет экран на следующем этапе.',
          ),
        ),
      ],
    );
  }
}

