---
description: Forgein — Claude productivity toolkit. Subcommands: optimize (discover and install skills), mem (manage memory), sec (security check).
---

Parse `$ARGUMENTS` — first word is the subcommand. Route to the correct section. If no argument or unrecognized: print usage table.

**Usage:**
| Command | Description |
|---------|-------------|
| `/forgein optimize` | Discover Claude skills that fit your workflow and install them |
| `/forgein mem [list\|search\|add\|prune\|audit]` | Manage Claude's memory system |
| `/forgein sec [path]` | Security vibe check on staged changes or a path |

---

## optimize

Discover and install Claude skills from the Forgein registry tailored to your workflow.

**Steps:**

1. Fetch the registry — try in order until one succeeds:
   - `gh api repos/shadowmodder/forgein/contents/registry.json --jq '.content' | base64 -d` (reliable, uses gh auth)
   - WebFetch `https://raw.githubusercontent.com/shadowmodder/forgein/main/registry.json`

2. Run `ls ~/.claude/commands/ 2>/dev/null` via Bash — these are already-installed skills (strip `.md` extension)

3. Gather context signals via Bash:
   ```
   cat ~/.claude/CLAUDE.md 2>/dev/null
   cat CLAUDE.md 2>/dev/null
   find ~/.claude/projects -name "MEMORY.md" 2>/dev/null | head -3 | xargs cat 2>/dev/null
   git log --oneline -20 2>/dev/null
   ```

4. Build a single context string from all of step 3. Score each registry skill: count how many of its `signals` and `tags` appear in the context string (case-insensitive). Exclude already-installed skills.

5. Sort remaining skills by score descending. Present the top 5 as:

   ```
   Recommended skills for your workflow:

   #  Skill          What it does                        Why it fits you
   1  code-review    Multi-dimensional diff review       You have open PRs being reviewed
   2  commit         Smart conventional commit messages  You commit frequently
   ...
   ```

   "Why it fits you" must name the specific signal that triggered the match.

6. Ask: **"Which would you like to install? Enter numbers (e.g. 1,3), 'all', or 'none':"**

7. For each selected skill: fetch the file content with `gh api repos/shadowmodder/forgein/contents/<file> --jq '.content' | base64 -d` and Write it to `~/.claude/commands/<command>.md`

8. Confirm: "✓ Installed: X, Y. Type /<command> to start using each."

If the context is empty (no CLAUDE.md, no memory, no git): skip scoring and recommend the 5 most broadly useful skills by download rank in the registry.

---

## mem

Manage Claude's auto-memory system. Parse the next word as the mem subcommand. Default (no subcommand): `list`.

**Find memory location first:**
```bash
find ~/.claude/projects -name "MEMORY.md" 2>/dev/null | head -1
```
If no result: tell the user memory isn't set up, and point them to the Claude Code auto-memory docs.

---

### mem list

Read MEMORY.md. Display all entries grouped by type (user → feedback → project → reference):

```
MEMORY — 12 entries

USER (2)
  • user-profile.md — Who Sudhir is, working style, preferences
  • user-expertise.md — Deep ML background, new to frontend

FEEDBACK (4)
  • feedback-commits.md — Commit message rules for this project
  ...
```

Include total count and last-modified date of MEMORY.md.

---

### mem search <query>

Read MEMORY.md to get all linked filenames. Read each linked file. Return entries where the body contains the query (case-insensitive). Output:

```
Found 2 matches for "commit":

[feedback-commits.md] feedback
  "Commit messages must not mention Claude or AI..."

[feedback-working-style.md] feedback
  "...post without asking, commit autonomously..."
```

---

### mem add <type> <content>

Valid types: `user`, `feedback`, `project`, `reference`.

Generate a kebab-case slug from the content summary. Write a new memory file with frontmatter:

```markdown
---
name: <slug>
description: <one-line summary>
metadata:
  type: <type>
---

<content>
```

Append to MEMORY.md: `- [Title](file.md) — one-line hook`

Confirm: "✓ Saved as <slug>.md and added to index."

---

### mem prune

Read all files linked from MEMORY.md. For each one: check if file paths, function names, URLs, or repo references it mentions still resolve (use Bash/Read to verify). Flag entries where referenced artifacts no longer exist or the facts are clearly stale (e.g., references a PR that's now merged and closed).

Show flagged entries one at a time and ask: "Delete this memory? (y/n)"

On 'y': delete the file and remove the line from MEMORY.md.

---

### mem audit

Check for and report:
- Duplicate slugs in MEMORY.md
- Lines in MEMORY.md that link to non-existent files
- Memory files with empty body
- MEMORY.md lines over 150 characters
- Memory files missing required frontmatter fields (name, description, metadata.type)

For each issue: print the problem and offer to auto-fix it.

---

## sec

Security vibe check. Parse the second argument:
- No argument or `staged`: run `git diff --staged` and scan the output
- A file or directory path: read that path

For each finding record: **severity** (critical / medium / low), **location** (file:line), **class**, **snippet** (≤ 80 chars), **attack scenario** (1 sentence).

---

**Vulnerability classes to check:**

| Class | What to look for |
|-------|-----------------|
| Secrets | String literals in variables named `key`, `secret`, `password`, `token`, `api_key`, `auth` — long alphanumeric, base64-looking, or prefixed (sk-, ghp-, xox-) |
| SQL injection | User input concatenated into SQL via f-string, `.format()`, or `+` |
| Command injection | User input in `subprocess`, `os.system`, `exec`, `eval`, or `shell=True` |
| Path traversal | User-controlled strings in `open()`, `os.path.join`, file reads without `realpath` normalization |
| XSS | User input in `innerHTML`, `dangerouslySetInnerHTML`, unescaped template output |
| Insecure deserialization | `pickle.loads`, `yaml.load` (not `safe_load`), `eval()` on external data |
| SSRF | User-controlled URLs passed to `requests`, `httpx`, `fetch`, `urllib` without allowlist validation |
| Hardcoded credentials | Literal passwords or tokens in config files, source code, or test fixtures |

---

**Output format:**

If findings:
```
SECURITY FINDINGS — 2 critical, 1 medium, 0 low

CRITICAL  auth/login.py:47   Command injection
  snippet: f"convert {user_filename} output.png"
  risk: attacker passes "x; rm -rf /" as filename

MEDIUM    config/settings.py:12   Hardcoded secret
  snippet: API_KEY = "sk-proj-abc123..."
  risk: key exposed if repo is public or leaked in logs
```

Then: `Summary: X critical, Y medium, Z low.`

If no findings: `✓ Clean — no issues found in the scanned code.`

Always append: `Note: heuristic check only — run a dedicated SAST tool (Semgrep, Bandit, CodeQL) before shipping to production.`
