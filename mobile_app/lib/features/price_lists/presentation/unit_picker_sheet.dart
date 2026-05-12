import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_loader.dart';
import '../providers.dart';

class UnitPickerSheet extends ConsumerWidget {
  final int companyId;

  const UnitPickerSheet({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(unitsListProvider(companyId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const SizedBox(height: 200, child: Center(child: AppLoader())),
          error: (e, _) => Text('$e'),
          data: (units) => SizedBox(
            height: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.selectUnit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: units.length,
                    itemBuilder: (_, i) {
                      final u = units[i];
                      return ListTile(
                        title: Text(u.name),
                        subtitle: Text(u.shortName),
                        onTap: () => Navigator.pop(context, u),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
