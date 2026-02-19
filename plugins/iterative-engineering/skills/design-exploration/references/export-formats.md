# Export Format Reference

The export modal produces a **single format** — a markdown document with embedded JSON ratings, designed to be pasted back into the agent to trigger the next round. This closes the explore → rate → iterate loop.

## Format

```markdown
## Design Exploration Feedback — [Project] (Round N)
Source: docs/design-explorations/YYYY-MM-DD-<topic>/vN.html

### Ratings
```json
{
  "A1": { "stars": 5, "notes": "Editorial spacing is perfect, warm tones feel right" },
  "B1": { "stars": 4, "notes": "Clean information hierarchy. Keep the monospace numbers." },
  "B2": { "stars": 2, "notes": "Good concept but too sparse. Needs visual anchors." },
  "C3": { "stars": 0, "notes": "Too aggressive for our audience" }
}
```

### Summary

**Loved (4-5★)**
- **A1 "Shopify Morning"** (5★) [Sidebar + Cards / Clean Light]
  → Editorial spacing is perfect, warm tones feel right

**Mixed (2-3★)**
- **B2 "Notion Zen"** (2★) [Split Panel / Minimal]
  → Good concept but too sparse. Needs visual anchors.

**Skip (0★)**
- **C3 "Brutalist Raw"** [Hero First / Brutalist]
  → Too aggressive for our audience

**Unreviewed**
- C2 "Stripe Night" — not yet reviewed

### Direction for Next Round
Generate refined variations that lean into A1's warm typography and B1's information density.
Drop the C family — too aggressive for our audience.
Explore mixing A1's editorial feel with B1's dark theme.
```

## How it works

- The **Ratings JSON** block and **Summary** section are auto-generated from localStorage data by `generateFeedback()` in the template
- The **Direction for Next Round** section comes from a `<textarea>` in the export modal that the user edits before copying
- The **Copy to Clipboard** button combines the auto-generated feedback + the user's direction into a single string
- The `Source` line references the HTML file so the agent can read the metadata block for full variation details

## Rating System

**Components:**
- **Star rating (1-5):** Click or press `1`-`5`. Click same star to clear (back to unreviewed).
- **Skip (0★):** Click the ✗ button or press `0`. Marks a variation as explicitly skipped.
- **Notes:** Always-visible text input in the rating bar. Per-variation.
- **Progress pips:** Colored dots in sidebar footer — amber = 4-5★, yellow = 2-3★, red = 1★ or skip, empty = unreviewed.

**States:** `null` = unreviewed (no action taken), `0` = explicit skip, `1-5` = star rating.

**Persistence:** All ratings, notes, control states, and panel position save to `localStorage` automatically. Key format: `design-exploration-{topic}-r{round}-ratings`.
