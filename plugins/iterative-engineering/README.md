# Iterative Engineering Plugin

A plugin for Claude Code and Codex — iterative development workflows with brainstorming, tech planning, multi-agent reviews, TDD implementation, and PR management.

## Philosophy

- **Planning pays off** — Rushing to code is often slower than planning first.
- **Iteration improves quality** — A review after a review can still find improvements.
- **User drives decisions** — Stage transitions, review rounds, and what to fix all surface options to go deeper or move forward.
- **Opinionated defaults, user choice** — Recommend reviews, suggest worktrees, default to full coverage. The user can skip, customize, or exit at any point.
- **Skills are independently valuable** — Each skill works standalone. Run `/code-review` without the full pipeline, or `/iterative:brainstorming` to revisit requirements mid-implementation.

## Installation

### Quick Install

```bash
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash
```

Installs the Claude Code plugin and Codex skills. Safe to re-run (idempotent). Skips anything not detected (e.g., no Codex installed).

To uninstall:

```bash
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --uninstall
```

### Manual Install

#### Claude Code

Claude Code uses a [plugin marketplace](https://docs.anthropic.com/en/docs/claude-code/plugins) — the marketplace must be added before installing the plugin:

```
/plugin marketplace add tmchow/tmc-marketplace
/plugin install iterative-engineering@tmc-marketplace
```

Verify with `/plugin list`.

#### Codex

Download the skills into your Codex skills directory:

```bash
curl -sL https://github.com/tmchow/tmc-marketplace/archive/refs/heads/main.tar.gz \
  | tar xz --strip-components=4 -C ~/.codex/skills/ \
    tmc-marketplace-main/plugins/iterative-engineering/skills/
```

This extracts all skills (with their reference files) to `~/.codex/skills/`.

## The Workflow

```
brainstorming
     │ PRD
     ↕ plan-review (1+ rounds)
     ↕ research (optional)
     ↕ spike (optional)
     │
tech-planning
     │ Tech Plan
     ↕ plan-review (1+ rounds)
     │
implementing
     ├─ execute batch ◄──────────┐
     │   incremental code-review? ┘ (many subtasks)
     │
     ├─ code-review (per plan section)
     │   fix selected severities
     │
     ├─ code-simplifier (cleanup pass)
     │
     ├─ final code-review (all changes)
     │   fix selected severities
     │
     └─ wrapup: verify tests → PR
```

Each stage produces an artifact, offers iterative review, and hands off when the user is ready. Re-entry is supported — run any skill again at any point.

### Brainstorming

Brainstorming shapes requirements through dialogue. It asks 2-3 questions to map the problem space, presents broad directions to narrow things down, and validates the user's choice against core requirements before going deep. It pushes back on assumptions and suggests alternatives — the goal is to surface options, not just document what the user already knows.

The output is a **PRD** with requirements grouped by priority: Core (the whole point), Must-Have (required for v1), Nice-to-Have (include if straightforward), Out (considered and explicitly excluded). Scope splits into In Scope and deliberate Boundaries — active decisions that prevent scope creep, not oversights. Open questions are tagged with what they affect (requirements, scope, direction) so downstream stages know what depends on resolving them. Sections earn their place based on criteria, not a rigid template. High-level technical direction belongs here; implementation specifics do not.

After the PRD is written, it goes through review. 4 specialized reviewers (clarity, completeness, specificity, YAGNI) analyze the document via agent team with cross-validation — a YAGNI reviewer can push back when completeness wants more detail. The user reviews findings, fixes issues, and can run as many rounds as needed. If the PRD has open questions, they can be resolved before planning. The agent classifies each question by resolution method: questions where the answer exists somewhere (prior art, constraints, competitive landscape) get parallel research via `iterative:research`. Questions that need to be built and experienced (UX feel, interaction design, behavioral validation) get spiked via `iterative:spike`. Technical questions defer to tech planning; questions needing user decisions get flagged. Findings are proposed as PRD updates, applied only with user approval. The PRD stays live — tech planning, spiking, and implementation update it when they hit new constraints.

Spiking builds lightweight throwaway prototypes in isolated worktrees to validate uncertain requirements. Each spike follows a build → present → feedback loop — the user experiences the prototype and provides direction. The spike adapts its approach to the system state: if relevant modules exist, it spikes within the existing system; if not, it builds a standalone prototype. Spike findings update the PRD with full rationale — the PRD stays self-sufficient for downstream stages without needing to read the spike doc. Spike code is throwaway; the decisions are what persist.

### Tech Planning

Tech planning turns the PRD into an implementation plan. It starts by exploring the codebase — existing patterns, conventions, affected modules — and asking implementation-focused questions before writing anything. Open questions from the PRD get resolved during exploration, and the PRD is updated accordingly.

The output is a **Tech Plan** that captures what to build and where — architecture decisions, query strategies, file paths, concrete test scenarios with specific inputs and expected outputs. It does not pre-write implementation code; that's brittle and gets followed blindly. The implementer writes the actual code. Subtasks are scoped to atomic commits (typically 2-3 files) with explicit dependencies. New constraints found during planning go back into the PRD with rationale.

Same review process: the 4 plan reviewers analyze via agent team, the user fixes issues, multiple rounds until it's ready.

### Implementing

Implementing executes the tech plan with dependency-aware batching. Subtasks are grouped by their dependency graph — each batch runs concurrently via worker subagents, but batches execute sequentially to respect ordering. Each worker reads its subtask from the plan, loads referenced patterns, implements with TDD, and commits.

Code review happens throughout. Large plan sections (6+ subtasks) get automatic incremental reviews between batches to catch issues before later batches build on flawed code. Every section gets a code review when complete, using 5 specialized reviewers (correctness, security, performance, simplicity, testing) via agent team with cross-validation. Severity-based fix acceptance keeps the user in control — they pick which levels to address, not all-or-nothing.

After all sections finish, a code-simplifier agent makes a single bounded pass of behavior-preserving cleanup on changed files, followed by a final code review of all branch changes. Wrapup verifies tests pass and creates the PR.

### Stage Boundaries

Each stage has a clear scope — what it produces and what it deliberately leaves to the next stage:

| Stage | Produces | Does | Does NOT |
|-------|----------|------|----------|
| **Brainstorming** | PRD | Explore problem space, make directional choices, capture prioritized requirements and scope boundaries | Specify libraries, schemas, API endpoints, or implementation details |
| **Tech Planning** | Tech Plan | Structure subtasks with dependencies, file paths, test scenarios, and architecture decisions | Pre-write implementation code — describe what and where, implementer writes the code |
| **Implementing** | Code → PR | Execute plan with dependency-aware batching, TDD, code reviews, test verification, PR creation | Deploy or release — the workflow ends at PR creation |

### Reviews

Reviews are user-driven:

- **Offered, never forced** — Every review is presented as a choice. The user can skip.
- **Severity-based acceptance** — Findings grouped by severity (Critical / High / Medium / Low). User selects which levels to fix — not all-or-nothing.
- **User-controlled loop** — After fixes, user chooses to re-review or continue. No automatic re-review.
- **Scaled to scope** — Full review for substantial work, quick review for moderate changes, skip for trivial config edits.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| PRD captures direction, not implementation | High-level technical direction ("real-time via WebSockets") belongs in the PRD. Specific libraries and database schemas don't — that's tech planning's job. |
| Requirements are prioritized, not flat | Requirements grouped as Core / Must-Have / Nice-to-Have / Out. Priority drives implementation scope and prevents everything from being treated as equally important. |
| PRD is a living document | Tech planning and implementation update the PRD when they hit new constraints. Changes are noted with rationale. |
| Tech plan describes what, not how | Plans capture architecture, query strategies, and test scenarios. They don't pre-write method bodies — that's brittle and gets followed blindly. The implementer writes the actual code. |
| Dependency-aware batch execution | Subtasks are grouped by their dependency graph. Each batch runs concurrently, but batches execute sequentially. Not one-at-a-time (too slow), not all-at-once (ignores ordering). |
| Incremental reviews for large sections | Plan sections with 6+ subtasks get code review offers between batches. Catches issues before later batches build on flawed code. |
| Severity-based fix acceptance | Not all review findings warrant fixing. User picks which severity levels to address. Keeps the user in control of review scope. |

## Skills

The core workflow skills use an `iterative:` prefix in their name (e.g., `/iterative:brainstorming`). The slash command menu shows skill names from all installed plugins — if another plugin also has a "brainstorming" skill, you'd see duplicate `/brainstorming` entries. The prefix makes ours immediately identifiable. Substring search still works — typing `/brain` finds `/iterative:brainstorming`.

### Core Workflow

| Skill | Output | Description |
|-------|--------|-------------|
| `iterative:brainstorming` | PRD | Collaborative exploration of problem space, broad directions, deep Q&A |
| `iterative:research` | Updated PRD | Research open questions from PRD or user — parallel investigation, findings synthesis |
| `iterative:spike` | Spike Doc + Updated PRD | Build and validate uncertain requirements — throwaway prototypes, user feedback loops |
| `iterative:tech-planning` | Tech Plan | Structure PRD into dependency-ordered subtasks with file paths, test scenarios, architecture decisions |
| `plan-review` | Review Report | 4 specialized reviewers analyze PRDs and tech plans via agent team with cross-validation |
| `iterative:implementing` | Code → PR | Dependency-aware batch execution with TDD, incremental and final code reviews, then wrapup |
| `code-review` | Review Report | 5 specialized reviewers with severity ratings, full or quick mode, language-agnostic |

### Internal

| Skill | Description |
|-------|-------------|
| `implementation-wrapup` | Test verification, final review, PR creation — invoked by implementing or standalone ("create a PR") |
| `git-worktree` | Workspace isolation — invoked by implementing and spike during setup |

### Supporting

| Skill | Description |
|-------|-------------|
| `fix-code-review-feedback` | Resolve PR review comments systematically — evaluates validity before fixing, supports local agent feedback and GitHub PR threads |
| `agent-browser` | Browser automation using Vercel's agent-browser CLI |

## Agents

### Review Agents (Plan Review)

4 specialized reviewers analyze documents via [agent team](https://code.claude.com/docs/en/agent-teams):

| Agent | Focus |
|-------|-------|
| `clarity-reviewer` | Vague language, ambiguity, structure |
| `completeness-reviewer` | Missing sections, gaps, dependencies |
| `specificity-reviewer` | Actionability, concrete details |
| `yagni-reviewer` | Scope creep, over-specification |

### Review Agents (Code Review)

5 specialized reviewers analyze code via agent team:

| Agent | Focus |
|-------|-------|
| `correctness-reviewer` | Logic errors, edge cases, bugs, silent failures, plan compliance |
| `security-reviewer` | Vulnerabilities, auth, input validation, project conventions |
| `performance-reviewer` | Algorithmic complexity, queries, memory, caching |
| `simplicity-reviewer` | YAGNI, over-engineering, unnecessary abstraction |
| `testing-reviewer` | Coverage, test quality, edge cases, plan test scenarios |

Review agents run as teammates who can cross-validate findings — a security reviewer can flag missing test coverage, a YAGNI reviewer can push back on completeness suggestions. When agent teams are unavailable, reviews fall back to parallel subagent execution.

### Workflow Agents

| Agent | Purpose |
|-------|---------|
| `task-worker` | Executes subtasks — reads plan context, loads patterns, implements with TDD, commits |
| `code-simplifier` | Behavior-preserving simplification pass on changed files before final review |
| `branch-setup-worker` | Creates git worktrees or branches for isolation |
| `pr-creator-worker` | Creates pull requests following repo conventions |

Workflow agents run as isolated subagents. Each `task-worker` gets its own context window with just its subtask from the plan.

## HZL Integration (Optional)

This plugin supports [HZL](https://github.com/tmchow/hzl) for persistent task tracking across sessions and agents. Implementing detects HZL automatically and offers it as the recommended option. Without HZL, the workflow uses built-in task management.

See the [HZL repository](https://github.com/tmchow/hzl) for installation.

## Credits

This plugin draws inspiration from:

- [superpowers](https://github.com/obra/superpowers) by Jesse Vincent
- [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by [Kieran Klaassen](https://x.com/kieranklaassen) / [Every](https://every.to)
- [pr-review-toolkit](https://github.com/anthropics/claude-code-pr-review) by Anthropic
- [code-simplifier](https://github.com/anthropics/claude-code-code-simplifier) by Anthropic
- [Shape Up](https://basecamp.com/shapeup) by Ryan Singer
- [Shaping Skills](https://github.com/rjs/shaping-skills) by Ryan Singer

## License

MIT
