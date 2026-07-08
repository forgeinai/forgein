#!/usr/bin/env bash
# forgein → GitHub Copilot adapter
# Fetches your active forgein context and writes .github/copilot-instructions.md.
# Usage: bash inject.sh
# Run from the root of any project. Commit the generated file to share with your team.
set -euo pipefail

TOKEN_FILE="$HOME/.config/forgein/token"
API="https://api.forgein.ai"

[ -f "$TOKEN_FILE" ] || { echo "✗ Not authenticated. Run: curl -fsSL https://app.forgein.ai/cli/install.sh | bash  then /forgein auth"; exit 1; }
TOKEN=$(cat "$TOKEN_FILE")

printf 'Fetching active context from forgein...\n'
RESPONSE=$(curl -sf --max-time 10 \
  -H "Authorization: Bearer $TOKEN" \
  "$API/api/adapters/copilot" 2>/dev/null) || { echo "✗ Could not reach api.forgein.ai — check your connection."; exit 1; }

CONTENT=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('content',''))" 2>/dev/null)
CTX=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('context','work'))" 2>/dev/null)
FILES=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('fileCount',0))" 2>/dev/null)

[ -z "$CONTENT" ] && { echo "✗ No context files synced yet. Run /forgein mem sync first."; exit 1; }

mkdir -p .github
OUT=".github/copilot-instructions.md"
{
  printf '<!-- forgein context — %s (%s files) — updated %s -->\n\n' "$CTX" "$FILES" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "$CONTENT"
} > "$OUT"

printf '✓ Written to %s (%s context, %s files)\n' "$OUT" "$CTX" "$FILES"
printf '  Commit this file to share the context with your team.\n'
printf '  Add to a git hook or CI step to keep it current.\n'
