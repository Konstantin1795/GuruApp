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
```

История операций использует:

```text
GET .../operations/history
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
меню: при can_view_expense_items → статьи расходов (список); участники; переводы (company); заглушки документов/статуса
```

Флаги **`can_view_expense_items`** и **`can_manage_expense_items`** приходят в **`visibility`** ответа summary (company workspace). Пункт «Статьи расходов» не показывается, если **`can_view_expense_items`** = false.

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

Текущий экран:

```text
AggregatedOperationsHistoryScreen
```

Фактически показывает:

```text
TRANSFER + INCOME
```

Источник:

```text
GET .../operations/history
```

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
TRANSFER + INCOME
```

Бейдж:

```text
combinedOperationsPendingCountProvider
```

---

## 13. Не реализовано / placeholder

```text
REPORT
Documents
Push notifications
Realtime/WebSocket
Offline sync
полная аналитика dashboard
вкладка Операции как полноценный operation center
```
