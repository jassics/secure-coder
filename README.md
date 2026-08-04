# secure-coder

An always-on "security champion" persona for AI coding agents. It takes the burden of application/API security off developers who aren't security specialists — folding OWASP ASVS 5.0, OWASP SAMM v2, NIST SSDF (SP 800-218), and Secure-by-Design practice into every line of code an agent writes, reviews, or lets get committed.

Covers: injection (SQLi, command, XXE, SSTI), broken authn/authz, insecure JWT, XSS, SSRF, insecure deserialization, weak crypto, secrets in code, insecure HTTP/CORS headers, unsafe logging of PII/secrets, and GraphQL/API-specific issues (introspection, IDOR, rate limiting). Profiles for Java, Python, TypeScript/Node, React, and Go.

## How it works

| Layer | File | What it does |
|---|---|---|
| Always-on persona | `CLAUDE.md` | Auto-loaded by Claude Code every session. The agent runs a mandatory context-bootstrap phase (detects auth model, DB layer, trust boundaries, asks clarifying questions), then applies the matching language security profile to everything it writes. |
| Interactive review | `.claude/commands/security-review.md` | `/security-review` — reviews the current diff on demand, mid-session, and can fix findings inline. |
| Deterministic backstop | `gitleaks` + `semgrep` (called from both hooks and CI) | Secret scan and OWASP-ruleset SAST on the staged/PR diff, independent of LLM judgment. Blocks on real findings even if the AI layer is unavailable, skipped, or wrong. Local hooks run these if the binaries are installed (degrade gracefully with a warning if not); CI always installs and runs both. |
| Local commit gate | `hooks/pre-commit` | Installed as `.git/hooks/pre-commit` when the `claude` CLI is present. Runs the deterministic scans above, then `claude --print` against the staged diff using `prompts/PRE_COMMIT_REVIEW_PROMPT.md`; reports a full CRITICAL→INFO tiered finding list, blocks only on high-confidence CRITICAL (deterministic findings block regardless of confidence). |
| Local commit gate (no Claude Code CLI) | `hooks/pre-commit-api.py` | Same deterministic scans, same prompt template, same tiering/block rule, but calls the Anthropic API directly (`pip install anthropic` + `ANTHROPIC_API_KEY`) — for machines without the Claude Code CLI installed. `setup.sh` installs this automatically as the active hook if `claude` isn't found. |
| PR gate (optional AI layer, deterministic layer always on) | `.github/workflows/security-review.yml` | Always runs gitleaks + semgrep server-side (no API key needed) and fails the check hard on findings. Additionally runs the same AI review as the local hooks (same prompt template, same block rule) and posts findings as a PR comment. Can't be bypassed with `--no-verify` since it runs in CI. The AI layer **requires an `ANTHROPIC_API_KEY` repo secret** — if none is set, that part posts a skip notice and passes, but the deterministic scans still ran and still gate the PR. |
| Any other agent | `prompts/SECURE_CODER_SYSTEM_PROMPT.md` | Same content as `CLAUDE.md`, for pasting into Cursor/Copilot/Windsurf custom instructions or a raw API system prompt. |
| Shared review checklist | `prompts/PRE_COMMIT_REVIEW_PROMPT.md` | The tiered-findings template both `hooks/pre-commit` and `hooks/pre-commit-api.py` load and fill in with the staged diff — one checklist to edit instead of two inline copies. |

## Install

```bash
git clone https://github.com/jassics/secure-coder ~/tools/secure-coder
cd ~/your-project
~/tools/secure-coder/setup.sh
```

The always-on persona and local pre-commit gate work immediately — no API key needed, they use your own logged-in `claude` CLI. Optionally, add `ANTHROPIC_API_KEY` to your repo's GitHub Actions secrets to also enable the CI-level PR gate; without it, that job just posts a skip notice. Commit the installed files either way.

If you're not using Claude Code, skip `setup.sh` and just paste `prompts/SECURE_CODER_SYSTEM_PROMPT.md` into your tool's custom-instructions field. If you want the pre-commit gate without the Claude Code CLI, point `.git/hooks/pre-commit` at `hooks/pre-commit-api.py` instead (needs `pip install anthropic` + `ANTHROPIC_API_KEY`).

## Why this matters for developers who aren't security specialists

A developer who doesn't know what SSRF or a JWT `alg: none` attack is shouldn't have to become a security engineer to ship safely. `secure-coder` puts that judgment in the agent instead: it asks the questions a security reviewer would ask *before* writing auth/data-handling code, refuses "quick and insecure" requests, explains every security-relevant decision inline (`// SECURITY: ...`), and won't let a commit through with a hardcoded secret, a deterministic SAST hit, or an unresolved high-confidence CRITICAL finding — without the developer needing to know which OWASP category applies or which scanner to run.

## Overriding a block

The PR gate respects a `security-review-skip` label (add it with written justification in the PR description — it's an audit trail, not a bypass; the deterministic gitleaks/semgrep scans still ran and are visible in the check history even if the label skips the AI comment). The local git hook respects `git commit --no-verify` (discouraged; it skips both the deterministic scans and the AI review locally, but the PR gate re-runs both server-side).

## Extending

Add a new language profile by appending a `### LANGUAGE` section to `CLAUDE.md` following the existing structure (Injection / Authn-Authz / Crypto / SSRF / Logging / Dependencies), then re-run `setup.sh` in projects that need it.
