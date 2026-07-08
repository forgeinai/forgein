# forgein adapters

Lightweight shell scripts that write your active [forgein](https://forgein.ai) context to the config file each AI tool expects.

All adapters call the same forgein API — your context is defined once, injected everywhere.

## Prerequisites

1. A forgein account (free): [app.forgein.ai/signup](https://app.forgein.ai/signup)
2. The CLI installed: `curl -fsSL https://app.forgein.ai/cli/install.sh | bash`
3. Authenticated: `/forgein auth` in Claude Code, or manually:
   ```bash
   mkdir -p ~/.config/forgein
   echo "fg_your_token_here" > ~/.config/forgein/token
   ```
4. At least one memory synced: `/forgein mem sync`

## Adapters

| Tool | Config file | Command |
|------|------------|---------|
| [Cursor](./cursor/) | `.cursorrules` or `~/.cursor/rules` | `bash adapters/cursor/inject.sh` |
| [Windsurf](./windsurf/) | `.windsurfrules` or `~/.codeium/windsurf/memories/global_rules.md` | `bash adapters/windsurf/inject.sh` |
| [GitHub Copilot](./copilot/) | `.github/copilot-instructions.md` | `bash adapters/copilot/inject.sh` |

ChatGPT and Gemini adapters are available from the [forgein dashboard](https://app.forgein.ai/dashboard/contexts) — they generate content you paste once, since those tools don't expose a file-level config.

## Usage

Run from the root of your project:

```bash
# Cursor — writes .cursorrules
bash <(curl -fsSL https://raw.githubusercontent.com/forgeinai/forgein/main/adapters/cursor/inject.sh)

# Windsurf — writes .windsurfrules
bash <(curl -fsSL https://raw.githubusercontent.com/forgeinai/forgein/main/adapters/windsurf/inject.sh)

# Copilot — writes .github/copilot-instructions.md
bash <(curl -fsSL https://raw.githubusercontent.com/forgeinai/forgein/main/adapters/copilot/inject.sh)
```

Or with global flag for tool-level rules:
```bash
bash adapters/cursor/inject.sh --global    # → ~/.cursor/rules
bash adapters/windsurf/inject.sh --global  # → ~/.codeium/windsurf/memories/global_rules.md
```

## Automate with git hooks

Add to `.git/hooks/post-checkout` (and make executable) to refresh context on branch switches:

```bash
#!/usr/bin/env bash
bash <(curl -fsSL https://raw.githubusercontent.com/forgeinai/forgein/main/adapters/cursor/inject.sh) 2>/dev/null || true
```

## Contributing

PRs welcome. If you have an adapter for another tool (VS Code, JetBrains, Zed, etc.), open a PR with `adapters/<tool>/inject.sh` following the same pattern.
