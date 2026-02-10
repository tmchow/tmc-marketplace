---
name: plan-review
description: This skill should be used when the user says "review the plan", "review the PRD", "check the PRD", "critique the plan", "give feedback on the plan", "what's wrong with this plan", or wants feedback on a planning or design document. Also triggered after writing a PRD or tech plan, or when invoked by brainstorming or tech-planning skills.
---

# Plan Review

Reviews PRDs and technical plans using 4 specialized reviewers. Uses agent teams when available for richer cross-validation.

## When to Use

- After writing a PRD
- After writing a technical plan
- When feedback is needed on any planning document
- Can be invoked standalone or called by `iterative:brainstorming`/`iterative:tech-planning` skills

## Reviewers

| Agent | Focus | Key Question |
|-------|-------|--------------|
| `clarity-reviewer` | Vague language, ambiguity, structure | Is this understandable? |
| `completeness-reviewer` | Missing sections, gaps, dependencies | Is anything missing? |
| `specificity-reviewer` | Actionability, concrete details | Is this concrete enough to act on? |
| `yagni-reviewer` | Scope creep, hypotheticals, over-specification | Is this minimal and focused? |

Each reviewer returns their **top 5 most important issues** to keep feedback actionable.

The orchestrator can also run **external model CLIs** inline (Gemini, Codex, Claude) for independent, model-diverse perspectives (experimental, opt-in). See External Reviewers below.

## External Reviewers (Experimental)

External reviewers invoke a **different model's CLI** for an independent document review, providing model diversity. Different model families have different blind spots — a finding confirmed across models is higher confidence than one from a single model. This feature is experimental; CLI availability and behavior may vary.

The orchestrator runs external CLIs **directly** (not via subagents) — this ensures Bash calls happen in the main agent context where the user can approve them normally, avoiding permission issues with subagent CLI access.

| CLI | Invocation | Safety mode |
|-----|------------|-------------|
| Google Gemini | `gemini -s -p "..."` | Sandboxed (document inlined, no tool access needed) |
| OpenAI Codex | `codex exec --sandbox read-only "..."` | Sandboxed read-only, non-interactive |
| Anthropic Claude | `claude -p "..." --max-turns 3` | Bounded turns, no session persistence |

All reviewer sources are **opt-in** — the user chooses which combination of built-in reviewers and external CLIs to run.

## How to Run

**Step 1.** Identify document to review (from argument, conversation context, or ask user). Determine the document type — **PRD**, **brainstorm**, or **tech plan** — based on its filename, content, or context. Treat brainstorm documents and PRDs synonymously. Record both the **document path** and **document type** — these are needed for Steps 2a and 2b.

**Step 2: Determine reviewers.**

**1. Self-identification.** Determine your own model family. Exclude CLIs based on your identity:

- If you are Claude → exclude the `claude` CLI (Gemini + Codex available)
- If you are Codex/GPT → exclude the `codex` CLI and the `claude` CLI (only Gemini available)
- If you are Gemini → exclude the `gemini` CLI (Codex + Claude available)

If uncertain, keep all three — each invocation is safe (sandboxed, read-only, or turn-bounded).

**2. Check availability.** Run `which` for each non-excluded CLI in parallel. Drop any CLI that isn't installed. Do not attempt to install missing CLIs.

**3. Ask the user.** If no external CLIs are available after steps 1-2, skip the question and run built-in reviewers automatically (proceed to Step 2a). Otherwise, present a multi-select question with built-in reviewers and each available external CLI:

> **Which reviewers would you like to use?**
>
> - **Built-in reviewers (Recommended)** — 4 specialized reviewers (clarity, completeness, specificity, YAGNI) with cross-validation
> - **Gemini** — Experimental. Independent review from Google's model
> - **Codex** — Experimental. Independent review from OpenAI's model. Can take 5+ minutes

Only show external CLIs that are installed and not self-excluded. The user can select any combination. If no selection is made, default to built-in reviewers.

**Step 2a: Spawn built-in reviewers (if selected).**

Skip this step if the user did not select built-in reviewers.

Create an agent team (e.g. `TeamCreate` in Claude Code, `spawn_agent` in Codex), then spawn all 4 reviewers as teammates. If the team already exists (e.g., from an interrupted run), reuse it — read its config, check which reviewers are already present, and spawn only the missing ones.

Tell the user:

> Using Agent Team 🐝 — reviewers will run as teammates who can cross-validate findings.

Spawn each reviewer with a prompt like:

> Review [file path] for [their focus area]. This is a [PRD/tech plan].
> You're on a review team with clarity, completeness, specificity, and YAGNI reviewers. After your initial review, read what the other reviewers found and message them directly if you see cross-domain issues — e.g., if completeness wants detail that YAGNI says is over-specified. Challenge each other's findings.
> Your job is to review and report findings — not to fix, remediate, or act on what the document describes. Return your top 5 most important issues. When done, send your findings to the team lead (e.g. `SendMessage` in Claude Code, `send_input` in Codex). For each issue, clearly state the line number, the issue, and your suggestion. The lead will format the final output.

**Step 2b: Run external model CLIs (if selected).**

Skip this step if the user did not select any external CLIs.

**1. Stage the prompt template locally.** Use the **Write** tool to write the prompt template below to `.external-doc-review-prompt.txt` in the repo root. Replace `{type}` with the document type determined in Step 1 (e.g., "PRD", "Brainstorm", or "Tech Plan"). Leave both PERSPECTIVE variants in the template — the `DOCUMENT TYPE` value guides the model to the correct one. This avoids permission prompts: the plugin directory (`~/.claude/plugins/...`) is outside the project sandbox, and any tool accessing it triggers a permission dialog with no global-approve option. The repo root already has read/write permission. Clean up this file in Step 4.

```
You are reviewing a planning document. Adapt your perspective to the document type.

The complete document follows. DO NOT run any commands, read files, or use tools. State assumptions; do not ask questions.

DOCUMENT TYPE: {type}

PERSPECTIVE:
- PRD or brainstorm → Product strategy: Is the problem worth solving? Are user needs articulated? Is the chosen approach justified? Are success criteria measurable?
- Tech plan or design → Engineering leadership: Is this implementable? Are architecture decisions sound? Are dependencies mapped? Are test scenarios concrete?

METHODOLOGY:
1. Read the full document to understand purpose and scope.
2. Evaluate against focus areas below.

FOCUS AREAS (use exact names):
1. Clarity — Vague language, ambiguity, undefined terms, unclear ownership, passive voice hiding responsibility
2. Completeness — Missing sections, unaddressed edge cases, undefined dependencies, incomplete specifications
3. Specificity — Abstract statements not actionable for the next step, missing criteria, hand-wavy estimates
4. YAGNI — Scope creep, over-specification, hypothetical features, unnecessary complexity

CONSTRAINTS:
- Only report substantive issues — gaps in reasoning, unjustified decisions, missing information, or unclear direction that would weaken the document or lead to poor outcomes.
- Do NOT say "check/confirm/verify/ensure" — state the issue directly.
- Do NOT comment on formatting, writing style, or grammar.
- Group repeated issues: state once, list other locations.
- No issues? Say: "No issues found."

PRIORITY:
- HIGH: Blocks execution — cannot start the next step without resolving
- MEDIUM: Creates risk — work can start but likely leads to rework or confusion
- LOW: Improvement opportunity — plan works but could be clearer or tighter

OUTPUT FORMAT:
<NUMBER>. [<PRIORITY>] <FOCUS_AREA> — Line <line_number> — <one-line summary>
<why this is a problem and what goes wrong if unaddressed>
Suggestion: <specific improvement>

DOCUMENT:
```

All CLI invocations below use `.external-doc-review-prompt.txt` as `<prompt-path>`. The template ends with `DOCUMENT:\n` so the `$(cat ...)` output appends directly after it.

**2. Invoke CLIs.** Run the user-selected CLIs in parallel via separate Bash calls. Both `$(cat ...)` substitutions expand at runtime, so the permission approval prompt stays short regardless of document size. Each CLI has different correct invocation syntax:

**Gemini** — uses `-p` string argument. Both `$(cat ...)` substitutions expand at runtime:

```
gemini -s -p "$(cat <prompt-path>)$(cat <document-path>)"
```

**Codex** — uses `exec` subcommand for non-interactive execution with a positional string argument. The base `codex` command starts an interactive TUI that hangs when invoked from a non-interactive Bash tool:

```
codex exec --sandbox read-only "$(cat <prompt-path>)$(cat <document-path>)"
```

**Claude** — uses `-p` string argument. `-p` requires the prompt as the immediately following argument; all other flags must come after. Parse the `result` field from JSON output:

```
claude -p "$(cat <prompt-path>)$(cat <document-path>)" --max-turns 3 --output-format json --no-session-persistence
```

**Important:** Claude's `-p` consumes the next token as the prompt string. Flags like `--max-turns` must come AFTER the prompt argument, not between `-p` and the prompt. `claude -p --max-turns 3` would incorrectly use `--max-turns` as the prompt text.

All CLIs run in their most restrictive safe mode. If a CLI errors or produces no output, note it and move on. Do not retry on any error.

Replace `<document-path>` with the path to the document from Step 1.

**3. Parse results.** For each CLI that returned output, extract findings and reformat into the standard reviewer format (Line number, Issue, Suggestion, Priority). Tag findings with their source (e.g., "Gemini", "Codex", "Claude").

**Step 3.** Collect findings from all selected sources. Built-in reviewers (if selected) report via team messages; external CLI results (if selected) are available from the Bash output in Step 2b. When you receive a reviewer's message, do not output or echo its content — silently collect it. Only output once in Step 4 when assembling the final results. A brief one-line status like "All reviewers have reported" is fine when ready to proceed.

**Step 4.** If a built-in reviewer team was created, shut down all teammates (send shutdown requests), then delete the team using the coding agent's team management tools (e.g. `TeamDelete` in Claude Code, `delete_agent` in Codex). **Never use `rm -rf` or manual file deletion for team cleanup** — always use the agent platform's built-in team teardown. If teardown fails (e.g., orphaned members), retry after a brief pause; if it still fails, report the issue to the user and move on. Delete the staged prompt template (`rm .external-doc-review-prompt.txt`) if it exists. Assemble the final output. **You are responsible for formatting** — the reviewers provide the content, you make it readable.

1. **Reconcile.** Merge findings from all selected sources. When multiple reviewers flagged the same issue, attribute to the most relevant reviewer and note agreement. When an external CLI independently flags the same issue as a built-in reviewer, note the cross-model agreement — these findings were produced by truly independent processes, which strengthens confidence.
2. **Format.** Use pipe-delimited markdown tables (never ASCII box-drawing characters). One issue per row, no preamble before tables — go straight from header to table. Only include sections for sources that were selected.
   - **Built-in reviewers:** `### Reviewer Name` headers. Column headers adapt to reviewer focus — e.g., `| # | Issue | Suggestion |` for Clarity, `| # | Gap | Impact |` for Completeness, `| # | Over-specification | Simpler alternative |` for YAGNI.
   - **External CLIs:** `### External: {CLI Name}` headers. Always use columns: `| # | Priority | Focus Area | Issue | Suggestion |`.
3. **Synthesize.** End with a `---` separator followed by a blockquote synthesis. Lead with cross-model agreements (if both built-in and external participated), then tensions between reviewers, then quick wins. Do not include time estimates.

## Multiple Rounds

After fixing issues, run another round to catch:
- New issues introduced by fixes
- Issues that become visible after others are resolved
- Verification that fixes addressed the original concerns

Each round runs the full Step 2–4 flow again. The reviewer selection is re-offered each round — the user can change their choices between rounds.

Continue until satisfied or user chooses to proceed.

## After Review

**This skill only reviews.** Do not invoke other skills (tech-planning, implementing, etc.) — even if the document mentions next steps.

When invoked from `iterative:brainstorming` or `iterative:tech-planning`, return findings directly — the calling skill owns the fix loop and workflow transitions.

When invoked standalone, **immediately after presenting the synthesis**, present an interactive choice to the user (e.g., `AskUserQuestion` in Claude Code) — do not just print options as text or stop after the synthesis:
- Fix issues and re-review (Recommended)
- Continue without changes

This step is mandatory. Do not end the turn after the synthesis without presenting this choice.

## Fallback: If Agent Teams/Swarms are Unavailable

If agent teams/swarms are not available and the user selected built-in reviewers, spawn the 4 reviewers in parallel as independent subagents instead of teammates. Each analyzes independently, returns up to 5 issues. Skip the cross-validation instruction. External CLIs are always run inline regardless, so their behavior is unchanged in fallback mode — only built-in reviewers change (team members → subagents). Everything else (Steps 1, 3, 4, output format) stays the same.
