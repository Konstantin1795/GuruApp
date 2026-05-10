import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';

/// Convenience accessor: `context.l10n.someKey`
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
