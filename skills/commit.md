---
description: Generates a conventional commit message from staged changes with automatic scope detection and breaking-change flagging.
---

Generate a conventional commit message for the current staged changes.

**Steps:**

1. Run `git diff --staged` to get what's staged. If nothing staged, run `git diff HEAD` and note it's unstaged.

2. Run `git log --oneline -10` to learn this repo's commit style and scope conventions.

3. Analyze the diff to determine:
   - **Type**: `feat` (new capability), `fix` (bug fix), `refactor` (no behavior change), `perf` (performance), `test` (tests only), `docs` (docs only), `style` (formatting only), `chore` (build/tooling), `ci` (CI config)
   - **Scope**: the subsystem or module most affected (infer from file paths — e.g. `auth`, `api`, `cache`, `ui`). Omit if changes span many modules with no clear center.
   - **Breaking change**: does this change a public API, remove a parameter, change a return type, or require migration? If yes, add `!` after type and a `BREAKING CHANGE:` footer.
   - **Subject**: imperative mood, ≤ 72 chars, no period, specific not vague ("fix null check in user loader" not "fix bug")

4. If the diff is large (> 300 lines) or touches many unrelated files: suggest splitting into multiple commits and list the logical groupings.

5. Output the commit message ready to copy:

```
feat(auth): add refresh token rotation with automatic revocation

Replaces single-use tokens with a rotation window that issues a new
refresh token on each use. Old token is immediately revoked, preventing
replay attacks from token theft.

Closes #142
```

Or for a simple fix:
```
fix(cache): prevent stale read when TTL expires mid-request
```

6. Ask: **"Use this message? (y to commit, e to edit, n to cancel)"**
   - `y` → run `git commit -m "<message>"` 
   - `e` → open the message for editing, then commit
   - `n` → do nothing
