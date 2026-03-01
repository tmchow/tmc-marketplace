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

Install only one target:

```bash
# Codex skills only
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --codex-only

# Claude Code plugin only
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --claude-only
```

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
     ↕ design-exploration (optional)
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
     ├─ simplify (cleanup pass)
     │
     ├─ final code-review (all changes)
     │   fix selected severities
     │
     └─ wrapup: verify tests → PR
```

Each stage produces an artifact, offers iterative review, and hands off when the user is ready. Re-entry is supported — run any skill again at any point.

### Brainstorming

Brainstorming shapes requirements through dialogue. It asks 2-3 questions to map the problem space, then assesses scope — **Quick** (bug fix, config change), **Standard** (small feature, bounded refactor), or **Full** (large feature, new subsystem). The scope determines how much ceremony follows: Quick gets focused Q&A and an inline sanity check before implementing directly; Standard produces a lightweight brief with full review; Full produces a complete PRD with full review and structured tech planning. The user confirms or overrides the scope assessment.

For Standard and Full scope, it presents broad directions to narrow things down, validates the user's choice against core requirements before going deep, and pushes back on assumptions. The Full scope output is a **PRD** with requirements grouped by priority: Core (the whole point), Must-Have (required for v1), Nice-to-Have (include if straightforward), Out (considered and explicitly excluded). Scope splits into In Scope and deliberate Boundaries. Open questions are tagged with what they affect so downstream stages know what depends on resolving them. Sections earn their place based on criteria, not a rigid template. High-level technical direction belongs here; implementation specifics do not.

After the PRD is written, it goes through review. 4 specialized reviewers (clarity, completeness, specificity, complexity/debt) analyze the document via agent team with cross-validation — the complexity reviewer can push back when completeness wants more detail. The user reviews findings, fixes issues, and can run as many rounds as needed. If the PRD has open questions, they can be resolved before planning. The agent classifies each question by resolution method: questions where the answer exists somewhere (prior art, constraints, competitive landscape) get parallel research via `iterative:research`. Questions about visual design or UX feel get explored via `iterative:design-exploration`. Technical questions defer to tech planning; questions needing user decisions get flagged. Findings are proposed as PRD updates, applied only with user approval. The PRD stays live — tech planning, design exploration, and implementation update it as reality reveals new constraints.

Design exploration generates 5-10 radically different design variations in an interactive HTML gallery. Each variation has per-variation tuning controls, and the gallery includes a rating/feedback system with structured export. The user rates variations, adds notes, and exports feedback that feeds directly back into the next round of exploration. Multiple rounds refine the options until the user converges on a direction. The output is a design direction document capturing chosen directions and discarded approaches — the PRD references it rather than duplicating the content.

### Tech Planning

Tech planning turns the PRD into an implementation plan. It starts by exploring the codebase — existing patterns, conventions, affected modules — and asking implementation-focused questions before writing anything. Open questions from the PRD get resolved during exploration, and the PRD is updated accordingly.

The output is a **Tech Plan** that captures what to build and where — architecture decisions, query strategies, file paths, concrete test scenarios with specific inputs and expected outputs. It does not pre-write implementation code; that's brittle and gets followed blindly. The implementer writes the actual code. Subtasks are scoped to atomic commits (typically 2-3 files) with explicit dependencies. New constraints found during planning go back into the PRD with rationale.

Same review process — all 4 plan reviewers analyze via agent team regardless of document size. Shorter documents naturally produce fewer findings. The user fixes issues, multiple rounds until it's ready.

### Implementing

Implementing executes the tech plan with dependency-aware batching. Subtasks are grouped by their dependency graph — each batch runs concurrently via worker subagents, but batches execute sequentially to respect ordering. Each worker reads its subtask from the plan, loads referenced patterns, implements with TDD, and commits.

Code review happens throughout. Large plan sections (6+ subtasks) get automatic incremental reviews between batches to catch issues before later batches build on flawed code. Every section gets a code review when complete, using 5 built-in reviewers (correctness, security, performance, simplicity, testing) via agent team with cross-validation. In full mode, external model CLIs (Gemini, Codex, Claude) can optionally provide independent perspectives — the orchestrator self-identifies and skips the matching model family's CLI. Severity-based fix acceptance keeps the user in control — they pick which levels to address, not all-or-nothing.

After all sections finish, a simplification pass (via `/simplify` if available, otherwise manual review) makes a single bounded cleanup of changed files, followed by a final code review of all branch changes. Wrapup verifies tests pass and creates the PR.

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
- **Agent teams with fallback** — Reviewers run as an agent team so they can cross-validate findings (the complexity/debt reviewer can push back on completeness suggestions). When agent teams aren't available, reviews automatically fall back to parallel subagents.
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
| Docs committed at every checkpoint | PRDs, plans, and design direction docs are committed incrementally — not left as uncommitted changes across workflow stages. A branch safety gate before the first commit prevents accidental commits to the default branch. |

## Skills

The core workflow skills use an `iterative:` prefix in their name (e.g., `/iterative:brainstorming`). The slash command menu shows skill names from all installed plugins — if another plugin also has a "brainstorming" skill, you'd see duplicate `/brainstorming` entries. The prefix makes ours immediately identifiable. Substring search still works — typing `/brain` finds `/iterative:brainstorming`.

### Core Workflow

| Skill | Output | Description |
|-------|--------|-------------|
| `iterative:brainstorming` | PRD | Collaborative exploration of problem space, broad directions, deep Q&A |
| `iterative:research` | Updated PRD | Research open questions from PRD or user — parallel investigation, findings synthesis |
| `iterative:design-exploration` | Design Direction Doc | Explore 5-10 radically different design approaches with interactive gallery, ratings, and iterative refinement |
| `iterative:tech-planning` | Tech Plan | Structure PRD into dependency-ordered subtasks with file paths, test scenarios, architecture decisions |
| `plan-review` | Review Report | 4 specialized reviewers analyze PRDs and tech plans via agent team with cross-validation |
| `iterative:implementing` | Code → PR | Dependency-aware batch execution with TDD, incremental and final code reviews, then wrapup |
| `code-review` | Review Report | 5 built-in + external model-diverse reviewers, severity ratings, full or quick mode, diff-anchored scoping |

### Internal

| Skill | Description |
|-------|-------------|
| `implementation-wrapup` | Test verification, final review, PR creation — invoked by implementing or standalone ("create a PR") |
| `git-worktree` | Workspace isolation — invoked by implementing during setup |

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
| `yagni-reviewer` | Unjustified complexity, maintenance burden, dead flexibility |

### Review Agents (Code Review)

5 built-in reviewers analyze code via agent team:

| Agent | Focus |
|-------|-------|
| `correctness-reviewer` | Logic errors, edge cases, bugs, silent failures, plan compliance |
| `security-reviewer` | Vulnerabilities, auth, input validation, project conventions |
| `performance-reviewer` | Algorithmic complexity, queries, memory, caching |
| `simplicity-reviewer` | Unjustified complexity, over-engineering, unnecessary abstraction |
| `testing-reviewer` | Coverage, test quality, edge cases, plan test scenarios |

Built-in reviewers use diff-anchored scoping — primary focus on changed lines, with pre-existing issues tagged separately for independent triage. They run as teammates who can cross-validate findings. When agent teams are unavailable, reviews fall back to parallel subagent execution.

### External Reviewers (Code Review, Experimental)

In Full mode, the orchestrator can run external model CLIs directly (opt-in) for independent, model-diverse perspectives. This feature is experimental; CLI availability and behavior may vary. Codex reviews can take 5+ minutes.

| CLI | Invocation | Safety mode |
|-----|------------|-------------|
| Google Gemini | `gemini -s -p "..."` | Sandboxed (diff inlined, no tool access needed) |
| OpenAI Codex | `codex review` | Review-dedicated subcommand (inherently read-only) |
| Anthropic Claude | `claude -p "..." --max-turns 3` | Bounded turns, no session persistence |

The orchestrator self-identifies its model family and skips the matching CLI (e.g., `claude` is skipped in Claude Code, `codex` is skipped in Codex). CLIs that aren't installed are skipped gracefully. Full mode only — never run in quick mode. See [Code Review Strategy](./docs/CODE_REVIEW_STRATEGY.md) for design details.

### Workflow Agents

| Agent | Purpose |
|-------|---------|
| `task-worker` | Executes subtasks — reads plan context, loads patterns, implements with TDD, commits |
| `branch-setup-worker` | Creates git worktrees or branches for isolation |
| `pr-creator-worker` | Creates pull requests following repo conventions |

Workflow agents run as isolated subagents. Each `task-worker` gets its own context window with just its subtask from the plan. Simplification is handled by `/simplify` (if available) rather than a dedicated agent.

## HZL Integration (Optional)

This plugin supports [HZL](https://github.com/tmchow/hzl) for persistent task tracking across sessions and agents. Implementing detects HZL automatically and offers the choice between built-in and HZL task tracking. Without HZL, the workflow uses built-in task management.

See the [HZL repository](https://github.com/tmchow/hzl) for installation.

## Changelog

See [CHANGELOG.md](../../CHANGELOG.md) for a detailed history of all changes, new features, and fixes across releases.

## Credits

This plugin draws inspiration from:

- [superpowers](https://github.com/obra/superpowers) by Jesse Vincent
- [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by [Kieran Klaassen](https://x.com/kieranklaassen) / [Every](https://every.to)
- [pr-review-toolkit](https://github.com/anthropics/claude-code-pr-review) by Anthropic
- [Shape Up](https://basecamp.com/shapeup) by Ryan Singer
- [Shaping Skills](https://github.com/rjs/shaping-skills) by Ryan Singer

## License

MIT
