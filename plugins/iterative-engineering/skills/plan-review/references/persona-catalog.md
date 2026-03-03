# Persona Catalog

6 reviewer personas organized in three tiers. The orchestrator uses this catalog to select which reviewers to spawn for each review.

## Document-type (exactly 1)

Exactly one is spawned based on document type. The orchestrator determines document type from the filename, content, or caller context.

| Persona | Agent file | Selected when | Identity |
|---------|-----------|--------------|----------|
| `prd-reviewer` | `agents/prd-reviewer.md` | Document is a PRD or brainstorm | Senior product leader evaluating product document quality |
| `tech-plan-reviewer` | `agents/tech-plan-reviewer.md` | Document is a tech plan | Implementer evaluating whether they can code from this plan |

## Always-on (1)

Spawned on every review regardless of document type or content.

| Persona | Agent file | Focus |
|---------|-----------|-------|
| `coherence-reviewer` | `agents/coherence-reviewer.md` | Internal consistency, contradictions, terminology drift, structural issues |

## Conditional (3)

Spawned when the orchestrator identifies relevant patterns in the document. The orchestrator reads the document and reasons about selection — this is agent judgment, not keyword matching.

| Persona | Agent file | Select when... |
|---------|-----------|---------------|
| `skeptic-reviewer` | `agents/skeptic-reviewer.md` | Plan proposes abstractions, multi-layer architecture, plugin systems, generic frameworks, or infrastructure ahead of need |
| `feasibility-reviewer` | `agents/feasibility-reviewer.md` | Tech plan proposes architecture decisions, external system integrations, performance requirements, or migration strategies |
| `scope-guardian-reviewer` | `agents/scope-guardian-reviewer.md` | PRD has multiple priority levels with potential conflicts, unclear scope boundaries, many requirements where goal alignment isn't obvious, or stated goals that don't connect to requirements |

## Selection rules

1. **Determine document type** and spawn the matching doc-type persona.
2. **Always spawn coherence-reviewer.**
3. **For each conditional persona**, read the document and decide whether the persona's domain is relevant. This is a judgment call, not a keyword match.
4. **Announce the team** before spawning with a one-line justification per conditional reviewer selected.
