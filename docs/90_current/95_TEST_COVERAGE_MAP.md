# 95 — Карта тестового покрытия (backend)

**Обновлено:** 2026-05-11. Сводка по PHPUnit в `backend/tests/`. SQLite + `RefreshDatabase` для feature-тестов (см. `phpunit.xml`).

---

## TRANSFER

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| Pending-бейдж vs доступные действия | `Unit/TransferAvailableActionsPendingBadgeTest.php` — соответствие ключей `PENDING_BADGE_ACTION_KEYS` и `hasPendingConfirmationAction`. | Полный e2e по каждому переходу статуса через HTTP. |
| Агрегированная история + company OWNER/PARTNER | `Feature/AggregatedOperationsHistoryTabsTest.php` (в т.ч. `tab=all` / `tab=pending`, OWNER без участия в проекте). | Личный кабинет: часть сценариев есть в том же файле; не все роли и не все статусы. |

---

## INCOME

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| Pending-бейдж | `Unit/IncomeAvailableActionsPendingBadgeTest.php`. | Полный lifecycle через API-тесты. |
| История / pending | В составе `AggregatedOperationsHistoryTabsTest.php` (личный кабинет, заказчик и др.). | Edge cases `reset_approval` vs бейдж — зафиксированы в документации сильнее, чем в тестах. |

---

## EXPENSE_ITEMS (ТЗ-10A)

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| CRUD / права | Нет выделенного feature-класса в репозитории на момент карты. | Soft-delete, доли, `markup_*`, PARTNER view-only — **нужны целевые feature-тесты** перед REPORT. |

---

## PRICE_LISTS (ТЗ-10B)

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| Company workspace API | `Feature/PriceListsCompanyWorkspaceTest.php`. | Удаление с ветвлением под REPORT (`PriceListReportUsageChecker`) — после реализации REPORT. |

---

## OPERATIONS_HISTORY (агрегат)

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| `tab=pending` / `tab=all`, роли | `Feature/AggregatedOperationsHistoryTabsTest.php`. | Пагинация union-запроса под нагрузкой, персональные edge cases. |

---

## PROJECTS

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| PARTNER создаёт проект | `Feature/CreateProjectPartnerCompanyWorkspaceTest.php`. | Остальные project API и customer-потоки. |

---

## REPORT

Не реализовано. Тестов нет. После ТЗ-10C — отдельный контур тестов (операция, снимки, взаимодействие с прайсами/статьями расходов).

---

## Критичные тесты перед REPORT

1. **EXPENSE_ITEMS:** feature-тесты прав (OWNER/PROJECT_HEAD manage, PARTNER read-only), soft-delete и валидация процентов/долей.
2. **INCOME/TRANSFER:** хотя бы по одному интеграционному сценарию «полный переход + кошелёк» на SQLite (сейчас упор на available_actions и историю).
3. **REPORT (после реализации):** `PriceListReportUsageChecker` + запрет hard-delete при использовании в отчёте; строки отчёта и ссылки на прайс/позицию.
4. **Права company-workspace:** расширить `ProtectedApiRoutesTest` или отдельный класс для новых чувствительных маршрутов по мере роста API.
