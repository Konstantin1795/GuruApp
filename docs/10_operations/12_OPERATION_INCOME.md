# 12 — Operation INCOME / Операция «Поступление»

Канонический краткий файл по поступлению.

---

## 1. Назначение

`INCOME` создаёт деньги проекта.

Поступление фиксирует вход денег от Заказчика в рамках проекта и увеличивает подотчётные балансы:

```text
Заказчика
Руководителя проекта
```

---

## 2. Кто может создать

Создавать могут только first-order участники проекта:

```text
PROJECT_HEAD
PARTNER
```

Только из Company Workspace.

OWNER компании не создаёт поступление, если он не является PROJECT_HEAD или PARTNER в выбранном проекте.

---

## 3. Кто подтверждает

Подтверждает:

```text
CUSTOMER ProjectParticipant
```

Заказчик работает через Personal Workspace / Customer Workspace.

---

## 4. Финансовая логика

Финансы применяются при переходе:

```text
CREATED → CUSTOMER_APPROVAL
```

### Заказчик

```text
customer.accountable_balance += amount
customer.accountable_received += amount
```

### Руководитель проекта

```text
project_head.accountable_balance += amount
project_head.accountable_received += amount
```

---

## 5. Что не меняется

`INCOME` не меняет:

```text
personal_balance
personal_earned
personal_received
accountable_spent
```

---

## 6. Откат финансов

При отклонении или откате completed:

```text
customer.accountable_balance -= amount
customer.accountable_received -= amount

project_head.accountable_balance -= amount
project_head.accountable_received -= amount
```

---

## 7. Lifecycle

### Создание / отправка

```text
CREATED → CUSTOMER_APPROVAL
```

Финансы применяются сразу.

### Заказчик подтверждает

```text
CUSTOMER_APPROVAL → WAITING_24_HOURS
```

Финансы повторно не применяются.

### Заказчик отклоняет

```text
CUSTOMER_APPROVAL → REJECTED → CREATED
```

Комментарий обязателен.  
Финансы откатываются.

### Заказчик возвращает из 24 часов

```text
WAITING_24_HOURS → CUSTOMER_APPROVAL
```

Финансы не откатываются.

### Заказчик отклоняет после возврата

```text
CUSTOMER_APPROVAL → REJECTED → CREATED
```

Финансы откатываются только здесь.

### Завершение 24 часов

```text
WAITING_24_HOURS → COMPLETED
```

Варианты:

```text
автоматически через scheduled command
вручную Руководителем проекта
```

Финансы повторно не применяются.

### Откат completed

```text
COMPLETED → CREATED
```

Финансы откатываются сразу.

Кто может:

```text
если создал PROJECT_HEAD → только PROJECT_HEAD-инициатор
если создал PARTNER → PARTNER-инициатор или PROJECT_HEAD проекта
```

Комментарий обязателен.

---

## 8. Редактирование

Редактировать можно только в статусе:

```text
CREATED
```

Можно менять:

```text
amount
comment
```

Нельзя менять:

```text
project_id
customer_project_participant_id
project_head_project_participant_id
initiator_project_participant_id
operation_type
```

---

## 9. Сервисы

```text
IncomeService
IncomeBalanceService
IncomeLifecycleService
IncomeVisibilityService
IncomeAvailableActionsService
IncomePendingActionCountService
IncomeProjectParticipantsResolver
```

---

## 10. API

Company workspace:

```text
GET /operations/incomes/history
GET /operations/incomes/pending-count
GET /projects/{projectId}/operations/incomes
POST /projects/{projectId}/operations/incomes
GET /projects/{projectId}/operations/incomes/{incomeId}
PATCH /projects/{projectId}/operations/incomes/{incomeId}
POST /submit-to-customer-approval
POST /complete-waiting
POST /rollback-completed
```

Personal workspace:

```text
GET /operations/incomes/history
GET /operations/incomes/pending-count
GET /projects/{projectId}/operations/incomes
GET /projects/{projectId}/operations/incomes/{incomeId}
POST /approve-customer
POST /reject-customer
POST /return-to-customer-approval
```

---

## 11. Unified history

`INCOME` должен отображаться в единой истории операций:

```text
GET /operations/history
```

вместе с `TRANSFER`.

---

## 12. Pending count

`INCOME` должен учитываться в combined pending count.

Пример:

```text
CUSTOMER_APPROVAL для Заказчика = pending
CREATED после отклонения для инициатора = pending, если требуется повторная отправка
```

---

## 13. Проверки

Проверять:

```text
PROJECT_HEAD create → CUSTOMER_APPROVAL + deltas
PARTNER create → CUSTOMER_APPROVAL + deltas
CUSTOMER approve → WAITING_24_HOURS без повторного apply
CUSTOMER reject → REJECTED → CREATED + revert
CUSTOMER return from waiting → CUSTOMER_APPROVAL без revert
PROJECT_HEAD complete waiting → COMPLETED
auto complete waiting → COMPLETED, author = Автоматически
rollback completed → CREATED + revert
income visible in unified history
income included in combined pending count
```
