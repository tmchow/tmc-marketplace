# Design Exploration Strategy

## What It Does

You describe a design problem — "a notification center for our admin panel," "a landing page for a new product," "a pricing input with sale toggle" — and the system generates 6-8 fully interactive HTML prototypes in parallel, each representing a fundamentally different approach. Not mockups. Not wireframes. Complete, functional pages you can click through, scroll, and interact with, rendered side by side in a gallery with controls, ratings, and structured export.

The gallery opens in a browser. You flip between variations, adjust design controls (spacing, color mood, density, animation style), rate each one 1-5 stars, add notes, and export structured feedback. Paste that feedback back to start a refined round. When you've converged on a direction, click "Ship It" and the system writes a design direction document — a durable record of what was chosen, what was rejected, and why.

The entire cycle — from text description to interactive gallery — takes one conversation turn.

## Why It Matters

### Parallel creative exploration at a scale humans can't match

A designer exploring a notification center might develop 2-3 approaches over the course of a week. That's not a limitation of skill — it's a limitation of time and attention. Each approach requires committing to a direction, building it out, evaluating it, and deciding whether to try another. The cost of each additional approach is high, so exploration gets cut short.

AI agents don't have that constraint. Six agents can pursue six fundamentally different directions simultaneously, each working from only its own brief with no knowledge of what the others are building. The result is genuine creative divergence — not six riffs on the same idea, but six independent answers to the same design question, generated in minutes instead of days.

This isn't about replacing designers. It's about giving anyone in the design process — designers, engineers, product managers, founders — the ability to see a breadth of approaches that's impractical to produce manually. A designer uses this to rapidly externalize ideas they'd normally have to pick between in their head. An engineer uses it to understand the UX implications of a feature before committing to an implementation. A PM uses it to ground a requirements discussion in something concrete rather than abstract.

### Design decisions without alternatives are guesses

A PRD can say "discount-first pricing input with live preview," but that sentence maps to dozens of different interaction models, layouts, and progressive disclosure strategies. A sidebar with inline editing? A stepped wizard? A side-by-side comparison view with a live storefront preview? These are fundamentally different user experiences that feel identical as text descriptions.

Seeing 6 different interaction models for the same component, rendered as realistic UI you can actually interact with, changes the conversation from "I think it should work like X" to "I've seen how X, Y, and Z work, and X is right because..."

### Interactive prototypes, not static mockups

The output isn't screenshots or Figma frames — it's functional HTML. Each variation has working toggles, wizards, live calculations, animations, and design controls you can adjust in real time. You're evaluating how something *feels to use*, not how it looks in a picture. That's a different kind of feedback, and it surfaces different problems. A layout that looks great as a static comp might feel claustrophobic when you're actually clicking through it.

This makes the tool useful at stages where traditional prototyping is too expensive. Exploring 8 interaction models for a component before a single design review? Generating a gallery to align stakeholders before any detailed design work begins? These aren't things teams typically do — not because they wouldn't be valuable, but because the cost has always been prohibitive.

### The rejection record matters as much as the selection

After exploring, you don't just have a chosen direction — you have a written record of what was discarded and why. That prevents "what about this approach?" from recurring in every future meeting. The design direction document captures both the positive case (why this works) and the negative case (why the alternatives didn't).

## Key Concepts

### The divergence axis

The most important decision in any exploration is **what varies between approaches**. Getting this wrong produces galleries that are visually impressive but practically useless.

**Interaction divergence (the default).** Approaches explore different ways the thing *works*. All variations share a clean, professional visual treatment. The user is comparing interaction models, not color palettes. This is right for components, features, anything inside an existing app, anything with a clear functional problem.

Example: "price input with sale toggle" generates one approach using an inline toggle that reveals progressive detail, another using a side-by-side comparison layout, another using a stepped wizard, another embedding a live storefront preview. All look like the same professional admin panel — the differences are in how the UX works.

**Visual divergence.** Approaches explore different ways the thing *looks*. Same functional structure, different aesthetics, typography, spatial composition, atmosphere. Right for landing pages, brand exploration, design system foundations.

**Both.** Rare. Only when the entire page or app is genuinely open in both dimensions.

Interaction is the default because it's almost always what people need. "Show me different ways a price input could work" is more useful than "show me the same price input in six different color schemes."

### The specific design question

Within the chosen axis, every exploration is focused by a specific question. "Explore different ways a price input works" is too broad. "Explore different mental models for how a user sets a sale price" is specific enough to produce meaningfully different approaches.

The question determines the quality of the exploration. It's the difference between generating random variations and generating variations that represent genuinely different answers to a real design problem.

### Controls as design decisions

Each variation has 4-8 design controls — sliders, dropdowns, toggles — that let you explore decisions within a single approach without generating a whole new variant. Adjust spacing density, switch color mood, toggle element visibility, change animation style, shift layout width.

The key principle: **every control must produce a visible difference.** The litmus test is whether someone across the room could tell the control changed something. Compact vs. spacious density reshapes the layout. Warm vs. cool color mood shifts the entire atmosphere. Show vs. hide a sidebar changes the spatial model. These are design decisions worth debating. Shadow opacity from 6% to 8% is invisible — that's parameter tweaking, not design exploration.

Controls prioritize what's unique to each variation's structure. Two variations with different interaction models should have mostly different controls. The most valuable controls are the ones specific to *this* approach's design decisions, not generic options that apply to any UI.

## The Workflow

### Single round

1. **Describe the problem.** A sentence, a paragraph, or a full PRD — the system adapts.
2. **See the gallery.** Open the HTML file. 6-8 variations organized into families (approaches), each with its own design controls.
3. **Explore and rate.** Flip between variations. Adjust controls. Rate 1-5 stars. Add notes. Skip ones that aren't relevant.
4. **Converge.** Click "Ship It" on the variation you want to move forward with. A design direction document is written.

### Multi-round iteration

The first round is broad exploration. Subsequent rounds refine.

1. **Explore.** Generate gallery with divergent variations.
2. **Rate.** Stars, notes, skips.
3. **Export.** "Next Round" produces structured feedback — markdown with embedded JSON ratings that the system can parse.
4. **Iterate.** Paste feedback back. The system reads your ratings and generates a refined round — drops rejected approaches, goes deeper on the ones you liked.
5. **Converge.** Finalize a direction when ready.

The feedback format closes the loop. It's designed to be pasted directly into the next conversation turn.

### Four entry points

**Standalone.** "Explore designs for a notification center." The system asks 0-2 scoping questions based on ambiguity, then generates.

**Before brainstorming.** Anchors a greenfield discussion with visual options. The design direction becomes input to brainstorming, narrowing the space without locking it as a spec.

**During brainstorming.** For design-heavy tasks, brainstorming offers design exploration instead of text-described options at the point where directions are being compared. Text descriptions of visual or interaction concepts are the wrong medium — you need to see them.

**After brainstorming.** A PRD maps the problem space; the exploration tests visual and interaction possibilities that requirements alone can't express. The design direction folds back into the PRD.

The system adapts to whatever context exists. Rich context (a PRD) means the problem space is already mapped — proceed directly to variation planning. Light context (a sentence) means a few scoping questions may be needed. The behavior is driven by what's available, not by which workflow stage triggered it.

## Architecture

### Single-file portability

Every gallery is one self-contained HTML file. No build step, no dependencies, no server. Open it in any browser, share it as an attachment, archive it in the repo. This is non-negotiable — the artifact needs to survive outside the development environment.

### Parallel agent generation

The gallery is generated by an orchestrator delegating to parallel agents (one per variation). This separation exists for two reasons:

- **Context protection.** 6-8 variations at 250-500 lines each would consume the orchestrator's entire context window. Agents generate in isolation; the orchestrator never reads their output.
- **Creative independence.** Each agent knows only its own variation's brief. No knowledge of other variations prevents unconscious convergence — agents can't copy each other's patterns.

A Python assembly script combines the agent output files into the final gallery HTML. The orchestrator runs one command; it never reads variation content into its own context. Assembly is a file operation, not a context operation.

### Iframe isolation

Each variation is a complete HTML page rendered in an iframe. This provides full CSS and JavaScript isolation — variations can have their own fonts, animations, scripts, and styles without conflicting with each other or the gallery shell. Controls reach across the iframe boundary by setting CSS custom properties on the variation's root element.

### Resilient to imperfect output

The gallery shell normalizes common deviations in agent output at load time — missing IDs, alternate type names, misformatted values. Normalizing is cheaper than re-generating. The system renders something useful even when agent output is slightly off-spec.

For deeper architectural detail — the template placeholder system, CSS architecture, control wiring mechanics, assembly script behavior — see `references/html-architecture.md`.

## The Direction Doc

HTML galleries are working artifacts — large, interactive, meant to be opened and explored. The **design direction document** is the durable output. It captures:

- **What was chosen and why** — the specific interaction model, layout, and design decisions that worked
- **What was discarded and why** — prevents future rehashing of approaches that were already evaluated
- **Design parameters** — cross-cutting decisions (spacing philosophy, color temperature, density, animation style) that carry forward into implementation
- **Context** — when standalone, so the doc is self-sufficient without a PRD

The direction doc is a decision record. When it exists alongside a PRD, the PRD references it rather than duplicating it. The direction doc stands alone as evidence of what was explored and what was chosen — and more importantly, that the choice was informed by seeing real alternatives.
