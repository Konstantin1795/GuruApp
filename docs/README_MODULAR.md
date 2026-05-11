# GURU — модульная документация для Cursor

## Быстрый вход

**Репозиторий:** GuruApp — `backend/` (Laravel API), `mobile_app/` (Flutter).  
**Стек:** PHP 8.3 / Laravel 13 / Sanctum / PostgreSQL; Flutter / Riverpod / go_router / Dio.

**Единая точка входа:** этот файл — `docs/README_MODULAR.md`. Часто достаточно приложить его вместе с **`docs/90_current/90_GURU_CURRENT_STATE.md`**.

Устаревшие точки входа (**`PROJECT_CONTEXT_GURU.md`**, **`docs/GURU_CONTEXT_INDEX.md`**) из репозитория удалены — для Cursor использовать только этот файл и перечисленные ниже модули.

**Git и коммиты:** **`docs/90_current/93_GURU_GIT_COMMIT_STANDARD.md`** — в том числе обязательная проверка актуализации модульной документации перед коммитом изменений в коде; в Cursor то же задаётся правилом `.cursor/rules/guru-git-commit-standard.mdc`.

| Папка под `docs/` | Содержание | Как часто меняется |
|-------------------|------------|---------------------|
| **`00_core/`** | Постулаты, стандарты архитектуры, воркспейсы, домен | Редко |
| **`10_operations/`** | Общие правила операций, TRANSFER, INCOME, REPORT (черновик) | При смене бизнес-логики операций |
| **`20_api/`** | Маршруты, контракт ответа API | При добавлении/смене маршрутов |
| **`30_flutter/`** | Архитектура клиента, UI, экраны | При развитии UI |
| **`90_current/`** | Текущий снимок, шаблон задачи, smoke checklist, стандарт Git | Постоянно / операционные редко |

Дефолтный «широкий» минимум без выбора сценария:

```text
docs/00_core/00_GURU_CORE_PRINCIPLES.md
docs/00_core/02_GURU_WORKSPACES_AND_ACCESS.md
docs/90_current/90_GURU_CURRENT_STATE.md
```

**Инвариант (одна строка):** два API-контура — `**/api/company-workspace/{companyId}/**` и `**/api/personal-workspace/**`; кошелёк у **`ProjectParticipant`**; объединённая история на клиенте — **`GET …/operations/history`** (TRANSFER + INCOME).

**Архив:** `docs/OldDocs/` (в т.ч. `docs/OldDocs/legacy_monolith/`) — не канон без явного запроса.

### Операционные документы (регрессия и Git)

Имеет смысл держать под рукой при релизах и при работе с Git:

```text
docs/90_current/92_GURU_SMOKE_CHECKLIST.md
docs/90_current/93_GURU_GIT_COMMIT_STANDARD.md
```

- `docs/90_current/91_GURU_NEXT_TASK_REPORT.md` — краткий контекст для нового Cursor-чата по ТЗ-10 «Отчёт» / REPORT.

Стандарт безопасных коммитов подробно описан в **`docs/90_current/93_GURU_GIT_COMMIT_STANDARD.md`**; в Cursor он усиливается правилом **`.cursor/rules/guru-git-commit-standard.mdc`** (`alwaysApply: true`).

---

## Зачем разбили документы

Раньше каноном были большие файлы с теми же именами; они перенесены в **`docs/OldDocs/legacy_monolith/`** и заменены модульными файлами ниже — так проще прикладывать в Cursor только нужное.

Теперь документация разделена на маленькие тематические файлы:

- стабильные постулаты;
- архитектура;
- доступы;
- доменная модель;
- операции;
- API;
- Flutter;
- текущий статус;
- текущая задача.

## Как использовать

В Cursor не нужно каждый раз прикладывать все файлы.

Для каждой задачи выбирай только нужный набор:

### Backend по операции

```text
00_core/00_GURU_CORE_PRINCIPLES.md
00_core/01_GURU_ARCHITECTURE_STANDARDS.md
00_core/02_GURU_WORKSPACES_AND_ACCESS.md
10_operations/10_OPERATION_COMMON_RULES.md
10_operations/нужная операция
20_api/20_API_ROUTES_CURRENT.md
90_current/91_GURU_NEXT_TASK_TEMPLATE.md
```

### Flutter UI

```text
00_core/00_GURU_CORE_PRINCIPLES.md
30_flutter/30_FLUTTER_ARCHITECTURE.md
30_flutter/31_FLUTTER_UI_STANDARDS.md
30_flutter/32_FLUTTER_SCREENS_CURRENT.md
90_current/91_GURU_NEXT_TASK_TEMPLATE.md
```

### Доступы / безопасность

```text
00_core/00_GURU_CORE_PRINCIPLES.md
00_core/02_GURU_WORKSPACES_AND_ACCESS.md
00_core/03_GURU_DOMAIN_MODEL.md
20_api/20_API_ROUTES_CURRENT.md
90_current/91_GURU_NEXT_TASK_TEMPLATE.md
```

### Новая операция

```text
00_core/00_GURU_CORE_PRINCIPLES.md
00_core/01_GURU_ARCHITECTURE_STANDARDS.md
00_core/02_GURU_WORKSPACES_AND_ACCESS.md
00_core/03_GURU_DOMAIN_MODEL.md
10_operations/10_OPERATION_COMMON_RULES.md
10_operations/11_OPERATION_TRANSFER.md
10_operations/12_OPERATION_INCOME.md
10_operations/13_OPERATION_REPORT_DRAFT.md
90_current/91_GURU_NEXT_TASK_TEMPLATE.md
```

## Что менять часто

Часто меняются:

```text
20_api/20_API_ROUTES_CURRENT.md
30_flutter/32_FLUTTER_SCREENS_CURRENT.md
90_current/90_GURU_CURRENT_STATE.md
90_current/91_GURU_NEXT_TASK_TEMPLATE.md
90_current/92_GURU_SMOKE_CHECKLIST.md
```

## Что менять редко

Редко меняются:

```text
90_current/93_GURU_GIT_COMMIT_STANDARD.md
00_core/00_GURU_CORE_PRINCIPLES.md
00_core/01_GURU_ARCHITECTURE_STANDARDS.md
00_core/02_GURU_WORKSPACES_AND_ACCESS.md
00_core/03_GURU_DOMAIN_MODEL.md
20_api/21_API_RESPONSE_CONTRACT.md
30_flutter/31_FLUTTER_UI_STANDARDS.md
```

## Старые большие документы

Копии прежних монолитов лежат в **`docs/OldDocs/legacy_monolith/`** — только для сверки или восстановления контекста, не для ежедневного attach в Cursor.
