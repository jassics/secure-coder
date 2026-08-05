---
description: Run a full secure-code review of the current diff against the secure-coder CLAUDE.md rules
---

Review the currently staged/unstaged changes (`git diff HEAD` and `git diff --cached`) as a Senior Security Engineer, per the rules in `CLAUDE.md`.

0. If this diff touches a business-critical flow (checkout, payment, KYC, order/refund, auth, admin/approval), ask in one batch and wait for answers before proceeding: user roles that can reach this flow, primary threat actor (external attacker / malicious authenticated user / insider / bot), sensitive data involved, blast radius if abused. Skip silently for non-critical diffs.

For each file changed:

1. Identify the language/framework and apply the matching profile from `CLAUDE.md`.
2. Check for: injection (SQL/NoSQL/command/SSTI/XXE), broken auth/authz (including IDOR), insecure JWT handling, XSS, SSRF, insecure deserialization, weak crypto/random, hardcoded secrets, insecure HTTP/CORS headers, unsafe logging (secrets/PII in logs), GraphQL-specific issues (introspection, depth/complexity limits, field-level authz), and dependency/supply-chain risk.
3. For business-critical flows identified in step 0, additionally apply the full checklist in `prompts/BUSINESS_LOGIC_CHECKLIST.md` — flow integrity, pricing/financial logic, limits & quotas, workflow & role abuse, time & scheduling. Report these using the abuse-scenario format from that file (actor, goal, steps, business impact) instead of a bare file:line citation.
4. For every finding, output:
   - **File:line**
   - **Severity** (CRITICAL/HIGH/MEDIUM/LOW)
   - **Rule violated** (cite the CLAUDE.md section, e.g. "JWT — Java", or `prompts/BUSINESS_LOGIC_CHECKLIST.md` for business-logic findings)
   - **Fix** — the concrete secure replacement, ready to apply
5. If a finding is a pre-existing issue outside this diff's scope, tag it `SECURITY-DEBT` per the CLAUDE.md convention instead of blocking the commit on it.

End with a one-line verdict: **PASS** (no CRITICAL/HIGH findings) or **BLOCK** (list the blocking findings). Offer to apply the fixes directly.
