// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'GURU';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get create => 'Создать';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get retry => 'Повторить';

  @override
  String get add => 'Добавить';

  @override
  String get remove => 'Удалить';

  @override
  String get close => 'Закрыть';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get loadMore => 'Загрузить ещё';

  @override
  String get loading => 'Загрузка...';

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get errorValidation => 'Проверьте введённые данные.';

  @override
  String get errorNetwork => 'Ошибка соединения. Проверьте интернет.';

  @override
  String get language => 'Язык';

  @override
  String get changeLanguage => 'Изменить язык';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get authWelcome => 'Добро пожаловать';

  @override
  String get authWelcomeSubtitle => 'Войдите в аккаунт';

  @override
  String get authSignIn => 'Войти';

  @override
  String get authSignUp => 'Создать аккаунт';

  @override
  String get authSignUpTitle => 'Создать аккаунт';

  @override
  String get authSignUpSubtitle => 'Начните использовать GURU';

  @override
  String get authBackToLogin => 'Назад к входу';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authName => 'Имя';

  @override
  String get authConfirmPassword => 'Подтвердите пароль';

  @override
  String get authLoginFailed => 'Ошибка входа. Проверьте данные.';

  @override
  String get authRegisterFailed => 'Ошибка регистрации.';

  @override
  String get workspacesTitle => 'Рабочие пространства';

  @override
  String get workspaceChoose => 'Выберите пространство';

  @override
  String get workspaceCompany => 'Компания';

  @override
  String get workspacePersonal => 'Личное пространство';

  @override
  String get workspacesEmpty => 'Рабочих пространств пока нет.';

  @override
  String get workspacesErrorLoad => 'Не удалось загрузить пространства.';

  @override
  String get openPersonal => 'Открыть личное пространство';

  @override
  String personalRoles(String roles) {
    return 'Роли: $roles';
  }

  @override
  String get logout => 'Выйти';

  @override
  String get createCompanyTitle => 'Создать компанию';

  @override
  String get createCompanyHeading => 'Новая компания';

  @override
  String get createCompanySubtitle => 'Вы станете владельцем';

  @override
  String get companyNameLabel => 'Название компании';

  @override
  String get companyCreateError => 'Не удалось создать компанию.';

  @override
  String get dashboardAnalytics => 'Аналитика за квартал';

  @override
  String get dashboardIncome => 'Доход';

  @override
  String get dashboardDebt => 'Задолженность';

  @override
  String get dashboardOverpayment => 'Переплата';

  @override
  String get dashboardActiveProjects => 'Активные проекты';

  @override
  String get dashboardDocuments => 'Документы';

  @override
  String get dashboardHistory => 'История операций';

  @override
  String get dashboardAwaitingConfirmation => 'Ожидают подтверждения';

  @override
  String get projectsTitle => 'Проекты';

  @override
  String get createProject => 'Создать проект';

  @override
  String get projectNameLabel => 'Название проекта';

  @override
  String get projectCustomerLabel => 'Заказчик';

  @override
  String get projectNoCustomer => 'Сначала добавьте заказчика';

  @override
  String get projectsEmpty => 'Проектов пока нет.';

  @override
  String get projectsErrorLoad => 'Не удалось загрузить проекты.';

  @override
  String projectProgress(int percent) {
    return 'Прогресс: $percent%';
  }

  @override
  String get projectInactive => 'неактивен';

  @override
  String get projectCreated => 'Проект создан';

  @override
  String get projectErrorCreate => 'Не удалось создать проект';

  @override
  String projectTotal(int count) {
    return 'Всего: $count';
  }

  @override
  String get counterpartiesTitle => 'Контрагенты';

  @override
  String get addCounterparty => 'Добавить контрагента';

  @override
  String get counterpartyFullName => 'ФИО';

  @override
  String get counterpartyEmail => 'Email';

  @override
  String get counterpartyRole => 'Роль';

  @override
  String get counterpartiesEmpty => 'Контрагентов пока нет.';

  @override
  String get counterpartiesErrorLoad => 'Не удалось загрузить контрагентов.';

  @override
  String get counterpartyAdded => 'Контрагент добавлен';

  @override
  String get counterpartyErrorCreate => 'Ошибка создания';

  @override
  String get counterpartyEnterName => 'Введите ФИО';

  @override
  String get counterpartyEnterEmail => 'Введите email';

  @override
  String get counterpartySearch => 'Поиск по имени…';

  @override
  String counterpartyTotal(int count) {
    return 'Всего: $count';
  }

  @override
  String get roleOwner => 'Владелец';

  @override
  String get rolePartner => 'Партнёр';

  @override
  String get companyWorkspaceRoleHead => 'Руководитель компании';

  @override
  String get dashboardQuarterAnalytics => 'Аналитика за квартал';

  @override
  String get dashboardMetricsPending => 'Данные отчёта — позже';

  @override
  String get dashboardProjectsTile => 'Проекты';

  @override
  String get dashboardCounterpartiesTile => 'Контрагенты';

  @override
  String get dashboardDocumentsSoon => 'Документы — скоро';

  @override
  String get dashboardAnalyticsSettingsSoon => 'Настройки аналитики — скоро';

  @override
  String companyWorkspaceFallbackName(int id) {
    return 'Компания №$id';
  }

  @override
  String get roleEmployee => 'Сотрудник';

  @override
  String get roleContractor => 'Подрядчик';

  @override
  String get roleSupplier => 'Поставщик';

  @override
  String get roleCustomer => 'Заказчик';

  @override
  String get roleProjectHead => 'Руководитель проекта';

  @override
  String get roleSupervisor => 'Куратор';

  @override
  String get participantsTitle => 'Участники';

  @override
  String get addParticipant => 'Добавить';

  @override
  String get participantCounterparty => 'Контрагент';

  @override
  String get participantRole => 'Роль';

  @override
  String get participantsEmpty => 'Участников пока нет.';

  @override
  String get participantsEmptyHint =>
      'Нажмите значок добавления участника вверху справа.';

  @override
  String get participantsErrorLoad => 'Не удалось загрузить участников.';

  @override
  String get participantAdded => 'Участник добавлен';

  @override
  String get participantRemoved => 'Участник удалён';

  @override
  String get participantUpdated => 'Роль обновлена';

  @override
  String get participantErrorAdd => 'Не удалось добавить участника';

  @override
  String get participantErrorRemove => 'Не удалось удалить участника';

  @override
  String get participantErrorUpdate => 'Не удалось обновить роль';

  @override
  String get participantConfirmRemove => 'Удалить этого участника?';

  @override
  String get participantRemoveTitle => 'Удалить участника';

  @override
  String get participantEditRole => 'Изменить роль';

  @override
  String get participantTransfers => 'Переводы';

  @override
  String get walletTitle => 'Кошелёк';

  @override
  String get walletPersonalFunds => 'Личные средства';

  @override
  String get walletAccountableFunds => 'Подотчётные средства';

  @override
  String get walletBalance => 'Баланс';

  @override
  String get walletEarned => 'Заработано';

  @override
  String get walletReceived => 'Получено';

  @override
  String get walletSpent => 'Потрачено';

  @override
  String get walletErrorLoad => 'Не удалось загрузить кошелёк.';

  @override
  String get transfersTitle => 'Переводы';

  @override
  String get createTransfer => 'Создать перевод';

  @override
  String get transfersEmpty => 'Переводов пока нет.';

  @override
  String get transfersErrorLoad => 'Не удалось загрузить переводы.';

  @override
  String get transferErrorCreate => 'Не удалось создать перевод';

  @override
  String get transferCreated => 'Перевод создан';

  @override
  String get transferReceiver => 'Получатель';

  @override
  String get transferType => 'Тип перевода';

  @override
  String get transferAmountLabel => 'Сумма';

  @override
  String get transferAmountHint => '10000.00';

  @override
  String get transferAmountError =>
      'Введите сумму больше 0, до 2 знаков после точки';

  @override
  String get transferCommentLabel => 'Комментарий';

  @override
  String get transferCommentHint => 'Подотчёт на закупку';

  @override
  String get transferNoParticipants => 'Нет участников для перевода';

  @override
  String get transferTypePersonal => 'На расчётный баланс';

  @override
  String get transferTypeAccountable => 'На подотчётный баланс';

  @override
  String get transferDetailTitle => 'Перевод';

  @override
  String get transferLifecycleTitle => 'Ход операции';

  @override
  String get transferDetailErrorLoad => 'Не удалось загрузить перевод.';

  @override
  String get transferActionError => 'Не удалось выполнить действие.';

  @override
  String get transferActionCommentTitle => 'Комментарий к действию';

  @override
  String get transferActionApproveProjectHead => 'Подтвердить';

  @override
  String get transferActionRejectProjectHead => 'Отклонить';

  @override
  String get transferActionResetApproval => 'Сбросить согласование';

  @override
  String get transferActionSubmitForApproval => 'Отправить на согласование РП';

  @override
  String get transferActionCompleteImmediate => 'Завершить перевод';

  @override
  String get transferActionReturnToCreated => 'Вернуть в статус «Создана»';

  @override
  String get transferActionReturnToProjectHeadApproval =>
      'Вернуть на согласование РП';

  @override
  String get transferActionCompleteWaiting => 'Завершить период ожидания';

  @override
  String get transferActionRollbackCompleted => 'Откатить перевод';

  @override
  String get transferActionReturnCompletedToProjectHeadApproval =>
      'Вернуть на согласование РП';

  @override
  String get transferHistoryAllProjects => 'Все доступные проекты';

  @override
  String get transferHistoryAuthorSystem => 'Система';

  @override
  String get operationsTitle => 'Операции';

  @override
  String get operationTypeTitle => 'Тип операции';

  @override
  String get operationIncome => 'Поступление';

  @override
  String get operationTransfer => 'Перевод';

  @override
  String get operationReport => 'Отчёт';

  @override
  String get operationIncomeDescription => 'Источник средств проекта';

  @override
  String get operationTransferDescription =>
      'Перераспределение средств между участниками';

  @override
  String get operationReportDescription => 'Подтверждение выполненных работ';

  @override
  String get operationIncomeSoon => 'Будет доступно на следующем этапе';

  @override
  String get incomeDetailTitle => 'Поступление';

  @override
  String get incomeActionApprove => 'Подтвердить';

  @override
  String get incomeActionReject => 'Отклонить';

  @override
  String get incomeActionReturn => 'Вернуть на проверку';

  @override
  String get incomeActionCompleteWaiting => 'Завершить период ожидания';

  @override
  String get incomeActionRollback => 'Откатить поступление';

  @override
  String get incomeActionSubmit => 'Отправить заказчику';

  @override
  String get incomeActionResetApproval => 'Сбросить подтверждение';

  @override
  String get operationsHistorySubtitle =>
      'Переводы и поступления по доступным проектам';

  @override
  String get operationsHistoryEmpty => 'Нет операций';

  @override
  String get incomeHistoryCardTitle => 'Поступление средств';

  @override
  String get incomeRoleInitiator => 'Инициатор';

  @override
  String get incomeRoleProjectHead => 'Руководитель проекта';

  @override
  String get incomeRoleCustomer => 'Заказчик';

  @override
  String get incomeCreated => 'Поступление создано';

  @override
  String get operationReportSoon => 'Будет доступно позже';

  @override
  String get selectProject => 'Выберите проект';

  @override
  String get noProjects => 'Нет доступных проектов. Создайте проект сначала.';

  @override
  String get operationsPlaceholder =>
      'Операции (плейсхолдер).\n\nЭкран будет реализован на следующем этапе.';

  @override
  String get statusCreated => 'Создана';

  @override
  String get statusProjectHeadApproval => 'Ожидает подтверждения РП';

  @override
  String get statusCustomerApproval => 'Ожидает подтверждения заказчика';

  @override
  String get statusWaiting24h => 'Ожидание 24 часа';

  @override
  String get statusCompleted => 'Завершена';

  @override
  String get statusRejected => 'Отклонена';

  @override
  String get statusRolledBack => 'Отменена';

  @override
  String get personalWorkspaceTitle => 'Личное пространство';

  @override
  String get personalWorkspacePlaceholder =>
      'Поставщик, подрядчик и сотрудник: компании и доход по месяцам.';

  @override
  String get personalIncomeTitle => 'Доход';

  @override
  String get personalIncomePeriodSubtitle => 'за весь период';

  @override
  String get personalTop5Title => 'Топ 5';

  @override
  String get personalShowAllLink => 'Показать все >';

  @override
  String get personalRoleInCompany => 'Роль в компании';

  @override
  String get personalWorkspaceEmpty => 'Пока нет компаний.';

  @override
  String get personalWorkspaceLoadError =>
      'Не удалось загрузить личный кабинет.';

  @override
  String get notificationsComingSoon => 'TODO: уведомления';

  @override
  String get openCustomerWorkspace => 'Кабинет заказчика';

  @override
  String get customerWorkspaceSubtitle =>
      'Проекты, где вы указаны как заказчик';

  @override
  String get customerHomeTitle => 'Главная';

  @override
  String get customerAllProjects => 'Все проекты';

  @override
  String get customerDocuments => 'Документы';

  @override
  String get customerCompaniesTitle => 'Компании';

  @override
  String get customerProjectsTitle => 'Проекты';

  @override
  String get customerSearchHint => 'Поиск';

  @override
  String get customerTabActive => 'Активные';

  @override
  String get customerTabInactive => 'Не активные';

  @override
  String get customerTabClosed => 'Закрытые';

  @override
  String get customerReceived => 'Поступило';

  @override
  String get customerSpentAccumulated => 'Израсходовано';

  @override
  String get customerBalancePersonal => 'Баланс';

  @override
  String get customerDebt => 'Задолженность';

  @override
  String get customerProgress => 'Прогресс';

  @override
  String customerProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String customerProjectsTotalCount(int count) {
    return '$count проектов';
  }

  @override
  String get customerAwaitingBadge => 'Ожидают подтверждения';

  @override
  String get customerDocumentsSoon => 'Раздел документов появится позже.';

  @override
  String get customerOperationsHistorySoon =>
      'История операций появится позже.';

  @override
  String get customerNoData => 'Пока нет данных.';

  @override
  String get customerErrorLoad => 'Не удалось загрузить данные.';

  @override
  String get navNotifications => 'Уведомления';

  @override
  String get navOperations => 'Операции';

  @override
  String get personalOperationsProjectsTitle => 'Переводы по проектам';

  @override
  String get personalOperationsNoTransferProjects =>
      'Нет проектов, где доступно создание перевода.';
}
