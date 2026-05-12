import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../providers.dart';

class CreateEditPriceListScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int? priceListId;

  const CreateEditPriceListScreen({
    super.key,
    required this.companyId,
    required this.priceListId,
  });

  @override
  ConsumerState<CreateEditPriceListScreen> createState() => _CreateEditPriceListScreenState();
}

class _CreateEditPriceListScreenState extends ConsumerState<CreateEditPriceListScreen> {
  late final TextEditingController _name = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.priceListId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final d = await ref.read(
          priceListDetailProvider((companyId: widget.companyId, priceListId: widget.priceListId!)).future,
        );
        if (mounted) _name.text = d.name;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(priceListsRepositoryProvider);
      if (widget.priceListId == null) {
        await repo.createPriceList(companyId: widget.companyId, name: name);
      } else {
        await repo.updatePriceList(
          companyId: widget.companyId,
          priceListId: widget.priceListId!,
          name: name,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, widget.companyId, l10n);
    final isEdit = widget.priceListId != null;

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: isEdit ? l10n.editPriceList : l10n.createPriceList,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInput(controller: _name, label: l10n.priceListName, autofocus: !isEdit),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Text(_loading ? l10n.loading : l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
