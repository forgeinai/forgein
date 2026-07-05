---
description: Onboards a new contributor to a codebase. Maps architecture, entry points, data flow, and key abstractions from a fresh read of the repo.
---

Generate a codebase orientation for `$ARGUMENTS` (a path, repo name, or empty for the current directory).

Target audience: a competent engineer who is new to *this* codebase. Skip obvious things, explain what's non-obvious.

**Steps:**

1. Read the project root: `ls -la`, `cat README.md 2>/dev/null`, `cat pyproject.toml package.json go.mod Cargo.toml 2>/dev/null | head -30`

2. Map the directory structure — identify what each top-level directory does. Only go 2 levels deep.

3. Find entry points:
   - Web app: routes file, main app file, wsgi/asgi config
   - CLI: `__main__.py`, `main.go`, `bin/` scripts
   - Library: `__init__.py` exports, public API surface

4. Trace one key data flow end-to-end (e.g. an HTTP request, a CLI command, a job). Read the relevant files.

5. Identify the 5-10 most important abstractions (classes, functions, modules) that a new contributor must understand. For each: name, what it does, where it lives.

6. Note anything non-obvious: unusual patterns, important conventions, things that will bite you if you don't know them.

**Output format:**

```
CODEBASE ORIENTATION — <repo name>

Stack: Python 3.12, FastAPI, PostgreSQL, Redis, Celery

Directory map:
  src/api/        HTTP handlers and routing
  src/models/     SQLAlchemy ORM models
  src/services/   Business logic (no HTTP/DB imports)
  src/workers/    Celery background tasks
  tests/          pytest — run with `make test`

Entry points:
  src/api/main.py    FastAPI app, mounts all routers
  src/workers/app.py Celery app, auto-discovers task modules

Key request flow (POST /orders):
  api/routes/orders.py → services/order_service.py → models/order.py + workers/fulfillment.py

Key abstractions:
  1. OrderService (services/order_service.py) — all order business logic lives here
  2. BaseModel (models/base.py) — adds created_at/updated_at/soft_delete to every model
  ...

Non-obvious things:
  • All DB writes go through services/, never directly in handlers
  • Redis is used for both caching AND as Celery broker — same connection pool
  • tests/ mirrors src/ structure exactly — add your test next to the thing you're testing
```
