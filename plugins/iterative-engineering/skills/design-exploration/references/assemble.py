#!/usr/bin/env python3
"""Assembly script for design exploration gallery (v3 — single-file architecture).

Usage: python3 assemble.py <exploration_dir> <round> <template_path>

Input files per variation:
  _var-{ID}.html  — Complete HTML page with embedded variation-meta JSON block
  _metadata.json  — Exploration metadata

Each HTML file contains a <script type="application/json" id="variation-meta">
block in <head> with the variation's identity (id, family, name, etc.) and
controls array. The assembly script extracts this JSON to build the variations
array for the gallery shell.

Steps:
  1. Copies shell template to exploration_dir/v{round}.html
  2. Validates all agent output files exist and are safe
  3. Extracts variation-meta JSON from each HTML file
  4. Replaces 3 template placeholders with variation content
  5. Cleans up temp files (_var-*.html, _metadata.json)

Exit codes:
  0 — success (warnings may be printed)
  1 — missing files (lists which variations are incomplete)
  2 — validation failure (orphaned </template> tags)
  3 — usage error
"""
import glob
import json
import os
import re
import shutil
import sys


def extract_variation_meta(html_content):
    """Extract JSON from <script type="application/json" id="variation-meta"> block."""
    # Match regardless of attribute order (type before id, or id before type)
    pattern = r'<script\s+(?:type="application/json"\s+id="variation-meta"|id="variation-meta"\s+type="application/json")\s*>(.*?)</script>'
    match = re.search(pattern, html_content, re.DOTALL)
    if not match:
        return None
    try:
        return json.loads(match.group(1).strip())
    except json.JSONDecodeError:
        return None


def meta_to_js_object(meta):
    """Convert a variation-meta dict to a JavaScript object literal string."""
    lines = []
    lines.append("{")
    for key in ["id", "family", "familyName", "name", "layoutType", "aesthetic", "description"]:
        val = meta.get(key, "")
        escaped = str(val).replace("'", "\\'")
        lines.append(f"  {key}: '{escaped}',")

    controls = meta.get("controls", [])
    lines.append(f"  controls: {json.dumps(controls, indent=4)}")
    lines.append("}")
    return "\n".join(lines)


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <exploration_dir> <round> <template_path>", file=sys.stderr)
        sys.exit(3)

    d = sys.argv[1]
    r = sys.argv[2]
    template = sys.argv[3]

    html_path = os.path.join(d, f"v{r}.html")
    meta_path = os.path.join(d, "_metadata.json")

    # --- Step 1: Copy template ---
    if not os.path.exists(template):
        print(f"ERROR: Template not found at {template}", file=sys.stderr)
        sys.exit(3)
    shutil.copy2(template, html_path)

    # --- Step 2: Check metadata ---
    if not os.path.exists(meta_path):
        print(f"ERROR: Metadata not found at {meta_path}", file=sys.stderr)
        sys.exit(1)

    # --- Step 3: Find and validate variation files ---
    html_files = sorted(glob.glob(os.path.join(d, "_var-*.html")))

    if not html_files:
        print("ERROR: No variation HTML files found (_var-*.html)", file=sys.stderr)
        sys.exit(1)

    # Validate HTML files
    variation_data = []  # (vid, html_content, meta_dict)
    errors = []

    for f in html_files:
        vid = os.path.basename(f).replace("_var-", "").replace(".html", "")
        content = open(f).read()

        # Check for unbalanced </template> tags — only orphaned close tags break
        # the <template> wrapper. Balanced nesting (e.g., Alpine.js <template x-for>)
        # is safe because the HTML parser closes the nearest open <template>.
        if "</template>" in content.lower():
            # Strip <script>...</script> blocks first — </template> inside JS
            # string literals is inert (HTML parser treats <script> as raw text)
            stripped = re.sub(r'<script[\s>].*?</script>', '', content, flags=re.DOTALL | re.IGNORECASE)
            opens = len(re.findall(r'<template[\s>]', stripped, re.IGNORECASE))
            closes = len(re.findall(r'</template\s*>', stripped, re.IGNORECASE))
            if closes > opens:
                print(f"ERROR: _var-{vid}.html has {closes - opens} orphaned </template> close tag(s) — this breaks the gallery wrapper. Remove unmatched </template> tags.", file=sys.stderr)
                sys.exit(2)
            elif opens > 0:
                print(f"  {vid}: {opens} balanced <template> tags (safe — e.g., Alpine.js x-for/x-if)")

        meta = extract_variation_meta(content)
        if meta is None:
            errors.append(f"  {vid}: missing or invalid <script id=\"variation-meta\"> JSON block")
        else:
            variation_data.append((vid, content, meta))

    if errors:
        print("ERROR: Variation files with missing metadata:", file=sys.stderr)
        for line in errors:
            print(line, file=sys.stderr)
        sys.exit(1)

    var_ids = [vd[0] for vd in variation_data]
    print(f"Validated {len(variation_data)} variations: {', '.join(var_ids)}")

    # --- Step 3b: Control quality checks (warnings, not errors) ---
    warnings = []
    for vid, html_content, meta in variation_data:
        controls = meta.get("controls", [])

        # Check for controls missing 'id' field
        has_ids = all(c.get("id") for c in controls)
        if controls and not has_ids:
            warnings.append(f"  {vid}: some controls missing 'id' field (template will auto-generate from label)")

        # Check for cssVar references in HTML (skip event controls — they use JS listeners)
        for c in controls:
            css_var = c.get("cssVar")
            is_event = c.get("event", False)
            if css_var and not is_event and f"var({css_var})" not in html_content:
                warnings.append(f"  {vid}: control '{c.get('label', '?')}' targets {css_var} but var({css_var}) not found in HTML")
            if is_event and "control-change" not in html_content:
                warnings.append(f"  {vid}: event control '{c.get('label', '?')}' but no 'control-change' listener found in HTML")

    if warnings:
        print("WARNINGS (controls may not work as expected):")
        for w in warnings:
            print(w)
    else:
        print("Control quality checks passed")

    # --- Step 4: Assemble ---
    html = open(html_path).read()

    # Metadata
    html = html.replace("__METADATA_JSON__", open(meta_path).read())

    # Variation JS objects — extract from embedded JSON, convert to JS object literals
    objs = ",\n".join(meta_to_js_object(meta) for _, _, meta in variation_data)
    html = html.replace("__VARIATIONS_ARRAY__", objs)

    # Variation templates — wrap each HTML file in <template id="tpl-{id}">
    templates = []
    for vid, content, _ in variation_data:
        # Extract body class — the <template> HTML parser strips <body> attributes,
        # so we preserve them as a data attribute for the shell to reapply
        body_match = re.search(r'<body\s[^>]*class="([^"]*)"', content)
        body_attr = f' data-body-class="{body_match.group(1)}"' if body_match else ''
        templates.append(f'  <template id="tpl-{vid.lower()}"{body_attr}>\n{content}\n  </template>')
    html = html.replace("__VARIATION_TEMPLATES__", "\n".join(templates))

    open(html_path, "w").write(html)

    line_count = html.count("\n") + 1
    print(f"Assembled {html_path} ({line_count} lines)")

    # --- Step 5: Cleanup ---
    cleaned = 0
    for pattern in ["_var-*.html", "_metadata.json"]:
        for f in glob.glob(os.path.join(d, pattern)):
            os.remove(f)
            cleaned += 1
    print(f"Cleaned up {cleaned} temp files")


if __name__ == "__main__":
    main()
