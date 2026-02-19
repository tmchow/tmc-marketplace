#!/usr/bin/env python3
"""Assembly script for design exploration gallery (v2 — template + iframe architecture).

Usage: python3 assemble.py <exploration_dir> <round> <template_path>

Input files per variation:
  _var-{ID}.js    — JavaScript object literal (metadata + controls, NO html field)
  _var-{ID}.html  — Complete HTML page (rendered inside an iframe)
  _metadata.json  — Exploration metadata

Steps:
  1. Copies shell template to exploration_dir/v{round}.html
  2. Validates all subagent output files exist and are safe
  3. Replaces 3 template placeholders with variation content
  4. Cleans up temp files (_var-*.js, _var-*.html, _metadata.json)

Exit codes:
  0 — success
  1 — missing files (lists which variations are incomplete)
  2 — validation failure (dangerous content in variation html)
  3 — usage error
"""
import glob
import os
import re
import shutil
import sys


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
    js_files = sorted(glob.glob(os.path.join(d, "_var-*.js")))
    html_files = sorted(glob.glob(os.path.join(d, "_var-*.html")))

    if not js_files:
        print("ERROR: No variation JS files found (_var-*.js)", file=sys.stderr)
        sys.exit(1)

    # Check for incomplete file sets — both JS and HTML required per variation
    js_ids = {os.path.basename(f).replace("_var-", "").replace(".js", "") for f in js_files}
    html_ids = {os.path.basename(f).replace("_var-", "").replace(".html", "") for f in html_files}
    all_ids = js_ids | html_ids

    missing = []
    for vid in sorted(all_ids):
        parts = []
        if vid not in js_ids:
            parts.append("JS")
        if vid not in html_ids:
            parts.append("HTML")
        if parts:
            missing.append(f"  {vid}: missing {', '.join(parts)}")

    if missing:
        print("ERROR: Incomplete variation file sets:", file=sys.stderr)
        for line in missing:
            print(line, file=sys.stderr)
        sys.exit(1)

    # Validate HTML files — only danger tag is </template>
    for f in html_files:
        content = open(f).read()
        if "</template>" in content.lower():
            vid = os.path.basename(f)
            print(f"ERROR: {vid} contains \"</template>\" — this breaks the <template> wrapper", file=sys.stderr)
            sys.exit(2)

    print(f"Validated {len(js_files)} variations: {', '.join(sorted(all_ids))}")

    # --- Step 3b: Control quality checks (warnings, not errors) ---
    warnings = []
    for f in js_files:
        vid = os.path.basename(f).replace("_var-", "").replace(".js", "")
        js_content = open(f).read()
        html_var_path = os.path.join(d, f"_var-{vid}.html")
        html_content = open(html_var_path).read() if os.path.exists(html_var_path) else ""

        # Check for controls missing 'id' field
        control_blocks = re.findall(r'\{[^{}]*?label\s*:\s*[\'"]([^"\']+)[\'"][^{}]*?\}', js_content, re.DOTALL)
        id_fields = re.findall(r'id\s*:\s*[\'"]([^"\']+)[\'"]', js_content)
        if control_blocks and not id_fields:
            warnings.append(f"  {vid}: all controls missing 'id' field (template will auto-generate from label)")

        # Check for cssVar references in HTML
        css_vars = re.findall(r"cssVar\s*:\s*['\"]([^'\"]+)['\"]", js_content)
        for var in css_vars:
            var_ref = f"var({var})"
            if var_ref not in js_content and var_ref not in html_content:
                warnings.append(f"  {vid}: control targets {var} but var({var}) not found in JS or HTML")

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

    # Variation JS objects — comma-join all JS files
    objs = ",\n".join(open(f).read() for f in js_files)
    html = html.replace("__VARIATIONS_ARRAY__", objs)

    # Variation templates — wrap each HTML file in <template id="tpl-{id}">
    templates = []
    for f in html_files:
        vid = os.path.basename(f).replace("_var-", "").replace(".html", "")
        content = open(f).read()
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
    for pattern in ["_var-*.js", "_var-*.html", "_metadata.json"]:
        for f in glob.glob(os.path.join(d, pattern)):
            os.remove(f)
            cleaned += 1
    print(f"Cleaned up {cleaned} temp files")


if __name__ == "__main__":
    main()
