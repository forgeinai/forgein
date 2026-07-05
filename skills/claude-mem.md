---
description: CRUD for Claude's auto-memory system. List, search, add, prune stale entries, and audit the memory index.
---

Manage Claude's auto-memory system. Parse `$ARGUMENTS` — first word is the subcommand. Default (no argument): `list`.

**Find memory location first:**
```bash
find ~/.claude/projects -name "MEMORY.md" 2>/dev/null | head -1
```
If no result: tell the user memory isn't configured and suggest enabling auto-memory in Claude Code settings.

---

## list

Read MEMORY.md. Display all entries grouped by type:

```
MEMORY INDEX — 12 entries  (last updated: 2026-07-05)

USER (2)
  • user-profile.md        — Who you are, working style, preferences
  • user-expertise.md      — Domain knowledge and skill levels

FEEDBACK (4)
  • feedback-commits.md    — Commit message rules for this project
  • feedback-style.md      — Response format preferences
  ...

PROJECT (3)  ...
REFERENCE (3)  ...
```

---

## search <query>

Read MEMORY.md to get all linked filenames. Read each file. Return entries where the body contains the query (case-insensitive):

```
2 matches for "commit"

[feedback-commits.md]  type: feedback
  "Commit messages must not mention Claude or AI..."

[feedback-working-style.md]  type: feedback
  "...post without asking, commit autonomously..."
```

---

## add <type> <content>

Valid types: `user`, `feedback`, `project`, `reference`.

Generate a kebab-case slug from the content. Write a new memory file:

```markdown
---
name: <slug>
description: <one-line summary>
metadata:
  type: <type>
---

<content — structured as: main fact, then **Why:** and **How to apply:** for feedback/project types>
```

Append to MEMORY.md: `- [Title](file.md) — one-line hook`

Confirm: `✓ Saved as <slug>.md and added to index.`

---

## prune

Read all files linked from MEMORY.md. For each one: check if file paths, function names, repo names, PR numbers, or URLs it mentions still exist or resolve (use Bash/Read to verify). Flag entries that reference artifacts that no longer exist, or project memories where the deadline/event has clearly passed.

Show each flagged entry and ask: **"Delete this memory? (y/n)"**

On `y`: delete the file and remove the corresponding line from MEMORY.md.

---

## audit

Check for and report each issue:
- Duplicate slugs or duplicate link lines in MEMORY.md
- Lines in MEMORY.md that link to files that don't exist
- Memory files with empty or near-empty body (< 20 chars)
- MEMORY.md lines longer than 150 characters
- Memory files missing required frontmatter fields (`name`, `description`, `metadata.type`)

For each issue: print the problem and offer to auto-fix where possible (delete broken links, truncate long lines, fill in missing frontmatter by reading the body).
