# GURU — контекст проекта (единый handoff)

**Последнее обновление:** 2026-05-09  
**Репозиторий:** GuruApp (монорепозиторий: `backend/` Laravel API, `mobile_app/` Flutter).

Прикрепляйте этот файл в новый чат Cursor вместе с задачей. Расширенная справка: `docs/GURU_ARCHITECTURE_AND_STANDARDS.md`, полный blueprint: `docs/GURU_FULL_PROJECT_BLUEPRINT.md`.

---

## 1. Продукт и домен (кратко)

**GURU** — платформа вокруг **компаний**, **проектов**, **контрагентов**, **участников проекта**, **кошельков на уровне участника** (`ProjectParticipant` → `ProjectParticipantWallet`) и **операций** (в т.ч. **переводов TRANSFER**) с формализованным жизненным циклом.

Два изолированных HTTP-контура:

| Контур | Префикс API | Кто |
|--------|-------------|-----|
| **Company workspace** | `/api/company-workspace/{companyId}/…` | OWNER / PARTNER компании (`EnsureCompanyWorkspaceAccess`) |
| **Personal workspace** | `/api/personal-workspace/…` | EMPLOYEE, CONTRACTOR, SUPPLIER, CUSTOMER (`EnsurePersonalWorkspaceAccess`) |

**Кабинет заказчика (Flutter)** — UX поверх personal-workspace (`/customer`), не отдельный backend-контур.

Деньги: в БД `decimal(15,2)`, на backend без float в финансовой логике переводов; математика переводов — **`TransferBalanceService`**, оркестрация создания — **`TransferService::create`**, переходы после создания — **`TransferLifecycleService`**.

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
```

---

## 4. HTTP-контракт

- Успех: `ok: true`, `data`, `meta` (часто `meta.request_id` из `X-Request-Id`).
- Ошибка: `ok: false`, `error` (`message`, `type`, опционально `fields`), `meta.request_id`.
- Пагинация в `data`: `items`, `pagination`: `page`, `per_page`, `total`, `last_page` (default `per_page` 20, max 50).
- `JsonResource::withoutWrapping()` — одна обёртка `data` от `ApiResponse`, без двойного `data` от Laravel Resource.

---

## 5. Маршруты API (сводка)

Полный список — в `backend/routes/api.php` и в `docs/GURU_ARCHITECTURE_AND_STANDARDS.md` §6.

### 5.1 Company workspace (важное)

- `GET /context`, `GET /companies/current`
- `GET /operations/transfers/history` — агрегированная лента переводов по видимым проектам компании
- `GET /operations/transfers/pending-count` — `{ pending_action_count }` (whitelist «ожидаемого подтверждения»)
- `GET|POST /projects`, участники, кошелёк участника, контрагенты
- `GET|POST /projects/{id}/operations/transfers`, `GET …/transfers/{id}` (в ответе `transfer`, `available_actions`, при загрузке проекта — `project_name`)
- POST действий lifecycle: `…/transfers/{id}/approve-project-head`, `submit-for-approval`, … (сегмент URL в kebab-case)

### 5.2 Personal workspace (важное)

- `GET /context`, `GET /companies`, `GET /projects`, `GET /income-by-month`
- `GET /operations/transfers/history`, `GET /operations/transfers/pending-count`
- Переводы в проекте: те же относительные пути под `/personal-workspace/projects/{projectId}/operations/transfers…`
- Создание перевода из ЛК: только участник **first** + роль **EMPLOYEE** (`PersonalWorkspaceTransferGuard`)

### 5.3 Общее

- `GET /api/workspaces`, auth: register, token, me, logout

Планировщик: `operations:complete-expired-transfer-waiting` (каждую минуту) — переводы в `WAITING_24_HOURS` → `COMPLETED` после 24 ч UTC.

---

## 6. Домен TRANSFER (сервисы)

- **`OperationVisibilityService`** — видимость переводов в проекте; РП видит всё; иначе только initiator/sender/receiver; **`transferQueryForUserAcrossProjects`** — для агрегированной истории.
- **`TransferAvailableActionsService`** — карта **`available_actions`** для UI (те же правила, что POST у lifecycle).
- **`TransferPendingActionCountService`** — считает переводы с действиями из whitelist (**`PENDING_BADGE_ACTION_KEYS`**: например `approve_project_head`, `reject_project_head`, `submit_for_approval`), без опциональных шагов вроде `complete_immediate`.
- **`TransferLifecycleService`**, **`TransferBalanceService`**, **`TransferParticipantResolver`**, **`TransferRecipientListService`**.

---

## 7. Flutter — ключевые экраны и файлы

### 7.1 Навигация

`mobile_app/lib/core/routing/router_provider.dart`: splash, login, workspaces, `/company/:id`, `/personal`, `/customer`, create-company.

### 7.2 Company workspace shell

`company_workspace/presentation/company_workspace_shell.dart`:

- **IndexedStack:** главная (дашборд), проекты, контрагенты, плейсхолдер «Операции».
- Нижняя навигация + центральная кнопка «Операции» открывает bottom sheet (поступление / **перевод** / отчёт).
- Перевод из sheet: выбор проекта (если несколько) → **`CreateTransferScreen`**; при успехе → вкладка **«Операции»** (индекс 3), snackbar «Перевод создан», `invalidate` **`transferPendingActionCountProvider`**.
- В шапке на главной: **`LocaleSwitchButton`** (как RU/EN на логине), без отдельного меню «три точки»; переход к воркспейсам — иконка приложений.

### 7.3 Главная компании (дашборд)

`company_dashboard_screen.dart` + `company_workspace/domain/company_dashboard_stats.dart` + провайдер **`companyDashboardStatsProvider`**:

- Плитки **Проекты** / **Контрагенты**: числа с API — всего **активных** проектов (`is_active`) и всего контрагентов (`pagination.total` при запросе списка).
- Карточка **аналитики за квартал**: доход / задолженность / переплата — пока плейсхолдеры «—» и текст про отчёты (строки l10n).
- Столбцы **активных проектов** по трём месяцам **текущего календарного квартала**: высота столбиков пропорциональна max среди месяцев; подписи месяцев выровнены по низу; цифры внутри столбиков тёмным цветом. Месяц **ещё не наступил** (до 1-го числа) → **0**. Учёт активных на конец месяца: текущий `is_active` и `created_at` ≤ конец месяца (до появления истории статусов проекта — упрощённая модель).

### 7.4 Участники проекта

`project_participants_screen.dart`:

- Шапка через общий **`AppScaffold`** — увеличенный `toolbarHeight`, имя/роль столбиком, подзаголовок проекта с переносом (без обрезки).
- Дублирующая кнопка «Добавить» в списке убрана; добавление — иконка в app bar. Пустой список: подсказка **`participantsEmptyHint`**.

### 7.5 Переводы

- **`TransfersScreen`**, **`CreateTransferScreen`** (`transfers_screen.dart`), **`TransferDetailScreen`**, **`AggregatedTransfersHistoryScreen`**.
- API: `TransfersApi` / **`TransfersRepository`**; после создания POST проверка **`ok`**, разбор `data.transfer`; **`TransferOperation.fromJson`** — безопасный разбор строковых полей (`readOptString`), чтобы не показывать ложную ошибку при успешном **201** на сервере.
- Деталь: **`available_actions`**, после успешного POST при необходимости **`pushReplacement`**; счётчик pending не инвалидировать на экране детали во время действия — обновление при возврате.

Провайдеры: **`transferPendingActionCountProvider`**, **`companyDashboardStatsProvider`**, **`transfersControllerProvider`**.

### 7.6 Локализация

Строки через `context.l10n`; ключи дашборда (`dashboard*`), переводов, участников — в `app_en.arb` / `app_ru.arb`. После правок ARB: `flutter gen-l10n`.

---

## 8. Команды разработки

```bash
cd backend && php artisan route:list
cd backend && php artisan test   # при наличии тестов

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
| Ложная ошибка после создания перевода | Разбор ответа `TransferOperation.fromJson`, поля строк |

---

## 10. Явные пробелы / долг

- Операции **INCOME**, **REPORT**; полные отчётные суммы на дашборде.
- Вкладка «Операции» внизу компании — частично плейсхолдер; живой сценарий перевода из sheet и из участников.
- Push, realtime, offline; документы (отдельный API); ручное управление активностью проекта/компании для согласования с UI.

---

*Этот файл поддерживайте при изменении API, ключевых экранов Flutter и договорённостей по домену.*
