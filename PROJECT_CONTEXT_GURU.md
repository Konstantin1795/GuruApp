# GURU — Project Context (single-file handoff)

Last updated: 2026-05-08

This file is meant to be attached/shared in a new chat to restore full project context quickly.

---

## 1) Target stack and repo layout

- **Backend**: PHP **Laravel** + **PostgreSQL** + **Sanctum**
- **Mobile frontend**: **Flutter** (Android Emulator first)
- **Cursor**: development environment

Repo structure (current):

```text
C:\GuruApp\
  backend\      Laravel API
  mobile_app\   Flutter mobile application
```

Important note:
- `backend/package.json` + `backend/node_modules` exist (Laravel tooling / Vite pipeline). This is **not** a Node.js backend.

---

## 2) Core domain rules (from TZ-00 + clarifications)

### 2.1 Workspaces are split by routes + backend contours
There are **two different workspace modes**, they must not be mixed:

- **Company Workspace** (roles: `OWNER`, `PARTNER`)
  - Context: `active_company_id`, `company_role`
  - Separate API contour:
    - `/api/company-workspace/{companyId}/...`
- **Personal Workspace** (roles: `EMPLOYEE`, `CONTRACTOR`, `SUPPLIER`, `CUSTOMER`)
  - Context: `user_id`, `company_ids[]`, `project_ids[]`
  - Separate API contour:
    - `/api/personal-workspace/...`

Backend must enforce access via separate endpoints/controllers/services + access checks (not only filters).

### 2.2 Entities
- **Company** contains projects and counterparties.
- **Counterparty** = user (or invite) inside a company. Can be created **without** `user_id` (invite-first).
- **ProjectParticipant** = per-project projection of a Counterparty (can exist only with a Counterparty).
- **Dictionaries**:
  - `CompanyRole`: `OWNER`, `PARTNER`, `EMPLOYEE`, `SUPPLIER`, `CONTRACTOR`, `CUSTOMER`
  - `ProjectRole`: `PROJECT_HEAD`, `PARTNER`, `CUSTOMER`, `SUPERVISOR`, `EMPLOYEE`, `SUPPLIER`, `CONTRACTOR`

### 2.3 Finance / operations
For current stage:
- **Do NOT implement** Laravel Wallet, Income/Transfer/Report operations, financial business logic, realtime, offline sync.

---

## 3) Backend: architecture + standards

### 3.1 API response standard
All success responses use `ApiResponse::ok()`:

```json
{ "ok": true, "data": { ... }, "meta": { "request_id": "..." } }
```

Errors are rendered in a single JSON format in `bootstrap/app.php`:

```json
{ "ok": false, "error": { "message": "...", "type": "...", "fields": {...?} }, "meta": { "request_id": "..." } }
```

Request id is attached via middleware (`X-Request-Id`) and returned in:
- response header `X-Request-Id`
- `meta.request_id` for both success and error responses.

### 3.2 Middleware (workspace access)
- **Company workspace access**: only if authenticated user is an active `Counterparty` in that company with role `OWNER` or `PARTNER`.
- **Personal workspace access**: only if authenticated user has at least one active `Counterparty` role among `EMPLOYEE/CONTRACTOR/SUPPLIER/CUSTOMER`.

### 3.3 Feature-first module layout (backend)
Backend is organized under `app/Modules/*`:
- `Auth`
- `Workspaces`
- `Companies`
- `Projects`
- `Dictionaries`
- `System`

---

## 4) Backend: migrations + seeders (foundation)

### 4.1 Migrations (added)
- Role dictionaries:
  - `company_roles(code PK, description)`
  - `project_roles(code PK, description)`
- Core tables:
  - `companies`
  - `counterparties` (unique: `company_id + user_id`)
  - `projects` (with Postgres check constraint for `progress_percent` 0..100)
  - `project_participants` (unique: `project_id + counterparty_id`, `level: first|second`)

### 4.2 Seeders
Seeders exist for:
- `CompanyRoleSeeder`
- `ProjectRoleSeeder`
- `GuruDemoSeeder` (idempotent demo data)

Demo accounts (password: `password`):
- `owner@guru.local`
- `partner@guru.local`
- `employee@guru.local`

---

## 5) Backend: implemented endpoints (current)

### 5.1 System
- `GET /api/health`

### 5.2 Auth (Sanctum)
- `POST /api/auth/register` (returns `{ user, token }`)
- `POST /api/auth/token` (returns `{ user, token }`)
- `POST /api/auth/logout` (deletes **current** token only)
- `GET /api/auth/me` (returns `{ user, company_roles, available_workspaces }`)

### 5.3 Workspaces
- `GET /api/workspaces`
  - returns `company_workspaces[]` + `personal_workspace{...}`

### 5.4 Company Workspace (read-only + entry)
Entry action (not scoped by companyId):
- `POST /api/company-workspace/companies` (creates Company + Counterparty OWNER in a DB transaction)

Scoped by companyId (requires Company Workspace middleware):
- `GET /api/company-workspace/{companyId}/context`
- `GET /api/company-workspace/{companyId}/companies/current`
- `GET /api/company-workspace/{companyId}/projects` (paginated)
- `GET /api/company-workspace/{companyId}/counterparties` (paginated)

### 5.5 Personal Workspace (read-only)
Requires Personal Workspace middleware:
- `GET /api/personal-workspace/context`
- `GET /api/personal-workspace/companies` (paginated)
- `GET /api/personal-workspace/projects` (paginated)

---

## 6) Backend: run / check commands

From `C:\GuruApp\backend`:

```powershell
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Minimal PowerShell check (example):

```powershell
$base='http://127.0.0.1:8000'
Invoke-RestMethod "$base/api/health"
```

---

## 7) Flutter: architecture + current status

### 7.1 Flutter structure
Feature-first structure exists:

```text
lib/
  core/
    api/
    storage/
    routing/
    theme/
    widgets/
    constants/
  features/
    auth/
    workspaces/
    company_workspace/
    personal_workspace/
```

### 7.2 Flutter routing (go_router)
Routes (kept stable):
- `/` Splash
- `/login`
- `/register`
- `/workspaces`
- `/create-company`
- `/company/:companyId`
- `/personal`

Auth-redirect is handled by router + an auth state controller.

### 7.3 Flutter API baseUrl (Android Emulator)
Base URL is configured for Android Emulator host access:
- `http://10.0.2.2:8000/api`

Implementation:
- `lib/core/constants/app_config.dart`
- `ApiClient` prints on init:
  - `GURU API baseUrl: ...` (visible in `flutter run`)

### 7.4 Flutter bootstrap logic
Bootstrap uses secure token storage:
- if token missing -> unauthenticated -> router redirects to `/login`
- if token exists -> calls:
  - `GET /api/auth/me`
  - then `GET /api/workspaces`
  - success -> authenticated -> router redirects to `/workspaces`
  - failure -> logs error, clears token, unauthenticated -> `/login`

Debug logs (flutter run):
- `Splash bootstrap started`
- `Token exists: true/false`
- `Auth me success` / `Auth me failed`
- `Workspaces loaded`
- `Bootstrap finished (...)`

### 7.5 Flutter UI kit
Reusable widgets:
- `AppButton` (`lib/core/widgets/app_button.dart`)
- `AppInput` (`lib/core/widgets/app_input.dart`)
- `AppCard` (`lib/core/widgets/app_card.dart`)

Theme:
- dark background + neon green accent `#C3FF40`

---

## 8) Flutter: run / check commands (Pixel 8 Emulator)

From `C:\GuruApp\mobile_app`:

```powershell
flutter pub get
flutter analyze
flutter devices
flutter run -d emulator-5554 --dart-define=GURU_API_BASE_URL=http://10.0.2.2:8000/api
```

Windows note:
- Flutter may require Developer Mode (symlink support).

---

## 9) Known issue fixed recently (historical)

Infinite Splash loader was caused by router redirect allowing unauthenticated state to stay on `/`.
Redirect logic was updated to always redirect unauthenticated users to `/login` (except when already on `/login` or `/register`).

---

## 10) What is explicitly NOT implemented yet

- Laravel Wallet
- Income / Transfer / Report operations
- Any financial business logic
- WebSockets / realtime
- Offline sync
- Analytics
- Notifications

