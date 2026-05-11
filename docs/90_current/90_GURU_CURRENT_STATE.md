# 90 — Current State

**Обновлено:** 2026-05-09. Короткий снимок; детали — в `docs/README_MODULAR.md` и файлах `00_core` … `30_flutter`. Монолиты в `docs/OldDocs/legacy_monolith/` не канон.

**Проверка статусов (факт кода):** TRANSFER и INCOME на backend + Flutter; единая лента `GET …/operations/history`; суммарный бейдж — `combinedOperationsPendingCountProvider`; операция REPORT, realtime и документы в продукте **не** реализованы.

---

## 1. Реализовано

- **Auth:** register, token, me, logout (Sanctum).
- **Workspaces:** список, company / personal / customer UX; создание компании.
- **Companies / counterparties:** текущая компания, список и создание контрагента, привязка по email (invite-first).
- **Projects:** список/создание; автосоздание PROJECT_HEAD и CUSTOMER; участники; кошельки участников (`ProjectParticipantWallet`, фабрика/баланс).
- **TRANSFER:** полный lifecycle в сервисах Operations, маршруты company + personal, Flutter create / list / detail, `available_actions`, pending-count.
- **INCOME:** lifecycle, маршруты, Flutter create / detail, действия заказчика, pending-count.
- **Unified operations:** `GET …/operations/history` (TRANSFER + INCOME); на клиенте объединённая лента и **`combinedOperationsPendingCountProvider`** (сумма pending по TRANSFER и INCOME для scope).
- **Customer:** карточки проектов с **«Поступило» / баланс** из API (`PersonalProjectResource` + экран заказчика).
- **Локализация:** RU/EN, ARB, переключатель локали.

---

## 2. Частично реализовано

- Вкладка **«Операции»** в нижнем меню компании — оболочка / точки входа; не полноценный «операционный центр».
- **Дашборд компании:** часть блоков (квартальная аналитика и т.п.) — заглушки до REPORT и ТЗ-07.
- **Статистика проекта** у исполнителя — базово; расширенная аналитика — позже.

---

## 3. Не реализовано

- **REPORT** (операция «Отчёт») — только черновик в `docs/10_operations/13_OPERATION_REPORT_DRAFT.md` и UI «скоро».
- **WebSocket / realtime** обновлений.
- **Документы** (API и экраны) — заглушки «скоро».
- **Push**, **offline-sync**, **production-grade** тестовый контур.
- Полная **финансовая аналитика** (долг / переплата и т.д.) без REPORT.

---

## 4. Текущий технический долг

- Виджет **`AggregatedTransfersHistoryScreen`** по смыслу уже «операции», имя файла/класса историческое — при желании переименовать без смены поведения.
- Дашборд/метрики ждут ТЗ-07; до этого не раздувать placeholder-логику.

---

## 5. Не трогать без отдельного ТЗ

- Жизненные циклы **TRANSFER / INCOME** и математика кошельков.
- Изоляция **workspaces** и правила доступа.
- Контракт **`ApiResponse`** и доменная модель **User / Counterparty / ProjectParticipant** (менять только осознанно и согласованно).

---

## 6. Следующий крупный этап

- **ТЗ-07:** UI проекта и метрики (детальный экран проекта, показатели для исполнителя/заказчика в рамках согласованного объёма).
- После стабилизации операций — приоритетно обсуждаем **REPORT**, затем **документы** и **realtime** по отдельным ТЗ.
