import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'GURU'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the entered data.'**
  String get errorValidation;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your internet.'**
  String get errorNetwork;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @languageRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcome;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authWelcomeSubtitle;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start using GURU'**
  String get authSignUpSubtitle;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get authBackToLogin;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authName;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Check your credentials.'**
  String get authLoginFailed;

  /// No description provided for @authRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get authRegisterFailed;

  /// No description provided for @workspacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspacesTitle;

  /// No description provided for @workspaceChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a workspace'**
  String get workspaceChoose;

  /// No description provided for @workspaceCompany.
  ///
  /// In en, this message translates to:
  /// **'Company workspace'**
  String get workspaceCompany;

  /// No description provided for @workspacePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal workspace'**
  String get workspacePersonal;

  /// No description provided for @workspacesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workspaces available yet.'**
  String get workspacesEmpty;

  /// No description provided for @workspacesErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load workspaces.'**
  String get workspacesErrorLoad;

  /// No description provided for @openPersonal.
  ///
  /// In en, this message translates to:
  /// **'Open personal workspace'**
  String get openPersonal;

  /// No description provided for @personalRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles: {roles}'**
  String personalRoles(String roles);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @createCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create company'**
  String get createCompanyTitle;

  /// No description provided for @createCompanyHeading.
  ///
  /// In en, this message translates to:
  /// **'New company'**
  String get createCompanyHeading;

  /// No description provided for @createCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You will become OWNER'**
  String get createCompanySubtitle;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyNameLabel;

  /// No description provided for @companyCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create company.'**
  String get companyCreateError;

  /// No description provided for @dashboardAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Quarter analytics'**
  String get dashboardAnalytics;

  /// No description provided for @dashboardIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardIncome;

  /// No description provided for @dashboardDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get dashboardDebt;

  /// No description provided for @dashboardOverpayment.
  ///
  /// In en, this message translates to:
  /// **'Overpayment'**
  String get dashboardOverpayment;

  /// No description provided for @dashboardActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'Active projects'**
  String get dashboardActiveProjects;

  /// No description provided for @dashboardDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get dashboardDocuments;

  /// No description provided for @dashboardHistory.
  ///
  /// In en, this message translates to:
  /// **'Operations history'**
  String get dashboardHistory;

  /// No description provided for @dashboardAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get dashboardAwaitingConfirmation;

  /// No description provided for @projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProject;

  /// No description provided for @projectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectNameLabel;

  /// No description provided for @projectCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get projectCustomerLabel;

  /// No description provided for @projectNoCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add a customer first'**
  String get projectNoCustomer;

  /// No description provided for @projectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects yet.'**
  String get projectsEmpty;

  /// No description provided for @projectsErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load projects.'**
  String get projectsErrorLoad;

  /// No description provided for @projectProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {percent}%'**
  String projectProgress(int percent);

  /// No description provided for @projectInactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get projectInactive;

  /// No description provided for @projectCreated.
  ///
  /// In en, this message translates to:
  /// **'Project created'**
  String get projectCreated;

  /// No description provided for @projectErrorCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create project'**
  String get projectErrorCreate;

  /// No description provided for @projectTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String projectTotal(int count);

  /// No description provided for @counterpartiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Counterparties'**
  String get counterpartiesTitle;

  /// No description provided for @addCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Add counterparty'**
  String get addCounterparty;

  /// No description provided for @counterpartyFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get counterpartyFullName;

  /// No description provided for @counterpartyEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get counterpartyEmail;

  /// No description provided for @counterpartyRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get counterpartyRole;

  /// No description provided for @counterpartiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No counterparties yet.'**
  String get counterpartiesEmpty;

  /// No description provided for @counterpartiesErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load counterparties.'**
  String get counterpartiesErrorLoad;

  /// No description provided for @counterpartyAdded.
  ///
  /// In en, this message translates to:
  /// **'Counterparty added'**
  String get counterpartyAdded;

  /// No description provided for @counterpartyErrorCreate.
  ///
  /// In en, this message translates to:
  /// **'Create error'**
  String get counterpartyErrorCreate;

  /// No description provided for @counterpartyEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get counterpartyEnterName;

  /// No description provided for @counterpartyEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get counterpartyEnterEmail;

  /// No description provided for @counterpartySearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name…'**
  String get counterpartySearch;

  /// No description provided for @counterpartyTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String counterpartyTotal(int count);

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @rolePartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get rolePartner;

  /// No description provided for @companyWorkspaceRoleHead.
  ///
  /// In en, this message translates to:
  /// **'Company head'**
  String get companyWorkspaceRoleHead;

  /// No description provided for @dashboardQuarterAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Quarter analytics'**
  String get dashboardQuarterAnalytics;

  /// No description provided for @dashboardMetricsPending.
  ///
  /// In en, this message translates to:
  /// **'From reports — coming soon'**
  String get dashboardMetricsPending;

  /// No description provided for @dashboardProjectsTile.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get dashboardProjectsTile;

  /// No description provided for @dashboardCounterpartiesTile.
  ///
  /// In en, this message translates to:
  /// **'Counterparties'**
  String get dashboardCounterpartiesTile;

  /// No description provided for @dashboardDocumentsSoon.
  ///
  /// In en, this message translates to:
  /// **'Documents — coming soon'**
  String get dashboardDocumentsSoon;

  /// No description provided for @dashboardAnalyticsSettingsSoon.
  ///
  /// In en, this message translates to:
  /// **'Analytics settings — coming soon'**
  String get dashboardAnalyticsSettingsSoon;

  /// No description provided for @companyWorkspaceFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Company #{id}'**
  String companyWorkspaceFallbackName(int id);

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @roleContractor.
  ///
  /// In en, this message translates to:
  /// **'Contractor'**
  String get roleContractor;

  /// No description provided for @roleSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get roleSupplier;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @roleProjectHead.
  ///
  /// In en, this message translates to:
  /// **'Project Head'**
  String get roleProjectHead;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @participantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsTitle;

  /// No description provided for @addParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addParticipant;

  /// No description provided for @participantCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Counterparty'**
  String get participantCounterparty;

  /// No description provided for @participantRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get participantRole;

  /// No description provided for @participantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No participants yet.'**
  String get participantsEmpty;

  /// No description provided for @participantsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the add icon in the top bar.'**
  String get participantsEmptyHint;

  /// No description provided for @participantsErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load participants.'**
  String get participantsErrorLoad;

  /// No description provided for @participantAdded.
  ///
  /// In en, this message translates to:
  /// **'Participant added'**
  String get participantAdded;

  /// No description provided for @participantRemoved.
  ///
  /// In en, this message translates to:
  /// **'Participant removed'**
  String get participantRemoved;

  /// No description provided for @participantUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get participantUpdated;

  /// No description provided for @participantErrorAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add participant'**
  String get participantErrorAdd;

  /// No description provided for @participantErrorRemove.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove participant'**
  String get participantErrorRemove;

  /// No description provided for @participantErrorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update role'**
  String get participantErrorUpdate;

  /// No description provided for @participantConfirmRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this participant?'**
  String get participantConfirmRemove;

  /// No description provided for @participantRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove participant'**
  String get participantRemoveTitle;

  /// No description provided for @participantEditRole.
  ///
  /// In en, this message translates to:
  /// **'Edit role'**
  String get participantEditRole;

  /// No description provided for @participantTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get participantTransfers;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @walletPersonalFunds.
  ///
  /// In en, this message translates to:
  /// **'Personal funds'**
  String get walletPersonalFunds;

  /// No description provided for @walletAccountableFunds.
  ///
  /// In en, this message translates to:
  /// **'Accountable funds'**
  String get walletAccountableFunds;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get walletBalance;

  /// No description provided for @walletEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get walletEarned;

  /// No description provided for @walletReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get walletReceived;

  /// No description provided for @walletSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get walletSpent;

  /// No description provided for @walletErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wallet.'**
  String get walletErrorLoad;

  /// No description provided for @transfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTitle;

  /// No description provided for @createTransfer.
  ///
  /// In en, this message translates to:
  /// **'Create transfer'**
  String get createTransfer;

  /// No description provided for @transfersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transfers yet.'**
  String get transfersEmpty;

  /// No description provided for @transfersErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transfers.'**
  String get transfersErrorLoad;

  /// No description provided for @transferErrorCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create transfer'**
  String get transferErrorCreate;

  /// No description provided for @transferCreated.
  ///
  /// In en, this message translates to:
  /// **'Transfer created'**
  String get transferCreated;

  /// No description provided for @transferReceiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get transferReceiver;

  /// No description provided for @transferType.
  ///
  /// In en, this message translates to:
  /// **'Transfer type'**
  String get transferType;

  /// No description provided for @transferAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transferAmountLabel;

  /// No description provided for @transferAmountHint.
  ///
  /// In en, this message translates to:
  /// **'10000.00'**
  String get transferAmountHint;

  /// No description provided for @transferAmountError.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0, up to 2 decimal places'**
  String get transferAmountError;

  /// No description provided for @transferCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get transferCommentLabel;

  /// No description provided for @transferCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Accountable for procurement'**
  String get transferCommentHint;

  /// No description provided for @transferNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'No participants available for transfer'**
  String get transferNoParticipants;

  /// No description provided for @transferTypePersonal.
  ///
  /// In en, this message translates to:
  /// **'To settlement balance'**
  String get transferTypePersonal;

  /// No description provided for @transferTypeAccountable.
  ///
  /// In en, this message translates to:
  /// **'To accountable balance'**
  String get transferTypeAccountable;

  /// No description provided for @transferDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferDetailTitle;

  /// No description provided for @transferLifecycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle'**
  String get transferLifecycleTitle;

  /// No description provided for @transferDetailErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load transfer.'**
  String get transferDetailErrorLoad;

  /// No description provided for @transferActionError.
  ///
  /// In en, this message translates to:
  /// **'Action failed.'**
  String get transferActionError;

  /// No description provided for @transferActionCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get transferActionCommentTitle;

  /// No description provided for @transferActionApproveProjectHead.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get transferActionApproveProjectHead;

  /// No description provided for @transferActionRejectProjectHead.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get transferActionRejectProjectHead;

  /// No description provided for @transferActionResetApproval.
  ///
  /// In en, this message translates to:
  /// **'Reset approval'**
  String get transferActionResetApproval;

  /// No description provided for @transferActionSubmitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get transferActionSubmitForApproval;

  /// No description provided for @transferActionCompleteImmediate.
  ///
  /// In en, this message translates to:
  /// **'Complete now'**
  String get transferActionCompleteImmediate;

  /// No description provided for @transferActionReturnToCreated.
  ///
  /// In en, this message translates to:
  /// **'Return to Created'**
  String get transferActionReturnToCreated;

  /// No description provided for @transferActionReturnToProjectHeadApproval.
  ///
  /// In en, this message translates to:
  /// **'Return to project head approval'**
  String get transferActionReturnToProjectHeadApproval;

  /// No description provided for @transferActionCompleteWaiting.
  ///
  /// In en, this message translates to:
  /// **'Complete waiting period'**
  String get transferActionCompleteWaiting;

  /// No description provided for @transferActionRollbackCompleted.
  ///
  /// In en, this message translates to:
  /// **'Rollback completed transfer'**
  String get transferActionRollbackCompleted;

  /// No description provided for @transferActionReturnCompletedToProjectHeadApproval.
  ///
  /// In en, this message translates to:
  /// **'Return to project head approval'**
  String get transferActionReturnCompletedToProjectHeadApproval;

  /// No description provided for @transferHistoryAllProjects.
  ///
  /// In en, this message translates to:
  /// **'All accessible projects'**
  String get transferHistoryAllProjects;

  /// No description provided for @transferHistoryAuthorSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get transferHistoryAuthorSystem;

  /// No description provided for @operationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operationsTitle;

  /// No description provided for @operationTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Operation type'**
  String get operationTypeTitle;

  /// No description provided for @operationIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get operationIncome;

  /// No description provided for @operationTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get operationTransfer;

  /// No description provided for @operationReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get operationReport;

  /// No description provided for @operationIncomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Source of project funds'**
  String get operationIncomeDescription;

  /// No description provided for @operationTransferDescription.
  ///
  /// In en, this message translates to:
  /// **'Redistribute funds between participants'**
  String get operationTransferDescription;

  /// No description provided for @operationReportDescription.
  ///
  /// In en, this message translates to:
  /// **'Confirm work completed'**
  String get operationReportDescription;

  /// No description provided for @operationIncomeSoon.
  ///
  /// In en, this message translates to:
  /// **'Income will be available at the next stage'**
  String get operationIncomeSoon;

  /// No description provided for @incomeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeDetailTitle;

  /// No description provided for @incomeActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get incomeActionApprove;

  /// No description provided for @incomeActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get incomeActionReject;

  /// No description provided for @incomeActionReturn.
  ///
  /// In en, this message translates to:
  /// **'Return for review'**
  String get incomeActionReturn;

  /// No description provided for @incomeActionCompleteWaiting.
  ///
  /// In en, this message translates to:
  /// **'Complete waiting period'**
  String get incomeActionCompleteWaiting;

  /// No description provided for @incomeActionRollback.
  ///
  /// In en, this message translates to:
  /// **'Rollback income'**
  String get incomeActionRollback;

  /// No description provided for @incomeActionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send to customer'**
  String get incomeActionSubmit;

  /// No description provided for @incomeActionResetApproval.
  ///
  /// In en, this message translates to:
  /// **'Reset approval'**
  String get incomeActionResetApproval;

  /// No description provided for @operationsHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers and income across your projects'**
  String get operationsHistorySubtitle;

  /// No description provided for @operationsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No operations yet'**
  String get operationsHistoryEmpty;

  /// No description provided for @operationsHistoryTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending confirmation'**
  String get operationsHistoryTabPending;

  /// No description provided for @operationsHistoryTabAll.
  ///
  /// In en, this message translates to:
  /// **'All operations'**
  String get operationsHistoryTabAll;

  /// No description provided for @operationsHistoryEmptyPending.
  ///
  /// In en, this message translates to:
  /// **'No operations require your action'**
  String get operationsHistoryEmptyPending;

  /// No description provided for @incomeHistoryCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Project income'**
  String get incomeHistoryCardTitle;

  /// No description provided for @incomeRoleInitiator.
  ///
  /// In en, this message translates to:
  /// **'Initiator'**
  String get incomeRoleInitiator;

  /// No description provided for @incomeRoleProjectHead.
  ///
  /// In en, this message translates to:
  /// **'Project head'**
  String get incomeRoleProjectHead;

  /// No description provided for @incomeRoleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get incomeRoleCustomer;

  /// No description provided for @incomeCreated.
  ///
  /// In en, this message translates to:
  /// **'Income created'**
  String get incomeCreated;

  /// No description provided for @operationReportSoon.
  ///
  /// In en, this message translates to:
  /// **'Report will be available later'**
  String get operationReportSoon;

  /// No description provided for @operationReportNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You cannot create a report for this project with your current role.'**
  String get operationReportNoPermission;

  /// No description provided for @reportDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportDetailTitle;

  /// No description provided for @reportTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportTabDetails;

  /// No description provided for @reportTabTransfers.
  ///
  /// In en, this message translates to:
  /// **'Linked transfers'**
  String get reportTabTransfers;

  /// No description provided for @reportCustomerTotal.
  ///
  /// In en, this message translates to:
  /// **'Customer total'**
  String get reportCustomerTotal;

  /// No description provided for @reportRecipientTotal.
  ///
  /// In en, this message translates to:
  /// **'Recipient total'**
  String get reportRecipientTotal;

  /// No description provided for @reportProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get reportProfit;

  /// No description provided for @reportLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get reportLinesTitle;

  /// No description provided for @reportTransfersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No linked transfers yet.'**
  String get reportTransfersEmpty;

  /// No description provided for @reportAttachTransferButton.
  ///
  /// In en, this message translates to:
  /// **'Attach transfer'**
  String get reportAttachTransferButton;

  /// No description provided for @reportAttachTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a transfer'**
  String get reportAttachTransferTitle;

  /// No description provided for @reportAttachTransferSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by number, date (YYYY-MM-DD), or amount'**
  String get reportAttachTransferSearchHint;

  /// No description provided for @reportAttachTransferMissingNumber.
  ///
  /// In en, this message translates to:
  /// **'This transfer has no operation number yet.'**
  String get reportAttachTransferMissingNumber;

  /// No description provided for @transferAttachToReportButton.
  ///
  /// In en, this message translates to:
  /// **'Attach to report'**
  String get transferAttachToReportButton;

  /// No description provided for @transferAttachToReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a report'**
  String get transferAttachToReportTitle;

  /// No description provided for @transferAttachToReportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by number, date (YYYY-MM-DD), or amount'**
  String get transferAttachToReportSearchHint;

  /// No description provided for @transferLinkedToReport.
  ///
  /// In en, this message translates to:
  /// **'Linked to report {number}'**
  String transferLinkedToReport(String number);

  /// No description provided for @reportCreateAddCustomLine.
  ///
  /// In en, this message translates to:
  /// **'Add custom line'**
  String get reportCreateAddCustomLine;

  /// No description provided for @reportCreateAddFromPriceList.
  ///
  /// In en, this message translates to:
  /// **'From price list'**
  String get reportCreateAddFromPriceList;

  /// No description provided for @reportCreatePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview (approximate)'**
  String get reportCreatePreviewTitle;

  /// No description provided for @reportCreatePreviewRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient total'**
  String get reportCreatePreviewRecipient;

  /// No description provided for @reportCreatePreviewCustomerBase.
  ///
  /// In en, this message translates to:
  /// **'Customer (lines)'**
  String get reportCreatePreviewCustomerBase;

  /// No description provided for @reportCreatePreviewMarkup.
  ///
  /// In en, this message translates to:
  /// **'Markup'**
  String get reportCreatePreviewMarkup;

  /// No description provided for @reportCreatePreviewCustomerTotal.
  ///
  /// In en, this message translates to:
  /// **'Customer total (with markup)'**
  String get reportCreatePreviewCustomerTotal;

  /// No description provided for @reportCreatePreviewProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit (lines)'**
  String get reportCreatePreviewProfit;

  /// No description provided for @reportCreatePreviewNote.
  ///
  /// In en, this message translates to:
  /// **'Final totals are calculated on the server.'**
  String get reportCreatePreviewNote;

  /// No description provided for @reportPriceListPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Attached price lists'**
  String get reportPriceListPickerTitle;

  /// No description provided for @reportPriceListPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No positions found. Attach a price list to the project first.'**
  String get reportPriceListPickerEmpty;

  /// No description provided for @reportCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New report'**
  String get reportCreateTitle;

  /// No description provided for @reportCreateFormationTitle.
  ///
  /// In en, this message translates to:
  /// **'Report builder'**
  String get reportCreateFormationTitle;

  /// No description provided for @reportCreateProjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get reportCreateProjectLabel;

  /// No description provided for @reportCreateCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get reportCreateCommentLabel;

  /// No description provided for @reportPositionsEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Report positions'**
  String get reportPositionsEditorTitle;

  /// No description provided for @reportPositionsPriceListLabel.
  ///
  /// In en, this message translates to:
  /// **'Price list'**
  String get reportPositionsPriceListLabel;

  /// No description provided for @reportPositionsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All positions'**
  String get reportPositionsTabAll;

  /// No description provided for @reportPositionsTabAddedCount.
  ///
  /// In en, this message translates to:
  /// **'Added ({count})'**
  String reportPositionsTabAddedCount(int count);

  /// No description provided for @reportPositionsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get reportPositionsSearch;

  /// No description provided for @reportPositionsConfirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get reportPositionsConfirmSelection;

  /// No description provided for @reportPositionsGoToAdded.
  ///
  /// In en, this message translates to:
  /// **'Added tab'**
  String get reportPositionsGoToAdded;

  /// No description provided for @reportPositionsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reportPositionsDone;

  /// No description provided for @reportPositionsNoPriceLists.
  ///
  /// In en, this message translates to:
  /// **'No price lists attached to this project. Attach one in project settings.'**
  String get reportPositionsNoPriceLists;

  /// No description provided for @reportPositionsNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Select at least one position and quantity.'**
  String get reportPositionsNothingSelected;

  /// No description provided for @reportPositionsAddedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lines yet. Pick from the price list or add a custom line.'**
  String get reportPositionsAddedEmpty;

  /// No description provided for @reportPositionsAddCustomFab.
  ///
  /// In en, this message translates to:
  /// **'Custom line'**
  String get reportPositionsAddCustomFab;

  /// No description provided for @reportPositionsAddCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom line'**
  String get reportPositionsAddCustomTitle;

  /// No description provided for @reportPositionsUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit of measure'**
  String get reportPositionsUnitLabel;

  /// No description provided for @reportPositionsUnitShort.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get reportPositionsUnitShort;

  /// No description provided for @reportPositionsRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} lines · recipient {recipient}'**
  String reportPositionsRowSubtitle(int count, String recipient);

  /// No description provided for @reportManualRecipientTotal.
  ///
  /// In en, this message translates to:
  /// **'Recipient total'**
  String get reportManualRecipientTotal;

  /// No description provided for @reportManualCustomerBase.
  ///
  /// In en, this message translates to:
  /// **'Customer total (base, before markup)'**
  String get reportManualCustomerBase;

  /// No description provided for @reportAmountsLockedFromLines.
  ///
  /// In en, this message translates to:
  /// **'Totals follow selected lines'**
  String get reportAmountsLockedFromLines;

  /// No description provided for @reportManualLineTitle.
  ///
  /// In en, this message translates to:
  /// **'Work (manual totals)'**
  String get reportManualLineTitle;

  /// No description provided for @reportCreateExpenseSection.
  ///
  /// In en, this message translates to:
  /// **'Expense item'**
  String get reportCreateExpenseSection;

  /// No description provided for @reportCreateExpenseItem.
  ///
  /// In en, this message translates to:
  /// **'Expense item'**
  String get reportCreateExpenseItem;

  /// No description provided for @reportCreateRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient (counterparty)'**
  String get reportCreateRecipient;

  /// No description provided for @reportCreateOperationDate.
  ///
  /// In en, this message translates to:
  /// **'Operation date'**
  String get reportCreateOperationDate;

  /// No description provided for @reportCreateLineSection.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get reportCreateLineSection;

  /// No description provided for @reportCreateLineName.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportCreateLineName;

  /// No description provided for @reportCreateQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get reportCreateQuantity;

  /// No description provided for @reportCreateRecipientUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price (recipient)'**
  String get reportCreateRecipientUnitPrice;

  /// No description provided for @reportCreateCustomerUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price (customer)'**
  String get reportCreateCustomerUnitPrice;

  /// No description provided for @reportCreateMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Select expense item and recipient.'**
  String get reportCreateMissingFields;

  /// No description provided for @reportCreateMissingManualTotals.
  ///
  /// In en, this message translates to:
  /// **'Enter positive recipient and customer amounts, or pick positions.'**
  String get reportCreateMissingManualTotals;

  /// No description provided for @reportActionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get reportActionSubmit;

  /// No description provided for @reportActionApproveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Confirm (customer)'**
  String get reportActionApproveCustomer;

  /// No description provided for @reportActionRejectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Reject (customer)'**
  String get reportActionRejectCustomer;

  /// No description provided for @reportActionApproveProjectHead.
  ///
  /// In en, this message translates to:
  /// **'Approve (project head)'**
  String get reportActionApproveProjectHead;

  /// No description provided for @reportActionRejectProjectHead.
  ///
  /// In en, this message translates to:
  /// **'Reject (project head)'**
  String get reportActionRejectProjectHead;

  /// No description provided for @reportActionApproveSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Approve (supervisor)'**
  String get reportActionApproveSupervisor;

  /// No description provided for @reportActionRejectSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Reject (supervisor)'**
  String get reportActionRejectSupervisor;

  /// No description provided for @reportActionCompleteWaiting.
  ///
  /// In en, this message translates to:
  /// **'Complete waiting period'**
  String get reportActionCompleteWaiting;

  /// No description provided for @reportActionRollbackCompleted.
  ///
  /// In en, this message translates to:
  /// **'Rollback completed report'**
  String get reportActionRollbackCompleted;

  /// No description provided for @reportCreated.
  ///
  /// In en, this message translates to:
  /// **'Report created'**
  String get reportCreated;

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select project'**
  String get selectProject;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects available. Create a project first.'**
  String get noProjects;

  /// No description provided for @operationsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Operations (placeholder).\n\nThis screen will be implemented at the next stage.'**
  String get operationsPlaceholder;

  /// No description provided for @statusCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get statusCreated;

  /// No description provided for @statusProjectHeadApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting project head approval'**
  String get statusProjectHeadApproval;

  /// No description provided for @statusCustomerApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting customer approval'**
  String get statusCustomerApproval;

  /// No description provided for @statusWaiting24h.
  ///
  /// In en, this message translates to:
  /// **'Waiting 24 hours'**
  String get statusWaiting24h;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusRolledBack.
  ///
  /// In en, this message translates to:
  /// **'Rolled back'**
  String get statusRolledBack;

  /// No description provided for @personalWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal workspace'**
  String get personalWorkspaceTitle;

  /// No description provided for @personalWorkspacePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Supplier, contractor, and employee: companies and monthly income.'**
  String get personalWorkspacePlaceholder;

  /// No description provided for @personalIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get personalIncomeTitle;

  /// No description provided for @personalIncomePeriodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'for the whole period'**
  String get personalIncomePeriodSubtitle;

  /// No description provided for @personalTop5Title.
  ///
  /// In en, this message translates to:
  /// **'Top 5'**
  String get personalTop5Title;

  /// No description provided for @personalShowAllLink.
  ///
  /// In en, this message translates to:
  /// **'Show all >'**
  String get personalShowAllLink;

  /// No description provided for @personalRoleInCompany.
  ///
  /// In en, this message translates to:
  /// **'Role in company'**
  String get personalRoleInCompany;

  /// No description provided for @personalWorkspaceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No companies yet.'**
  String get personalWorkspaceEmpty;

  /// No description provided for @personalWorkspaceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load personal workspace.'**
  String get personalWorkspaceLoadError;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'TODO: notifications'**
  String get notificationsComingSoon;

  /// No description provided for @openCustomerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Customer workspace'**
  String get openCustomerWorkspace;

  /// No description provided for @customerWorkspaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Projects where you are the customer'**
  String get customerWorkspaceSubtitle;

  /// No description provided for @customerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get customerHomeTitle;

  /// No description provided for @customerAllProjects.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get customerAllProjects;

  /// No description provided for @customerDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get customerDocuments;

  /// No description provided for @customerCompaniesTitle.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get customerCompaniesTitle;

  /// No description provided for @customerProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get customerProjectsTitle;

  /// No description provided for @customerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get customerSearchHint;

  /// No description provided for @customerTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customerTabActive;

  /// No description provided for @customerTabInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get customerTabInactive;

  /// No description provided for @customerTabClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get customerTabClosed;

  /// No description provided for @customerReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get customerReceived;

  /// No description provided for @customerSpentAccumulated.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get customerSpentAccumulated;

  /// No description provided for @customerBalancePersonal.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get customerBalancePersonal;

  /// No description provided for @customerDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get customerDebt;

  /// No description provided for @customerProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get customerProgress;

  /// No description provided for @customerProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String customerProgressPercent(int percent);

  /// No description provided for @customerProjectsTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} projects'**
  String customerProjectsTotalCount(int count);

  /// No description provided for @customerAwaitingBadge.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get customerAwaitingBadge;

  /// No description provided for @customerDocumentsSoon.
  ///
  /// In en, this message translates to:
  /// **'Documents will be available later.'**
  String get customerDocumentsSoon;

  /// No description provided for @customerOperationsHistorySoon.
  ///
  /// In en, this message translates to:
  /// **'Operation history will be available later.'**
  String get customerOperationsHistorySoon;

  /// No description provided for @customerNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet.'**
  String get customerNoData;

  /// No description provided for @customerErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data.'**
  String get customerErrorLoad;

  /// No description provided for @projectDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectDetailTitle;

  /// No description provided for @projectMetricsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Project metrics'**
  String get projectMetricsSectionTitle;

  /// No description provided for @projectIncomeMetric.
  ///
  /// In en, this message translates to:
  /// **'Income received'**
  String get projectIncomeMetric;

  /// No description provided for @projectExpenseMetric.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get projectExpenseMetric;

  /// No description provided for @projectBalanceMetric.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get projectBalanceMetric;

  /// No description provided for @projectParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get projectParticipants;

  /// No description provided for @projectOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get projectOperations;

  /// No description provided for @projectExpenseArticles.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get projectExpenseArticles;

  /// No description provided for @projectDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get projectDocuments;

  /// No description provided for @projectStatus.
  ///
  /// In en, this message translates to:
  /// **'Project status'**
  String get projectStatus;

  /// No description provided for @projectInternalDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Project internals'**
  String get projectInternalDataTitle;

  /// No description provided for @participantsAccountableBalance.
  ///
  /// In en, this message translates to:
  /// **'Participants accountable balance'**
  String get participantsAccountableBalance;

  /// No description provided for @projectDebtToCounterparties.
  ///
  /// In en, this message translates to:
  /// **'Debt to counterparties'**
  String get projectDebtToCounterparties;

  /// No description provided for @projectOverpaymentOrMissingReports.
  ///
  /// In en, this message translates to:
  /// **'Overpayment or missing reports'**
  String get projectOverpaymentOrMissingReports;

  /// No description provided for @projectComingSoonSnippet.
  ///
  /// In en, this message translates to:
  /// **'This section will be available later.'**
  String get projectComingSoonSnippet;

  /// No description provided for @projectHistoryOperations.
  ///
  /// In en, this message translates to:
  /// **'Operation history'**
  String get projectHistoryOperations;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get navOperations;

  /// No description provided for @personalOperationsProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers by project'**
  String get personalOperationsProjectsTitle;

  /// No description provided for @personalOperationsNoTransferProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects where you can create a transfer.'**
  String get personalOperationsNoTransferProjects;

  /// No description provided for @expenseItemsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No expense categories yet.'**
  String get expenseItemsEmptyState;

  /// No description provided for @createExpenseItem.
  ///
  /// In en, this message translates to:
  /// **'Create expense category'**
  String get createExpenseItem;

  /// No description provided for @editExpenseItem.
  ///
  /// In en, this message translates to:
  /// **'Edit expense category'**
  String get editExpenseItem;

  /// No description provided for @expenseItemName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get expenseItemName;

  /// No description provided for @profitShares.
  ///
  /// In en, this message translates to:
  /// **'Profit shares'**
  String get profitShares;

  /// No description provided for @addProfitRecipient.
  ///
  /// In en, this message translates to:
  /// **'Add recipients'**
  String get addProfitRecipient;

  /// No description provided for @markupOnExpenseItem.
  ///
  /// In en, this message translates to:
  /// **'Markup on category'**
  String get markupOnExpenseItem;

  /// No description provided for @markupPercent.
  ///
  /// In en, this message translates to:
  /// **'Markup percent'**
  String get markupPercent;

  /// No description provided for @markupShares.
  ///
  /// In en, this message translates to:
  /// **'Markup shares'**
  String get markupShares;

  /// No description provided for @addMarkupRecipient.
  ///
  /// In en, this message translates to:
  /// **'Add markup recipients'**
  String get addMarkupRecipient;

  /// No description provided for @recipients.
  ///
  /// In en, this message translates to:
  /// **'Recipients'**
  String get recipients;

  /// No description provided for @companyCounterpartiesTab.
  ///
  /// In en, this message translates to:
  /// **'Company counterparties'**
  String get companyCounterpartiesTab;

  /// No description provided for @markupDisabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Markup off'**
  String get markupDisabledLabel;

  /// No description provided for @expenseItemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a category name.'**
  String get expenseItemNameRequired;

  /// No description provided for @profitRecipientsRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one profit recipient.'**
  String get profitRecipientsRequired;

  /// No description provided for @markupRecipientsRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one markup recipient.'**
  String get markupRecipientsRequired;

  /// No description provided for @markupPercentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter markup percent with two decimal places (step 0.01%).'**
  String get markupPercentInvalid;

  /// No description provided for @percentFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Use two decimal places for shares (e.g. 33.33).'**
  String get percentFormatHint;

  /// No description provided for @percentHintShort.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get percentHintShort;

  /// No description provided for @deleteExpenseItem.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteExpenseItem;

  /// No description provided for @deleteExpenseItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense category? This cannot be undone in the app.'**
  String get deleteExpenseItemConfirm;

  /// No description provided for @profitSharesMustEqualHundred.
  ///
  /// In en, this message translates to:
  /// **'Profit shares must total exactly 100.00%.'**
  String get profitSharesMustEqualHundred;

  /// No description provided for @markupSharesMustEqualHundred.
  ///
  /// In en, this message translates to:
  /// **'Markup shares must total exactly 100.00%.'**
  String get markupSharesMustEqualHundred;

  /// No description provided for @expenseItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense category deleted.'**
  String get expenseItemDeleted;

  /// No description provided for @priceListsTitle.
  ///
  /// In en, this message translates to:
  /// **'Price lists'**
  String get priceListsTitle;

  /// No description provided for @dashboardDocumentsPriceLists.
  ///
  /// In en, this message translates to:
  /// **'Price lists'**
  String get dashboardDocumentsPriceLists;

  /// No description provided for @projectPriceLists.
  ///
  /// In en, this message translates to:
  /// **'Price lists'**
  String get projectPriceLists;

  /// No description provided for @priceListName.
  ///
  /// In en, this message translates to:
  /// **'Price list name'**
  String get priceListName;

  /// No description provided for @priceListCreator.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get priceListCreator;

  /// No description provided for @priceListGroupsCount.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get priceListGroupsCount;

  /// No description provided for @priceListPositionsCount.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get priceListPositionsCount;

  /// No description provided for @createPriceList.
  ///
  /// In en, this message translates to:
  /// **'Create price list'**
  String get createPriceList;

  /// No description provided for @editPriceList.
  ///
  /// In en, this message translates to:
  /// **'Edit price list'**
  String get editPriceList;

  /// No description provided for @deletePriceList.
  ///
  /// In en, this message translates to:
  /// **'Delete price list'**
  String get deletePriceList;

  /// No description provided for @deletePriceListConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this price list?'**
  String get deletePriceListConfirm;

  /// No description provided for @priceListDeleteProjectsWarning.
  ///
  /// In en, this message translates to:
  /// **'This price list is attached to {count} project(s). It will be detached and become unavailable.'**
  String priceListDeleteProjectsWarning(int count);

  /// No description provided for @partnerAlreadyHasPriceList.
  ///
  /// In en, this message translates to:
  /// **'You already have a price list in this company — delete or edit the existing one.'**
  String get partnerAlreadyHasPriceList;

  /// No description provided for @partnerNotProjectHeadPriceList.
  ///
  /// In en, this message translates to:
  /// **'Only a project lead (partner) can create a company price list.'**
  String get partnerNotProjectHeadPriceList;

  /// No description provided for @priceListGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups / sections'**
  String get priceListGroups;

  /// No description provided for @createPriceListGroup.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get createPriceListGroup;

  /// No description provided for @editPriceListGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editPriceListGroup;

  /// No description provided for @deletePriceListGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deletePriceListGroup;

  /// No description provided for @deletePriceListGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this group and its positions?'**
  String get deletePriceListGroupConfirm;

  /// No description provided for @priceListPositions.
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get priceListPositions;

  /// No description provided for @createPriceListPosition.
  ///
  /// In en, this message translates to:
  /// **'Add line item'**
  String get createPriceListPosition;

  /// No description provided for @editPriceListPosition.
  ///
  /// In en, this message translates to:
  /// **'Edit line item'**
  String get editPriceListPosition;

  /// No description provided for @deletePriceListPosition.
  ///
  /// In en, this message translates to:
  /// **'Delete line item'**
  String get deletePriceListPosition;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get serviceName;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @recipientUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Recipient price per unit'**
  String get recipientUnitPrice;

  /// No description provided for @customerUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Customer price per unit'**
  String get customerUnitPrice;

  /// No description provided for @profitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profitLabel;

  /// No description provided for @profitPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit %'**
  String get profitPercentLabel;

  /// No description provided for @selectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select unit'**
  String get selectUnit;

  /// No description provided for @attachPriceLists.
  ///
  /// In en, this message translates to:
  /// **'Attach price lists'**
  String get attachPriceLists;

  /// No description provided for @availablePriceLists.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availablePriceLists;

  /// No description provided for @attachSelected.
  ///
  /// In en, this message translates to:
  /// **'Attach selected'**
  String get attachSelected;

  /// No description provided for @detachPriceList.
  ///
  /// In en, this message translates to:
  /// **'Detach'**
  String get detachPriceList;

  /// No description provided for @priceListsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No price lists yet.'**
  String get priceListsEmpty;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
