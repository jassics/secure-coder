# Security Champion

> **No insecure code reaches your repository.**

A portable, agent-agnostic security system for developers. Drop it into any project and your AI coding agent becomes a security-aware pair programmer — with automatic pre-commit blocking on critical vulnerabilities.

Covers Java, Python, TypeScript, React, and Go. Checks for SQLi, XSS, RCE, SSRF, auth/authz flaws, insecure JWT, GraphQL vulnerabilities, insecure headers, secrets in code, CVE-laden dependencies, Docker misconfigs, and logging PII.

---

## What it does

### Always-On Secure Coder (`CLAUDE.md`)
Once installed, your AI agent:
- Reads the codebase and asks for design docs (PRD, HLD, LLD, DFD) at session start to understand trust boundaries and data sensitivity
- Writes secure-by-default code in every language — parameterized queries, correct crypto, secure JWT config, proper headers, least-privilege patterns
- Adds `// SECURITY:` inline comments explaining every security decision
- Refuses "quick/dirty" shortcuts and explains why
- Flags security debt it observes in existing code, even when not asked to fix it

### Pre-Commit Reviewer (`/security-review`)
Before every `git commit`:
- Reads the staged diff **and** surrounding code context (not just changed lines)
- Runs a structured checklist for every detected language
- Produces a tiered findings report: CRITICAL → HIGH → MEDIUM → INFO
- **Blocks commits** on CRITICAL findings (only when confidence is HIGH)
- Generates ready-to-file remediation tickets for CRITICAL/HIGH findings

---

## Install

```bash
git clone https://github.com/your-org/security-champion
cd security-champion
chmod +x setup.sh
./setup.sh
```

Choose your mode when prompted:
- **Claude Code CLI** — uses the `claude` CLI installed with Claude Code (recommended)
- **Anthropic API** — uses your API key directly, no Claude Code required
- **Prompt only** — install `CLAUDE.md` and the slash command, skip the hook

Or non-interactively:
```bash
./setup.sh --claude-code   # Claude Code mode
./setup.sh --api           # API mode
./setup.sh --prompt-only   # No hook
```

The script installs into whatever git repo you run it from.

---

## What gets installed

```
your-project/
├── CLAUDE.md                          ← Always-on secure coder (auto-read by Claude Code)
├── .claude/
│   └── commands/
│       └── security-review.md         ← /security-review slash command
└── .git/
    └── hooks/
        └── pre-commit                 ← Automatic review on git commit
```

---

## Usage

### Automatic (pre-commit hook)
```bash
git add src/UserController.java
git commit -m "feat: add password reset endpoint"
# → Security review runs automatically
# → APPROVED / CAUTION / BLOCKED verdict printed
# → Commit blocked if CRITICAL findings found
```

### Manual slash command (Claude Code)
```
/security-review
```
Runs on current staged changes or the last commit.

### Emergency bypass
```bash
SKIP_SECURITY_REVIEW=1 git commit -m "hotfix: ..."
```
Use sparingly. Every bypass is visible in git history context.

---

## Standalone (non-Claude-Code agents)

Works with any AI coding agent (Cursor, Copilot Chat, ChatGPT, Gemini, etc.):

1. **Always-on coder**: Paste the contents of `CLAUDE.md` as your agent's **system prompt**.
2. **Pre-commit review**: Paste `prompts/PRE_COMMIT_REVIEW_PROMPT.md` + your `git diff --staged` output as a user message.

---

## Requirements

| Mode | Requirements |
|------|-------------|
| Claude Code | `claude` CLI installed, authenticated |
| API | `pip install anthropic`, `ANTHROPIC_API_KEY` in shell env |
| Prompt only | Any AI coding agent |

---

## Language Coverage

| Language | Injection | Crypto | AuthN/Z | SSRF | Headers | Logging | Deps |
|----------|-----------|--------|---------|------|---------|---------|------|
| Java (Spring) | SQLi, XXE, SSTI, Deserialization | AES-GCM, BCrypt, SecureRandom | Spring Security, CSRF, JWT RS256 | RestTemplate/WebClient | CSP, HSTS, XFO | Logback structured, no PII | OWASP dep-check |
| Python (Django/Flask/FastAPI) | SQLi, cmdi, SSTI, Pickle, Path traversal | bcrypt/argon2, cryptography lib | @login_required, CSRF, Depends() JWT | requests + allowlist | Django security settings | logging module, no PII | pip-audit |
| TypeScript/Node | SQLi, NoSQLi, Prototype pollution, cmdi | — | passport/express-jwt, JWT RS256 | fetch + IP check | helmet | pino/winston, redacted fields | npm audit |
| React | XSS (DOMPurify, href), eval | — | CSRF tokens | — | CSP via server | — | npm audit |
| Go | SQLi, cmdi, Path traversal | AES-GCM, bcrypt, crypto/rand | golang-jwt RS256, middleware | net/http + IP check | Manual headers | log/slog, no PII | govulncheck |
| GraphQL | Injection | — | Field-level authz | — | — | Error sanitization | — |
| Infra | Secrets (regex), Docker, .env | — | — | — | — | — | CVE scan |

---

## Findings Format

```
[CRITICAL] SQL Injection in UserRepository.java
File     : src/main/java/com/example/UserRepository.java:47
Confidence: HIGH
Category : Injection
Evidence : String sql = "SELECT * FROM users WHERE email = '" + email + "'";
Attack   : Attacker passes email='; DROP TABLE users;-- to delete all user data
Fix      :
  // SECURITY: Parameterized query prevents SQL injection
  PreparedStatement stmt = conn.prepareStatement(
      "SELECT * FROM users WHERE email = ?"
  );
  stmt.setString(1, email);
```

---

## Commit Verdicts

```
✅  SECURITY REVIEW: APPROVED    → Safe to commit
⚠️  SECURITY REVIEW: CAUTION    → HIGH findings; fix before merging to main
🚫  SECURITY REVIEW: BLOCKED    → CRITICAL finding confirmed; must fix before commit
```

BLOCKED is only issued when the reviewer has confirmed the vulnerability by reading surrounding code context — not just the diff line.

---

## GitHub Actions (CI/CD)

Copy `dot-github/workflows/security-review.yml` → `.github/workflows/security-review.yml` in your repo.

**Setup:**
1. Add `ANTHROPIC_API_KEY` to repo secrets: Settings → Secrets and variables → Actions
2. Copy the workflow file (rename `dot-github/` → `.github/`)

**What it does on every PR:**
- Diffs the PR branch against base and sends it to Claude for review
- Posts a collapsible security report as a PR comment (updates on re-push, no spam)
- **Fails the check** (blocks merge) on CRITICAL findings
- CAUTION posts a warning but does not block
- Large diffs (>150KB) are truncated with a manual review note
- Add label `security-review-skip` to a PR to bypass (useful for doc-only PRs)

**GitLab equivalent:** copy `dot-gitlab-ci.yml` → `.gitlab-ci.yml`. Add `ANTHROPIC_API_KEY` and optionally `GITLAB_TOKEN` (for MR note posting) to CI/CD variables. Same verdict logic and MR note behavior as GitHub.

**Example PR/MR comment:**

```
🚫 Security Review: BLOCKED — Critical findings must be fixed before merge

▶ Full Security Review Report (click to expand)

[CRITICAL] SQL Injection in UserRepository.java
File     : src/main/java/.../UserRepository.java:47
Confidence: HIGH
...
```

---

## Files

```
security-champion/
├── README.md
├── setup.sh                               ← Install script
├── CLAUDE.md                              ← Always-on system prompt (copy to project root)
├── dot-claude/
│   └── commands/
│       └── security-review.md             ← Slash command (copy to .claude/commands/)
├── dot-github/
│   ├── workflows/
│   │   └── security-review.yml            ← GitHub Actions PR review workflow
│   └── labels.yml                         ← GitHub label definitions
├── dot-gitlab-ci.yml                      ← GitLab CI MR review pipeline
├── hooks/
│   ├── pre-commit                         ← Claude Code CLI hook
│   └── pre-commit-api.py                  ← Anthropic API hook
└── prompts/
    ├── SECURE_CODER_SYSTEM_PROMPT.md      ← Same as CLAUDE.md (for standalone use)
    └── PRE_COMMIT_REVIEW_PROMPT.md        ← Full reviewer prompt (for standalone use)
```

---

## GitHub Labels

`setup.sh` copies `.github/labels.yml` to your repo. Sync to GitHub:

```bash
npx github-label-sync \
  --access-token YOUR_GITHUB_TOKEN \
  --labels .github/labels.yml \
  your-org/your-repo
```

Labels included:

| Label | Color | Purpose |
|-------|-------|---------|
| `security-review-skip` | yellow | Bypass review for doc-only PRs |
| `security: critical` | red | PR has CRITICAL finding — do not merge |
| `security: high` | yellow | PR has HIGH finding — fix before main |
| `security: approved` | green | Review passed |
| `security-debt` | blue | Tracks `SECURITY-DEBT` comments in code |
| `security: false-positive` | light blue | Finding reviewed, not a real issue |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add language profiles, vulnerability categories, and framework rules.

PRs welcome for:
- New language profiles (Ruby/Rails, Rust, PHP/Laravel, C#/.NET, Kotlin)
- New vulnerability categories (OAuth misconfigs, mass assignment, gRPC security)
- CI/CD integrations (Jenkins, CircleCI, Azure DevOps, Bitbucket Pipelines)
- Framework-specific additions (Spring WebFlux, FastAPI advanced patterns, Next.js App Router)
