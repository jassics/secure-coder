# secure-coder

An always-on "security champion" persona for AI coding agents. It takes the burden of application/API security off developers who aren't security specialists — folding OWASP ASVS 5.0, OWASP SAMM v2, NIST SSDF (SP 800-218), and Secure-by-Design practice into every line of code an agent writes, reviews, or lets get committed.

Covers: injection (SQLi, command, XXE, SSTI), broken authn/authz, insecure JWT, XSS, SSRF, insecure deserialization, weak crypto, secrets in code, insecure HTTP/CORS headers, unsafe logging of PII/secrets, and GraphQL/API-specific issues (introspection, IDOR, rate limiting). Profiles for Java, Python, TypeScript/Node, React, and Go.

## How it works

| Layer | File | What it does |
|---|---|---|
| Always-on persona | `CLAUDE.md` | Auto-loaded by Claude Code every session. The agent runs a mandatory context-bootstrap phase (detects auth model, DB layer, trust boundaries, asks clarifying questions), then applies the matching language security profile to everything it writes. |
| Interactive review | `.claude/commands/security-review.md` | `/security-review` — reviews the current diff on demand, mid-session, and can fix findings inline. |
| Local commit gate | `hooks/pre-commit` | Installed as `.git/hooks/pre-commit`. Runs `claude --print` headlessly against the staged diff before every commit; blocks on CRITICAL/HIGH findings. |
| PR gate (optional) | `.github/workflows/security-review.yml` | Runs the same review server-side on every PR, posts findings as a comment, fails the check on blocking findings. Can't be bypassed with `--no-verify` since it runs in CI. **Requires an `ANTHROPIC_API_KEY` repo secret** — if none is set, the job posts a one-line skip notice and passes, so adopting this repo never forces a team to buy an API key just to get the local persona and pre-commit gate working. |
| Any other agent | `prompts/system-prompt.md` | Same content as `CLAUDE.md`, for pasting into Cursor/Copilot/Windsurf custom instructions or a raw API system prompt. |

## Install

```bash
git clone https://github.com/jassics/secure-coder ~/tools/secure-coder
cd ~/your-project
~/tools/secure-coder/setup.sh
```

The always-on persona and local pre-commit gate work immediately — no API key needed, they use your own logged-in `claude` CLI. Optionally, add `ANTHROPIC_API_KEY` to your repo's GitHub Actions secrets to also enable the CI-level PR gate; without it, that job just posts a skip notice. Commit the installed files either way.

If you're not using Claude Code, skip `setup.sh` and just paste `prompts/system-prompt.md` into your tool's custom-instructions field.

## Why this matters for developers who aren't security specialists

A developer who doesn't know what SSRF or a JWT `alg: none` attack is shouldn't have to become a security engineer to ship safely. `secure-coder` puts that judgment in the agent instead: it asks the questions a security reviewer would ask *before* writing auth/data-handling code, refuses "quick and insecure" requests, explains every security-relevant decision inline (`// SECURITY: ...`), and won't let a commit through with an unresolved CRITICAL/HIGH finding — without the developer needing to know which OWASP category applies.

## Overriding a block

The PR gate respects a `security-review-skip` label (add it with written justification in the PR description — it's an audit trail, not a bypass). The local git hook respects `git commit --no-verify` (discouraged; the PR gate still catches it).

## Extending

Add a new language profile by appending a `### LANGUAGE` section to `CLAUDE.md` following the existing structure (Injection / Authn-Authz / Crypto / SSRF / Logging / Dependencies), then re-run `setup.sh` in projects that need it.
