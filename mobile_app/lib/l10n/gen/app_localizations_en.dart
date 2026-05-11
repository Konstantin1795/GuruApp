// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GURU';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Retry';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get loadMore => 'Load more';

  @override
  String get loading => 'Loading...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorValidation => 'Please check the entered data.';

  @override
  String get errorNetwork => 'Connection error. Check your internet.';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get authWelcome => 'Welcome back';

  @override
  String get authWelcomeSubtitle => 'Sign in to continue';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authSignUpSubtitle => 'Start using GURU';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authName => 'Name';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authLoginFailed => 'Login failed. Check your credentials.';

  @override
  String get authRegisterFailed => 'Registration failed.';

  @override
  String get workspacesTitle => 'Workspaces';

  @override
  String get workspaceChoose => 'Choose a workspace';

  @override
  String get workspaceCompany => 'Company workspace';

  @override
  String get workspacePersonal => 'Personal workspace';

  @override
  String get workspacesEmpty => 'No workspaces available yet.';

  @override
  String get workspacesErrorLoad => 'Failed to load workspaces.';

  @override
  String get openPersonal => 'Open personal workspace';

  @override
  String personalRoles(String roles) {
    return 'Roles: $roles';
  }

  @override
  String get logout => 'Logout';

  @override
  String get createCompanyTitle => 'Create company';

  @override
  String get createCompanyHeading => 'New company';

  @override
  String get createCompanySubtitle => 'You will become OWNER';

  @override
  String get companyNameLabel => 'Company name';

  @override
  String get companyCreateError => 'Failed to create company.';

  @override
  String get dashboardAnalytics => 'Quarter analytics';

  @override
  String get dashboardIncome => 'Income';

  @override
  String get dashboardDebt => 'Debt';

  @override
  String get dashboardOverpayment => 'Overpayment';

  @override
  String get dashboardActiveProjects => 'Active projects';

  @override
  String get dashboardDocuments => 'Documents';

  @override
  String get dashboardHistory => 'Operations history';

  @override
  String get dashboardAwaitingConfirmation => 'Awaiting confirmation';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get createProject => 'Create project';

  @override
  String get projectNameLabel => 'Project name';

  @override
  String get projectCustomerLabel => 'Customer';

  @override
  String get projectNoCustomer => 'Add a customer first';

  @override
  String get projectsEmpty => 'No projects yet.';

  @override
  String get projectsErrorLoad => 'Failed to load projects.';

  @override
  String projectProgress(int percent) {
    return 'Progress: $percent%';
  }

  @override
  String get projectInactive => 'inactive';

  @override
  String get projectCreated => 'Project created';

  @override
  String get projectErrorCreate => 'Failed to create project';

  @override
  String projectTotal(int count) {
    return 'Total: $count';
  }

  @override
  String get counterpartiesTitle => 'Counterparties';

  @override
  String get addCounterparty => 'Add counterparty';

  @override
  String get counterpartyFullName => 'Full name';

  @override
  String get counterpartyEmail => 'Email';

  @override
  String get counterpartyRole => 'Role';

  @override
  String get counterpartiesEmpty => 'No counterparties yet.';

  @override
  String get counterpartiesErrorLoad => 'Failed to load counterparties.';

  @override
  String get counterpartyAdded => 'Counterparty added';

  @override
  String get counterpartyErrorCreate => 'Create error';

  @override
  String get counterpartyEnterName => 'Enter full name';

  @override
  String get counterpartyEnterEmail => 'Enter email';

  @override
  String get counterpartySearch => 'Search by name…';

  @override
  String counterpartyTotal(int count) {
    return 'Total: $count';
  }

  @override
  String get roleOwner => 'Owner';

  @override
  String get rolePartner => 'Partner';

  @override
  String get companyWorkspaceRoleHead => 'Company head';

  @override
  String get dashboardQuarterAnalytics => 'Quarter analytics';

  @override
  String get dashboardMetricsPending => 'From reports — coming soon';

  @override
  String get dashboardProjectsTile => 'Projects';

  @override
  String get dashboardCounterpartiesTile => 'Counterparties';

  @override
  String get dashboardDocumentsSoon => 'Documents — coming soon';

  @override
  String get dashboardAnalyticsSettingsSoon =>
      'Analytics settings — coming soon';

  @override
  String companyWorkspaceFallbackName(int id) {
    return 'Company #$id';
  }

  @override
  String get roleEmployee => 'Employee';

  @override
  String get roleContractor => 'Contractor';

  @override
  String get roleSupplier => 'Supplier';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleProjectHead => 'Project Head';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get participantsTitle => 'Participants';

  @override
  String get addParticipant => 'Add';

  @override
  String get participantCounterparty => 'Counterparty';

  @override
  String get participantRole => 'Role';

  @override
  String get participantsEmpty => 'No participants yet.';

  @override
  String get participantsEmptyHint => 'Tap the add icon in the top bar.';

  @override
  String get participantsErrorLoad => 'Failed to load participants.';

  @override
  String get participantAdded => 'Participant added';

  @override
  String get participantRemoved => 'Participant removed';

  @override
  String get participantUpdated => 'Role updated';

  @override
  String get participantErrorAdd => 'Failed to add participant';

  @override
  String get participantErrorRemove => 'Failed to remove participant';

  @override
  String get participantErrorUpdate => 'Failed to update role';

  @override
  String get participantConfirmRemove => 'Remove this participant?';

  @override
  String get participantRemoveTitle => 'Remove participant';

  @override
  String get participantEditRole => 'Edit role';

  @override
  String get participantTransfers => 'Transfers';

  @override
  String get walletTitle => 'Wallet';

  @override
  String get walletPersonalFunds => 'Personal funds';

  @override
  String get walletAccountableFunds => 'Accountable funds';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletEarned => 'Earned';

  @override
  String get walletReceived => 'Received';

  @override
  String get walletSpent => 'Spent';

  @override
  String get walletErrorLoad => 'Failed to load wallet.';

  @override
  String get transfersTitle => 'Transfers';

  @override
  String get createTransfer => 'Create transfer';

  @override
  String get transfersEmpty => 'No transfers yet.';

  @override
  String get transfersErrorLoad => 'Failed to load transfers.';

  @override
  String get transferErrorCreate => 'Failed to create transfer';

  @override
  String get transferCreated => 'Transfer created';

  @override
  String get transferReceiver => 'Receiver';

  @override
  String get transferType => 'Transfer type';

  @override
  String get transferAmountLabel => 'Amount';

  @override
  String get transferAmountHint => '10000.00';

  @override
  String get transferAmountError =>
      'Enter an amount greater than 0, up to 2 decimal places';

  @override
  String get transferCommentLabel => 'Comment';

  @override
  String get transferCommentHint => 'Accountable for procurement';

  @override
  String get transferNoParticipants => 'No participants available for transfer';

  @override
  String get transferTypePersonal => 'To settlement balance';

  @override
  String get transferTypeAccountable => 'To accountable balance';

  @override
  String get transferDetailTitle => 'Transfer';

  @override
  String get transferLifecycleTitle => 'Lifecycle';

  @override
  String get transferDetailErrorLoad => 'Could not load transfer.';

  @override
  String get transferActionError => 'Action failed.';

  @override
  String get transferActionCommentTitle => 'Comment';

  @override
  String get transferActionApproveProjectHead => 'Approve';

  @override
  String get transferActionRejectProjectHead => 'Reject';

  @override
  String get transferActionResetApproval => 'Reset approval';

  @override
  String get transferActionSubmitForApproval => 'Submit for approval';

  @override
  String get transferActionCompleteImmediate => 'Complete now';

  @override
  String get transferActionReturnToCreated => 'Return to Created';

  @override
  String get transferActionReturnToProjectHeadApproval =>
      'Return to project head approval';

  @override
  String get transferActionCompleteWaiting => 'Complete waiting period';

  @override
  String get transferActionRollbackCompleted => 'Rollback completed transfer';

  @override
  String get transferActionReturnCompletedToProjectHeadApproval =>
      'Return to project head approval';

  @override
  String get transferHistoryAllProjects => 'All accessible projects';

  @override
  String get transferHistoryAuthorSystem => 'System';

  @override
  String get operationsTitle => 'Operations';

  @override
  String get operationTypeTitle => 'Operation type';

  @override
  String get operationIncome => 'Income';

  @override
  String get operationTransfer => 'Transfer';

  @override
  String get operationReport => 'Report';

  @override
  String get operationIncomeDescription => 'Source of project funds';

  @override
  String get operationTransferDescription =>
      'Redistribute funds between participants';

  @override
  String get operationReportDescription => 'Confirm work completed';

  @override
  String get operationIncomeSoon =>
      'Income will be available at the next stage';

  @override
  String get operationReportSoon => 'Report will be available later';

  @override
  String get selectProject => 'Select project';

  @override
  String get noProjects => 'No projects available. Create a project first.';

  @override
  String get operationsPlaceholder =>
      'Operations (placeholder).\n\nThis screen will be implemented at the next stage.';

  @override
  String get statusCreated => 'Created';

  @override
  String get statusProjectHeadApproval => 'Awaiting project head approval';

  @override
  String get statusCustomerApproval => 'Awaiting customer approval';

  @override
  String get statusWaiting24h => 'Waiting 24 hours';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusRolledBack => 'Rolled back';

  @override
  String get personalWorkspaceTitle => 'Personal workspace';

  @override
  String get personalWorkspacePlaceholder =>
      'Supplier, contractor, and employee: companies and monthly income.';

  @override
  String get personalIncomeTitle => 'Income';

  @override
  String get personalIncomePeriodSubtitle => 'for the whole period';

  @override
  String get personalTop5Title => 'Top 5';

  @override
  String get personalShowAllLink => 'Show all >';

  @override
  String get personalRoleInCompany => 'Role in company';

  @override
  String get personalWorkspaceEmpty => 'No companies yet.';

  @override
  String get personalWorkspaceLoadError => 'Failed to load personal workspace.';

  @override
  String get notificationsComingSoon => 'TODO: notifications';

  @override
  String get openCustomerWorkspace => 'Customer workspace';

  @override
  String get customerWorkspaceSubtitle => 'Projects where you are the customer';

  @override
  String get customerHomeTitle => 'Home';

  @override
  String get customerAllProjects => 'All projects';

  @override
  String get customerDocuments => 'Documents';

  @override
  String get customerCompaniesTitle => 'Companies';

  @override
  String get customerProjectsTitle => 'Projects';

  @override
  String get customerSearchHint => 'Search';

  @override
  String get customerTabActive => 'Active';

  @override
  String get customerTabInactive => 'Inactive';

  @override
  String get customerTabClosed => 'Closed';

  @override
  String get customerReceived => 'Received';

  @override
  String get customerSpentAccumulated => 'Spent';

  @override
  String get customerBalancePersonal => 'Balance';

  @override
  String get customerDebt => 'Debt';

  @override
  String get customerProgress => 'Progress';

  @override
  String customerProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String customerProjectsTotalCount(int count) {
    return '$count projects';
  }

  @override
  String get customerAwaitingBadge => 'Awaiting confirmation';

  @override
  String get customerDocumentsSoon => 'Documents will be available later.';

  @override
  String get customerOperationsHistorySoon =>
      'Operation history will be available later.';

  @override
  String get customerNoData => 'No data yet.';

  @override
  String get customerErrorLoad => 'Failed to load data.';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navOperations => 'Operations';

  @override
  String get personalOperationsProjectsTitle => 'Transfers by project';

  @override
  String get personalOperationsNoTransferProjects =>
      'No projects where you can create a transfer.';
}
