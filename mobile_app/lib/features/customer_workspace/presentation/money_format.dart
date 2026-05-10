import 'package:intl/intl.dart';

double parseDecimalMoney(String raw) {
  final s = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(s) ?? 0;
}

String formatMoneyDisplay(String raw, String localeName) {
  final v = parseDecimalMoney(raw);
  final fmt = NumberFormat.decimalPatternDigits(locale: localeName, decimalDigits: 2);
  return fmt.format(v);
}
