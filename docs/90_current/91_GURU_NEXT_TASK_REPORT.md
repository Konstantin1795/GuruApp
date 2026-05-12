# 91 — Текущая задача: цепочка ТЗ-10 к операции «Отчёт» / REPORT

Краткий контекст для нового чата в Cursor по этапам **ТЗ-10** (подготовка и REPORT). Без опоры на старые монолиты.

---

## 1. Название задачи

```text
ТЗ-10 — операция «Отчёт» / REPORT (и подэтапы ТЗ-10A …)
```

---

## 2. Цель

```text
Подготовить и затем реализовать операцию REPORT, которая фиксирует расходы проекта, влияет на аналитику, начисляет заработанное участникам и запускает отдельный lifecycle согласования.
```

---

## 3. Цепочка подэтапов (актуально)

```text
ТЗ-10A — статьи расходов проекта: реализовано в коде, запушено в main (см. 14_PROJECT_EXPENSE_ITEMS.md)
ТЗ-10B — прайс-листы / позиции / прикрепление к проекту: реализовано в коде (см. 15_PRICE_LISTS.md)
ТЗ-10C — REPORT foundation: следующий зависимый этап перед полноценным REPORT
ТЗ-10 — REPORT: пока не реализован (черновик 13_OPERATION_REPORT_DRAFT.md)
```

Перед полноценным REPORT уже есть **справочник статей расходов (ТЗ-10A)** и **прайс-листы компании / прикрепление к проекту (ТЗ-10B)**; следующим логическим зависимым шагом по плану ТЗ-10 является **ТЗ-10C (REPORT foundation)**.

---

## 4. Что уже реализовано

```text
TRANSFER
INCOME
Unified operations history
combined pending count
ProjectDetailScreen
Project Summary Metrics
Internal Metrics
ТЗ-10A — статьи расходов (backend + Flutter: список, создание/редактирование, picker контрагентов компании без вкладок, soft-delete)
ТЗ-10B — прайс-листы (backend + Flutter: библиотека компании, группы/позиции, единицы, прикрепление к проекту; см. 15_PRICE_LISTS.md)
модульная документация
```

---

## 5. Что не трогать без отдельного решения

```text
Transfer lifecycle
Income lifecycle
wallet math
workspace access
ProjectParticipant wallet model
API response contract
```

---

## 6. Обязательные документы для нового Cursor-чата

```text
docs/README_MODULAR.md
docs/00_core/00_GURU_CORE_PRINCIPLES.md
docs/00_core/01_GURU_ARCHITECTURE_STANDARDS.md
docs/00_core/02_GURU_WORKSPACES_AND_ACCESS.md
docs/00_core/03_GURU_DOMAIN_MODEL.md
docs/10_operations/10_OPERATION_COMMON_RULES.md
docs/10_operations/11_OPERATION_TRANSFER.md
docs/10_operations/12_OPERATION_INCOME.md
docs/10_operations/13_OPERATION_REPORT_DRAFT.md
docs/10_operations/14_PROJECT_EXPENSE_ITEMS.md
docs/10_operations/15_PRICE_LISTS.md
docs/20_api/20_API_ROUTES_CURRENT.md
docs/30_flutter/32_FLUTTER_SCREENS_CURRENT.md
docs/90_current/90_GURU_CURRENT_STATE.md
docs/90_current/91_GURU_NEXT_TASK_REPORT.md
```

---

## 7. Не использовать как канон

```text
docs/OldDocs/
docs/OldDocs/legacy_monolith/
```

---

## 8. Важное предупреждение

```text
REPORT пока не реализован. 13_OPERATION_REPORT_DRAFT.md — это черновик направления, а не финальное ТЗ. Перед реализацией нужно сначала согласовать бизнес-логику REPORT.
Прайс-листы (ТЗ-10B) реализованы — канон `docs/10_operations/15_PRICE_LISTS.md`.
```
