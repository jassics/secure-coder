# Contributing to Security Champion

Thank you for helping make this better. Every new language profile, vulnerability category, or framework rule reduces the security burden on developers everywhere.

---

## What you can contribute

- **New language profiles** — Ruby/Rails, Rust, PHP/Laravel, C#/.NET, Kotlin, Swift
- **New vulnerability categories** — race conditions, business logic flaws, OAuth misconfigs, gRPC security
- **Framework-specific additions** — Spring WebFlux, Next.js App Router, FastAPI advanced patterns, Gin/Echo (Go)
- **Infra additions** — Terraform misconfigs, Kubernetes RBAC, GitHub Actions secrets exposure
- **CI/CD integrations** — Jenkins, CircleCI, Bitbucket Pipelines, Azure DevOps
- **False positive fixes** — if a checklist item fires incorrectly in a specific context, fix the wording to add precision

---

## How the prompts are structured

There are two prompts. Every contribution touches one or both.

### `CLAUDE.md` / `prompts/SECURE_CODER_SYSTEM_PROMPT.md`

The **always-on secure coder**. This is the AI's persona and ruleset when writing code.

Structure:
```
IDENTITY                    ← Do not change
PHASE 0 — CONTEXT BOOTSTRAP ← Do not change
CORE BEHAVIOR RULES         ← Do not change without discussion
LANGUAGE-SPECIFIC RULES     ← Where most contributions go
  └── ### JAVA
  └── ### PYTHON
  └── ### TYPESCRIPT / NODE.JS
  └── ### REACT
  └── ### GO
  └── ### [YOUR LANGUAGE HERE]
GRAPHQL SECURITY            ← Protocol-level, not language-specific
API SECURITY                ← Cross-cutting
INFRASTRUCTURE & DEPENDENCY RULES
LOGGING & MONITORING STANDARDS
WHEN TO STOP AND ASK
SECURITY DEBT TRACKING
```

### `dot-claude/commands/security-review.md` / `prompts/PRE_COMMIT_REVIEW_PROMPT.md`

The **pre-commit and CI reviewer**. Checklists + verdict logic.

Structure:
```
ROLE                        ← Do not change
STEP 1 — GATHER CONTEXT     ← Do not change
STEP 2 — DETECT LANGUAGES   ← Checklist section per language
  └── JAVA CHECKLIST
  └── PYTHON CHECKLIST
  └── TYPESCRIPT / NODE.JS CHECKLIST
  └── REACT CHECKLIST
  └── GO CHECKLIST
  └── [YOUR LANGUAGE CHECKLIST]
  └── GRAPHQL CHECKLIST
  └── INFRASTRUCTURE & SECRETS CHECKLIST
STEP 3 — FINDINGS REPORT    ← Do not change format
STEP 4 — VERDICT            ← Do not change verdict logic
STEP 5 — TICKETS            ← Do not change
REVIEWER RULES              ← Do not change
```

---

## Adding a new language profile

This is the most common contribution. Follow this template exactly — consistency matters because the AI reads these rules literally.

### Step 1 — Add to `CLAUDE.md`

Add a new `###` section under `LANGUAGE-SPECIFIC SECURITY RULES`. Follow this structure:

```markdown
### LANGUAGE (Framework1 / Framework2 / Plain Language)

#### Injection
- **SQL**: [parameterized query guidance with code example]
- **Command injection**: [safe exec pattern with code example]
- **[Other injection relevant to this language]**: ...

#### Deserialization (if applicable)
- [guidance]

#### Authentication & Authorization
- [framework-specific auth patterns]

#### JWT (if applicable)
- [algorithm, claims validation, code example]

#### Cryptography
- Password hashing: [recommended library + settings]
- Encryption: [recommended approach]
- Random: [secure vs insecure]
- TLS: [version enforcement]

#### SSRF
- [URL validation pattern for this language's HTTP client]

#### Logging
- [structured logging library recommendation]
- [what NOT to log]

#### Dependencies
- [audit tool for this ecosystem]
- [lock file requirement]

#### [Framework]-Specific (if applicable)
- [framework-specific security settings]
```

**Rules for writing rules:**

1. Every rule must have a concrete consequence if violated (what attack does this enable?).
2. Provide a code example for every non-obvious rule. Use `// SECURITY:` comments.
3. Name the specific library/function to use AND the one to avoid. "Use X, never Y."
4. Do not write vague rules like "validate all inputs." Write "validate X at Y with Z library."
5. Keep it scannable — the AI reads this at coding time. Dense paragraphs get skipped.

**Example of a good rule:**
```markdown
- **SQL**: Always use `database/sql` with `$1`/`?` placeholders. Never `fmt.Sprintf` into SQL strings:
  ```go
  // SECURITY: Parameterized query — Sprintf into SQL causes injection
  row := db.QueryRow("SELECT id FROM users WHERE email = $1", email)
  ```
```

**Example of a bad rule (too vague):**
```markdown
- Be careful with SQL queries and make sure to sanitize user input properly.
```

---

### Step 2 — Add to the reviewer checklist

Add a new checklist section to `dot-claude/commands/security-review.md` (and `prompts/PRE_COMMIT_REVIEW_PROMPT.md` — keep them in sync).

Follow this template:

```markdown
#### [LANGUAGE] CHECKLIST
- [ ] SQL: [parameterized? no string concat?]
- [ ] Commands: [safe exec? no shell=True equivalent?]
- [ ] Auth: [framework auth applied to new routes/handlers?]
- [ ] JWT: [algorithm enforced? claims validated?]
- [ ] Crypto: [correct algorithm? secure random?]
- [ ] TLS: [version enforced? verify not disabled?]
- [ ] SSRF: [URL validated? private IPs blocked?]
- [ ] Path traversal: [safe path join + prefix check?]
- [ ] Logging: [structured? no PII/tokens?]
- [ ] Errors: [stack traces not returned to client?]
- [ ] New dependencies: [audit tool clean?]
- [ ] Secrets: [no hardcoded credentials?]
- [ ] [Framework-specific item 1]
- [ ] [Framework-specific item 2]
```

**Rules for checklist items:**

1. Each item is a yes/no question. The AI checks it against the diff.
2. Include both what to check for AND the failure condition: `SQL: parameterized? no string concat?`
3. Order: Injection → Auth → Crypto → SSRF → Headers → Logging → Dependencies → Secrets
4. Aim for 12–20 items. Too few misses things; too many causes the AI to skim.
5. Include framework-specific items at the bottom (e.g., Django `DEBUG=False`, Spring `@PreAuthorize`).

---

## Adding a new vulnerability category

If you want to add a vulnerability class that cuts across languages (e.g., OAuth misconfiguration, mass assignment, insecure file upload):

1. Add a new top-level `##` section in `CLAUDE.md` after the language sections, following the same pattern as `## GRAPHQL SECURITY` or `## API SECURITY`.
2. Add a corresponding checklist section in the reviewer, following the same pattern as `#### GRAPHQL CHECKLIST`.
3. Reference the new section from any language profile where it's relevant.

---

## Updating existing rules

If a rule is wrong, too broad, or causing false positives:

1. Open an issue describing the false positive with a concrete example.
2. In your PR, tighten the language to add the missing condition. Don't delete rules — narrow them.
3. If a library recommendation has changed (e.g., a formerly-safe library is now deprecated), update both the positive recommendation and the "never use" example.

---

## Keeping `CLAUDE.md` and the prompts in sync

`CLAUDE.md` and `prompts/SECURE_CODER_SYSTEM_PROMPT.md` are intentionally identical — one is for Claude Code (auto-read), one is for standalone use. When you edit one, edit the other. The CI will diff them and fail if they diverge.

Similarly, `dot-claude/commands/security-review.md` and `prompts/PRE_COMMIT_REVIEW_PROMPT.md` must stay in sync.

---

## PR checklist

Before opening a PR:

- [ ] Language profile added to both `CLAUDE.md` and `prompts/SECURE_CODER_SYSTEM_PROMPT.md`
- [ ] Checklist added to both `dot-claude/commands/security-review.md` and `prompts/PRE_COMMIT_REVIEW_PROMPT.md`
- [ ] All code examples use `// SECURITY:` prefix comments
- [ ] Every rule names a specific library/function (not generic guidance)
- [ ] Checklist items are yes/no questions with both the check and the failure condition
- [ ] README language coverage table updated
- [ ] No existing rules removed (only narrowed or corrected)

---

## Testing your contribution

The best way to test a new language profile is to write a small deliberately-insecure snippet in that language, run `/security-review` or the pre-commit hook against it, and verify your new checklist items catch the issues.

Example test cases to write for any new language:

| Test | Should catch |
|------|-------------|
| Raw SQL with user input concatenated | SQLi checklist item |
| `os.system("rm " + userInput)` equivalent | Command injection item |
| Password hashed with MD5 | Crypto checklist item |
| JWT decoded without algorithm check | JWT checklist item |
| Hardcoded `api_key = "sk-..."` | Secrets checklist item |
| HTTP client called without timeout | SSRF / resource exhaustion item |

---

## Questions

Open an issue. Tag it `question` or `language-request`.
