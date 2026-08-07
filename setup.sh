#!/usr/bin/env bash
# =============================================================================
# Security Champion — Setup Script
# Installs the security champion system into your project.
#
# Usage:
#   ./setup.sh                   # Interactive install
#   ./setup.sh --claude-code     # Claude Code CLI mode (pre-commit hook)
#   ./setup.sh --api             # Anthropic API mode (pre-commit hook)
#   ./setup.sh --prompt-only     # Copy CLAUDE.md only (no hook)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO="${2:-$(pwd)}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "🔐 Security Champion Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect if we're inside a git repo
if ! git -C "$TARGET_REPO" rev-parse --git-dir &>/dev/null; then
    echo -e "${RED}❌ Not inside a git repository. Run from your project root.${NC}"
    exit 1
fi

GIT_ROOT=$(git -C "$TARGET_REPO" rev-parse --show-toplevel)
echo "📁 Target repo: $GIT_ROOT"
echo ""

MODE="${1:-}"

if [[ -z "$MODE" ]]; then
    echo "Which setup mode?"
    echo "  1) Claude Code CLI  — uses \`claude\` CLI for pre-commit (recommended)"
    echo "  2) Anthropic API    — uses API key directly (no Claude Code required)"
    echo "  3) Prompt only      — copy CLAUDE.md only, no pre-commit hook"
    echo ""
    read -rp "Enter choice [1/2/3]: " CHOICE
    case "$CHOICE" in
        1) MODE="--claude-code" ;;
        2) MODE="--api" ;;
        3) MODE="--prompt-only" ;;
        *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
    esac
fi

# ─── Step 1: Copy CLAUDE.md ───────────────────────────────────────────────────
echo -e "${BLUE}[1/4] Installing CLAUDE.md (always-on secure coder)...${NC}"

if [[ -f "$GIT_ROOT/CLAUDE.md" ]]; then
    echo -e "${YELLOW}      CLAUDE.md already exists. Merging security champion section...${NC}"
    # Append if the security champion header isn't already present
    if ! grep -q "Security Champion" "$GIT_ROOT/CLAUDE.md"; then
        echo "" >> "$GIT_ROOT/CLAUDE.md"
        echo "---" >> "$GIT_ROOT/CLAUDE.md"
        cat "$SCRIPT_DIR/CLAUDE.md" >> "$GIT_ROOT/CLAUDE.md"
        echo -e "${GREEN}      ✓ Appended to existing CLAUDE.md${NC}"
    else
        echo -e "${YELLOW}      ⚠ Security Champion already present in CLAUDE.md. Skipping.${NC}"
    fi
else
    cp "$SCRIPT_DIR/CLAUDE.md" "$GIT_ROOT/CLAUDE.md"
    echo -e "${GREEN}      ✓ CLAUDE.md installed${NC}"
fi

# ─── Step 2: Install slash command ────────────────────────────────────────────
echo -e "${BLUE}[2/4] Installing /security-review slash command...${NC}"

mkdir -p "$GIT_ROOT/.claude/commands"
cp "$SCRIPT_DIR/dot-claude/commands/security-review.md" \
   "$GIT_ROOT/.claude/commands/security-review.md"
echo -e "${GREEN}      ✓ .claude/commands/security-review.md installed${NC}"
echo "      Usage in Claude Code: /security-review"

# ─── Step 3: Install pre-commit hook ──────────────────────────────────────────
if [[ "$MODE" != "--prompt-only" ]]; then
    echo -e "${BLUE}[3/4] Installing pre-commit hook...${NC}"

    HOOKS_DIR="$GIT_ROOT/.git/hooks"
    mkdir -p "$HOOKS_DIR"

    if [[ -f "$HOOKS_DIR/pre-commit" ]]; then
        echo -e "${YELLOW}      Existing pre-commit hook found. Backing up to pre-commit.bak${NC}"
        cp "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-commit.bak"
    fi

    if [[ "$MODE" == "--claude-code" ]]; then
        cp "$SCRIPT_DIR/hooks/pre-commit" "$HOOKS_DIR/pre-commit"
        chmod +x "$HOOKS_DIR/pre-commit"
        echo -e "${GREEN}      ✓ pre-commit hook installed (Claude Code CLI mode)${NC}"

        # Verify claude CLI is available
        if ! command -v claude &>/dev/null; then
            echo -e "${YELLOW}      ⚠ Warning: 'claude' CLI not found in PATH.${NC}"
            echo "        Install Claude Code: https://claude.ai/code"
        else
            echo -e "${GREEN}      ✓ claude CLI detected: $(which claude)${NC}"
        fi

    elif [[ "$MODE" == "--api" ]]; then
        cp "$SCRIPT_DIR/hooks/pre-commit-api.py" "$HOOKS_DIR/pre-commit"
        chmod +x "$HOOKS_DIR/pre-commit"
        echo -e "${GREEN}      ✓ pre-commit hook installed (API mode)${NC}"

        if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
            echo -e "${YELLOW}      ⚠ ANTHROPIC_API_KEY not set in current shell.${NC}"
            echo "        Add to your shell profile (~/.bashrc, ~/.zshrc):"
            echo "        export ANTHROPIC_API_KEY=your_key_here"
        else
            echo -e "${GREEN}      ✓ ANTHROPIC_API_KEY detected${NC}"
        fi

        # Check anthropic package
        if ! python3 -c "import anthropic" &>/dev/null; then
            echo -e "${YELLOW}      ⚠ anthropic Python package not installed.${NC}"
            echo "        Run: pip install anthropic"
        fi
    fi
else
    echo -e "${YELLOW}[3/4] Skipping pre-commit hook (prompt-only mode)${NC}"
fi

# ─── Step 4: Add to .gitignore (optional) ─────────────────────────────────────
echo -e "${BLUE}[4/4] Checking .gitignore...${NC}"

GITIGNORE="$GIT_ROOT/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
    # .env should already be there, but make sure
    if ! grep -q "^\.env$" "$GITIGNORE"; then
        echo ".env" >> "$GITIGNORE"
        echo -e "${GREEN}      ✓ Added .env to .gitignore${NC}"
    else
        echo "      .env already in .gitignore ✓"
    fi
    if ! grep -q "\.pem$\|\.key$\|\.p12$\|\.pfx$" "$GITIGNORE"; then
        printf "\n# Secret files — managed by Security Champion\n*.pem\n*.key\n*.p12\n*.pfx\n" >> "$GITIGNORE"
        echo -e "${GREEN}      ✓ Added key file patterns to .gitignore${NC}"
    fi
else
    printf ".env\n*.pem\n*.key\n*.p12\n*.pfx\n" > "$GITIGNORE"
    echo -e "${GREEN}      ✓ Created .gitignore with secret file patterns${NC}"
fi

# ─── Step 5: Sync GitHub labels (optional) ────────────────────────────────────
if [[ "$MODE" != "--prompt-only" ]]; then
    echo -e "${BLUE}[5/5] GitHub labels (optional)...${NC}"
    LABELS_SRC="$SCRIPT_DIR/dot-github/labels.yml"
    LABELS_DEST="$GIT_ROOT/.github/labels.yml"

    if [[ -f "$LABELS_SRC" ]]; then
        mkdir -p "$GIT_ROOT/.github"
        cp "$LABELS_SRC" "$LABELS_DEST"
        echo -e "${GREEN}      ✓ .github/labels.yml installed${NC}"
        echo ""
        echo "      To sync labels to GitHub:"
        echo "      npx github-label-sync --access-token YOUR_TOKEN \\"
        echo "        --labels .github/labels.yml YOUR_ORG/YOUR_REPO"
        echo ""
        echo "      Labels created:"
        echo "        security-review-skip    (yellow) bypass automated review"
        echo "        security: critical      (red)    CRITICAL finding on PR"
        echo "        security: high          (yellow) HIGH finding on PR"
        echo "        security: approved      (green)  review passed"
        echo "        security-debt           (blue)   tracks SECURITY-DEBT comments"
        echo "        security: false-positive         reviewed, not a real finding"
    fi
fi

# ─── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅  Security Champion installed successfully!${NC}"
echo ""
echo "What's active:"
echo "  • CLAUDE.md            → Always-on secure coder (Claude Code reads this automatically)"
echo "  • /security-review     → Slash command for on-demand reviews"
if [[ "$MODE" != "--prompt-only" ]]; then
echo "  • .git/hooks/pre-commit → Automatic review on every git commit"
echo "  • .github/labels.yml   → GitHub label definitions (sync with github-label-sync)"
fi
echo ""
echo "CI/CD (copy and rename):"
echo "  dot-github/workflows/security-review.yml  →  .github/workflows/security-review.yml"
echo "  dot-gitlab-ci.yml                          →  .gitlab-ci.yml"
echo ""
echo "Usage:"
echo "  git add . && git commit -m 'feat: ...'   # Hook runs automatically"
echo "  /security-review                         # Run on-demand in Claude Code"
echo "  SKIP_SECURITY_REVIEW=1 git commit ...    # Emergency bypass (use sparingly)"
echo ""
echo "Standalone (non-Claude-Code agents):"
echo "  Copy CLAUDE.md content as your agent's system prompt."
echo "  Copy prompts/PRE_COMMIT_REVIEW_PROMPT.md and paste with your diff."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
