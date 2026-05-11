# GURU — архитектура, реализованный функционал и стандарты разработки

**Быстрый handoff одним файлом (прикреплять в новый чат):** корень репозитория — **`PROJECT_CONTEXT_GURU.md`**. В нём сводно: воркспейсы, домен операций (**TRANSFER**, **INCOME**), таблицы маршрутов (в т.ч. в §6 ниже), пути к коду, Flutter, команды и типичные сбои. Этот документ — расширенная справка по модулям, стандартам и диаграммам.

Документ описывает текущее состояние монорепозитория **GuruApp**: доменную модель, разбиение на backend (Laravel) и мобильный клиент (Flutter), связи сущностей, уже реализованные модули и договорённости по разработке, зафиксированные в проекте и в технических заданиях (TZ).

---

## 1. Цель продукта и домен (high level)

**GURU** — платформа для совместной работы вокруг **компаний** и **проектов** с разделением контекстов **Company workspace** и **Personal workspace**, учётом **контрагентов**, **участников проекта**, **кошельков** на уровне участника и **операций** (**переводы TRANSFER**, **поступления INCOME**) с формализованным жизненным циклом статусов.

Ключевые принципы домена:

- **Кошелёк привязан к участнику проекта (`ProjectParticipant`)**, а не напрямую к пользователю, компании или контрагенту.
- **Логика Company и Personal workspace не смешивается**: разные префиксы маршрутов, разные middleware и сценарии доступа.
- **Деньги и суммы** — типы с фиксированной точностью (`decimal(15,2)` в БД, в PHP — касты `decimal:2` / строки; на backend для пересчёта переводов используется целочисленная арифметика в центах там, где это применимо).

---

## 2. Технологический стек

| Слой | Технологии |
|------|------------|
| Backend | PHP 8.3, Laravel 13, Laravel Sanctum, PostgreSQL |
| Backend (доп.) | Пакет `bavix/laravel-wallet` подключён в `composer.json` (есть исторические миграции кошельков/транзакций); **доменные балансы GURU для участников** живут в отдельной таблице `project_participant_wallets` |
| Mobile | Flutter, Riverpod, go_router, Dio |
| API | JSON, единый контракт ответов (см. §4) |

---

## 3. Структура репозитория

```
GuruApp/
├── backend/                 # Laravel API
│   ├── app/
│   │   ├── Models/          # User и при необходимости общие модели
│   │   ├── Modules/         # Фиче-модули домена (см. §5)
│   │   └── Support/         # Http helpers (ApiResponse, Pagination, middleware)
│   ├── database/migrations/
│   └── routes/api.php
├── mobile_app/              # Flutter-клиент
│   └── lib/
│       ├── core/            # API-клиент, тема, роутинг, общие виджеты
│       └── features/        # auth, workspaces, company_workspace, personal_workspace, customer_workspace, operations, …
└── docs/                    # Документация (этот файл)
```

---

## 4. HTTP API: контракт и инфраструктура

### 4.1. Успешный ответ

Используется обёртка `App\Support\Http\ApiResponse`:

- Поля: `ok: true`, `data` (объект или массив), `meta` (объект).
- В `meta` минимум **`request_id`**: берётся из заголовка `X-Request-Id` запроса, либо проставляется на стороне сервера.

### 4.2. Ошибки

Для `api/*` (и JSON-ожиданий) в `bootstrap/app.php` настроен единый рендер исключений:

- Структура: `ok: false`, `error` (`message`, `type`, при валидации — `fields`), `meta.request_id`.
- Отдельно маппится `InvalidOperationTransitionException` → HTTP **422**.

### 4.3. Идентификатор запроса и жёсткий JSON-контур

Middleware `App\Support\Http\Middleware\RequestId`:

- Принимает или генерирует `X-Request-Id`, прокидывает в ответ.
- Все успешные ответы через `ApiResponse::ok()` также кладут `request_id` в `meta`.

На API-группе `api/*` (см. `bootstrap/app.php`, `$middleware->api(append: ...)`) подключены:

- `ForceJsonResponse` — единый контракт тела ответа.
- `RequestId` — `X-Request-Id` / `meta.request_id`.
- `RejectHtmlApiResponses` — если по сниффингу тела ответ под `api/*` похож на HTML (логин, страница ошибки веб-сервера), подмена на JSON-ошибку **502** (`api_error.html_response`), чтобы мобильный клиент не падал на парсинге «как JSON».

В `bootstrap/app.php` для рендера исключений API-ветка определяется по **`$request->is('api/*')`**, чтобы глобальные обработчики не отдавали редирект/HTML там, где клиент ждёт JSON.

В `AppServiceProvider` вызывается **`JsonResource::withoutWrapping()`**: поля из `JsonResource` попадают в `data` ответа **без** дополнительной обёртки Laravel `data: { ... }` на уровне Resource (итоговая форма — одна обёртка `ApiResponse`).

### 4.4. Пагинация

Класс `App\Support\Http\Pagination\Pagination`:

- Query-параметры: `page`, `per_page`.
- По умолчанию **`per_page = 20`**, максимум **`50`**.

Формат тела внутри `data` для списков (через `PaginatedResourceResponse::fromPaginator`):

```json
{
  "items": [ … ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "last_page": 5
  }
}
```

На Flutter парсятся модели `Paginated<T>` и `PaginationInfo` в `mobile_app/lib/core/api/api_models.dart`.

---

## 5. Backend: модульная архитектура

Модули располагаются в `backend/app/Modules/<Name>/` по слоям:

- `Enums/` — перечисления домена (роли, типы операций, статусы, тип цели перевода).
- `Models/` — Eloquent-модели модуля.
- `Services/` — бизнес-логика, транзакции, оркестрация.
- `Http/Controllers/` — «тонкие» контроллеры: валидация через FormRequest, вызов сервиса, `ApiResponse` + Resource.
- `Http/Requests/` — FormRequest.
- `Http/Resources/` — JSON-представления (DTO наружу).
- `Exceptions/` — доменные исключения.

**Стандарты (как договорённости в проекте):**

- Не отдавать «сырой» Eloquent наружу — использовать **Resources**.
- Не раздувать контроллеры — **Services** и отдельные классы для переходов статусов и финансовой математики.
- Многошаговые изменения БД — **`DB::transaction`** в сервисах.
- **Операции типа TRANSFER:** создание и начальные статусы — в **`TransferService::create`**; все последующие переходы и откаты кошельков — только через **`TransferLifecycleService`** и соответствующие HTTP-эндпоинты; аудит в `operation_status_histories` (в т.ч. `comment`, `author_user_id`, `author_full_name`).
- **`OperationTransitionService`** — централизованная карта переходов для типов, где переходы описаны декларативно; **TRANSFER** и **INCOME** в коде идут через **`TransferLifecycleService`** и **`IncomeLifecycleService`** соответственно (не через этот сервис).

---

## 6. Маршрутизация API (актуальный снимок)

Файл `backend/routes/api.php`.

### 6.1. Публичные / общие

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/api/health` | Проверка живости |
| POST | `/api/auth/register` | Регистрация |
| POST | `/api/auth/token` | Выдача токена |
| GET | `/api/auth/me` | Текущий пользователь (Sanctum) |
| POST | `/api/auth/logout` | Выход (Sanctum) |

### 6.2. Защищённые Sanctum

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/api/workspaces` | Список доступных воркспейсов |

### 6.3. Company workspace

Префикс: `/api/company-workspace/{companyId}`  
Middleware: `EnsureCompanyWorkspaceAccess` — доступ есть у **активного** контрагента компании с ролью **OWNER** или **PARTNER**, привязанного к текущему `user_id`.

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/context` | Контекст воркспейса |
| GET | `/operations/transfers/history` | Агрегированная лента переводов по всем проектам с видимостью для пользователя в компании |
| GET | `/operations/transfers/pending-count` | `{ pending_action_count }` — переводы, где от пользователя ожидается шаг подтверждения (whitelist действий, см. `TransferPendingActionCountService`) |
| GET | `/operations/incomes/history` | Агрегированная лента поступлений (INCOME) по проектам с видимостью в компании |
| GET | `/operations/incomes/pending-count` | `{ pending_action_count }` — поступления, где от пользователя ожидается шаг (см. `IncomePendingActionCountService`) |
| GET | `/companies/current` | Текущая компания |
| GET/POST | `/projects` | Список / создание проекта |
| GET | `/projects/{projectId}/participants` | Участники (пагинация) |
| POST | `/projects/{projectId}/participants` | Добавить участника |
| PATCH | `/projects/{projectId}/participants/{participantId}` | Смена роли |
| DELETE | `/projects/{projectId}/participants/{participantId}` | Удаление участника |
| GET | `/projects/{projectId}/participants/{participantId}/wallet` | Балансы кошелька участника |
| GET/POST | `/counterparties` | Список / создание контрагента |
| GET | `/projects/{projectId}/operations/transfers/recipients` | Список допустимых получателей по типу (`transfer_target_type` в query) |
| GET | `/projects/{projectId}/operations/transfers` | Список переводов |
| POST | `/projects/{projectId}/operations/transfers` | Создать перевод |
| GET | `/projects/{projectId}/operations/transfers/{transferId}` | Деталь перевода: в `data.transfer` — история статусов, при загрузке проекта — `project_name`; в `data.available_actions` — карта разрешённых POST-действий для UI |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/approve-project-head` | Утвердить (сотрудн. сценарий): дельты → `WAITING_24_HOURS`, старт 24 ч UTC |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/reject-project-head` | Отклонить на согласовании РП (с промежуточным `REJECTED` и возвратом в `CREATED`) |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/reset-approval` | Сотрудник: сброс из `PROJECT_HEAD_APPROVAL` в `CREATED` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/submit-for-approval` | Сотрудник: `CREATED` → `PROJECT_HEAD_APPROVAL` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/complete-immediate` | РП/партнёр: `CREATED` → `COMPLETED` с применением дельт (при создании HEAD/PARTNER обычно уже `COMPLETED`) |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/return-to-created` | Сотрудник: из `WAITING_24_HOURS` откат дельт → `CREATED` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/return-to-project-head-approval` | РП: из `WAITING_24_HOURS` откат дельт → `PROJECT_HEAD_APPROVAL` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/complete-waiting` | РП: `WAITING_24_HOURS` → `COMPLETED` (дельты уже применены) |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/rollback-completed` | Откат `COMPLETED` для сценария РП/партнёра (дельты снимаются) |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/return-completed-to-project-head-approval` | РП: из `COMPLETED` сценария сотрудника откат дельт → `PROJECT_HEAD_APPROVAL` |
| GET | `/projects/{projectId}/operations/incomes` | Список поступлений в проекте (пагинация) |
| POST | `/projects/{projectId}/operations/incomes` | Создать поступление (ТЗ-06) |
| GET | `/projects/{projectId}/operations/incomes/{incomeId}` | Деталь: `income`, `available_actions` |
| PATCH | `/projects/{projectId}/operations/incomes/{incomeId}` | Редактирование суммы/комментария в `CREATED` (только инициатор) |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/submit-to-customer-approval` | Отправка на согласование заказчика (дельты на кошельки по сценарию ТЗ-06) |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/complete-waiting` | Ручное завершение ожидания 24 ч (роль РП) |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/rollback-completed` | Откат завершённого поступления (роль РП, по правилам сервиса) |

Планировщик Laravel (см. `bootstrap/app.php`):

- **`operations:complete-expired-transfer-waiting`** (каждую минуту) — авто-`COMPLETED` для TRANSFER в `WAITING_24_HOURS` по UTC.
- **`operations:complete-expired-income-waiting`** (каждую минуту) — авто-завершение ожидания по INCOME.

### 6.4. Personal workspace

Префикс: `/api/personal-workspace`  
Middleware: `EnsurePersonalWorkspaceAccess` — пользователь с активным контрагентом в роли **EMPLOYEE / CONTRACTOR / SUPPLIER / CUSTOMER**.

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/context` | Контекст |
| GET | `/operations/transfers/history` | Лента переводов по всем проектам с участием пользователя (видимость как в company-контуре на проект) |
| GET | `/operations/transfers/pending-count` | То же правило счётчика «ожидают подтверждения», что и в company-workspace |
| GET | `/operations/incomes/history` | Агрегированная лента поступлений (личный контур) |
| GET | `/operations/incomes/pending-count` | Счётчик ожидающих действий по поступлениям |
| GET | `/companies` | Компании пользователя (в личном кабинете) |
| GET | `/projects` | Проекты пользователя (в ресурсе — `my_wallet`, **`my_participation`** с `level` и `project_role_code` для клиента) |
| GET | `/income-by-month` | Доход по месяцам (исполнительский контур) |

**Переводы (ТЗ-05.3):** те же доменные сервисы, что и в company-workspace (`TransferService`, `TransferRecipientListService`, `OperationVisibilityService`, `TransferLifecycleService`, **`TransferAvailableActionsService`**, **`TransferPendingActionCountService`**). Отличается префикс маршрута и проверка инициатора: **`PersonalWorkspaceTransferGuard`** — создание перевода, выдача списка получателей для формы и действия сотрудника (`submit-for-approval`, `reset-approval`, `return-to-created`) разрешены только если участник проекта **уровня `first`** и **роль в проекте `EMPLOYEE`**; иначе **403**. Поставщик, подрядчик, 2-й уровень и заказчик не создают переводы через этот контур (видимость списков переводов — по `OperationVisibilityService`: не РП видит только операции, где он initiator/sender/receiver).

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/projects/{projectId}/operations/transfers/recipients` | Получатели (`transfer_target_type` в query); для инициатора из личного кабинета — после guard |
| GET | `/projects/{projectId}/operations/transfers` | Список переводов проекта (с фильтром видимости) |
| POST | `/projects/{projectId}/operations/transfers` | Создать перевод |
| GET | `/projects/{projectId}/operations/transfers/{transferId}` | Деталь перевода |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/submit-for-approval` | Сотрудник: отправка на согласование РП |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/reset-approval` | Сотрудник: сброс из `PROJECT_HEAD_APPROVAL` |
| POST | `/projects/{projectId}/operations/transfers/{transferId}/return-to-created` | Сотрудник: откат из `WAITING_24_HOURS` → `CREATED` |
| GET | `/projects/{projectId}/operations/incomes` | Список поступлений (заказчик / видимость по `IncomeVisibilityService`) |
| GET | `/projects/{projectId}/operations/incomes/{incomeId}` | Деталь поступления |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/approve-customer` | Заказчик: согласовать |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/reject-customer` | Заказчик: отклонить |
| POST | `/projects/{projectId}/operations/incomes/{incomeId}/return-to-customer-approval` | Заказчик: вернуть на согласование |

Создание поступлений в текущем API — только в **company-workspace** (§6.3). Действия **только для РП/партнёра** по переводам остаются в **§6.3**. Доступ к проекту в personal-контуре: **`ProjectVisibilityService::assertCanAccessPersonalWorkspaceProject`**.

Подробное ТЗ по переводам в ЛК: `docs/TZ_05_3_GURU_Transfer_Personal_Workspace_Alignment.md`.

---

## 7. Доменная модель и связи

Ниже — сущности, которые уже используются в коде и БД (миграции в `backend/database/migrations/`).

### 7.1. Словари ролей

- **Компания**: `CompanyRoleCode` — OWNER, PARTNER, EMPLOYEE, CONTRACTOR, SUPPLIER, CUSTOMER (и др. по мере расширения словаря).
- **Проект**: `ProjectRoleCode` — PROJECT_HEAD, CUSTOMER, PARTNER, SUPERVISOR, EMPLOYEE, SUPPLIER, CONTRACTOR.

Роли хранятся в справочных таблицах (`dictionaries`), код — строковый FK в бизнес-таблицах.

### 7.2. Компания и контрагент

- **`companies`** — организация.
- **`counterparties`** — «лицо» в контексте компании: связь с `company_id`, опционально `user_id`, `company_role_code`, контактные поля (`full_name`, `email`), `is_active`.
- Контрагент может существовать без пользователя (сценарий invite-first).

Связи:

- `Counterparty` → `Company`, `User?`, `ProjectParticipant[]`.

### 7.3. Проект и участник

- **`projects`** — проект внутри компании.
- **`project_participants`** — участник проекта: `project_id`, `counterparty_id`, `project_role_code`, `level`, `is_active`.

Связи:

- `ProjectParticipant` → `Project`, `Counterparty`, `ProjectRole`, `ProjectParticipantWallet` (hasOne).

### 7.4. Кошелёк участника (`project_participant_wallets`)

Один кошелёк на участника. Поля балансов (все `decimal(15,2)`):

| Поле | Смысл в терминах TZ |
|------|---------------------|
| `personal_balance` | Личный баланс |
| `personal_earned` | Личный заработанный |
| `personal_received` | Личный полученный |
| `accountable_balance` | Подотчётный баланс |
| `accountable_received` | Подотчётный полученный |
| `accountable_spent` | Подотчётный потраченный |

Сервисы:

- `WalletFactoryService` — идемпотентное создание записи кошелька.
- `WalletBalanceService` / `WalletService` — чтение и единообразная выдача сумм (без потери точности через float).
- При создании проекта и при добавлении участника кошелёк обеспечивается (см. `CreateProjectController`, `ProjectParticipantService`).

### 7.5. Операции (база)

Таблица **`operations`**:

- `project_id`
- `initiator_project_participant_id`
- `operation_type` (`OperationType`: INCOME, TRANSFER, REPORT)
- `operation_status` (`OperationStatus`)

Таблица **`operation_status_histories`** — журнал переходов: `from_status`, `to_status`, `changed_by_project_participant_id`, опционально **`comment`**, **`author_user_id`**, **`author_full_name`**, `created_at`.

Для **TRANSFER** записи пишут **`TransferService`** и **`TransferLifecycleService`**. Для **INCOME** — **`IncomeService`** и **`IncomeLifecycleService`**. **`OperationTransitionService`** держит декларативную карту для типов, где она используется; жизненный цикл TRANSFER и INCOME реализован в специализированных lifecycle-сервисах.

Статусы (подмножество жизненного цикла GURU): CREATED, PROJECT_HEAD_APPROVAL, CUSTOMER_APPROVAL, WAITING_24_HOURS, COMPLETED, REJECTED, ROLLED_BACK.

**Терминальность:** метод enum **`isTerminal()`** сохраняет общий смысл (в т.ч. `REJECTED` — терминальный «в лоб»). Для бизнес-логики сервисов используется **`OperationStatus::isTerminalForOperationType(OperationType)`**: для **TRANSFER** переход с участием `REJECTED` не считается завершением операции (промежуточное отклонение с возвратом к редактированию); для **INCOME** — см. правила в **`IncomeLifecycleService`** и enum; для будущих **REPORT** — по необходимости расширяется. Кэш словаря статусов (`DictionaryCacheService`, ключ `guru:dict:operation_statuses:v2`) отдаёт и общий признак `terminal`, и карту **`is_terminal_by_operation_type`**.

### 7.6. Перевод (`transfer_operations`)

Таблица связывает операцию с деталями перевода:

- `operation_id`, `project_id`, `initiator_project_participant_id`
- `sender_project_participant_id`, `receiver_project_participant_id`
- **`receiver_counterparty_id`** (nullable) — для расчётного перевода: исходный контрагент-получатель до резолва во второго участника
- `transfer_target_type` — **`PERSONAL_BALANCE`** или **`ACCOUNTABLE_BALANCE`**
- `amount`, `comment?`, дублирование **`operation_status`** для удобства выборок (согласовано с базовой операцией)
- **`wallets_applied_at`**, **`wallets_reverted_at`**, **`waiting_period_started_at`** (UTC-семантика для 24 ч ожидания и аудита)

Сервисы:

- **`TransferBalanceService`** — математика дельт и **`revertTransfer`** (целочисленные центы при пересчёте).
- **`TransferParticipantResolver`** — допустимые получатели и автосоздание участника второго порядка для расчётного перевода.
- **`TransferService::create`** — создание `Operation` + `TransferOperation`: **PROJECT_HEAD / PARTNER** → сразу **`COMPLETED`** с применением дельт; **EMPLOYEE** → **`PROJECT_HEAD_APPROVAL`** без дельт.
- **`TransferLifecycleService`** — все действия после создания (согласование РП, 24 ч, завершение, откаты).
- **`TransferAvailableActionsService`** — карта **`available_actions`** для клиента (те же условия, что разрешают соответствующий POST).
- **`TransferPendingActionCountService`** — число переводов с «обязательным» входящим шагом для пользователя (whitelist **`PENDING_BADGE_ACTION_KEYS`**, без опциональных действий вроде `complete_immediate`).
- **`OperationVisibilityService::transferQueryForUserAcrossProjects`** — базовый запрос для агрегированной ленты переводов.
- **`TransferRecipientListService`** + `ListTransferRecipientsController` — список получателей для UI.

**ТЗ-05.2 v3 (сжато):** подотчётный перевод — получатели участники 1-го порядка (PROJECT_HEAD, PARTNER, EMPLOYEE); расчётный — контрагенты с автодобавлением 2-го уровня; 24 ч отсчитываются в UTC от `waiting_period_started_at`.

**ТЗ-05.3:** расчётный перевод (`PERSONAL_BALANCE`) — любой активный контрагент компании, включая роль **`CUSTOMER`**; маппинг company→project для 2-го порядка: `CUSTOMER` → `CUSTOMER` в проекте.

**Уточнения реализации (2026-05):** перевод **на подотчёт самому себе** запрещён; **на расчётный себе** — разрешён. В выдаче списка для подотчётного получателя **текущий участник исключается**. Для расчётного списка в кандидатах контрагентов допускаются роли **`OWNER`**, **`CUSTOMER`** и остальные из ТЗ-05.3. При автосоздании участника второго порядка для **OWNER** задано согласованное отображение роли в проекте (`TransferParticipantResolver`).

### 7.6.1. Поступление (`income_operations`)

Таблица **`income_operations`** — детали операции типа **INCOME**:

- связь с **`operations`** (`operation_id`), `project_id`, инициатор, **`project_head_project_participant_id`**, **`customer_project_participant_id`**
- `amount`, `comment?`, **`operation_status`**, метки **`wallets_applied_at`**, **`wallets_reverted_at`**, **`waiting_period_started_at`**

Сервисы:

- **`IncomeBalanceService`** — начисление/откат на **подотчётные** поля кошельков заказчика и руководителя проекта (`accountable_balance`, `accountable_received`).
- **`IncomeService`** — создание черновика в **`CREATED`**.
- **`IncomeLifecycleService`** — все переходы (отправка на согласование заказчика, решение заказчика, ожидание 24 ч, завершение, откаты по правилам ТЗ-06).
- **`IncomeAvailableActionsService`**, **`IncomePendingActionCountService`**, **`IncomeVisibilityService`**, **`IncomeProjectParticipantsResolver`**.

Подробнее: `docs/GURU_INCOME_OPERATION_REFERENCE.md`.

### 7.7. Диаграмма связей (обзор)

```mermaid
erDiagram
    User ||--o{ Counterparty : has
    Company ||--o{ Counterparty : has
    Company ||--o{ Project : has
    Project ||--o{ ProjectParticipant : has
    Counterparty ||--o{ ProjectParticipant : has
    ProjectParticipant ||--o| ProjectParticipantWallet : has
    Project ||--o{ Operation : has
    ProjectParticipant ||--o{ Operation : initiates
    Operation ||--o{ OperationStatusHistory : has
    Operation ||--o| TransferOperation : typed_as
    Operation ||--o| IncomeOperation : typed_as
    ProjectParticipant ||--o{ TransferOperation : sender_or_receiver
```

---

## 8. Производительность и качество API

Реализовано в духе TZ «Performance Foundation (1000 users)»:

- Миграция с **индексами** под частые фильтры/связи (составные и одиночные) — см. `2026_05_09_000004_add_performance_indexes_for_1000_users.php`.
- **Жадная загрузка** в контроллерах списков/show, где возможен N+1 (участники, переводы — по мере развития проверять `with(...)`).
- **`DictionaryCacheService`** — кэширование статичных словарей (роли, типы/статусы операций) для снижения нагрузки на БД.
- Пагинация списков с ограничением `per_page`.

---

## 9. Mobile app (Flutter)

### 9.1. Навигация

`go_router` в `mobile_app/lib/core/routing/router_provider.dart`:

- `/` Splash → `/login` | `/register` | `/workspaces`
- Экран `/workspaces`: кнопка **«Создать компанию»** видна **всегда** (в т.ч. при непустом списке)
- `/company/:companyId` → `CompanyWorkspaceShell`
- `/personal` → `PersonalWorkspaceShell` (нижняя навигация: главная исполнителя, **«Операции»** — `PersonalOperationsTab`, уведомления-заглушка)
- `/personal/companies` — полный список компаний личного кабинета
- `/customer`, `/customer/companies`, `/customer/companies/:companyId/projects` — кабинет заказчика (тот же personal-workspace API, фильтр ролей)
- `/create-company` — сценарий создания компании

Для экранов участников и переводов используются **императивные** `Navigator.push` с `MaterialPageRoute` (внутри company workspace и из personal «Операции»).

### 9.2. Слои фичи

Для каждой области:

- `domain/` — типизированные модели и enum’ы.
- `data/*_api.dart` — вызовы REST через `ApiClient`.
- `data/*_repository.dart` — фасад для UI/провайдеров.
- `providers.dart` — Riverpod.

Общие модели ответа: `ApiResponse`, `Paginated`, обработка ошибок — `ApiException` + `meta.request_id`.

`ApiClient` (Dio): **`ResponseType.plain`**, **`followRedirects: false`**, для мутаций — заголовок JSON, разбор тела с отловом HTML (сообщение пользователю вместо низкоуровневого `FormatException`). На Android для dev-HTTP — **`usesCleartextTraffic`** и разрешение **`INTERNET`** в манифесте.

### 9.3. UI и единый стиль

- Базовые виджеты: `AppScaffold`, `AppCard`, `AppInput`, `AppButton`, тема `guru_theme.dart`.
- **`AppScaffold`:** для заголовка с подзаголовком и блоком «имя / роль компании» задан увеличенный **`toolbarHeight`**, чтобы не обрезать название проекта и многострочную роль; подзаголовок до двух строк.
- **Company workspace** (`CompanyWorkspaceShell`): нижняя навигация — «Главная», уведомления (заглушка), **«Операции»** — picker типа операции (**поступление** → `CreateIncomeScreen`, **перевод** → `CreateTransferScreen`, отчёт — заглушка); после успешного создания **перевода** — переход на вкладку **«Операции»**, snackbar успеха, обновление **`transferPendingActionCountProvider`**. На главной вкладке в шапке — **`LocaleSwitchButton`** (RU/EN), как на экранах авторизации.
- **Главная компании** (`CompanyDashboardScreen`): реальные счётчики контрагентов и активных проектов (см. репозитории); карточка квартальной аналитики (метрики дохода/долга — плейсхолдеры до отчётов); столбики активных проектов по месяцам текущего квартала (`company_dashboard_stats.dart`). Плитка «История операций» → **`AggregatedTransfersHistoryScreen`** (пока только **переводы**); бейдж **`pending_action_count`** — из **`transferPendingActionCountProvider`** (только TRANSFER; для поступлений отдельный API `…/operations/incomes/pending-count`).
- Живая работа с переводами также из **участников проекта** (⇄) → **`TransfersScreen`** / **`CreateTransferScreen`** / **`TransferDetailScreen`**: таймлайн **`status_history`**, кнопки по **`available_actions`**, при необходимости **`pushReplacement`** после POST; **`invalidate` pending** на возврате, не в момент нажатия на детали. **Поступления** — **`CreateIncomeScreen`**, **`IncomeDetailScreen`** (`IncomesRepository`).
- **Personal workspace (исполнитель)** — вкладка **«Операции»** (`personal_operations_tab.dart`): пункт «Перевод» (только проекты, где `my_participation` = first + EMPLOYEE), список проектов → **`TransfersScreen`** / **`CreateTransferScreen`** с **`TransferApiScope.personal`**; «Отчёт» — disabled. Поставщик/подрядчик/2-й уровень: просмотр без кнопки создания (`canCreateTransfer: false`).
- **Проекты** → **Участники** (`ProjectParticipantsScreen`): кошелёк, переводы; без дублирующей кнопки «Добавить» в списке (только иконка в app bar).

### 9.4. Соответствие backend enum’ам

Flutter дублирует коды в:

- `features/operations/domain/operation_type.dart`
- `operation_status.dart`
- `transfer_target_type.dart`
- модели `TransferOperation`, `IncomeOperation`, `Operation`, `OperationStatusHistory`

При добавлении новых значений — синхронизировать PHP enum и Dart.

---

## 10. Что уже сделано (чеклист по модулям TZ)

| Модуль / тема | Состояние |
|---------------|-----------|
| Аутентификация Sanctum, профиль | Реализовано (register, token, me, logout) |
| Workspaces list + context | Реализовано |
| Company: создание, текущая компания | Реализовано |
| Counterparties в company workspace | Реализовано (листинг, создание, ресурс с контактами) |
| Projects: список, создание | Реализовано |
| Project participants (TZ-03C) | CRUD API, пагинация, роли, UI со списком/редактированием/удалением |
| Wallet foundation (TZ-04) | Таблица балансов, фабрика, API баланса, экран в приложении |
| Operation lifecycle foundation (TZ-05A) | operations + status history + transition service + исключение 422 |
| Performance foundation | Индексы, кэш словарей, стандарты пагинации |
| Transfer operation (ТЗ-05.2 v3) | Полный контур: lifecycle, recipients API, POST **201** / разбор ответа на клиенте; планировщик 24 ч UTC; **`available_actions`**, pending-count, агрегированная история переводов; Flutter: дашборд компании, список/создание/деталь/история |
| Income operation (ТЗ-06) | Backend: `income_operations`, `IncomeService`, `IncomeLifecycleService`, `IncomeBalanceService`, агрегированная история и pending-count, заказчик personal-workspace; Flutter: создание и деталь поступления |
| Вкладка «Операции» в нижнем меню компании | Контент вкладки — **плейсхолдер**; сценарии — через **picker** «Операции» и через **участников проекта** |

---

## 11. Стандарты разработки GURU (сводка)

1. **Два воркспейса** — не смешивать company- и personal-эндпойнты и бизнес-правила.
2. **Единый JSON-контракт** — `ok`, `data`, `meta.request_id`; ошибки — `ok: false`, `error`, `meta.request_id`.
3. **Типы денег** — decimal в БД; не использовать float для денежной логики.
4. **Контроллеры** — только координация; валидация в FormRequest; ответы через Resource и `ApiResponse`.
5. **Операции TRANSFER** — после создания только `TransferLifecycleService` (создание — `TransferService`); **INCOME** — `IncomeLifecycleService` (создание — `IncomeService`); история в `operation_status_histories`. Декларативная карта `OperationTransitionService` — для типов, где она подключена в коде (TRANSFER/INCOME идут через свои lifecycle-сервисы).
6. **Переводы** — математика в `TransferBalanceService`; **поступления** — в `IncomeBalanceService`; создание трансфера в `TransferService::create`; получатели — `TransferParticipantResolver` / API recipients.
7. **Пагинация** — `page`, `per_page`, `total`, `last_page`; default 20, max 50.
8. **Мобильный клиент** — repository + typed models; следовать визуальным паттернам `AppScaffold` и существующих экранов компании.
9. **Согласованность кодов** — строковые enum-коды в PHP и Dart должны совпадать.

---

## 12. Расширение документа

При добавлении новых модулей имеет смысл:

- дополнять §6 таблицей маршрутов;
- дополнять §7 сущностями и связями;
- фиксировать новые бизнес-инварианты в §11.

---

*Версия документа: 2026-05-09 — добавлены маршруты и домен INCOME (ТЗ-06), второй планировщик `complete-expired-income-waiting`, раздел `income_operations`; обновлены Flutter-сценарии и чеклист. Отражает кодовую базу GuruApp на указанную дату.*
