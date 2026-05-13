import 'package:flutter/material.dart';

import '../domain/report_operation.dart';

/// Заглушка деталей REPORT до полного UI ТЗ-10C.
class ReportDetailStubScreen extends StatelessWidget {
  final int projectId;
  final ReportOperation report;

  const ReportDetailStubScreen({
    super.key,
    required this.projectId,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отчёт')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('№ ${report.operationNumber ?? report.id}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Проект #$projectId'),
          if (report.projectName != null) Text(report.projectName!),
          const SizedBox(height: 16),
          Text('Статус: ${report.status.label}'),
          const SizedBox(height: 8),
          Text('Заказчик (итого): ${report.customerTotalAmount}'),
          Text('Прибыль: ${report.profitAmount}'),
        ],
      ),
    );
  }
}
