---
name: plan-review
description: >
  Review PRDs, brainstorm docs, tech plans, design docs, specs, or any planning document for issues. This skill should be used whenever the user wants feedback, critique, or a quality check on an existing planning or requirements document — even if they don't use the word "review." Common triggers include: "review the plan", "check the PRD", "critique my tech plan", "what's wrong with this plan", "poke holes in the requirements", "is this plan solid", "take a look at this spec", "give feedback on the brainstorm", or pointing to a doc file and asking if anything is off. Also triggers after writing a PRD or tech plan (to review what was just created), or when invoked by brainstorming or tech-planning skills. Do NOT trigger for code review (PRs, diffs, source files), writing/creating new plans, debugging, or reviewing non-planning documents (READMEs, CLAUDE.md, test coverage).
---

# Plan Review

Reviews PRDs, brainstorms, and technical plans using dynamically selected reviewer personas. Spawns parallel sub-agents that return structured JSON, then merges and deduplicates findings into a single report.

## When to Use

- After writing a PRD
- After writing a technical plan
- When feedback is needed on any planning document
- Can be invoked standalone or called by `iterative:brainstorming`/`iterative:tech-planning` skills

## Priority Scale

All reviewers use HIGH/MEDIUM/LOW:

| Level | Meaning | Action |
|-------|---------|--------|
| **HIGH** | Blocks execution; cannot start the next step without resolving | Must fix before proceeding |
| **MEDIUM** | Creates risk; work can start but likely leads to rework or confusion | Should fix |
| **LOW** | Improvement opportunity; plan works but could be clearer or tighter | Author's discretion |

## Reviewers

6 personas in three tiers. See `references/persona-catalog.md` for the full catalog.

**Document-type (exactly 1 — selected by document type):**

| Agent | Selected when | Identity |
|-------|--------------|----------|
| `prd-reviewer` | Document is a PRD or brainstorm | Senior product leader evaluating product document quality |
| `tech-plan-reviewer` | Document is a tech plan | Implementer evaluating whether they can code from this plan |

**Always-on (every review):**

| Agent | Focus |
|-------|-------|
| `coherence-reviewer` | Internal consistency, contradictions, terminology drift, structural issues |

**Conditional (selected per document):**

| Agent | Select when document... |
|-------|------------------------|
| `skeptic-reviewer` | Proposes abstractions, multi-layer architecture, plugin systems, or infrastructure ahead of need |
| `feasibility-reviewer` | Is a tech plan that proposes architecture, external integrations, or performance constraints |
| `scope-guardian-reviewer` | Is a PRD with multiple priority levels and potential conflicts, unclear scope boundaries, many requirements where goal alignment isn't obvious, or goals that don't connect to requirements |

## Review Scope

The document type naturally regulates the review. A simple PRD gets 2 reviewers (prd-reviewer + coherence-reviewer). A complex tech plan with architecture decisions gets 4 (tech-plan-reviewer + coherence-reviewer + skeptic-reviewer + feasibility-reviewer). No separate "mode" is needed.

## How to Run

### Stage 1: Identify document

Identify the document to review from argument, conversation context, or ask user. Determine the **document type** — PRD, brainstorm, or tech plan — from filename, content, and context. Treat brainstorm documents and PRDs synonymously. Record the **document path** and **document type**.

Read the full document content. This is needed for both reviewer selection and spawning.

### Stage 2: Select reviewers

Read the document content from Stage 1. The document-type reviewer and coherence are automatic. For each conditional persona in the catalog (`references/persona-catalog.md`), decide whether the document warrants it. This is agent judgment, not keyword matching.

Announce the team before spawning:

```
Review team:
- prd-reviewer (document-type)
- coherence-reviewer (always)
- scope-guardian-reviewer — PRD has 12 requirements across 3 priority levels with dependency conflicts
```

This is progress reporting, not a blocking confirmation.

### Stage 3: Spawn sub-agents

Spawn each selected reviewer as a parallel sub-agent using the template in `references/subagent-template.md`. Each sub-agent receives:

1. Their persona file content (identity, failure modes, calibration, suppress conditions)
2. The JSON output contract from `references/findings-schema.json`
3. Review context: document type, document path, document content

Sub-agents are **read-only**: they review and return structured JSON. They do not edit files, run commands, or propose fixes.

Each sub-agent returns JSON matching `references/findings-schema.json`:

```json
{
  "reviewer": "prd-reviewer",
  "findings": [...],
  "residual_concerns": [...]
}
```

### Stage 4: Merge findings

Convert multiple reviewer JSON payloads into one deduplicated, confidence-gated finding set.

1. **Validate.** Check each output against the schema. Drop malformed findings (missing required fields). Record the drop count.
2. **Confidence gate.** Suppress findings below 0.50 confidence. Record the suppressed count.
3. **Deduplicate.** Compute fingerprint: `normalize(section) + line_bucket(line, ±5) + normalize(title)`. When fingerprints match, merge: keep highest priority, keep highest confidence with strongest evidence, union evidence, note which reviewers flagged it.
4. **Promote residual concerns.** Scan residual_concerns for issues that overlap with findings from other reviewers or that describe concrete blocking risks (missing dependencies, unowned prerequisites, timeline impossibilities). Promote these to MEDIUM findings with confidence 0.55-0.65. A residual concern that corroborates an existing finding strengthens the case; one that identifies a distinct blocking risk deserves to be surfaced rather than buried.
5. **Sort.** Order by priority (HIGH first) → confidence (descending) → document order.
6. **Collect coverage data.** Union remaining (non-promoted) residual_concerns across reviewers.

### Stage 5: Synthesize and present

Assemble the final report using the template in `references/review-output-template.md`:

1. **Header.** Document path, type, reviewer team with per-conditional justifications.
2. **Findings.** Grouped by priority (HIGH, MEDIUM, LOW). Each finding shows section, issue, reviewer(s), confidence.
3. **Coverage.** Suppressed count, residual concerns, failed/timed-out reviewers.
4. **Synthesis.** Patterns, tensions between reviewers, quick wins. Not a binary verdict — plans don't have "ready/not ready." The synthesis helps the author decide what to address.

Do not include time estimates.

## After Review

**When invoked from `iterative:brainstorming` or `iterative:tech-planning`:** return findings directly — the calling skill owns the fix loop and workflow transitions. Do not enter the standalone fix loop below.

**When invoked standalone:** run the standalone fix loop.

### Standalone Fix Loop

After presenting the synthesized findings (Stage 5), offer to fix issues when running standalone. Plan fixes are text edits with low cascading risk — keep the loop simple.

If zero findings, the review is done — no further prompts needed.

#### Step 6: Fix Offer

**Use the platform's interactive question tool** — `AskUserQuestion` (Claude Code) or `request_user_input` (Codex). Both platforms provide an automatic "Other" free-form option — do not add one manually.

Present a **single prompt** listing all priority levels with findings. No intermediate "choose which..." step.

**Claude Code** — use `AskUserQuestion` with `multiSelect: true`:

When HIGH issues exist, pre-check the HIGH option:
- ☑ **HIGH (Recommended)** — N issues that block execution
- ☐ **MEDIUM** — N issues
- ☐ **LOW** — N issues

When only MEDIUM/LOW issues exist, nothing pre-checked:
- ☐ **MEDIUM** — N issues
- ☐ **LOW** — N issues

Only include priority levels that have findings.

**Codex** — use `request_user_input` (single-select, build combined options):

When HIGH issues exist:
- **Fix HIGH (Recommended)** — N issues
- **Fix HIGH + MEDIUM** — N issues
- **Fix all** — N issues
- **Skip fixes**

When only MEDIUM/LOW issues exist:
- **Fix MEDIUM only** — N issues
- **Fix MEDIUM + LOW** — N issues
- **Skip fixes**

Only include options where findings exist at those levels. Omit options that would duplicate another (e.g., if no LOW, omit "Fix all" since it equals the line above).

#### Step 7: Apply Fixes

Fix only the selected priorities. Spawn a single subagent with the filtered findings, document path, and document type. The subagent applies targeted fixes, preserves the document's voice and decisions, and commits.

Wait for the subagent to complete.

#### Step 8: Done

After fixes land (or user skipped), present an interactive choice:

- **Another review round** — fresh reviewers on the updated document
- **Done** — review complete

If another round: run the full Stage 1–Step 8 flow again. No workflow transition options — the user knows what to do next.

## Fallback

If the platform doesn't support parallel sub-agents, run reviewers sequentially. Everything else (stages, output format, merge pipeline) stays the same.
