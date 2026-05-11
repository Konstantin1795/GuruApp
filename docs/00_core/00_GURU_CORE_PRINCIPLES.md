# 00 — GURU Core Principles / Постулаты проекта

Этот файл содержит правила, которые почти не должны меняться.  
Прикладывать в Cursor почти для любой задачи.

## 1. Главная модель денег

Кошелёк принадлежит только участнику проекта:

```text
ProjectParticipant → ProjectParticipantWallet
```

Кошелёк НЕ принадлежит напрямую:

```text
User
Company
Counterparty
Project
```

Один и тот же пользователь может быть разным контрагентом в разных компаниях и разным участником в разных проектах.

---

## 2. Разделение сущностей

Нельзя смешивать:

```text
User ≠ Counterparty ≠ ProjectParticipant
```

### User

Человек в системе, авторизация, токены, email/phone.

### Counterparty

Контрагент внутри конкретной компании.

### ProjectParticipant

Контрагент, добавленный в конкретный проект с проектной ролью и уровнем участия.

---

## 3. Workspace-контуры не смешиваются

В GURU есть два backend-контура:

```text
Company Workspace
Personal Workspace
```

### Company Workspace

```text
/api/company-workspace/{companyId}/...
```

Для ролей компании:

```text
OWNER
PARTNER
```

### Personal Workspace

```text
/api/personal-workspace/...
```

Для личных ролей:

```text
EMPLOYEE
SUPPLIER
CONTRACTOR
CUSTOMER
```

Кабинет Заказчика во Flutter — это отдельный UX поверх Personal Workspace, а не отдельный backend-контур.

---

## 4. Backend — источник прав доступа

Flutter может скрывать кнопки, но backend обязан защищать данные.

Правильная цепочка доступа:

```text
User
→ Counterparty
→ ProjectParticipant
→ Operation visibility / actions
```

Запрещены fallback-доступы:

```text
company_id = 1
project_id = 1
первый проект из БД
первая компания из БД
автоматический OWNER без Counterparty
```

---

## 5. Операции живут внутри проекта

Любая операция обязательно имеет:

```text
project_id
```

Операция не должна влиять на другие проекты.

---

## 6. У каждой операции свой lifecycle

Операции нельзя загонять в один универсальный жизненный цикл.

```text
TRANSFER ≠ INCOME ≠ REPORT
```

Для каждой операции должны быть свои правила:

```text
создания
подтверждения
отклонения
отката
видимости
доступных действий
финансовых дельт
```

---

## 7. Деньги не считать через float/double

Запрещено:

```text
float
double
денежная математика во Flutter
денежная математика в Controller
денежная математика в Model
```

Разрешено:

```text
DB: decimal(15,2)
PHP: decimal strings / integer cents в сервисах
```

---

## 8. Финансовая математика только в сервисах

Для `TRANSFER`:

```text
TransferBalanceService
```

Для `INCOME`:

```text
IncomeBalanceService
```

Для будущего `REPORT`:

```text
ReportBalanceService
```

---

## 9. Каждая операция имеет историю

Любая операция должна иметь:

```text
operations
operation_status_histories
```

История должна фиксировать:

```text
from_status
to_status
changed_by_project_participant_id
author_user_id
author_full_name
comment
created_at
```

Для автоматических действий:

```text
author_full_name = Автоматически
```

---

## 10. Русский язык основной

Русский — язык по умолчанию.

Все новые строки во Flutter должны идти через:

```dart
context.l10n.someKey
```

В русском интерфейсе не должно быть английских видимых слов.

---

## 11. UI должен следовать дизайн-системе

Использовать:

```text
AppScaffold
AppCard
AppButton
AppInput
AppLoader
AppEmptyState
AppSectionTitle
AppColors
AppTextStyles
AppSpacing
AppRadii
```

Акцентный цвет:

```text
#00D6C9
```

---

## 12. Нельзя “просто добавить экран” или “просто добавить endpoint”

Любая новая возможность должна быть встроена в:

```text
правильный workspace-контур
доменную модель
API-контракт
сервисный слой
UI design system
localization
правила денежных расчётов
lifecycle операций
```

Иначе архитектура быстро расползётся.
