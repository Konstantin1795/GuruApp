import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/providers.dart';
import 'company_workspace_identity.dart';
import '../../../core/widgets/app_section_title.dart';
import '../../projects/domain/participant_wallet.dart';
import '../../projects/domain/project_participant.dart';
import '../../projects/providers.dart';

// ──────────────────────────── State / Controller ───────────────────────────

typedef _WalletKey = ({int companyId, int projectId, int participantId});

final _participantWalletProvider = StateNotifierProvider.family<
    _WalletController, AsyncValue<ParticipantWallet>, _WalletKey>(
  (ref, key) => _WalletController(ref: ref, key: key),
);

class _WalletController extends StateNotifier<AsyncValue<ParticipantWallet>> {
  final Ref ref;
  final _WalletKey key;

  _WalletController({required this.ref, required this.key})
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final wallet = await ref.read(participantWalletRepositoryProvider).get(
            companyId: key.companyId,
            projectId: key.projectId,
            participantId: key.participantId,
          );
      state = AsyncValue.data(wallet);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();
}

// ──────────────────────────── Screen ───────────────────────────────────────

class ParticipantWalletScreen extends ConsumerWidget {
  final ProjectParticipant participant;
  final int companyId;

  const ParticipantWalletScreen({
    super.key,
    required this.participant,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      companyId: companyId,
      projectId: participant.projectId,
      participantId: participant.id,
    );
    final state = ref.watch(_participantWalletProvider(key));

    final l10n = context.l10n;

    final userName = ref.watch(currentUserProvider).valueOrNull?.name.trim() ?? '';
    final roleLabel = companyWorkspaceHeaderRoleLabel(ref, companyId, l10n);

    return AppScaffold(
      headerUserName: userName.isEmpty ? null : userName,
      headerRoleLabel: roleLabel,
      title: l10n.walletTitle,
      subtitle: participant.displayName,
      body: state.when(
        loading: () => const AppLoader(),
        error: (e, _) => _ErrorBody(
          message: e is ApiException ? e.message : l10n.walletErrorLoad,
          onRetry: () => ref.read(_participantWalletProvider(key).notifier).refresh(),
        ),
        data: (wallet) => RefreshIndicator(
          onRefresh: () => ref.read(_participantWalletProvider(key).notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              AppSectionTitle(title: l10n.walletPersonalFunds),
              const SizedBox(height: 10),
              _WalletCard(
                items: [
                  _BalanceItem(
                    label: l10n.walletBalance,
                    value: wallet.personalBalance,
                    accent: true,
                  ),
                  _BalanceItem(label: l10n.walletEarned, value: wallet.personalEarned),
                  _BalanceItem(label: l10n.walletReceived, value: wallet.personalReceived),
                ],
              ),
              const SizedBox(height: 20),
              AppSectionTitle(title: l10n.walletAccountableFunds),
              const SizedBox(height: 10),
              _WalletCard(
                items: [
                  _BalanceItem(
                    label: l10n.walletBalance,
                    value: wallet.accountableBalance,
                    accent: true,
                  ),
                  _BalanceItem(label: l10n.walletReceived, value: wallet.accountableReceived),
                  _BalanceItem(label: l10n.walletSpent, value: wallet.accountableSpent),
                ],
              ),
              const SizedBox(height: 24),
              _RoleChip(role: participant.role),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────── UI Widgets ───────────────────────────────────

class _WalletCard extends StatelessWidget {
  final List<_BalanceItem> items;
  static const _accent = Color(0xFF00D6C9);

  const _WalletCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.09),
                _accent.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  static const _accentColor = Color(0xFF00D6C9);

  const _BalanceItem({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: accent ? 0.9 : 0.65),
                fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            _formatted(value),
            style: TextStyle(
              fontSize: accent ? 20 : 16,
              fontWeight: FontWeight.w800,
              color: accent ? _accentColor : Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatted(String raw) {
    // Ensure always 2 decimal places: "0.00" → "0.00", "1234.5" → "1 234.50"
    final d = double.tryParse(raw) ?? 0.0;
    final parts = d.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    // Thousand separator
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('\u00A0'); // non-breaking space
      buf.write(intPart[i]);
    }
    return '${buf.toString()}.$decPart';
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  static const _accentColor = Color(0xFF00D6C9);

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = {
      'PROJECT_HEAD': l10n.roleProjectHead,
      'PARTNER':      l10n.rolePartner,
      'CUSTOMER':     l10n.roleCustomer,
      'SUPERVISOR':   l10n.roleSupervisor,
      'EMPLOYEE':     l10n.roleEmployee,
      'SUPPLIER':     l10n.roleSupplier,
      'CONTRACTOR':   l10n.roleContractor,
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _accentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          labels[role] ?? role,
          style: const TextStyle(
            color: _accentColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(label: context.l10n.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
