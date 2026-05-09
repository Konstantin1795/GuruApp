enum OperationType {
  income,
  transfer,
  report;

  static OperationType fromJson(String value) {
    return switch (value.toUpperCase()) {
      'INCOME'   => income,
      'TRANSFER' => transfer,
      'REPORT'   => report,
      _          => throw ArgumentError('Unknown OperationType: $value'),
    };
  }

  String toJson() => name.toUpperCase();

  String get label => switch (this) {
        income   => 'Поступление',
        transfer => 'Перевод',
        report   => 'Отчёт',
      };
}
