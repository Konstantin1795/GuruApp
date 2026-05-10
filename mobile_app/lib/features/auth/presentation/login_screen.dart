import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../providers.dart';
import 'auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).login(
            email: _email.text.trim(),
            password: _password.text,
            deviceName: 'android',
          );
      await ref.read(authControllerProvider.notifier).setAuthenticated();
      if (!mounted) return;
      context.go('/workspaces');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.l10n.authLoginFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.appName,
      actions: [const LocaleSwitchButton()],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.authWelcome,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.authWelcomeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 18),
                  AppInput(
                    controller: _email,
                    label: l10n.authEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    controller: _password,
                    label: l10n.authPassword,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppButton(
                    label: l10n.authSignIn,
                    onPressed: _loading ? null : _submit,
                    loading: _loading,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: l10n.authSignUp,
                    onPressed: _loading ? null : () => context.go('/register'),
                    outlined: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Language switcher (shown in AppBar actions on auth screens) ──────────────

/// Public language switcher button — used on Login, Register, and potentially
/// any other screen that needs a locale toggle in the AppBar.
class LocaleSwitchButton extends ConsumerWidget {
  const LocaleSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return TextButton(
      onPressed: () => _showPicker(context, ref),
      child: Text(
        locale.languageCode.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LocalePickerSheet(
        onSelect: (locale) {
          Navigator.of(ctx).pop();
          ref.read(localeProvider.notifier).setLocale(locale);
        },
      ),
    );
  }
}

class _LocalePickerSheet extends ConsumerWidget {
  final ValueChanged<Locale> onSelect;
  const _LocalePickerSheet({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              l10n.language,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _LocaleOption(
              label: l10n.languageRu,
              flag: '🇷🇺',
              selected: current.languageCode == 'ru',
              onTap: () => onSelect(const Locale('ru')),
            ),
            const SizedBox(height: 10),
            _LocaleOption(
              label: l10n.languageEn,
              flag: '🇬🇧',
              selected: current.languageCode == 'en',
              onTap: () => onSelect(const Locale('en')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocaleOption extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LocaleOption({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentDim
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accentBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 15,
              ),
            ),
            if (selected) ...[
              const Spacer(),
              const Icon(Icons.check, color: AppColors.accent, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
