# Deferred Findings Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow the code review synthesizer to defer findings so they're excluded from severity acceptance counts and fix lists.

**Architecture:** Mirror the pre-existing findings pattern — the synthesizer separates deferred findings during Stage 6. Severity acceptance in both code-review and implementing skills filters them out. No schema changes needed.

**Tech Stack:** Markdown skill files only (no code changes)

---

### Task 1: Add deferral guidance to Stage 6 in code-review SKILL.md

**Files:**
- Modify: `plugins/iterative-engineering/skills/code-review/SKILL.md:144-153`

**Step 1: Add deferral substep to Stage 6**

Insert after item 3 ("Pre-existing") and before item 4 ("Coverage") in the Stage 6 numbered list at line 144. Renumber subsequent items.

Change:

```markdown
### Stage 6: Synthesize and present

Assemble the final report using the template in `references/review-output-template.md`:

1. **Header.** Scope, intent, reviewer team with per-conditional justifications.
2. **Findings.** Grouped by severity (P0, P1, P2, P3). Each finding shows file, issue, reviewer(s), confidence.
3. **Pre-existing.** Separate section, does not count toward verdict.
4. **Coverage.** Suppressed count, residual risks, testing gaps, failed/timed-out reviewers.
5. **Verdict.** Ready to merge / Ready with fixes / Not ready. Fix order if applicable.
```

To:

```markdown
### Stage 6: Synthesize and present

Assemble the final report using the template in `references/review-output-template.md`:

1. **Header.** Scope, intent, reviewer team with per-conditional justifications.
2. **Findings.** Grouped by severity (P0, P1, P2, P3). Each finding shows file, issue, reviewer(s), confidence.
3. **Pre-existing.** Separate section, does not count toward verdict.
4. **Deferred.** Move findings that should not be fixed in this cycle into a separate "Deferred Findings" section with a one-line reason per finding. Defer when: (a) the finding targets an acknowledged placeholder explicitly planned for a future task, (b) the fix would be immediately overwritten by planned work, or (c) the review context makes clear the code is intentional scaffolding. Deferred findings keep their original numbering, do not appear in severity tables, and do not count toward the verdict. This is orchestrator judgment based on plan context that sub-agents lack.
5. **Coverage.** Suppressed count, residual risks, testing gaps, failed/timed-out reviewers.
6. **Verdict.** Ready to merge / Ready with fixes / Not ready. Fix order if applicable.
```

**Step 2: Commit**

```bash
git add plugins/iterative-engineering/skills/code-review/SKILL.md
git commit -m "feat: add deferral guidance to code-review Stage 6"
```

---

### Task 2: Add Deferred Findings section to output template

**Files:**
- Modify: `plugins/iterative-engineering/skills/code-review/references/review-output-template.md`

**Step 1: Add Deferred Findings section to the example**

Insert after the P3 table (line 42) and before the Pre-existing Issues section (line 44):

```markdown
### Deferred Findings

| # | File | Issue | Reason | Reviewer | Confidence |
|---|------|-------|--------|----------|------------|
| 6 | `export_job.rb:30` | No retry logic for failed exports | Placeholder — retry wired in task 3.4 | reliability | 0.85 |
```

**Step 2: Update verdict to reflect deferral**

Change the verdict example to show deferred findings are excluded:

```markdown
> **Verdict:** Ready with fixes
>
> **Reasoning:** 1 critical auth bypass must be fixed. The memory/pagination issues (P1) should be addressed for production safety. 1 finding deferred (placeholder for task 3.4).
>
> **Fix order:** P0 auth bypass → P1 memory/pagination → P2 error handling if straightforward
```

**Step 3: Add formatting rule for Deferred section**

Add to the Formatting Rules list:

```markdown
- **Deferred section** — separate table between severity tables and pre-existing, includes Reason column. Deferred findings keep original `#` numbering. Omit section if no findings are deferred. Deferred findings do not count toward severity table counts or verdict.
```

**Step 4: Commit**

```bash
git add plugins/iterative-engineering/skills/code-review/references/review-output-template.md
git commit -m "feat: add Deferred Findings section to review output template"
```

---

### Task 3: Update severity acceptance in code-review SKILL.md

**Files:**
- Modify: `plugins/iterative-engineering/skills/code-review/SKILL.md:170-196`

**Step 1: Add deferral exclusion rule**

Insert after the first paragraph of Step 5 (line 172), before "When P0 or P1 issues exist":

```markdown
**Exclude deferred findings from all counts and fix lists.** Only non-deferred findings count toward severity level totals. If deferring all findings at a severity level leaves it empty, omit that level. If all findings across all levels are deferred, treat the review as clean and skip to Step 8.
```

**Step 2: Commit**

```bash
git add plugins/iterative-engineering/skills/code-review/SKILL.md
git commit -m "feat: exclude deferred findings from code-review severity acceptance"
```

---

### Task 4: Update severity acceptance in implementing SKILL.md

**Files:**
- Modify: `plugins/iterative-engineering/skills/implementing/SKILL.md:136-159`

**Step 1: Add deferral exclusion rule**

Insert after the first paragraph of the Severity Acceptance section (line 138), before "When Critical or High issues exist":

```markdown
**Exclude deferred findings from all counts and fix lists.** Only non-deferred findings count toward severity level totals. If deferring all findings at a severity level leaves it empty, omit that level. If all findings across all levels are deferred, treat the review as clean and skip to the next-steps prompt.
```

**Step 2: Commit**

```bash
git add plugins/iterative-engineering/skills/implementing/SKILL.md
git commit -m "feat: exclude deferred findings from implementing severity acceptance"
```

---

### Task 5: Update strategy doc

**Files:**
- Modify: `plugins/iterative-engineering/docs/CODE_REVIEW_STRATEGY.md:87-88`

**Step 1: Add Finding Deferral section**

Insert after the "Standalone Fix Loop" section (line 87) and before "Design Principles" (line 89):

```markdown
## Finding Deferral

During synthesis (Stage 6), the orchestrator may defer findings that target acknowledged placeholders or scaffolding explicitly planned for future work. Deferred findings are separated in the output (like pre-existing findings), excluded from severity counts, and not passed to the fix loop. This is orchestrator judgment based on plan context that sub-agents lack. No schema changes are needed — deferral happens after the merge pipeline, during synthesis.
```

**Step 2: Commit**

```bash
git add plugins/iterative-engineering/docs/CODE_REVIEW_STRATEGY.md
git commit -m "docs: add finding deferral section to code review strategy"
```
