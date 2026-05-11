# GURU — модульная документация для Cursor

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
```

## Что менять редко

Редко меняются:

```text
00_core/00_GURU_CORE_PRINCIPLES.md
00_core/01_GURU_ARCHITECTURE_STANDARDS.md
00_core/02_GURU_WORKSPACES_AND_ACCESS.md
00_core/03_GURU_DOMAIN_MODEL.md
20_api/21_API_RESPONSE_CONTRACT.md
30_flutter/31_FLUTTER_UI_STANDARDS.md
```

## Старые большие документы

Копии прежних монолитов лежат в **`docs/OldDocs/legacy_monolith/`** — только для сверки или восстановления контекста, не для ежедневного attach в Cursor.
