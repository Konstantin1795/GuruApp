import 'dart:ui' show Locale;

import 'package:intl/intl.dart';

import '../../projects/domain/project.dart';

/// Три календарных месяца текущего квартала (янв–мар, апр–июн, …).
List<DateTime> quarterMonthStarts(DateTime now) {
  final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
  return [
    DateTime(now.year, startMonth, 1),
    DateTime(now.year, startMonth + 1, 1),
    DateTime(now.year, startMonth + 2, 1),
  ];
}

DateTime endOfMonth(DateTime monthStart) =>
    DateTime(monthStart.year, monthStart.month + 1, 0, 23, 59, 59, 999);

/// Месяц ещё не наступил (на дашборде показываем 0), пока календарная дата раньше 1-го числа месяца.
bool monthNotYetStarted(DateTime monthStart, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final first = DateTime(monthStart.year, monthStart.month, 1);
  return today.isBefore(first);
}

/// Сколько проектов считаются активными на конец месяца [monthStart]:
/// сейчас активны (`is_active`) и уже созданы к концу месяца.
/// Истории смены активности пока нет — опора на текущий флаг и `created_at`.
int activeProjectsAtMonthEnd(List<Project> projects, DateTime monthStart) {
  final end = endOfMonth(monthStart);
  return projects.where((p) {
    if (!p.isActive) return false;
    final c = p.createdAt;
    if (c == null) return true;
    return !c.isAfter(end);
  }).length;
}

const _ruMonthShort = <int, String>{
  1: 'янв',
  2: 'фев',
  3: 'мар',
  4: 'апр',
  5: 'май',
  6: 'июн',
  7: 'июл',
  8: 'авг',
  9: 'сен',
  10: 'окт',
  11: 'ноя',
  12: 'дек',
};

String monthShortLabel(DateTime monthStart, Locale locale) {
  if (locale.languageCode == 'ru') {
    return _ruMonthShort[monthStart.month] ?? '${monthStart.month}';
  }
  final s = DateFormat.MMM(locale.toLanguageTag()).format(monthStart);
  final t = s.replaceAll('.', '').trim();
  return t.length <= 3 ? t.toLowerCase() : t.substring(0, 3).toLowerCase();
}

class QuarterMonthBarData {
  final DateTime monthStart;
  final String label;
  final int activeProjectsCount;

  const QuarterMonthBarData({
    required this.monthStart,
    required this.label,
    required this.activeProjectsCount,
  });
}

class CompanyDashboardStats {
  final int counterpartiesTotal;
  final int activeProjectsTotal;
  final List<QuarterMonthBarData> quarterBars;

  const CompanyDashboardStats({
    required this.counterpartiesTotal,
    required this.activeProjectsTotal,
    required this.quarterBars,
  });

  static CompanyDashboardStats compute({
    required List<Project> projects,
    required int counterpartiesTotal,
    required DateTime now,
    required Locale locale,
  }) {
    final months = quarterMonthStarts(now);
    final bars = <QuarterMonthBarData>[];
    for (final m in months) {
      final n = monthNotYetStarted(m, now)
          ? 0
          : activeProjectsAtMonthEnd(projects, m);
      bars.add(QuarterMonthBarData(
        monthStart: m,
        label: monthShortLabel(m, locale),
        activeProjectsCount: n,
      ));
    }
    final activeTotal = projects.where((p) => p.isActive).length;
    return CompanyDashboardStats(
      counterpartiesTotal: counterpartiesTotal,
      activeProjectsTotal: activeTotal,
      quarterBars: bars,
    );
  }
}
