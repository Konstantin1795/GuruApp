# 30 — Flutter Architecture / Архитектура Flutter

Файл про структуру Flutter-клиента.  
Меняется умеренно.

---

## 1. Feature-first structure

Каждая фича строится так:

```text
features/<feature>/
  data/
    *_api.dart
    *_repository.dart
  domain/
    models/enums
  presentation/
    screens/widgets
  providers.dart
```

---

## 2. Core layer

```text
core/
  api/
  constants/
  localization/
  providers/
  routing/
  storage/
  theme/
  widgets/
```

---

## 3. API layer

HTTP только через:

```text
ApiClient
```

Фича использует:

```text
*_api.dart
```

UI не должен вызывать Dio напрямую.

---

## 4. Repository layer

Repository скрывает детали API от UI.

Пример:

```text
TransfersRepository
IncomesRepository
ProjectsRepository
```

---

## 5. Domain layer

Все ответы backend должны парситься в typed models.

Примеры:

```text
TransferOperation
IncomeOperation
OperationStatus
OperationType
ProjectParticipant
PersonalCompanyRow
```

---

## 6. State management

Использовать Riverpod.

После мутаций инвалидировать нужные providers:

```text
history
pending count
details
wallet
project lists
customer workspace data
```

---

## 7. Routing

Верхняя навигация через:

```text
go_router
```

Внутренние экраны могут открываться через:

```text
Navigator.push
MaterialPageRoute
```

---

## 8. ApiClient requirements

```text
Dio
ResponseType.plain
followRedirects: false
Authorization: Bearer token
JSON Content-Type for POST/PATCH
HTML detection
ApiException
requestId
```

---

## 9. Auth/session

Токен хранится в:

```text
flutter_secure_storage
```

При logout / login другого пользователя нужно инвалидировать:

```text
workspacesProvider
customerWorkspaceDataProvider
operation providers
```

---

## 10. Localization

Все строки через:

```dart
context.l10n.key
```

После изменения ARB:

```cmd
flutter gen-l10n
flutter analyze
```

---

## 11. Operations module

Папка:

```text
mobile_app/lib/features/operations
```

Содержит:

```text
Transfer
Income
Unified history
Operation status / type models
Action buttons
Comment dialog
```

---

## 12. Unified operations history

Экран истории должен использовать:

```text
GET .../operations/history?tab=pending|all
```

и показывать:

```text
TRANSFER
INCOME
```

При открытии элемента:

```text
TRANSFER → TransferDetailScreen
INCOME → IncomeDetailScreen
```

---

## 13. Pending count

Для суммарного бейджа использовать:

```text
combinedOperationsPendingCountProvider
```

Он должен учитывать:

```text
TRANSFER + INCOME
```
