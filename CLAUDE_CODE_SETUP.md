# Security Champion — Claude Code Setup Guide

This guide covers everything specific to using Security Champion with **Claude Code** (the `claude` CLI).

---

## Prerequisites

```bash
# Verify Claude Code is installed
claude --version

# Verify you're authenticated
claude whoami
```

If not installed: https://claude.ai/code

---

## Install into your project

```bash
# 1. Clone security-champion next to your project (or anywhere)
git clone https://github.com/your-org/security-champion ~/tools/security-champion

# 2. Go to YOUR project root
cd ~/your-project

# 3. Run the installer
~/tools/security-champion/setup.sh --claude-code
```

That's it. The installer copies four things into your project:

| What | Where | Effect |
|------|-------|--------|
| `CLAUDE.md` | `./CLAUDE.md` | Claude Code reads this automatically every session |
| `security-review.md` | `./.claude/commands/security-review.md` | Adds `/security-review` slash command |
| `settings.json` | `./.claude/settings.json` | Adds lifecycle hook (reminder when staged changes exist) |
| `pre-commit` | `./.git/hooks/pre-commit` | Runs `claude --print` review before every `git commit` |

---

## Day-to-day usage in Claude Code

### 1. Always-on secure coder (automatic)

Open your project in Claude Code:
```bash
cd ~/your-project
claude
```

Claude Code reads `CLAUDE.md` at session start. From this point the secure coder is active — it will:
- Bootstrap context by scanning your codebase
- Ask you for design docs (PRD, HLD, LLD, DFD) if they exist
- Write secure code by default in every language it touches
- Add `// SECURITY:` inline comments explaining security decisions
- Refuse insecure shortcuts and explain why

You don't invoke it. It's always on.

---

### 2. On-demand review: `/security-review`

Run this at any time inside a Claude Code session:

```
/security-review
```

Claude Code will:
1. Run `git diff --staged` (or `git diff HEAD~1` if nothing staged)
2. Read surrounding code context for every changed file
3. Run the full security checklist for detected languages
4. Print a tiered findings report
5. Emit a verdict: ✅ APPROVED / ⚠️ CAUTION / 🚫 BLOCKED

Use this before committing when you want a detailed interactive review — the pre-commit hook is non-interactive; `/security-review` lets you ask follow-up questions.

```
/security-review

# Then you can follow up:
"Explain the SSRF finding on line 47 in more detail"
"Show me the safe version of that handler"
"Is the JWT fix compatible with our existing auth middleware?"
```

---

### 3. Pre-commit hook (automatic on `git commit`)

The hook runs automatically:

```bash
git add src/UserController.java
git commit -m "feat: add password reset"

# Output:
# 🔐 Running security review on staged changes...
#
# [CRITICAL] SQL Injection in UserController.java
# File     : src/UserController.java:52
# ...
# 🚫 SECURITY REVIEW: BLOCKED
#
# 🚫 Commit BLOCKED. Fix CRITICAL findings and retry.
```

The hook uses `claude --print` which runs Claude non-interactively (no UI, no session, just stdout). It's fast enough to run on every commit.

**Emergency bypass** (use sparingly — leaves a paper trail):
```bash
SKIP_SECURITY_REVIEW=1 git commit -m "hotfix: ..."
```

---

### 4. Claude Code lifecycle hook

`settings.json` adds a `Stop` hook — when Claude Code finishes a session where you have staged changes, it reminds you to run `/security-review` before committing. This catches the gap between "Claude wrote the code" and "developer commits without reviewing."

---

## Workflow: new feature development

```
1. cd my-project && claude
   → CLAUDE.md loads → secure coder active

2. "Build me a password reset endpoint using Spring Boot"
   → Claude writes secure code (parameterized SQL, BCrypt, secure JWT, safe error handling)
   → Adds // SECURITY: comments explaining each decision

3. You review, ask questions, tweak

4. git add src/...
   → Stop hook fires: "Staged changes detected. Run /security-review before committing."

5. /security-review
   → Interactive review with context-reading
   → "The JWT expiry is set to 30 days — for password reset tokens this should be 15 minutes. Fix?"
   → "Yes"
   → Claude fixes it inline

6. git commit -m "feat: password reset endpoint"
   → Pre-commit hook runs: ✅ SECURITY REVIEW: APPROVED
   → Commit proceeds
```

---

## Workflow: reviewing someone else's PR locally

```bash
git fetch origin
git checkout -b review/feature-xyz origin/feature/xyz

claude  # Opens in the branch context

/security-review  # Reviews diff vs main

# Follow up:
"The CRITICAL finding on UserRepo — is there an existing pattern in our codebase we should follow?"
"Generate the fix and explain it to me so I can review the PR properly"
```

---

## Sharing across your team

Once `CLAUDE.md` and `.claude/` are committed to your repo, every engineer who runs `claude` in that repo gets the security champion automatically. No individual setup required beyond having Claude Code installed.

```bash
# What to commit to your project repo:
git add CLAUDE.md .claude/commands/security-review.md .claude/settings.json
git commit -m "chore: add security champion"

# The pre-commit hook is NOT committed (it's in .git/ which is gitignored).
# Each developer runs setup.sh once to install it locally.
```

---

## Customising for your project

Once installed, you can edit `CLAUDE.md` in your project root to add project-specific context that the secure coder should always know:

```markdown
# Project Security Context (add at top of CLAUDE.md)

## This project
- Auth model: OAuth2 with internal IdP, JWT RS256, 15-minute expiry
- Database: PostgreSQL via Hibernate ORM — always use named parameters
- Sensitive data: PII (name, email, phone), no financial or health data
- External calls: payments via Stripe SDK only (no raw HTTP to payment endpoints)
- Secret storage: AWS Secrets Manager (region: ap-south-1)
- Trust boundary: public API (unauthenticated users can call /api/public/*)
```

The secure coder reads this at session start and applies it to every decision it makes.

---

## Troubleshooting

**Hook says `claude: command not found`**
```bash
# Claude Code CLI not in PATH. Find it and add to shell profile:
which claude || find /usr/local /opt ~/.local -name "claude" 2>/dev/null
echo 'export PATH="$PATH:/path/to/claude/bin"' >> ~/.zshrc
```

**`/security-review` not showing up in Claude Code**
```bash
# Check the command file is in the right place
ls .claude/commands/security-review.md

# If missing, re-run setup:
~/tools/security-champion/setup.sh --claude-code
```

**Review is slow on large diffs**
The hook passes the full diff to Claude. For very large commits, it can take 20–40 seconds. This is normal — Claude is reading surrounding file context for each change. Split large commits into smaller, logical units (which is good practice anyway).

**False positive blocked my commit**
```bash
# Bypass this one commit:
SKIP_SECURITY_REVIEW=1 git commit -m "..."

# Then open Claude Code and investigate:
claude
/security-review
"The CRITICAL finding on line 23 — is this actually exploitable given our middleware?"
```
