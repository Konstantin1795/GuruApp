# GURU — контекст проекта (единый handoff)

**Последнее обновление:** 2026-05-09  
**Репозиторий:** GuruApp (монорепозиторий: `backend/` Laravel API, `mobile_app/` Flutter).

Прикрепляйте этот файл в новый чат Cursor вместе с задачей. Расширенная справка: `docs/GURU_ARCHITECTURE_AND_STANDARDS.md`, полный blueprint: `docs/GURU_FULL_PROJECT_BLUEPRINT.md`, переводы: `docs/GURU_TRANSFER_OPERATION_REFERENCE.md`, поступления: `docs/GURU_INCOME_OPERATION_REFERENCE.md`.

---

## 1. Продукт и домен (кратко)

**GURU** — платформа вокруг **компаний**, **проектов**, **контрагентов**, **участников проекта**, **кошельков на уровне участника** (`ProjectParticipant` → `ProjectParticipantWallet`) и **операций** с формализованным жизненным циклом. Реализованы типы **TRANSFER** (перевод) и **INCOME** (поступление средств на проект).

Два изолированных HTTP-контура:

| Контур | Префикс API | Кто |
|--------|-------------|-----|
| **Company workspace** | `/api/company-workspace/{companyId}/…` | OWNER / PARTNER компании (`EnsureCompanyWorkspaceAccess`) |
| **Personal workspace** | `/api/personal-workspace/…` | EMPLOYEE, CONTRACTOR, SUPPLIER, CUSTOMER (`EnsurePersonalWorkspaceAccess`) |

**Кабинет заказчика (Flutter)** — UX поверх personal-workspace (`/customer`), не отдельный backend-контур.

**TRANSFER:** математика — **`TransferBalanceService`**, создание — **`TransferService::create`**, переходы после создания — **`TransferLifecycleService`**.

**INCOME:** математика — **`IncomeBalanceService`** (подотчёт заказчика и РП), создание и черновик — **`IncomeService`**, переходы — **`IncomeLifecycleService`**.

---

## 2. Стек

| Слой | Технологии |
|------|------------|
| Backend | PHP 8.3, Laravel 13, Sanctum, PostgreSQL |
| Backend (кошельки) | `bavix/laravel-wallet` + доменные балансы в `project_participant_wallets` |
| Mobile | Flutter (Dart 3.11+), Riverpod, go_router, Dio |
| Локализация | `flutter gen-l10n`, ARB (`ru` по умолчанию), `localeProvider` |

---

## 3. Структура репозитория

```
backend/
  app/Modules/<Domain>/   # Auth, Companies, Projects, Operations, Workspaces, …
  routes/api.php
  database/migrations/
mobile_app/lib/
  core/                   # ApiClient, theme, routing, widgets (AppScaffold, …)
  features/
    auth, workspaces, company_workspace, personal_workspace,
    customer_workspace, operations, counterparties, projects, …
docs/
  GURU_ARCHITECTURE_AND_STANDARDS.md
  GURU_FULL_PROJECT_BLUEPRINT.md
  GURU_TRANSFER_OPERATION_REFERENCE.md
  GURU_INCOME_OPERATION_REFERENCE.md
```

---

## 4. HTTP-контракт

- Успех: `ok: true`, `data`, `meta` (часто `meta.request_id` из `X-Request-Id`).
- Ошибка: `ok: false`, `error` (`message`, `type`, опционально `fields`), `meta.request_id`.
- Пагинация в `data`: `items`, `pagination`: `page`, `per_page`, `total`, `last_page` (default `per_page` 20, max 50).
- `JsonResource::withoutWrapping()` — одна обёртка `data` от `ApiResponse`, без двойного `data` от Laravel Resource.

---

## 5. Маршруты API (сводка)

Полный перечень — `backend/routes/api.php` и `docs/GURU_ARCHITECTURE_AND_STANDARDS.md` §6.

### 5.1 Company workspace (важное)

- `GET /context`, `GET /companies/current`
- **Переводы (агрегаты):** `GET /operations/transfers/history`, `GET /operations/transfers/pending-count`
- **Поступления (агрегаты):** `GET /operations/incomes/history`, `GET /operations/incomes/pending-count`
- `GET|POST /projects`, участники, кошелёк участника, контрагенты
- **Переводы в проекте:** `GET|POST /projects/{id}/operations/transfers`, `GET …/transfers/{id}`, lifecycle POST в kebab-case (`approve-project-head`, `submit-for-approval`, `reset-approval`, …)
- **Поступления в проекте:** `GET|POST /projects/{id}/operations/incomes`, `GET /…/incomes/{id}`, `PATCH /…/incomes/{id}` (редактирование только инициатором в `CREATED`), `submit-to-customer-approval`, `complete-waiting`, `rollback-completed`

### 5.2 Personal workspace (важное)

- `GET /context`, `GET /companies`, `GET /projects`, `GET /income-by-month`
- Те же агрегированные эндпоинты: **transfers** и **incomes** (`history`, `pending-count`)
- Переводы в проекте: создание и действия сотрудника — только участник **first** + роль **EMPLOYEE** (`PersonalWorkspaceTransferGuard`)
- **Поступления:** `GET` список/деталь; действия заказчика: `approve-customer`, `reject-customer`, `return-to-customer-approval` (создание поступлений — в company-контуре)

### 5.3 Общее

- `GET /api/workspaces`, auth: register, token, me, logout

### 5.4 Планировщик (`bootstrap/app.php`)

- `operations:complete-expired-transfer-waiting` — каждую минуту (TRANSFER в `WAITING_24_HOURS` → `COMPLETED` по UTC).
- `operations:complete-expired-income-waiting` — каждую минуту (INCOME в ожидании 24 ч → завершение по правилам ТЗ-06).

---

## 6. Доменные сервисы операций

### TRANSFER

- **`OperationVisibilityService`** — видимость переводов; **`transferQueryForUserAcrossProjects`** — агрегированная история переводов.
- **`TransferAvailableActionsService`**, **`TransferPendingActionCountService`** (whitelist **`PENDING_BADGE_ACTION_KEYS`**).
- **`TransferLifecycleService`**, **`TransferBalanceService`**, **`TransferParticipantResolver`**, **`TransferRecipientListService`**.

### INCOME

- **`IncomeVisibilityService`**, **`IncomeAvailableActionsService`**, **`IncomePendingActionCountService`**.
- **`IncomeService`** (создание), **`IncomeLifecycleService`** (все переходы после создания), **`IncomeBalanceService`** (дельты на кошельки заказчика и РП), **`IncomeProjectParticipantsResolver`**.

---

## 7. Flutter — ключевые экраны и файлы

### 7.1 Навигация

`mobile_app/lib/core/routing/router_provider.dart`: splash, login, workspaces, `/company/:id`, `/personal`, `/customer`, create-company.

### 7.2 Company workspace shell

`company_workspace/presentation/company_workspace_shell.dart`:

- **IndexedStack:** главная, проекты, контрагенты, вкладка «Операции» (частично плейсхолдер).
- Центральная кнопка «Операции» — bottom sheet: **поступление** → **`CreateIncomeScreen`** (если включено в сборке), **перевод** → **`CreateTransferScreen`**, отчёт — заглушка.
- После успешного перевода — вкладка «Операции», snackbar, **`invalidate`** **`transferPendingActionCountProvider`**.

### 7.3 Главная компании (дашборд)

`company_dashboard_screen.dart` + **`companyDashboardStatsProvider`**:

- Плитки Проекты / Контрагенты — из API.
- Квартальная аналитика — плейсхолдеры до отчётов.
- Плитка **«История операций»** → **`AggregatedTransfersHistoryScreen`** — сейчас загружает **только переводы** (`GET …/operations/transfers/history`). Бейдж **`pending_action_count`** на дашборде берётся из **`transferPendingActionCountProvider`** (только TRANSFER); отдельный счётчик поступлений на backend есть (`…/operations/incomes/pending-count`), в UI объединения пока нет.

### 7.4 Участники проекта

`project_participants_screen.dart` — кошелёк, переводы (`TransfersScreen`), добавление участника через app bar.

### 7.5 Переводы и поступления

- **Переводы:** `TransfersScreen`, `CreateTransferScreen`, **`TransferDetailScreen`**, **`AggregatedTransfersHistoryScreen`**; `TransfersApi` / **`TransfersRepository`**; **`transferPendingActionCountProvider`**.
- **Поступления:** **`CreateIncomeScreen`**, **`IncomeDetailScreen`**; `IncomesApi` / **`IncomesRepository`** (`income_operation.dart`, `income_detail_view.dart`).

Провайдер **`transferPendingActionCountProvider`** — только для переводов.

### 7.6 Локализация

`context.l10n`; ARB `app_en.arb` / `app_ru.arb`; после правок — `flutter gen-l10n`.

---

## 8. Команды разработки

```bash
cd backend && php artisan route:list
cd backend && php artisan schedule:list
cd backend && php artisan test

cd mobile_app && flutter pub get
cd mobile_app && flutter gen-l10n
cd mobile_app && flutter analyze
```

---

## 9. Типичные сбои (напоминание)

| Симптом | Куда смотреть |
|---------|----------------|
| HTML вместо JSON | `ApiClient`, base URL `/api`, cleartext Android |
| Двойной `data` | `JsonResource::withoutWrapping()` |
| Ложная ошибка после создания перевода | `TransferOperation.fromJson`, типы полей |

---

## 10. Явные пробелы / долг

- **Единая лента «История операций»** в приложении: backend отдаёт отдельно `transfers/history` и `incomes/history`; клиентский экран истории пока только трансферы.
- **Объединённый бейдж** «ожидают действия» (TRANSFER + INCOME) на дашборде — не подключён (есть два API счётчика).
- Операция **REPORT**; полные отчётные суммы на дашборде компании.
- Вкладка «Операции» внизу компании — частично плейсхолдер.
- Push, realtime, offline; отдельный API документов.

---

*Поддерживайте этот файл при изменении API, ключевых экранов Flutter и доменных договорённостей.*
