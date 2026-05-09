enum TransferTargetType {
  personalBalance,
  accountableBalance;

  static TransferTargetType fromJson(String value) => switch (value) {
        'PERSONAL_BALANCE' => personalBalance,
        'ACCOUNTABLE_BALANCE' => accountableBalance,
        _ => throw ArgumentError('Unknown TransferTargetType: $value'),
      };

  String toJson() => switch (this) {
        personalBalance => 'PERSONAL_BALANCE',
        accountableBalance => 'ACCOUNTABLE_BALANCE',
      };

  String get label => switch (this) {
        personalBalance => 'На расчётный баланс',
        accountableBalance => 'На подотчётный баланс',
      };
}
