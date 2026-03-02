# AGENTS.md

## Overview

This is a Claude Code plugin marketplace repository. It hosts plugins that can be installed by other Claude Code users via the marketplace system.

## Repository Structure

```
.claude-plugin/marketplace.json  # Marketplace configuration (plugin registry)
plugins/                         # All plugins live here
  <plugin-name>/
    .claude-plugin/plugin.json   # Plugin manifest (name, version, paths)
    skills/                      # Skill definitions (SKILL.md files)
    agents/                      # Agent definitions (AGENT.md files)
    README.md                    # Plugin documentation
```

## Adding a New Plugin

1. Create a new directory under `plugins/<plugin-name>/`
2. Add `.claude-plugin/plugin.json` with the plugin manifest
3. Add `skills/` and/or `agents/` directories with SKILL.md/AGENT.md files
4. Add a README.md documenting the plugin
5. Register the plugin in `.claude-plugin/marketplace.json` under the `plugins` array

**Note:** Do not add commands—use skills instead. As of Claude Code 2.1.3+, commands have been merged into skills.

## Skill and Agent Frontmatter

Skills and agents should include frontmatter for proper registration and invocation control.

**Skill frontmatter (`skills/<name>/SKILL.md`):**
```yaml
---
name: skill-name
description: When Claude should use this skill
disable-model-invocation: false  # true = user-only via /command
user-invocable: true             # false = Claude-only, hidden from /menu
---
```

**Agent frontmatter (`agents/<name>.md`):**
```yaml
---
name: agent-name
description: When Claude should use this agent
tools: Read, Grep, Glob        # omit to inherit all tools
model: sonnet                   # sonnet, opus, haiku, or inherit (default)
permissionMode: default         # default, acceptEdits, dontAsk, bypassPermissions, plan
maxTurns: 5                     # max agentic turns before stopping
background: false               # true = runs concurrently
skills:                         # full skill content injected at startup
  - plugin-name:skill-name
color: green                    # UI color for identifying the agent
---
```

See the [subagents documentation](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields) for the complete field reference (including `disallowedTools`, `mcpServers`, `hooks`, `memory`, `isolation`).

Always include a clear `description` that explains when the skill or agent should be used; Claude uses the description to decide when to delegate.

See the [skills documentation](https://code.claude.com/docs/en/skills) for more details.

## Plugin Manifest Format

```json
{
  "name": "plugin-name",
  "version": "0.1.0",
  "description": "Description of the plugin",
  "author": { "name": "Author Name" },
  "skills": "./skills/",
  "agents": "./agents/"
}
```

## Releasing a New Version

When asked to "cut a release" or "release a new version":

1. **Determine bump type** from changes since last tag (`git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~10)..HEAD`):
   - `major` — breaking changes, major reorganization
   - `minor` — new skills, agents, or significant behavior changes
   - `patch` — bug fixes, doc updates, minor improvements

2. **Write the changelog entry** in `CHANGELOG.md` (repo root). Keep it scannable. Link each line to its PR with inline markdown links (e.g., `([#27](https://github.com/tmchow/tmc-marketplace/pull/27))`). Add a version comparison link reference at the bottom of the file (e.g., `[1.3.5]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.4...v1.3.5`). Make the version header a link using the reference (e.g., `## [1.3.5]`).

3. **Run the release script** — bumps version in both `plugins/iterative-engineering/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (plugin entry only, not marketplace metadata):
   ```bash
   ./scripts/release.sh <major|minor|patch>
   ```

4. **Commit and open a PR:**
   ```bash
   git add -A && git commit -m "chore(release): <version>"
   ```
   Push the branch and open a PR. The `v<version>` tag is created automatically when the PR merges (via `.github/workflows/auto-tag.yml`).

## Commit and PR Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages and PR titles:

- `feat:` — new skills, agents, or capabilities
- `fix:` — bug fixes, behavior corrections
- `chore:` — maintenance, config, releases (`chore(release): 1.3.5`)
- `docs:` — documentation-only changes
- `refactor:` — restructuring without behavior change

PR titles follow the same format. Keep them under 70 characters.

## Plugin Development Learnings

Patterns and pitfalls discovered while building skills, agents, and workflows.

### Plugin skill namespacing in agent frontmatter

When an agent's `skills:` field references a skill from the same plugin, use the full `plugin-name:skill-name` namespace. The bare skill name silently fails to resolve.

```yaml
# Wrong — skill won't load, no error
skills:
  - design-prototyping

# Correct
skills:
  - iterative-engineering:design-prototyping
```

### Agent invocation control

Agents have no `disable-model-invocation` or `user-invocable` fields (those only exist for skills). The `description` is the only mechanism to prevent Claude from auto-invoking an agent. For internal agents that should only be spawned by a specific skill, lead with the constraint and explain why standalone invocation won't work:

```yaml
# Vague — Claude may match this to general user requests
description: Generates HTML prototypes for design exploration.

# Clear — Claude understands this can't be used standalone
description: >
  Internal implementation detail of the design-exploration skill.
  Do not invoke directly — requires a structured variation spec
  that only the design-exploration orchestrator provides.
```

### Skills as preloaded agent knowledge

Non-user-invocable skills can carry invariant rules (file formats, schemas, validation checklists) that get injected into an agent's context at startup via the `skills:` frontmatter field. This separates what never changes (the craft) from what varies per invocation (the task).

Use `user-invocable: false` to hide the skill from the `/` menu. Keep `disable-model-invocation: false` (or omit it) so the agent preloading system can discover and inject the skill content.

```yaml
---
name: design-prototyping
user-invocable: false
disable-model-invocation: false
---
```

**Warning:** Setting `disable-model-invocation: true` makes the skill invisible to Claude entirely — including agent `skills:` preloading. The skill silently fails to inject with no error. Only use `disable-model-invocation: true` for skills that are exclusively user-invoked via `/command`.

### Custom agents save context

Custom agents receive only their markdown body as the system prompt, not the full Claude Code system prompt. This saves significant context for single-turn agents where every token matters. Combine with `maxTurns: 1` to structurally prevent multi-turn exploration.

### Keep docs in sync with skill changes

Strategy docs (`plugins/<name>/docs/`) describe the rationale and mechanics behind each skill. When a skill's behavior changes — new invocation syntax, different file handling, renamed agents — the corresponding strategy doc must be updated in the same PR. The README (`plugins/<name>/README.md`) must also reflect new skills, agents, or workflow changes.

Docs that commonly drift:
- **External CLI invocations** — when the exact command syntax changes (e.g., `codex review` → `codex exec review --base`), update the strategy doc's invocation tables and safety tables
- **Input handling** — when the mechanism for passing data to external CLIs changes (e.g., inline → file-based), update the Diff Handling / Document Handling sections
- **Agent/skill additions or renames** — when agents or skills are added, removed, or renamed, update the README's skills tables, agents tables, and any cross-references in strategy docs
- **Workflow changes** — when the end-to-end workflow changes (new stages, reordered steps), update the README's workflow diagram and stage boundaries table

### Agent + skill + orchestrator abstraction

When a skill orchestrates parallel agents, split responsibilities cleanly:

- **Agent definition** (the `.md` file): who it is and how it behaves. Keep minimal.
- **Preloaded skill**: the craft. Invariant rules, file format, schema, validation checklist. Loaded once, shared across all invocations.
- **Orchestrator prompt**: what to build. Per-invocation specifics (the brief, data, parameters). Don't repeat invariant content here.

This keeps orchestrator prompts lean (the rules live in the skill) and agent definitions focused (the knowledge lives in the skill).

## Installation (for users)

```bash
# Install both (default)
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash

# Codex skills only
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --codex-only

# Claude Code plugin only
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --claude-only
```

Or install manually:

```
/plugin marketplace add tmchow/tmc-marketplace
/plugin install <plugin-name>@tmc-marketplace
```
