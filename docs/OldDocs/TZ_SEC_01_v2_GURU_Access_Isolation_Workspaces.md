# ТЗ-SEC-01 v2 — Access Isolation + Role-Based Workspace Routing GURU

## 1. Цель

Исправить критичный баг доступа и зафиксировать единую архитектуру видимости данных в GURU.

После выполнения этапа пользователь должен видеть только:

- компании, где он является владельцем или добавлен как контрагент;
- проекты, где он имеет доступ по роли и участию;
- операции, где он участвует, либо все операции проекта, если он является Руководителем проекта;
- интерфейс, соответствующий выбранному сценарию входа.

Критичная проблема:

```text
Новый зарегистрированный пользователь сейчас может видеть чужой проект и входить в него как владелец.
```

Это security bug. Исправить до реализации операции «Поступление».

---

## 2. Важная корректировка относительно текущего blueprint

В текущем проекте уже зафиксированы два backend workspace-контура:

```text
Company Workspace
Personal Workspace
```

Их нельзя смешивать и нельзя добавлять универсальный endpoint, который сам решает, какой это сценарий.

Поэтому в этом ТЗ:

```text
Customer Workspace
Worker Workspace
```

— это НЕ новые backend workspace-контуры.

Это разные Flutter/UI-shells и разные сценарии отображения внутри Personal Workspace.

Backend должен оставаться в рамках:

```text
/api/company-workspace/{companyId}/...
/api/personal-workspace/...
```

Если нужны отдельные контроллеры для customer/worker — они должны быть явно названы и находиться внутри personal-workspace контура, а не создавать третий общий workspace.

---

## 3. Текущий стек

Backend:

- Laravel
- PostgreSQL
- Sanctum
- Feature-first modules
- ApiResponse + request_id
- Policies / Middleware / Services

Frontend:

- Flutter
- Riverpod
- go_router
- Dio
- RU/EN localization
- UI design system

---

## 4. Что уже реализовано

Уже есть:

- Auth;
- Workspaces;
- Company Workspace;
- Personal Workspace;
- Companies;
- Counterparties;
- Projects;
- ProjectParticipants;
- ProjectParticipantWallet;
- Transfer Operation;
- OperationTypePicker;
- localization foundation;
- UI foundation.

### 4.1 Дополнение — актуализация 2026-05-09

Два backend-контура без смешения сохранены:

- **`/api/company-workspace/{companyId}/…`** — OWNER/PARTNER компании;
- **`/api/personal-workspace/…`** — личные роли (EMPLOYEE, SUPPLIER, CONTRACTOR, CUSTOMER и др.).

**Flutter (имена оболочек в коде могут отличаться от черновиков «Worker/Customer workspace» в тексте ТЗ):**

- **`CompanyWorkspaceShell`** — главная компании (дашборд), проекты, контрагенты; нижняя навигация и picker «Операции» (перевод / заглушки); язык **`LocaleSwitchButton`** на главной вкладке.
- **`PersonalWorkspaceShell`** — личный кабинет исполнителя (проекты, операции, доход и т.д.); отдельного класса с именем `WorkerWorkspaceShell` в репозитории может не быть — это один personal-контур API.
- **`CustomerWorkspaceShell`** — маршруты `/customer`, те же personal-workspace endpoints с фильтром роли заказчика.

Сервисы доступа и видимости (эталонные имена в коде): **`EnsureCompanyWorkspaceAccess`**, **`EnsurePersonalWorkspaceAccess`**, **`ProjectVisibilityService`**, **`OperationVisibilityService`**, при необходимости **`WorkspaceResolver`** и связывание пользователя с контрагентом.

Полная таблица маршрутов, экранов и сценариев перевода — **`PROJECT_CONTEXT_GURU.md`**, **`docs/GURU_FULL_PROJECT_BLUEPRINT.md`**.

Сценарии изоляции **§24–§25** этого документа рекомендуется прогонять при изменениях доступа и списков workspace.

---

## 5. Главные архитектурные инварианты

### 5.1 Backend — источник прав

Backend является единственным источником прав доступа.

Flutter может скрывать лишние элементы, но не является защитой.

Все ограничения проверяются:

- в query;
- в middleware;
- в policies;
- в services;
- в endpoints.

---

### 5.2 Не отдавать fallback-данные

Запрещено:

- отдавать первую компанию из БД;
- отдавать первый проект из БД;
- использовать `company_id = 1`;
- использовать `project_id = 1`;
- считать пользователя OWNER без Counterparty;
- привязывать нового пользователя к demo company/project.

---

### 5.3 Связь доступа

Пользователь получает доступ только через цепочку:

```text
User
→ Counterparty
→ ProjectParticipant
→ Operation participation
```

Исключения:

- OWNER видит свою компанию и проекты компании;
- PROJECT_HEAD видит все операции своего проекта;
- OWNER может видеть company-level financial operations только через отдельный явно разрешённый owner-scope endpoint/screen, если он реализован.

---

## 6. Базовые сущности доступа

### 6.1 User

`User` — зарегистрированный пользователь.

### 6.2 Counterparty

`Counterparty` — пользователь/контакт внутри конкретной компании.

Один User может быть Counterparty в нескольких компаниях.

Counterparty может быть создан до регистрации пользователя.

### 6.3 ProjectParticipant

`ProjectParticipant` — Counterparty внутри конкретного проекта.

Один Counterparty может быть участником нескольких проектов.

Участник проекта бывает:

```text
level = first
level = second
```

### 6.4 Company Workspace

Интерфейс конкретной выбранной компании.

Используется для:

```text
OWNER
PARTNER
```

### 6.5 Personal Workspace

Backend-контур для личных интерфейсов.

Используется для:

```text
CUSTOMER
EMPLOYEE
SUPPLIER
CONTRACTOR
```

Внутри Flutter делится на:

```text
CustomerWorkspaceShell
WorkerWorkspaceShell
```

---

## 7. Регистрация и связывание User с Counterparty по email

### 7.1 Новый email

Если email нового User не найден среди Counterparty:

- создать User;
- не показывать чужие компании;
- не показывать чужие проекты;
- показать возможность создать свою компанию;
- после создания компании User становится OWNER только этой новой компании.

---

### 7.2 Email уже есть у Counterparty

Если email нового User совпал с `counterparties.email`:

- связать найденный Counterparty с User;
- заполнить `counterparty.user_id = user.id`;
- не создавать дубль Counterparty;
- пользователь должен увидеть эту компанию в Workspace Entry;
- пользователь должен войти под той ролью, под которой его добавили.

Если email найден у Counterparty в нескольких компаниях:

- связать User со всеми подходящими Counterparty;
- показать все доступные сценарии входа;
- доступ внутри каждой компании определяется ролью Counterparty и ProjectParticipant.

---

### 7.3 Защита от перезаписи

Если `counterparty.user_id` уже заполнен другим User:

- не перезаписывать;
- не связывать автоматически;
- зафиксировать conflict в логах;
- не давать доступ текущему User через этот Counterparty.

---

### 7.4 Нормализация email

Перед сравнением email:

- trim;
- lowercase;
- использовать единый формат сравнения.

---

### 7.5 Сервис связывания

Создать или доработать:

```text
UserCounterpartyLinkingService
```

Responsibilities:

- найти Counterparty по email;
- связать с User;
- не создавать дубли;
- не перезаписывать чужой user_id;
- работать идемпотентно;
- возвращать список связанных Counterparty.

Вызывать:

- после регистрации;
- при login/token issue;
- при `/api/auth/me`, если это безопасно и идемпотентно.

---

## 8. Workspace Entry после авторизации

После авторизации пользователь попадает на экран выбора доступных сценариев входа.

Endpoint:

```http
GET /api/workspaces
```

Должен возвращать только доступные текущему User entries.

---

## 9. Формат workspace entries

Рекомендуемый контракт:

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "type": "company",
        "company": {
          "id": 1,
          "name": "Company A"
        },
        "company_role": "OWNER",
        "label": "Руководитель компании"
      },
      {
        "type": "customer",
        "label": "Заказчик",
        "companies_count": 2,
        "projects_count": 5
      },
      {
        "type": "worker",
        "label": "Моя работа",
        "company_roles": ["EMPLOYEE", "SUPPLIER"],
        "companies_count": 3,
        "projects_count": 7
      }
    ],
    "can_create_company": true
  },
  "meta": {
    "request_id": "..."
  }
}
```

---

## 10. Правила отображения Workspace Entry

### 10.1 Company entry

Показывать, если User связан с Counterparty роли:

```text
OWNER
PARTNER
```

Поведение:

- OWNER входит в Company Workspace как руководитель компании;
- PARTNER входит в Company Workspace как партнёр компании.

---

### 10.2 Customer entry

Показывать, если User связан с Counterparty роли:

```text
CUSTOMER
```

и есть проекты, где этот Counterparty является ProjectParticipant роли:

```text
CUSTOMER
```

Переход:

```text
CustomerWorkspaceShell
```

---

### 10.3 Worker entry

Показывать, если User связан с Counterparty роли:

```text
EMPLOYEE
SUPPLIER
CONTRACTOR
```

и есть проекты, где этот Counterparty является ProjectParticipant.

Переход:

```text
WorkerWorkspaceShell
```

---

### 10.4 Create company

Всегда показывать:

```text
Создать компанию
```

При создании компании:

- создаётся Company;
- создаётся Counterparty с ролью OWNER;
- `counterparty.user_id = current user.id`;
- пользователь получает Company Workspace этой компании.

---

## 11. Три главных интерфейса

### 11.1 Company Workspace — Руководитель компании / Партнёр

Backend:

```text
/api/company-workspace/{companyId}/...
```

Frontend:

```text
CompanyWorkspaceShell
```

Роли:

```text
OWNER
PARTNER
```

#### OWNER

Видит:

- свою компанию;
- все проекты своей компании;
- всех контрагентов своей компании;
- company-level dashboard.

Операции:

- OWNER может видеть company-level операции только через отдельный явно разрешённый экран/endpoint;
- в проектных endpoints финансовые операции не должны автоматически открываться всем OWNER без явного правила.

#### PARTNER

Видит:

- компанию, где он Counterparty;
- интерфейс компании;
- проекты, где он ProjectParticipant.

Если PARTNER является PROJECT_HEAD:

- видит все операции проекта;
- работает как Руководитель проекта.

Если PARTNER обычный участник проекта:

- видит только операции, где участвует.

---

### 11.2 Customer Workspace — Заказчик

Backend:

```text
/api/personal-workspace/...
```

Frontend:

```text
CustomerWorkspaceShell
```

Заказчик видит:

- все компании, внутри которых у него есть проекты;
- проекты внутри этих компаний, где он ProjectParticipant с ролью CUSTOMER;
- доступную детализацию проекта;
- операции, где он участвует:
  - Поступление;
  - Отчёт;
  - операции на подтверждении;
  - доступная история операций.

Заказчик НЕ видит:

- чужие компании;
- проекты, где он не участник;
- внутренние переводы между участниками;
- операции, где он не участвует.

---

### 11.3 Worker Workspace — Сотрудник / Поставщик / Подрядчик

Backend:

```text
/api/personal-workspace/...
```

Frontend:

```text
WorkerWorkspaceShell
```

Роли:

```text
EMPLOYEE
SUPPLIER
CONTRACTOR
```

Пользователь видит:

- все компании, где он Counterparty и имеет проекты;
- роль в каждой компании;
- проекты внутри этих компаний, где он ProjectParticipant первого или второго порядка;
- операции, где он участвует.

Пользователь НЕ видит:

- чужие компании;
- проекты, где он не участник;
- операции других участников;
- внутренние данные проекта, к которым он не привязан.

---

## 12. Backend: Company Workspace access

Проверить и доработать:

```text
EnsureCompanyWorkspaceAccess
```

Правила:

- user должен быть связан с Counterparty этой company;
- `counterparty.user_id = current user.id`;
- Counterparty должен быть активным;
- роль Counterparty:
  - OWNER
  - PARTNER

Нельзя:

- пропускать по company_id без user_id;
- пропускать по project participant без company counterparty;
- пропускать нового User без Counterparty;
- использовать fallback company.

---

## 13. Backend: Personal Workspace access

Проверить и доработать:

```text
EnsurePersonalWorkspaceAccess
```

Правила:

- user должен быть связан хотя бы с одним активным Counterparty роли:
  - CUSTOMER
  - EMPLOYEE
  - SUPPLIER
  - CONTRACTOR;
- данные внутри Personal Workspace всё равно фильтруются по ProjectParticipant.

Нельзя:

- отдавать все компании пользователя только по Counterparty без проверки проектов, если экран показывает проекты;
- отдавать проекты без ProjectParticipant.

---

## 14. Backend: Project visibility

Создать или доработать:

```text
ProjectVisibilityService
```

Правила:

### OWNER

В Company Workspace:

```text
OWNER → все проекты своей company
```

### PARTNER

В Company Workspace:

```text
PARTNER → только проекты, где его Counterparty есть в ProjectParticipant
```

### CUSTOMER

В Customer Workspace:

```text
CUSTOMER → только проекты, где он ProjectParticipant role CUSTOMER
```

### EMPLOYEE / SUPPLIER / CONTRACTOR

В Worker Workspace:

```text
только проекты, где он ProjectParticipant
```

Учитывать:

```text
level = first
level = second
```

---

## 15. Backend: Operation visibility

Создать или доработать:

```text
OperationVisibilityService
```

Общее правило:

```text
Пользователь видит операцию, если он в ней участвует.
```

Участие в операции может быть через:

- initiator_project_participant_id;
- sender_project_participant_id;
- receiver_project_participant_id;
- customer_project_participant_id;
- report participant;
- approval participant;
- linked participant in report/expense distribution.

### PROJECT_HEAD

```text
PROJECT_HEAD → все операции своего проекта
```

### PARTNER

Если PARTNER является PROJECT_HEAD:

```text
все операции проекта
```

Если обычный участник:

```text
только операции, где участвует
```

### CUSTOMER

```text
только Поступление / Отчёт / подтверждения / история, где он участвует
```

Не показывать внутренние Transfer между участниками.

### EMPLOYEE / SUPPLIER / CONTRACTOR

```text
только операции, где участвует
```

### OWNER

OWNER company-level access к операциям должен быть отдельным явно разрешённым правилом.

Не смешивать owner company dashboard и participant operation endpoints.

---

## 16. Backend: не дублировать существующие сервисы

В текущем blueprint уже есть:

```text
WorkspaceResolver
EnsureCompanyWorkspaceAccess
EnsurePersonalWorkspaceAccess
```

Поэтому:

- не создавать дубли, если существующий сервис можно расширить;
- сначала проверить текущую реализацию;
- если создаётся новый сервис, он должен дополнять, а не обходить WorkspaceResolver.

Допустимый вариант:

```text
WorkspaceResolver
→ использует UserCounterpartyLinkingService
→ использует ProjectVisibilityService
→ формирует entries
```

---

## 17. Backend: endpoints

### 17.1 GET /api/workspaces

Должен возвращать:

- company entries;
- customer entry;
- worker entry;
- can_create_company.

Не должен возвращать чужие компании и проекты.

### 17.2 GET /api/company-workspace/{companyId}/projects

Правила:

- OWNER → все проекты компании;
- PARTNER → только свои ProjectParticipant projects.

### 17.3 GET /api/personal-workspace/companies

Правила:

- CUSTOMER → компании, где есть customer-projects;
- EMPLOYEE/SUPPLIER/CONTRACTOR → компании, где есть participant-projects.

### 17.4 GET /api/personal-workspace/projects

Правила:

- возвращать только проекты, где текущий User связан через Counterparty → ProjectParticipant.

### 17.5 Transfer operations endpoints

Проверить, что:

- PROJECT_HEAD видит все transfers проекта;
- sender видит свой transfer;
- receiver видит свой transfer;
- другой participant не видит transfer, если не участвует;
- user вне проекта не видит transfer.

---

## 18. Flutter: Workspace Entry

Доработать экран после авторизации.

Карточки:

### 18.1 Company Workspace card

```text
Компания: <company name>
Роль: Руководитель компании / Партнёр
Кнопка: Войти
```

Переход:

```text
CompanyWorkspaceShell(companyId)
```

### 18.2 Customer Workspace card

```text
Заказчик
Компаний: N
Проектов: N
Кнопка: Открыть
```

Переход:

```text
CustomerWorkspaceShell
```

### 18.3 Worker Workspace card

```text
Моя работа
Компаний: N
Проектов: N
Роли: Сотрудник / Поставщик / Подрядчик
Кнопка: Открыть
```

Переход:

```text
WorkerWorkspaceShell
```

### 18.4 Create company card

```text
Создать компанию
```

---

## 19. Flutter: Customer Workspace Shell

Создать или доработать:

```text
CustomerWorkspaceShell
```

Минимально:

- список компаний;
- проекты заказчика внутри компаний;
- переход в проект;
- заглушка операций на подтверждении;
- использовать Personal Workspace API;
- не создавать отдельный backend customer-workspace контур.

---

## 20. Flutter: Worker Workspace Shell

Создать или доработать:

```text
WorkerWorkspaceShell
```

Минимально:

- список компаний;
- роль пользователя в компании;
- проекты внутри каждой компании;
- переход в проект;
- доступные операции;
- использовать Personal Workspace API;
- не создавать отдельный backend worker-workspace контур.

---

## 21. Flutter: Company Workspace

Проверить:

- OWNER входит в конкретную компанию;
- PARTNER входит в конкретную компанию;
- PARTNER видит только доступные проекты;
- проект, где PARTNER является PROJECT_HEAD, открывается с расширенными правами проекта.

---

## 22. Localization

Все новые строки через:

```dart
context.l10n
```

В русском интерфейсе не должно быть английских слов.

---

## 23. Что запрещено

НЕ делать:

- Поступление;
- Отчёт;
- новую финансовую математику;
- изменение TransferBalanceService;
- realtime;
- websocket;
- offline sync;
- полноценный UI redesign;
- second-order participant auto-create, если это не требуется для проверки доступа;
- массовый refactor без необходимости;
- третий backend workspace-контур `/customer-workspace` или `/worker-workspace`.

---

## 24. Проверки backend

### 24.1 User A / User B isolation

1. User A создаёт компанию.
2. User A создаёт проект.
3. User B регистрируется с новым email.
4. User B не видит компанию User A.
5. User B не видит проект User A.
6. User B не может открыть Company Workspace User A.
7. API возвращает 403 или empty list.

### 24.2 Existing Counterparty linking

1. User A создаёт компанию.
2. User A добавляет Counterparty Partner с email `partner@test.local`.
3. User C регистрируется с email `partner@test.local`.
4. Система связывает User C с Counterparty.
5. User C видит компанию.
6. User C может войти в Company Workspace как PARTNER.
7. User C видит только проекты, где он ProjectParticipant.

### 24.3 Customer Workspace

1. User A добавляет Customer Counterparty.
2. Создаёт проект с этим Customer.
3. Customer регистрируется по email.
4. Customer видит Customer Workspace.
5. Customer видит компанию и проект, где он CUSTOMER.
6. Customer не видит чужие проекты.

### 24.4 Worker Workspace

1. User A добавляет Employee/Supplier/Contractor Counterparty.
2. Добавляет его в проект как ProjectParticipant.
3. Пользователь регистрируется по email.
4. Видит Worker Workspace.
5. Видит только компании и проекты, где участвует.

### 24.5 Operations visibility

Проверить на текущих Transfer operations:

- PROJECT_HEAD видит все transfers проекта;
- receiver видит transfer, где он receiver;
- sender видит transfer, где он sender;
- другой participant проекта не видит transfer, где не участвует;
- пользователь вне проекта не видит transfer.

---

## 25. Проверки Flutter

Выполнить:

```cmd
flutter analyze
```

Проверить вручную:

1. Новый пользователь не видит чужие проекты.
2. Пользователь с email существующего Counterparty видит назначенную компанию.
3. OWNER входит в Company Workspace.
4. PARTNER входит в Company Workspace.
5. CUSTOMER входит в Customer Workspace.
6. EMPLOYEE/SUPPLIER/CONTRACTOR входят в Worker Workspace.
7. Создать компанию можно из Workspace Entry.
8. После смены языка интерфейсы остаются корректными.
9. Нет английских слов в русском интерфейсе.

---

## 26. Команды проверки

Backend:

```cmd
php artisan route:list
php artisan migrate
```

Flutter:

```cmd
flutter analyze
```

Опционально:

```cmd
flutter run -d emulator-5554 --dart-define=GURU_API_BASE_URL=http://10.0.2.2:8000/api
```

---

## 27. После выполнения Cursor должен показать

1. Где была причина утечки доступа.
2. Какие endpoints были небезопасны.
3. Какие middleware/policies/services исправлены.
4. Как реализовано связывание User с Counterparty по email.
5. Как теперь формируется Workspace Entry.
6. Как разделены Company / Customer / Worker UI-shells.
7. Как сохранены два backend-контура: Company Workspace и Personal Workspace.
8. Какие query-фильтры добавлены.
9. Какие Flutter screens/shells добавлены или изменены.
10. Результат `php artisan route:list`.
11. Результат `flutter analyze`.
12. Результаты ручных проверок User A / User B / Partner / Customer / Worker.

---

## 28. Модель Cursor

Использовать:

```text
Sonnet 4.6
Agent
MAX OFF
Thinking ON
Effort High
```

Причина:

- задача критичная по безопасности;
- нужно аккуратно поправить доступы;
- backend + Flutter;
- важно не сломать текущий blueprint;
- MAX не нужен при строгом scope.

---

## 29. Главное правило

Пользователь GURU должен видеть только те данные, к которым он связан через:

```text
User
→ Counterparty
→ ProjectParticipant
→ Operation participation
```

Исключения:

- OWNER видит свою компанию и проекты компании;
- PROJECT_HEAD видит все операции своего проекта;
- OWNER company-level operations visibility реализуется только отдельным явным правилом, а не автоматически через project participant endpoints.
