#!/usr/bin/env bash
# Installs secure-coder into the target project (run from inside the target repo).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"

if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "Run this from the root of a git repository." >&2
  exit 1
fi

echo "Installing secure-coder into $TARGET_DIR"

# 1. Always-on persona
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  echo "CLAUDE.md already exists — appending secure-coder rules instead of overwriting."
  {
    echo ""
    echo "---"
    echo ""
    cat "$SCRIPT_DIR/CLAUDE.md"
  } >> "$TARGET_DIR/CLAUDE.md"
else
  cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
fi

# 2. Slash command
mkdir -p "$TARGET_DIR/.claude/commands"
cp "$SCRIPT_DIR/.claude/commands/security-review.md" "$TARGET_DIR/.claude/commands/security-review.md"

# 3. Claude Code settings (Stop hook reminder) — merge if settings.json already exists
if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
  echo "$TARGET_DIR/.claude/settings.json already exists — merge the Stop hook from $SCRIPT_DIR/.claude/settings.json manually."
else
  cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"
fi

# 4. Local pre-commit git hook
cp "$SCRIPT_DIR/hooks/pre-commit" "$TARGET_DIR/.git/hooks/pre-commit"
chmod +x "$TARGET_DIR/.git/hooks/pre-commit"

# 5. GitHub Actions PR gate
mkdir -p "$TARGET_DIR/.github/workflows"
cp "$SCRIPT_DIR/.github/workflows/security-review.yml" "$TARGET_DIR/.github/workflows/security-review.yml"

echo ""
echo "Done. Installed:"
echo "  - CLAUDE.md                              (always-on secure coder persona)"
echo "  - .claude/commands/security-review.md     (/security-review slash command)"
echo "  - .claude/settings.json                   (pre-commit reminder hook)"
echo "  - .git/hooks/pre-commit                   (local commit gate, needs 'claude' CLI)"
echo "  - .github/workflows/security-review.yml   (PR gate, needs ANTHROPIC_API_KEY repo secret)"
echo ""
echo "Next steps:"
echo "  1. Add ANTHROPIC_API_KEY to this repo's GitHub secrets (Settings > Secrets and variables > Actions)."
echo "  2. Commit these files."
echo "  3. Run 'claude' in this project — the secure coder persona is now always active."
