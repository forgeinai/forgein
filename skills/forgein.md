---
description: Forgein — Claude productivity toolkit. Subcommands: auth (authenticate), optimize (discover and install skills), mem (manage and sync memory), sec (security check).
---

Parse `$ARGUMENTS` — first word is the subcommand. Route to the correct section. If no argument or unrecognized subcommand: print the usage table below and stop.

```
FORGEIN — Claude productivity toolkit

  /forgein auth            Authenticate CLI with your forgein account
  /forgein optimize        Discover and install skills that fit your workflow
  /forgein mem             List all memories (default)
  /forgein mem list        List memories grouped by type
  /forgein mem search <q>  Search memory bodies for a keyword
  /forgein mem add <type> <content>  Add a new memory
  /forgein mem prune       Remove stale memories interactively
  /forgein mem audit       Check index for broken links and duplicates
  /forgein mem sync        Sync memory files with forgein cloud
  /forgein mem sync --team Pull team-shared memory from your org
  /forgein sec             Security check on staged git changes
  /forgein sec <path>      Security check on a specific file or directory
```

---

## auth

Authenticate the Claude Code session with a forgein API token. The token is stored at `~/.config/forgein/token` and used for all subsequent CLI API calls.

### Algorithm

**Step 1 — Check existing token**

```bash
cat ~/.config/forgein/token 2>/dev/null
```

If a token is found, verify it:
```bash
curl -sf -H "Authorization: Bearer $(cat ~/.config/forgein/token)" https://api.forgein.ai/api/auth/user
```

- If the response is valid JSON with an `email` field: print `✓ Already authenticated as <email>` and stop.
- If the response is 401 or empty: the token is stale — proceed to re-authenticate.

**Step 2 — Guide the user to create a token**

Print exactly:
```
To authenticate the forgein CLI:

  1. Open https://app.forgein.ai/dashboard/tokens
  2. Click "New token", give it a name (e.g. "laptop-claude")
  3. Copy the full token (starts with fg_)

Paste your token:
```

Read the user's input as the token value. If it doesn't start with `fg_`, print `✗ That doesn't look like a forgein token (should start with fg_). Try again.` and re-prompt once.

**Step 3 — Verify and store**

```bash
curl -sf -H "Authorization: Bearer <token>" https://api.forgein.ai/api/auth/user
```

- On success (HTTP 200 with JSON):
  ```bash
  mkdir -p ~/.config/forgein
  echo "<token>" > ~/.config/forgein/token
  chmod 600 ~/.config/forgein/token
  ```
  Print: `✓ Authenticated as <email>. Token saved to ~/.config/forgein/token`

- On 401: print `✗ Token rejected by server — check that you copied the full token.` and stop.
- On network error: print `✗ Could not reach api.forgein.ai — check your connection.` and stop.

---

## optimize

### Algorithm

**Step 1 — Fetch public registry**

Try in order, use first that succeeds:
```bash
gh api repos/shadowmodder/forgein/contents/registry.json --jq '.content' | base64 -d
```
Fallback: WebFetch `https://raw.githubusercontent.com/shadowmodder/forgein/main/registry.json`

Parse the JSON. Extract the `skills` array.

**Step 2 — Fetch private skills (if authenticated)**

```bash
TOKEN=$(cat ~/.config/forgein/token 2>/dev/null)
```

If `TOKEN` is non-empty:
```bash
curl -sf -H "Authorization: Bearer $TOKEN" https://api.forgein.ai/api/skills/private
```

Parse the JSON array. Each private skill has: `id`, `command`, `name`, `description`, `tags`, `signals`. Merge these into the skills list, marking them as `source: "private"`. Private skills always rank higher than public ones with the same score.

**Step 3 — Inventory installed skills**

```bash
ls ~/.claude/commands/ 2>/dev/null
```

Strip `.md` extensions. Store as a set of installed command names. Exclude these from recommendations.

**Step 4 — Gather context signals**

Run all four in one Bash call:
```bash
cat ~/.claude/CLAUDE.md 2>/dev/null
cat CLAUDE.md 2>/dev/null
find ~/.claude/projects -name "MEMORY.md" 2>/dev/null | head -3 | xargs cat 2>/dev/null
git log --oneline -20 2>/dev/null
```

Concatenate all output into one context string.

**Step 5 — Score skills (word-boundary matching)**

For each skill not already installed, compute:

```
score = 0
for term in (skill.signals + skill.tags):
    if whole-word match of term in context (case-insensitive):
        score += 1
```

A **whole-word match** means the term is surrounded by word boundaries — spaces, punctuation, newlines, or string start/end. The term `"pr"` must NOT match inside `"sprint"` or `"improve"`. Use this test: the character before and after the match (if it exists) must be non-alphanumeric.

If context is empty (no CLAUDE.md, no memory, no git log): assign all skills a score of 0 and rank by registry order.

**Step 6 — Present top 5**

Sort non-installed skills by score descending, private skills first on tie. Take top 5. Display:

```
RECOMMENDED SKILLS FOR YOUR WORKFLOW

#  Skill        Score  Source   What it does                        Why it fits you
1  deploy         8    private  Deploy to staging with one command  Matched: "deploy", "staging", "k8s"
2  pr-monitor     6    public   CI status across all open PRs       Matched: "open prs", "github actions", "ci"
3  code-review    4    public   Multi-dimensional diff review       Matched: "pull request", "review", "pr"
4  commit         3    public   Smart conventional commit messages  Matched: "commits", "git"
5  vibe-sec       2    public   Security check on staged changes    Matched: "security", "auth"
```

Show the matched terms in "Why it fits you" — be specific.

**Step 7 — Install**

Ask: **"Install all 5? [Enter = yes / numbers e.g. 1,3 / none]:"**

Default (Enter with no input) = install all recommendations.

For each selected skill:
- Public skills: fetch from GitHub and write to `~/.claude/commands/<install_as>`
  ```bash
  gh api repos/shadowmodder/forgein/contents/<file> --jq '.content' | base64 -d
  ```
- Private skills: fetch content from API
  ```bash
  curl -sf -H "Authorization: Bearer $TOKEN" https://api.forgein.ai/api/skills/<id>
  ```
  Parse the `content` field and write to `~/.claude/commands/<command>.md`
  Then record the install:
  ```bash
  curl -sf -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d '{"source":"optimize"}' https://api.forgein.ai/api/skills/<id>/install
  ```

Confirm each install: `✓ /commit installed — type /commit to use it.`

If user enters `none` or `n`: exit without installing.

---

## mem

Parse the next word as the mem subcommand. Default (no word given): run `list`. Subcommands: `list`, `search`, `add`, `prune`, `audit`, `sync`.

**Locate memory directory:**
```bash
find ~/.claude/projects -name "MEMORY.md" 2>/dev/null | head -1
```
Use the parent directory of the first result as the memory directory. If none found: print "Memory not configured. Enable auto-memory in Claude Code settings → Memory." and stop.

---

### mem list

Read MEMORY.md. For each line matching `- [<Title>](<file>) — <description>`, read the file's frontmatter to get its `type` field.

Group entries by type in this order: `user` → `feedback` → `project` → `reference`.

```
MEMORY — 5 entries  (updated 2026-07-06)

USER (1)
  • user-profile.md       — Who Sudhir is, working style, preferences

FEEDBACK (2)
  • feedback-commits.md   — Commit message rules for this project
  • feedback-working-style.md — Autonomy level, post without asking

PROJECT (1)
  • project-portfolio-sprint.md — Active OSS contribution sprint

REFERENCE (1)
  • reference-blog-repo.md — shadowmodder.github.io setup notes
```

---

### mem search \<query\>

Read MEMORY.md to get all linked filenames. Read each linked file in full. Return entries whose body contains the query as a whole word or phrase (case-insensitive).

```
2 matches for "commit"

[feedback-commits.md]  type: feedback
  "Commit messages must not mention Claude or AI..."

[feedback-working-style.md]  type: feedback
  "...post without asking, commit autonomously..."
```

---

### mem add \<type\> \<content\>

Valid types: `user`, `feedback`, `project`, `reference`.

1. Generate a kebab-case slug from the first 5 significant words of content.
2. Write a new file with this frontmatter structure:
```markdown
---
name: <slug>
description: <one-line summary>
metadata:
  type: <type>
---

<content body — for feedback/project: lead with the rule/fact, then **Why:** and **How to apply:** lines>
```
3. Append to MEMORY.md: `- [Title](slug.md) — one-line hook`
4. Confirm: `✓ Saved as <slug>.md and added to index.`

---

### mem prune

Read all files linked from MEMORY.md. For each, check whether the artifacts it references still exist:
- File paths → check with `test -f <path>`
- GitHub PR/issue URLs → check with `gh pr view <number> --repo <repo> --json state`
- Function/class names → `grep -r "<name>" .` from the project root
- Deadlines or dated facts where the date has clearly passed

Flag entries where artifacts are gone or facts are stale. Show one at a time:

```
[project-portfolio-sprint.md]
  References PR #32199 — still open ✓
  References branch fix/reasoning-tokens — still exists ✓
  → OK

[reference-blog-repo.md]
  References branch "master" — exists ✓
  → OK
```

For flagged entries ask: `Delete this memory? (y/n)`
On `y`: delete the file and remove the line from MEMORY.md.

---

### mem audit

Check for and report each structural issue. For each issue, offer to auto-fix:

| Check | Auto-fix |
|-------|----------|
| Duplicate slugs in MEMORY.md | Remove the duplicate line |
| Link points to non-existent file | Remove the broken line |
| Memory file has empty body | Flag for user review |
| MEMORY.md line over 150 chars | Truncate description to fit |
| File missing frontmatter fields | Infer from body and write |

Report format:
```
MEMORY AUDIT

✓ No duplicate slugs
✗ Broken link: user-expertise.md does not exist → remove? (y/n)
✓ All bodies non-empty
✓ All lines under 150 chars
✓ All frontmatter complete

1 issue found.
```

---

### mem sync

Check if `$ARGUMENTS` contains `--team` after `sync`. If so, run **Team sync** below. Otherwise run **Personal sync**.

---

#### Personal sync

Sync memory files for the current project to/from the forgein cloud.

**Load token**
```bash
cat ~/.config/forgein/token 2>/dev/null
```
If missing, print `✗ Not authenticated. Run /forgein auth first.` and stop.

**Detect project**
```bash
pwd
```
Derive the project path identifier by replacing each `/` with `-` and stripping the leading `-`. Example: `/Users/sid/projects/myapp` → `-Users-sid-projects-myapp`.

```bash
echo "$HOME/.claude/projects/$(pwd | sed 's|/|-|g')"
```

If that directory doesn't exist, print `✗ No memory directory found for this project. Run Claude Code in this directory first.` and stop.

**Get cloud manifest**
```bash
TOKEN=$(cat ~/.config/forgein/token)
PROJECT_PATH=$(pwd | sed 's|/|-|g')
curl -sf -H "Authorization: Bearer $TOKEN" \
  "https://api.forgein.ai/api/memory/files?projectPath=$PROJECT_PATH"
```

Parse the JSON array of `{filePath, sha256, updatedAt}`. If request fails with 401, print `✗ Token invalid. Run /forgein auth to re-authenticate.` and stop.

**Compute local state**
```bash
MEMORY_DIR="$HOME/.claude/projects/$(pwd | sed 's|/|-|g')"
find "$MEMORY_DIR" -name "*.md" -not -name "MEMORY.md" -type f
```

For each local file, compute its sha256:
```bash
shasum -a 256 "$file"   # macOS; use sha256sum on Linux
```

**Determine delta**

Build two lists:
- **push**: local files where sha256 differs from cloud (or not in cloud at all)
- **pull**: cloud files not present locally or where cloud sha256 differs from local

If both lists are empty, print `✓ Memory already in sync (N files).` and stop.

Print the plan:
```
MEMORY SYNC — project: -Users-sid-projects-myapp

  PUSH (2)
    user-profile.md          local → cloud
    feedback-commits.md      local → cloud  (updated)

  PULL (1)
    reference-blog.md        cloud → local  (not on this machine)

Proceed? [Y/n]
```

Wait for confirmation. Default is yes (Enter). If user types `n`, stop.

**Execute push**
```bash
TOKEN=$(cat ~/.config/forgein/token)
CONTENT=$(cat "$MEMORY_DIR/$filePath")
curl -sf -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"projectPath\": \"$PROJECT_PATH\", \"filePath\": \"$filePath\", \"content\": $(echo "$CONTENT" | jq -Rs .)}" \
  https://api.forgein.ai/api/memory/files
echo "  ↑ $filePath"
```

**Execute pull**
```bash
TOKEN=$(cat ~/.config/forgein/token)
RESULT=$(curl -sf \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.forgein.ai/api/memory/files/$filePath?projectPath=$PROJECT_PATH")
echo "$RESULT" | jq -r '.content' > "$MEMORY_DIR/$filePath"
echo "  ↓ $filePath"
```

Print final summary: `✓ Sync complete — 2 pushed, 1 pulled.`

---

#### Team sync

Pull memory files shared by your teammates and merge them into the current project's memory directory.

**Load token**
```bash
cat ~/.config/forgein/token 2>/dev/null
```
If missing, print `✗ Not authenticated. Run /forgein auth first.` and stop.

**Fetch shared projects**
```bash
TOKEN=$(cat ~/.config/forgein/token)
curl -sf -H "Authorization: Bearer $TOKEN" https://api.forgein.ai/api/memory/team-projects
```

If the response is an empty array `[]`, print:
```
No team memory has been shared yet.
Ask a team member to share a project from https://app.forgein.ai/dashboard/org
```
and stop.

Parse the JSON array of `{id, ownerEmail, ownerName, projectPath, name, fileCount, lastSyncedAt}`.

**Show available projects**

Display each shared project:
```
TEAM MEMORY — 3 shared projects

#  Owner           Project                       Files   Last sync
1  alice@acme.com  ~/repos/myapp                 12      2h ago
2  alice@acme.com  ~/repos/shared-libs           5       1d ago
3  bob@acme.com    ~/repos/myapp                 8       30m ago
```

Ask: **"Pull which project? [1 / numbers e.g. 1,3 / all / none]:"**

Default (Enter with no input) = pull all.

**For each selected project:**

1. Fetch file list:
```bash
curl -sf -H "Authorization: Bearer $TOKEN" \
  "https://api.forgein.ai/api/memory/team-files?ownerUserId=<ownerUserId>&projectPath=<projectPath>"
```

2. For each file, determine local destination:
   - Local directory: `~/.claude/projects/<currentProjectPath>/`
   - File name: `team-<ownerHandle>-<filePath>` where `ownerHandle` is the part of the owner's email before `@`
   - Example: `alice@acme.com` sharing `user-profile.md` → `team-alice-user-profile.md`

3. Only pull files that don't already exist locally (non-destructive — never overwrite your own memories):
```bash
curl -sf -H "Authorization: Bearer $TOKEN" \
  "https://api.forgein.ai/api/memory/team-file/<filePath>?ownerUserId=<ownerUserId>&projectPath=<projectPath>" \
  | jq -r '.content' > "$MEMORY_DIR/team-<ownerHandle>-<filePath>"
echo "  ↓ team-<ownerHandle>-<filePath>"
```

Print final summary:
```
TEAM SYNC COMPLETE

  ↓ team-alice-user-profile.md        (new)
  ↓ team-alice-feedback-commits.md    (new)
  ↓ team-bob-project-sprint.md        (new)
  — team-alice-feedback-style.md      (already exists, skipped)

✓ 3 pulled, 1 skipped — Claude will read these automatically in this project.
```

---

## sec

### Algorithm

**Step 1 — Get code to scan**

If no second argument or argument is `staged`:
```bash
git diff --staged 2>/dev/null
```
If the output is **empty**, do NOT silently scan something else. Instead print:
```
No staged changes found.
Enter a path to scan (file or directory), or press Enter to cancel:
```
Wait for input. If user gives a path: read that path (use `find <path> -type f` if directory, then Read each file). If user presses Enter with no input: exit cleanly.

If a path argument was given: read that path directly.

**Step 2 — Scan for vulnerability classes**

Check all 8 classes. For each finding, record: severity, location (file:line where available), class name, code snippet ≤ 80 chars, and a one-sentence attack scenario.

| Class | Severity | Pattern |
|-------|----------|---------|
| Secrets | critical | String literals in vars named `key/secret/password/token/api_key/auth` — long alphanumeric, base64, or prefixed (`sk-`, `ghp-`, `xox-`, `AKIA`) |
| Command injection | critical | User input in `subprocess`/`os.system`/`exec`/`eval` with `shell=True` or string concatenation |
| SQL injection | high | User input concatenated into SQL via f-string, `.format()`, or `+` instead of parameterized queries |
| Path traversal | high | User-controlled strings in `open()`/`os.path.join` without `realpath` normalization |
| SSRF | high | User-controlled URLs in `requests`/`httpx`/`fetch`/`urllib` without allowlist |
| XSS | medium | User input in `innerHTML`/`dangerouslySetInnerHTML`/unescaped template output |
| Insecure deserialization | medium | `pickle.loads`, `yaml.load` (not `safe_load`), `eval()` on external data |
| Hardcoded credentials | medium | Literal passwords/tokens in source, config, or test fixtures |

**Step 3 — Output**

Sort findings: critical → high → medium → low.

```
SECURITY FINDINGS — 1 critical, 1 high, 0 medium, 0 low

CRITICAL  src/auth/login.py:47   Command injection
  snippet: subprocess.run(f"convert {filename}", shell=True)
  attack:  filename="x; rm -rf /" executes arbitrary shell commands

HIGH      config/db.py:12   SQL injection
  snippet: f"SELECT * FROM users WHERE id={user_id}"
  attack:  user_id="1 OR 1=1" dumps entire users table

Summary: 1 critical, 1 high, 0 medium, 0 low
```

If no findings: `✓ Clean — no issues found in the scanned code.`

Always end with:
> Note: heuristic check only — run Semgrep, Bandit, or CodeQL for production audits.
