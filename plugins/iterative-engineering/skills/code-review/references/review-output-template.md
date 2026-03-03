# Code Review Output Template

Use this **exact format** when presenting synthesized review findings. Findings are grouped by severity, not by reviewer.

**IMPORTANT:** Use pipe-delimited markdown tables (`| col | col |`). Do NOT use ASCII box-drawing characters.

## Example

```markdown
## Code Review Results (Full)

**Scope:** origin/main..HEAD (14 files, 342 lines)
**Intent:** Add order export endpoint with CSV and JSON format support

**Reviewers:** correctness, testing, maintainability, security, api-contract
- security — new public endpoint accepts user-provided format parameter
- api-contract — new /api/orders/export route with response schema

### P0 — Critical

| # | File | Issue | Reviewer | Confidence |
|---|------|-------|----------|------------|
| 1 | `orders_controller.rb:42` | User-supplied ID in account lookup without ownership check | security | 0.92 |

### P1 — High

| # | File | Issue | Reviewer | Confidence |
|---|------|-------|----------|------------|
| 2 | `export_service.rb:87` | Loads all orders into memory — unbounded for large accounts | performance | 0.85 |
| 3 | `export_service.rb:91` | No pagination — response size grows linearly with order count | api-contract, performance | 0.80 |

### P2 — Moderate

| # | File | Issue | Reviewer | Confidence |
|---|------|-------|----------|------------|
| 4 | `export_service.rb:45` | Missing error handling for CSV serialization failure | correctness | 0.75 |

### P3 — Low

| # | File | Issue | Reviewer | Confidence |
|---|------|-------|----------|------------|
| 5 | `export_helper.rb:12` | Format detection could use early return instead of nested conditional | maintainability | 0.70 |

### Pre-existing Issues

| # | File | Issue | Reviewer |
|---|------|-------|----------|
| 1 | `orders_controller.rb:12` | Broad rescue masking failed permission check | correctness |

### Coverage

- Suppressed: 2 findings below 0.50 confidence
- Residual risks: No rate limiting on export endpoint
- Testing gaps: No test for concurrent export requests

---

> **Verdict:** Ready with fixes
>
> **Reasoning:** 1 critical auth bypass must be fixed. The memory/pagination issues (P1) should be addressed for production safety.
>
> **Fix order:** P0 auth bypass → P1 memory/pagination → P2 error handling if straightforward
```

## Formatting Rules

- **Pipe-delimited markdown tables** — never ASCII box-drawing characters
- **Severity-grouped sections** — `### P0 — Critical`, `### P1 — High`, `### P2 — Moderate`, `### P3 — Low`. Omit empty severity levels.
- **Always include file:line location** for code review issues
- **Reviewer column** shows which persona(s) flagged the issue. Multiple reviewers = cross-reviewer agreement.
- **Confidence column** shows the finding's confidence score
- **Header includes** scope, intent, and reviewer team with per-conditional justifications
- **Pre-existing section** — separate table, no confidence column (these are informational)
- **Coverage section** — suppressed count, residual risks, testing gaps, failed reviewers
- **Summary uses blockquotes** for verdict, reasoning, and fix order
- **Horizontal rule** (`---`) separates findings from verdict
- **`###` headers** for each section — never plain text headers
