---
name: code-review
description: This skill should be used when the user says "review my code", "check these changes", or wants feedback on code before creating a PR. Also used after completing a task during iterative implementation.
---

# Code Review

Reviews code changes using dynamically selected reviewer personas. Spawns parallel sub-agents that return structured JSON, then merges and deduplicates findings into a single report.

## When to Use

- After completing a plan section (during `iterative:implementing` skill)
- Before finishing work and creating a PR
- When feedback is needed on any code changes
- Can be invoked standalone

## Severity Scale

All reviewers use P0–P3:

| Level | Meaning | Action |
|-------|---------|--------|
| **P0** | Critical breakage, exploitable vulnerability, data loss/corruption | Must fix before merge |
| **P1** | High-impact defect likely hit in normal usage, breaking contract | Should fix |
| **P2** | Moderate issue with meaningful downside (edge case, perf regression, maintainability trap) | Fix if straightforward |
| **P3** | Low-impact, narrow scope, minor improvement | User's discretion |

## Reviewers

8 personas in two tiers. See `references/persona-catalog.md` for the full catalog.

**Always-on (every review):**

| Agent | Focus |
|-------|-------|
| `correctness-reviewer` | Logic errors, edge cases, state bugs, error propagation |
| `testing-reviewer` | Coverage gaps, weak assertions, brittle tests |
| `maintainability-reviewer` | Coupling, complexity, naming, dead code, abstraction debt |

**Conditional (selected per diff):**

| Agent | Select when diff touches... |
|-------|---------------------------|
| `security-reviewer` | Auth, public endpoints, user input, permissions |
| `performance-reviewer` | DB queries, data transforms, caching, async |
| `api-contract-reviewer` | Routes, serializers, type signatures, versioning |
| `data-migrations-reviewer` | Migrations, schema changes, backfills |
| `reliability-reviewer` | Error handling, retries, timeouts, background jobs |

## Review Modes

### Full Mode (default)
Spawns all 3 always-on reviewers plus any applicable conditional reviewers.

### Quick Mode
Spawns 2-3 from the always-on tier. Auto-detect from changed files when the caller doesn't specify a type:

| Changed files | Reviewers |
|---------------|-----------|
| Auth/security code | correctness + security |
| Database/queries/migrations | correctness + performance |
| New feature code | correctness + testing |
| Refactoring (same tests, restructured code) | correctness + maintainability |
| Test files only | correctness + testing |
| Config/CI only | correctness (single reviewer — minimal review) |
| Mixed or unclear | Default to full mode |

## How to Run

### Stage 1: Determine scope

Compute the diff range, file list, and diff in a **single Bash call**. This minimizes permission prompts. Do not run extra commands.

Chain everything into one command using `&&` and labeled output markers (`BASE:`, `FILES:`, `DIFF:`) so you can parse each section:

- **From implementing (section-level):** The caller provides a baseline SHA. Use it directly.
- **From implementing (final/branch-level):** The caller provides the base branch. Compute merge-base inline.
- **Standalone:** Detect base branch and compute merge-base inline.
- **Explicit files:** If the caller specifies files, skip merge-base and use those directly.

**Standalone example** (single Bash call):

```
BASE=$(git merge-base HEAD $(git rev-parse --verify origin/main 2>/dev/null && echo origin/main || echo origin/master)) && echo "BASE:$BASE" && echo "FILES:" && git diff --name-only ${BASE}..HEAD -- . ':!*.md' && echo "DIFF:" && git diff -U10 ${BASE}..HEAD -- . ':!*.md'
```

Parse: `BASE:` = merge-base SHA, `FILES:` = file list, `DIFF:` = diff. If no commits on the branch, fall back to unstaged changes (`git diff -U10 -- . ':!*.md'`).

### Stage 2: Intent discovery

Understand what the change is trying to accomplish. Run a single bash call:

```
echo "BRANCH:" && git rev-parse --abbrev-ref HEAD && echo "COMMITS:" && git log --oneline ${BASE}..HEAD
```

Combined with conversation context (plan section summary, caller-provided description), write a 2-3 line intent summary:

```
Intent: Simplify tax calculation by replacing the multi-tier rate lookup
with a flat-rate computation. Must not regress edge cases in tax-exempt handling.
```

Pass this to every reviewer in their spawn prompt. Intent shapes *how hard each reviewer looks*, not which reviewers are selected.

**When intent is ambiguous:** Ask one question: "What is the primary goal of these changes?" Do not spawn reviewers until intent is established.

### Stage 3: Select reviewers

Read the diff and file list from Stage 1. The 3 always-on reviewers are automatic. For each conditional persona in the catalog (`references/persona-catalog.md`), decide whether the diff warrants it. This is agent judgment, not keyword matching.

Announce the team before spawning:

```
Review team:
- correctness (always)
- testing (always)
- maintainability (always)
- security — new endpoint in routes.rb accepts user-provided redirect URL
- data-migrations — adds migration 20260303_add_index_to_orders
```

This is progress reporting, not a blocking confirmation.

### Stage 4: Spawn sub-agents

Spawn each selected reviewer as a parallel sub-agent using the template in `references/subagent-template.md`. Each sub-agent receives:

1. Their persona file content (identity, failure modes, calibration, suppress conditions)
2. Shared diff-scope rules from `references/diff-scope.md`
3. The JSON output contract from `references/findings-schema.json`
4. Review context: intent summary, file list, diff

Sub-agents are **read-only**: they review and return structured JSON. They do not edit files, run commands, or propose refactors.

Each sub-agent returns JSON matching `references/findings-schema.json`:

```json
{
  "reviewer": "security",
  "findings": [...],
  "residual_risks": [...],
  "testing_gaps": [...]
}
```

### Stage 5: Merge findings

Convert multiple reviewer JSON payloads into one deduplicated, confidence-gated finding set.

1. **Validate.** Check each output against the schema. Drop malformed findings (missing required fields). Record the drop count.
2. **Confidence gate.** Suppress findings below 0.50 confidence. Record the suppressed count.
3. **Deduplicate.** Compute fingerprint: `normalize(file) + line_bucket(line, ±3) + normalize(title)`. When fingerprints match, merge: keep highest severity, keep highest confidence with strongest evidence, union evidence, note which reviewers flagged it.
4. **Separate pre-existing.** Pull out findings with `pre_existing: true` into a separate list.
5. **Sort.** Order by severity (P0 first) → confidence (descending) → file path → line number.
6. **Collect coverage data.** Union residual_risks and testing_gaps across reviewers.

### Stage 6: Synthesize and present

Assemble the final report using the template in `references/review-output-template.md`:

1. **Header.** Scope, intent, reviewer team with per-conditional justifications.
2. **Findings.** Grouped by severity (P0, P1, P2, P3). Each finding shows file, issue, reviewer(s), confidence.
3. **Pre-existing.** Separate section, does not count toward verdict.
4. **Coverage.** Suppressed count, residual risks, testing gaps, failed/timed-out reviewers.
5. **Verdict.** Ready to merge / Ready with fixes / Not ready. Fix order if applicable.

Do not include time estimates. **When invoked from `iterative:implementing`:** omit the `**Fix order:**` line — implementing handles prioritization through its own severity acceptance flow.

## Language-Agnostic

This skill does NOT use language-specific reviewer agents. Reviewers adapt their criteria to the language/framework based on project context (loaded automatically). This keeps the skill simple and avoids maintaining parallel reviewers per language.

## After Review

**When invoked from `iterative:implementing`:** return findings directly — implementing owns its own fix loop. Do not enter the standalone fix loop below.

**When invoked standalone or from `implementation-wrapup`:** run the standalone fix loop.

### Standalone Fix Loop

After presenting findings and verdict (Stage 6), handle the full fix-review cycle.

#### Step 5: Severity Acceptance

**This is its own prompt — do not combine it with next-step options.** Present severity acceptance whenever the review has findings at ANY severity. Do not interpret "no P0/P1" as "clean" — clean means zero findings. If zero findings, skip to Step 8. **Use the interactive question tool** for all severity acceptance prompts.

**When P0 or P1 issues exist:**

Present an interactive choice:
- **Fix P0 + P1 (Recommended)** — N P0, N P1
- **Choose which severity levels to fix** — select from all levels
- **Skip fixes**

If the user accepts the recommendation, fix P0 + P1. If they choose, present an interactive multi-select of severity levels with findings:
- P0 (N issues)
- P1 (N issues)
- P2 (N issues)
- P3 (N issues)

**When only P2/P3 issues exist:**

Present an interactive choice:
- **Choose which severity levels to fix** — select from P2, P3
- **Proceed without fixes (Recommended)**

#### Step 6: Apply Fixes via Subagent

Fix only the selected severities. Spawn one or more subagents with the filtered findings, affected file paths, and diff range from Stage 1. Each subagent applies fixes, runs tests, and commits.

Wait for all fixes to complete before proceeding.

#### Step 7: Re-review Offer

After fixes land, present an interactive choice:
- **Run another review round (Recommended)** — verify fixes and check for new issues
- **Proceed without re-review**

If another round: run the full Stage 1–Step 7 flow again (fresh sub-agents, fresh scope).

#### Step 8: Post-fix Options

After the fix-review cycle completes (clean verdict or user chose to stop), present next steps via the interactive question tool.

**On a feature branch:**
- **Create a PR (Recommended)** — push and open a pull request
- **Continue without PR** — stay on the branch
- **Exit** — done for now

**On main/master:**
- **Continue** — proceed with next steps
- **Exit** — done for now

If "Create a PR": push the branch and use `gh pr create` with a title and summary derived from the branch changes.

## Fallback

If the platform doesn't support parallel sub-agents, run reviewers sequentially. Everything else (stages, output format, merge pipeline) stays the same.
