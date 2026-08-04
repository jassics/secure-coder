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

# 4. Standalone prompt files (for non-Claude-Code agents, and shared by both pre-commit hooks)
mkdir -p "$TARGET_DIR/prompts"
cp "$SCRIPT_DIR/prompts/SECURE_CODER_SYSTEM_PROMPT.md" "$TARGET_DIR/prompts/SECURE_CODER_SYSTEM_PROMPT.md"
cp "$SCRIPT_DIR/prompts/PRE_COMMIT_REVIEW_PROMPT.md" "$TARGET_DIR/prompts/PRE_COMMIT_REVIEW_PROMPT.md"

# 5. Local pre-commit git hook — Claude Code CLI by default, or Anthropic API directly if no CLI/login
mkdir -p "$TARGET_DIR/hooks"
cp "$SCRIPT_DIR/hooks/pre-commit" "$TARGET_DIR/hooks/pre-commit"
cp "$SCRIPT_DIR/hooks/pre-commit-api.py" "$TARGET_DIR/hooks/pre-commit-api.py"
chmod +x "$TARGET_DIR/hooks/pre-commit" "$TARGET_DIR/hooks/pre-commit-api.py"

if command -v claude >/dev/null 2>&1; then
  cp "$SCRIPT_DIR/hooks/pre-commit" "$TARGET_DIR/.git/hooks/pre-commit"
  chmod +x "$TARGET_DIR/.git/hooks/pre-commit"
  HOOK_INSTALLED="hooks/pre-commit (Claude Code CLI)"
else
  cp "$SCRIPT_DIR/hooks/pre-commit-api.py" "$TARGET_DIR/.git/hooks/pre-commit"
  chmod +x "$TARGET_DIR/.git/hooks/pre-commit"
  HOOK_INSTALLED="hooks/pre-commit-api.py (Anthropic API — 'claude' CLI not found on this machine)"
fi

# 6. GitHub Actions PR gate
mkdir -p "$TARGET_DIR/.github/workflows"
cp "$SCRIPT_DIR/.github/workflows/security-review.yml" "$TARGET_DIR/.github/workflows/security-review.yml"

echo ""
echo "Done. Installed:"
echo "  - CLAUDE.md                              (always-on secure coder persona)"
echo "  - .claude/commands/security-review.md     (/security-review slash command)"
echo "  - .claude/settings.json                   (pre-commit reminder hook)"
echo "  - prompts/SECURE_CODER_SYSTEM_PROMPT.md   (portable persona, paste into any coding agent)"
echo "  - prompts/PRE_COMMIT_REVIEW_PROMPT.md     (shared template for both pre-commit hooks)"
echo "  - hooks/pre-commit + hooks/pre-commit-api.py (both variants copied into the repo)"
echo "  - .git/hooks/pre-commit                   (active hook: $HOOK_INSTALLED)"
echo "  - .github/workflows/security-review.yml   (PR gate, needs ANTHROPIC_API_KEY repo secret)"
echo ""
echo "Next steps:"
echo "  1. Add ANTHROPIC_API_KEY to this repo's GitHub secrets (Settings > Secrets and variables > Actions)."
echo "  2. Commit these files."
echo "  3. Run 'claude' in this project — the secure coder persona is now always active."
echo ""
echo "To switch the active local hook: cp hooks/pre-commit .git/hooks/pre-commit (Claude Code CLI)"
echo "                              or: cp hooks/pre-commit-api.py .git/hooks/pre-commit (Anthropic API, needs 'pip install anthropic')"
echo ""
if ! command -v gitleaks >/dev/null 2>&1 || ! command -v semgrep >/dev/null 2>&1; then
  echo "Recommended: install the deterministic scanner backstop the pre-commit hooks and CI rely on:"
  command -v gitleaks >/dev/null 2>&1 || echo "  - gitleaks (secrets): https://github.com/gitleaks/gitleaks"
  command -v semgrep >/dev/null 2>&1 || echo "  - semgrep (SAST):     pip install semgrep"
  echo "Without them, the local hooks fall back to AI-only review; CI always installs and runs both."
fi
