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

### Projects

```http
GET  /projects
POST /projects
```

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
