# Design Direction Template

Use this template when creating or updating the design direction document at the conclusion of a design exploration.

## Document Structure

```markdown
# Design Direction: [Topic]

**Date:** YYYY-MM-DD
**Rounds:** N
**Final gallery:** vN.html
```

## Sections

### Chosen Directions (always include)

1-3 directions the user wants to carry forward. Each gets its own subsection.

```markdown
## Chosen Directions

### [Variation code] "[Name]" — [Layout Type / Aesthetic]

[What works about this direction. What to carry forward. Key design decisions —
interaction model, layout structure, typography, color direction, etc.
Be specific about what the user responded to.]
```

If carrying forward elements from multiple variations (a mashup), describe which elements come from where:

```markdown
### Hybrid: [Name] — [Brief description]

Combines [Variation A]'s [specific element] with [Variation B]'s [specific element].
[What this combination achieves that neither variation did alone.]
```

### Discarded Approaches (always include)

What was explored and didn't make the cut. Concise — the goal is preventing future rehashing, not a detailed post-mortem.

```markdown
## Discarded Approaches

### [Family letter] — [Family name]

[Why it was discarded. What specifically didn't work. 1-2 sentences.]
```

Group by family when an entire family was rejected. Call out individual variations only when one variation in an otherwise-liked family was dropped for a specific reason.

### Design Parameters (include when applicable)

Cross-cutting decisions that apply regardless of which chosen direction is implemented. Skip this section if there are no cross-cutting decisions worth capturing.

```markdown
## Design Parameters

[Key decisions that emerged from the exploration: spacing philosophy, color
temperature, typography approach, interaction patterns, accessibility
constraints, responsive behavior, animation style, etc.

Only include parameters where the exploration surfaced a clear preference.
Don't list every possible design dimension.]
```

### Context (include when standalone)

When the exploration was done standalone (no PRD), include brief context so the document is self-sufficient.

```markdown
## Context

[What prompted this exploration. The problem being solved. Who it's for.
Skip this section when a PRD exists — the PRD provides the context.]
```