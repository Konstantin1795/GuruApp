import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import '../../company_workspace/presentation/company_workspace_identity.dart';
import '../data/incomes_api.dart';
import '../data/transfers_api.dart';
import '../providers.dart';
import 'income_detail_screen.dart';

/// ТЗ-06: создание поступления (company workspace, HEAD/PARTNER — проверка на backend).
class CreateIncomeScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int projectId;
  final String projectName;

  const CreateIncomeScreen({
    super.key,
    required this.companyId,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<CreateIncomeScreen> createState() => _CreateIncomeScreenState();
}

class _CreateIncomeScreenState extends ConsumerState<CreateIncomeScreen> {
  final _amountCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = _amountCtrl.text.trim().replaceAll(',', '.');
    if (!RegExp(r'^(?!0+(?:\.0{1,2})?$)\d+(?:\.\d{1,2})?$').hasMatch(amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.transferAmountError)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final income = await ref.read(incomesRepositoryProvider).create(
            scope: IncomeApiScope.company,
            companyId: widget.companyId,
            projectId: widget.projectId,
            amount: amount,
            comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(
        combinedOperationsPendingCountProvider(
          (scope: TransferApiScope.company, companyId: widget.companyId),
        ),
      );
      ref.invalidate(
        incomePendingActionCountProvider(
          (scope: IncomeApiScope.company, companyId: widget.companyId),
        ),
      );
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => IncomeDetailScreen(
            apiScope: IncomeApiScope.company,
            companyId: widget.companyId,
            projectId: widget.projectId,
            incomeId: income.id,
          ),
        ),
      );
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : context.l10n.transferErrorCreate),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = ref.read(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabelRead(ref, widget.companyId, l10n);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.operationIncome,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.projectName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 18),
            AppInput(
              controller: _amountCtrl,
              label: l10n.transferAmountLabel,
              hint: l10n.transferAmountHint,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _commentCtrl,
              label: l10n.transferCommentLabel,
              hint: l10n.transferCommentHint,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 22),
            AppButton(
              label: l10n.confirm,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
