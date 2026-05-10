import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../customer_workspace/presentation/money_format.dart';
import '../domain/personal_income_month.dart';

/// Bars scale relative to the maximum month (100% height).
class MonthlyIncomeChart extends StatelessWidget {
  final List<PersonalIncomeMonth> months;
  final String localeName;

  const MonthlyIncomeChart({
    super.key,
    required this.months,
    required this.localeName,
  });

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return const SizedBox.shrink();

    final values = months.map((m) => parseDecimalMoney(m.total)).toList();
    final maxV = values.fold<double>(0, (a, b) => a > b ? a : b);
    const maxBarH = 96.0;
    const gap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final n = months.length;
        final slotW = (constraints.maxWidth - gap * (n - 1)) / n;
        final barW = (slotW * 0.52).clamp(8.0, 32.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(n, (i) {
            final v = values[i];
            final ratio = maxV > 0 ? v / maxV : 0.0;
            var h = ratio * maxBarH;
            if (maxV > 0 && h > 0 && h < 4) h = 4;
            if (maxV == 0) h = 4;

            final dt = DateTime(months[i].year, months[i].month);
            final lab = DateFormat.MMM(localeName).format(dt);

            return Padding(
              padding: EdgeInsets.only(right: i == n - 1 ? 0 : gap),
              child: SizedBox(
                width: slotW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: maxBarH,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: barW,
                          height: h.clamp(2.0, maxBarH),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lab,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
