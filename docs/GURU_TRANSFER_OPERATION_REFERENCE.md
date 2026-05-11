# GURU — операция «Перевод» (TRANSFER): полный справочник реализации

**Назначение:** единая точка правды по домену перевода **в том виде, как он реализован в коде сейчас**. Используйте для поддержки, регрессии и согласования изменений.  
**Последнее обновление документа:** 2026-05-09 — §3.1–3.4 (перетекание финансов); сверка с `backend/app/Modules/Operations`, `backend/routes/api.php`, `mobile_app/lib/features/operations`.

**Связанные файлы:** `PROJECT_CONTEXT_GURU.md`, `docs/GURU_ARCHITECTURE_AND_STANDARDS.md`, `docs/GURU_FULL_PROJECT_BLUEPRINT.md`.

---

## 1. Суть домена

- Один **перевод** в продукте — это тип операции **`TRANSFER`**: строка в таблице **`operations`** (общая сущность операции проекта) и **ровно одна** связанная строка в **`transfer_operations`** (детали перевода: сумма, отправитель/получатель, тип цели, статус, метки времени кошельков).
- Перевод **всегда привязан к одному `project_id`**. Участники фигурируют как **`ProjectParticipant`** (связь пользователя/контрагента с проектом); деньги считаются на **`ProjectParticipantWallet`** (подотчётный и личный блоки баланса).

Инвариант: **источник списания** при любом типе цели — **подотчётный блок отправителя** (`accountable_balance` / `accountable_spent`). **`personal_balance` отправителя переводом не уменьшается.**

---

## 2. Типы перевода (`TransferTargetType`)

| Значение API | Смысл | Получатель в запросе |
|--------------|--------|----------------------|
| `ACCOUNTABLE_BALANCE` | Зачисление на **подотчётный** баланс другого участника проекта | `receiver_project_participant_id` — участник **этого же** проекта |
| `PERSONAL_BALANCE` | Зачисление на **личный (расчётный)** баланс участника, связанного с контрагентом компании | `receiver_counterparty_id` — контрагент компании (`company_id` проекта) |

Правила выбора получателя реализованы в **`TransferParticipantResolver`**:

- **Подотчёт (`ACCOUNTABLE_BALANCE`):** получатель — активный участник проекта, **`level` = первый порядок** (`first`), роль одна из: руководитель проекта, партнёр, сотрудник (`PROJECT_HEAD`, `PARTNER`, `EMPLOYEE`). Нельзя указать себя.
- **Личный (`PERSONAL_BALANCE`):** контрагент компании с допустимой ролью компании (OWNER, PARTNER, EMPLOYEE, SUPPLIER, CONTRACTOR, CUSTOMER). Если у контрагента ещё нет строки участника в этом проекте, при создании перевода участник **создаётся автоматически**: `level = second`, роль в проекте маппится из роли контрагента (например OWNER компании → PARTNER в проекте), кошелёк — через **`WalletFactoryService`**.

Список получателей для UI отдаёт **`TransferRecipientListService`** (GET `.../recipients?transfer_target_type=...`): для подотчёта — участники 1-го порядка с фильтром ролей; для личного — контрагенты компании с фильтром ролей.

---

## 3. Кошелёк и математика (`TransferBalanceService`)

Расчёт в **целых минорных единицах** (копейки), строки в БД — `decimal`, без денежной логики на `float`.

**Отправитель (всегда):** списание с подотчёта:

- `accountable_balance` уменьшается на сумму;
- `accountable_spent` увеличивается на сумму.

**Получатель при `PERSONAL_BALANCE`:** увеличиваются `personal_balance` и `personal_received`.

**Получатель при `ACCOUNTABLE_BALANCE`:** увеличиваются `accountable_balance` и `accountable_received`.

Обратная операция **`revertTransfer`** симметрично откатывает те же поля (используется при откатах после уже применённых дельт).

### 3.1 Перетекание финансов при «исполнении» (реальное движение по счётам)

**Исполнение в коде** — это вызов **`TransferBalanceService::applyTransfer`** (один раз на сумму перевода для пары кошельков отправителя и получателя). Повторного начисления при смене статуса на **`COMPLETED`** после **`WAITING_24_HOURS`** нет: деньги уже списаны и зачислены на шаге согласования руководителя; дальше меняется только **`operation_status`** (вручную или автозавершением по таймеру).

Ниже — **какие поля** трогает один проход `applyTransfer` (знак «−» — уменьшение, «+» — увеличение на сумму перевода):

**Отправитель (sender)** — всегда одинаково, независимо от типа цели:

| Поле | Изменение |
|------|-----------|
| `accountable_balance` | − сумма |
| `accountable_spent` | + сумма |

Смысл: у отправителя уменьшается доступный подотчёт и растёт учёт «потрачено из подотчёта». Поля **`personal_balance`**, **`personal_earned`**, **`personal_received`** у отправителя **не меняются**.

**Получатель (receiver)** — зависит от **`transfer_target_type`**:

| Тип перевода | Поля получателя |
|--------------|-----------------|
| `ACCOUNTABLE_BALANCE` | `accountable_balance` + сумма; `accountable_received` + сумма |
| `PERSONAL_BALANCE` | `personal_balance` + сумма; `personal_received` + сумма |

Поля **`accountable_*`** у получателя при личном переводе в этом проходе не увеличиваются; при подотчётном — не трогаются **`personal_*`**.

**Итог:** виртуально «перетекание» — **из подотчётного запаса отправителя** в **выбранный блок получателя** (подотчёт или личный), в рамках строк **`project_participant_wallets`** двух участников одного проекта.

### 3.2 Когда дельты применяются впервые (появляется `wallets_applied_at`)

| Сценарий | Где в коде | Статус после шага с деньгами |
|----------|------------|------------------------------|
| Создание инициатором **PROJECT_HEAD / PARTNER** | `TransferService::create` | Сразу **`COMPLETED`**, дельты в той же транзакции |
| Согласование руководителем при **`PROJECT_HEAD_APPROVAL`** | `TransferLifecycleService::approveByProjectHead` | **`WAITING_24_HOURS`**; выставляются **`wallets_applied_at`** и **`waiting_period_started_at`** (UTC) |
| Действие **`complete-immediate`** из **`CREATED`** (HEAD/PARTNER) | `completeImmediateByHeadOrPartner` | **`COMPLETED`** с дельтами |

Для HEAD/PARTNER при создании перевода **всегда** применяются дельты и сразу **`COMPLETED`** (отдельной ветки «создали без проводки» нет).

Пока операция только в **`PROJECT_HEAD_APPROVAL`** и **`wallets_applied_at` пустой**, **балансы не менялись** (ожидание решения руководителя).

### 3.3 Когда деньги уже «проведены», но статус ещё не финальный

После **`approveByProjectHead`** деньги **уже** у отправителя списаны и у получателя зачислены. Статус **`WAITING_24_HOURS`** — это **юридическое/процессное окно**, а не второе списание:

- **`completeWaitingByProjectHead`** и **`autoCompleteWaitingIfDue`** только ставят **`COMPLETED`** на операции; **`applyTransfer` не вызывается**.
- Поэтому при регрессии важно: после входа в **`WAITING_24_HOURS`** суммы на кошельках уже отражают перевод; **`COMPLETED`** лишь фиксирует завершение процесса без дополнительной проводки.

### 3.4 Откат проводки (`revertTransfer`)

Вызывается при переходах, где в комментариях к коду указан откат дельт: возврат из **`WAITING_24_HOURS`** к **`CREATED`** или **`PROJECT_HEAD_APPROVAL`**, откаты из **`COMPLETED`** и т.д. Логика зеркальна **`applyTransfer`**: те же поля отправителя и получателя возвращаются на величину суммы перевода. После успешного отката **`wallets_applied_at`** обнуляется, **`wallets_reverted_at`** заполняется (UTC).

Сценарии **без дельт на момент действия** (отклонение, сброс до **`CREATED`** до согласования): **`revertTransfer`** не вызывается — денег «в проводке» не было.

---

## 4. Кто может создать перевод

Проверка **`TransferParticipantResolver::assertInitiatorCanCreateTransfer`:**

- Участник **первого порядка** (`level` = `first`).
- Роль в проекте: **`PROJECT_HEAD`**, **`PARTNER`** или **`EMPLOYEE`**.

### 4.1 HTTP-контуры

| Контур | Префикс | Кто создаёт |
|--------|---------|-------------|
| **Company workspace** | `/api/company-workspace/{companyId}/...` | Любой допустимый инициатор (см. выше), проект принадлежит компании |
| **Personal workspace** | `/api/personal-workspace/...` | Дополнительно **`PersonalWorkspaceTransferGuard`**: только **`EMPLOYEE`** **первого порядка** (исполнитель из личного кабинета) |

Инициатор определяется резолвером участника по текущему пользователю и проекту (`ResolvesProjectParticipant` / `ResolvesPersonalWorkspaceProjectParticipant`).

---

## 5. Создание перевода (`TransferService::create`)

Общая логика:

1. В транзакции создаётся **`Operation`**: тип `TRANSFER`, статус сначала **`CREATED`**, первая запись в **`operation_status_histories`** (из статуса `null` в `CREATED`).
2. Если финальный статус после создания **не** `CREATED`, строка `Operation` обновляется и в историю добавляется переход **`CREATED → <финальный статус>`**.
3. Создаётся **`TransferOperation`** с тем же финальным статусом.
4. Дельты кошельков применяются **только если** инициатор — **`PROJECT_HEAD` или `PARTNER`** (**немедленное завершение**).

**Важно про сотрудника (`EMPLOYEE`):**

- Для сотрудника **`immediate = false`**, финальный статус при создании — **`PROJECT_HEAD_APPROVAL`** (ожидание руководителя).
- В истории это выглядит как два шага подряд: `CREATED`, затем `CREATED → PROJECT_HEAD_APPROVAL`.
- **Дельты при создании не применяются** (`wallets_applied_at = null`).
- В базе **нет промежуточного «застревания» в `CREATED`** после успешного POST: сразу **`PROJECT_HEAD_APPROVAL`**.

**Важно про руководителя / партнёра:**

- Финальный статус при создании — **`COMPLETED`**.
- Дельты применяются сразу, **`wallets_applied_at`** выставляется в **UTC**.

Идентификация сторон в `transfer_operations`:

- **`initiator_project_participant_id`** — кто создал операцию.
- **`sender_project_participant_id`** — сейчас всегда совпадает с инициатором (отправитель).
- **`receiver_project_participant_id`** — получатель как участник (для личного перевода может быть только что созданный участник 2-го порядка).
- **`receiver_counterparty_id`** — заполняется для **`PERSONAL_BALANCE`** (для аудита / связи с контрагентом).

Ответ API создания: **`201`**, тело `ok`, `data.transfer` — см. **`TransferOperationResource`**.

---

## 6. Статусы (`OperationStatus`) и терминальность для TRANSFER

Общий enum содержит также статусы для **других** типов операций (например **`CUSTOMER_APPROVAL`**, **`ROLLED_BACK`**). В **текущем жизненном цикле TRANSFER** переходы реализованы в **`TransferLifecycleService`** и **не используют** `CUSTOMER_APPROVAL` и **`ROLLED_BACK`** (они остаются заделом / другими типами операций).

Для типа **`TRANSFER`** терминальные статусы (**конец процесса для UI «финал»**):

- **`COMPLETED`**
- Плюс по политике `OperationStatus::isTerminalForOperationType(TRANSFER)`: **`ROLLED_BACK`** считается терминальным на уровне enum, но **в текущем коде перевода перехода в `ROLLED_BACK` нет** — фактические терминалы перевода: **`COMPLETED`** и сценарии, когда операция снова в работе после отката к **`CREATED`** / **`PROJECT_HEAD_APPROVAL`**.

**Особый случай `REJECTED`:** при отклонении руководителем запись в истории проходит через `REJECTED`, но затем в **той же транзакции** статус возвращается в **`CREATED`**. Для TRANSFER **`REJECTED` не является «висящим» конечным статусом** — пользователь видит **`CREATED`**.

---

## 7. Жизненный цикл (state machine)

Ниже — **реализованные** переходы. Условия и акторы — в коде **`TransferLifecycleService`** и **`TransferAvailableActionsService`**.

### 7.1 Схема для инициатора — сотрудник (типичный согласованный поток)

1. **Создание** → сразу **`PROJECT_HEAD_APPROVAL`** (без дельт).
2. Руководитель: **`approve-project-head`** → **`WAITING_24_HOURS`**: дельты применены, **`wallets_applied_at`**, **`waiting_period_started_at`** (UTC).
3. Далее:
   - Через **24 часа UTC** от `waiting_period_started_at` срабатывает **`TransferLifecycleService::autoCompleteWaitingIfDue`** (обычно вызывается кроном **`operations:complete-expired-transfer-waiting`**) → **`COMPLETED`** (история с комментарием автозавершения, без участника).
   - Или руководитель раньше: **`complete-waiting`** → **`COMPLETED`** (дельты уже были, только смена статуса).
   - Или сотрудник в окне 24ч: **`return-to-created`** — откат дельт, статус **`CREATED`**.
   - Или руководитель в окне 24ч: **`return-to-project-head-approval`** — откат дельт, статус снова **`PROJECT_HEAD_APPROVAL`**.

Из **`CREATED`** сотрудник может **`submit-for-approval`** → снова **`PROJECT_HEAD_APPROVAL`** (актуально после возврата/сброса/отклонения).

### 7.2 Отклонение руководителем в стадии согласования

- **`reject-project-head`** при **`PROJECT_HEAD_APPROVAL`** (дельты ещё не применены): в истории фиксируется переход через **`REJECTED`**, итоговый статус **`CREATED`**.

### 7.3 Сброс сотрудником до черновика

- **`reset-approval`** при **`PROJECT_HEAD_APPROVAL`** (дельты не применены): **`CREATED`**.

### 7.4 Инициатор — руководитель или партнёр

При **создании** сразу **`COMPLETED`** и дельты применены **или** (в компании) доступно ручное действие **`complete-immediate`** из **`CREATED`** для того же инициатора-HEAD/PARTNER — тоже **`COMPLETED`** с дельтами.

Отдельный путь «согласование руководителя» для них при создании **не используется** — они проходят мгновенное завершение при POST.

### 7.5 После **`COMPLETED`** (корректирующие сценарии)

Реализовано только для части случаев (см. **`rollbackCompletedHeadOrPartner`** и **`returnCompletedEmployeeToProjectHeadApproval`**):

- Если инициатор был **`EMPLOYEE`**, руководитель может **`return-completed-to-project-head-approval`**: откат дельт, статус **`PROJECT_HEAD_APPROVAL`**.
- Если инициатор **`PROJECT_HEAD`** или **`PARTNER`**, возможен **`rollback-completed`** с откатом дельт → **`CREATED`** (правила «кто может нажать» завязаны на роль инициатора и актора — см. код `rollbackCompletedHeadOrPartner`).

---

## 8. Доступные действия UI (`available_actions`)

Флаги считаются в **`TransferAvailableActionsService::forParticipant`** для текущего **`ProjectParticipant`** просматривающего пользователя.

Имена ключей (сопоставление с POST-сегментами см. §10):

| Ключ | Когда true (упрощённо) |
|------|------------------------|
| `approve_project_head` | Статус `PROJECT_HEAD_APPROVAL`, роль актора — руководитель, дельты не применены |
| `reject_project_head` | То же |
| `reset_approval` | Статус `PROJECT_HEAD_APPROVAL`, инициатор-сотрудник = актор, дельты не применены |
| `submit_for_approval` | Статус `CREATED`, инициатор-сотрудник = актор, дельты не применены |
| `complete_immediate` | Статус `CREATED`, инициатор HEAD/PARTNER = актор, дельты не применены |
| `return_to_created` | `WAITING_24_HOURS`, дельты есть, инициатор-сотрудник = актор |
| `return_to_project_head_approval` | `WAITING_24_HOURS`, дельты есть, актор — руководитель |
| `complete_waiting` | `WAITING_24_HOURS`, актор — руководитель |
| `rollback_completed` | `COMPLETED`, дельты есть, правила инициатора HEAD/PARTNER |
| `return_completed_to_project_head_approval` | `COMPLETED`, инициатор был EMPLOYEE, актор — руководитель |

**Счётчик «ожидает вашего шага»** (`pending-count`): **`TransferPendingActionCountService`** считает переводы, где у участника есть одно из действий с ключами **`approve_project_head`**, **`reject_project_head`**, **`submit_for_approval`** (не включает опциональные «complete_immediate», работу с 24ч окном, откаты завершённых).

---

## 9. Видимость переводов (`OperationVisibilityService`)

Пользователь видит перевод в проекте, если:

- найден его **`ProjectParticipant`** в этом проекте (активный контрагент с **`user_id`**), и
- **либо** он **руководитель проекта** (`PROJECT_HEAD`) — видит **все** переводы проекта,
- **либо** его участник совпадает с **инициатором**, **отправителем** или **получателем** перевода.

Агрегированная лента по компании / личному кабинету строится как объединение видимых переводов по списку доступных проектов с теми же правилами на каждый проект.

---

## 10. HTTP API (сводка)

### 10.1 Общие префиксы

- Компания: `/api/company-workspace/{companyId}/...`
- Личный кабинет: `/api/personal-workspace/...`  
Все маршруты под **`auth:sanctum`**.

### 10.2 Company workspace — переводы

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `.../operations/transfers/history` | Агрегированная история по видимым проектам компании (пагинация) |
| GET | `.../operations/transfers/pending-count` | `{ pending_action_count }` |
| GET | `.../projects/{projectId}/operations/transfers/recipients` | Список получателей для типа |
| GET | `.../projects/{projectId}/operations/transfers` | Список переводов проекта |
| POST | `.../projects/{projectId}/operations/transfers` | Создание |
| GET | `.../projects/{projectId}/operations/transfers/{transferId}` | Деталь + `available_actions` + история (если загружена) |
| POST | `.../transfers/{id}/approve-project-head` | Согласование руководителем |
| POST | `.../transfers/{id}/reject-project-head` | Отклонение (с причиной — см. контроллер / request) |
| POST | `.../transfers/{id}/reset-approval` | Сброс сотрудником |
| POST | `.../transfers/{id}/submit-for-approval` | Отправка на согласование из CREATED |
| POST | `.../transfers/{id}/complete-immediate` | Немедленное завершение HEAD/PARTNER |
| POST | `.../transfers/{id}/return-to-created` | Из WAITING_24_HOURS сотрудником |
| POST | `.../transfers/{id}/return-to-project-head-approval` | Из WAITING_24_HOURS руководителем |
| POST | `.../transfers/{id}/complete-waiting` | Завершение из WAITING_24_HOURS руководителем |
| POST | `.../transfers/{id}/rollback-completed` | Откат COMPLETED → CREATED (HEAD/PARTNER сценарии) |
| POST | `.../transfers/{id}/return-completed-to-project-head-approval` | Откат COMPLETED → PROJECT_HEAD_APPROVAL (инициатор был сотрудник) |

### 10.3 Personal workspace — переводы

Реализован **поднабор** (создание и «черновой» цикл сотрудника):

| Метод | Путь |
|-------|------|
| GET | `/personal-workspace/operations/transfers/history` |
| GET | `/personal-workspace/operations/transfers/pending-count` |
| GET/POST | `/personal-workspace/projects/{projectId}/operations/transfers` |
| GET | `.../transfers/{transferId}` |
| POST | `.../transfers/{id}/submit-for-approval` |
| POST | `.../transfers/{id}/reset-approval` |
| POST | `.../transfers/{id}/return-to-created` |

Согласование руководителя, окно 24 часов и завершение — **через company workspace** (тот же пользователь как участник руководителя в проекте компании).

### 10.4 Тело создания (валидатор `CreateTransferRequest`)

- **`transfer_target_type`**: `PERSONAL_BALANCE` | `ACCOUNTABLE_BALANCE`
- **`amount`**: строка, > 0, до 2 знаков после запятой
- **`comment`**: опционально, до 2000 символов
- В зависимости от типа — либо **`receiver_project_participant_id`**, либо **`receiver_counterparty_id`** (взаимоисключающие).

### 10.5 Комментарий обязателен для части POST-действий

Запрос **`TransferCommentRequest`**: JSON с полем **`comment`** (непустая строка, до 2000 символов) используется в контроллерах:

- `reject-project-head`, `return-to-created` (company и personal), `rollback-completed`, `return-completed-to-project-head-approval`.

Остальные действия перевода обычно принимают пустое тело или опциональные поля по конкретному контроллеру.

---

## 11. История статусов

Таблица **`operation_status_histories`**: связь с **`operations.id`**, `from_status`, `to_status`, `changed_by_project_participant_id`, опционально **`comment`**, **`author_user_id`**, **`author_full_name`**.  
В **`TransferOperationResource`** история отдаётся в **`status_history`**, если загружена связь **`operation.statusHistory`**.

---

## 12. Автозавершение 24 часов

- Условие: статус **`WAITING_24_HOURS`**, заданы **`waiting_period_started_at`** и **`wallets_applied_at`**.
- Время: строго **24 часа в UTC** от `waiting_period_started_at`.
- Команда: **`php artisan operations:complete-expired-transfer-waiting`**. На продакшене должна вызываться планировщиком (cron / scheduler).

---

## 13. Клиент Flutter (кратко)

- Модуль: **`mobile_app/lib/features/operations/`**.
- **`TransfersApi`**: базовый путь для company — `/company-workspace/{companyId}/projects/{projectId}/operations/transfers`, для personal — `/personal-workspace/projects/{projectId}/operations/transfers`; история и счётчик — без `projectId` в пути.
- Действия: POST на `{base}/{transferId}/{actionSegment}` (kebab-case как в Laravel routes).
- Модель **`TransferOperation`**, статусы **`OperationStatus`** зеркалят строковые enum backend.
- Детальный экран парсит **`TransferDetailView.fromShowJson`**: `transfer`, `available_actions`, вложенная `status_history`.

---

## 14. Таблицы БД (поля перевода)

**`transfer_operations`** (ключевое):

- Связи: `operation_id`, `project_id`, `initiator_project_participant_id`, `sender_project_participant_id`, `receiver_project_participant_id`, опционально `receiver_counterparty_id`
- `transfer_target_type`, `amount`, `comment`, `operation_status`
- **`wallets_applied_at`**, **`wallets_reverted_at`**, **`waiting_period_started_at`** — контроль дельт и окна 24ч

**`operations`**: тип операции, текущий статус (дублируется логика с `transfer_operations` для универсальной сущности).

---

## 15. При регрессии проверять

1. Создание HEAD/PARTNER → сразу **`COMPLETED`** и дельты на кошельках.
2. Создание EMPLOYEE → сразу **`PROJECT_HEAD_APPROVAL`**, дельт нет.
3. Approve HEAD → **`WAITING_24_HOURS`**, дельты есть, таймстемпы UTC.
4. Reject HEAD → итог **`CREATED`**, дельт нет.
5. Личный перевод: автосоздание участника 2-го порядка и корректный **`receiver_counterparty_id`**.
6. Видимость: не-HEAD видит только «свои» переводы; HEAD — все в проекте.
7. Personal workspace: создание только **EMPLOYEE** 1-го порядка (**403** иначе).
8. Pending count совпадает с whitelist действий в **`TransferAvailableActionsService`**.

---

*Конец справочника.*
