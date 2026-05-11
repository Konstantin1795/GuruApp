# 11 — Operation TRANSFER / Операция «Перевод»

Канонический краткий файл по переводу.

---

## 1. Назначение

`TRANSFER` не создаёт новые деньги проекта.

Он перераспределяет средства:

```text
с подотчётного баланса отправителя
на подотчётный или личный баланс получателя
```

---

## 2. Источник списания

Для любого перевода источник всегда:

```text
sender.accountable_balance
sender.accountable_spent
```

Запрещено списывать:

```text
sender.personal_balance
```

---

## 3. Типы перевода

```text
ACCOUNTABLE_BALANCE
PERSONAL_BALANCE
```

### ACCOUNTABLE_BALANCE

Перевод на подотчётный баланс получателя.

Получатель:

```text
ProjectParticipant first-order
PROJECT_HEAD / PARTNER / EMPLOYEE
тот же project_id
не сам инициатор
```

### PERSONAL_BALANCE

Перевод на личный / расчётный баланс получателя.

Получатель:

```text
любой активный Counterparty компании
OWNER / PARTNER / EMPLOYEE / SUPPLIER / CONTRACTOR / CUSTOMER
```

Если Counterparty ещё не является участником проекта:

```text
создать ProjectParticipant level = second
создать wallet
зачислить на personal_balance
```

Перевод самому себе на `PERSONAL_BALANCE` разрешён.

---

## 4. Математика

### У отправителя всегда

```text
sender.accountable_balance -= amount
sender.accountable_spent += amount
```

### Получатель ACCOUNTABLE_BALANCE

```text
receiver.accountable_balance += amount
receiver.accountable_received += amount
```

### Получатель PERSONAL_BALANCE

```text
receiver.personal_balance += amount
receiver.personal_received += amount
```

---

## 5. Кто может создать

Только first-order участники проекта:

```text
PROJECT_HEAD
PARTNER
EMPLOYEE
```

### Company Workspace

```text
PROJECT_HEAD
PARTNER
```

### Personal Workspace

```text
EMPLOYEE first-order
```

---

## 6. Кто не может создать

```text
SUPPLIER
CONTRACTOR
CUSTOMER
SUPERVISOR
second-order participants
```

---

## 7. Lifecycle PROJECT_HEAD / PARTNER

При создании:

```text
CREATED → COMPLETED
```

Финансы применяются сразу.

Откат completed:

```text
COMPLETED → CREATED
```

Финансы откатываются сразу.

---

## 8. Lifecycle EMPLOYEE

При создании:

```text
CREATED → PROJECT_HEAD_APPROVAL
```

Финансы не применяются.

РП подтверждает:

```text
PROJECT_HEAD_APPROVAL → WAITING_24_HOURS
```

Финансы применяются.

Далее:

```text
WAITING_24_HOURS → COMPLETED
```

вручную РП или автоматически через 24 часа.

---

## 9. Отклонение РП

```text
PROJECT_HEAD_APPROVAL → REJECTED → CREATED
```

`REJECTED` нужен для UI lifecycle.

Финансы не откатываются, если ещё не применялись.

---

## 10. Откаты из WAITING_24_HOURS

Сотрудник:

```text
WAITING_24_HOURS → CREATED
```

РП:

```text
WAITING_24_HOURS → PROJECT_HEAD_APPROVAL
```

В обоих случаях финансы откатываются.

---

## 11. Сервисы

```text
TransferService
TransferBalanceService
TransferLifecycleService
TransferParticipantResolver
TransferRecipientListService
TransferAvailableActionsService
TransferPendingActionCountService
OperationVisibilityService
```

---

## 12. API

Company workspace:

```text
GET /operations/transfers/history
GET /operations/transfers/pending-count
GET /projects/{projectId}/operations/transfers
POST /projects/{projectId}/operations/transfers
GET /projects/{projectId}/operations/transfers/{transferId}
POST lifecycle actions
```

Personal workspace:

```text
GET /operations/transfers/history
GET /operations/transfers/pending-count
GET /projects/{projectId}/operations/transfers
POST /projects/{projectId}/operations/transfers
GET /projects/{projectId}/operations/transfers/{transferId}
POST submit-for-approval
POST reset-approval
POST return-to-created
```

---

## 13. Проверки регрессии

Проверять:

```text
PROJECT_HEAD/PARTNER create → COMPLETED + deltas
EMPLOYEE create → PROJECT_HEAD_APPROVAL без deltas
approve by PROJECT_HEAD → WAITING_24_HOURS + deltas
auto complete after 24h
rollback completed
PERSONAL self-transfer allowed
ACCOUNTABLE self-transfer forbidden
second-order auto-create for PERSONAL
```
