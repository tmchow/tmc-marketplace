# Iterative Engineering Plugin

A plugin for Claude Code and Codex — standalone skills for brainstorming, design exploration, code review, tech planning, TDD implementation, and PR management. Use them individually or compose them into an end-to-end workflow.

## What You Can Do

Every skill works on its own. Pick what fits your situation:

- **Explore designs visually** — `/iterative:design-exploration` generates 5-10 radically different interactive HTML prototypes in parallel, each with tuning controls, star ratings, and structured feedback export. Iterate across rounds until you converge on a direction. See [Design Exploration Strategy](./docs/DESIGN_EXPLORATION_STRATEGY.md).
- **Brainstorm requirements** — `/iterative:brainstorming` shapes a problem through dialogue, adapting depth to scope (quick bug fix vs. full feature PRD). See [Brainstorming Strategy](./docs/BRAINSTORMING_STRATEGY.md).
- **Review code** — `/code-review` dynamically selects from 8 reviewer personas (3 always-on, 5 conditional), spawns them as parallel sub-agents with structured JSON output, and deduplicates findings through a merge pipeline. See [Code Review Strategy](./docs/CODE_REVIEW_STRATEGY.md).
- **Review plans and PRDs** — `/plan-review` runs 4 reviewers (clarity, completeness, specificity, complexity) with cross-validation. See [Plan Review Strategy](./docs/PLAN_REVIEW_STRATEGY.md).
- **Research open questions** — `/iterative:research` investigates prior art, constraints, and competitive landscape through parallel research agents.
- **Plan implementation** — `/iterative:tech-planning` turns requirements into dependency-ordered subtasks with file paths and test scenarios.
- **Implement with review** — `/iterative:implementing` executes a tech plan with TDD, code review, and PR creation.
- **Fix review feedback** — `/fix-code-review-feedback` resolves PR review comments systematically, from local agent feedback or GitHub PR threads.

These skills also compose into a full pipeline (brainstorm → plan → implement) — see [The End-to-End Workflow](#the-end-to-end-workflow) — but that's one way to use them, not the only way.

## Philosophy

- **Skills are independently valuable** — Each skill works standalone. Run `/code-review` on any branch, `/iterative:design-exploration` before writing a single line of code, or `/iterative:brainstorming` to revisit requirements mid-implementation.
- **Planning pays off** — Rushing to code is often slower than planning first.
- **Iteration improves quality** — A review after a review can still find improvements.
- **User drives decisions** — Stage transitions, review rounds, and what to fix all surface options to go deeper or move forward.
- **Opinionated defaults, user choice** — Recommend reviews, suggest worktrees, default to full coverage. The user can skip, customize, or exit at any point.

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

## Skills

The core skills use an `iterative:` prefix in their name (e.g., `/iterative:brainstorming`). The slash command menu shows skill names from all installed plugins — if another plugin also has a "brainstorming" skill, you'd see duplicate entries. The prefix makes ours immediately identifiable. Substring search still works — typing `/brain` finds `/iterative:brainstorming`.

### Core

| Skill | Output | Description |
|-------|--------|-------------|
| `iterative:brainstorming` | PRD | Collaborative exploration of problem space, broad directions, deep Q&A |
| `iterative:research` | Updated PRD | Research open questions from PRD or user — parallel investigation, findings synthesis |
| `iterative:design-exploration` | Design Direction Doc | Explore 5-10 radically different design approaches with interactive gallery, ratings, and iterative refinement |
| `iterative:tech-planning` | Tech Plan | Structure requirements into dependency-ordered subtasks with file paths, test scenarios, architecture decisions |
| `plan-review` | Review Report | 4 specialized reviewers analyze PRDs and tech plans via agent team with cross-validation |
| `iterative:implementing` | Code → PR | Dependency-aware batch execution with TDD, section and final code reviews, then wrapup |
| `code-review` | Review Report | 8 reviewer personas (dynamic selection), structured JSON output, merge pipeline, P0-P3 severity |

### Supporting

| Skill | Description |
|-------|-------------|
| `fix-code-review-feedback` | Resolve PR review comments systematically — evaluates validity before fixing, supports local agent feedback and GitHub PR threads |
| `agent-browser` | Browser automation using Vercel's agent-browser CLI |

### Internal

| Skill | Description |
|-------|-------------|
| `implementation-wrapup` | Test verification, final review, PR creation — invoked by implementing or standalone ("create a PR") |
| `git-worktree` | Workspace isolation — invoked by implementing during setup |
| `design-prototyping` | HTML prototyping craft knowledge — preloaded into the `html-prototyper` agent, not invoked directly |

## Skill Deep Dives

### Design Exploration

Run `/iterative:design-exploration` to generate a gallery of interactive HTML prototypes — each built by a separate agent with no knowledge of the others, ensuring genuine creative divergence.

Each variation is a complete, functional page (not a mockup) with 4-8 design controls — sliders, dropdowns, toggles — that let you adjust spacing, color mood, density, animation style, and layout within a single approach. The gallery includes star ratings, notes, and a structured feedback export that feeds directly into the next round.

The workflow supports multiple rounds: rate variations, export feedback, paste it back, and the system drops rejected approaches while going deeper on the ones you liked. When you converge, "Ship It" produces a **design direction document** — a durable record of what was chosen, what was rejected, and why.

Use it standalone to explore a component, a page layout, or an interaction model. Use it during brainstorming to ground a discussion in something concrete. Use it after a PRD to test visual possibilities that requirements alone can't express.

For the full rationale — divergence axes, parallel agent architecture, iframe isolation, the direction doc format — see [Design Exploration Strategy](./docs/DESIGN_EXPLORATION_STRATEGY.md).

### Brainstorming

Run `/iterative:brainstorming` to shape a problem through dialogue. The skill assesses scope first — **Quick** (bug fix, config change), **Standard** (small feature, bounded refactor), or **Full** (large feature, new subsystem) — and adapts depth accordingly. Quick gets focused Q&A and an inline sanity check before implementing directly. Standard produces a lightweight brief with review. Full produces a complete **PRD** with prioritized requirements (Core / Must-Have / Nice-to-Have / Out), scope boundaries, and open questions tagged by resolution method.

After the PRD is written, 4 specialized reviewers analyze it via agent team with cross-validation. Open questions get classified: researchable questions go to `/iterative:research`, design questions go to `/iterative:design-exploration`, technical questions defer to tech planning, and questions needing user decisions get flagged.

For the full rationale — scope-first routing, adaptive depth, PRD structure — see [Brainstorming Strategy](./docs/BRAINSTORMING_STRATEGY.md).

### Code Review

Run `/code-review` on any branch to get findings from dynamically selected reviewer personas. The orchestrator reads the diff, selects from 8 personas (3 always-on: correctness, testing, maintainability; 5 conditional: security, performance, api-contract, data-migrations, reliability), and spawns them as parallel sub-agents returning structured JSON. A merge pipeline deduplicates, confidence-gates, and severity-normalizes findings. Results are grouped by severity (P0/P1/P2/P3); you pick which levels to fix.

For the full rationale — persona selection, JSON output, merge pipeline — see [Code Review Strategy](./docs/CODE_REVIEW_STRATEGY.md).

### Tech Planning

Run `/iterative:tech-planning` to turn requirements into an implementation plan. It explores the codebase first — existing patterns, conventions, affected modules — and asks implementation-focused questions before writing anything.

The output is a **Tech Plan** with architecture decisions, file paths, and concrete test scenarios. Subtasks are scoped to atomic commits with explicit dependencies. Same review process — all 4 plan reviewers analyze via agent team.

### Implementing

Run `/iterative:implementing` to execute a tech plan with dependency-aware batching. Subtasks grouped by their dependency graph run concurrently via worker subagents; batches execute sequentially to respect ordering. Each worker implements with TDD and commits.

Code review happens at section boundaries and at the end — section-level reviews for multi-section plans, and a final review of all branch changes. TDD and test verification gates catch issues between batches. Wrapup verifies tests pass and creates the PR.

## The End-to-End Workflow

The skills compose into a full pipeline when you want the complete lifecycle:

```
brainstorming
     │ PRD
     ↕ plan-review (1+ rounds)
     ↕ research → Updated PRD (optional)
     ↕ design-exploration → Direction Doc (optional)
     │
tech-planning
     │ Tech Plan
     ↕ plan-review (1+ rounds)
     │
implementing
     ├─ execute batches (TDD + test gate)
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

### Stage Boundaries

| Stage | Produces | Does | Does NOT |
|-------|----------|------|----------|
| **Brainstorming** | PRD | Explore problem space, make directional choices, capture prioritized requirements and scope boundaries | Specify libraries, schemas, API endpoints, or implementation details |
| **Design Exploration** | Direction Doc | Generate interactive prototypes, compare interaction models, converge on a visual/UX direction | Produce production code or final assets |
| **Tech Planning** | Tech Plan | Structure subtasks with dependencies, file paths, test scenarios, and architecture decisions | Pre-write implementation code — describe what and where, implementer writes the code |
| **Implementing** | Code → PR | Execute plan with dependency-aware batching, TDD, code reviews, test verification, PR creation | Deploy or release — the workflow ends at PR creation |

### Reviews

Reviews are user-driven:

- **Offered, never forced** — Every review is presented as a choice. The user can skip.
- **Severity-based acceptance** — Findings grouped by severity (P0 / P1 / P2 / P3). User selects which levels to fix — not all-or-nothing.
- **User-controlled loop** — After fixes, user chooses to re-review or continue. No automatic re-review.
- **Parallel sub-agents** — Code reviewers run as parallel sub-agents returning structured JSON. Plan reviewers run as an agent team for cross-validation.
- **Scaled to scope** — The tier model right-sizes automatically. Skip for trivial config edits.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| PRD captures direction, not implementation | High-level technical direction ("real-time via WebSockets") belongs in the PRD. Specific libraries and database schemas don't — that's tech planning's job. |
| Requirements are prioritized, not flat | Requirements grouped as Core / Must-Have / Nice-to-Have / Out. Priority drives implementation scope and prevents everything from being treated as equally important. |
| PRD is a living document | Tech planning and implementation update the PRD when they hit new constraints. Changes are noted with rationale. |
| Tech plan describes what, not how | Plans capture architecture, query strategies, and test scenarios. They don't pre-write method bodies — that's brittle and gets followed blindly. The implementer writes the actual code. |
| Dependency-aware batch execution | Subtasks are grouped by their dependency graph. Each batch runs concurrently, but batches execute sequentially. Not one-at-a-time (too slow), not all-at-once (ignores ordering). |
| TDD + test gates between batches | Each subtask uses TDD and a test verification gate catches missing tests after each batch. Issues are caught during development, not deferred to review. |
| Severity-based fix acceptance | Not all review findings warrant fixing. User picks which severity levels to address. Keeps the user in control of review scope. |
| Docs committed at every checkpoint | PRDs, plans, and design direction docs are committed incrementally — not left as uncommitted changes across workflow stages. A branch safety gate before the first commit prevents accidental commits to the default branch. |

## Agents

### Review Agents (Plan Review)

4 specialized reviewers analyze documents via [agent team](https://code.claude.com/docs/en/agent-teams):

| Agent | Focus |
|-------|-------|
| `clarity-reviewer` | Vague language, ambiguity, structure |
| `completeness-reviewer` | Missing sections, gaps, dependencies |
| `specificity-reviewer` | Actionability, concrete details |
| `complexity-reviewer` | Unjustified complexity, maintenance burden, dead flexibility |

### Review Agents (Code Review)

8 personas in two tiers, running as parallel sub-agents with structured JSON output:

**Always-on:**

| Agent | Focus |
|-------|-------|
| `correctness-reviewer` | Logic errors, edge cases, state bugs, error propagation |
| `testing-reviewer` | Coverage gaps, weak assertions, brittle tests |
| `maintainability-reviewer` | Coupling, complexity, naming, dead code, abstraction debt |

**Conditional (selected per diff):**

| Agent | Focus |
|-------|-------|
| `security-reviewer` | Injection, auth/authz bypasses, secrets, SSRF/path traversal |
| `performance-reviewer` | N+1 queries, unbounded memory, missing pagination, blocking I/O |
| `api-contract-reviewer` | Breaking changes, missing versioning, inconsistent error shapes |
| `data-migrations-reviewer` | Irreversible migrations, missing backfills, deploy-window breaks |
| `reliability-reviewer` | Missing error handling, retry storms, missing timeouts, error swallowing |

Reviewers use diff-anchored scoping — primary focus on changed lines, with pre-existing issues tagged separately. Findings are deduplicated via fingerprint matching, confidence-gated, and severity-normalized before presentation.

### Workflow Agents

| Agent | Purpose |
|-------|---------|
| `task-worker` | Executes subtasks — reads plan context, loads patterns, implements with TDD, commits |
| `branch-setup-worker` | Creates git worktrees or branches for isolation |
| `pr-creator-worker` | Creates pull requests following repo conventions |
| `html-prototyper` | Generates individual design variations — receives a brief from the design exploration orchestrator, writes one self-contained HTML file |

Workflow agents run as isolated subagents. Each `task-worker` gets its own context window with just its subtask from the plan. Simplification is handled by `/simplify` (if available) rather than a dedicated agent.

## Documentation

For deeper rationale behind each skill's design:

| Document | Covers |
|----------|--------|
| [Design Exploration Strategy](./docs/DESIGN_EXPLORATION_STRATEGY.md) | Divergence axes, the gallery workflow, parallel agent architecture, iframe isolation, the direction doc |
| [Brainstorming Strategy](./docs/BRAINSTORMING_STRATEGY.md) | Scope-first routing, Quick/Standard/Full paths, adaptive depth, PRD structure |
| [Code Review Strategy](./docs/CODE_REVIEW_STRATEGY.md) | 8 persona catalog, dynamic selection, JSON output, merge pipeline, P0-P3 severity |
| [Plan Review Strategy](./docs/PLAN_REVIEW_STRATEGY.md) | 4 specialized reviewers, cross-validation, priority model, agent team design |

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
