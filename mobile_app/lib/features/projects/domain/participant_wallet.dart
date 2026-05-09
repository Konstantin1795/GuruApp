class ParticipantWallet {
  final String personalBalance;
  final String personalEarned;
  final String personalReceived;
  final String accountableBalance;
  final String accountableReceived;
  final String accountableSpent;

  const ParticipantWallet({
    required this.personalBalance,
    required this.personalEarned,
    required this.personalReceived,
    required this.accountableBalance,
    required this.accountableReceived,
    required this.accountableSpent,
  });

  factory ParticipantWallet.fromJson(Map<String, dynamic> json) => ParticipantWallet(
        personalBalance: json['personal_balance'] as String? ?? '0.00',
        personalEarned: json['personal_earned'] as String? ?? '0.00',
        personalReceived: json['personal_received'] as String? ?? '0.00',
        accountableBalance: json['accountable_balance'] as String? ?? '0.00',
        accountableReceived: json['accountable_received'] as String? ?? '0.00',
        accountableSpent: json['accountable_spent'] as String? ?? '0.00',
      );
}
