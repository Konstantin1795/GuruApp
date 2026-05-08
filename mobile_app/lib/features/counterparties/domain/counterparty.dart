class Counterparty {
  final int id;
  final int companyId;
  final int? userId;
  final String companyRole;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Counterparty({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.companyRole,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Counterparty.fromJson(Map<String, dynamic> json) => Counterparty(
        id: json['id'] as int,
        companyId: json['company_id'] as int,
        userId: json['user_id'] as int?,
        companyRole: json['company_role'] as String,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      );
}

