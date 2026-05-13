import 'operation_status_history_entry.dart';

class ReportDetailView {
  final Map<String, dynamic> report;
  final Map<String, bool> availableActions;
  final String? viewerContext;
  final List<OperationStatusHistoryEntry> statusHistory;
  final List<Map<String, dynamic>> transferLinks;

  const ReportDetailView({
    required this.report,
    required this.availableActions,
    required this.viewerContext,
    required this.statusHistory,
    required this.transferLinks,
  });

  factory ReportDetailView.fromShowJson(Map<String, dynamic> data) {
    final reportMap = (data['report'] as Map).cast<String, dynamic>();
    final rawActions = data['available_actions'];
    final Map<String, bool> actions = {};
    if (rawActions is Map) {
      for (final e in rawActions.entries) {
        actions[e.key.toString()] = e.value == true;
      }
    }

    final viewerContext = data['viewer_context'] as String?;

    final List<OperationStatusHistoryEntry> history = [];
    final histRaw = reportMap['status_history'];
    if (histRaw is List) {
      for (final item in histRaw) {
        if (item is Map) {
          history.add(OperationStatusHistoryEntry.fromJson(item.cast<String, dynamic>()));
        }
      }
    }
    history.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;
      return ta.compareTo(tb);
    });

    final List<Map<String, dynamic>> links = [];
    final tl = reportMap['transfer_links'];
    if (tl is List) {
      for (final e in tl) {
        if (e is Map) {
          links.add(e.cast<String, dynamic>());
        }
      }
    }

    return ReportDetailView(
      report: reportMap,
      availableActions: actions,
      viewerContext: viewerContext,
      statusHistory: history,
      transferLinks: links,
    );
  }
}
