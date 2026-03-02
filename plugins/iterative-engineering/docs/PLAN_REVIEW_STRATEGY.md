# Plan Review Strategy

## Overview

The plan review system offers 4 built-in domain experts and up to 2 external reviewers from different model families (one of 3 supported CLIs is always self-excluded), designed for PRDs, brainstorms, and technical plans. All reviewer sources are opt-in; the user chooses which combination to run.

## Built-in Reviewers

Four reviewers run natively on the host platform, each focused on a specific domain:

| Reviewer | Domain | Key Question |
|----------|--------|--------------|
| Clarity | Vague language, ambiguity, structure | Is this understandable? |
| Completeness | Missing sections, gaps, dependencies | Is anything missing? |
| Specificity | Actionability, concrete details | Is this concrete enough? |
| Complexity & Debt | Unjustified complexity, premature abstraction, dead flexibility | Is the complexity justified? |

Built-in reviewers run as an agent team, enabling cross-validation: reviewers can read each other's findings and challenge them. A key cross-validation pattern is the completeness-vs-complexity tension, where completeness wants more detail while the complexity reviewer pushes back on additions that add maintenance burden. When these reviewers disagree, the friction itself is informative.

Quick scope tasks don't invoke plan-review; they use a lightweight confirmation gate during brainstorming (confirm understanding of the fix, flag edge cases) and exit directly. Standard scope also doesn't invoke plan-review — brainstorming captures decisions in an inline summary without creating a document, so there's nothing for reviewers to analyze. Only Full scope invokes plan-review, since it produces a PRD that benefits from structured multi-reviewer analysis.

## External Reviewers (Experimental)

Four reviewers powered by the same model share the same training data, reasoning patterns, and blind spots. External reviewers address this by invoking a different model family's CLI for an independent review. This feature is experimental; CLI availability and behavior may vary.

Three external CLIs are supported:

| CLI | Invocation | Safety mode |
|-----|------------|-------------|
| Google Gemini | `gemini -s -p "..."` | Sandboxed (reads document from workspace, no write access) |
| OpenAI Codex | `codex exec --sandbox read-only "..."` | Sandboxed read-only, non-interactive |
| Anthropic Claude | `claude -p "..." --max-turns 3` | Bounded turns, no session persistence |

### Execution Model

The orchestrator runs external CLIs **directly** via Bash, not via subagents. This ensures CLI commands execute in the main agent context where the user can approve Bash access normally, avoiding permission issues with subagent CLI access.

All reviewer sources are opt-in. The user selects which combination of built-in reviewers and external CLIs to run via a single multi-select prompt. This means the user can run built-in reviewers only, external CLIs only, or any combination. The orchestrator runs all selected sources in parallel: built-in reviewers as a team (if selected), external CLIs inline via Bash (if selected).

### Self-Identification

The orchestrator determines its own model family and excludes CLIs accordingly:

- Running in Claude Code: Gemini + Codex CLIs available, Claude CLI skipped (self)
- Running in Codex: Only Gemini CLI available (Codex CLI skipped as self; Claude CLI not offered for Codex-hosted plan reviews)
- Running in Gemini: Codex + Claude CLIs available, Gemini CLI skipped (self)

The Codex-hosted restriction is intentional. For document reviews, the cross-model value of offering Claude from within Codex isn't established yet. This may be relaxed in the future.

CLIs that aren't installed are also skipped (checked via `which`).

### Document Handling (vs. Code Review)

Code review stages the diff to a local file (`.external-review-diff.txt`) and the prompt instructs each CLI to read it from disk. Plan review gives them a **file path** to the document and lets each CLI read it directly. Both approaches avoid inlining large content in CLI arguments, preventing shell `ARG_MAX` limits.

| Dimension | Code Review | Plan Review |
|-----------|------------|-------------|
| Input | Diff staged to file (CLI reads `.external-review-diff.txt`) | Document path (CLI reads document) |
| Scope model | Diff-anchored (changed vs. pre-existing) | Document-anchored (full content) |
| Focus areas | Correctness, Security, Performance, Simplicity, Testing | Clarity, Completeness, Specificity, Complexity/Debt |
| Output framing | Severity (Critical/High/Medium/Low) + merge verdict | Priority (High/Medium/Low) + suggestions |

All three CLIs can read workspace files in their respective sandbox modes (Gemini `-s` has `read_file`, Codex `--sandbox read-only` has file access, Claude has its Read tool).

### Document-Type-Aware Persona

The external review prompt adapts its evaluation perspective based on document type:

| Document Type | Perspective | Key Evaluation Angle |
|---------------|------------|---------------------|
| PRD / Brainstorm | Product strategy | Is the problem worth solving? Are user needs clear? Is the approach justified? |
| Tech Plan / Design | Engineering leadership | Is this implementable? Are architecture decisions sound? Are dependencies mapped? |

A PRD's job is to justify *what* and *why*; a tech plan's job is to specify *how*. Reviewing a PRD through a pure engineering lens misses product gaps; reviewing a tech plan through a product lens misses implementation gaps.

The document type is determined in Step 1 and baked into the staged prompt template before CLI invocation.

### Safety

Each CLI runs in its most restrictive mode. The document path is embedded in the prompt; each CLI reads the document from disk using its sandbox file access:

| CLI | Safety flags | Effect |
|-----|-------------|--------|
| Gemini | `-s` | Sandboxed (reads document from workspace, no write access) |
| Codex | `codex exec --sandbox read-only` | Sandboxed read-only; `exec` subcommand for non-interactive use |
| Claude | `-p "..." --max-turns 3 --no-session-persistence` | Bounded turns; `-p` requires prompt as immediately following arg |

Codex uses the `exec` subcommand because the base `codex` command starts an interactive TUI that hangs when invoked from a non-interactive Bash tool. `codex exec` is explicitly designed for headless, non-interactive execution. Combined with `--sandbox read-only`, this gives the model read-only file access with no ability to modify anything.

### Why `codex` Instead of `codex review`

Code review uses `codex exec review --base <branch>`, which invokes Codex's built-in review preset — it computes the branch diff internally and has read-only filesystem access. Plan review uses `codex exec --sandbox read-only` with a custom prompt instead because:

1. The `review` preset is optimized for code diffs and adds its own code-review framing
2. For document review, a custom prompt gives full control over the evaluation perspective (product vs. engineering lens)
3. Both use `codex exec` for non-interactive, headless execution — the base `codex` command starts an interactive TUI that hangs when invoked from agent Bash tools
4. `codex exec --sandbox read-only` gives the model read-only file access with no ability to modify anything

### Graceful Degradation

All sources are opt-in with graceful degradation. If no external CLIs are installed, the orchestrator skips the selection prompt and runs built-in reviewers automatically. If external CLIs are available, the user chooses their combination via multi-select. The system never fails because of a missing external tool or an unexpected user selection; any combination of sources produces a valid review.

## Priority Scale

Plan reviews use a 3-level priority scale (vs. code review's 4-level severity scale):

| Level | Meaning | Action |
|-------|---------|--------|
| **High** | Blocks execution; cannot start the next step without resolving | Must fix before proceeding |
| **Medium** | Creates risk; work can start but likely leads to rework or confusion | Should fix |
| **Low** | Improvement opportunity; plan works but could be clearer or tighter | Author's discretion |

The scale is lighter than code review's severity scale because document issues don't crash systems or create security vulnerabilities. "High" in a plan review means "someone will be blocked or confused," not "the system will break in production."

## Synthesis

The skill orchestrator (not the individual reviewers) synthesizes all findings:

1. **Reconciliation.** Merge findings from all selected sources. When multiple reviewers flag the same issue, merge and note agreement. Cross-model agreement (when both built-in and external sources are used) strengthens confidence.
2. **Structured output.** Per-reviewer findings tables, then synthesis with cross-reviewer patterns, tensions, and quick wins. Works with any combination of sources: built-in only, external only, or both.
3. **No verdict.** Unlike code review (which ends with a merge verdict), plan review ends with a synthesis that highlights patterns and tensions. Plans don't have a binary "ready/not ready"; the synthesis helps the author decide what to address.

## Design Principles

**Model diversity over model quantity.** Two models catching the same gap is stronger signal than four instances of the same model agreeing. External reviewers exist for genuine perspective diversity, not throughput.

**Reviewers report, the skill synthesizes.** Individual reviewers only find and report issues. They never fix the document, invoke other skills, or make decisions about what to do with findings. The orchestrating skill owns deduplication, presentation, and next-step decisions.

**Inline for opaque wrappers, teams for collaborators.** External CLIs are opaque wrappers that can't cross-validate, so they run inline via the orchestrator. Built-in reviewers can read each other's findings and challenge them, so they belong as team members.

**Document-type-aware.** The external review prompt adapts its perspective based on whether the document is a PRD/brainstorm (product lens) or tech plan (engineering lens). The built-in reviewers already handle this via their individual agent definitions (e.g., specificity-reviewer calibrates its bar by document type).

**Graceful degradation everywhere.** No component is required for the system to function. Missing CLI? Hide it from the selection. Missing agent teams? Fall back to parallel subagents for built-in reviewers. No external CLIs installed? Skip the selection prompt and run built-in reviewers automatically. Any combination the user selects produces a valid review.

## Prompt Design

The external review prompt differs from the code review prompt in several key ways:

| Decision | Code Review Prompt | Plan Review Prompt |
|----------|-------------------|-------------------|
| Input | Diff with +/- markers | Full document |
| Persona | "Senior engineer reviewing code" | Varies by doc type (product strategy / engineering leadership) |
| Focus areas | Correctness, Security, Performance, Simplicity, Testing | Clarity, Completeness, Specificity, Complexity/Debt |
| Scope instruction | "Only comment on changed lines" | "Only report substantive issues that weaken the document or lead to poor outcomes" |
| Severity | 4-level (Critical/High/Medium/Low) | 3-level (High/Medium/Low) |
| Output anchor | File path + line number | Line number + suggestion |

Shared design decisions:
- **File-based input.** Document path embedded in prompt; model reads from disk. Told not to modify files.
- **Headless, no interaction.** State assumptions, don't ask questions.
- **Constraint-heavy.** Over half the prompt is about what NOT to do.
- **Structured output.** Numbered findings with consistent format.
- **Deduplication instruction.** State repeated issues once, list locations.

The prompt includes both persona variants (product and engineering) with instructions keyed to the document type. The orchestrator replaces the `{type}` placeholder before staging the file, so the model gets an unambiguous signal about which perspective to use.

## Temporary File Naming

Plan review stages its prompt to `.external-doc-review-prompt.txt` (vs. code review's `.external-review-prompt.txt`). Different names ensure the two features can coexist if both run in the same repository, and make it clear from the filename which review process created the temporary file. Both files are cleaned up during their respective Step 4.
