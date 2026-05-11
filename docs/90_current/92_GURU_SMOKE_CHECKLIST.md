# 92 — GURU smoke checklist (ручная регрессия)

**Назначение:** быстрая проверка перед релизом / после крупных изменений (ТЗ-08). Не заменяет автотесты.

**Окружение:** backend поднят, миграции применены, тестовые пользователи с известными ролями (OWNER, PROJECT_HEAD, CUSTOMER и т.д.).

---

## Backend (CLI)

В каталоге `backend/`:

```bash
php artisan optimize:clear
php artisan route:list
php artisan schedule:list
php artisan test
```

Ожидание: тесты зелёные; в `schedule:list` видны `operations:complete-expired-transfer-waiting` и `operations:complete-expired-income-waiting`.

---

## API (curl / Postman)

С валидным `Authorization: Bearer …` (Sanctum):

| Проверка | Метод и путь (фрагмент) | Ожидание |
|----------|-------------------------|----------|
| Health | `GET /api/health` или системный health по конфигу | 200, JSON ok |
| Сводка проекта (компания) | `GET …/company-workspace/{id}/projects/{projectId}/summary` | 200, блок project + metrics + visibility |
| Сводка проекта (personal) | `GET …/personal-workspace/projects/{projectId}/summary` | 200 |
| Единая история (компания) | `GET …/company-workspace/{id}/operations/history` | 200, пагинация |
| Единая история (personal) | `GET …/personal-workspace/operations/history` | 200 |
| Internal metrics (разрешено) | `GET …/projects/{id}/internal-metrics` от роли с правом | 200, блок `metrics` |
| Internal metrics (запрещено) | тот же URL от пользователя без права | 403 |

Без токена: защищённые маршруты → **401**.

---

## Flutter

В каталоге `mobile_app/`:

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib
```

При наличии целевых тестов:

```bash
flutter test
```

---

## UI (короткий сценарий)

1. **Компания:** главная → плитка «История операций» → список TRANSFER + INCOME → открытие карточки → возврат.
2. **Заказчик (personal):** главная → история операций (если есть вход).
3. **Проект:** список проектов → **деталь проекта** (summary, карточка метрик, история) → **участники** → при наличии права — блок **«Данные по проекту»** (internal-metrics).

---

## Логи (опционально)

При **403** на internal-metrics в логах приложения ищется ключ **`project_internal_metrics.forbidden`** (контекст: `workspace`, `user_id`, `project_id`, при company — `company_id`).
