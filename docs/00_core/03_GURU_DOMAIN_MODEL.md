# 03 — GURU Domain Model / Доменная модель

Файл про основные сущности и связи.  
Меняется редко.

---

## 1. User

```text
users
```

Смысл: человек в системе.

Используется для:

```text
авторизации
Sanctum tokens
связи с Counterparty
```

User не равен участнику проекта.

---

## 2. Company

```text
companies
```

Смысл: бизнес-единица.

Связи:

```text
Company → Counterparty[]
Company → Project[]
```

---

## 3. Counterparty

```text
counterparties
```

Смысл: контрагент внутри компании.

Поля:

```text
company_id
user_id nullable
full_name
email
company_role_code
is_active
```

Роли компании:

```text
OWNER
PARTNER
EMPLOYEE
SUPPLIER
CONTRACTOR
CUSTOMER
```

Counterparty может существовать без `user_id`.

---

## 4. Project

```text
projects
```

Смысл: проект внутри компании.

Связи:

```text
Project → ProjectParticipant[]
Project → Operation[]
```

Операции всегда живут внутри проекта.

---

## 5. ProjectParticipant

```text
project_participants
```

Смысл: Counterparty внутри конкретного проекта.

Поля:

```text
project_id
counterparty_id
project_role_code
level
is_active
```

Роли проекта:

```text
PROJECT_HEAD
CUSTOMER
PARTNER
SUPERVISOR
EMPLOYEE
SUPPLIER
CONTRACTOR
```

Уровни:

```text
first
second
```

---

## 6. ProjectParticipantWallet

```text
project_participant_wallets
```

Один кошелёк на одного участника проекта.

Поля:

```text
personal_balance
personal_earned
personal_received
accountable_balance
accountable_received
accountable_spent
```

Разрешено уходить в минус:

```text
personal_balance
accountable_balance
```

Накопительные поля не должны уходить в минус при корректных apply/revert:

```text
personal_earned
personal_received
accountable_received
accountable_spent
```

---

## 7. Operation

```text
operations
```

Базовая карточка операции.

Поля:

```text
project_id
initiator_project_participant_id
operation_type
operation_status
```

Типы операций:

```text
TRANSFER
INCOME
REPORT
```

---

## 8. OperationStatusHistory

```text
operation_status_histories
```

История переходов статусов.

Поля:

```text
operation_id
from_status
to_status
changed_by_project_participant_id
author_user_id
author_full_name
comment
created_at
```

---

## 9. TransferOperation

```text
transfer_operations
```

Детали операции `TRANSFER`.

Ключевые поля:

```text
operation_id
project_id
initiator_project_participant_id
sender_project_participant_id
receiver_project_participant_id
receiver_counterparty_id nullable
transfer_target_type
amount
comment
operation_status
wallets_applied_at
wallets_reverted_at
waiting_period_started_at
```

---

## 10. IncomeOperation

```text
income_operations
```

Детали операции `INCOME`.

Ключевые поля:

```text
operation_id
project_id
initiator_project_participant_id
project_head_project_participant_id
customer_project_participant_id
amount
comment
operation_status
wallets_applied_at
wallets_reverted_at
waiting_period_started_at
```

---

## 11. Главная схема

```text
User
  → Counterparty
    → ProjectParticipant
      → ProjectParticipantWallet
      → Operation participation
```

---

## 12. ER overview

```text
Company
  ├─ Counterparty
  └─ Project
       ├─ ProjectParticipant
       │    └─ ProjectParticipantWallet
       └─ Operation
            ├─ TransferOperation
            ├─ IncomeOperation
            └─ OperationStatusHistory
```
