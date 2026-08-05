# Business Logic Abuse Checklist

Language-agnostic. Apply to any endpoint/flow that is checkout, payment, KYC,
order/refund, auth, or an admin/approval action. A scanner (semgrep/gitleaks)
cannot see these — they require reasoning about the flow, not pattern-matching
a line of code.

## Flow integrity
- Step skipping: can a user jump from step 1 to step 3 without completing step 2
  (place order without payment, skip OTP)?
- State tampering: is flow state stored client-side (cookie/localStorage/hidden
  field) and trusted on the next request instead of re-derived server-side?
- Replay: can a successful payment/OTP/token be replayed for a different transaction?
- TOCTOU races: check-then-act gap exploitable with parallel requests (double-spend,
  duplicate coupon use, concurrent order edits)?

## Pricing & financial logic
- Can price/quantity/discount be modified in the request, and is it re-validated
  server-side against the catalog/DB rather than trusted from the client?
- Negative quantity/price handled (rejected, not silently accepted)?
- Coupon codes: single-use enforced atomically (DB constraint), or racy (read-check-write)?
- Refund logic: valid original transaction required? Refund amount capped at the
  original purchase amount?
- Wallet/credit: deduction+credit atomic in one DB transaction? Double-credit possible
  via retry/duplicate request?

## Limits & quotas
- Rate limits enforced per user *and* per IP? Bypassable by rotating IP/UA/account?
- Free-tier/usage limits enforced at the DB/service level, or only in client-visible
  app logic (client-bypassable)?
- File upload size/type/count enforced server-side, not just client-side validation?

## Workflow & role abuse
- Can an actor approve their own submission (self-approval)?
- Can a user act on another user's resource by guessing/enumerating an ID — horizontal
  privilege escalation (IDOR)?
- **Vertical privilege escalation**: can a lower-privileged actor gain a higher role/
  permission by tampering with a request — a client-supplied `role`/`isAdmin`/`scope`
  field in a body or JWT claim that the server trusts instead of deriving from the
  authenticated session server-side?
- **Mass assignment / overposting**: does a create/update endpoint bind the full
  request body (or an ORM `.update(**request.data)`-style call) to the model, letting
  a client set fields it was never meant to write (role, price, ownerId, verified flag)?
- **DB actions bypassing the authz layer**: does any code path run a raw query or
  direct ORM call that skips the tenant/ownership filter a higher layer normally
  applies — e.g. an admin/internal helper reused from a user-facing path without
  re-adding the `WHERE user_id = ?` / row-level scope?
- Do irreversible ops (delete, refund, payout) require a second factor/second approver?
- Can an approval step be bypassed by calling the post-approval endpoint directly?

## Time & scheduling
- Flash sale/limited inventory: is stock check + reservation atomic? Race to negative
  inventory possible?
- Are scheduled/internal jobs reachable via an exposed HTTP endpoint?
- Time-boxed offers/discounts: is server time authoritative, or is a client-supplied
  timestamp trusted?

## Reporting findings in this category

Use an abuse-scenario, not just a line citation — a business-logic finding is only
actionable if the reviewer can see how it's exploited:

```
ABUSE SCENARIO:
  Actor: [guest / authenticated user / seller / ops / insider]
  Goal: [financial gain / data theft / service disruption / privilege escalation]
  Steps:
    1. ...
    2. ...
  Expected (buggy) outcome: ...
  Business impact: [$ loss / N records exposed / inventory integrity broken / ...]
```

Cite this file (`prompts/BUSINESS_LOGIC_CHECKLIST.md`) as the rule violated, same as
a `CLAUDE.md` section citation for other finding categories.
