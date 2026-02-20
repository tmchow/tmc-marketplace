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
- **Transition CSS required.** The `:root * { transition: ... }` rule (shown in file format above) must be included for smooth control changes.

## Control Schema

Controls are **JSON metadata only**. Define them in the `controls` array inside the variation-meta block. A separate gallery shell reads this JSON and renders the control UI (sliders, dropdowns, toggles) outside the iframe. The shell applies values to the iframe via `style.setProperty()` on `:root`.

**Do NOT build any control panel, settings panel, or configuration UI into the variation HTML.** The variation contains only the design content. All control rendering and interaction is handled by the shell.

Include 4-6 controls in the `controls` array.

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

## Pre-Output Checklist

Verify before writing:

- [ ] `<script type="application/json" id="variation-meta">` block is in `<head>` with valid JSON
- [ ] Every control has an `id` field (unique within this variation)
- [ ] Every control's `cssVar` appears as `var(--xxx)` in the HTML
- [ ] `cssValues` is an object keyed by option labels, never an array
- [ ] All controlled styling uses `var()` references, no CSS class toggling
- [ ] No range control uses `unit: "%"`
- [ ] Hover/active/focus states use `var()` for any property driven by a control
- [ ] HTML does NOT contain `</template>` (the only forbidden tag)
- [ ] CSS custom properties are defined on `:root` (not scoped by class)
- [ ] HTML includes Tailwind CDN and Google Fonts in `<head>`
- [ ] HTML includes transition CSS for smooth control changes
- [ ] HTML contains NO control panel UI (no sliders, dropdowns, toggles, settings panels)

## Forbidden

- **No control UI in the variation.** Never build sliders, dropdowns, toggle switches, settings panels, or any control interface into the HTML. Controls are JSON metadata; the gallery shell renders all control UI.
- **No `</template>` tag.** The assembly system wraps each file in a `<template>` element; a closing tag would break the wrapper. If needed in a `<script>` string, escape as `<\/template>`.
