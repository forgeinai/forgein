---
description: Generates a CHANGELOG.md section from git log between two tags or since the last release. Groups changes by feat/fix/breaking.
---

Generate a changelog section. Parse `$ARGUMENTS`:
- No argument → since last git tag to HEAD
- `v1.2.0` → since that tag to HEAD  
- `v1.1.0..v1.2.0` → between those two tags
- `--since="2026-07-01"` → since a date

**Steps:**

1. Get the commit range:
   ```bash
   # No args: find last tag
   LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
   git log ${LAST_TAG:+$LAST_TAG..}HEAD --oneline --no-merges
   ```

2. For each commit, classify by conventional commit prefix (`feat:`, `fix:`, `perf:`, `refactor:`, `docs:`, `chore:`, `ci:`). Commits without a prefix go into "Other changes."

3. Extract breaking changes: commits with `!` after type or `BREAKING CHANGE:` in body.

4. Group and format:

```markdown
## [1.2.0] — 2026-07-05

### Breaking Changes
- **auth**: removed `user.token` field — use `user.access_token` instead (#142)

### Features
- Add refresh token rotation with automatic revocation (#142)
- Support `input_audio` content parts in `/v1/responses` endpoint (#47662)

### Bug Fixes
- Prevent `reasoning_tokens` forced to 0 in Responses API proxy (#32199)
- Guard against chunks missing `choices` key in stream_chunk_builder (#32198)

### Performance
- Reduce N+1 queries in order listing by 60% with select_related

### Other
- Update CI to pin ruff==0.15.3 across all lint jobs
```

5. Ask: **"Write this to CHANGELOG.md? (prepend / append / print only)"**
   - `prepend` → insert after the `# Changelog` header line
   - `append` → add at end
   - `print only` → just display, don't write
