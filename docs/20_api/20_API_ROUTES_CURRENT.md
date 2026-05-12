# 20 — Current API Routes / Актуальные маршруты API

Файл часто меняется.  
Обновлять после добавления маршрутов.

---

## 1. Auth

```http
POST /api/auth/register
POST /api/auth/token
GET  /api/auth/me
POST /api/auth/logout
```

---

## 2. Workspaces

```http
GET /api/workspaces
```

---

## 3. Company Workspace

Префикс:

```http
/api/company-workspace/{companyId}
```

### Context

```http
GET /context
GET /companies/current
```

Ответ **`GET /context`**: помимо `active_company_id`, `company_role`, `company` — объект **`price_lists`**: `can_view_company_price_list_library`, `can_create_company_price_list`, `company_price_list_create_blocked_reason` (`partner_not_project_head` | `partner_already_has_active_list` | `null`), `active_own_price_list_id`.

### Projects

```http
GET  /projects
POST /projects
GET  /projects/{projectId}/summary
GET  /projects/{projectId}/internal-metrics

GET    /projects/{projectId}/expense-items/recipients?search=
GET    /projects/{projectId}/expense-items
POST   /projects/{projectId}/expense-items
GET    /projects/{projectId}/expense-items/{expenseItemId}
PATCH  /projects/{projectId}/expense-items/{expenseItemId}
DELETE /projects/{projectId}/expense-items/{expenseItemId}
```

Блок **ТЗ-10A** (статьи расходов): реализовано; ответ `…/recipients` — только контрагенты компании (`source` в JSON ответа — `company_counterparties`). Детали — **`docs/10_operations/14_PROJECT_EXPENSE_ITEMS.md`**.

`expenseItemId` — только числовой сегмент; маршрут `…/recipients` объявлен выше параметрического `…/{expenseItemId}`.

### Price lists (ТЗ-10B)

```http
GET    /units
GET    /price-lists?search=&page=&per_page=
POST   /price-lists
GET    /price-lists/{priceListId}
PATCH  /price-lists/{priceListId}
DELETE /price-lists/{priceListId}

GET    /price-lists/{priceListId}/groups?search=&page=&per_page=
POST   /price-lists/{priceListId}/groups
PATCH  /price-lists/{priceListId}/groups/{groupId}
DELETE /price-lists/{priceListId}/groups/{groupId}

GET    /price-lists/{priceListId}/groups/{groupId}/positions?search=&page=&per_page=
POST   /price-lists/{priceListId}/groups/{groupId}/positions
PATCH  /price-lists/{priceListId}/groups/{groupId}/positions/{positionId}
DELETE /price-lists/{priceListId}/groups/{groupId}/positions/{positionId}

GET    /projects/{projectId}/price-lists/available
GET    /projects/{projectId}/price-lists
POST   /projects/{projectId}/price-lists/attach
DELETE /projects/{projectId}/price-lists/{priceListId}
```

Канон по домену и правам — **`docs/10_operations/15_PRICE_LISTS.md`**.  
`GET /context` дополняется блоком `price_lists` (флаги библиотеки компании для UI).  
`GET …/summary` → `visibility` дополняется `can_view_project_price_lists`, `can_manage_project_price_list_attachments`.

### Counterparties

```http
GET  /counterparties
POST /counterparties
```

### Participants

```http
GET    /projects/{projectId}/participants
POST   /projects/{projectId}/participants
PATCH  /projects/{projectId}/participants/{participantId}
DELETE /projects/{projectId}/participants/{participantId}
GET    /projects/{projectId}/participants/{participantId}/wallet
```

---

## 4. Company Workspace — unified operations

```http
GET /operations/history
```

Назначение:

```text
объединённая история TRANSFER + INCOME
```

---

## 5. Company Workspace — transfers

```http
GET /operations/transfers/history
GET /operations/transfers/pending-count

GET  /projects/{projectId}/operations/transfers/recipients
GET  /projects/{projectId}/operations/transfers
POST /projects/{projectId}/operations/transfers
GET  /projects/{projectId}/operations/transfers/{transferId}
```

Lifecycle actions:

```http
POST /projects/{projectId}/operations/transfers/{transferId}/approve-project-head
POST /projects/{projectId}/operations/transfers/{transferId}/reject-project-head
POST /projects/{projectId}/operations/transfers/{transferId}/reset-approval
POST /projects/{projectId}/operations/transfers/{transferId}/submit-for-approval
POST /projects/{projectId}/operations/transfers/{transferId}/complete-immediate
POST /projects/{projectId}/operations/transfers/{transferId}/return-to-created
POST /projects/{projectId}/operations/transfers/{transferId}/return-to-project-head-approval
POST /projects/{projectId}/operations/transfers/{transferId}/complete-waiting
POST /projects/{projectId}/operations/transfers/{transferId}/rollback-completed
POST /projects/{projectId}/operations/transfers/{transferId}/return-completed-to-project-head-approval
```

---

## 6. Company Workspace — incomes

```http
GET /operations/incomes/history
GET /operations/incomes/pending-count

GET   /projects/{projectId}/operations/incomes
POST  /projects/{projectId}/operations/incomes
GET   /projects/{projectId}/operations/incomes/{incomeId}
PATCH /projects/{projectId}/operations/incomes/{incomeId}
```

Lifecycle actions:

```http
POST /projects/{projectId}/operations/incomes/{incomeId}/submit-to-customer-approval
POST /projects/{projectId}/operations/incomes/{incomeId}/complete-waiting
POST /projects/{projectId}/operations/incomes/{incomeId}/rollback-completed
```

---

## 7. Personal Workspace

Префикс:

```http
/api/personal-workspace
```

### Context / lists

```http
GET /context
GET /companies
GET /projects
GET /projects/{projectId}/summary
GET /projects/{projectId}/internal-metrics
GET /income-by-month
```

### Unified operations

```http
GET /operations/history
```

---

## 8. Personal Workspace — transfers

```http
GET /operations/transfers/history
GET /operations/transfers/pending-count

GET  /projects/{projectId}/operations/transfers/recipients
GET  /projects/{projectId}/operations/transfers
POST /projects/{projectId}/operations/transfers
GET  /projects/{projectId}/operations/transfers/{transferId}
```

Lifecycle actions:

```http
POST /projects/{projectId}/operations/transfers/{transferId}/submit-for-approval
POST /projects/{projectId}/operations/transfers/{transferId}/reset-approval
POST /projects/{projectId}/operations/transfers/{transferId}/return-to-created
```

---

## 9. Personal Workspace — incomes

```http
GET /operations/incomes/history
GET /operations/incomes/pending-count

GET /projects/{projectId}/operations/incomes
GET /projects/{projectId}/operations/incomes/{incomeId}
```

Customer actions:

```http
POST /projects/{projectId}/operations/incomes/{incomeId}/approve-customer
POST /projects/{projectId}/operations/incomes/{incomeId}/reject-customer
POST /projects/{projectId}/operations/incomes/{incomeId}/return-to-customer-approval
```

---

## 10. Scheduler commands

```cmd
php artisan operations:complete-expired-transfer-waiting
php artisan operations:complete-expired-income-waiting
```
