class Counterparty {
  final int id;
  final int companyId;
  final int? userId;
  final String companyRole;
  final bool isActive;
  final String? userName;
  final String? userEmail;
  final String? fullName;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Counterparty({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.companyRole,
    required this.isActive,
    required this.userName,
    required this.userEmail,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Counterparty.fromJson(Map<String, dynamic> json) => Counterparty(
        id: json['id'] as int,
        companyId: json['company_id'] as int,
        userId: json['user_id'] as int?,
        companyRole: json['company_role'] as String,
        isActive: json['is_active'] as bool,
        userName: (json['user'] as Map?)?['name'] as String?,
        userEmail: (json['user'] as Map?)?['email'] as String?,
        fullName: json['full_name'] as String?,
        email: json['email'] as String?,
        createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      );

  /// Строка для выбора в списках (ФИО с бэкенда или из профиля пользователя).
  String get pickerDisplayLabel {
    String? trimmed(String? s) {
      final t = s?.trim();
      if (t == null || t.isEmpty) return null;
      return t;
    }

    final fio = trimmed(fullName) ?? trimmed(userName);
    if (fio != null) return fio;

    final mail = trimmed(email) ?? trimmed(userEmail);
    if (mail != null) return mail;

    return 'Заказчик #$id';
  }
}

/// Коды ролей контрагента в company workspace (как на бэкенде).
const kCompanyWorkspaceCounterpartyRoles = <String>[
  'PARTNER',
  'EMPLOYEE',
  'CONTRACTOR',
  'SUPPLIER',
  'CUSTOMER',
];

const kCompanyWorkspaceCounterpartyRoleLabelsRu = <String, String>{
  'PARTNER': 'Партнёр',
  'EMPLOYEE': 'Сотрудник',
  'CONTRACTOR': 'Подрядчик',
  'SUPPLIER': 'Поставщик',
  'CUSTOMER': 'Заказчик',
};

String companyWorkspaceCounterpartyRoleLabelRu(String code) =>
    kCompanyWorkspaceCounterpartyRoleLabelsRu[code] ?? code;

