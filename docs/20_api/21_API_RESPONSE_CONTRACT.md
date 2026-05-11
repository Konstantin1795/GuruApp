# 21 — API Response Contract / Контракт ответов API

Стабильный файл.  
Меняется редко.

---

## 1. Success response

Все успешные API-ответы должны иметь формат:

```json
{
  "ok": true,
  "data": {},
  "meta": {
    "request_id": "..."
  }
}
```

---

## 2. Error response

Все ошибки API должны иметь формат:

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

## 3. request_id

Каждый ответ должен содержать:

```text
meta.request_id
```

Также используется HTTP header:

```text
X-Request-Id
```

---

## 4. Validation errors

При ошибках валидации:

```json
{
  "ok": false,
  "error": {
    "message": "Validation failed",
    "type": "validation_error",
    "fields": {
      "amount": ["Некорректная сумма"]
    }
  },
  "meta": {
    "request_id": "..."
  }
}
```

Flutter должен показывать человеку понятное сообщение, а не только `Validation failed`.

---

## 5. Pagination response

Для списков внутри `data`:

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

## 6. Pagination params

```text
page
per_page
```

Значения:

```text
default per_page = 20
max per_page = 50
```

---

## 7. JsonResource

В Laravel включено:

```php
JsonResource::withoutWrapping()
```

Поэтому не должно быть двойного:

```json
{
  "data": {
    "data": {}
  }
}
```

---

## 8. API не должен отдавать HTML

Для `api/*` нельзя отдавать:

```text
login page HTML
Laravel error HTML
redirect HTML
```

Backend должен вернуть JSON-ошибку.

Flutter ApiClient должен уметь распознать HTML и показать понятное сообщение.

---

## 9. HTTP statuses

Ориентиры:

```text
200 OK
201 Created
401 Unauthorized
403 Forbidden
404 Not Found
422 Validation / Domain transition error
500 Server error
```

`InvalidOperationTransitionException` → `422`.
