# 16 — Operation REPORT (foundation / ТЗ-10C)

**Статус:** канон по **уже реализованному** REPORT foundation в коде (backend + минимальный Flutter).  
**Не канон** для нереализованных частей: полный UI отчёта, полный personal-workspace API действий, документы, realtime.

Исторический черновик и уточнения до кода — **`13_OPERATION_REPORT_DRAFT.md`** (в т.ч. раздел **9**); при конфликте постановки «на бумаге» и этого файла приоритет у **фактической реализации** и у **16**.

---

## 1. Модель данных

1. **REPORT** реализован отдельной сущностью **`report_operations`** (не как строка в универсальной бизнес-таблице `operations` для доменной логики отчёта).
2. Общая таблица **`operations`** для бизнес-логики REPORT **не используется** (TRANSFER/INCOME по-прежнему живут в своих таблицах и своих lifecycle).
3. Строки отчёта — **`report_operation_lines`**.
4. Строки хранят **snapshot**: скопированные поля (название, единицы, количество, цены, суммы, при необходимости ссылки на прайс-лист/позицию); пересчёт итогов отчёта идёт от сохранённых строк, а не от «живого» прайса после изменения прайса в справочнике.
5. Финансовые дельты REPORT — **`report_wallet_deltas`**.
6. **Откат** финансов выполняется **по сохранённым строкам дельт** (`ReportBalanceService::revertReportDeltas`), а не пересчётом из текущих строк или справочников.
7. Связь отчёта с переводами — **`report_transfer_links`** (один перевод не более чем в одном отчёте; уникальность по `transfer_operation_id`).
8. **TRANSFER** остаётся отдельной операцией со своим lifecycle; привязка к отчёту не подменяет lifecycle перевода.

---

## 2. Номера операций и история

9. **`operation_number`**: для отчётов **`REP-{id}`**, для переводов **`TRF-{id}`** (после выделения id), отдаётся в API.
10. **Агрегированная история** операций (`AggregatedOperationsHistoryService`): третья ветка **`operation_kind = report`** наряду с transfer и income; те же правила `tab=pending` / `tab=all`, что и для остальных типов (с учётом visibility).

---

## 3. Pending и lifecycle (ключевые правила)

11. Статус **`WAITING_24_HOURS`** **не считается** ожиданием действия для **pending-count / бейджа**: ключ **`complete_waiting`** доступен в `available_actions`, но **не входит** в `PENDING_BADGE_ACTION_KEYS` в `ReportAvailableActionsService` (согласовано с ТЗ-10C).
12. **`COMPLETED` rollback** возвращает отчёт в **`PROJECT_HEAD_APPROVAL`** и откатывает финансы по дельтам (`ReportLifecycleService`).

---

## 4. Видимость и роли

13. **Заказчик (CUSTOMER)** не видит переводы к отчёту: **`GET …/transfer-links`** возвращает пустой список; в **`GET …/reports/{id}`** связи **`transfer_links`** для роли CUSTOMER в проекте не подгружаются (UI «вкладка переводов» — только не-CUSTOMER).
14. **Основной получатель** при необходимости создаётся как **second-order** `ProjectParticipant`; такой участник **не получает** полноту данных как **OWNER** компании без участия в проекте — видимость отчётов и строк в ленте ограничена правилами `ReportVisibilityService` и участием в операции (см. также агрегированную историю для non-OWNER).
15. **Заказчик проекта** (**first-order CUSTOMER**) по определению **не совпадает** с основным получателем отчёта (валидация/разрешение получателя в `ReportParticipantResolver` / `ReportService`).

---

## 5. MVP-ограничения и клиент

16. **Отрицательная прибыль** (`profit_amount < 0`) в MVP **запрещена**: ответ **422** до применения финансов (`ReportService::recalculateTotals`).
17. **Flutter (текущее):** отчёт **отображается** в объединённой истории операций, **участвует** в суммарном pending-count, открывается через **`ReportDetailStubScreen`**; **полноценный** create/edit/detail UI отчёта **не** реализован.
18. **Personal-workspace (текущее):** реализованы **`GET /operations/reports/pending-count`** и **transfer-links** (`GET`/`POST`/`DELETE` под `/api/personal-workspace/projects/{projectId}/…`); **полного** набора маршрутов REPORT (list/show/patch/submit/customer actions и т.д.), как в company-workspace, **нет** — следующий этап.

---

## 6. См. также

- Маршруты API: **`docs/20_api/20_API_ROUTES_CURRENT.md`**
- Статьи расходов: **`docs/10_operations/14_PROJECT_EXPENSE_ITEMS.md`**
- Прайс-листы: **`docs/10_operations/15_PRICE_LISTS.md`**
- Карта тестов: **`docs/90_current/95_TEST_COVERAGE_MAP.md`**
