# Brainstorming Strategy

## Why This Skill Was Restructured

The original brainstorming skill used a single phase-based workflow (Phase 0-5) with scope modifications applied at each phase. Every task entered the same pipeline; scope assessment happened after Phase 1's mandatory 2-3 questions; lighter scopes got modifications ("skip Phase 2," "use a brief instead of a PRD") but still parsed the full workflow.

This created friction at every scope level:
- **Quick scope** (bug fixes, config changes) still went through Phase 1 questions before scope was even assessed. "Fix the hover state on the sidebar" got 2-3 questions before anyone acknowledged it was a bug fix.
- **Standard scope** (small features) wrote a document to `docs/prd/`, committed it, and offered a multi-reviewer analysis. "Add a loading spinner" got the same document ceremony as "redesign the auth system."
- **Full scope** worked well, since the ceremony matched the complexity. But the skill spent most of its length on conditional logic for lighter scopes.

The restructure replaced this with scope-first routing and three self-contained paths. Each path is independently readable; the model executing Quick never parses Full path PRD ceremony.

## Core Design Decisions

### Scope Assessment Before Questions

The original skill asked 2-3 questions (Phase 1), then assessed scope. Every task, regardless of complexity, paid the cost of initial Q&A before the skill even knew what it was dealing with.

The new design assesses scope from the initial message plus a light codebase scan, before any questions. For a bug fix, the initial message ("fix the hover state") plus a quick look at relevant files gives enough signal to route to Quick immediately. For ambiguous cases, one targeted disambiguating question is allowed before routing.

This front-loads the most consequential decision (how much ceremony?) to the earliest possible moment.

### Three Self-Contained Paths

The original skill was one workflow with scope-conditional branches at each phase. This had two problems:

1. **Cognitive load on the model.** At every phase, the model had to check "am I Quick, Standard, or Full?" and follow the right branch. The skill was ~280 lines of interleaved conditional logic.
2. **Difficulty of modification.** Changing Quick path behavior meant finding and modifying scattered conditionals across 5 phases, while avoiding unintended effects on Standard and Full.

The three paths (Quick, Standard, Full) are self-contained sections. Quick is ~25 lines. Standard is ~35 lines. Full is ~65 lines. Each reads top-to-bottom with no conditionals. The model executing Quick never sees Full's PRD ceremony.

### No Documents for Quick and Standard

**Quick:** The brainstorming conversation itself is the artifact. A bug fix doesn't need a document. The model confirms its understanding, the user confirms, and they proceed. No branch safety gate (nothing to commit), no plan-review (nothing to review).

**Standard:** An inline summary in the conversation captures the key outcomes (goal, deliverables, decisions, scope boundaries, edge cases). This is presented in the conversation, not saved to a file. No commits, no branch safety gate, no plan-review.

This is an intentional tradeoff. Most Quick and Standard tasks complete in one session. The conversation itself is the record. Users wanting a durable document for a Standard task can upgrade to Full. The previous approach, writing and committing a "brief" document for every Standard task, added file management overhead without proportional value.

### The What/How Boundary

Brainstorming captures WHAT to build. Tech-planning captures HOW to build it. This boundary applies at every scope level:

- **Quick:** "Fix the hover state on the sidebar nav items" (what). "Edit `sidebar.css` line 47, change `:hover` selector to include `.nav-item`" (how, implementation territory).
- **Standard:** "Add server-side pagination to the list API, add page controls to the UI" (what). "Modify `api/list.ts` to accept `page` and `limit` params, update `ListView.tsx` to track page state" (how, tech-planning territory).
- **Full:** "Build OAuth support alongside existing auth, supporting Google and GitHub providers" (what). "Create an `OAuthProvider` abstract class with Google and GitHub implementations" (how, tech-planning territory).

The Standard path's inline summary describes deliverables ("add pagination support"), not implementation steps ("modify api/list.ts"). Users who implement directly from it bring their own judgment for the HOW. Users who want explicit HOW go to tech-planning.

Quick is the exception: for bug fixes, the what/how line blurs because "what" IS somewhat technical ("fix the hover state in the sidebar CSS"). The skill acknowledges this; Quick's question focus is "inherently technical."

### Scope-Aware Question Focus

Different scopes call for different kinds of questions:

- **Quick:** Technical. Root cause, affected behavior, edge cases. Natural for bug fixes.
- **Standard:** Product + light technical direction. "Client-side or server-side pagination?" is fine. "Offset or cursor pagination in SQL?" is tech-planning territory.
- **Full:** Product-focused. High-level technical direction ("build vs buy," "real-time vs polling") is the limit. Implementation specifics belong in tech-planning.

This prevents a common failure mode: asking implementation questions during brainstorming ("which database?" "what schema?") when the conversation should be about requirements and direction.

### Design Exploration at Broad Directions

For design and interaction-heavy tasks, the Full path offers design exploration at the Broad Directions stage, not only in Review and Handoff (after the PRD is written).

**The timing argument.** Map the Space questions (2-3) provide initial scoping: what should be preserved, what feels stale, who's the audience. After this, the model has enough constraints for meaningful exploration but hasn't locked in a direction. Text descriptions of visual or interaction concepts at Broad Directions ("The Clearing, cinematic scroll journey") are the wrong tool for inherently visual/interactive decisions. The user needs to see or experience options to choose.

**But not too early.** If exploration happens before any scoping questions, it's untethered. The model is exploring in the dark. Map the Space provides the constraints that make exploration meaningful. Deep Exploration then refines requirements within the chosen direction. The sequence is: initial scoping → exploration → detailed scoping → documentation.

**Exploration surfaces hidden requirements.** Seeing a scroll-triggered interaction concept might reveal "oh, we need this to work on slow connections." Seeing an interaction flow might surface "we need users to be able to skip this step." These requirements wouldn't emerge from text-based Q&A alone.

**The user chooses.** Exploration at Broad Directions is offered via an interactive choice, not automatically invoked. The user might already have a visual direction in mind, or might prefer to narrow conceptually first.

### Scope Upgrades with Carry-Forward

Scope can be upgraded mid-conversation when hidden complexity emerges. The carry-forward protocol ensures work isn't repeated:

1. Explain why the upgrade is suggested.
2. Everything discussed transfers. Don't re-ask questions.
3. Enter the new path at the stage that makes sense given what's already been covered.

This handles the common case: user starts with "fix this bug" (Quick), investigation reveals it's actually a design problem (Standard) or a systemic issue (Full). Without carry-forward, the user would re-answer questions they've already answered.

## What the Skill Intentionally Doesn't Do

**Prescribe exact question counts.** The original had "2-3 questions, do not extend." The new skill gives guidance ("typically 3-5 exchanges" for Standard) but trusts model judgment. Some conversations need 2 questions; some need 7. An artificial cap either cuts exploration short or forces padding.

**Mandate document creation for lighter scopes.** Standard's inline summary and Quick's confirmation gate are sufficient for tasks that complete in one session. Document creation is reserved for Full scope, where the PRD genuinely serves as a durable requirements artifact.

**Prescribe output formats.** The original had a blockquote sanity check format for Quick scope. The new skill describes what information to convey (understanding, edge cases, risks) without prescribing the exact markdown structure. The model can format appropriately for the context.

**Force a transition menu on Quick scope.** Quick exits after confirmation. No AskUserQuestion with options, no "what would you like to do next?" Just done. The user asked to fix a bug; the brainstorming confirmed the understanding; now they go fix it.
