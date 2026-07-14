# Forgein Roadmap

This file covers what's shipped, what's in progress, and what's coming. It's updated with each release. For the full changelog, see [forgein.ai/changelog](https://forgein.ai/changelog).

---

## Shipped

### CLI + Skills
- [x] `/forgein mem` — memory list, search, add, prune, audit
- [x] `/forgein mem delete` — delete a synced memory file from cloud
- [x] `/forgein sec` — heuristic security scan on staged diffs (8 vulnerability classes)
- [x] `/forgein optimize` — word-boundary skill scoring + interactive install
- [x] `/forgein auth` — device-code flow (open URL, approve in browser) or paste-to-chat fallback
- [x] `/forgein mem sync` — push/pull memory files to cloud; walk-up loop path resolution for all project structures
- [x] `/forgein export <target>` — write context into any tool's native format
- [x] `FORGEIN_NO_TELEMETRY=1` — suppress adapter telemetry from all CLI requests

### Adapters (all free)
- [x] Claude Code — context served via `/forgein mem sync`; no background hooks or auto-injection
- [x] MCP Server — JSON-RPC 2.0, stateless HTTP, auto-discovery at `/.well-known/mcp`
- [x] Cursor — writes `.cursorrules`
- [x] Windsurf — writes `.windsurfrules`
- [x] GitHub Copilot — writes `.github/copilot-instructions.md`
- [x] ChatGPT — formats Custom Instructions (two-field)
- [x] Gemini — formats Gems system prompt

### Platform
- [x] Work / Home / Family contexts — memory that doesn't cross between work and personal sessions
- [x] Team memory sharing — org members share a common project memory
- [x] Org baseline templates — admin sets base context that all members inherit
- [x] Webhooks — event delivery for memory syncs, with retry queue
- [x] AI adoption analytics — per-member usage breakdown across all AI tools, audit log
- [x] `@forgein/adapter-sdk` on npm — build your own adapter or integration
- [x] Context inheritance — adapter output layers org baseline → team → project → personal
- [x] Org context templates — admin CRUD dashboard for managing the org baseline context layer
- [x] Browser extension — Chrome MV3, auto-injects context into ChatGPT and Gemini on click
- [x] Installer audit trail — `/cli/install` issues a 302 redirect to the GitHub raw URL; deployed = source, structurally auditable
- [x] SHA-256 release checksums — `CHECKSUMS.txt` in repo with `sha256` hashes for `install.sh` and `skills/forgein.md` per release
- [x] Database row-level security — Postgres RLS on `memory_files`, `adapter_usage`, `memory_file_history`; tenant isolation enforced at DB layer (migration 0015)
- [x] Telemetry opt-out — API respects `X-No-Telemetry: 1` header; no `adapter_usage` row recorded when opted out
- [x] Privacy policy — field-by-field disclosure of adapter telemetry at `/privacy`; opt-out instructions included

### Skills in the registry (10)
`/forgein`, `/sec`, `/mem`, `/review`, `/commit`, `/standup`, `/pr-monitor`, `/test-gen`, `/explain`, `/changelog`

---

## In progress

- [ ] **Public GitHub Projects board** — mirror of this file with community-voted priorities.

---

## Planned

### Near-term (next 60 days)
- [x] **Browser extension** — Chrome MV3 extension with floating button on chatgpt.com and gemini.google.com; injects your context on click
- [x] **Policy / constraint layer** — org owners set block rules (redact regex matches) and require rules (prepend text) that apply to every member's adapter output
- [x] **Context versioning** — full version history on org templates; diff viewer (LCS line diff); rollback to any prior version
- [x] **Compliance export** — audit CSV of all `adapter_usage` + org policy change events; downloadable from admin analytics
- [x] **SAML / SSO** — SP-initiated SAML 2.0; per-org config; auto-provision; optional enforcement (blocks password login for org members)
- [ ] **VS Code / JetBrains adapter** — native IDE context injection without the CLI

### Longer-term
- [ ] **Context pipeline API** — pipe internal docs, runbooks, Linear tickets into forgein automatically
- [ ] **Confluence / Notion / Linear integration** — pull current project state, keep context fresh without manual sync
- [ ] **Context health monitoring** — detect stale or policy-violating org context, alert the platform admin
- [ ] **Template marketplace** — publish and discover org-level context templates

---

## How to contribute

**Submit a skill:** add your `.md` to `skills/`, add an entry to `registry.json`, open a PR. See [README.md](README.md) for the file format and signal guidelines.

**Propose a feature:** open a GitHub Discussion in this repo. Accepted proposals move to "In progress" here.

**Build an adapter:** `npm install @forgein/adapter-sdk` and follow the [adapter SDK docs](https://forgein.ai/docs/api).

---

## What won't be here

Features that are org-internal, compliance-sensitive (exact SSO implementation details), or that haven't been committed to a timeline. This roadmap is honest about what's speculative.
