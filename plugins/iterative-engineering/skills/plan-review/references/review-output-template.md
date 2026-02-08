# Plan Review Output Template

Use this **exact format** when presenting synthesized review findings. Tables make issues scannable; the summary calls out cross-reviewer patterns.

**IMPORTANT:** Use pipe-delimited markdown tables (`| col | col |`). Do NOT use ASCII box-drawing characters (`┌─┬─┐`, `│`, `└─┴─┘`).

## Example

```markdown
## Plan Review Results

### Clarity

| # | Issue | Suggestion |
|---|-------|------------|
| 1 | "minus comments and checkpoints" is ambiguous | Clarify: "excluding comments and checkpoints for those children" |
| 2 | Approach B conclusion dangles without rationale | Expand reasoning or remove |
| 3 | "all other task show fields" contradicts the explicit exclusions | Replace with an explicit field list |

### Completeness

| # | Gap | Impact |
|---|-----|--------|
| 1 | `blocked_by` shape undefined — `string[]`? Resolved objects? | Affects JSON contract |
| 2 | Subtask ordering not specified | Agents may depend on deterministic ordering |

### Specificity

| # | Issue | What's needed |
|---|-------|---------------|
| 1 | Service method signature missing | Concrete interface for new/modified method |
| 2 | Test scenarios too vague ("verify output shape") | Name specific scenarios: blocked subtask, mixed statuses, etc. |

### YAGNI

| # | Over-specification | Simpler alternative |
|---|--------------------|---------------------|
| 1 | Re-listing all 16+ fields | Just say "same as task show minus comments/checkpoints" |
| 2 | Non-parent task edge case spelled out | Empty array follows naturally — no design needed |

---

**Summary:** 9 issues across 4 categories.

> **High confidence** (multiple reviewers): Field list needs to be explicit or reference existing schema — don't do both.
>
> **Tension** (Completeness vs YAGNI): Completeness wants edge case detail; YAGNI says defer to tech design. Resolution: pin down the JSON contract shape, defer implementation specifics.
>
> **Quick wins:** Clarify `--deep` without `--json` behavior, specify subtask sort order, define `blocked_by` as `string[]` of task IDs.
```

## Formatting Rules

- **Pipe-delimited markdown tables** (`| col | col |` with `|---|---|` separators) — never ASCII box-drawing characters
- **Column headers vary by reviewer type** — adapt to what's useful (Issue/Suggestion, Gap/Impact, etc.)
- **No preamble before tables** — go straight from `###` header to the table
- **Summary uses blockquotes** for high-confidence items, tensions, and quick wins
- **Horizontal rule** (`---`) separates issues from summary
- **`###` headers** for each reviewer section — never plain text headers
