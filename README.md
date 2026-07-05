# Forgein

**Claude productivity toolkit.** One command. Three superpowers.

→ [forgein.ai](https://forgein.ai)

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/shadowmodder/forgein/main/install.sh | bash
```

One file drops into `~/.claude/commands/forgein.md`. That's it.

---

## Commands

### `/forgein optimize`
Scans your CLAUDE.md, memory, and git history to find Claude skills from the registry that fit your actual workflow. Recommends and installs them interactively.

```
Recommended skills for your workflow:

#  Skill        What it does                         Why it fits you
1  code-review  Multi-dimensional diff review        You have open PRs being reviewed
2  standup      Daily standup from git log           You commit daily across multiple repos
3  test-gen     Generate tests for any function      You work in Python with pytest

Which would you like to install? (1,2 / all / none)
```

### `/forgein mem`
Full CRUD for Claude's auto-memory system.

```
/forgein mem              — list all memories by type
/forgein mem search auth  — find memories about auth
/forgein mem add feedback "always use ruff==0.15.3 for this project"
/forgein mem prune        — find and remove stale entries
/forgein mem audit        — check for broken links and duplicates
```

### `/forgein sec [path]`
Security vibe check on staged changes or any path. Catches secrets, injection, path traversal, XSS, SSRF, and insecure deserialization.

```
/forgein sec           — check staged changes
/forgein sec src/auth  — check a specific directory
```

---

## Skills registry

The registry lives in [`registry.json`](registry.json). Each skill is a `.md` file in [`skills/`](skills/).

**Current skills (10):**

| Skill | Command | Description |
|-------|---------|-------------|
| Forgein | `/forgein` | This toolkit |
| Vibe Sec | `/sec` | Security check on staged changes or any path |
| Claude Mem | `/mem` | Memory CRUD |
| Code Review | `/review` | Multi-dimensional diff review |
| Smart Commit | `/commit` | Conventional commit message generator |
| Standup | `/standup` | Daily standup from git log + PRs |
| PR Monitor | `/pr-monitor` | CI status across all open PRs |
| Test Gen | `/test-gen` | Generate tests for any function/file |
| Explain Codebase | `/explain` | Onboard to any codebase fast |
| Changelog | `/changelog` | Generate CHANGELOG from git log |

### Install individual skills

```bash
# Install just the security checker
curl -fsSL https://raw.githubusercontent.com/shadowmodder/forgein/main/skills/vibe-sec.md \
  -o ~/.claude/commands/sec.md
```

### Submit a skill

Open a PR adding your `.md` file to `skills/` and an entry to `registry.json`.

---

## How skills work

Claude Code skills are markdown files in `~/.claude/commands/`. When you type `/forgein`, Claude reads `forgein.md` and follows its instructions — using your local tools, files, and APIs. No server. No telemetry. Everything runs locally in your Claude session.

---

## License

MIT — [forgein.ai](https://forgein.ai)
