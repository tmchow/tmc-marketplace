---
name: iterative:design-exploration
description: >
  Explore radically different design approaches for any page, component,
  or feature. Generates an interactive gallery with per-variation tuning
  controls, star ratings, and AI-ready export for iterating across multiple
  rounds. Concludes with a design direction document. Also triggers when the
  user pastes design exploration feedback (starts with "## Design Exploration
  Feedback") to iterate on a previous round, or when they paste a design
  direction (starts with "## Design Direction") to finalize. Triggers:
  "explore designs for", "generate design variations", "design exploration",
  "show me different ways to design", "iterate on this design exploration".
---

# Design Exploration

Generate a single self-contained HTML file presenting distinct design variations (scaled to scope — see Step 2) with per-variation interactive controls, a rating/feedback system, and structured export. The goal is divergent thinking: explore fundamentally different approaches to a design problem before converging on a direction. "Different" means different on the right axis — usually different interaction models, not different visual themes.

## When to Use

- Before brainstorming, to anchor a greenfield discussion with visual options
- After brainstorming, to explore how requirements could look/feel before tech planning
- Standalone, when someone wants to see design options for any page, component, or feature
- When iterating on a previous round of explorations (user pastes feedback from export)

## Key Principles

1. **Diverge before converging** — The point is to explore fundamentally different approaches. But "different" must be on the right axis: different interaction models for functional problems, different visual identities for aesthetic problems. A neon terminal and a boutique card layout that have identical form flows are NOT different where it matters.
2. **Multiple rounds are normal** — The first round is broad exploration. Subsequent rounds refine based on feedback. The skill supports this loop natively.
3. **The direction doc is the durable output** — HTML galleries are working artifacts. The design direction document captures what was chosen and why.
4. **Standalone or in-workflow** — Works independently or as part of the brainstorming → tech-planning pipeline. Adapts handoff based on context.

## Process

1. **Detect context (always first)** — check for existing explorations before responding. Resume, iterate, or fresh start.
2. **Understand the request** — only for fresh explorations. What is being designed, for whom, divergence axis, constraint level
3. **Plan the variations** — variations across families, count scaled to scope, divergent on the right axis
4. **Generate the HTML file** — gallery with variations, controls, ratings, metadata, export
5. **Conclude** — when the user converges, capture the design direction

## File Structure

All artifacts for an exploration live in a dated topic directory:

```
docs/design-explorations/YYYY-MM-DD-<topic>/
  v1.html          ← first round
  v2.html          ← refined round
  v3.html          ← further refinement

docs/design-directions/
  YYYY-MM-DD-<topic>-design-direction.md    ← written at conclude
```

---

## Step 0: Detect Context (MANDATORY — runs first, before ANY response to the user)

**Your very first action must be detection — before any Q&A, scoping questions, or even acknowledging the request.** Do NOT skip to Step 1 without completing the checks below.

### 0a. Check for feedback input

If the user's message contains structured feedback (ratings, reference to a previous exploration file), this is an iteration round. Extract the `Source:` path from the feedback, then read the metadata from that HTML file (see "Reading prior metadata" in Step 3). This gives you the families, variations, and round number. Proceed to Step 2 with both the feedback and the metadata as context.

### 0b. Check for existing explorations

**Before responding to the user**, check what's in `docs/design-explorations/`. If any existing exploration looks relevant to the user's request, tell them you found it and ask whether to iterate or start fresh. If iterating, read the previous round's metadata (see Step 3). Proceed to Step 2 — **skip Step 1 entirely**. If nothing relevant exists, proceed to Step 1.

---

## Step 1: Understand the Request

Input can range from a single sentence ("explore designs for a notification system") to a full PRD. The goal of this step is to gather enough context that the approach-based divergence planning in Step 2 produces meaningfully different directions — not random ones.

**This step only runs for fresh explorations** (no feedback input, no existing exploration to iterate on). If Step 0 found a previous round to iterate on, skip this step — the metadata provides the context.

### Adaptive scoping

Ask 0-2 scoping questions based on how much ambiguity exists. When a PRD or detailed requirements already exist (e.g., from `iterative:brainstorming`), the problem space is already mapped — determine the divergence axis from the existing context and proceed to Step 2. The PRD informs the exploration but doesn't constrain the creative surface; the whole point is to discover visual and interaction possibilities the requirements alone can't express.

When input is lighter (a sentence or brief description), component prompts tend to describe the full problem; larger scopes tend to leave more genuinely open. The right questions inform the exploration — the wrong ones constrain it. The test: does knowing the answer change *which approaches you'd explore*, or does it just eliminate options the user should see? If it eliminates options, don't ask — let the exploration show them.

### What you need to know before proceeding (infer from context when possible)

- **Divergence axis** — interaction, visual, or both? (see below — usually obvious from context)
- **The goal** — what problem is being solved
- **Who** — audience and their context (obvious for components, worth asking for full pages)
- **Constraint level** — greenfield or fitting into an existing app?

### Divergence Axis

The divergence axis determines WHAT varies between families. This is the most important decision — getting it wrong produces explorations that are visually impressive but practically useless.

**Interaction divergence (DEFAULT)** — Families explore different ways the thing WORKS. Different behavior, flow, information architecture, progressive disclosure, state handling. All variations share a clean, professional visual treatment — a realistic neutral UI that looks like it belongs in a real product. The user is comparing interaction models, not color palettes.

- Default for: components, features, anything inside an existing app, anything with a clear functional problem to solve
- Example: "price input with sale toggle" → one family uses inline toggle that reveals fields, another uses side-by-side comparison, another uses a stepped wizard, another shows a live storefront preview. All look like a professional admin panel.
- Example: "notification center" → drawer vs popover vs inline expansion vs full-page view. All share the same visual language.

**Visual divergence** — Families explore different ways the thing LOOKS. Same functional structure (or a simple reference structure), different aesthetics, typography, spatial composition, atmosphere. Useful for establishing visual identity when there IS no existing design language.

- Use for: landing pages, brand exploration, design system foundations, or when the user explicitly asks to explore visual styles
- Example: "landing page for a new product" → one family is brutalist editorial, another is luxury minimal, another is playful illustrated
- This mode triggers the full creative typography, color, and atmosphere treatment

**Both** — Families differ in both visual identity AND interaction model. Only appropriate when the entire page or app is open — no existing design system, no existing interaction patterns, full greenfield.

- Use for: full-page or full-app greenfield explorations where both visual identity and interaction model are genuinely open questions
- Rare — most explorations have at least some constraints or a clear functional problem that makes interaction the primary axis

**How to determine the axis:**

| Signal | Axis |
|---|---|
| "explore different ways to [do X]" | Interaction |
| Component or feature scope | Interaction |
| Mentions an existing app, screen, or design system | Interaction |
| Has a clear functional problem to solve | Interaction |
| "explore visual styles for...", "what should it look like" | Visual |
| Landing page, marketing site, brand identity | Visual |
| Full page, no existing app, no functional constraints | Both |

**When in doubt, default to interaction.** Wild visual divergence on a functional problem (like a price input rendered as a neon cyberpunk terminal) is rarely useful. Interaction divergence is almost always what people need — they want to see different UX approaches, rendered professionally, so they can make a decision about how the thing should work.

### Constraint Level

Orthogonal to the divergence axis — this determines whether visual choices are locked to an existing system or open.

**Within an existing app** — Visual language is locked. Axis is always interaction.
1. **Establish the visual boundaries.** Ask for or infer: color palette, font stack, border-radius, spacing scale, component patterns.
2. **Create a shared visual base.** All variations share font families, colors, radius, spacing, button/input styles via shared CSS custom properties.
3. **Simulate the surrounding context.** Render each variation inside a mock of the existing app — same header/nav/shell across all variations; only the explored area differs.
4. **Shift controls to UX dimensions.** Per-variation controls focus on behavioral parameters (animation style, disclosure model, density) — not color and font (those are locked).

**Greenfield** — No existing app or design system. The divergence axis determines how much visual freedom each variation gets.
- Interaction axis (greenfield): use a clean, professional visual base (one good font pairing, neutral palette) across all variations. Families differ in how the thing works.
- Visual axis (greenfield): full creative freedom per family — different typography, colors, spatial composition.
- Both axes (greenfield): families differ in everything — visual identity, layout, and interaction model.

---

## Step 2: Plan the Variations

### How many variations?

The variation count scales with the **design space** — how many meaningfully different approaches exist for the problem. Don't default to 6 every time; don't inflate to 12 when the scope doesn't warrant it.

| Scope | Round 1 | Round 2+ (refinement) | Families |
|---|---|---|---|
| **Component** (toggle, input, card, single widget) | 4-6 | 4 | 2 × 2, or 2 × 3 |
| **Feature / section** (notification panel, pricing area, settings) | 6-8 | 6 | 3 × 2, or 3 × 3 |
| **Full page** (dashboard, landing page, onboarding) | 8-9 | 6-8 | 3 × 3 |
| **Full app / multi-page flow** | 9-12 | 8-9 | 3-4 × 3 |

**Rules:**
- Minimum 2 families, minimum 2 variations per family
- Round 2+ counts drop because feedback narrows the space — drop families the user rejected, go deeper on ones they liked
- When in doubt, 6 is a safe default for most explorations. Only go higher when the scope genuinely has more axes of divergence to explore.

### Approach-based divergence planning

Before deciding families, identify the **specific design question** the exploration is answering — then brainstorm different answers to it.

The axis from Step 1 (interaction vs visual) determines the visual treatment: interaction-axis variations share a neutral professional style; visual-axis variations get full creative freedom. But within the chosen axis, the specific question is what makes the exploration focused and useful. "Explore different ways a price input works" is too broad — "explore different mental models for how a user sets a sale price" is specific enough to produce meaningfully different families.

**Interaction axis (default):** Each approach is a different answer to the design question — articulable as **"What if [specific concept]?"** The concept should evoke a UX pattern, mental model, or interaction philosophy — not a visual aesthetic.

**Visual axis:** Each approach is a different way the thing LOOKS — articulable as **"What if it felt like [aesthetic / brand / product]?"** Full creative divergence on typography, color, spatial composition.

**Both axes:** Approaches differ in both how it works AND how it looks. The concept evokes a complete product mental model.

**Process:**

1. **Brainstorm 4-6 approaches.** Frame each as a question appropriate to the axis:

   Interaction-axis examples:
   - "What if prices were side-by-side for direct comparison?" (dual-column, always-visible, comparison-first)
   - "What if the sale was a mode toggle that reveals progressive detail?" (compact by default, expanding)
   - "What if there was a live storefront preview next to the inputs?" (WYSIWYG, immediate feedback)
   - "What if pricing was a stepped flow?" (wizard-style, guided, one question at a time)

   Visual-axis examples:
   - "What if it felt like a Bloomberg Terminal?" (dense, data-forward, dark, monospace)
   - "What if it felt like a magazine spread?" (editorial, image-heavy, serif, generous whitespace)

   Both-axes examples:
   - "What if it worked like a command palette AND felt like a terminal?" (search-first + monospace dark)
   - "What if it was a guided conversation AND felt like a luxury checkout?" (progressive disclosure + refined, minimal)

2. **Push past obvious references.** The first approaches that come to mind are usually the most familiar — Notion, Linear, Slack, Shopify. These are fine as one data point but they're not exploration. Draw from outside the usual tech product vocabulary: print design, architecture, game UI, industrial controls, analog tools, other industries entirely. The goal is to surface approaches the user *hasn't* already considered.

3. **Select 2-3 approaches** that are most divergent from each other. Two approaches are divergent if they imply different answers to fundamental questions: What's visible first? How does the user interact? Where does complexity live? What's the primary flow?

4. **Articulate what makes each approach different** before assigning families. Don't just name the concept — state the concrete implications: what's prominent, what's hidden, how the user moves through the content, what the interaction prioritizes.

**CRITICAL for interaction axis:** Approaches must differ in BEHAVIOR, not aesthetics. "Nordic Ledger" and "Neon Terminal" sound different but might have identical interaction patterns — different paint on the same UX. "Side-by-side comparison" and "progressive disclosure wizard" ARE different — fundamentally different interaction models regardless of visual treatment. When the axis is interaction, name the UX pattern, not the aesthetic.

**Scale to scope:**
- **Full page / major feature**: Approaches differ in layout, navigation, information architecture, and (for visual/both axes) visual identity. Many axes of divergence.
- **Component / small scope**: Approaches differ primarily in interaction model and progressive disclosure. Fewer axes, but interaction differences matter more. A component rarely needs visual-axis divergence.

### Naming

Each family (approach) receives:
- **Code**: `LETTER + NUMBER` — Letter = family, Number = member (A1, A2, B1, B2, C1, C2, C3)
- **Memorable name**: Evokes what makes this approach distinctive. For interaction axis, name the UX concept ("Progressive Reveal", "Side-by-Side Compare"). For visual axis, name the aesthetic ("Boutique Ivory", "Neon Markdown"). People say "I liked the progressive reveal one" — not "I liked B1."
- **Layout label** and **Aesthetic label** (for interaction axis, the aesthetic label describes the interaction style, e.g., "Progressive Disclosure", "Compact Dense")

### Design thinking per variation

Commit to a clear direction for each family before writing HTML. The divergence axis determines what to decide.

**Interaction axis (default) — behavioral + structural divergence:**
- **Interaction model**: Fundamentally different per family — inline editing vs. modal, click-to-expand vs. always-visible, drag-and-drop vs. button actions, wizard vs. single form.
- **Information architecture**: Different content organization, hierarchy, progressive disclosure strategy.
- **Workflow**: Optimize for speed (power user)? Discovery (guided)? Safety (confirmations, undo)?
- **State handling**: Different approaches to empty states, loading, errors, edge cases.
- **Visual treatment**: All variations share a clean, professional visual base. Pick ONE good font pairing and neutral palette for the entire exploration. Variations look like they belong in the same product — the differences are in how they work, not how they're painted. Professional and polished, not bland — think of a well-designed SaaS admin panel.
- **Motion**: Animation STYLE can differ — spring physics vs. sharp cuts, vertical vs. horizontal motion. Hover transitions, open/close animations, micro-interactions ARE the design at component scale.
- **Differentiation**: What interaction or UX choice will someone remember? (Not what color or font.)

**Visual axis — aesthetic divergence:**
- **Tone**: Pick an extreme per family — brutally minimal, maximalist, retro-futuristic, editorial, brutalist, luxury, playful, industrial, etc.
- **Typography pairing**: Distinctive display font + refined body font per family. Never reuse pairings. Never use Inter, Roboto, Arial, or system fonts.
- **Spatial signature**: What makes this layout unforgettable? Generous whitespace? Asymmetric grid? Overlapping elements? Diagonal flow?
- **Atmosphere**: Go beyond flat backgrounds — but express it in 1-2 CSS effects, not 10. A single gradient + subtle shadow is more effective than stacking every technique.
- **Motion**: At minimum: hover transitions on interactive elements + one entrance animation per variation.
- **Differentiation**: Articulate the one memorable thing about this variation before building it.

**Both axes — full divergence:**
- Combine interaction and visual thinking above. Each family differs in both how it works AND how it looks.

**Components — scale the thinking regardless of axis:**
- Atmosphere = how the component FEELS to interact with, not page-level visual depth.
- Motion matters MORE at component scale — hover transitions, open/close animations, micro-interactions ARE the design.
- Controls focus on component-scale parameters: padding, radius, shadow, animation timing, label placement. Not page-level concerns.

### Variation quality rules

- **Families must represent fundamentally different approaches** — not variations on a theme. If you can't articulate what each approach's concept is, the families aren't divergent enough.
- **Divergence must be on the right axis.** For interaction-axis explorations: families that look different but work the same way is a FAILURE (e.g., neon terminal vs. boutique card layout, but both have identical form fields in the same order). For visual-axis explorations: families that look the same but have different names is a failure.
- **Same realistic data across all variations.** Compelling, real-sounding content (never lorem ipsum). Same data = fair comparison.
- **Each must be memorable on the chosen axis.** Interaction axis: indistinguishable after 10 seconds of interaction = too similar. Visual axis: indistinguishable at a glance = too similar. Push harder.
- **Include at least one unexpected approach.** A pattern from a different domain, an unconventional interaction model, something the user probably hasn't considered.
- **Design-preview quality, not production build.** Show the IDEA of the design efficiently. A well-composed preview with 3-4 content items beats a bloated one with 12 repetitive cards. For interaction-axis explorations, the preview must make the interaction model obvious even in a static mockup — use state indicators, clear affordances, and layout that implies the flow.

### Per-variation controls

Determine 4-8 interactive controls per variation that make sense for THAT variation's structure. Controls modify CSS custom properties on the variation's wrapper.

**Universal controls — scale to scope:**
- **Full page / feature**: include spacing density, font scale, and 1-2 color/appearance controls in every variation
- **Component**: skip spacing density and font scale — they're noise at component scale. Use 1 accent/mood control at most. Dedicate most controls (4-6) to the interaction parameters that make THIS variation's UX tuneable.
- Visual axis (any scope): explore color as a primary dimension — accent + mood, multiple independent color axes
- Interaction axis (any scope): prioritize behavior-relevant controls over cosmetic ones

**Interaction-axis controls (prioritize these, especially for components):**
- Controls that expose the variation's UX parameters — the things that make THIS interaction model tuneable
- Examples: disclosure speed, animation style, label placement, validation display mode, information density, field grouping
- The goal: let the user tune the BEHAVIOR, not just the paint. Each variation should have mostly DIFFERENT controls, reflecting its unique interaction model. If 4 out of 6 controls are identical across all variations, the controls aren't differentiated enough.

**Structure-specific controls (include only if relevant):**

| Structure element | Controls |
|---|---|
| Sidebar | Width (range), Position (left/right), Collapse toggle |
| Card grid | Columns (2/3/4), Gap size, Card style (bordered/shadow/flat) |
| Content area | Max width (narrow/medium/wide/full) |
| Hero section | Height (range), Alignment (left/center) |
| Table/list | Row density, Stripe toggle, Border style |
| Typography | Heading font family, Line height |
| Borders | Style (none/subtle/visible), Radius (range) |

Control data model schema:
```javascript
// Range control — value + unit are set directly on the CSS var
{
  id: 'sidebar-width',        // unique within variation
  label: 'Sidebar Width',     // human-readable
  type: 'range',              // range | select | toggle
  min: 180, max: 320, step: 10,
  options: null,
  value: 240,                 // current value (REQUIRED — never null/undefined)
  defaultValue: 240,          // reset target
  unit: 'px',                 // appended to value when setting CSS var
  cssVar: '--sidebar-width'   // CSS custom property this modifies
}

// Select — single property (e.g. accent color):
{
  id: 'accent',
  label: 'Accent Color',
  type: 'select',
  min: null, max: null, step: null,
  options: ['coral', 'teal', 'indigo', 'amber'],
  cssValues: { coral: '#e07a5f', teal: '#4a9e8f', indigo: '#5c6bc0', amber: '#d4a853' },
  value: 'teal',
  defaultValue: 'teal',
  unit: '',
  cssVar: '--accent'     // single var: --accent: #4a9e8f
}

// Select — MULTI-VAR (e.g. mood changes bg + text + borders together):
{
  id: 'mood',
  label: 'Mood',
  type: 'select',
  min: null, max: null, step: null,
  options: ['light', 'dark', 'midnight'],
  cssValues: {
    light:    { '--bg': '#faf9f7', '--text': '#2d2a26', '--text-dim': '#8a8580', '--border': '#e5e0d8' },
    dark:     { '--bg': '#1e1e2a', '--text': '#e0ddd8', '--text-dim': '#8a8580', '--border': '#333340' },
    midnight: { '--bg': '#0d0d14', '--text': '#c8c4be', '--text-dim': '#6a6660', '--border': '#1e1e2a' }
  },
  value: 'light',
  defaultValue: 'light',
  unit: '',
  cssVar: null            // multi-var: no single var, cssValues objects set all vars
}

// Toggle — cssValues maps true/false to CSS values:
{
  id: 'show-dividers',
  label: 'Show Dividers',
  type: 'toggle',
  min: null, max: null, step: null,
  options: null,
  cssValues: { true: '1px', false: '0px' },
  value: true,
  defaultValue: true,
  unit: '',
  cssVar: '--divider-width'
}
```

**Key rules for controls:**
- `id` is REQUIRED — unique within the variation. Without it, the control renders but clicking/dragging does nothing. (The template auto-generates from `label` as a safety net, but don't rely on this.)
- `value` and `defaultValue` must ALWAYS be set (never null/undefined)
- Range controls: `value` is numeric, `unit` is appended → `--gap: 24px`. **Exception: never use `unit: '%'` for percentage-scale ranges** — use unitless values (e.g., 0-100 or 0-1) and let the CSS handle the math (`calc(var(--opacity) / 100)` or `calc(var(--opacity) * 1%)`). The `%` unit in CSS var output causes `calc()` failures.
- Select controls: MUST include `cssValues` mapping options → CSS values. Without it, the CSS var gets a label string like `--bg: warm` which is useless
- Toggle controls: SHOULD include `cssValues` mapping `true`/`false` → CSS values. Without it, defaults to `1`/`0`
- **Multi-var controls** — when one control needs to change multiple CSS properties (e.g. mood/mode changing background, text, and borders together), use an **object** as the `cssValues` value instead of a string. Set `cssVar: null`. See the "mood" example above.
- **Every control must represent a meaningful design decision.** Controls let the user tune a variation without needing a whole new variant — they should surface the decisions that actually matter for that variation's design. The test: would a designer credibly debate between these options? If yes, it's a good control. If the difference is imperceptible or arbitrary, it's noise. Bad: switching between near-identical off-whites, 2px radius changes, shadow opacity going from 6% to 8%. Good: compact vs spacious density (reshapes the layout), rounded vs sharp corners (changes the personality), warm vs cool color mood, showing vs hiding a secondary element.
- **Every `cssVar` must be used in the variation.** The HTML must reference it via Tailwind arbitrary values (e.g., `bg-[var(--bg)]`, `rounded-[var(--radius)]`) or the CSS must use it. If a control defines `--card-radius` but the HTML uses `rounded-xl`, the control does nothing. The assembly script validates this and prints warnings.
- **ALL visual states must use `var()` for controlled properties.** Hover, active, and focus states must reference CSS vars, not hardcoded values. If `--accent` is `#BB6BD9`, don't write `:hover { color: #BB6BD9 }` — write `:hover { color: var(--accent) }`. Use `color-mix()` for derived colors: `color-mix(in srgb, var(--accent) 10%, transparent)`.
- **Never use `[style*="..."]` attribute selectors** for CSS variable detection. Attribute selectors are fragile for detecting CSS custom property values and should not be used.

---

## Step 3: Generate the HTML File

Generate a single self-contained HTML file (~3000-5000 lines total) using Tailwind CSS Play CDN + Alpine.js CDN + Google Fonts. This step uses **parallel subagents** to generate variation content, keeping context windows small and variation quality high.

### File Naming and Location

Exploration directory: `docs/design-explorations/YYYY-MM-DD-<topic>/`

**Before creating files, check if the directory already exists.** If it does:

1. **User provided feedback from a previous round** (pasted export with ratings/direction) → this is an iteration. The feedback's `Source:` line gives the HTML path. Extract its metadata with the same `sed` command from "Reading prior metadata" below to get the `families` array and `variations` array. Create `v{N+1}.html` where N is the `round` value from the metadata.

2. **No feedback provided, but directory has existing files** → ask the user:
   - *"I found an existing exploration at `docs/design-explorations/YYYY-MM-DD-<topic>/` with v1.html. Would you like to continue iterating (creates v2.html) or start fresh?"*
   - If **continue**: create the next `vN.html`. Extract the metadata from the latest existing round to avoid repeating previous designs (see "Reading prior metadata" below).
   - If **start fresh**: create a new directory with a disambiguating suffix: `YYYY-MM-DD-<topic>-2/`. This preserves the original exploration.

3. **Directory doesn't exist** → create it and generate `v1.html`.

**Round detection:**
- Check for existing `v*.html` files: `ls docs/design-explorations/YYYY-MM-DD-<topic>/v*.html 2>/dev/null`
- Or read from the feedback input's metadata block (`"round": N`)
- Next round = highest existing round + 1

**Reading prior metadata (continue without feedback):**

When the user chooses to continue in an existing directory but hasn't provided feedback, extract the metadata from the latest round's HTML to learn what was already explored. Use `sed` to pull just the JSON block — do NOT read the full file:

```bash
sed -n '/<script type="application\/json" id="exploration-metadata">/,/<\/script>/p' "{exploration_dir}/v{latest}.html" | sed '1d;$d'
```

This gives you the `families` array (each family's approach concept) and the `variations` array (each entry's `layoutType`, `aesthetic`, `familyName`, `name`, and `description`). Use this to:
- **Understand what approaches were tried** — the `families[].approach` field captures the "What if it worked like...?" concept behind each family
- **Avoid repeating the same approach or layout × aesthetic pairings** — if v1 explored "What if it worked like a magazine article?", don't try that again
- **Diversify family directions** — if v1 explored 2 families, aim for 2-3 different families in the continuation
- **Reference what was tried** — include a `"previousVariations"` summary in the new round's metadata so the chain is traceable

Include the prior family approaches and variation summary in each subagent prompt as a "do not repeat" constraint:

```
Previous round explored these approaches (do NOT recreate these):
- Family A "Editorial Manifesto": What if it worked like a long-form magazine article? → Sidebar + Cards layout, Clean Light aesthetic
- Family B "Interactive Product Stage": What if the product demo was the hero? → Stacked Full Width layout, Dark Dramatic aesthetic
Generate something with a fundamentally different approach.
```

### Generation Architecture

The file is too large for a single agent to generate well — quality degrades across multiple variations in one context. Split the work:

**You (the orchestrator, Opus) handle:**
- Writing `_metadata.json` (the only file the orchestrator creates directly)
- Spawning variation subagents with complete prompts
- Running `assemble.py` which copies the template, injects all content, and produces the final HTML

**Variation subagents (Sonnet, parallel) handle:**
- One variation each — the creative work of generating a complete HTML page and metadata/controls for a single variation
- Spawned in parallel since variations are independent

#### Step 3a: Understand the Shell (do NOT read reference files)

The shell template (`references/shell-template.html`) is a complete gallery page with three placeholders: `__METADATA_JSON__`, `__VARIATIONS_ARRAY__`, and `__VARIATION_TEMPLATES__`. Each variation's HTML is a complete page rendered inside an `<iframe srcdoc>`. The assembly script copies the template, wraps each `_var-{ID}.html` file in a `<template id="tpl-{id}">` element, and fills all placeholders automatically — **the orchestrator never reads it**. Do NOT read any files in `references/` — all essential rules are in this document, and `assemble.py` handles the template. Reading plugin reference files triggers avoidable permission prompts.

#### Step 3b: Spawn Variation Subagents

For each planned variation, spawn a background **subagent** (model: `sonnet` or equivalent capable general-purpose model). Subagents must have write permissions — they need to create files without interactive approval since they run in the background. Launch all subagents in a single message so they run in parallel. Wait for all subagents to complete using your platform's built-in mechanism before proceeding to assembly.

**CRITICAL: Subagents are single-turn generators, not exploratory agents.** The orchestrator must frame each subagent's task as structured output generation — not an open-ended build task. If the prompt reads like "here's a creative brief, go build something," the subagent will act like an agent (read files, explore, burn context). If it reads like "here's the complete spec, write these files," it acts like a generator.

**Set `max_turns: 2` on each subagent.** This structurally prevents multi-turn exploratory behavior (reading files, searching, retrying) that burns context. The subagent gets one turn to generate + write, and one safety buffer turn.

**Prompt structure for each subagent:**

Open the prompt by setting the frame:

> You are generating a complete HTML page and a JS metadata file for a single design variation. Everything you need is in this prompt. Do not read any files. Generate the content and write it to the 2 files specified below. No commentary — just write the files.
>
> The HTML file is a COMPLETE page (with `<!DOCTYPE html>`, `<head>`, `<body>`, etc.) that will be rendered inside an iframe. It can include `<script>` and `<style>` tags. The ONLY tag you must NEVER include is `</template>` (the HTML is wrapped in a `<template>` element by the assembly script, and a closing `</template>` tag would break the wrapper).

Then include ONLY:

1. **The output files** — tell the subagent exactly what to write and where. **Write the HTML file first** (it's the largest and most critical — if the subagent runs out of context, the HTML file is the one that must exist):
   - `{exploration_dir}/_var-{ID}.html` — the complete HTML page (WRITE THIS FIRST)
   - `{exploration_dir}/_var-{ID}.js` — the variation JavaScript object literal with metadata and controls (no `html` field)
2. **The variation brief** — id, family, familyName, name, layoutType, aesthetic, description, what makes it memorable, the key design commitments for this variation
3. **The shared realistic data** — the exact content (names, numbers, descriptions) to use. Keep this compact — just the data, no surrounding context about the project
4. **The divergence axis and constraint level** — one sentence establishing both. For interaction-axis explorations, explicitly state: "Visual treatment is shared — use [font pairing] and [palette description]. Focus on making the INTERACTION MODEL distinct, not the visual style." For visual-axis, state: "Full creative freedom on visual treatment — make the aesthetic distinctive and memorable."
5. **The rules** — distilled to essentials, NOT the full reference docs:
   - **Complete HTML page** — the file is a full page rendered inside an iframe. Include `<!DOCTYPE html>`, `<html>`, `<head>`, `<body>`. Include Tailwind CDN (`<script src="https://cdn.tailwindcss.com"></script>`) and Google Fonts `<link>` in the `<head>`. `<script>` and `<style>` tags are allowed — use them for interactive demonstrations (toggles, wizards, live calculations, etc.)
   - **The ONLY forbidden tag is `</template>`** — the assembly script wraps each HTML file in a `<template>` element. A literal `</template>` in the HTML would close the wrapper prematurely and break the gallery. This is extremely rare in practice. If needed inside a `<script>` tag, escape as `<\/template>`.
   - **Tailwind-first styling** — use Tailwind utility classes for layout, spacing, colors, typography, borders, shadows. Custom CSS in `<style>` tags is for: (a) CSS custom property definitions on `:root`, (b) keyframe animations, (c) smooth transitions for control-driven changes, (d) scrollbar styling, (e) things Tailwind genuinely can't express.
   - CSS custom properties (`var(--xxx)`) for all theme values — colors, fonts, spacing, radii. Define on `:root` (not scoped by class — the iframe provides isolation). Use via Tailwind arbitrary values: `bg-[var(--bg)]`, `text-[var(--text)]`, `font-[var(--font-body)]`
   - Use unprefixed custom property names (`--bg`, `--text`, `--accent`) — never `--shell-*`
   - Include 4-6 interactive controls in the JS file (provide the control schema inline). **Every control's `cssVar` must be actively used** in the variation's HTML via Tailwind arbitrary values (e.g., `rounded-[var(--card-radius)]`) or in the CSS. A control that defines `cssVar: '--card-radius'` is useless if the HTML uses `rounded-3xl` instead. Every control should represent a meaningful design decision — something a designer would credibly debate. If switching between options looks the same, it's not worth including. Prefer controls that change how the variation feels (density, color mood, corner personality, element visibility) over micro-adjustments that nobody would notice (2px radius tweaks, near-identical background shades). Controls are applied by the shell via `iframe.contentDocument.documentElement.style.setProperty()`.
   - Motion via CSS: hover transitions + one entrance animation with staggered delays. JavaScript is also allowed for interactive demonstrations.
   - Realistic content only, no lorem ipsum
   - Self-contained: no external images, use CSS gradients/inline SVG/Unicode
   - **Component scope**: center content in the viewport (`min-h-screen flex items-center justify-center p-8` on `<body>`). Without this, small components get pinned to the top-left corner of the preview. Full pages don't need this — their own layout fills the space.
   - Include transition CSS for smooth control changes: `:root * { transition: color 0.3s ease, background-color 0.3s ease, border-color 0.3s ease, padding 0.3s ease, gap 0.3s ease, font-size 0.3s ease, border-radius 0.3s ease, box-shadow 0.3s ease, max-width 0.3s ease, width 0.3s ease; }`
6. **SIZE GUIDANCE** — state these explicitly in the prompt. The mockup must look and feel like a real product — not a wireframe. Use realistic content, icons (inline SVG), and interactions. But stay efficient:
   - **HTML page: 250-450 lines.** Enough for a full page with boilerplate, icons, multiple content sections, and realistic data. Use Tailwind density — one `<div>` with 8 utility classes replaces 15 lines of nested markup + custom CSS. Scale to scope: a full page needs ~350-450 lines; a component needs ~200-250.
   - **Controls: 4-6 controls.** Each defined in ~8 lines.
   - **Total per file set: ~300-500 lines across the 2 files.**
7. **The file format** — describe exactly what each file contains:

**`_var-{ID}.html`** — a complete HTML page:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700&family=DM+Sans:wght@400;500&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #faf9f7;
      --text: #2d2a26;
      --accent: #62929e;
      --font-heading: 'Playfair Display', serif;
      --font-body: 'DM Sans', sans-serif;
      /* ... all custom properties ... */
    }
    :root * {
      transition: color 0.3s ease, background-color 0.3s ease,
                  border-color 0.3s ease, padding 0.3s ease,
                  gap 0.3s ease, font-size 0.3s ease,
                  border-radius 0.3s ease, box-shadow 0.3s ease,
                  max-width 0.3s ease, width 0.3s ease;
    }
    /* scrollbar styling, keyframes, etc. */
  </style>
</head>
<body class="min-h-screen bg-[var(--bg)] text-[var(--text)] font-[var(--font-body)]">
  <!-- Variation content -->
  ...
  <script>
    // Optional: JavaScript for interactive demonstrations
  </script>
</body>
</html>
```

**`_var-{ID}.js`** — a JavaScript object literal (no variable assignment, no semicolon, NO `html` field):
```javascript
{
  id: 'A1',
  family: 'A',
  familyName: 'Sidebar Classic',
  name: 'Shopify Morning',
  layoutType: 'Sidebar + Cards',
  aesthetic: 'Clean Light',
  description: 'Classic sidebar navigation with warm editorial card grid.',
  controls: [ /* 4-6 controls with full schema */ ]
}
```

8. **PRE-OUTPUT CHECKLIST** — include this in the subagent prompt as a mandatory verification step:

> Before writing the files, verify:
> - [ ] Every control has an `id` field (unique within this variation)
> - [ ] Every control's `cssVar` appears as `var(--xxx)` in the HTML — if nothing reads the var, the control is dead
> - [ ] `cssValues` is an OBJECT keyed by option labels (`{ compact: '0.75rem' }`), never an array
> - [ ] All controlled styling uses `var()` references — no CSS class toggling (the control system can only set CSS vars)
> - [ ] No range control uses `unit: '%'` — use unitless values for percentage scales
> - [ ] Hover, active, and focus states use `var()` references, not hardcoded color values, for any property driven by a control
> - [ ] HTML does NOT contain `</template>` (the only forbidden tag)
> - [ ] CSS custom properties are defined on `:root` (not scoped by class)
> - [ ] The JS file has NO `html` field (HTML is in the separate .html file)
> - [ ] HTML includes Tailwind CDN and Google Fonts in `<head>`
> - [ ] HTML includes transition CSS for smooth control changes

The goal: a self-contained prompt under ~2000 words. The subagent generates content and writes 2 files. No file reads, no searches, no multi-step exploration.

#### Step 3c: Assemble the Final File

**The orchestrator assembles via the standalone `assemble.py` script — it does NOT read variation file contents into its own context.** This is critical for scaling to many variations without the orchestrator itself hitting context limits.

1. **Write the metadata JSON** to `{exploration_dir}/_metadata.json` (the orchestrator generates this — it's small)

2. **Run the assembly script** — a single bash command. The `{skill_base}` path is the "Base directory for this skill" shown when the skill loads. Run the command directly (don't verify the path first — that triggers permission prompts).

```bash
python3 "{skill_base}/references/assemble.py" "{exploration_dir}" {round} "{skill_base}/references/shell-template.html" && open "{exploration_dir}/v{round}.html"
```

The script handles everything:
- Copies the shell template to `v{round}.html`
- Validates both files exist per variation (`_var-{ID}.js` + `_var-{ID}.html`)
- Validates HTML files contain no `</template>` tag (the only danger tag)
- Wraps each HTML file in a `<template id="tpl-{id}">` element
- Replaces all three template placeholders with subagent file contents
- Reports exit code 1 (missing files), 2 (validation failure), or 0 (success)
- Cleans up all temp files (`_var-*.js`, `_var-*.html`, `_metadata.json`)

**If the script reports missing files** (e.g. "B1: missing HTML"), do NOT try to fix this by reading existing files and generating the missing ones. That approach reads variation content into the orchestrator's context and defeats the whole architecture. Instead:
1. Delete the partial output for that variation: `rm -f {exploration_dir}/_var-{ID}*`
2. Re-spawn the specific subagent with the same prompt

**If the script reports validation errors** (e.g. "contains `</template>`"), delete the variation's output and re-spawn with extra emphasis on the `</template>` restriction.

The orchestrator's context only holds the conversation, the metadata JSON (small), and one bash command. It never reads the variation files.

### Metadata Block

Include a `<script type="application/json" id="exploration-metadata">` block in the HTML `<head>`:

```json
{
  "project": "Dashboard",
  "topic": "dashboard",
  "round": 2,
  "date": "2026-02-18",
  "previousRound": "v1.html",
  "sourceDirectory": "docs/design-explorations/2026-02-18-dashboard",
  "families": [
    { "letter": "A", "name": "Horizontal Flow", "approach": "What if it worked like a social media feed — infinite scroll, cards, algorithmic ordering?" },
    { "letter": "B", "name": "Command Center", "approach": "What if it worked like a Bloomberg terminal — dense, data-forward, keyboard-driven?" }
  ],
  "previousVariations": [
    { "family": "A", "familyName": "Sidebar Classic", "layoutType": "Sidebar + Cards", "aesthetic": "Clean Light" },
    { "family": "B", "familyName": "Bold Editorial", "layoutType": "Stacked Full Width", "aesthetic": "Dark Dramatic" }
  ],
  "variations": [
    {
      "id": "A1",
      "family": "A",
      "familyName": "Horizontal Flow",
      "name": "Nordic Mist",
      "layoutType": "Top Nav + Masonry",
      "aesthetic": "Muted Scandinavian",
      "description": "Horizontal navigation with masonry content grid in cool muted tones."
    }
  ]
}
```

The `families` array captures the conceptual approach behind each family — the "What if it worked like...?" framing from Step 2. This is included in the feedback export so the next round's agent understands what was tried and can iterate meaningfully. The `previousRound` field maintains the iteration chain. The `previousVariations` field (included when continuing without feedback) records what was explored in earlier rounds so agents can avoid repeating the same directions.

### Feedback Export

The export modal (built into the shell template) produces a markdown document optimized for LLM consumption. Per variation it includes: the family approach concept ("What if it worked like...?"), layout/aesthetic labels, the variation description, user notes, and tuning adjustments showing direction of change (default → adjusted value). Grouped by rating tier (Loved/Mixed/Low/Skip/Not reviewed). Designed to be pasted back into the agent to trigger the next round. The format spec is documented in `references/export-formats.md` (for human reference — do not read at runtime).

### Reference Files (do NOT read at runtime)

These files exist for human maintenance and for `assemble.py` to consume. The orchestrator must NOT read them — doing so triggers avoidable permission prompts. All rules the orchestrator needs are inlined in this document.

- **`references/shell-template.html`** — Gallery shell template. Consumed by `assemble.py`, never by the orchestrator.
- **`references/html-architecture.md`** — Architecture spec for maintainers. Essential rules are inlined in this skill file.
- **`references/export-formats.md`** — Export format spec for maintainers. The export modal is built into the template.

---

## Step 4: Conclude

The user finalizes from the gallery by clicking "Ship It" on their chosen variation, then pastes the direction output into the conversation. The skill handles everything from there.

### How It Works

The gallery has two actions:
- **"Next Round"** (sidebar footer) — exports feedback for iteration (another round)
- **"Ship It"** (rating bar) — finalizes the currently viewed variation as the chosen direction

When the user clicks "Ship It", the gallery generates a `## Design Direction` block containing the chosen variation's family approach, description, and tuned design specs (absolute values). The user adds notes and copies it to paste into the conversation.

### When the user pastes `## Design Direction`

The skill detects the header and runs the conclude sequence:

1. **Read metadata** — extract the `Source:` path from the pasted text. Read the metadata from the HTML file using `sed` (same as Step 0/3). This gives full context: families, approaches, all variations, round count.

2. **Write direction doc** — create `docs/design-directions/YYYY-MM-DD-<topic>-design-direction.md` using the template below. Combine the pasted direction data with metadata context.

3. **PRD integration** — if a PRD exists, add a reference line (`**Design Direction:** [path]`). If no PRD, the direction doc stands alone.

4. **Handoff** — depends on how the skill was invoked:

   **Invoked from `iterative:brainstorming`:** Write the direction doc, then exit. Do NOT present handoff options — `iterative:brainstorming` owns the workflow and will resume its own flow with the updated context (direction doc now exists, PRD references it).

   **Invoked standalone:** Write the direction doc, then present an interactive choice:
   - **Continue to `iterative:brainstorming`** — define requirements around the chosen direction (when no PRD exists)
   - **Continue to tech planning** — plan the implementation (when PRD exists or requirements are clear enough)
   - **Explore more** — another round of design exploration
   - **Done for now** — exit

### Direction Document Template

```markdown
# Design Direction: [Topic]

**Date:** YYYY-MM-DD
**Rounds:** N
**Gallery:** vN.html

## Chosen Direction

### [Variation code] "[Name]" — [Layout Type / Aesthetic]

**Approach:** [Family approach concept — "What if it worked like...?"]

[What works about this direction. Key design decisions — interaction model,
layout structure, typography, color direction, etc. Include tuned design specs
if the user adjusted controls from defaults. Include any notes the user added.]

## Design Parameters

<!-- Cross-cutting decisions worth carrying forward.
     Only include if the exploration surfaced clear preferences.
     Skip this section entirely if there are none. -->

## Context

<!-- Include when standalone (no PRD). Skip when a PRD provides the context. -->
[What prompted this exploration. The problem being solved. Who it's for.]
```

---

## Quality Bar

- [ ] Each variation is MEANINGFULLY different on the chosen axis — interaction axis: different UX flow or interaction model; visual axis: different layout structure and aesthetic
- [ ] Switching variations is instant (no janky reflows)
- [ ] Per-variation controls update the preview in real time with smooth transitions
- [ ] Each variation has 4-8 controls RELEVANT to its specific structure
- [ ] Same realistic data across all variations
- [ ] Star ratings persist across page reloads
- [ ] Export produces a single markdown document with JSON ratings, summary, and editable direction
- [ ] All keyboard shortcuts work
- [ ] Gallery shell matches the fixed template exactly — same tokens, fonts, layout, and behavior as every other exploration file
- [ ] Gallery shell is dark and RECEDES — eyes go to the variations, not the chrome
- [ ] File works by opening directly in a browser (no build step, no server)
- [ ] Each variation has a memorable name
- [ ] Visual axis: no two families use the same font pairing. Interaction axis: all families share a professional visual base
- [ ] At least one variation is unexpected/creative
- [ ] Metadata block is present and accurate
- [ ] File is named with correct round number in the exploration directory

## Common Mistakes

- **Visual divergence on a functional problem (THE #1 mistake)** — When asked to explore a component or feature (e.g., "price input with sale toggle"), generating a neon cyberpunk version, a developer terminal version, and a boutique card version is NOT useful. Those are visually different but may have identical interaction patterns. The user wants to see different ways the pricing UX WORKS — inline toggle vs wizard vs side-by-side comparison — all rendered in a clean, professional style. Default to interaction-axis divergence. Only go visually wild when the user is explicitly exploring visual identity.
- **Variations are just color swaps** — Each family needs fundamentally different HTML structure or interaction model. Not the same tree with different colors.
- **Controls don't work** — Common causes: (1) missing `id` field — control renders but clicks do nothing (template auto-fixes this but don't rely on it); (2) `cssVar: '--card-radius'` defined but HTML uses `rounded-3xl` instead of `rounded-[var(--card-radius)]` — the var is set but nothing reads it; (3) `unit: '%'` on a range control breaks `calc()` in CSS (use unitless values for percentage scales); (4) hover/active states use hardcoded colors instead of `var(--accent)` — the default state changes but hover doesn't; (5) `cssValues` written as an **array** instead of an object — `cssValues: ['0.75rem', '1rem']` MUST be `cssValues: { compact: '0.75rem', comfortable: '1rem' }` keyed by option labels (the template auto-fixes this but don't rely on it). Controls are applied via `iframe.contentDocument.documentElement.style.setProperty()`. The assembly script warns about orphaned CSS vars.
- **Controls drive CSS classes instead of CSS vars** — The control system can ONLY set CSS custom properties. If a control's effect requires toggling CSS classes (e.g., `.input-bordered` vs `.input-underlined`), the control is dead. All controlled styling must flow through `var()` references. Use CSS that reads `var(--input-border)` rather than switching between `.input-bordered` and `.input-underlined` classes.
- **Same controls on every variation** — Each variation's controls should reflect its unique structure. If 4 out of 6 controls are identical across all variations (e.g., every variation has spacing-density, font-scale, card-radius, accent-color), the tuning experience feels generic. Especially for components: skip boilerplate controls like spacing density and font scale, and dedicate all controls to the interaction parameters specific to that variation.
- **Generic AI aesthetics (visual axis)** — No Inter + purple gradients on white. Distinctive, intentional choices. Reference real products. Note: this applies to visual-axis explorations. For interaction-axis explorations, a clean professional style IS the goal — the aesthetics should be polished but not distracting from the UX being explored.
- **Lorem ipsum** — Real content only. "$1,247,890 in revenue" beats "Lorem ipsum dolor sit amet."
- **Export is just raw data** — The export must produce a ready-to-paste markdown prompt with structured JSON ratings, a human-readable summary, and a user-editable direction section.
- **Too many controls** — 4-8 per variation.
- **Controls too subtle to notice** — If switching between options looks the same, the control is noise. Common traps: page background switching between near-identical off-whites, corner radius changing by a few pixels, shadow opacity going from 6% to 8%. Each control should surface a design decision someone would actually care about — "do we want this compact or spacious?" not "should the shadow be 6% or 8% opacity?"
- **Missing Google Fonts** — Every variation HTML file must include its own Google Fonts `<link>` in `<head>`. Each variation is a complete page inside an iframe and loads its own fonts.
- **Missing metadata block** — Every HTML file needs the `exploration-metadata` JSON block for agent consumption.
- **Shell chrome varies between files** — The gallery shell is a fixed product. Same design tokens, fonts, layout, and interaction across every file. Only the variations inside the preview stage differ. The template enforces this automatically.
- **Reading reference files at runtime** — Never read files in `references/` during skill execution. The orchestrator has everything it needs in this document, and `assemble.py` handles the template. Reading plugin files triggers permission prompts that interrupt the user.
- **Generating all variations in the orchestrator** — Don't skip the subagent pattern. Variation quality degrades when one agent generates all variations sequentially. Each variation deserves a focused subagent.
- **Orchestrator reading variation content into context** — The orchestrator must assemble via bash/python file operations, not by reading each subagent's output. Reading 7 × 500-line files into the orchestrator's context will cause it to hit context limits during the write step.
- **Inconsistent data across variations** — The orchestrator must include the same realistic data set in every subagent prompt. If subagents invent their own data, variations can't be fairly compared.
- **Subagent or orchestrator context overflow** — Set `max_turns: 2` on subagents to prevent multi-turn exploration. Include size guidance (HTML page 250-450 lines). Critically, the orchestrator must NOT read variation file contents into its own context — use the file-based assembly pattern (bash/python to replace template placeholders with file contents). If the orchestrator reads all 7 variation files, it will hit context limits during assembly.
- **Custom CSS instead of Tailwind** — When a subagent writes `margin-top: 24px; padding: 16px; border-radius: 12px; background: var(--bg);` as custom CSS, it should be `mt-6 p-4 rounded-xl bg-[var(--bg)]` in a Tailwind class string. Custom CSS is only for property definitions, keyframes, transitions, and things Tailwind genuinely can't express. Use Tailwind utility classes in the HTML and keep `<style>` blocks compact.
- **`</template>` in variation HTML** — The only forbidden tag. The assembly script wraps each HTML file in a `<template>` element, and a literal `</template>` would close the wrapper prematurely. If it appears inside a `<script>` tag, the HTML parser handles it correctly (raw text mode), but the string-based validator flags it as a false positive. Subagents can escape as `<\/template>` in JS string literals if needed.
- **JS file still has an `html` field** — The JS file should contain ONLY metadata and controls. The HTML is in the separate `_var-{ID}.html` file. An `html` field in the JS is ignored and wastes context.
- **CSS scoped by class instead of `:root`** — Variations are isolated in iframes. Define custom properties on `:root`, not on `.v-a1`. Class-scoped properties won't be reached by `setProperty()` on `documentElement`.
- **Missing transition CSS** — Each variation HTML must include the transition CSS rule (`:root * { transition: ... }`) for smooth control changes. Without it, control adjustments appear as jarring instant changes.
- **Interim files not cleaned up** — The assembly script handles cleanup automatically. If you're not using the script, always run `rm -f _var-*.js _var-*.html _metadata.json` after assembly.
- **Color controls as a single theme preset** — A single "warm/cool/neutral" select is too blunt. Prefer 2-3 independent color dimensions the viewer can mix. Use multi-var `cssValues` (object format) when one control needs to change multiple properties together.
- **Orchestrator reading variation files to fix partial subagent output** — If a subagent wrote JS but not HTML (or vice versa), do NOT read the existing file to "understand what's needed." This reads variation content into the orchestrator's context. Instead, delete the partial output and re-spawn the subagent.
- **Wrong round number** — Check existing files in the directory before naming.
- **Unnecessary filesystem checks** — Don't verify plugin file paths (`ls`, `find`) before running commands, and don't poll for subagent completion with `sleep && ls`. Both trigger permission prompts. Run commands directly; wait for subagents using built-in tools.