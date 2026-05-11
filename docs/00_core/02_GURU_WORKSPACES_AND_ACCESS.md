# 02 — GURU Workspaces and Access / Воркспейсы и доступы

Файл про роли, контуры доступа и видимость данных.  
Меняется редко, но очень важен.

---

## 1. Два backend-контура

В GURU есть два явных API-контура.

### Company Workspace

```text
/api/company-workspace/{companyId}/...
```

Кто входит:

```text
OWNER
PARTNER
```

Проверка:

```text
EnsureCompanyWorkspaceAccess
```

### Personal Workspace

```text
/api/personal-workspace/...
```

Кто входит:

```text
EMPLOYEE
SUPPLIER
CONTRACTOR
CUSTOMER
```

Проверка:

```text
EnsurePersonalWorkspaceAccess
```

---

## 2. Customer Workspace

Кабинет Заказчика во Flutter — отдельный UX:

```text
/customer
```

Но backend-контур тот же:

```text
/api/personal-workspace
```

С фильтрацией по роли:

```text
workspace_role=customer
```

Customer Workspace НЕ является третьим backend-контуром.

---

## 3. Кто видит компании

Пользователь видит компанию, если:

```text
User связан с active Counterparty этой компании
```

или:

```text
User создал компанию и имеет Counterparty OWNER
```

Запрещено показывать чужие компании.

---

## 4. Кто видит проекты

### OWNER

В Company Workspace видит все проекты своей компании.

### PARTNER

В Company Workspace видит только проекты, где его Counterparty добавлен как ProjectParticipant.

### CUSTOMER / EMPLOYEE / SUPPLIER / CONTRACTOR

В Personal Workspace видят только проекты, где у них есть активный ProjectParticipant.

---

## 5. Участники первого и второго порядка

### First-order participant

Добавлен вручную в проект.

Может иметь расширенные права в зависимости от роли.

### Second-order participant

Создан автоматически через операцию.

Не получает права создания операций по умолчанию.

---

## 6. Кто может создавать операции

### Transfer

Создавать могут:

```text
PROJECT_HEAD first-order
PARTNER first-order
EMPLOYEE first-order
```

Но:

```text
EMPLOYEE first-order создаёт из Personal Workspace
PROJECT_HEAD/PARTNER создают из Company Workspace
```

### Income

Создавать могут:

```text
PROJECT_HEAD first-order
PARTNER first-order
```

Только из Company Workspace.

### Report

Будет отдельно согласовано.

---

## 7. Кто не создаёт операции

Не создают операции:

```text
SUPPLIER
CONTRACTOR
CUSTOMER
SUPERVISOR
EMPLOYEE second-order
SUPPLIER second-order
CONTRACTOR second-order
любой ProjectParticipant level = second
```

Они только смотрят доступные им данные.

---

## 8. Видимость операций

### PROJECT_HEAD

Видит все операции своего проекта.

### Обычный участник

Видит только операции, где он участвует:

```text
initiator
sender
receiver
customer
другой явно связанный участник операции
```

### OWNER

OWNER видит данные своей компании в рамках owner view-scope.

Но OWNER не получает автоматическое право выполнять действия по операции, если не является нужной проектной ролью.

---

## 9. Действия по операциям

Действия определяются backend через:

```text
available_actions
```

Flutter не должен сам решать, можно ли нажать бизнес-кнопку.

Flutter может скрывать кнопку, но backend обязан проверить действие.

---

## 10. Pending count

Pending count — это количество операций, где от пользователя требуется обязательное действие.

Опциональные действия не должны попадать в обязательный pending.

Пример:

```text
complete_waiting у РП — опционально
approve_customer у Заказчика — pending
```

---

## 11. Invite-first Counterparty

Контрагент может быть создан до регистрации пользователя.

После регистрации User с таким же email должен быть связан с Counterparty.

Правило:

```text
trim + lowercase email
не перезаписывать чужой user_id
```

---

## 12. Что запрещено

Запрещено:

```text
универсальный endpoint, который сам решает company или personal
доступ к проекту только по company_id без ProjectParticipant
доступ по первому найденному проекту
пропускать backend-проверку из-за скрытой кнопки во Flutter
```
