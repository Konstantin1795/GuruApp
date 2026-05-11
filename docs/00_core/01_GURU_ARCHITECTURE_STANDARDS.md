# 01 — GURU Architecture Standards / Стандарты архитектуры

Этот файл содержит правила разработки backend и Flutter.  
Меняется редко.

---

## 1. Backend: feature-first modules

Backend организован по доменным модулям:

```text
backend/app/Modules/<ModuleName>
```

Стандартная структура:

```text
Enums/
Models/
Services/
Http/
  Controllers/
  Requests/
  Resources/
Exceptions/
```

---

## 2. Контроллеры должны быть тонкими

Controller должен:

```text
получить validated input
вызвать service
вернуть ApiResponse + Resource
```

Controller НЕ должен:

```text
считать деньги
содержать сложную бизнес-логику
возвращать Eloquent напрямую
делать многошаговые транзакции вручную
```

---

## 3. Валидация через FormRequest

Для входных данных использовать:

```text
Http/Requests/*
```

Ошибки валидации должны возвращаться в общем JSON-контракте.

---

## 4. Ответы через Resource

Запрещено отдавать сырой Eloquent наружу.

Использовать:

```text
Http/Resources/*
```

Laravel Resource работает без двойной обёртки `data`, потому что включено:

```text
JsonResource::withoutWrapping()
```

---

## 5. Бизнес-логика в Services

В сервисах должны жить:

```text
финансовая математика
оркестрация операций
переходы статусов
видимость операций
доступные действия
pending count
резолв участников
```

---

## 6. DB::transaction

Все multi-write операции выполнять внутри:

```php
DB::transaction(function () {
    // writes
});
```

Обязательно для:

```text
создания операций
применения финансовых дельт
отката дельт
смены статусов
создания истории
автосоздания участника/кошелька
```

---

## 7. Единый API-контракт

Успешный ответ:

```json
{
  "ok": true,
  "data": {},
  "meta": {
    "request_id": "..."
  }
}
```

Ошибка:

```json
{
  "ok": false,
  "error": {
    "message": "...",
    "type": "...",
    "fields": {}
  },
  "meta": {
    "request_id": "..."
  }
}
```

---

## 8. Request ID

Каждый API-ответ должен иметь:

```text
meta.request_id
X-Request-Id
```

Это нужно для отладки mobile/backend.

---

## 9. Пагинация

Стандарт query-параметров:

```text
page
per_page
```

Значения:

```text
default per_page = 20
max per_page = 50
```

Формат ответа:

```json
{
  "items": [],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "last_page": 5
  }
}
```

---

## 10. OperationTransitionService

`OperationTransitionService` может использоваться для декларативных lifecycle.

Но текущие операции работают через свои сервисы:

```text
TRANSFER → TransferLifecycleService
INCOME → IncomeLifecycleService
REPORT → ReportLifecycleService в будущем
```

Не менять статусы TRANSFER/INCOME напрямую через общий сервис, если бизнес-логика уже вынесена в operation-specific lifecycle.

---

## 11. Flutter architecture

Flutter строится по feature-first структуре:

```text
features/<feature>/
  data/
  domain/
  presentation/
  providers.dart
```

Слои:

```text
API → Repository → Domain model → UI
```

UI не должен напрямую знать Dio.

---

## 12. Riverpod

State и зависимости через Riverpod providers.

После мутаций нужно инвалидировать связанные providers:

```text
history
pending count
details
wallets
project lists
```

---

## 13. Dio / ApiClient

HTTP-запросы только через:

```text
core/api/api_client.dart
```

Требования:

```text
ResponseType.plain
followRedirects: false
Authorization Bearer token
человекочитаемые ошибки
детекция HTML вместо JSON
```

---

## 14. Flutter UI

Использовать core widgets:

```text
AppScaffold
AppCard
AppButton
AppInput
AppLoader
AppEmptyState
AppSectionTitle
```

Тему брать из:

```text
AppColors
AppTextStyles
AppSpacing
AppRadii
```

---

## 15. Localization

Все новые строки:

```dart
context.l10n.key
```

Файлы:

```text
app_ru.arb
app_en.arb
```

После изменения:

```cmd
flutter gen-l10n
flutter analyze
```

---

## 16. Не делать лишний рефакторинг

В рамках задачи нельзя:

```text
рефакторить не относящееся к задаче
ломать работающие маршруты
менять API без необходимости
менять бизнес-логику в UI-задаче
добавлять тяжёлые зависимости без причины
```
