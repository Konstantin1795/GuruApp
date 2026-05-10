import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../workspaces/domain/workspaces.dart';
import '../../workspaces/providers.dart';
import '../providers.dart';

CompanyWorkspaceItem? companyWorkspaceEntry(Workspaces? ws, int companyId) {
  if (ws == null) return null;
  for (final c in ws.companyWorkspaces) {
    if (c.companyId == companyId) return c;
  }
  return null;
}

String? companyWorkspaceRoleLabelFromCode(String? roleCode, AppLocalizations l10n) {
  if (roleCode == null || roleCode.isEmpty) return null;
  switch (roleCode) {
    case 'OWNER':
      return l10n.companyWorkspaceRoleHead;
    case 'PARTNER':
      return l10n.rolePartner;
    default:
      return roleCode;
  }
}

/// Company workspace app-bar role (OWNER / PARTNER in company), not project role.
String? companyWorkspaceHeaderRoleLabel(WidgetRef ref, int companyId, AppLocalizations l10n) {
  final ws = ref.watch(workspacesProvider).valueOrNull;
  final entry = companyWorkspaceEntry(ws, companyId);
  final company = ref.watch(currentCompanyProvider(companyId)).valueOrNull;
  final code = entry?.role ?? company?.myCompanyRoleCode;
  return companyWorkspaceRoleLabelFromCode(code, l10n);
}

/// То же для экранов без подписки на провайдеры в [build] (избегаем лишних перестроек).
String? companyWorkspaceHeaderRoleLabelRead(WidgetRef ref, int companyId, AppLocalizations l10n) {
  final ws = ref.read(workspacesProvider).valueOrNull;
  final entry = companyWorkspaceEntry(ws, companyId);
  final company = ref.read(currentCompanyProvider(companyId)).valueOrNull;
  final code = entry?.role ?? company?.myCompanyRoleCode;
  return companyWorkspaceRoleLabelFromCode(code, l10n);
}
