---
description: Checks CI status across all your open PRs. Flags failures that need attention vs. known infrastructure issues that can't be fixed externally.
---

Check CI status across all open PRs authored by you.

**Steps:**

1. List all your open PRs across repos you care about:
   ```bash
   gh pr list --author "@me" --state open --json number,title,headRepository,headRefName,url
   ```
   If `$ARGUMENTS` contains repo names (e.g. `BerriAI/litellm`), filter to those only.

2. For each PR, get checks:
   ```bash
   gh pr checks <number> --repo <repo>
   ```

3. Classify each failing check:
   - **Infrastructure** (skip, unfixable externally): `Guard main branch`, `Verify PR source branch`, `CodeQL`, `Code scanning results / CodeQL`, `codecov/patch`, `CodSpeed Benchmarks`, `benchmarks`, `pre-run-check`
   - **Actionable**: everything else that's failing

4. Present a status table:

```
PR CI STATUS — 2026-07-05 14:00 UTC

Repo         PR       Status          Notes
litellm      #32198   🟢 Green        all 8 checks pass (guard/CodeQL skipped)
litellm      #32199   ⏳ In progress  3 pass, 2 pending
litellm      #32200   🟢 Green        all 8 checks pass
trl          #6297    🟢 Green        all checks pass
vllm         #47662   ❌ Needs human  pre-run-check: maintainer must add `ready` label
dspy         #9979    🟢 Green        all checks pass
```

5. If any PR has actionable failures: describe what's failing and suggest a fix.

6. If `$ARGUMENTS` includes `--watch`: re-run every 5 minutes until all PRs are green or need human review. Print a diff of what changed each run.
