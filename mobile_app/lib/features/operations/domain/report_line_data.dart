/// Строка отчёта для UI и тела `POST …/reports` (immutable).
class ReportLineData {
  const ReportLineData({
    required this.sourceType,
    this.priceListId,
    this.groupId,
    this.positionId,
    required this.name,
    required this.unitName,
    required this.unitShortName,
    this.unitId,
    required this.quantity,
    required this.recipientUnitPrice,
    required this.customerUnitPrice,
  });

  final String sourceType;
  final int? priceListId;
  final int? groupId;
  final int? positionId;
  final String name;
  final String unitName;
  final String unitShortName;
  final int? unitId;
  final String quantity;
  final String recipientUnitPrice;
  final String customerUnitPrice;

  bool get isFromPriceList => sourceType == 'PRICE_LIST';

  factory ReportLineData.custom({
    String name = '',
    String unitName = 'pc',
    String unitShortName = 'pc',
    int? unitId,
    String quantity = '1',
    String recipientUnitPrice = '0',
    String customerUnitPrice = '0',
  }) {
    return ReportLineData(
      sourceType: 'CUSTOM',
      name: name,
      unitName: unitName,
      unitShortName: unitShortName,
      unitId: unitId,
      quantity: quantity,
      recipientUnitPrice: recipientUnitPrice,
      customerUnitPrice: customerUnitPrice,
    );
  }

  factory ReportLineData.fromPriceList({
    required int priceListId,
    required int groupId,
    required int positionId,
    required String name,
    required String unitName,
    required String unitShortName,
    int? unitId,
    required String quantity,
    required String recipientUnitPrice,
    required String customerUnitPrice,
  }) {
    return ReportLineData(
      sourceType: 'PRICE_LIST',
      priceListId: priceListId,
      groupId: groupId,
      positionId: positionId,
      name: name,
      unitName: unitName,
      unitShortName: unitShortName,
      unitId: unitId,
      quantity: quantity,
      recipientUnitPrice: recipientUnitPrice,
      customerUnitPrice: customerUnitPrice,
    );
  }

  ReportLineData copyWith({
    String? name,
    String? unitName,
    String? unitShortName,
    int? unitId,
    String? quantity,
    String? recipientUnitPrice,
    String? customerUnitPrice,
  }) {
    return ReportLineData(
      sourceType: sourceType,
      priceListId: priceListId,
      groupId: groupId,
      positionId: positionId,
      name: name ?? this.name,
      unitName: unitName ?? this.unitName,
      unitShortName: unitShortName ?? this.unitShortName,
      unitId: unitId ?? this.unitId,
      quantity: quantity ?? this.quantity,
      recipientUnitPrice: recipientUnitPrice ?? this.recipientUnitPrice,
      customerUnitPrice: customerUnitPrice ?? this.customerUnitPrice,
    );
  }

  double recipientLineTotal() {
    final q = double.tryParse(quantity.trim().replaceAll(',', '.')) ?? 0;
    final ru = double.tryParse(recipientUnitPrice.trim().replaceAll(',', '.')) ?? 0;
    return q * ru;
  }

  double customerLineTotal() {
    final q = double.tryParse(quantity.trim().replaceAll(',', '.')) ?? 0;
    final cu = double.tryParse(customerUnitPrice.trim().replaceAll(',', '.')) ?? 0;
    return q * cu;
  }

  Map<String, dynamic> toRequestLine() {
    final qty = quantity.trim().replaceAll(',', '.');
    final ru = recipientUnitPrice.trim().replaceAll(',', '.');
    final cu = customerUnitPrice.trim().replaceAll(',', '.');
    final rt = recipientLineTotal();
    final ct = customerLineTotal();
    final n = name.trim().isEmpty ? 'Line' : name.trim();
    return {
      'source_type': sourceType,
      if (priceListId != null) 'price_list_id': priceListId,
      if (groupId != null) 'price_list_group_id': groupId,
      if (positionId != null) 'price_list_position_id': positionId,
      'name': n,
      if (unitId != null) 'unit_id': unitId,
      'unit_name': unitName,
      'unit_short_name': unitShortName,
      'quantity': qty,
      'recipient_unit_price': ru,
      'customer_unit_price': cu,
      'recipient_total': rt.toStringAsFixed(2),
      'customer_total': ct.toStringAsFixed(2),
    };
  }
}
