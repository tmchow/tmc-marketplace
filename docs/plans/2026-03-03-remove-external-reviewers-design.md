# Remove External Model Reviewers

## Problem

The code-review and plan-review skills include external model CLI integration (Gemini, Codex, Claude) for "model-diverse" perspectives. This adds substantial complexity:

- Self-identification logic (determine own model family, exclude matching CLI)
- CLI availability checks (`which` calls)
- User prompting logic (multi-select when 2+ CLIs, yes/no when 1)
- Diff/prompt file staging (`.external-review-diff.txt`, `.external-review-prompt.txt`, `.external-doc-review-prompt.txt`)
- Per-CLI invocation syntax (each has different flags and behaviors)
- Result parsing and reformatting
- Cleanup of staged files
- Graceful degradation for missing CLIs
- Extensive documentation across 6 files

The ROI doesn't justify the complexity. Remove it.

## Scope

**Remove from:**
1. `skills/code-review/SKILL.md` — External Reviewers section, Step 2b, embedded prompt template, references in Review Modes/Synthesis/Fallback
2. `skills/plan-review/SKILL.md` — External Reviewers section, self-identification step, reviewer selection prompt, Step 2b, references in Fallback
3. `docs/CODE_REVIEW_STRATEGY.md` — External Reviewers section and all subsections, references in Synthesis/Design Principles/Unified Prompt Design
4. `docs/PLAN_REVIEW_STRATEGY.md` — External Reviewers section and all subsections, references in Synthesis/Design Principles/Prompt Design/Temporary File Naming
5. `README.md` — External Reviewers section, references in skill descriptions and strategy doc summaries

**Simplifications enabled:**
- Code review Full mode = "all 5 built-in reviewers" (no external opt-in language)
- Plan review runs built-in reviewers automatically (no reviewer selection prompt)
- Synthesis step merges findings from one source (built-in team), not two
- No staged files to create or clean up
- No self-identification or CLI detection

**Unchanged:**
- All 9 reviewer agent definitions (5 code + 4 plan)
- Review output template
- Standalone fix loop (Steps 5-8)
- Quick mode logic
- Agent team creation/teardown
- Fallback to parallel subagents (minus external CLI sentence)

## Decisions

- Plan-review: built-in reviewers run automatically with no prompt (no reviewer selection step needed)
- Code-review: Full mode runs 5 built-in reviewers directly (Step 2b disappears entirely)
- Strategy docs: remove external reviewer sections, simplify design principles to focus on built-in team architecture
- README: remove External Reviewers section, simplify skill descriptions
