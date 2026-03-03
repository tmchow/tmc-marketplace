---
name: design-prototyping
description: The craft of building design exploration prototypes. Covers file structure, control wiring, styling conventions, and output validation. Preloaded into the html-prototyper agent. Not intended for direct invocation.
user-invocable: false
disable-model-invocation: false
---

# Design Prototyping

How to build a single self-contained design exploration variation file.

## File Format

Every variation is a single HTML file with embedded metadata. The file is a complete page rendered inside an iframe in the gallery shell.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <!-- Google Fonts <link> for specified fonts -->
  <script type="application/json" id="variation-meta">
  {
    "id": "A1",
    "family": "A",
    "familyName": "...",
    "name": "...",
    "layoutType": "...",
    "aesthetic": "...",
    "description": "...",
    "controls": [ /* control objects — see Control Schema below */ ]
  }
  </script>
  <style>
    :root {
      /* All theme values as CSS custom properties */
    }
    :root * {
      transition: color 0.3s ease, background-color 0.3s ease,
                  border-color 0.3s ease, padding 0.3s ease,
                  gap 0.3s ease, font-size 0.3s ease,
                  border-radius 0.3s ease, box-shadow 0.3s ease,
                  max-width 0.3s ease, width 0.3s ease;
    }
  </style>
</head>
<body>
  <!-- Variation content -->
</body>
</html>
```

### Metadata Block

The `<script type="application/json" id="variation-meta">` block in `<head>` contains valid JSON with:

| Field | Type | Description |
|---|---|---|
| `id` | string | Variation code, e.g. `"A1"`, `"B2"` |
| `family` | string | Family letter, e.g. `"A"` |
| `familyName` | string | Human-readable family name |
| `name` | string | Memorable variation name |
| `layoutType` | string | Layout description, e.g. `"Sidebar + Cards"` |
| `aesthetic` | string | Aesthetic description, e.g. `"Clean Light"` |
| `description` | string | One-line description of the variation |
| `controls` | array | 4-6 control objects (see schema below) |

Populate all fields from the variation brief provided in the prompt.

## Styling Rules

- **Tailwind-first.** Utility classes for layout, spacing, colors, typography, borders, shadows. Custom CSS in `<style>` only for: `:root` property definitions, `@keyframes`, transitions, scrollbar styling.
- **CSS custom properties on `:root`.** All theme values: colors, fonts, spacing, radii. Unprefixed names: `--bg`, `--text`, `--accent`. Never `--shell-*`. Reference via Tailwind arbitrary values: `bg-[var(--bg)]`, `text-[var(--text)]`, `rounded-[var(--radius)]`.
- **Self-contained.** No external images. Use CSS gradients, inline SVG, Unicode.
- **Realistic content only.** Never lorem ipsum. Use the data from the prompt.
- **Motion.** Hover transitions on interactive elements. At least one entrance animation with staggered delays. JavaScript is allowed for interactive demonstrations (accordions, toggles, wizards).
- **Component scope.** For components (not full pages), center content in the viewport: `min-h-screen flex items-center justify-center p-8` on `<body>`.
- **Viewport containment.** The outermost container element must use `overflow-hidden` (or `overflow-auto` if scrolling is intentional). This prevents content from breaking out of the iframe bounds. Apply to the root layout wrapper, not `<body>`.
- **Transition CSS required.** The `:root * { transition: ... }` rule (shown in file format above) must be included for smooth control changes.

## Control Schema

Controls are **JSON metadata only**. Define them in the `controls` array inside the variation-meta block. A separate gallery shell reads this JSON and renders the control UI (sliders, dropdowns, toggles) outside the iframe.

**Do NOT build any control panel, settings panel, or configuration UI into the variation HTML.** The variation contains only the design content. All control rendering and interaction is handled by the shell.

Include 4-6 controls in the `controls` array.

### Two types of controls

**CSS controls** (default) — The shell sets a CSS custom property on `:root` via `style.setProperty()`. The HTML references it via `var()`. This is automatic — no JS needed in the variation. Use for visual parameters: colors, spacing, radii, opacity, font sizes, layout widths.

**Event controls** — For behavioral parameters that CSS can't express (sort order, filter thresholds, data grouping, expansion mode). The shell sets the CSS var AND dispatches a `CustomEvent` on the iframe's `document`. The variation includes a JS listener that reads the value and updates the DOM.

To make a control an event control, add `"event": true` to the control JSON. The shell dispatches `control-change` events with `{ detail: { id, value } }` for all controls, but only event controls need a listener.

Event controls still need a `cssVar` (it can be a dummy like `"--sort-order"`) so the shell has something to set. The actual work happens in your listener.

### Range

Value + unit are set directly on the CSS var.

```json
{
  "id": "sidebar-width",
  "label": "Sidebar Width",
  "type": "range",
  "min": 180, "max": 320, "step": 10,
  "options": null,
  "value": 240,
  "defaultValue": 240,
  "unit": "px",
  "cssVar": "--sidebar-width"
}
```

### Select (single CSS var)

Maps option labels to CSS values via `cssValues`.

```json
{
  "id": "accent",
  "label": "Accent Color",
  "type": "select",
  "min": null, "max": null, "step": null,
  "options": ["coral", "teal", "indigo", "amber"],
  "cssValues": { "coral": "#e07a5f", "teal": "#4a9e8f", "indigo": "#5c6bc0", "amber": "#d4a853" },
  "value": "teal",
  "defaultValue": "teal",
  "unit": "",
  "cssVar": "--accent"
}
```

### Select (multi-var)

When one control changes multiple CSS properties, use an object as the `cssValues` value and set `cssVar: null`.

```json
{
  "id": "mood",
  "label": "Mood",
  "type": "select",
  "min": null, "max": null, "step": null,
  "options": ["light", "dark", "midnight"],
  "cssValues": {
    "light":    { "--bg": "#faf9f7", "--text": "#2d2a26", "--text-dim": "#8a8580", "--border": "#e5e0d8" },
    "dark":     { "--bg": "#1e1e2a", "--text": "#e0ddd8", "--text-dim": "#8a8580", "--border": "#333340" },
    "midnight": { "--bg": "#0d0d14", "--text": "#c8c4be", "--text-dim": "#6a6660", "--border": "#1e1e2a" }
  },
  "value": "light",
  "defaultValue": "light",
  "unit": "",
  "cssVar": null
}
```

### Toggle

Maps `true`/`false` to CSS values. Without `cssValues`, defaults to `"1"`/`"0"`.

```json
{
  "id": "show-dividers",
  "label": "Show Dividers",
  "type": "toggle",
  "min": null, "max": null, "step": null,
  "options": null,
  "cssValues": { "true": "1px", "false": "0px" },
  "value": true,
  "defaultValue": true,
  "unit": "",
  "cssVar": "--divider-width"
}
```

### Event Control Pattern

When a control needs to drive behavior (not just CSS), mark it with `"event": true` and add a listener in the variation's `<script>`:

```json
{
  "id": "sort-order",
  "label": "Sort By",
  "type": "select",
  "options": ["status", "last-active", "name"],
  "cssValues": { "status": "status", "last-active": "last-active", "name": "name" },
  "value": "status",
  "defaultValue": "status",
  "unit": "",
  "cssVar": "--sort-order",
  "event": true
}
```

```html
<script>
  document.addEventListener('control-change', (e) => {
    const { id, value } = e.detail;
    if (id === 'sort-order') {
      sortAgents(value);  // your function that re-sorts the DOM
    }
  });

  // Also handle initial state — controls-ready fires once after all
  // CSS vars are set on first iframe load
  document.addEventListener('controls-ready', () => {
    const sort = getComputedStyle(document.documentElement)
      .getPropertyValue('--sort-order').trim();
    if (sort) sortAgents(sort);
  });
</script>
```

The `controls-ready` event fires once after all controls are applied on iframe load. Use it to read initial CSS var values and set up initial state. Individual `control-change` events fire on each subsequent control adjustment.

## Control Rules

- **`id` is required.** Unique within the variation. Without it, the control renders but interactions do nothing.
- **`value` and `defaultValue` must always be set.** Never null or undefined.
- **`cssValues` must be an object keyed by option labels**, never an array. `{ "compact": "0.75rem" }` not `["0.75rem", "1rem"]`.
- **Never use `unit: "%"` on range controls.** The `%` breaks `calc()` expressions. Use unitless values and let CSS handle the math: `calc(var(--opacity) * 1%)`.
- **Select controls must include `cssValues`.** Without it, the CSS var gets a label string like `--bg: warm` which is useless to CSS.
- **Every `cssVar` must be consumed in the HTML.** Reference via Tailwind arbitrary values (`rounded-[var(--card-radius)]`) or in CSS. A control that defines `--card-radius` is dead if the HTML uses `rounded-xl` instead.
- **All visual states must use `var()` for controlled properties.** Hover, active, and focus states must reference CSS vars, not hardcoded values. Use `color-mix()` for derived colors: `color-mix(in srgb, var(--accent) 10%, transparent)`.
- **Never use `[style*="..."]` attribute selectors** for CSS variable detection. They are fragile.
- **CSS custom properties on `:root` only.** Not scoped by class. The iframe provides isolation. Controls apply via `documentElement.style.setProperty()`.
- **The control system can only set CSS custom properties.** It cannot toggle CSS classes. All controlled styling must flow through `var()` references.
- **Behavioral controls need `"event": true` and a JS listener.** If a control drives behavior (sorting, filtering, thresholds, expansion mode), mark it `"event": true` and add a `control-change` event listener. Without the listener, the CSS var is set but nothing reads it.

**CRITICAL: The metadata block MUST use exactly `id="variation-meta"`.** This ID is machine-parsed by the assembly script. Not `variation-metadata`, not `exploration-metadata` — exactly `variation-meta`. If the ID is wrong, the variation will silently fail to appear in the gallery.

## Pre-Output Checklist

Verify before writing:

- [ ] `<script type="application/json" id="variation-meta">` block is in `<head>` with valid JSON
- [ ] Every control has an `id` field (unique within this variation)
- [ ] Every control's `cssVar` appears as `var(--xxx)` in the HTML or is consumed by a `control-change` event listener
- [ ] `cssValues` is an object keyed by option labels, never an array
- [ ] All controlled styling uses `var()` references, no CSS class toggling
- [ ] No range control uses `unit: "%"`
- [ ] Hover/active/focus states use `var()` for any property driven by a control
- [ ] Every `<template>` open tag has a matching `</template>` close tag (balanced nesting is safe; orphaned close tags break assembly)
- [ ] CSS custom properties are defined on `:root` (not scoped by class)
- [ ] HTML includes Tailwind CDN and Google Fonts in `<head>`
- [ ] HTML includes transition CSS for smooth control changes
- [ ] HTML contains NO control panel UI (no sliders, dropdowns, toggles, settings panels)
- [ ] The outermost container uses `overflow-hidden` or `overflow-auto`

### Mandatory QA — Controls Audit

**After writing the HTML, before finishing**, audit every control against its wiring:

For each control in the `controls` array:
1. **Find where it's consumed.** Search the HTML for `var(--{cssVar})` or the `control-change` listener handling its `id`.
2. **If not consumed, fix it.** Either: (a) add the `var()` reference to the HTML where the property should apply, or (b) add a `control-change` listener if the control is behavioral.
3. **Verify visible impact.** Ask: "If I move this slider from min to max (or toggle this), would the change be obvious to someone across the room?" If not, widen the range or choose a more impactful property.

This audit catches the most common failure mode: controls that are defined in JSON but have no effect on the rendered output.

## Forbidden

- **No control UI in the variation.** Never build sliders, dropdowns, toggle switches, settings panels, or any control interface into the HTML. Controls are JSON metadata; the gallery shell renders all control UI.
- **No orphaned `</template>` tags.** Every `</template>` must have a matching `<template>` open tag. The assembly system wraps each file in a `<template>` element; an orphaned close tag would break the wrapper. Balanced `<template>` nesting (e.g., Alpine.js `<template x-for>`, `<template x-if>`) is safe.
