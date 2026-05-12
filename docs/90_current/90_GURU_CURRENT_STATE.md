# 90 — Current State

**Обновлено:** 2026-05-12. Короткий снимок; детали — в `docs/README_MODULAR.md` и файлах `00_core` … `30_flutter`. Монолиты в `docs/OldDocs/legacy_monolith/` не канон.

**Документация:** каноничный вход — **`docs/README_MODULAR.md`** и модульные файлы под `docs/` (в т.ч. этот файл).

**Проверка статусов (факт кода):** TRANSFER и INCOME на backend + Flutter; единая лента `GET …/operations/history`; суммарный бейдж — `combinedOperationsPendingCountProvider`; **ТЗ-10A** и **ТЗ-10B** (прайс-листы, единицы, прикрепление к проекту) реализованы в **main**; операция **REPORT**, realtime и полноценные **документы** в продукте **не** реализованы.

---

## 1. Реализовано

- **Auth:** register, token, me, logout (Sanctum).
- **Workspaces:** список, company / personal / customer UX; создание компании.
- **Companies / counterparties:** текущая компания, список и создание контрагента, привязка по email (invite-first).
- **Projects:** список/создание; автосоздание PROJECT_HEAD и CUSTOMER; участники; кошельки участников (`ProjectParticipantWallet`, фабрика/баланс); API **`GET …/projects/{id}/summary`** и **`GET …/projects/{id}/internal-metrics`** (company + personal); Flutter **`ProjectDetailScreen`** (карточка метрик из summary, переход к истории операций, разделы); при **`can_view_internal_metrics`** — блок внутренних метрик на **`ProjectParticipantsScreen`** (`ProjectInternalMetricsSection`). **Статьи расходов проекта (ТЗ-10A), реализовано:** backend-модель и таблицы долей; **`profit_shares`**; **`markup_enabled`**, **`markup_percent`**, **`markup_shares`**; **soft-delete** (`is_active` + `deleted_at`); права **OWNER / PROJECT_HEAD** (управление) и **PARTNER first-order** (просмотр); API company-workspace (`…/expense-items`, `…/recipients`, CRUD); Flutter — список, создание/редактирование, **`ExpenseItemRecipientPickerSheet`** без вкладок (только контрагенты компании, поиск, множественный выбор); во **`visibility`** summary — **`can_view_expense_items`** / **`can_manage_expense_items`**. **Прайс-листы (ТЗ-10B), реализовано:** таблицы `units`, `price_lists`, `price_list_groups`, `price_list_positions`, `project_price_lists`; API (`…/units`, `…/price-lists`, вложенные группы/позиции, `…/projects/{id}/price-lists*`); сервисы доступа/удаления/прикрепления; Flutter — библиотека компании, деталь прайса, группы/позиции, прикрепление к проекту; **`GET /context`** и **`visibility`** summary — флаги для UI прайсов.
- **TRANSFER:** полный lifecycle в сервисах Operations, маршруты company + personal, Flutter create / list / detail, `available_actions`, pending-count.
- **INCOME:** lifecycle, маршруты, Flutter create / detail, действия заказчика, pending-count.
- **Unified operations:** `GET …/operations/history` (TRANSFER + INCOME); на клиенте объединённая лента и **`combinedOperationsPendingCountProvider`** (сумма pending по TRANSFER и INCOME для scope).
- **Customer:** карточки проектов с **«Поступило» / баланс** из API (`PersonalProjectResource` + экран заказчика).
- **Локализация:** RU/EN, ARB, переключатель локали.

---

## 2. Частично реализовано

- Вкладка **«Операции»** в нижнем меню компании — оболочка / точки входа; не полноценный «операционный центр».
- **Дашборд компании:** часть блоков (квартальная аналитика и т.п.) — заглушки до REPORT и полной ТЗ-07 по аналитике.
- **Метрики проекта:** сводка и внутренний блок метрик по API есть; часть полей internal-metrics — осмысленные суммы из кошельков, часть — плейсхолдеры до REPORT (см. сервисы Projects).
- **Прайс-листы (ТЗ-10B) и историчность удаления:** в `PriceListDeletionService` заложена ветка soft-delete при «использовании в отчётах»; **`PriceListReportUsageChecker`** до реализации REPORT **всегда false** (отчётов нет — hard-delete допустим). После REPORT checker **обязан** быть доработан (см. TODO в коде и **`docs/10_operations/15_PRICE_LISTS.md`**), иначе историчность нарушится.

---

## 3. Не реализовано

- **REPORT** (операция «Отчёт») — только черновик в `docs/10_operations/13_OPERATION_REPORT_DRAFT.md` и UI «скоро» для типа операции «Отчёт».
- **WebSocket / realtime** обновлений.
- **Документы** (прочие, вне прайс-листов) — заглушки «скоро».
- **Push**, **offline-sync**, **production-grade** тестовый контур.
- Полная **финансовая аналитика** (долг / переплата и т.д.) без REPORT.

---

## 4. Текущий технический долг

- Дашборд компании и «полная» финансовая аналитика без REPORT; не раздувать placeholder-логику до отдельного ТЗ.

---

## 5. Не трогать без отдельного ТЗ

- Жизненные циклы **TRANSFER / INCOME** и математика кошельков.
- Изоляция **workspaces** и правила доступа.
- Контракт **`ApiResponse`** и доменная модель **User / Counterparty / ProjectParticipant** (менять только осознанно и согласованно).

---

## 6. Следующий крупный этап

- **ТЗ-10C — REPORT foundation** и полноценная операция **REPORT** (опорный черновик: `docs/10_operations/13_OPERATION_REPORT_DRAFT.md`); канон по статьям расходов — **`docs/10_operations/14_PROJECT_EXPENSE_ITEMS.md`**; канон по прайс-листам — **`docs/10_operations/15_PRICE_LISTS.md`**.
- Доработки **ТЗ-07** (UX проекта, заказчик, аналитика) поверх уже существующего detail / summary / internal-metrics — по приоритету продукта.
- После REPORT — **документы** и **realtime** по отдельным ТЗ.
