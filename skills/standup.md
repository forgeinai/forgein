---
description: Generates a daily standup from git log, open PRs, and tasks. Done / doing / blocked format.
---

Generate a standup update. Parse `$ARGUMENTS`:
- No argument → yesterday + today (standard daily standup)
- `week` → last 5 working days
- `@name` → generate for a different team member (use their git author name)

**Gather data:**

```bash
# What was done (last working day's commits)
git log --oneline --since="yesterday 00:00" --until="today 00:00" --author="$(git config user.name)" 2>/dev/null

# What's in progress (open PRs)
gh pr list --author "@me" --state open --json number,title,isDraft,reviewDecision 2>/dev/null

# Any blockers in PR review comments
gh pr list --author "@me" --state open --json number,reviews 2>/dev/null
```

Also read memory files for any project notes about blockers or upcoming deadlines.

**Format output:**

```
STANDUP — Monday July 7

✅ Done
  • Fixed reasoning_tokens forced to 0 in Responses API proxy (litellm #32199)
  • Pushed NaN guard fix for vLLM logprobs in TRL GRPO trainer (#6297)

🔨 Doing
  • Waiting on maintainer review for 4 LiteLLM PRs (#32198, #32199, #32200, #32205)
  • Building Forgein — Claude skills toolkit

🚧 Blocked
  • vLLM #47662 needs maintainer to add `ready` label before CI runs
```

Keep each bullet ≤ 100 characters. Group closely related items. Omit sections that are empty.

Ask: **"Copy to clipboard? (y/n)"** — if yes, run `echo "<standup>" | pbcopy` (Mac) or `xclip` (Linux).
