# 95 — Карта тестового покрытия (backend)

**Обновлено:** 2026-05-11 (в т.ч. `ProjectSummaryReportExpenseMetricsTest`, сводка проекта). Сводка по PHPUnit в `backend/tests/`. SQLite + `RefreshDatabase` для feature-тестов (см. `phpunit.xml`).

---

## TRANSFER

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| Pending-бейдж vs доступные действия | `Unit/TransferAvailableActionsPendingBadgeTest.php` — соответствие ключей `PENDING_BADGE_ACTION_KEYS` и `hasPendingConfirmationAction`. | Полный e2e по каждому переходу статуса через HTTP. |
| Агрегированная история + company OWNER/PARTNER | `Feature/AggregatedOperationsHistoryTabsTest.php` (в т.ч. `tab=all` / `tab=pending`, OWNER без участия в проекте; **company PROJECT_HEAD: pending без перевода в WAITING_24_HOURS**). | Личный кабинет: часть сценариев есть в том же файле; не все роли и не все статусы. |

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
| CRUD / права / доли | `Feature/ProjectExpenseItemsCompanyWorkspaceTest.php` — сумма `profit_shares`/`markup_shares` = 100%, PARTNER не POST/PATCH, soft-delete скрывает из списка. | Полный матричный набор ролей и edge cases долей; view-only GET для PARTNER — по желанию. |

---

## PRICE_LISTS (ТЗ-10B)

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| Company workspace API | `Feature/PriceListsCompanyWorkspaceTest.php` (+ невалидная цена позиции, `…/price-lists/available`). | Удаление с ветвлением под REPORT (`PriceListReportUsageChecker`) — после реализации REPORT. |
| Нормализация цен (маржа) | `Unit/PriceListPricingNormalizeTest.php` — `normalizeMoney`, `profit` на типовых строках. | Полный property-based тест на все строковые форматы. |

---

## OPERATIONS_HISTORY (агрегат)

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| `tab=pending` / `tab=all`, роли | `Feature/AggregatedOperationsHistoryTabsTest.php`. | REPORT в union и edge cases **report** в `tab=pending` — без отдельного feature-файла; пагинация union под нагрузкой. |

---

## PROJECTS

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| PARTNER / OWNER создают проект, кошелёк РП | `Feature/CreateProjectPartnerCompanyWorkspaceTest.php`, `Feature/CreateProjectOwnerCompanyWorkspaceTest.php` (в т.ч. заказчик при создании: **CUSTOMER, level=first** + wallet). | Полный матричный набор ролей компании. |
| Сводка проекта / расход по REPORT | `Feature/ProjectSummaryReportExpenseMetricsTest.php` — `expense_total` и баланс из применённых отчётов; отчёт без `wallets_applied_at` и сценарий с `wallets_reverted_at`; HTTP summary. | Расширение матрицы ролей и краевых сумм. |

---

## REPORT (foundation ТЗ-10C)

| Область | Покрыто | Не покрыто / слабо |
|---------|---------|---------------------|
| **ТЗ-10C.1 hardening (payload, pending, attach guard, search, customer approve)** | `Feature/ReportTenC1HardeningTest.php` — customer/second-order redaction, `WAITING_24_HOURS` вне pending, reject + wallet revert, cross-project attach **422**, transfer list `search`, customer approve → `WAITING_24_HOURS`. Дубликат attach **422** — `ReportTransferLinksCompanyWorkspaceTest`. | Полная матрица lifecycle и UI-smoke. |
| **personal-workspace REPORT API (list/show + customer + rollback)** | `Feature/ReportPersonalWorkspaceApiTest.php` — redacted payload для заказчика, approve через personal. | Полная матрица lifecycle (см. список ТЗ-10C.1). |
| **transfer-links** company-workspace | `Feature/ReportTransferLinksCompanyWorkspaceTest.php` — attach / list / detach; повторный attach → **422**. | Все роли и сочетания с редактированием отчёта в разных статусах. |
| **transfer-links** personal-workspace | `Feature/ReportTransferLinksPersonalWorkspaceTest.php` — партнёр (company) видит связь; заказчик (personal) — пустой список. | EMPLOYEE attach из personal и т.п. |
| **Защита маршрутов** | `Feature/ProtectedApiRoutesTest.php` — без auth на `…/transfer-links` (company + personal). | Полная матрица чувствительных REPORT-маршрутов. |
| **pending-count REPORT** | Косвенно: общий регресс `php artisan test`; логика в `ReportPendingActionCountService` + `ReportAvailableActionsService`. | Отдельный feature-тест на счётчик vs набор отчётов в **pending**. |
| **Остальной REPORT** | — | См. список ниже — **обязательно** нарастить перед «продуктовым» merge REPORT. |

**REPORT — что ещё нужно покрыть тестами (следующий этап):**

```text
1. lifecycle PROJECT_HEAD / PARTNER / EMPLOYEE;
2. SUPERVISOR branch;
3. ReportBalanceService apply/revert;
4. CUSTOMER reject;
5. COMPLETED rollback;
6. WAITING_24_HOURS auto complete (команда/schedule + HTTP edge);
7. snapshot строк после изменения прайса (регресс историчности);
8. visibility CUSTOMER / second-order recipient;
9. full aggregated history REPORT (tab=all|pending, роли);
10. full Flutter smoke.
```

После расширения покрытия — обновить этот файл и **`docs/10_operations/16_OPERATION_REPORT.md`** при смене контракта.

---

## Критичные тесты перед REPORT

1. **EXPENSE_ITEMS:** расширить покрытие GET для PARTNER (read-only) и сложные комбинации долей; при смене валидации — синхронизировать с `ProjectExpenseItemValidationService`.
2. **INCOME/TRANSFER:** хотя бы по одному интеграционному сценарию «полный переход + кошелёк» на SQLite (сейчас упор на available_actions и историю).
3. **REPORT (расширение после foundation):** `PriceListReportUsageChecker` + запрет hard-delete при использовании в отчёте; полный lifecycle + дельты; строки отчёта и ссылки на прайс/позицию; см. **`16_OPERATION_REPORT.md`**.
4. **Права company-workspace:** расширить `ProtectedApiRoutesTest` или отдельный класс для новых чувствительных маршрутов по мере роста API.
