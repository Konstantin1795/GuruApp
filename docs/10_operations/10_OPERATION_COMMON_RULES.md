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

Pending count считает только обязательные действия.

Не считать как pending:

```text
опциональные завершения
ручные досрочные завершения
откаты completed
```

Считать как pending:

```text
подтверждение Заказчика
подтверждение РП
возврат инициатору на доработку, если требуется действие
```

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
