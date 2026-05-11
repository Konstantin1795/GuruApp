# 90 — Current State

**Обновлено:** 2026-05-11. Короткий снимок; детали — в `docs/README_MODULAR.md` и файлах `00_core` … `30_flutter`. Монолиты в `docs/OldDocs/legacy_monolith/` не канон.

**Документация:** каноничный вход — **`docs/README_MODULAR.md`** и модульные файлы под `docs/` (в т.ч. **`docs/90_current/90_GURU_CURRENT_STATE.md`**). Корневые **`PROJECT_CONTEXT_GURU.md`** и **`docs/GURU_CONTEXT_INDEX.md`** из репозитория **удалены** — отдельных «индексов» в корне больше нет.

**Проверка статусов (факт кода):** TRANSFER и INCOME на backend + Flutter; единая лента `GET …/operations/history`; суммарный бейдж — `combinedOperationsPendingCountProvider`; операция REPORT, realtime и документы в продукте **не** реализованы.

---

## 1. Реализовано

- **Auth:** register, token, me, logout (Sanctum).
- **Workspaces:** список, company / personal / customer UX; создание компании.
- **Companies / counterparties:** текущая компания, список и создание контрагента, привязка по email (invite-first).
- **Projects:** список/создание; автосоздание PROJECT_HEAD и CUSTOMER; участники; кошельки участников (`ProjectParticipantWallet`, фабрика/баланс); API **`GET …/projects/{id}/summary`** и **`GET …/projects/{id}/internal-metrics`** (company + personal); Flutter **`ProjectDetailScreen`** (карточка метрик из summary, переход к истории операций, разделы); при **`can_view_internal_metrics`** — блок внутренних метрик на **`ProjectParticipantsScreen`** (`ProjectInternalMetricsSection`).
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

---

## 3. Не реализовано

- **REPORT** (операция «Отчёт») — только черновик в `docs/10_operations/13_OPERATION_REPORT_DRAFT.md` и UI «скоро».
- **WebSocket / realtime** обновлений.
- **Документы** (API и экраны) — заглушки «скоро».
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

- **ТЗ-10** — операция **REPORT** (опорный черновик: `docs/10_operations/13_OPERATION_REPORT_DRAFT.md`): проектирование и реализация по отдельному ТЗ.
- Доработки **ТЗ-07** (UX проекта, заказчик, аналитика) поверх уже существующего detail / summary / internal-metrics — по приоритету продукта.
- После REPORT — **документы** и **realtime** по отдельным ТЗ.
