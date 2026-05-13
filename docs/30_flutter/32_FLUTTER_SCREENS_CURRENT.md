# 32 — Flutter Screens Current / Текущие экраны Flutter

Файл часто меняется.  
Обновлять после изменения экранов.

---

## 1. Auth

```text
SplashScreen
LoginScreen
RegisterScreen
```

Сценарии:

```text
bootstrap token
login
register
logout
```

---

## 2. Workspace Entry

```text
WorkspaceEntryScreen
```

Показывает доступные воркспейсы.

Кнопка:

```text
Создать компанию
```

видна всегда.

---

## 3. Company Workspace

```text
CompanyWorkspaceShell
```

Нижняя навигация:

```text
Главная
Проекты
Контрагенты
Операции / placeholder
```

Центральная кнопка:

```text
Операции
```

открывает picker:

```text
Поступление
Перевод
Отчёт
```

---

## 4. Company Dashboard

```text
CompanyDashboardScreen
```

Показывает:

```text
Проекты
Контрагенты
Квартальная аналитика
История операций
Документы (плитка) → bottom sheet: Прайс-листы (ТЗ-10B) + заглушка «документы скоро»
```

**Прайс-листы компании (ТЗ-10B):** при **`context.price_lists.can_view_library`** — переход к **`CompanyPriceListsScreen`** → **`PriceListDetailScreen`**, CRUD групп/позиций, выбор единицы из **`UnitPickerSheet`**; создание собственного прайса для **Партнёра-РП** блокируется, если уже есть активный (`context.price_lists.has_active_own_price_list`).

```text
GET .../operations/history?tab=pending|all
```

и показывает:

```text
TRANSFER + INCOME
```

Бейдж:

```text
combinedOperationsPendingCountProvider
```

---

## 5. Projects

**ТЗ-10A (статьи расходов):** реализовано в приложении — см. экраны ниже.

```text
CompanyProjectsScreen
CreateProject flow
ProjectDetailScreen
ProjectExpenseItemsScreen
CreateEditProjectExpenseItemScreen
ProjectPriceListsScreen
CreateEditPriceListScreen
PriceListDetailScreen
PriceListGroupPositionsScreen
CreateEditPriceListGroupScreen
CreateEditPriceListPositionScreen
UnitPickerSheet
ExpenseItemRecipientPickerSheet (bottom sheet)
ProjectParticipantsScreen
ProjectInternalMetricsSection (на экране участников, если API разрешил can_view_internal_metrics)
```

Навигация к деталям проекта из списка компании / личного кабинета.

**ProjectDetailScreen** (`project_detail_screen.dart`):

```text
projectSummaryProvider → GET …/projects/{id}/summary
карточка метрик (доход / расход / баланс из summary)
кнопка истории операций → AggregatedOperationsHistoryScreen (company)
меню: при can_view_expense_items → статьи расходов (список); при can_view_project_price_lists → прайс-листы проекта (прикрепление); участники; переводы (company); заглушки документов/статуса
```

Флаги **`can_view_expense_items`** и **`can_manage_expense_items`** приходят в **`visibility`** ответа summary (company workspace). Пункт «Статьи расходов» не показывается, если **`can_view_expense_items`** = false. Пункт **«Прайс-лист»** (прикрепление к проекту) — при **`can_view_project_price_lists`**; управление прикреплением — при **`can_manage_project_price_list_attachments`** (OWNER / PROJECT_HEAD-Партнёр).

**Статьи расходов проекта** (ТЗ-10A): провайдеры **`projectExpenseItemsProvider`**, **`projectExpenseItemDetailProvider`**, **`projectExpenseItemRecipientsProvider`**; API префикс **`…/projects/{projectId}/expense-items`** (см. `20_API_ROUTES_CURRENT.md`). Выбор получателей долей — **`ExpenseItemRecipientPickerSheet`**: один список **контрагентов компании**, поиск и множественный выбор (без вкладок «участники / контрагенты» в MVP).

**Внутренние метрики** (`internal-metrics`): данные через `projectInternalMetricsProvider` / **`GET …/projects/{id}/internal-metrics`**; виджет **`ProjectInternalMetricsSection`** подключается на **`ProjectParticipantsScreen`**, если в summary **`can_view_internal_metrics`**.

Проект создаётся с:

```text
PROJECT_HEAD
CUSTOMER
wallets
```

---

## 6. Counterparties

```text
CompanyCounterpartiesScreen
```

Сценарии:

```text
list
search
create
```

---

## 7. Project Participants

```text
ProjectParticipantsScreen
ParticipantWalletScreen
ProjectInternalMetricsSection (условно, см. §5 Projects)
```

Сценарии:

```text
list participants
add participant
edit role
delete participant
open wallet
open transfers
просмотр внутренних метрик проекта (если есть право)
```

---

## 8. Transfers

```text
TransfersScreen
CreateTransferScreen
TransferDetailScreen
```

Действия:

```text
создание перевода
список переводов
деталь
lifecycle buttons by available_actions
comment dialog
```

---

## 9. Incomes

```text
CreateIncomeScreen
IncomeDetailScreen
```

Действия:

```text
создание поступления
деталь
подтверждение заказчиком
отклонение заказчиком
ручное завершение 24 часов
откат completed
```

---

## 10. Unified operations history

Экран:

```text
AggregatedOperationsHistoryScreen
```

Вкладки (порядок):

```text
На подтверждение — GET …/operations/history?tab=pending
Все операции — GET …/operations/history?tab=all (по умолчанию, если tab не передан)
```

Показывает:

```text
TRANSFER + INCOME + REPORT
```

Источник:

```text
GET .../operations/history?tab=&page=&per_page=
```

Суммарный бейдж ожиданий на дашборде: **`combinedOperationsPendingCountProvider`** (**TRANSFER + INCOME + REPORT** pending-count) совпадает с набором операций вкладки **«На подтверждение»** (для REPORT `complete_waiting` не входит в pending-бейдж).

### 10.1. REPORT foundation (Flutter)

```text
AggregatedOperationsHistoryScreen — карточка отчёта
reportPendingActionCountProvider + combinedOperationsPendingCountProvider
ReportDetailStubScreen — вход в деталь без полноценной формы отчёта
```

Полноценный **Create/Edit/Detail** UI отчёта — **не** реализован (следующий этап).

---

## 11. Personal Workspace

```text
PersonalWorkspaceShell
PersonalOperationsTab
PersonalAllCompaniesScreen
```

Для Employee first-order:

```text
может создавать Transfer из personal workspace
```

Supplier / Contractor / second-order:

```text
не создают операции
смотрят доступные данные
```

---

## 12. Customer Workspace

```text
CustomerWorkspaceShell
CustomerCompaniesScreen
CustomerCompanyProjectsScreen
```

Backend:

```text
personal-workspace
workspace_role=customer
```

История операций:

```text
GET .../operations/history
TRANSFER + INCOME + REPORT
```

Бейдж:

```text
combinedOperationsPendingCountProvider (TRANSFER + INCOME + REPORT)
```

---

## 13. Не реализовано / placeholder

```text
Полноценный UI операции REPORT (создание/редактирование/деталь, не stub)
Documents
Push notifications
Realtime/WebSocket
Offline sync
полная аналитика dashboard
вкладка Операции как полноценный operation center
```
