# Design Exploration Strategy

## Why This Skill Exists

Requirements documents describe what to build. They don't show what it feels like. A PRD can say "discount-first pricing input with live preview," but that sentence maps to dozens of different interaction models, layouts, and progressive disclosure strategies. Until you see them side by side, you can't meaningfully choose.

Design exploration generates fundamentally different approaches to a design problem: different answers to the question "how should this work?" (or, when appropriate, "how should this look?"). The user sees, rates, and refines. The output is a design direction document that captures what was chosen and why.

Design decisions made without seeing alternatives are guesses. Seeing 6 different interaction models for the same component, rendered as realistic UI you can actually interact with, changes the conversation from "I think it should work like X" to "I've seen how X, Y, and Z work, and X is right because..."

## Where It Fits in the Workflow

Design exploration can run at four points:

```
                    ┌──── standalone ────┐
                    │                    │
                    v                    v
prompt ──► design exploration ──► design direction doc
                    ^                    │
                    │                    v
brainstorming ──────┤              brainstorming (PRD updated)
  (before)          │                    │
  (during: at       │                    v
   Broad Directions)│              tech planning
  (after: at        │                    │
   Review/Handoff)  └── iterate ─────────┘
```

**Before brainstorming.** Anchors a greenfield discussion with visual options. The design direction becomes input to brainstorming, narrowing the exploration space without locking it as a final spec. Brainstorming builds on what the exploration established.

**During brainstorming (at Broad Directions).** For design and interaction-heavy tasks (visual redesigns, marketing pages, onboarding flows), brainstorming offers design exploration at the Broad Directions stage instead of presenting text-described options. This is the right timing: Map the Space questions have gathered initial constraints, but no direction has been locked in yet. Text descriptions of visual or interaction concepts are the wrong tool — the user needs to see or experience options to meaningfully choose. The chosen direction feeds into Deep Exploration for remaining requirements, then into the PRD.

**After brainstorming (at Review and Handoff).** Explores how requirements could look and feel before committing to implementation. The PRD maps the problem space; the exploration tests visual and interaction possibilities that requirements alone can't express. The design direction folds back into the PRD.

**Standalone.** When someone wants to see design options for any page, component, or feature, without the full brainstorming→planning pipeline.

In all cases, the skill adapts to whatever context is available. Rich context (a PRD, detailed requirements) means the problem space is already mapped, so proceed to divergence planning. Light context (a sentence) means a few scoping questions may be needed. The skill reads the context, not the source.

## Core Design Decisions

### Single-File Portability

Every gallery is a single self-contained HTML file. No build step, no dependencies, no server. Open it in any browser, share it as an attachment, archive it in the repo. The gallery is a working artifact that needs to survive outside the development environment, so single-file portability is non-negotiable.

### Iframe Isolation via `<template>` + `srcdoc`

Each variation is a complete HTML page stored in a `<template>` element and loaded into an `<iframe srcdoc>`. This replaced the original approach of injecting HTML fragments via Alpine.js `x-html`.

**What iframe isolation enables:**
- `<script>` and `<style>` tags in variations, which is critical for interactive demonstrations (toggles, wizards, live calculations)
- Full CSS isolation, so each variation's `:root` properties don't conflict with others or the shell
- Complete creative freedom: variations can load their own fonts, define their own keyframes, use any CSS technique
- Realistic rendering: variations render as they would in production, not as sanitized fragments

**What it preserves:**
- Single-file portability (everything is still one HTML file)
- Shell consistency (the gallery chrome is identical across every file, defined by the template)

**The body class preservation problem.** The HTML parser strips `<body>` attributes when parsing content inside `<template>` elements. Since variations put critical styling on `<body>` (centering for components, background colors, typography base), the assembly script extracts `<body class="...">` and stores it as `data-body-class` on the template element. The shell reapplies it to the iframe's body after load.

### Orchestrator + Parallel Subagents

The gallery is generated by an orchestrator (which owns the file and the process) delegating to parallel subagents (one per variation). This separation exists for two reasons.

**Context window protection.** Each variation is 250-500 lines of HTML. With 6-8 variations, that's 1500-4000 lines of generated content. If the orchestrator generated this itself, its context window would be consumed by HTML output, leaving no room for reasoning about the exploration as a whole. Subagents generate in isolation; the orchestrator never reads their output.

**Creative independence.** Each subagent knows only its variation's brief: the approach concept, the design parameters, the control requirements. It has no knowledge of the shell, Alpine.js, or other variations. This prevents convergence, since subagents can't unconsciously copy each other's patterns.

**File-based assembly.** The orchestrator runs a Python assembly script that reads subagent output files, validates them, wraps them in template elements, and fills in the shell template placeholders. The orchestrator never reads variation content into its own context. Assembly is a file operation, not a context operation.

### Defensive normalizeControl

Subagents deviate from the control schema in predictable ways. Rather than failing on malformed controls (which would require re-running the subagent), the shell template includes a `normalizeControl()` function that fixes common deviations at load time:

- Missing `id` → auto-generated from label
- Alternate type names (`boolean` → `toggle`, `slider` → `range`, `dropdown` → `select`)
- Missing type → inferred from data shape (has `min`/`max` → range, has `options` → select, boolean value → toggle)
- `cssValues` without `options` array → options derived from `cssValues` keys
- Range values as strings with units (`'0.5s'`) → parsed to number
- Missing `defaultValue` → copied from initial `value`

Normalizing is cheaper than re-generating. The template is the last line of defense; it should render something useful even when subagent output is slightly off-spec.

### Divergence Axis Model

The most important decision in any exploration is what varies between families. Getting this wrong produces galleries that are visually impressive but practically useless.

**Interaction divergence (default).** Families explore different ways the thing WORKS. All variations share a professional visual treatment. The user is comparing interaction models, not color palettes. This is the right axis for components, features, anything inside an existing app, anything with a clear functional problem.

**Visual divergence.** Families explore different ways the thing LOOKS. Same functional structure, different aesthetics. Right for landing pages, brand exploration, design system foundations.

**Both.** Rare. Only when the entire page or app is genuinely open in both dimensions.

Interaction is the default because it's almost always what people need. "Show me different ways a price input could work" is a more useful exploration than "show me the same price input in six different color schemes." The axis is determined from context, not surfaced as a user-facing choice.

Within the chosen axis, the exploration is focused by a **specific design question.** "Explore different ways a price input works" is too broad. "Explore different mental models for how a user sets a sale price" is specific enough to produce meaningfully different families.

### Controls as Design Decisions

Each variation has 4-6 tuning controls that let the user adjust parameters without needing a whole new variant. Controls are applied across the iframe boundary via `setProperty()` on the iframe's `documentElement`.

The key principle: **every control must represent a meaningful design decision.** Would a designer credibly debate between these options? If yes, it's a good control. If the difference is imperceptible or arbitrary, it's noise. Compact vs spacious density, rounded vs sharp corners, warm vs cool mood: meaningful. Near-identical off-whites, 2px radius changes, shadow opacity from 6% to 8%: not meaningful.

### Multi-Round Iteration

The first round is broad exploration. Subsequent rounds refine based on feedback. The skill supports this loop natively:

1. **Explore.** Generate gallery with divergent variations.
2. **Rate.** User rates each variation (1-5 stars), adds notes, can skip.
3. **Export.** Structured feedback with ratings, notes, and direction for next round.
4. **Iterate.** Paste feedback back; skill reads prior metadata and generates a refined round (drops rejected families, goes deeper on liked ones).
5. **Converge.** User finalizes a direction.

The export format closes the loop: markdown with embedded JSON ratings that the skill can parse when pasted back in. The "Ship It" button captures the chosen direction directly.

### The Direction Doc as Durable Output

HTML galleries are working artifacts. They're large, they reference CDN resources, they're meant to be opened and interacted with. The **design direction document** is the durable output. It captures:

- What was chosen and why (specific elements that worked)
- What was discarded and why (prevents future rehashing)
- Cross-cutting design parameters (spacing philosophy, color temperature, interaction patterns)
- Context (when standalone, so the doc is self-sufficient)

When brainstorming produces a PRD that leads to design exploration, the direction doc folds back into the PRD by reference, not duplication. The PRD says "see design direction doc for visual/interaction decisions." The direction doc stands alone as a record of what was explored and what was chosen.

## Context-Aware Handoffs

The skill adapts its behavior based on available context rather than checking which specific skill invoked it.

**Rich context (PRD, detailed requirements).** The problem space is mapped. Skip Q&A, determine divergence axis from context, proceed to variation planning. The exploration tests possibilities that requirements alone can't express.

**Design direction as input to brainstorming.** Narrows the exploration space but isn't a final spec. Strong input about interaction model and visual direction, not locked requirements. Brainstorming builds on what the exploration established; explores what it doesn't answer (requirements, behaviors, scope, edge cases). Technology and implementation questions belong in planning, not brainstorming.

**Light context (brief prompt).** Ask 0-2 scoping questions calibrated to how much ambiguity exists. The inform-vs-constrain test: does knowing the answer change which approaches you'd explore, or does it just eliminate options the user should see?

This principle (adapt to context, not source) keeps the skills loosely coupled. Each skill describes how to handle types of input, not specific upstream skill names.
