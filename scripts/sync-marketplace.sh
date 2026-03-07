#!/usr/bin/env bash
set -euo pipefail

# Reads version from each plugin's plugin.json and updates the matching
# entry in .claude-plugin/marketplace.json.
# Called by the release-please workflow after version bumps.

MARKETPLACE_JSON=".claude-plugin/marketplace.json"

for plugin_dir in plugins/*/; do
  plugin_json="${plugin_dir}.claude-plugin/plugin.json"
  [ -f "$plugin_json" ] || continue

  PLUGIN_NAME=$(python3 -c "import json; print(json.load(open('$plugin_json'))['name'])")
  PLUGIN_VERSION=$(python3 -c "import json; print(json.load(open('$plugin_json'))['version'])")

  python3 -c "
import json
with open('$MARKETPLACE_JSON', 'r') as f:
    data = json.load(f)
for plugin in data.get('plugins', []):
    if plugin['name'] == '$PLUGIN_NAME':
        plugin['version'] = '$PLUGIN_VERSION'
with open('$MARKETPLACE_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
  echo "Synced $PLUGIN_NAME v$PLUGIN_VERSION to $MARKETPLACE_JSON"
done
