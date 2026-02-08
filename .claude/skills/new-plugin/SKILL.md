---
name: new-plugin
description: Scaffold a new plugin with proper marketplace structure
disable-model-invocation: true
user-invocable: true
---

# New Plugin Scaffolder

Create a new plugin for the tmc-marketplace with the correct structure.

## Usage

```
/new-plugin <plugin-name>
```

## What This Creates

```
plugins/<plugin-name>/
  .claude-plugin/plugin.json   # Plugin manifest
  skills/                      # Skills directory
  agents/                      # Agents directory (if needed)
  README.md                    # Plugin documentation
```

## Workflow

1. **Get plugin name** from args or ask user
2. **Validate name**: lowercase, hyphenated, no spaces
3. **Check for conflicts**: Ensure plugin doesn't already exist
4. **Create structure**:

### plugin.json template

```json
{
  "name": "<plugin-name>",
  "version": "0.1.0",
  "description": "<description>",
  "author": {
    "name": "Trevin Chow"
  },
  "skills": "./skills/"
}
```

### README.md template

```markdown
# <plugin-name>

<description>

## Installation

\`\`\`
/plugin marketplace add tmchow/tmc-marketplace
/plugin install <plugin-name>@tmc-marketplace
\`\`\`

## Skills

- List skills here

## Agents

- List agents here (if any)
```

5. **Register in marketplace**: Add entry to `.claude-plugin/marketplace.json`
6. **Confirm**: Show created structure and next steps

## Next Steps After Creation

Tell the user:
- Add skills to `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`
- Add agents to `plugins/<plugin-name>/agents/<agent-name>/AGENT.md` (optional)
- Update README.md with skill/agent documentation
- Run `/validate-plugin <plugin-name>` before committing
