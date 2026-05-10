# GURU — Project Context (single-file handoff)

**Last updated:** 2026-05-10  

**Назначение:** один файл для прикрепления в новый чат Cursor — восстановить контекст без обязательного чтения остальных документов.  

**Иерархия документации (глубже по необходимости):**

| Файл | Содержание |
|------|------------|
| **Этот файл** | Стек, воркспейсы, домен, полные списки API, пути коду, Flutter, команды, сбои |
| `docs/GURU_ARCHITECTURE_AND_STANDARDS.md` | Те же темы развёрнуто, стандарты модулей, mermaid, чеклист модулей |
| `docs/GURU_FULL_PROJECT_BLUEPRINT.md` | Максимальная детализация, UX-кабинет заказчика, история постулатов |
| `docs/TZ_05_3_GURU_Transfer_Personal_Workspace_Alignment.md` | ТЗ personal-workspace + переводы |
| `docs/TZ_SEC_01_v2_...` | Изоляция воркспейсов (если есть в `docs/`) |

---

## 1) Стек и структура репозитория

- **Backend:** PHP 8.3, **Laravel 13**, **PostgreSQL**, **Sanctum** (Bearer token).
- **Mobile:** **Flutter**, **Riverpod**, **go_router**, **Dio**.
- Пакет `bavix/laravel-wallet` в `composer.json` (исторические миграции); **учёт GURU** — таблица **`project_participant_wallets`**, не путать с доменом пакета.

```text
C:\GuruApp\
  backend\           Laravel API — см. routes/api.php, app/Modules/, app/Support/
  mobile_app\        Flutter — lib/core/, lib/features/
  docs\              Архитектура, blueprint, ТЗ
```

`backend/package.json` + `node_modules` — только фронтенд-сборка Laravel (Vite), не Node API.

---

## 2) Воркспейсы (архитектурный инвариант)

**Не смешивать** префиксы маршрутов и бизнес-правила двух контуров.

### Company Workspace

- **Кто:** активный `Counterparty` компании с ролью **`OWNER`** или **`PARTNER`**, `user_id` = текущий пользователь.
- **Префикс API:** `/api/company-workspace/{companyId}/...`
- **Middleware:** `EnsureCompanyWorkspaceAccess`
- **Сотрудник (`EMPLOYEE`) сюда не попадает** — переводы создаёт из **Personal Workspace** (ТЗ-05.3).

### Personal Workspace

- **Кто:** хотя бы один активный контрагент с ролью **`EMPLOYEE`**, **`CONTRACTOR`**, **`SUPPLIER`** или **`CUSTOMER`**.
- **Префикс API:** `/api/personal-workspace/...`
- **Middleware:** `EnsurePersonalWorkspaceAccess`
- **Query `workspace_role`:** например `customer` — только контрагенты-заказчики; `performer` — исполнительские роли; без параметра — широкий набор (см. `PersonalWorkspaceRoleFilter`).

### Кабинет заказчика (только Flutter)

- Маршруты `/customer/...` — **тот же** personal-workspace API с узким фильтром; отдельного backend-контура нет.

---

## 3) Домен: сущности и переводы

- **Company** → **Projects**, **Counterparties**
- **Counterparty** — лицо в компании; может быть без `user_id` (invite-first); контакты (`full_name`, `email` и др.)
- **ProjectParticipant** — проекция контрагента в проекте: `level` = `first` | `second`, `project_role_code`, `is_active`
- **ProjectParticipantWallet** — один на участника; поля `decimal(15,2)`:
  - подотчёт: `accountable_balance`, `accountable_received`, `accountable_spent`
  - личный: `personal_balance`, `personal_received`, `personal_earned`

### Операция TRANSFER (реализована)

- Таблицы: **`operations`**, **`operation_status_histories`**, **`transfer_operations`**
- **Создание:** `TransferService::create` — HEAD/PARTNER первого порядка → часто сразу **`COMPLETED`** с дельтами; **EMPLOYEE** → **`PROJECT_HEAD_APPROVAL`** без дельт
- **После создания:** только **`TransferLifecycleService`** + HTTP POST из таблиц ниже
- **Математика:** только **`TransferBalanceService`** (целые центы где нужно); списание **всегда** с `sender.accountable_balance` / `accountable_spent`; запрет на списание `personal_balance` отправителя; отрицательный подотчёт не блокируется ошибкой «недостаточно средств»
- **Видимость:** `OperationVisibilityService` — **`PROJECT_HEAD`** видит все переводы проекта; остальные — только где они **initiator / sender / receiver**
- **Терминальность статусов:** `OperationStatus::isTerminal()` vs **`isTerminalForOperationType(OperationType)`** — для **TRANSFER** **`REJECTED`** не финал (отклонение РП → возврат к правкам). Кэш словаря: `DictionaryCacheService`, ключ статусов **`guru:dict:operation_statuses:v2`**
- **Получатели ACCOUNTABLE_BALANCE:** участники **first** с ролями PROJECT_HEAD, PARTNER, EMPLOYEE; **себе на подотчёт нельзя**; текущий участник **исключается** из списка для UI
- **Получатели PERSONAL_BALANCE:** любой активный контрагент компании: **OWNER, PARTNER, EMPLOYEE, SUPPLIER, CONTRACTOR, CUSTOMER**; **себе на расчётный можно**; при отсутствии в проекте — автосоздание участника **second** + кошелёк; маппинг ролей company→project для 2-го порядка включая **CUSTOMER → CUSTOMER**, **OWNER → PARTNER** (техн. роль в проекте)

### Personal Workspace и переводы (ТЗ-05.3)

- **`PersonalWorkspaceTransferGuard`:** создание перевода, `recipients`, действия **`submit-for-approval`**, **`reset-approval`**, **`return-to-created`** — только если участник **`level = first`** и **`project_role_code = EMPLOYEE`**; иначе **403**
- Доступ к проекту: **`ProjectVisibilityService::assertCanAccessPersonalWorkspaceProject`**
- Контроллеры: `app/Modules/Operations/Http/Controllers/PersonalWorkspace/*` — те же сервисы, что и Company-контур

---

## 4) Backend: модули и важные пути

```
app/Modules/Auth
app/Modules/Workspaces        — middleware EnsureCompany/Personal, ListWorkspaces, context
app/Modules/Companies
app/Modules/Projects
app/Modules/Dictionaries
app/Modules/Operations        — Transfer*, OperationVisibility, PersonalWorkspaceTransferGuard
app/Modules/System            — health
app/Support/Http              — ApiResponse, Pagination, Middleware (RequestId, ForceJsonResponse, RejectHtmlApiResponses)
```

**Расписание:** `bootstrap/app.php` — команда **`operations:complete-expired-transfer-waiting`** каждую минуту.

---

## 5) HTTP API — полный снимок

База: **`/api`**. Заголовок: **`Authorization: Bearer <token>`** для защищённых маршрутов.

### 5.1 Публичные

| Метод | Путь |
|-------|------|
| GET | `/api/health` |
| POST | `/api/auth/register` |
| POST | `/api/auth/token` |

### 5.2 Sanctum (auth)

| Метод | Путь |
|-------|------|
| GET | `/api/auth/me` |
| POST | `/api/auth/logout` |
| GET | `/api/workspaces` |
| POST | `/api/company-workspace/companies` |

### 5.3 Company workspace — `/api/company-workspace/{companyId}`

Все под префиксом + **`EnsureCompanyWorkspaceAccess`**.

| Метод | Относительный путь |
|-------|---------------------|
| GET | `/context` |
| GET | `/companies/current` |
| GET, POST | `/projects` |
| GET | `/projects/{projectId}/participants` |
| POST | `/projects/{projectId}/participants` |
| PATCH | `/projects/{projectId}/participants/{participantId}` |
| DELETE | `/projects/{projectId}/participants/{participantId}` |
| GET | `/projects/{projectId}/participants/{participantId}/wallet` |
| GET, POST | `/counterparties` |
| GET | `/projects/{projectId}/operations/transfers/recipients` ? `transfer_target_type=` |
| GET | `/projects/{projectId}/operations/transfers` |
| POST | `/projects/{projectId}/operations/transfers` |
| GET | `/projects/{projectId}/operations/transfers/{transferId}` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/approve-project-head` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/reject-project-head` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/reset-approval` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/submit-for-approval` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/complete-immediate` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/return-to-created` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/return-to-project-head-approval` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/complete-waiting` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/rollback-completed` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/return-completed-to-project-head-approval` |

### 5.4 Personal workspace — `/api/personal-workspace`

Все под префиксом + **`EnsurePersonalWorkspaceAccess`**.

| Метод | Путь |
|-------|------|
| GET | `/context` |
| GET | `/companies` |
| GET | `/projects` |
| GET | `/income-by-month` |
| GET | `/projects/{projectId}/operations/transfers/recipients` |
| GET | `/projects/{projectId}/operations/transfers` |
| POST | `/projects/{projectId}/operations/transfers` |
| GET | `/projects/{projectId}/operations/transfers/{transferId}` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/submit-for-approval` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/reset-approval` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/return-to-created` |

**Ответ `GET .../projects` (элемент):** `project`, `company`, `my_wallet`, **`my_participation`** `{ level, project_role_code }` — для клиента (кто может создавать перевод из личного кабинета).

---

## 6) Контракт ответа и middleware API

**Успех:** `{ "ok": true, "data": ..., "meta": { "request_id": "..." } }`  

**Ошибка:** `{ "ok": false, "error": { "message", "type", "fields"? }, "meta": { "request_id" } }`

**Глобальный стек `api` (см. `bootstrap/app.php`):**

- `ForceJsonResponse`
- `RequestId` (заголовок `X-Request-Id`)
- **`RejectHtmlApiResponses`** — если тело ответа на `api/*` похоже на HTML, подмена на JSON **502** (`api_error.html_response`), чтобы клиент не ловил `unexpected token "<"`

**Исключения:** ветка JSON если `expectsJson` **или** путь `api/*` — без редиректа на HTML-login для API.

**Провайдер:** `JsonResource::withoutWrapping()` — нет двойной обёртки `data` от Laravel Resource внутри уже обёрнутого `ApiResponse`.

**Пагинация:** `page`, `per_page` (default 20, max 50); формат `data.items` + `data.pagination`.

---

## 7) Миграции и демо

Ключевые миграции: `companies`, `counterparties`, `projects`, `project_participants`, `project_participant_wallets`, `operations`, `operation_status_histories`, `transfer_operations`, индексы производительности (`2026_05_09_000004_...`).

**Сиды:** `GuruDemoSeeder` и др. Аккаунты (пароль `password`): `owner@guru.local`, `partner@guru.local`, `employee@guru.local`.

---

## 8) Команды разработки (Windows / PowerShell)

Цепочки команд разделять **`;`**, не `&&`.

```powershell
cd C:\GuruApp\backend
php artisan migrate
php artisan route:list
php artisan schedule:list
php artisan optimize:clear
php artisan serve --host=0.0.0.0 --port=8000
```

После правок PHP: **`php -l path\to\File.php`**. Мусор в конце `.php` (например куски markdown с \`\`\`) даёт **Parse error** и «белый»/HTML ответ.

```powershell
cd C:\GuruApp\mobile_app
flutter pub get
flutter gen-l10n
flutter analyze
flutter run -d emulator-5554 --dart-define=GURU_API_BASE_URL=http://10.0.2.2:8000/api
```

**Эмулятор:** `10.0.2.2` — хост ПК. **Физическое устройство:** LAN IP ПК, не `10.0.2.2`. В `AndroidManifest`: **`INTERNET`**, **`usesCleartextTraffic="true"`** для dev HTTP.

---

## 9) Flutter — структура и поведение

### 9.1 Каталоги

```
lib/core/           api_client, api_models, routing, theme (accent #00D6C9), widgets
lib/features/
  auth/
  workspaces/       workspace entry, create company
  company_workspace/ shell, projects, participants, transfers (transfers_screen.dart)
  personal_workspace/ shell, personal_operations_tab, income, companies list
  customer_workspace/ /customer routes
  operations/       domain + transfers_api (TransferApiScope) + repository
```

### 9.2 Маршруты go_router (`router_provider.dart`)

- `/` Splash → при авторизации `/workspaces`, иначе `/login`
- `/login`, `/register`
- `/workspaces` — кнопка **«Создать компанию»** всегда видна
- `/create-company`
- `/company/:companyId` — `CompanyWorkspaceShell`
- `/personal` — `PersonalWorkspaceShell` (исполнители: **Главная | Операции | Уведомления**)
- `/personal/companies`
- `/customer`, `/customer/companies`, `/customer/companies/:companyId/projects`

Переводы из компании: **`TransferApiScope.company`**. Из личного кабинета сотрудника: **`TransferApiScope.personal`** (URL без `companyId` в пути, `companyId` в теле/DTO всё равно нужен для бизнеса — передаётся из выбранного проекта).

Экраны переводов: `CreateTransferScreen`, `TransfersScreen` — параметр **`canCreateTransfer`** для personal (только first-order **EMPLOYEE**).

### 9.3 ApiClient (Dio)

- **`ResponseType.plain`**, **`followRedirects: false`**
- POST/PATCH: JSON `Content-Type`
- Разбор тела с детекцией HTML → человекочитаемая ошибка

### 9.4 Локализация

Строки через `context.l10n`. Ключи для вкладки операций исполнителя: **`navOperations`**, **`personalOperationsProjectsTitle`**, **`personalOperationsNoTransferProjects`** (`app_ru.arb` / `app_en.arb`).

---

## 10) Типичные сбои

| Симптом | Причина / действие |
|---------|-------------------|
| `syntax error, unexpected token "<"` на клиенте | Сервер/прокси отдал HTML; проверить `RejectHtmlApiResponses`, Dio plain, cleartext, URL |
| Parse error на сервере после правок | `php -l`, убрать лишние символы в `.php` |
| 403 на personal transfer create | Не EMPLOYEE first-order — ожидаемо по ТЗ-05.3 |
| Двойной `data` в JSON | Проверить `JsonResource::withoutWrapping()` |

---

## 11) Явно не сделано / долг

- Операции **INCOME**, **REPORT** (продуктово)
- Полный **экран детали перевода** в Flutter с кнопками lifecycle для РП (REST в company-workspace есть)
- Push, realtime, offline, аналитика
- Полное использование **bavix/laravel-wallet** под сценарии GURU

---

## 12) Индекс ТЗ и документов в репозитории

- `docs/GURU_ARCHITECTURE_AND_STANDARDS.md`
- `docs/GURU_FULL_PROJECT_BLUEPRINT.md`
- `docs/TZ_05_3_GURU_Transfer_Personal_Workspace_Alignment.md`

*Конец handoff-файла.*
