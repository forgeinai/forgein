#!/usr/bin/env bash
set -e

REGISTRY="https://raw.githubusercontent.com/forgeinai/forgein/main"
COMMANDS_DIR="$HOME/.claude/commands"

mkdir -p "$COMMANDS_DIR"

echo "Installing Forgein..."
curl -fsSL "$REGISTRY/skills/forgein.md" -o "$COMMANDS_DIR/forgein.md"
echo "✓ /forgein installed"
echo ""
echo "Get started:"
echo "  /forgein optimize   — discover skills for your workflow"
echo "  /forgein mem        — manage your Claude memory"
echo "  /forgein sec        — security check your staged changes"
