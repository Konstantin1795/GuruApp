# 91 — GURU Next Task Template / Шаблон текущей задачи для Cursor

Этот файл нужно копировать и заполнять под конкретную задачу.  
Он меняется постоянно.

---

## 1. Название задачи

```text
<Например: Реализовать Report foundation>
```

---

## 2. Цель

```text
<Кратко: что должно заработать по итогам задачи>
```

---

## 3. Контекст

```text
<Что уже реализовано и на что опираемся>
```

---

## 4. Работать только с файлами / модулями

```text
backend/app/Modules/...
mobile_app/lib/features/...
docs/...
```

---

## 5. Не трогать

```text
Transfer lifecycle
Income lifecycle
Auth
Workspace access
Wallet math
API response contract
```

---

## 6. Обязательные документы для контекста

```text
00_core/00_GURU_CORE_PRINCIPLES.md
00_core/01_GURU_ARCHITECTURE_STANDARDS.md
...
```

---

## 7. Требования backend

```text
<эндпойнты>
<сервисы>
<миграции>
<ресурсы>
<валидации>
<права доступа>
```

---

## 8. Требования Flutter

```text
<экраны>
<providers>
<repository>
<l10n>
<UI states>
```

---

## 9. Проверки

Backend:

```cmd
php artisan route:list
php artisan schedule:list
php artisan test
```

Flutter:

```cmd
flutter gen-l10n
flutter analyze
```

Ручные сценарии:

```text
1.
2.
3.
```

---

## 10. Критерии готовности

```text
- работает основной сценарий
- нет регрессии
- права доступа сохранены
- flutter analyze без ошибок
- route:list показывает новые маршруты
- документация обновлена
```

---

## 11. Что Cursor должен показать в отчёте

```text
1. какие файлы изменены
2. какие endpoints добавлены
3. какие сервисы добавлены
4. какие проверки выполнены
5. что осталось долгом
```
