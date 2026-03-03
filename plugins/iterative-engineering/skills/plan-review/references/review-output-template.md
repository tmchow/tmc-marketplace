# Plan Review Output Template

Use this **exact format** when presenting synthesized review findings. Findings are grouped by priority, not by reviewer.

**IMPORTANT:** Use pipe-delimited markdown tables (`| col | col |`). Do NOT use ASCII box-drawing characters.

## Example

```markdown
## Plan Review Results

**Document:** docs/prd/2026-03-03-auth-prd.md
**Type:** PRD

**Reviewers:** prd-reviewer, coherence-reviewer, scope-guardian-reviewer
- scope-guardian-reviewer — PRD has 12 requirements across 3 priority levels with dependency conflicts

### HIGH

| # | Section | Issue | Reviewer | Confidence |
|---|---------|-------|----------|------------|
| 1 | Requirements | R3 (Core) depends on R7 (Nice) — can't build core without nice-to-have | scope-guardian-reviewer | 0.85 |
| 2 | Scope | "Real-time sync" is in-scope but no requirement addresses it | prd-reviewer | 0.82 |

### MEDIUM

| # | Section | Issue | Reviewer | Confidence |
|---|---------|-------|----------|------------|
| 3 | Architecture | Section says "stateless" but Session section describes server-side state | coherence-reviewer | 0.80 |
| 4 | Requirements | R5 and R8 overlap — unclear if they're the same requirement or distinct | coherence-reviewer, prd-reviewer | 0.75 |

### LOW

| # | Section | Issue | Reviewer | Confidence |
|---|---------|-------|----------|------------|
| 5 | Scope | Missing boundary around notification delivery mechanism | prd-reviewer | 0.65 |

### Coverage

- Suppressed: 1 finding below 0.50 confidence
- Residual concerns: Auth flow not fully specified, may need clarification during tech planning

---

> **Synthesis:** The plan has a priority dependency issue (HIGH) that blocks tech planning — R3 (Core) depends on R7 (Nice). The stateless/session contradiction should be clarified to avoid architectural confusion. R5/R8 overlap is worth cleaning up for clarity but doesn't block progress. The scope boundary items are improvements, not blockers.
```

## Formatting Rules

- **Pipe-delimited markdown tables** — never ASCII box-drawing characters
- **Priority-grouped sections** — `### HIGH`, `### MEDIUM`, `### LOW`. Omit empty priority levels.
- **Section column** shows which document section the issue lives in
- **Reviewer column** shows which persona(s) flagged the issue. Multiple reviewers = cross-reviewer agreement.
- **Confidence column** shows the finding's confidence score
- **Header includes** document path, type, and reviewer team with per-conditional justifications
- **Coverage section** — suppressed count and residual concerns
- **Synthesis uses blockquotes** — patterns, tensions between reviewers, quick wins. Not a binary verdict.
- **Horizontal rule** (`---`) separates findings from synthesis
- **`###` headers** for each section — never plain text headers
- **No fix order** — unlike code review, plan fixes are applied in-place, not in severity order
- **No verdict** — plans don't have a binary "ready/not ready". The synthesis helps the author decide what to address.
