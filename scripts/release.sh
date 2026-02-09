#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/release.sh <major|minor|patch>
# Bumps plugin version in plugin.json and marketplace.json plugin entry.
# Changelog entry should be written before running this script.

BUMP_TYPE="${1:-}"
PLUGIN="iterative-engineering"
PLUGIN_JSON="plugins/$PLUGIN/.claude-plugin/plugin.json"
MARKETPLACE_JSON=".claude-plugin/marketplace.json"

if [[ -z "$BUMP_TYPE" ]] || [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
  echo "Usage: ./scripts/release.sh <major|minor|patch>"
  exit 1
fi

# Read current version from plugin.json (source of truth)
CURRENT_VERSION=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])")
if [[ -z "$CURRENT_VERSION" ]]; then
  echo "Error: Could not read version from $PLUGIN_JSON"
  exit 1
fi

# Split version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump
case "$BUMP_TYPE" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "Bumping $CURRENT_VERSION → $NEW_VERSION ($BUMP_TYPE)"

# Update plugin.json
python3 -c "
import json
with open('$PLUGIN_JSON', 'r') as f:
    data = json.load(f)
data['version'] = '$NEW_VERSION'
with open('$PLUGIN_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

# Update marketplace.json (only the matching plugin entry, not metadata.version)
python3 -c "
import json
with open('$MARKETPLACE_JSON', 'r') as f:
    data = json.load(f)
for plugin in data.get('plugins', []):
    if plugin['name'] == '$PLUGIN':
        plugin['version'] = '$NEW_VERSION'
with open('$MARKETPLACE_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

echo "Updated $PLUGIN_JSON"
echo "Updated $MARKETPLACE_JSON"
echo ""
echo "Next steps:"
echo "  1. Verify CHANGELOG.md has an entry for $NEW_VERSION"
echo "  2. Commit: git add -A && git commit -m 'chore(release): $NEW_VERSION'"
echo "  3. Tag:    git tag v$NEW_VERSION"
echo "  4. Push:   git push && git push --tags"
