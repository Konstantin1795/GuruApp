# 90 — Current State

**Обновлено:** 2026-05-11 (в т.ч. сводка проекта: расход по REPORT; Flutter: компактная форма отчёта + `ReportPositionsEditorScreen`). Короткий снимок; детали — в `docs/README_MODULAR.md` и файлах `00_core` … `30_flutter`. Монолиты в `docs/OldDocs/legacy_monolith/` не канон.

**Документация:** каноничный вход — **`docs/README_MODULAR.md`** и модульные файлы под `docs/` (в т.ч. этот файл). **ТЗ-11:** структура репозитория и тестов — **`94_CODE_STRUCTURE_MAP.md`**, **`95_TEST_COVERAGE_MAP.md`**, чеклист готовности кода — **`96_GURU_DEFINITION_OF_DONE.md`**. **ТЗ-12.1 (targeted refactor перед REPORT):** создание проекта вынесено в `CreateProjectService`; расширены тесты OWNER/PARTNER + кошелёк и сценарий с заказчиком; в PHPDoc кошельков зафиксировано, что REPORT — отдельные сервисы (`ReportBalanceService` и др.), без дельт в контроллерах/`WalletBalanceService`. Подробности — раздел **«12. ТЗ-12.1»** в `94_CODE_STRUCTURE_MAP.md`.

**Проверка статусов (факт кода):** TRANSFER и INCOME на backend + Flutter; единая лента `GET …/operations/history` с **`tab`** (`pending` | `all`); суммарный бейдж — `combinedOperationsPendingCountProvider` (**TRANSFER + INCOME + REPORT** pending-count); **ТЗ-10A** и **ТЗ-10B** реализованы в **main**. **REPORT foundation (ТЗ-10C)** на backend реализована (схема, lifecycle, баланс по дельтам, ссылки на переводы, агрегированная история, pending-count, company-workspace API, transfer-links company + personal). **ТЗ-10C.1:** personal-workspace list/show отчётов, customer approve/reject, rollback completed, transfer-links; redacted JSON и **`viewer_context`**; summary **`can_create_report`**; поиск **`search`** на list transfers/reports (company + personal); **`linked_report`** на show transfer; Flutter — **`ReportDetailScreen`**, **`TransferDetailScreen`** (attach к отчёту), **`CreateEditReportScreen`** (компактная форма: блок «Позиции» без длинного inline-списка; строки — в **`ReportPositionsEditorScreen`** с вкладками «Все позиции» / «Добавлено», PRICE_LIST + CUSTOM, правило блокировки сумм при наличии строк), кнопка «Отчёт» в company shell. **Сводка проекта (`GET …/summary`):** **`expense_total`** = сумма **`customer_total_amount`** по REPORT с **`wallets_applied_at`** и без отката дельт; **`project_balance`** в карточке метрик = подтверждённые поступления **минус** этот расход (см. `ProjectSummaryMetricsService`). **Tech debt:** PATCH отчёта в UI, detach линков из клиента, ручной smoke полного REPORT lifecycle, realtime, доработка **`PriceListReportUsageChecker`**.

**Канон по реализованному foundation:** **`docs/10_operations/16_OPERATION_REPORT.md`**. Исторические уточнения до кода — **`docs/10_operations/13_OPERATION_REPORT_DRAFT.md`** (раздел **9**).

ТЗ-10B — Прайс-листы и позиции прайс-листа реализованы, запушены и прошли ручной smoke-проверку в приложении. Проверены сценарии OWNER / PROJECT_HEAD-Партнёр / проектные прайс-листы.

---

## 1. Реализовано

- **Auth:** register, token, me, logout (Sanctum).
- **Workspaces:** список, company / personal / customer UX; создание компании.
- **Companies / counterparties:** текущая компания, список и создание контрагента, привязка по email (invite-first).
- **Projects:** список/создание проекта в company-workspace для **OWNER** и **PARTNER** компании (создатель становится **PROJECT_HEAD** first-order); при указании заказчика создаётся **CUSTOMER** с **level = first** (участник первого порядка; `second` — для участников из операций, не из формы создания проекта); участники; кошельки участников (`ProjectParticipantWallet`, фабрика/баланс); API **`GET …/projects/{id}/summary`** и **`GET …/projects/{id}/internal-metrics`** (company + personal); в **summary** карточка «Показатели проекта»: **`expense_total`** по подтверждённым REPORT (**`customer_total_amount`**, дельты применены и не откатаны), **`project_balance`** = подтверждённые поступления − расход по отчётам; Flutter **`ProjectDetailScreen`** (метрики из summary, переход к истории операций, разделы); при **`can_view_internal_metrics`** — блок внутренних метрик на **`ProjectParticipantsScreen`** (`ProjectInternalMetricsSection`; там другой смысл **`project_balance`** — из кошельков). **Статьи расходов проекта (ТЗ-10A), реализовано:** backend-модель и таблицы долей; **`profit_shares`**; **`markup_enabled`**, **`markup_percent`**, **`markup_shares`**; **soft-delete** (`is_active` + `deleted_at`); права **OWNER / PROJECT_HEAD** (управление) и **PARTNER first-order** (просмотр); API company-workspace (`…/expense-items`, `…/recipients`, CRUD); Flutter — список, создание/редактирование, **`ExpenseItemRecipientPickerSheet`** без вкладок (только контрагенты компании, поиск, множественный выбор); во **`visibility`** summary — **`can_view_expense_items`** / **`can_manage_expense_items`**. **Прайс-листы (ТЗ-10B), реализовано:** таблицы `units`, `price_lists`, `price_list_groups`, `price_list_positions`, `project_price_lists`; API (`…/units`, `…/price-lists`, вложенные группы/позиции, `…/projects/{id}/price-lists*`); сервисы доступа/удаления/прикрепления; Flutter — библиотека компании, деталь прайса, группы/позиции, прикрепление к проекту; **`GET /context`** и **`visibility`** summary — флаги для UI прайсов.
- **TRANSFER:** полный lifecycle в сервисах Operations, маршруты company + personal, Flutter create / list / detail, `available_actions`, pending-count.
- **INCOME:** lifecycle, маршруты, Flutter create / detail, действия заказчика, pending-count.
- **Unified operations:** `GET …/operations/history` с параметром **`tab`** (`pending` | `all`): вкладка «На подтверждение» / «Все операции»; на клиенте **`AggregatedOperationsHistoryScreen`** (TabBar + TabBarView); **`combinedOperationsPendingCountProvider`** = сумма pending-count **TRANSFER + INCOME + REPORT** и совпадает с вкладкой **pending** (без `WAITING_24_HOURS`, без «только откат», без **INCOME** `reset_approval` на этапе заказчика — тогда «на подтверждение» только у заказчика; для TRANSFER учтён **`complete_immediate`** у инициатора РП/Партнёра в **CREATED**; для REPORT `complete_waiting` не входит в pending-бейдж). Для **OWNER** компании вкладка **all** — все операции компании (включая REPORT по `company_id`); для **PARTNER / CUSTOMER** — только участие в строке операции.
- **REPORT (ТЗ-10C + 10C.1):** backend — см. **`docs/10_operations/16_OPERATION_REPORT.md`**; Flutter — карточка в истории, pending, **`ReportDetailScreen`** (attach перевода), **`TransferDetailScreen`** (attach к отчёту, баннер связи), **`CreateEditReportScreen`** + **`ReportPositionsEditorScreen`** (компактная форма, строки отдельно; см. **16**).
- **Customer:** карточки проектов с **«Поступило» / баланс** из API (`PersonalProjectResource` + экран заказчика).
- **Дашборд компании:** `GET …/dashboard/analytics` + `GET …/dashboard/analytics/operations` (см. `20_API_ROUTES_CURRENT.md`); сервис **`CompanyDashboardAnalyticsService`**; Flutter **`CompanyDashboardScreen`** — квартал / выбор месяца, суммы, списки операций по клику; тесты **`CompanyDashboardAnalyticsTest`**.
- **Аналитика главного экрана Company Workspace доработана:**
  - задолженность и переплата считаются по `project_id` + `project_participant_id`, без взаимного гашения разных участников/проектов;
  - REPORT и TRANSFER могут закрываться аналитически без `report_transfer_links`, если совпадают проект и участник;
  - bottom sheet «Операции по показателю» показывает бизнесовые карточки без #0 и project id;
  - OWNER получил корректную видимость transfer details по проектам своей компании.
- **Локализация:** RU/EN, ARB, переключатель локали.

---

## 2. Частично реализовано

- Вкладка **«Операции»** в нижнем меню компании — оболочка / точки входа; не полноценный «операционный центр».
- **Метрики проекта:** карточка на **`ProjectDetailScreen`** использует **`GET …/summary`**: расход по **REPORT** с применёнными дельтами; баланс в карточке = поступления − расход; блок **`internal-metrics`** — отдельные показатели (кошельки и плейсхолдеры там, где ещё нет продуктовой аналитики).
- **Прайс-листы (ТЗ-10B) и историчность удаления:** в `PriceListDeletionService` заложена ветка soft-delete при «использовании в отчётах»; **`PriceListReportUsageChecker`** при foundation REPORT **ещё** должен быть доработан под реальные ссылки отчёт → прайс (см. TODO в коде и **`docs/10_operations/15_PRICE_LISTS.md`**), иначе историчность удаления под риском.

---

## 3. Не реализовано

- **Расширение REPORT в продукте:** редактирование отчёта (PATCH) в Flutter, detach transfer-link из UI, полный интеграционный smoke по всему lifecycle, WebSocket — см. **`16_OPERATION_REPORT.md`** и **`95_TEST_COVERAGE_MAP.md`**.
- **WebSocket / realtime** обновлений.
- **Документы** (прочие, вне прайс-листов) — заглушки «скоро».
- **Push**, **offline-sync**, **production-grade** тестовый контур.
- Расширенная **финансовая аналитика** вне главного экрана company-workspace (если появится отдельный продуктовый контур).

---

## 4. Текущий технический долг

- **ТЗ-11 (аудит):** смешение EN/RU в PHPDoc отдельных сервисов Operations; крупные Flutter-экраны (`ProjectDetailScreen`, `AggregatedOperationsHistoryScreen`) — позже декомпозиция на виджеты без смены поведения; **интеграционный «полный lifecycle + кошелёк»** для TRANSFER/INCOME через HTTP — по отдельному ТЗ.
- **ТЗ-12.1:** создание проекта вынесено в `CreateProjectService` — при добавлении полей создания проекта обновлять сервис и оба feature-теста (OWNER / PARTNER). Интеграционные smoke «TRANSFER/INCOME + дельты» и расширенный **REPORT** lifecycle — по отдельному этапу после foundation.

## 5. Не трогать без отдельного ТЗ

- Жизненные циклы **TRANSFER / INCOME** и математика кошельков.
- Изоляция **workspaces** и правила доступа.
- Контракт **`ApiResponse`** и доменная модель **User / Counterparty / ProjectParticipant** (менять только осознанно и согласованно).

---

## 6. Следующий крупный этап

**Аналитика главного экрана Company Workspace (ТЗ `docs/90_current/TZ_Company_Dashboard_Analytics_Report_Transfer.md`):** backend + Flutter MVP (квартал / месяц, суммы, списки операций) и тесты **`CompanyDashboardAnalyticsTest`**; уточнение списков по задолженности/переплате и продуктовые доработки — по обратной связи.

- **После foundation:** полноценный UI отчёта, personal-workspace parity для REPORT (по необходимости), расширенные тесты, доработка **`PriceListReportUsageChecker`**, продуктовая операция **REPORT** поверх foundation. Канон по статьям расходов — **`docs/10_operations/14_PROJECT_EXPENSE_ITEMS.md`**; по прайс-листам — **`docs/10_operations/15_PRICE_LISTS.md`**; по текущему foundation — **`docs/10_operations/16_OPERATION_REPORT.md`**.
- Доработки **ТЗ-07** (UX проекта, заказчик, аналитика) поверх уже существующего detail / summary / internal-metrics — по приоритету продукта.
- После REPORT — **документы** и **realtime** по отдельным ТЗ.
