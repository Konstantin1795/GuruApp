# ТЗ-05.3 — Transfer Access & Personal Workspace Alignment GURU

## 1. Цель

Проверить и скорректировать реализацию операции **«Перевод»** после ТЗ-05.2 v3, чтобы она соответствовала архитектуре GURU по workspace-доступам, ролям, получателям и видимости операций.

Это не новая операция и не переписывание Transfer с нуля.

Нужно точечно проверить и поправить:

- создание перевода сотрудником первого порядка из **Personal Workspace**;
- запрет создания операций для Поставщика, Подрядчика и Сотрудника второго порядка;
- получателей расчётного перевода `PERSONAL_BALANCE`;
- доступность кнопки «Операции» по ролям;
- соответствие текущего кода архитектурным стандартам GURU.

---

## 2. Контекст

Уже реализовано по ТЗ-05.2 v3:

- Transfer lifecycle;
- `TransferBalanceService`;
- `TransferLifecycleService`;
- `TransferParticipantResolver`;
- recipients API;
- `WAITING_24_HOURS`;
- scheduled command для автозавершения 24 часов;
- type-specific terminality через `isTerminalForOperationType`;
- история статусов с комментариями, ФИО автора и временем.

Не ломать уже реализованную финансовую математику и lifecycle.

---

## 3. Главный архитектурный конфликт

Сейчас endpoints перевода в основном находятся в контуре:

```text
/api/company-workspace/{companyId}/projects/{projectId}/operations/transfers
```

Но **Сотрудник первого порядка** не должен работать в Company Workspace.

Сотрудник работает из своего личного интерфейса:

```text
Personal Workspace
```

Поэтому для сотрудника первого порядка нужны endpoints в контуре:

```text
/api/personal-workspace/projects/{projectId}/operations/transfers
```

Company Workspace доступен для:

```text
OWNER
PARTNER
```

Personal Workspace используется для:

```text
EMPLOYEE
SUPPLIER
CONTRACTOR
CUSTOMER
```

---

## 4. Кто может создавать операцию «Перевод»

### 4.1 Разрешено создавать

Создавать операцию «Перевод» могут только участники проекта первого порядка:

```text
PROJECT_HEAD
PARTNER
EMPLOYEE
```

Правила:

- `PROJECT_HEAD` создаёт перевод из Company Workspace;
- `PARTNER` первого порядка создаёт перевод из Company Workspace;
- `EMPLOYEE` первого порядка создаёт перевод из Personal Workspace.

### 4.2 Запрещено создавать

Не могут создавать никакие операции:

```text
SUPPLIER
CONTRACTOR
EMPLOYEE level = second
SUPPLIER level = second
CONTRACTOR level = second
CUSTOMER
SUPERVISOR
```

Они могут только:

- видеть компании, где участвуют;
- видеть проекты, где они являются участниками;
- видеть операции, где они участвуют;
- видеть только информацию, относящуюся к ним.

---

## 5. Personal Workspace endpoints для EMPLOYEE first-order

Добавить или проверить наличие endpoints:

```http
GET  /api/personal-workspace/projects/{projectId}/operations/transfers/recipients?transfer_target_type=...
GET  /api/personal-workspace/projects/{projectId}/operations/transfers
POST /api/personal-workspace/projects/{projectId}/operations/transfers
GET  /api/personal-workspace/projects/{projectId}/operations/transfers/{transferId}
```

Для действий сотрудника:

```http
POST /api/personal-workspace/projects/{projectId}/operations/transfers/{transferId}/submit-for-approval
POST /api/personal-workspace/projects/{projectId}/operations/transfers/{transferId}/reset-approval
POST /api/personal-workspace/projects/{projectId}/operations/transfers/{transferId}/return-to-created
```

---

## 6. Что сотрудник может делать через Personal Workspace

Сотрудник первого порядка может:

```text
создать перевод
отправить на согласование РП
сбросить подтверждение до решения РП
вернуть свою операцию из WAITING_24_HOURS в CREATED
смотреть свои переводы
смотреть операции, где он sender / receiver / initiator
```

Сотрудник первого порядка НЕ может:

```text
подтверждать перевод
отклонять перевод как РП
завершать 24 часа вручную
откатывать COMPLETED
видеть чужие переводы проекта
```

---

## 7. Что остаётся в Company Workspace

Company Workspace endpoints остаются для:

```text
PROJECT_HEAD
PARTNER
```

Руководитель проекта через Company Workspace может:

```text
создавать перевод
смотреть все переводы проекта
подтверждать перевод сотрудника
отклонять перевод сотрудника
вернуть из WAITING_24_HOURS к себе на PROJECT_HEAD_APPROVAL
завершить 24 часа вручную
откатить completed transfer по правилам ТЗ-05.2 v3
```

Партнёр первого порядка через Company Workspace может:

```text
создавать перевод
смотреть свои переводы
откатывать свой completed transfer по правилам ТЗ-05.2 v3
```

---

## 8. Получатели для ACCOUNTABLE_BALANCE

Если выбран тип:

```text
ACCOUNTABLE_BALANCE
```

получатели только из участников выбранного проекта первого порядка:

```text
PROJECT_HEAD
PARTNER
EMPLOYEE
```

Источник:

```text
project_participants
where project_id = selected_project_id
and level = first
and project_role_code in PROJECT_HEAD, PARTNER, EMPLOYEE
```

Запрещено:

```text
переводить самому себе на подотчётный баланс
выбирать Counterparty вне проекта
выбирать second-order participant
выбирать SUPPLIER / CONTRACTOR / CUSTOMER / SUPERVISOR
```

---

## 9. Получатели для PERSONAL_BALANCE

Если выбран тип:

```text
PERSONAL_BALANCE
```

получателем может быть **любой активный Counterparty выбранной компании**.

Разрешены все роли Counterparty компании:

```text
OWNER
PARTNER
EMPLOYEE
SUPPLIER
CONTRACTOR
CUSTOMER
```

Также разрешён расчётный перевод самому себе.

Важно:

```text
PERSONAL_BALANCE перевод самому себе разрешён
ACCOUNTABLE_BALANCE перевод самому себе запрещён
```

---

## 10. Логика PERSONAL_BALANCE при выборе Counterparty

При создании расчётного перевода:

1. Пользователь выбирает Counterparty компании.
2. Backend проверяет, есть ли у этого Counterparty `ProjectParticipant` в выбранном `project_id`.
3. Если есть:
   - использовать существующий `ProjectParticipant`;
   - использовать его wallet;
   - если wallet отсутствует — создать идемпотентно.
4. Если нет:
   - создать `ProjectParticipant` второго порядка;
   - создать wallet;
   - зачислить деньги на `personal_balance`.

---

## 11. Маппинг ролей для второго порядка

Для автосоздания `ProjectParticipant level = second` при `PERSONAL_BALANCE` использовать маппинг:

| CompanyRole | ProjectRole |
|---|---|
| OWNER | PARTNER |
| PARTNER | PARTNER |
| EMPLOYEE | EMPLOYEE |
| SUPPLIER | SUPPLIER |
| CONTRACTOR | CONTRACTOR |
| CUSTOMER | CUSTOMER |

Важно:

- `OWNER → PARTNER` используется только как техническая проектная роль для привязки кошелька;
- так как `level = second`, такой участник не получает право создавать операции;
- участник второго порядка в будущем может быть переведён в участника первого порядка и обратно отдельной функцией управления участниками.

---

## 12. Финансовая математика не меняется

Источник списания всегда:

```text
sender.accountable_balance
sender.accountable_spent
```

Для любого типа перевода у отправителя:

```text
sender.accountable_balance -= amount
sender.accountable_spent += amount
```

Для `ACCOUNTABLE_BALANCE` у получателя:

```text
receiver.accountable_balance += amount
receiver.accountable_received += amount
```

Для `PERSONAL_BALANCE` у получателя:

```text
receiver.personal_balance += amount
receiver.personal_received += amount
```

Запрещено:

```text
трогать sender.personal_balance
блокировать отрицательный sender.accountable_balance
использовать float/double
```

---

## 13. Кнопка «Операции» в интерфейсах

### 13.1 EMPLOYEE level = first

В Personal Workspace у сотрудника первого порядка кнопка «Операции» должна показывать:

```text
Перевод
Отчёт
```

На этом этапе `Отчёт` может быть disabled/placeholder, если операция ещё не реализована.

`Перевод` должен открывать создание перевода через personal-workspace API.

### 13.2 SUPPLIER / CONTRACTOR / EMPLOYEE level = second

Для этих ролей кнопка создания операций не показывается.

Они видят только:

```text
список своих операций
детали операций, где участвуют
кошельки/суммы, относящиеся к ним
```

### 13.3 CUSTOMER

Заказчик не создаёт перевод.

В Customer Workspace не показывать создание Transfer.

### 13.4 PROJECT_HEAD / PARTNER

В Company Workspace кнопка «Операции» должна работать по текущему company-workspace flow:

```text
Операции → Перевод → выбор проекта → создание перевода
```

---

## 14. Access isolation

Проверить, что:

- сотрудник не может вызвать company-workspace transfer create;
- поставщик не может создать transfer через personal-workspace;
- подрядчик не может создать transfer через personal-workspace;
- сотрудник второго порядка не может создать transfer;
- сотрудник первого порядка видит только свои проекты;
- сотрудник первого порядка видит только свои операции, кроме случаев, где он является sender/receiver/initiator;
- РП видит все transfers своего проекта;
- transfer из Project A не виден и не влияет на Project B.

---

## 15. Backend: что проверить и исправить

Проверить/доработать:

```text
routes/api.php
EnsurePersonalWorkspaceAccess
OperationVisibilityService
TransferParticipantResolver
TransferRecipientListService
TransferService
TransferLifecycleService
CreateTransferRequest
TransferOperationResource
Personal Workspace controllers
```

Если часть логики уже есть — не дублировать, а переиспользовать сервисы.

Важно:

- не создавать отдельную копию бизнес-логики для personal-workspace;
- personal-workspace controllers должны вызывать те же domain services;
- различаться должен контур доступа и определение текущего ProjectParticipant.

---

## 16. Flutter: что проверить и исправить

Проверить/доработать:

```text
PersonalWorkspaceShell
Worker/Personal projects screens
OperationTypePicker
CreateTransferScreen
TransfersApi
TransfersRepository
Transfer recipients UI
```

Для сотрудника первого порядка:

- открывать создание перевода из Personal Workspace;
- использовать personal-workspace endpoints;
- корректно показывать типы получателей;
- не показывать действия РП.

Для Supplier/Contractor/Employee second-order:

- не показывать создание операций;
- показывать только просмотр доступных операций.

---

## 17. Что НЕ делать

НЕ делать в этом ТЗ:

```text
Поступление
Отчёт
новую финансовую математику
переписывание Transfer lifecycle
UI-polish сверх необходимого
realtime/websocket
уведомления
документы
аналитику
```

---

## 18. Проверки Backend

### 18.1 EMPLOYEE first-order creates transfer from Personal Workspace

Условия:

```text
User связан с Counterparty EMPLOYEE
Counterparty является ProjectParticipant level=first в project_id
```

Действие:

```http
POST /api/personal-workspace/projects/{projectId}/operations/transfers
```

Ожидаемо:

```text
status = PROJECT_HEAD_APPROVAL
wallet deltas not applied
```

### 18.2 EMPLOYEE second-order cannot create transfer

Ожидаемо:

```text
403 или 422
операция не создана
```

### 18.3 SUPPLIER / CONTRACTOR cannot create transfer

Ожидаемо:

```text
403 или 422
операция не создана
```

### 18.4 PERSONAL_BALANCE recipient can be any Counterparty

Проверить роли:

```text
OWNER
PARTNER
EMPLOYEE
SUPPLIER
CONTRACTOR
CUSTOMER
```

Ожидаемо:

```text
если Counterparty не в проекте → created ProjectParticipant level=second + wallet
если Counterparty уже в проекте → used existing ProjectParticipant + wallet
```

### 18.5 PERSONAL_BALANCE self-transfer

Ожидаемо:

```text
allowed
sender.accountable_balance -= amount
sender.accountable_spent += amount
receiver.personal_balance += amount
receiver.personal_received += amount
```

Если sender и receiver один и тот же ProjectParticipant:

```text
accountable_balance уменьшается
personal_balance увеличивается
```

### 18.6 ACCOUNTABLE_BALANCE self-transfer forbidden

Ожидаемо:

```text
422 validation error
операция не создана
```

### 18.7 Project isolation

Создать Project A и Project B.

Ожидаемо:

```text
transfer в Project A не меняет wallets Project B
transfer в Project A не виден в Project B
ProjectParticipant из Project B не используется в Project A
```

---

## 19. Проверки Flutter

Проверить:

1. Сотрудник первого порядка видит в Personal Workspace доступ к созданию перевода.
2. Сотрудник второго порядка не видит создание операций.
3. Поставщик не видит создание операций.
4. Подрядчик не видит создание операций.
5. Заказчик не видит создание перевода.
6. Для `ACCOUNTABLE_BALANCE` показываются только first-order PROJECT_HEAD/PARTNER/EMPLOYEE выбранного проекта.
7. Для `PERSONAL_BALANCE` показываются все Counterparty компании.
8. Для `PERSONAL_BALANCE` можно выбрать самого себя.
9. Для `ACCOUNTABLE_BALANCE` нельзя выбрать самого себя.
10. Ошибки человекочитаемые.
11. Русский интерфейс без английских слов.

---

## 20. Команды проверки

Backend:

```cmd
php artisan route:list
php artisan migrate
php artisan optimize:clear
```

PHP syntax:

```cmd
php -l path/to/file.php
```

Flutter:

```cmd
flutter gen-l10n
flutter analyze
```

Опционально:

```cmd
flutter run -d emulator-5554 --dart-define=GURU_API_BASE_URL=http://10.0.2.2:8000/api
```

---

## 21. После выполнения Cursor должен показать

1. Какие backend endpoints добавлены для personal-workspace transfer.
2. Как сотрудник первого порядка создаёт перевод из Personal Workspace.
3. Как запрещено создание операций для supplier/contractor/employee second-order.
4. Как изменён список получателей для PERSONAL_BALANCE.
5. Как работает PERSONAL_BALANCE self-transfer.
6. Как запрещён ACCOUNTABLE_BALANCE self-transfer.
7. Как работает OWNER/CUSTOMER как recipient для PERSONAL_BALANCE.
8. Как переиспользуются существующие Transfer services.
9. Какие Flutter экраны изменены.
10. Какие localization keys добавлены.
11. Результат `php artisan route:list`.
12. Результат `flutter analyze`.
13. Результаты ручных проверок.

---

## 22. Модель Cursor

Использовать:

```text
Sonnet 4.6
Agent
MAX OFF
Thinking ON
Effort Medium
```

Причина:

- задача точечная;
- финансовую математику и lifecycle не переписываем;
- нужно поправить доступы, endpoints и UI-видимость;
- MAX не нужен, если контекст актуальный.

Если Cursor context больше 70%, открыть новый чат и загрузить:

```text
GURU_FULL_PROJECT_BLUEPRINT.md
GURU_ARCHITECTURE_AND_STANDARDS.md
TZ_05_2_v3_GURU_Transfer_Lifecycle_Final.md
это ТЗ
```

---

## 23. Главное правило

Сотрудник первого порядка создаёт перевод из Personal Workspace.

Поставщик, подрядчик и сотрудник второго порядка операции не создают.

Расчётный перевод можно сделать на любого Counterparty компании, включая самого себя.

Подотчётный перевод — только участникам первого порядка выбранного проекта и не самому себе.
