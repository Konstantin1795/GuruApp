/// Парсинг процентов долей в «сотые доли процента» (100,00% → 10000). ТЗ-10A.
int? expensePercentHundredths(String raw) {
  final s = raw.trim();
  final re = RegExp(r'^(\d{1,3})(?:\.(\d{1,2}))?$');
  final m = re.firstMatch(s);
  if (m == null) return null;
  final intPart = int.tryParse(m.group(1)!);
  if (intPart == null) return null;
  final fracGroup = m.group(2);
  if (fracGroup != null && fracGroup.length > 2) return null;
  final frac = (fracGroup ?? '').padRight(2, '0');
  final fracVal = int.tryParse(frac.substring(0, 2));
  if (fracVal == null) return null;
  final v = intPart * 100 + fracVal;
  if (v <= 0 || v > 10000) return null;
  return v;
}

bool expensePercentsSumToFull(List<String> inputs) {
  var sum = 0;
  for (final x in inputs) {
    final h = expensePercentHundredths(x);
    if (h == null) return false;
    sum += h;
  }
  return sum == 10000;
}
