class PersonalIncomeMonth {
  final int year;
  final int month;
  final String total;

  const PersonalIncomeMonth({
    required this.year,
    required this.month,
    required this.total,
  });

  factory PersonalIncomeMonth.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return PersonalIncomeMonth(
      year: asInt(json['year']),
      month: asInt(json['month']),
      total: (json['total'] ?? '0.00').toString(),
    );
  }
}
