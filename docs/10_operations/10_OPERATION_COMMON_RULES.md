# 10 — Operation Common Rules / Общие правила операций

Файл про общие правила для TRANSFER, INCOME и будущего REPORT.

---

## 1. Общая сущность операции

Каждая операция имеет запись:

```text
operations
```

Поля:

```text
project_id
initiator_project_participant_id
operation_type
operation_status
```

---

## 2. Детальная таблица по типу

Каждый тип операции имеет свою таблицу деталей:

```text
TRANSFER → transfer_operations
INCOME → income_operations
REPORT → report_operations в будущем
```

---

## 3. Type-specific lifecycle

Нельзя делать один универсальный lifecycle для всех операций.

```text
TRANSFER ≠ INCOME ≠ REPORT
```

Для каждой операции должны быть отдельные сервисы:

```text
TransferLifecycleService
IncomeLifecycleService
ReportLifecycleService
```

---

## 4. Статусы

Общий набор статусов:

```text
CREATED
PROJECT_HEAD_APPROVAL
CUSTOMER_APPROVAL
WAITING_24_HOURS
COMPLETED
REJECTED
ROLLED_BACK
```

Не каждый тип операции обязан использовать все статусы.

---

## 5. REJECTED

`REJECTED` часто используется как визуальный/исторический статус.

Операция может не оставаться в `REJECTED`.

Пример:

```text
CUSTOMER_APPROVAL → REJECTED → CREATED
PROJECT_HEAD_APPROVAL → REJECTED → CREATED
```

Это нужно фронту для отображения красного крестика в lifecycle.

---

## 6. Terminality

Нельзя использовать только общий `isTerminal()` для всех типов.

Нужно использовать:

```text
OperationStatus::isTerminalForOperationType(OperationType)
```

Потому что:

```text
для TRANSFER REJECTED не финальный
для INCOME REJECTED не финальный
для REPORT правила будут отдельные
```

---

## 7. Status history

Каждый переход фиксируется в:

```text
operation_status_histories
```

В истории должны быть:

```text
статус
дата/время
ФИО автора действия
комментарий, если есть
```

Для системных действий:

```text
author_full_name = Автоматически
```

---

## 8. Available actions

Каждая деталь операции должна отдавать:

```json
"available_actions": {}
```

Flutter показывает кнопки только на основе `available_actions`.

Но backend всё равно обязан проверять права при POST.

---

## 9. Pending count

Pending count и вкладка **«На подтверждение»** в агрегированной истории (`GET …/operations/history?tab=pending`) считают только операции, где у текущего участника есть действие из набора «движение вперёд по процессу» (см. `TransferAvailableActionsService::PENDING_BADGE_ACTION_KEYS`, `IncomeAvailableActionsService::PENDING_BADGE_KEYS`), в т.ч. **CREATED** у инициатора (отправка на согласование / `complete_immediate` для РП и партнёра-инициатора после отклонения).

Не считать как pending:

```text
WAITING_24_HOURS (действия по таймеру и откаты из этого статуса — не бейдж и не вкладка «На подтверждение»)
TRANSFER: reset_approval у инициатора в PROJECT_HEAD_APPROVAL (снятие с рассмотрения, не «подтверждение»)
INCOME: reset_approval у инициатора в CUSTOMER_APPROVAL (опциональный сброс с этапа заказчика — не «ожидает вашего подтверждения вперёд»; очередь на вкладке «На подтверждение» только у заказчика)
опциональные завершения вне перечня бейджа
откаты completed
```

Считать как pending:

```text
подтверждение Заказчика (INCOME)
подтверждение РП (TRANSFER)
отправка на согласование сотрудником (TRANSFER)
complete_immediate для инициатора РП/Партнёра в CREATED (TRANSFER)
submit_to_customer_approval у инициатора в CREATED (INCOME)
```

Вкладка **«Все операции»** (`tab=all`): для **OWNER** компании в company-workspace — все операции компании по проектам; для остальных — только операции, где пользователь указан в строке операции (инициатор / стороны / заказчик и т.д.), без расширения «все операции проекта» только из‑за роли РП или партнёра первого уровня.

---

## 10. Apply / revert

Если операция меняет кошельки, обязательно нужны:

```text
wallets_applied_at
wallets_reverted_at
```

Правила:

```text
не делать двойной apply
не делать двойной revert
apply/revert только в DB transaction
```

---

## 11. WAITING_24_HOURS

Если операция использует 24-часовое окно:

```text
waiting_period_started_at
```

Хранить в UTC.

Автозавершение через scheduled command.

При автоматическом завершении:

```text
author_full_name = Автоматически
```
