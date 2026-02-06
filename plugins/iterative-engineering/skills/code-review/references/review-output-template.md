# Code Review Output Template

Use this **exact format** when presenting synthesized review findings. Tables make issues scannable; the summary calls out cross-reviewer patterns.

**IMPORTANT:** Use pipe-delimited markdown tables (`| col | col |`). Do NOT use ASCII box-drawing characters (`┌─┬─┐`, `│`, `└─┴─┘`).

## Example

```markdown
## Code Review Results (Full)

### Correctness

| # | Location | Issue | Severity |
|---|----------|-------|----------|
| 1 | `task-service.ts:142` | Off-by-one in pagination — skips last page when total is exact multiple | High |
| 2 | `claim.ts:87` | Race condition if two agents claim simultaneously without transaction | High |
| 3 | `list.ts:201` | Filter ignores archived tasks when `--all` flag is set | Medium |

### Security

| # | Location | Vulnerability | Severity |
|---|----------|---------------|----------|
| 1 | `auth.ts:34` | User-supplied ID used directly in SQL query — injection risk | Critical |
| 2 | `config.ts:12` | API key logged at debug level | Medium |

### Performance

| # | Location | Issue | Impact |
|---|----------|-------|--------|
| 1 | `list.ts:156` | N+1 query — fetches dependencies per task in loop | High at scale |
| 2 | `export.ts:89` | Loads all events into memory — unbounded for large projects | Medium |

### Simplicity

| # | Location | Suggestion |
|---|----------|------------|
| 1 | `utils/format.ts` | Three formatting helpers do the same thing — consolidate | Low |
| 2 | `task-service.ts:200-240` | Nested conditionals could be early returns | Low |

### Testing

| # | Location | Gap |
|---|----------|-----|
| 1 | `claim.ts` | No test for concurrent claim scenario | High |
| 2 | `list.ts` | Filter edge cases (empty project, archived tasks) untested | Medium |

---

**Summary:** 11 issues found. 1 critical, 3 high, 4 medium, 3 low.

> **Cross-domain insight:** The SQL injection in `auth.ts:34` has no test coverage (flagged by both security and testing reviewers).
>
> **Fix order:** Critical/high security first → correctness bugs → add missing tests → simplicity cleanup.
```

## Formatting Rules

- **Pipe-delimited markdown tables** (`| col | col |` with `|---|---|` separators) — never ASCII box-drawing characters
- **Always include file:line location** for code review issues
- **Include severity** (Critical/High/Medium/Low) for correctness and security
- **Column headers vary by reviewer type** — adapt to what's useful (Issue/Severity, Suggestion, Gap, etc.)
- **No preamble before tables** — go straight from `###` header to the table
- **Summary uses blockquotes** for cross-domain insights and fix order
- **Horizontal rule** (`---`) separates issues from summary
- **`###` headers** for each reviewer section — never plain text headers
