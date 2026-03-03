# Code Review v2 — Overhaul Proposal

## Problem

The current code-review skill spawns a fixed set of 5 reviewers (correctness, security, performance, simplicity, testing) on every run. This has three structural problems:

1. **Wrong reviewers for the code.** A database migration gets a simplicity-reviewer and testing-reviewer when it needs a data-migrations expert. A frontend state refactor gets a security-reviewer scanning for SQL injection. The fixed roster wastes reviewer slots on low-signal analysis and misses domain-specific issues that a specialized reviewer would catch.

2. **Prose output can't be deduplicated.** When correctness and testing both flag the same untested edge case, the orchestrator must manually reconcile free-text findings. There's no structured mechanism to detect duplicates, gate on confidence, or suppress noise. The quality of the final report depends entirely on how well the orchestrator ad-hocs the merge.

3. **Agent Teams add complexity without proportional value.** The teammate messaging, cross-validation instructions, TeamCreate/TeamDelete lifecycle, and shutdown/retry logic account for ~30% of the SKILL.md. In practice, cross-validation between teammates rarely fires meaningfully, and the team teardown is a persistent source of bugs. The same review quality is achievable with simpler parallel sub-agents.

## Goals

- Spawn the right reviewers for each diff, not a fixed roster
- Structured JSON output from every reviewer with confidence scores
- Deterministic dedup and noise suppression before the user sees anything
- Simpler execution model (parallel sub-agents, no Agent Teams)
- Keep the standalone fix loop, implementing integration, and scope efficiency
- Dramatically improve persona quality via identity framing and confidence calibration

## Architecture Overview

The new pipeline has 7 stages. Stages 1-4 replace the current Steps 1-2. Stages 5-6 replace the current Steps 3-4. Stage 7 is new.

```
1. Scope       → single bash call (unchanged)
2. Intent      → read commits + context, write 2-line summary (new)
3. Selection   → orchestrator reads diff, selects from persona catalog (new)
4. Spawn       → parallel sub-agents with JSON contract (replaces Agent Teams)
5. Merge       → validate, dedup, confidence-gate, reconcile severity (new)
6. Synthesize  → assemble final report (simplified)
7. Fix loop    → severity acceptance, subagent fixes, re-review (unchanged)
```

### What changes

| Current | v2 |
|---------|-----|
| Fixed 5 reviewers always | 3 always-on + up to 5 conditional from 8-persona catalog |
| Agent Teams with messaging | Parallel sub-agents returning JSON |
| Prose output, manual reconciliation | JSON schema with confidence, fingerprint-based dedup |
| No intent step | Intent discovery before selection |
| Orchestrator ad-hocs merge | Structured merge pipeline with confidence gating |
| Critical/High/Medium/Low severity | P0/P1/P2/P3 (shorter, sortable, unambiguous) |

### What stays

- **Scope step** — single bash call with `BASE:`, `FILES:`, `DIFF:` markers. This is already efficient and shouldn't change.
- **Standalone fix loop** (Steps 5-8) — severity acceptance, subagent fixes, re-review offer, post-fix options. Kept intact.
- **Implementing integration** — when invoked from `iterative:implementing`, return findings directly; skip the fix loop.
- **Quick mode** — fewer reviewers for incremental reviews. The selection logic naturally handles this (smaller diff → fewer conditional reviewers trigger).
- **Diff-anchored scope model** — primary/secondary/pre-existing tiers. Moves into each persona's instructions rather than being repeated in the SKILL.md.
- **Review output template** — updated to reflect new severity labels and JSON-derived structure, but same visual format (tables, `###` headers, summary blockquote).

---

## Stage 2: Intent Discovery

Before selecting reviewers, the orchestrator must understand what the change is trying to accomplish. Reviewing code without knowing intent catches syntax-level bugs but misses intent-vs-implementation mismatches.

**Mechanism.** A single bash call:

```bash
echo "BRANCH:" && git rev-parse --abbrev-ref HEAD && echo "COMMITS:" && git log --oneline ${BASE}..HEAD
```

Combined with any conversation context (plan section summary, caller-provided description), the orchestrator writes a 2-3 line intent summary:

```
Intent: Simplify tax calculation by replacing the multi-tier rate lookup
with a flat-rate computation. Author believes behavior is equivalent for
all current product categories. Must not regress edge cases in tax-exempt handling.
```

This summary is passed to every reviewer in their spawn prompt as the `intent` field. It shapes *how hard each reviewer looks* and *what they focus on*, not which reviewers are selected.

**When intent is ambiguous.** If the orchestrator can't derive intent from commits + context, ask one question:

> What is the primary goal of these changes?

Do not spawn reviewers until intent is established.

---

## Stage 3: Persona Selection

### Catalog

8 personas, organized in two tiers:

**Always-on (3).** Spawned on every review regardless of diff content.

| Persona | Focus | Why always |
|---------|-------|-----------|
| `correctness` | Logic, edge cases, error handling, intent compliance | Every change can introduce logic bugs |
| `testing` | Coverage gaps, weak assertions, missing edge case tests | Untested code is the most common escaped defect class |
| `maintainability` | Coupling, complexity, naming, dead code, abstraction debt | Every change affects long-term maintenance cost |

**Conditional (5).** Spawned when the orchestrator identifies relevant patterns in the diff.

| Persona | Trigger examples |
|---------|-----------------|
| `security` | Auth middleware modified, new public endpoint, user input handling, permission checks |
| `performance` | Database queries, ORM calls, loop-heavy data transforms, caching layer changes |
| `api-contract` | Route definitions, serializer/interface changes, event schemas, exported type signatures |
| `data-migrations` | Migration files, schema changes, backfill scripts |
| `reliability` | Background jobs, queue consumers, retry logic, async handlers, timeout/idempotency code |

### Selection mechanism

The orchestrator reads the full diff and file list, then reasons about which conditional personas are warranted. This is agent judgment, not keyword matching or a scoring formula.

Before spawning, the orchestrator announces the team with a one-line justification per conditional reviewer:

```
Review team:
- correctness (always)
- testing (always)
- maintainability (always)
- security — new endpoint in routes.rb accepts user-provided redirect URL
- data-migrations — adds migration 20260303_add_index_to_orders
```

This is progress reporting, not a blocking confirmation. The user sees who's being spawned and why, which makes the selection auditable and debuggable.

### Quick mode

When invoked from `iterative:implementing` for incremental section reviews, spawn only the always-on reviewers (or a subset of 2 based on change type, matching current Quick mode logic). Conditional reviewers only fire in Full mode.

### Why not a scoring formula

A numeric formula (`path_points + risk_points + intent_points + scope_points` with tier-based thresholds) is deterministic but fragile. File paths are unreliable signals — critical auth code lives in `users_controller.rb`, not `auth_helper.rb`. Our orchestrator can read the actual diff, so it has far more signal than file paths alone. Agent judgment with structured justification output is more accurate and more debuggable than a formula.

### Why not keyword matching

Pattern-matching keywords in file paths or diff content (e.g., `auth|token|secret` → spawn security) is brittle. A test file importing an auth helper would trigger security. A comment mentioning "token" would trigger it. The orchestrator reading and understanding the code is strictly better.

---

## Stage 4: Persona Definitions

### New structure

Each persona follows a 4-section structure designed to activate expert reasoning rather than checklist execution:

```markdown
# [Name]

[2-sentence identity statement — who you ARE, written in second person.
 Activates expert framing rather than checklist execution.]

## What you're hunting for

[3-5 concrete, specific failure modes. Not categories — specific patterns
 recognizable on sight. These are the highest-value section.]

## Confidence calibration

[Explicit per-persona guidance on what raises confidence from 0.50 to 0.90.
 What evidence makes a finding certain vs. speculative.
 This varies by domain — a security finding at 0.60 is actionable;
 a performance finding at 0.60 is probably noise.]

## What you don't flag

[Front-loaded suppress conditions. The biggest quality problem in AI code
 review is noise. Leading with what NOT to flag trains the persona to
 self-filter before generating, not after.]
```

### Why this structure

**Identity framing over checklist execution.** "You think like an attacker looking for the one exploitable path" produces different (better) results from "Verify authorization checks at server-side boundaries." Identity activates the model's understanding of what that expert would attend to.

**Concrete failure modes over abstract categories.** "User-controlled input reaching a database query without parameterization" is more recognizable on sight than "injection and unsafe deserialization." Specific patterns let the model pattern-match against the actual diff.

**Per-persona confidence calibration.** The current system has a uniform "skip if confidence below 80%" rule. But confidence means different things per domain:
- Security: 0.60 confidence on an auth bypass is worth reporting — the cost of a miss is high
- Performance: 0.60 confidence on a micro-optimization is noise — the cost of a miss is low
- Correctness: confidence should depend on whether the reviewer can trace the full execution path

The new structure makes each persona calibrate its own confidence thresholds with domain-specific guidance.

**Front-loaded suppress conditions.** Currently "Suppress When" is buried after Focus, Checklist, Anti-patterns, and Evidence Required. By the time the reviewer reaches it, it has already generated findings. Moving suppress conditions to the top trains the persona to self-filter before generating.

### Diff scope instructions

The current reviewer agents each contain a `## Scope` section explaining the primary/secondary/pre-existing tier model (~10 lines per agent). This is invariant across all reviewers.

In v2, move this into a shared reference file (`references/diff-scope.md`) that gets included in the sub-agent prompt template. Removes duplication, ensures consistency, and frees up persona files to focus on domain expertise.

### Personas to create (new)

These don't exist today and need to be written from scratch:

- `api-contract-reviewer.md` — backward compatibility, breaking changes, versioning
- `data-migrations-reviewer.md` — migration safety, rollback paths, schema compatibility
- `reliability-reviewer.md` — retry storms, idempotency, race conditions, partial failures

### Personas to rewrite

These exist today but need the new structure (identity framing, failure modes, confidence calibration, front-loaded suppress):

- `correctness-reviewer.md`
- `security-reviewer.md`
- `performance-reviewer.md`
- `testing-reviewer.md`
- `simplicity-reviewer.md` → renamed to `maintainability-reviewer.md` (broader scope: coupling, naming, dead code, abstraction debt — not just "is this over-engineered")

---

## Stage 4b: Sub-agent Prompt Template

Each sub-agent receives a structured prompt assembled from:

1. **Persona file** — their identity, failure modes, calibration, suppress conditions
2. **Shared diff-scope instructions** — primary/secondary/pre-existing tier model
3. **JSON output contract** — the schema they must return
4. **Review context** — scope, intent summary, file list, diff

Template:

```
You are a specialist code reviewer.

<persona>
{persona file content}
</persona>

<scope-rules>
{diff-scope.md content}
</scope-rules>

<output-contract>
Return JSON only. No prose outside JSON.
JSON must match the findings schema.
Suppress any finding below your stated confidence floor.
If no findings, return "findings": [] plus residual_risks and testing_gaps.
</output-contract>

<review-context>
Intent: {intent summary}
Changed files: {file list}
Diff:
{diff content}
</review-context>
```

Sub-agents are read-only: they do not edit files, run commands, or propose refactors. They review and return structured findings.

---

## Stage 5: JSON Output Schema

### Reviewer output

```json
{
  "reviewer": "security",
  "findings": [
    {
      "title": "Unparameterized user ID in account lookup",
      "severity": "P0",
      "file": "src/controllers/accounts.rb",
      "line": 42,
      "why_it_matters": "User-supplied ID passes directly to find() without ownership check — any authenticated user can read any account",
      "suggested_fix": "Scope query to current_user.accounts.find() or add explicit ownership assertion",
      "confidence": 0.85,
      "evidence": [
        "params[:id] passed to Account.find() on line 42",
        "No current_user scope in surrounding method"
      ],
      "pre_existing": false
    }
  ],
  "residual_risks": [
    "No test for concurrent account deletion race"
  ],
  "testing_gaps": [
    "Missing negative test: non-owner accessing account returns 403"
  ]
}
```

### Field reference

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `reviewer` | string | yes | Which persona produced this output |
| `findings` | array | yes | List of findings (empty array if none) |
| `findings[].title` | string | yes | Short, specific issue title |
| `findings[].severity` | enum | yes | `P0` / `P1` / `P2` / `P3` |
| `findings[].file` | string | yes | Relative file path |
| `findings[].line` | integer | yes | Line number of the issue |
| `findings[].why_it_matters` | string | yes | Impact and failure mode — not "what's wrong" but "what breaks" |
| `findings[].suggested_fix` | string | no | Concrete minimal fix. Omit if no good fix is obvious — a bad suggestion is worse than none |
| `findings[].confidence` | float | yes | 0.00–1.00, per persona calibration |
| `findings[].evidence` | array[string] | yes | Code-grounded evidence (snippets, references). Min 1 item. |
| `findings[].pre_existing` | boolean | yes | `true` if issue exists in unchanged code unrelated to the current diff |
| `residual_risks` | array[string] | yes | Risks the reviewer noticed but couldn't confirm as findings |
| `testing_gaps` | array[string] | yes | Missing test coverage the reviewer identified |

### What was dropped from comparable schemas

| Dropped field | Why |
|---------------|-----|
| `persona` | Redundant with `reviewer` |
| `domain` | Redundant — a security reviewer's findings are security domain by definition |
| `scope_slice` | We don't split one persona across multiple scope chunks |
| `coverage.paths_reviewed` | Not actionable — if a reviewer missed a file, this list doesn't tell you |
| `risk_tags` | Preflight routing metadata, not finding-level data |

### What was added

| Added field | Why |
|-------------|-----|
| `pre_existing` | Forces reviewer to decide at finding time. Currently the orchestrator guesses during merge. |
| `suggested_fix` optional | Required `suggested_fix` pressures reviewers to generate filler ("add validation"). Optional means they only suggest when they have a concrete fix. |

### Severity scale (P0–P3)

| Level | Meaning | Action |
|-------|---------|--------|
| **P0** | Critical breakage, exploitable vulnerability, data loss/corruption | Must fix before merge |
| **P1** | High-impact defect likely hit in normal usage, breaking contract | Should fix |
| **P2** | Moderate issue with meaningful downside (edge case, perf regression, maintainability trap) | Fix if straightforward |
| **P3** | Low-impact, narrow scope, minor improvement | User's discretion |

P0–P3 is shorter, unambiguous, and sorts naturally. "Critical" vs "High" requires label reasoning; "P0" vs "P1" is purely ordinal.

---

## Stage 6: Merge Pipeline

### Purpose

Convert multiple reviewer JSON payloads into one deduplicated, confidence-gated, severity-consistent finding set.

### Steps

**1. Validate.** Check each reviewer's output against the schema. Drop malformed findings (missing required fields). Record the drop count for the coverage gaps section.

**2. Confidence gate.** Suppress findings below 0.50 confidence. Record the suppressed count.

**3. Deduplicate.** Compute fingerprint per finding:

```
fingerprint = normalize(file) + line_bucket(line, ±3) + normalize(title)
```

`line_bucket` groups lines within ±3 of each other to catch the same issue reported at slightly different line numbers. `normalize` lowercases and strips whitespace.

When fingerprints match, merge into one finding:
- **Severity:** keep highest
- **Confidence:** keep highest backed by strongest evidence
- **Evidence:** union unique evidence snippets
- **Suggested fix:** keep the most specific, concrete one
- **Reviewers:** note which reviewers independently flagged it (cross-reviewer agreement)

**4. Separate pre-existing.** Pull out all findings with `pre_existing: true` into a separate list. These don't count toward the verdict.

**5. Sort.** Order merged findings by: severity (P0 first) → confidence (descending) → file path → line number.

**6. Collect residual risks and testing gaps.** Union across all reviewers, dedup by similarity.

### Coverage gap accounting

Always track and report:
- Failed or timed-out reviewers
- Dropped malformed findings count
- Suppressed low-confidence findings count

This goes in the final output so the user knows what the review did and didn't cover.

---

## Stage 7: Output Format

The orchestrator assembles the final report from merged findings. The visual format stays close to the current review output template (tables under `###` headers) but is now generated from structured data rather than ad-hoc reconciliation.

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

...

### P3 — Low

...

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
> **Fix order:** P0 auth bypass → P1 memory/pagination → P2 items if straightforward
```

### Changes from current output format

- **Reviewer team announced** at the top with per-reviewer justification
- **Intent shown** so the user can verify the review understood the change
- **Severity headers are P0/P1/P2/P3** instead of reviewer-grouped sections
- **Cross-reviewer agreement** shown inline (e.g., "api-contract, performance") — instead of a separate synthesis note
- **Confidence column** shown so the user can calibrate trust
- **Coverage section** replaces ad-hoc "Summary" — explicitly shows what was suppressed and what wasn't covered
- **Pre-existing section** preserved (already exists in current format)

---

## What Doesn't Change

### Standalone fix loop (Steps 5–8)

Severity acceptance → subagent fixes → re-review offer → post-fix options. This is our differentiator and stays exactly as-is, except:
- Severity labels change from Critical/High/Medium/Low to P0/P1/P2/P3
- The re-review spawns the same reviewer team as the initial review (fresh sub-agents, fresh scope)

### Implementing integration

When invoked from `iterative:implementing`, return findings directly. Implementing owns its own severity acceptance and fix loop. The `**Fix order:**` line is omitted. This behavior is unchanged.

### Scope step

Single bash call with `BASE:`, `FILES:`, `DIFF:` markers. Unchanged.

### Review modes

Full mode (default) and Quick mode. Full spawns all applicable reviewers (3 always + conditionals). Quick spawns 2-3 from the always-on tier based on change type. The Quick mode table stays the same.

---

## Implementation Plan

### Task 1: Create shared references

**Files to create:**
- `skills/code-review/references/diff-scope.md` — the primary/secondary/pre-existing tier model, extracted from current agent definitions
- `skills/code-review/references/findings-schema.json` — the JSON schema from this proposal
- `skills/code-review/references/subagent-template.md` — the prompt template for spawning sub-agents

**Why first:** These are dependencies for both the persona rewrites and the SKILL.md rewrite.

### Task 2: Create new persona definitions

**Files to create:**
- `agents/api-contract-reviewer.md`
- `agents/data-migrations-reviewer.md`
- `agents/reliability-reviewer.md`

Each follows the new 4-section structure (identity, failure modes, confidence calibration, suppress conditions). These are net-new personas that don't exist today.

### Task 3: Rewrite existing personas

**Files to modify:**
- `agents/correctness-reviewer.md` — rewrite to new structure
- `agents/security-reviewer.md` — rewrite to new structure
- `agents/performance-reviewer.md` — rewrite to new structure
- `agents/testing-reviewer.md` — rewrite to new structure
- `agents/simplicity-reviewer.md` → rename to `agents/maintainability-reviewer.md`, rewrite to new structure with broader scope (coupling, naming, dead code, abstraction debt)

Each rewrite:
1. Adds identity framing (2-sentence expert identity)
2. Replaces Focus Areas / Checklist / Anti-patterns with 3-5 concrete failure modes
3. Adds per-persona confidence calibration section
4. Moves suppress conditions to front-loaded "What you don't flag" section
5. Removes the Scope section (now in shared `diff-scope.md`)
6. Removes the Output Format section (now in shared `subagent-template.md`)
7. Removes the Severity Scale section (now in shared `findings-schema.json`)
8. Updates severity labels to P0/P1/P2/P3

### Task 4: Create persona catalog

**File to create:**
- `skills/code-review/references/persona-catalog.md`

Contains:
- The always-on tier (correctness, testing, maintainability) with brief descriptions
- The conditional tier (security, performance, api-contract, data-migrations, reliability) with trigger descriptions
- Team sizing guidance (always 3 + up to 2-3 conditional in Full mode, 2-3 from always-on in Quick mode)
- Instructions for the orchestrator: read the diff, select conditionals based on what you observe, announce the team with justifications

### Task 5: Rewrite SKILL.md

**File to modify:**
- `skills/code-review/SKILL.md`

Major changes:
1. Replace Steps 1-4 with the new 6-stage pipeline (scope → intent → selection → spawn → merge → synthesize)
2. Remove all Agent Team references (TeamCreate, TeamDelete, shutdown requests, cross-validation instructions)
3. Add intent discovery step
4. Add persona selection step with catalog reference
5. Add sub-agent spawn step with JSON contract reference
6. Add merge pipeline step
7. Update severity labels to P0/P1/P2/P3 throughout
8. Update Quick mode to use always-on tier subset
9. Keep Steps 5-8 (fix loop) with P0/P1/P2/P3 labels
10. Update Fallback section (no Agent Teams to fall back from — the primary model is already sub-agents)
11. Keep implementing integration behavior

### Task 6: Update review output template

**File to modify:**
- `skills/code-review/references/review-output-template.md`

Update the example to match the new output format: P0/P1/P2/P3 severity headers, reviewer team announcement, intent line, confidence column, coverage section.

### Task 7: Update strategy doc

**File to modify:**
- `docs/CODE_REVIEW_STRATEGY.md`

Rewrite to reflect:
- Dynamic persona selection from 8-persona catalog
- Intent discovery rationale
- Sub-agent execution model (no Agent Teams)
- JSON output + merge pipeline rationale
- New persona file structure rationale
- Updated synthesis description

### Task 8: Update README

**File to modify:**
- `README.md`

Update:
- Code-review skill description (dynamic personas, structured output)
- Reviewer table (8 personas, always/conditional tiers)
- Architecture section (sub-agents, JSON, merge pipeline)
- Remove references to Agent Teams in code-review context

### Task 9: Verify plan-review is unaffected

The plan-review skill has its own set of 4 reviewer agents (specificity, completeness, clarity, complexity). This proposal does NOT change plan-review. Verify that:
- Plan-review agents are not modified
- Plan-review SKILL.md references are not broken by the agent renames
- The `simplicity-reviewer.md` → `maintainability-reviewer.md` rename doesn't affect plan-review (it shouldn't — plan-review uses `complexity-reviewer.md`, not `simplicity-reviewer.md`)

---

## Migration Notes

### Severity label migration

All references to Critical/High/Medium/Low must change to P0/P1/P2/P3:
- SKILL.md severity scale table
- All 8 persona definitions
- Review output template
- Fix loop severity acceptance prompts (Step 5)
- Strategy doc

### Agent file rename

`simplicity-reviewer.md` → `maintainability-reviewer.md`. This requires updating:
- `SKILL.md` reviewer table
- `SKILL.md` Quick mode table (anywhere "simplicity" appears)
- Strategy doc reviewer table
- README reviewer descriptions

### Fallback section simplification

The current Fallback section says "if Agent Teams are unavailable, use sub-agents." Since v2 uses sub-agents as the primary model, the Fallback section changes to: "if the platform doesn't support parallel sub-agents, run reviewers sequentially." This is a much simpler fallback.

---

## Risks

**Agent judgment for selection may be inconsistent.** Two runs on the same diff might select different conditional reviewers. Mitigation: the justification announcement makes selection visible and auditable. If consistency becomes a problem, add deterministic rules for the highest-signal triggers (e.g., "always spawn data-migrations if any file matches `**/migrate/**`") while keeping agent judgment for ambiguous cases.

**JSON output compliance.** Sub-agents may not always produce valid JSON. Mitigation: the merge pipeline validates and drops malformed output, reporting the count in coverage gaps. The orchestrator can also retry a failed sub-agent once before giving up.

**Persona count increase.** Going from 5 to 8 personas means more files to maintain. Mitigation: the new structure is shorter per-persona (4 focused sections vs. 6 sections with overlap). The shared references (diff-scope, schema, template) eliminate duplication. Net line count per persona should decrease.

**P0-P3 label transition.** Users familiar with Critical/High/Medium/Low need to learn P0-P3. Mitigation: the output format includes descriptive headers (`P0 — Critical`, `P1 — High`) during the transition.
