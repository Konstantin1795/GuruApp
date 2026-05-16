# 16 — Operation REPORT (foundation / ТЗ-10C)

**Статус:** канон по **уже реализованному** REPORT foundation + **ТЗ-10C.1** (API parity, personal list/show/actions, attach-flow в UI, MVP create/edit с несколькими строками и прайс-строками, поиск list transfers/reports) + **компактный основной экран отчёта** и отдельный **`ReportPositionsEditorScreen`** на Flutter.  
**Tech debt:** редактирование черновика отчёта после создания (PATCH UI), детач линков из Flutter, расширенные фильтры attach, realtime.

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
14. **Сериализация отчёта для API:** в **GET list/show** (company- и personal-workspace) ответ включает **`viewer_context`**: `full` \| `customer` \| `second_order_recipient`. Для **CUSTOMER** из тела убраны внутренние суммы и «внутренние» поля строк; для **second-order** основного получателя скрыты суммы заказчика, **`transfer_links`** фильтруются по участию пользователя в переводе (`ReportOperationApiPayloadFactory` + `ReportOperationViewerModeResolver`).
15. **Основной получатель** при необходимости создаётся как **second-order** `ProjectParticipant`; такой участник **не получает** полноту данных как **OWNER** компании без участия в проекте — видимость отчётов и строк в ленте ограничена правилами `ReportVisibilityService` и участием в операции (см. также агрегированную историю для non-OWNER).
16. **Заказчик проекта** (**first-order CUSTOMER**) по определению **не совпадает** с основным получателем отчёта (валидация/разрешение получателя в `ReportParticipantResolver` / `ReportService`).

---

## 5. MVP-ограничения и клиент

17. **Отрицательная прибыль** (`profit_amount < 0`) в MVP **запрещена**: ответ **422** до применения финансов (`ReportService::recalculateTotals`).
18. **Flutter — форма отчёта (ТЗ-10C.1 + компактный UI):** отчёт в объединённой истории; **`ReportDetailScreen`** (детали, вкладка «Переводы к отчёту» с **«Прикрепить перевод»** и bottom sheet поиска); **`TransferDetailScreen`** — **`linked_report`**, кнопка **«Прикрепить к отчёту»**. **`CreateEditReportScreen`** — **компактный** основной экран: проект, дата операции, статья расходов, основной получатель, **компактный блок «Позиции»** (краткая сводка, без длинного inline-списка строк на этом экране), суммы (получателю / заказчику), наценка, прибыль, комментарий, действия отправки. **Строки отчёта** выносятся в отдельный полноэкранный **`ReportPositionsEditorScreen`** (`report_positions_editor_screen.dart`): вкладки **«Все позиции»** и **«Добавлено»**, выбор прайс-листа проекта, поиск, выбор **PRICE_LIST**-позиций с указанием количества, перенос в «Добавлено», там же редактирование количества, удаление строк, добавление **CUSTOM**-строк (наименование, единица, количество, цены за ед. получателю/заказчику), **preview** итогов; при возврате на форму отчёта список строк подставляется обратно. Доменная модель строк на клиенте — **`ReportLineData`** (`report_line_data.dart`). Старый bottom sheet выбора строк из прайса (**`report_price_list_line_picker_sheet.dart`**) **удалён** в пользу редактора. **Правило сумм:** если в отчёте есть **хотя бы одна строка**, суммы на основном экране **заблокированы** для ручного ввода и считаются из строк (preview на клиенте; **финальный расчёт всегда выполняет backend** при создании/сохранении). Если строк **нет**, допускается **ручной MVP-сценарий** сумм по текущей логике экрана.
19. **Personal-workspace (ТЗ-10C.1):** **`GET …/operations/reports`**, **`GET …/reports/{id}`**, **`POST …/approve-customer`**, **`POST …/reject-customer`**, **`POST …/rollback-completed`**, **transfer-links** list/attach/detach под `/api/personal-workspace/projects/{projectId}/…`. Создание отчёта и остальные lifecycle-этапы (кроме перечисленного) — **company-workspace**.
20. **Поиск для attach UI:** опциональный query **`search`** на **`GET …/operations/transfers`** и **`GET …/operations/reports`** (company и personal): номер операции, дата `YYYY-MM-DD`, суммы — см. `TransferOperationListSearchFilter`, `ReportOperationListSearchFilter`.

---

## 6. См. также

- Маршруты API: **`docs/20_api/20_API_ROUTES_CURRENT.md`** (в т.ч. семантика **`metrics.expense_total`** / **`project_balance`** в `GET …/summary`).
- Статьи расходов: **`docs/10_operations/14_PROJECT_EXPENSE_ITEMS.md`**
- Прайс-листы: **`docs/10_operations/15_PRICE_LISTS.md`**
- Карта тестов: **`docs/90_current/95_TEST_COVERAGE_MAP.md`**
