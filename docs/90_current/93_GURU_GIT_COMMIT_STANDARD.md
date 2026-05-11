# 93 — Стандарт коммитов Git для проекта GURU

**Назначение:** единые правила, чтобы при запросах «закоммить», «сохрани версию», «запушь» изменения попадали в Git предсказуемо и без лишних файлов.

**Дублирование в Cursor:** правило с тем же смыслом — `.cursor/rules/guru-git-commit-standard.mdc` (`alwaysApply: true`).

---

## 1. Главная цель

- не затягивать в коммит лишнее;
- не терять удалённые файлы;
- не смешивать несвязанные изменения;
- перед коммитом показывать, что именно попадёт в Git;
- после коммита подтверждать результат.

---

## 2. Запрет на слепой `git add .`

Не использовать **`git add .`**, если в репозитории есть несвязанные изменения, непонятные untracked-файлы или пользователь явно не просил добавить всё.

Порядок действий:

1. audit состояния репозитория;
2. целевой staging (`git add <path>`);
3. проверка staged diff;
4. commit;
5. **push** — только если пользователь явно попросил.

---

## 3. Базовый workflow

### Шаг 1 — состояние

```cmd
cd C:\GuruApp
git status --short
git branch --show-current
```

Показать: ветку, modified / deleted / untracked.

### Шаг 2 — классификация файлов

1. относятся к текущей задаче;
2. не относятся к текущей задаче;
3. непонятно — нужно решение пользователя.

Если есть пункты 2 или 3 — остановиться и уточнить.

### Шаг 3 — что не добавлять без явного подтверждения

- `.vscode/`, `.idea/`
- `build/`, `.dart_tool/`, `node_modules/`, `vendor/`
- `.env`, `.env.*`
- `*.log`, временные файлы, архивы, скриншоты
- случайные файлы в корне
- `docs/OldDocs/` — если задача не про эту документацию

Исключение: пользователь явно указал конкретный путь.

### Шаг 4 — targeted staging

```cmd
git add path/to/file
```

Для удалений:

```cmd
git add -u path/to/deleted
```
или `git rm path`.

### Шаг 5 — проверка перед коммитом

```cmd
git status --short
git diff --cached --stat
git diff --cached --name-status
```

Если в staged есть лишнее — не коммитить.

### Шаг 6 — проверки кода

**Backend** (если менялся код backend):

```cmd
cd C:\GuruApp\backend
php artisan optimize:clear
php artisan route:list
php artisan schedule:list
php artisan test
```

**Flutter** (если менялся клиент):

```cmd
cd C:\GuruApp\mobile_app
flutter gen-l10n
flutter analyze
```

При наличии тестов: `flutter test`.

**Только документация:** проверки кода можно не запускать; обязательно посмотреть diff.

Если проверки не запускались — явно написать: **«Проверки не запускались»**. Не утверждать, что всё проверено, если команды не выполнялись.

### Шаг 7 — сообщение коммита

Формат:

```text
<type>(<scope>): <short summary>
```

**type:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `build`, `ci`, `perf`, `style`

**scope (примеры):** `operations`, `transfer`, `income`, `projects`, `metrics`, `flutter`, `backend`, `docs`, `auth`, `workspaces`, `cleanup`, `tests`

Примеры:

```text
feat(projects): add project summary and internal metrics
fix(income): show income operations in unified history
refactor(operations): rename aggregated operations history screen
test(api): add protected route regression tests
docs: update modular Guru documentation
chore(cleanup): remove stale operation history references
```

Коротко без scope:

```text
docs: update current Guru state
```

### Шаг 8 — commit и push

```cmd
git commit -m "type(scope): summary"
```

**Push** (`git push`) — только по явной просьбе (push / запушь / на GitHub и т.д.).

### Шаг 9 — отчёт после commit/push

Показать:

- ветку;
- хеш коммита;
- сообщение коммита;
- был ли push;
- какие проверки запускались;
- что осталось unstaged/untracked.

```cmd
git log -1 --oneline
git status --short
```

---

## 4. Разделение коммитов

При больших разношёрстных изменениях — предлагать несколько коммитов (backend / Flutter / docs / tests / cleanup).

Если всё относится к одной фиче — один коммит допустим.

---

## 5. Untracked

Всегда показывать untracked отдельно. Не добавлять автоматически, кроме файлов, явно созданных в рамках текущей задачи.

---

## 6. `.vscode`

Не добавлять автоматически. Только если пользователь явно решил хранить настройки IDE в репозитории.

---

## 7. Lock-файлы

Коммитить только если менялись зависимости:

- `backend/composer.json` + `backend/composer.lock`
- `mobile_app/pubspec.yaml` + `mobile_app/pubspec.lock`

Если lock изменился без смены зависимостей — выяснить причину.

---

## 8. Generated (Flutter)

Генерируемые файлы — только если они приняты в проекте (например `mobile_app/lib/l10n/gen/*`). Не коммитить `build/`, `.dart_tool/`.

---

## 9. Документация

Менять модульные файлы под `docs/` (кроме явного запроса не опираться на `docs/OldDocs/` как на канон).

---

## 10. Миграции

Не переименовывать и не удалять применённые миграции без отдельного решения. Новые миграции задачи — включать в коммит осознанно.

---

## 11. Тесты

При изменении критичной бизнес-логики предлагать тесты (Feature API, wallet, protected routes). Если тестов нет — кратко объяснить почему.

---

## 12. Cleanup / refactor

Перед коммитом: `git diff --cached --name-status`. В отчёте указать переименования, удаления и что не трогали.

---

## 13. Ответ пользователю при просьбе «закоммить»

**Всё однозначно:** перечислить файлы коммита, проверки, сообщение, затем выполнить commit.

**Есть лишнее:** показать несвязанные файлы, не делать `git add .`, предложить только целевой список, запросить подтверждение.

**Пользователь сказал «добавь всё»:** всё равно показать полный список staged перед commit.

---

## 14. Главное правило

Не делать «быстрый коммит на глаз». Лучше минута проверки staged, чем потом вычищать случайный мусор из истории.
