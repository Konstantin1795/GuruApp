# GURU — индекс документации (минимум для контекста)

**Репозиторий:** GuruApp — `backend/` (Laravel API), `mobile_app/` (Flutter).  
**Стек:** PHP 8.3 / Laravel 13 / Sanctum / PostgreSQL; Flutter / Riverpod / go_router / Dio.

## Канонические файлы (четыре)

| Файл | Когда открывать |
|------|-----------------|
| **`docs/GURU_PROJECT_CONTEXT.md`** | Полный короткий handoff: продукт, маршруты, сервисы, Flutter, команды |
| **`docs/GURU_ARCHITECTURE_AND_STANDARDS.md`** | Модули, **§6 маршруты**, доменная модель, JSON-контракт, стандарты |
| **`docs/GURU_FULL_PROJECT_BLUEPRINT.md`** | Глубокий blueprint, постулаты, UI, сценарии «с нуля» |
| **`docs/GURU_OPERATIONS_REFERENCE.md`** | **TRANSFER** и **INCOME**: эндпойнты, кошельки, lifecycle (`#transfer` / `#income`) |

## Не тратить контекст

- **`docs/OldDocs/`** — архив; не использовать как источник истины, пока явно не попросили.
- Не дублировать в чат длинные куски blueprint: лучше сослаться на § или файл.

## Инварианты на одну строку

Два API-контура: **`/api/company-workspace/{companyId}`** (OWNER/PARTNER) и **`/api/personal-workspace`** (личные роли). Кошелёк — у **`ProjectParticipant`**, не у пользователя напрямую.
