# GURU — операция «Поступление» (INCOME): справочник реализации

**Назначение:** точка правды по домену **INCOME** в актуальном коде (ТЗ-06). Для переводов см. `docs/GURU_TRANSFER_OPERATION_REFERENCE.md`.

**Последнее обновление:** 2026-05-09

**Ключевые пути:** `backend/app/Modules/Operations/Services/Income*.php`, `Models/IncomeOperation.php`, `routes/api.php`, `mobile_app/lib/features/operations/` (`incomes_api.dart`, `create_income_screen.dart`, `income_detail_screen.dart`).

---

## 1. Модель данных

- Таблица **`operations`** — `operation_type = INCOME`, общий статус и связь с проектом/инициатором.
- Таблица **`income_operations`** — одна строка на операцию: сумма, комментарий, дублирующий `operation_status`, участники **инициатор**, **РП (`project_head_project_participant_id`)**, **заказчик (`customer_project_participant_id`)**, метки **`wallets_applied_at`**, **`wallets_reverted_at`**, **`waiting_period_started_at`** (UTC для 24 ч).
- **`operation_status_histories`** — журнал переходов (как у TRANSFER).

---

## 2. Кошельки (`IncomeBalanceService`)

При первом «живом» шаге с деньгами (отправка на согласование заказчика из `CREATED`) начисляются **подотчётные** суммы **одинаково** на кошелёк участника-заказчика и участника-РП:

- `accountable_balance` и `accountable_received` увеличиваются на сумму поступления.

Откаты вызывают симметричное списание через **`revertIncomeDeltas`** / **`debitAccountableReceived`** (см. код сервиса).

---

## 3. Сервисы

| Сервис | Роль |
|--------|------|
| **`IncomeService`** | Создание черновика в статусе **`CREATED`** |
| **`IncomeLifecycleService`** | Все переходы после создания: отправка на согласование заказчика, решение заказчика, ожидание 24 ч, завершение, откаты РП, правка черновика **`updateDraftInCreated`**, автозавершение по таймеру **`autoCompleteWaitingIfDue`** |
| **`IncomeBalanceService`** | Применение и откат дельт на кошельки |
| **`IncomeVisibilityService`** | Доступ к операции в списках/show |
| **`IncomeAvailableActionsService`** | Карта **`available_actions`** для UI |
| **`IncomePendingActionCountService`** | Счётчик «ожидают действия» для агрегированного эндпоинта |
| **`IncomeProjectParticipantsResolver`** | Резолв РП и заказчика по проекту |

Переходы статусов реализованы **в коде `IncomeLifecycleService`**, не через `OperationTransitionService`.

---

## 4. HTTP API (сводка)

**Company workspace** (`/api/company-workspace/{companyId}`):

| Метод | Путь |
|-------|------|
| GET | `/operations/incomes/history` |
| GET | `/operations/incomes/pending-count` |
| GET | `/projects/{projectId}/operations/incomes` |
| POST | `/projects/{projectId}/operations/incomes` |
| GET | `/projects/{projectId}/operations/incomes/{incomeId}` |
| PATCH | `/projects/{projectId}/operations/incomes/{incomeId}` |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/submit-to-customer-approval` |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/complete-waiting` |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/rollback-completed` |

**Personal workspace** (`/api/personal-workspace`):

| Метод | Путь |
|-------|------|
| GET | `/operations/incomes/history` |
| GET | `/operations/incomes/pending-count` |
| GET | `/projects/{projectId}/operations/incomes` |
| GET | `/projects/{projectId}/operations/incomes/{incomeId}` |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/approve-customer` |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/reject-customer` |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/return-to-customer-approval` |

Создание поступления — только из **company-workspace**.

---

## 5. Планировщик

В `bootstrap/app.php`: **`operations:complete-expired-income-waiting`** каждую минуту — автоматическое завершение ожидания по правилам **`IncomeLifecycleService::autoCompleteWaitingIfDue`**.

---

## 6. Flutter

- **`IncomesApi` / `IncomesRepository`** — REST-обёртки.
- **`CreateIncomeScreen`** — создание из picker «Операции» (выбор проекта при необходимости).
- **`IncomeDetailScreen`** — деталь, действия по **`available_actions`**.

**Замечание по продукту:** экран **`AggregatedTransfersHistoryScreen`** запрашивает только **`…/operations/transfers/history`**; объединённая лента TRANSFER+INCOME на клиенте описана в `PROJECT_CONTEXT_GURU.md` как долг.

---

## 7. Методы lifecycle (имена для поиска в коде)

- `submitFromCreatedToCustomerApproval`
- `approveByCustomer` / `rejectByCustomer`
- `returnToCustomerApprovalFromWaiting`
- `completeWaitingByProjectHead`
- `rollbackCompleted`
- `updateDraftInCreated`
- `autoCompleteWaitingIfDue`

Точная семантика статусов и допустимые акторы — в теле **`IncomeLifecycleService`** и в **`IncomeAvailableActionsService`**.
