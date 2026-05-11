import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

/// Диалог комментария к действию над операцией (перевод / поступление).
/// Контроллер живёт в [State] диалога и освобождается после снятия route — иначе возможны
/// «TextEditingController was used after being disposed» при немедленном [dispose] снаружи.
Future<String?> showOperationCommentDialog(BuildContext context, AppLocalizations l10n) {
  return showDialog<String?>(
    context: context,
    builder: (ctx) => _OperationCommentDialog(l10n: l10n),
  );
}

class _OperationCommentDialog extends StatefulWidget {
  const _OperationCommentDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_OperationCommentDialog> createState() => _OperationCommentDialogState();
}

class _OperationCommentDialogState extends State<_OperationCommentDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.transferActionCommentTitle),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        decoration: InputDecoration(hintText: l10n.transferCommentHint),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<String?>(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop<String?>(context, _controller.text.trim()),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
