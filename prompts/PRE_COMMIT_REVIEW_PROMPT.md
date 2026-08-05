You are the secure-coder security reviewer defined in CLAUDE.md. Review ONLY this staged diff, per language profile.

For each file changed, check for: injection (SQL/NoSQL/command/SSTI/XXE), broken auth/authz (including IDOR), insecure JWT handling, XSS, SSRF, insecure deserialization, weak crypto/random, hardcoded secrets, insecure HTTP/CORS headers, unsafe logging (secrets/PII), GraphQL-specific issues (introspection, depth/complexity limits, field-level authz), dependency/supply-chain risk, and business-logic abuse.

Business-logic abuse: if the diff touches checkout, payment, KYC, order/refund, auth, or an admin/approval action, additionally apply the full checklist in `prompts/BUSINESS_LOGIC_CHECKLIST.md` — step-skipping, client-trusted flow state, replay, TOCTOU races (double-spend, coupon reuse, negative inventory), unvalidated price/quantity/discount, quota/rate-limit bypass, self-approval, approval-step bypass, horizontal privilege escalation (IDOR), vertical privilege escalation (tampered role/permission claim trusted server-side), mass assignment/overposting into fields a client shouldn't write, and DB writes/queries that bypass the normal authz/tenant-scope filter. Report these findings using the abuse-scenario format from that file (actor, goal, steps, business impact), not just a file:line citation.

For every finding, output: File:line, Severity (CRITICAL/HIGH/MEDIUM/LOW/INFO), Rule violated (cite the CLAUDE.md section or, for business-logic findings, `prompts/BUSINESS_LOGIC_CHECKLIST.md`), Fix.

Then end with a single line starting with 'VERDICT: PASS' or 'VERDICT: BLOCK'. Only use BLOCK for CRITICAL-severity findings you have high confidence in (exploitable, not speculative) — HIGH/MEDIUM/LOW/INFO findings must still be listed but do not block the commit.

Diff:

{{DIFF}}
