---
name: validate-plugin
description: Validate plugin structure and manifests against marketplace requirements
user-invocable: true
---

# Plugin Validator

Validate a plugin meets marketplace requirements before publishing.

## Usage

```
/validate-plugin <plugin-name>
```

Or validate all plugins:

```
/validate-plugin --all
```

## Validation Checks

### 1. Plugin Structure

```bash
# Check required files exist
ls plugins/<plugin-name>/.claude-plugin/plugin.json
ls plugins/<plugin-name>/README.md
ls plugins/<plugin-name>/skills/  # At least skills/ or agents/ must exist
```

### 2. plugin.json Validation

Required fields:
- `name` - must match directory name
- `version` - semver format (e.g., "0.1.0")
- `description` - non-empty string
- `author.name` - non-empty string
- `skills` - path to skills directory (if skills exist)
- `agents` - path to agents directory (if agents exist)

```bash
# Validate JSON syntax
cat plugins/<plugin-name>/.claude-plugin/plugin.json | jq .
```

### 3. Skill Validation

For each `plugins/<plugin-name>/skills/*/SKILL.md`:

**Required frontmatter:**
```yaml
---
name: skill-name        # Required
description: ...        # Required - when Claude should use this
---
```

**Optional frontmatter:**
```yaml
disable-model-invocation: true   # User-only skill
user-invocable: false            # Claude-only skill
```

**Check:** Frontmatter must be valid YAML between `---` markers

### 4. Agent Validation

For each `plugins/<plugin-name>/agents/*/AGENT.md`:

**Required frontmatter:**
```yaml
---
name: agent-name        # Required
description: ...        # Required - when Claude should use this agent
---
```

### 5. Marketplace Registry

Check `.claude-plugin/marketplace.json` contains entry:

```json
{
  "plugins": [
    {
      "name": "<plugin-name>",
      "source": "./plugins/<plugin-name>",
      "description": "...",
      "version": "..."
    }
  ]
}
```

### 6. No Deprecated Commands

Verify no `commands/` directory exists (commands merged into skills in Claude Code 2.1.3+)

## Output Format

```
Validating plugin: <plugin-name>

[PASS] Plugin structure valid
[PASS] plugin.json valid
[PASS] 2 skills validated
[WARN] No agents defined (optional)
[PASS] Marketplace entry found
[PASS] No deprecated commands

Result: VALID (5 passed, 1 warning, 0 errors)
```

Or if errors:

```
[FAIL] plugin.json missing required field: description
[FAIL] skills/my-skill/SKILL.md missing frontmatter

Result: INVALID (3 passed, 0 warnings, 2 errors)
```
