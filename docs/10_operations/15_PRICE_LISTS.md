# 15 — Прайс-листы компании и прикрепление к проекту (ТЗ-10B)

Канон по реализованному этапу **ТЗ-10B**. Операция **REPORT** и финансовые дельты отчёта **не** входят в этот документ.

---

## 1. Статус

```text
ТЗ-10B реализовано в backend и Flutter (company workspace).
REPORT / snapshot строк отчёта / кастомные позиции отчёта — не реализованы.
Проверка «использовано в отчётах» для hard/soft delete: класс PriceListReportUsageChecker
подключён в PriceListDeletionService, но до появления REPORT всегда возвращает false
(прайс физически не мог попасть в отчёт) — см. комментарии и TODO в коде checker.
После REPORT checker обязан быть доработан (price_list_id, group/position id, snapshot items),
иначе историчность удаления будет нарушена.
```

---

## 2. Модель данных (кратко)

```text
units — системные единицы (MVP: company_id = null, is_system = true)
price_lists — библиотека компании; created_by_user_id, created_by_counterparty_id
price_list_groups — разделы внутри прайса
price_list_positions — позиции; БЕЗ expense_item_id; unit_id; цены decimal(15,2)
project_price_lists — связь проект ↔ прайс; unique(project_id, price_list_id)
```

---

## 3. Права

```text
OWNER — полный CRUD по всем прайсам компании; прикрепление любых активных прайсов к проектам; открепление любых.
PARTNER, являющийся PROJECT_HEAD (first-order) хотя бы в одном проекте компании — один активный собственный прайс-лист на компанию; редактирование/удаление только своего; в проектах, где он HEAD — прикрепление только своего прайса; открепление только своего.
PARTNER без роли PROJECT_HEAD — не создаёт прайс (403); в библиотеке видит пустой список чужих прайсов; GET детали чужого прайса по прямой ссылке — 403, кроме случаев чтения через участие (см. сервис доступа).
Просмотр чужого прайса, прикреплённого к проекту где пользователь PROJECT_HEAD — разрешён (read-only); редактирование чужого — запрещено.
```

Флаги UI:

```text
GET …/context → data.price_lists (создание в библиотеке, причина блокировки, active_own_price_list_id)
GET …/projects/{id}/summary → visibility.can_view_project_price_lists, can_manage_project_price_list_attachments
```

---

## 4. Инварианты

```text
Позиция прайс-листа не содержит expense_item_id.
Статья расходов (ТЗ-10A) и позиции прайса объединяются только в будущем REPORT.
Прайс-лист не является финансовой операцией.
```

---

## 5. API

Полный перечень путей — **`docs/20_api/20_API_ROUTES_CURRENT.md`** (секция *Price lists*).

Поиск и пагинация: query `search`, `page`, `per_page` на списках прайсов, групп и позиций.

---

## 6. Удаление и историчность

```text
PriceListDeletionService: при «использовано в отчётах» (через PriceListReportUsageChecker) — soft-delete дерева; иначе hard-delete price_list (открепление project_price_lists в той же транзакции).
До REPORT checker намеренно всегда false — см. §1 и комментарии в коде; после REPORT без доработки checker историчность будет нарушена.
Позиция/группа: через тот же checker на уровне позиции; группа учитывает дочерние позиции при решении soft vs hard.
Перед удалением прайс-листа строки project_price_lists удаляются; ответ DELETE содержит detached_projects_count.
```

---

## 7. Flutter

Экраны и навигация — **`docs/30_flutter/32_FLUTTER_SCREENS_CURRENT.md`**.

---

## 8. Связанные документы

```text
docs/10_operations/14_PROJECT_EXPENSE_ITEMS.md — статьи расходов (ТЗ-10A)
docs/10_operations/13_OPERATION_REPORT_DRAFT.md — направление REPORT
```
