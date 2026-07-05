---
description: Security vibe check on staged git changes or any file/directory. Catches secrets, injection, path traversal, XSS, SSRF, and more.
---

Run a security vibe check. Parse `$ARGUMENTS`:
- No argument or `staged` → run `git diff --staged` and scan the output
- A file or directory path → Read that path (use Bash `find` if directory)

For each finding record: **severity** (critical / medium / low), **location** (file:line), **class**, **snippet** (≤ 80 chars), **attack scenario** (1 sentence max).

---

## Vulnerability classes to check

| Class | What to look for |
|-------|-----------------|
| **Secrets** | String literals in variables named `key`, `secret`, `password`, `token`, `api_key`, `auth` — long alphanumeric, base64-looking, or prefixed (`sk-`, `ghp-`, `xox-`, `AKIA`) |
| **SQL injection** | User input concatenated into SQL via f-string, `.format()`, or `+` instead of parameterized queries |
| **Command injection** | User-controlled input passed to `subprocess`, `os.system`, `exec`, `eval`, or any call with `shell=True` |
| **Path traversal** | User-controlled strings used in `open()`, `os.path.join`, file reads without `os.path.realpath` normalization |
| **XSS** | User input in `innerHTML`, `dangerouslySetInnerHTML`, or unescaped template rendering |
| **Insecure deserialization** | `pickle.loads`, `yaml.load` (not `yaml.safe_load`), `eval()` on external data |
| **SSRF** | User-controlled URLs passed to `requests`, `httpx`, `fetch`, `urllib` without allowlist validation |
| **Hardcoded credentials** | Literal passwords, tokens, or private keys in source code, config files, or test fixtures |

---

## Output format

**If findings:**
```
SECURITY FINDINGS

CRITICAL  src/auth/login.py:47   Command injection
  snippet: f"convert {user_filename} output.png"
  attack:  attacker passes "x; rm -rf /" as filename, executes arbitrary shell commands

MEDIUM    config/settings.py:12   Hardcoded secret
  snippet: API_KEY = "sk-proj-abc123..."
  attack:  key exposed if repo is public or leaked in git history

LOW       api/views.py:83   Path traversal risk
  snippet: open(f"uploads/{user_id}/{filename}")
  attack:  filename="../../../etc/passwd" reads sensitive system files

Summary: 1 critical, 1 medium, 1 low
```

**If no findings:**
```
✓ Clean — no issues found in the scanned code.
```

**Always append:**
> Note: heuristic check only — run a dedicated SAST tool (Semgrep, Bandit, CodeQL) before shipping to production.
