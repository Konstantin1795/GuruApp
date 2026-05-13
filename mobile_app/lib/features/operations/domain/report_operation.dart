import 'operation_status.dart';

/// REPORT из API (`report` в объединённой истории).
class ReportOperation {
  final int id;
  final String? operationNumber;
  final int projectId;
  final String? projectName;
  final OperationStatus status;
  final String customerTotalAmount;
  final String profitAmount;

  const ReportOperation({
    required this.id,
    this.operationNumber,
    required this.projectId,
    this.projectName,
    required this.status,
    required this.customerTotalAmount,
    required this.profitAmount,
  });

  factory ReportOperation.fromJson(Map<String, dynamic> json) {
    return ReportOperation(
      id: (json['id'] as num).toInt(),
      operationNumber: json['operation_number']?.toString(),
      projectId: (json['project_id'] as num).toInt(),
      projectName: json['project_name']?.toString(),
      status: OperationStatus.fromJson(json['operation_status']?.toString() ?? ''),
      customerTotalAmount: (json['customer_total_amount'] ?? '0').toString(),
      profitAmount: (json['profit_amount'] ?? '0').toString(),
    );
  }
}
