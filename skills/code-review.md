---
description: Multi-dimensional code review across bugs, performance, security, and style. Runs parallel review passes and ranks findings by severity.
---

Run a multi-dimensional code review. Parse `$ARGUMENTS`:
- No argument → review `git diff HEAD` (all uncommitted changes)
- `staged` → review `git diff --staged`
- A file or directory path → review that path
- A PR number (e.g. `#42`) → fetch the diff with `gh pr diff <number>`

Get the diff/code, then run four independent review passes in parallel using the Agent tool. Each pass focuses on one dimension:

---

## Review dimensions

**1. Bugs** — Logic errors, off-by-one, null/None dereferences, unclosed resources, race conditions, incorrect error handling, missing edge cases.

**2. Performance** — N+1 queries, unnecessary allocations in hot paths, missing indexes, synchronous I/O where async is available, O(n²) where O(n log n) exists.

**3. Security** — Same classes as `/sec`: injection, path traversal, secrets, SSRF, broken auth, insecure deserialization.

**4. Style/maintainability** — Dead code, overly complex functions (cyclomatic complexity > 10), missing error messages, magic numbers without constants, inconsistent naming.

---

## Output format

After all passes complete, deduplicate and rank findings by severity. Present as:

```
CODE REVIEW

CRITICAL (must fix before merge)
  Bugs · api/handler.py:34
  user_id fetched from request but never validated — any authenticated user
  can access other users' data by setting ?user_id=<victim>

HIGH (strongly recommended)
  Performance · db/queries.py:89
  N+1: loading order.items in a loop — use select_related() or a JOIN

MEDIUM
  Security · utils/files.py:12
  open(user_path) without realpath normalization — path traversal risk

LOW
  Style · models/user.py:67
  Magic number 86400 — extract as SECONDS_PER_DAY constant

────────────────────────────────
Summary: 1 critical, 1 high, 1 medium, 1 low
Overall risk: HIGH — address critical before merging
```

If no findings across all dimensions: `✓ LGTM — no significant issues found.`
