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

## Installation (for users)

```
/plugin marketplace add tmchow/tmc-marketplace
/plugin install <plugin-name>@tmc-marketplace
```
