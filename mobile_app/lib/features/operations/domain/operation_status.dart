enum OperationStatus {
  created,
  projectHeadApproval,
  customerApproval,
  waiting24Hours,
  completed,
  rejected,
  rolledBack;

  static OperationStatus fromJson(String value) {
    return switch (value.toUpperCase()) {
      'CREATED'                => created,
      'PROJECT_HEAD_APPROVAL'  => projectHeadApproval,
      'CUSTOMER_APPROVAL'      => customerApproval,
      'WAITING_24_HOURS'       => waiting24Hours,
      'COMPLETED'              => completed,
      'REJECTED'               => rejected,
      'ROLLED_BACK'            => rolledBack,
      _                        => throw ArgumentError('Unknown OperationStatus: $value'),
    };
  }

  String toJson() => switch (this) {
        created             => 'CREATED',
        projectHeadApproval => 'PROJECT_HEAD_APPROVAL',
        customerApproval    => 'CUSTOMER_APPROVAL',
        waiting24Hours      => 'WAITING_24_HOURS',
        completed           => 'COMPLETED',
        rejected            => 'REJECTED',
        rolledBack          => 'ROLLED_BACK',
      };

  String get label => switch (this) {
        created             => 'Создана',
        projectHeadApproval => 'Ожидает руководителя',
        customerApproval    => 'Ожидает заказчика',
        waiting24Hours      => 'Период 24 часа',
        completed           => 'Завершена',
        rejected            => 'Отклонена',
        rolledBack          => 'Откат',
      };

  bool get isTerminal => switch (this) {
        completed || rejected || rolledBack => true,
        _ => false,
      };
}
