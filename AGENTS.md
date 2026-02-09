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

**Agent frontmatter (`agents/<name>/AGENT.md`):**
```yaml
---
name: agent-name
description: When Claude should use this agent
---
```

Always include a clear `description` that explains when the skill or agent should be used—this helps Claude decide when to invoke it automatically.

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

2. **Write the changelog entry** in `plugins/iterative-engineering/CHANGELOG.md`. Keep it scannable. Include PR references inline on each line (e.g., `(#27)` — auto-links on GitHub). Add a version comparison link reference at the bottom of the file (e.g., `[1.3.5]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.4...v1.3.5`). Make the version header a link using the reference (e.g., `## [1.3.5]`).

3. **Run the release script** — bumps version in both `plugins/iterative-engineering/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (plugin entry only, not marketplace metadata):
   ```bash
   ./scripts/release.sh <major|minor|patch>
   ```

4. **Commit and open a PR:**
   ```bash
   git add -A && git commit -m "chore(release): <version>"
   ```
   Push the branch and open a PR. The `v<version>` tag is created automatically when the PR merges (via `.github/workflows/auto-tag.yml`).

## Installation (for users)

```
/plugin marketplace add tmchow/tmc-marketplace
/plugin install <plugin-name>@tmc-marketplace
```
