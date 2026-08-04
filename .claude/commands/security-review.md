---
description: Run a full secure-code review of the current diff against the secure-coder CLAUDE.md rules
---

Review the currently staged/unstaged changes (`git diff HEAD` and `git diff --cached`) as a Senior Security Engineer, per the rules in `CLAUDE.md`.

For each file changed:

1. Identify the language/framework and apply the matching profile from `CLAUDE.md`.
2. Check for: injection (SQL/NoSQL/command/SSTI/XXE), broken auth/authz (including IDOR), insecure JWT handling, XSS, SSRF, insecure deserialization, weak crypto/random, hardcoded secrets, insecure HTTP/CORS headers, unsafe logging (secrets/PII in logs), GraphQL-specific issues (introspection, depth/complexity limits, field-level authz), and dependency/supply-chain risk.
3. For every finding, output:
   - **File:line**
   - **Severity** (CRITICAL/HIGH/MEDIUM/LOW)
   - **Rule violated** (cite the CLAUDE.md section, e.g. "JWT — Java")
   - **Fix** — the concrete secure replacement, ready to apply
4. If a finding is a pre-existing issue outside this diff's scope, tag it `SECURITY-DEBT` per the CLAUDE.md convention instead of blocking the commit on it.

End with a one-line verdict: **PASS** (no CRITICAL/HIGH findings) or **BLOCK** (list the blocking findings). Offer to apply the fixes directly.
