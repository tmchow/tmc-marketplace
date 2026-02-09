# PRD Update Guide

When a spike concludes, propose updates to the PRD based on what was learned. The PRD must be self-sufficient — capture full rationale, not just pointers to the spike doc.

## Update Mapping

| What changed | PRD update |
|---|---|
| Requirement validated | Note increased confidence, no change needed unless wording should be more specific |
| Requirement changed | Update wording and priority. Full rationale in the PRD: what was tried, why it changed. Link to spike doc for traceability. |
| New requirement discovered | Add to Requirements with appropriate priority. Note discovered during spike. |
| Scope boundary confirmed or shifted | Update Scope / Boundaries with rationale. |
| New decision made | Add to Key Decisions with rationale. |
| Direction invalidated | Flag for user — this is a significant PRD change. See `edge-cases.md` for handling direction invalidation. |
| Open question resolved | Remove from Open Questions. Rationale captured in the affected section. |

If a tech plan exists, propose updates there too.
