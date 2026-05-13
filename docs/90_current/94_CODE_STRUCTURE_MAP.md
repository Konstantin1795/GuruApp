# 94 — Карта структуры кода GURU

**Назначение:** быстрый ориентир для нового разработчика перед REPORT. Канон правил — `docs/00_core/`, операции — `docs/10_operations/`.

---

## 1. Backend structure

| Путь | Содержание |
|------|----------------|
| `backend/app/Modules/*` | Доменные модули (Companies, Projects, Operations, Workspaces, …). |
| `backend/app/Modules/*/Http/Controllers` | Тонкий слой: валидация запроса, вызов сервиса, `ApiResponse`. |
| `backend/app/Modules/*/Http/Requests` | FormRequest — правила валидации. |
| `backend/app/Modules/*/Services` | Бизнес-действия, доступ, агрегации, расчёты ответов. |
| `backend/app/Modules/*/Models` | Eloquent: связи, casts; без сложной бизнес-логики. |
| `backend/routes/api.php` | Регистрация маршрутов (два контура: `company-workspace`, `personal-workspace`). |

---

## 2. Flutter structure

| Путь | Содержание |
|------|----------------|
| `mobile_app/lib/core/` | API (Dio), тема, общие виджеты, локализация. |
| `mobile_app/lib/features/*/` | Фичи: `data/` (API), `domain/`, `presentation/`, `providers.dart`. |
| `mobile_app/lib/features/operations/` | Переводы, поступления, объединённая история. |
| `mobile_app/lib/features/projects/` | Проекты, деталь, статьи расходов. |
| `mobile_app/lib/features/price_lists/` | Прайс-листы компании и привязка к проекту. |

---

## 3. Где находятся операции (TRANSFER / INCOME)

- **Модели:** `backend/app/Modules/Operations/Models/` (`TransferOperation`, `IncomeOperation`, `Operation`, …).
- **Lifecycle и смена статусов:** `TransferLifecycleService`, `IncomeLifecycleService`.
- **Доступные POST-действия (UI):** `TransferAvailableActionsService`, `IncomeAvailableActionsService`.
- **Контроллеры:** `Operations/Http/Controllers/CompanyWorkspace/*`, `PersonalWorkspace/*`.

---

## 4. Где находятся права доступа

- **Проект в воркспейсе:** `ProjectVisibilityService`, middleware `EnsureCompanyWorkspaceAccess` / personal-аналоги.
- **Статьи расходов (ТЗ-10A):** `ProjectExpenseItemAccessService`.
- **Прайс-листы (ТЗ-10B):** `PriceListAccessService`.
- **Видимость операций в лентах:** `OperationVisibilityService`, `IncomeVisibilityService` (не путать с company OWNER «все операции компании» — это в `AggregatedOperationsHistoryService`).

---

## 5. Где находится lifecycle

- **TRANSFER:** только в `TransferLifecycleService` (+ история статусов внутри транзакций).
- **INCOME:** только в `IncomeLifecycleService`.
- Контроллеры вызывают lifecycle-сервисы после проверок доступа; не добавлять переходы статусов в контроллер.

---

## 6. Где находится финансовая математика

- **Переводы:** `TransferBalanceService` (дельты кошельков по ТЗ-05.2).
- **Поступления:** `IncomeBalanceService`.
- **Обеспечение кошелька / вспомогательно:** `WalletService`, чтение среза балансов — `WalletBalanceService` (без проведения дельт).

---

## 7. Где находятся API routes

- **Файл:** `backend/routes/api.php`.
- **Канон списка:** `docs/20_api/20_API_ROUTES_CURRENT.md`.

---

## 8. Где находятся tests

- **Каталог:** `backend/tests/Feature/`, `backend/tests/Unit/`.
- **Карта сценариев:** `docs/90_current/95_TEST_COVERAGE_MAP.md`.

---

## 9. Как добавлять новую операцию

1. Прочитать `docs/10_operations/10_OPERATION_COMMON_RULES.md` и черновик REPORT при необходимости.
2. Модели + миграции (отдельное согласование схемы).
3. `*LifecycleService` — все переходы статусов и побочные эффекты в транзакции.
4. `*BalanceService` или существующие wallet-сервисы — все деньги.
5. `*AvailableActionsService` — флаги для UI и для pending-логики.
6. Контроллеры — только orchestration.
7. Обновить `20_API_ROUTES_CURRENT.md`, Flutter-экраны по `32_FLUTTER_SCREENS_CURRENT.md`, тесты.

---

## 10. Что нельзя делать при добавлении новой логики

- Не проводить дельты кошельков в контроллере, ресурсе или Flutter.
- Не дублировать правила видимости «на глаз» в UI — источник истины на backend.
- Не смешивать company-workspace и personal-workspace в одном endpoint без явного префикса маршрута.
- Не менять lifecycle TRANSFER/INCOME без ТЗ и регрессионных тестов.
- Не полагаться на `docs/OldDocs/` как на канон.

---

## 11. Что прочитать за первые 30 минут (новый разработчик)

1. `docs/README_MODULAR.md` — вход и карта модулей.
2. `docs/90_current/94_CODE_STRUCTURE_MAP.md` — этот файл: где код и инварианты.
3. `docs/90_current/96_GURU_DEFINITION_OF_DONE.md` — чеклист перед merge.
4. `docs/10_operations/10_OPERATION_COMMON_RULES.md` — общие правила операций.
5. `docs/10_operations/11_OPERATION_TRANSFER.md` — TRANSFER.
6. `docs/10_operations/12_OPERATION_INCOME.md` — INCOME.
7. `docs/10_operations/14_PROJECT_EXPENSE_ITEMS.md` — статьи расходов.
8. `docs/10_operations/15_PRICE_LISTS.md` — прайс-листы.
9. `docs/90_current/95_TEST_COVERAGE_MAP.md` — что уже покрыто тестами.
