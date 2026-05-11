# 91 — Текущая задача: операция «Отчёт» / REPORT

Краткий контекст для нового чата в Cursor по этапу **ТЗ-10**. Без опоры на старые монолиты.

---

## 1. Название задачи

```text
ТЗ-10 — Операция «Отчёт» / REPORT
```

---

## 2. Цель

```text
Подготовить и затем реализовать операцию REPORT, которая фиксирует расходы проекта, влияет на аналитику, начисляет заработанное участникам и запускает отдельный lifecycle согласования.
```

---

## 3. Что уже реализовано

```text
TRANSFER
INCOME
Unified operations history
combined pending count
ProjectDetailScreen
Project Summary Metrics
Internal Metrics
модульная документация
```

---

## 4. Что не трогать без отдельного решения

```text
Transfer lifecycle
Income lifecycle
wallet math
workspace access
ProjectParticipant wallet model
API response contract
```

---

## 5. Обязательные документы для нового Cursor-чата

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
docs/20_api/20_API_ROUTES_CURRENT.md
docs/30_flutter/32_FLUTTER_SCREENS_CURRENT.md
docs/90_current/90_GURU_CURRENT_STATE.md
docs/90_current/91_GURU_NEXT_TASK_REPORT.md
```

---

## 6. Не использовать как канон

```text
docs/OldDocs/
docs/OldDocs/legacy_monolith/
```

---

## 7. Важное предупреждение

```text
REPORT пока не реализован. 13_OPERATION_REPORT_DRAFT.md — это черновик направления, а не финальное ТЗ. Перед реализацией нужно сначала согласовать бизнес-логику REPORT.
```
