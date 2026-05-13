/// Связь перевода с отчётом (`linked_report` в `GET …/transfers/{id}`).
class LinkedReportSummary {
  final int reportId;
  final String? operationNumber;

  const LinkedReportSummary({required this.reportId, this.operationNumber});

  factory LinkedReportSummary.fromJson(dynamic raw) {
    final parsed = tryParse(raw);
    return parsed ?? const LinkedReportSummary(reportId: 0, operationNumber: null);
  }

  static LinkedReportSummary? tryParse(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final m = raw.cast<String, dynamic>();
    final id = m['report_id'];
    final reportId = id is int ? id : int.tryParse('$id') ?? 0;
    if (reportId <= 0) {
      return null;
    }
    return LinkedReportSummary(
      reportId: reportId,
      operationNumber: m['operation_number']?.toString(),
    );
  }

  bool get isLinked => reportId > 0;
}
