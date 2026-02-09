# Changelog

All notable changes to the iterative-engineering plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-02-08

### Added

- **Spike skill: static HTML prototypes** — new spike medium for visual/UX exploration. Self-contained HTML files preserved in `docs/spikes/YYYY-MM-DD-<topic>/prototypes/`. No worktree needed.
- **Spike skill: standalone mode** — invoke spikes without a PRD or workflow context. Spike doc becomes the primary output. Phase 4 wrap-up handles the no-PRD case.
- **Spike skill: multi-variant exploration** — "Try a different approach" in the feedback loop. Multiple variants coexist in a single worktree (in-codebase) or as separate HTML files.
- **Spike skill: directory-based organization** — spike docs moved from flat files (`YYYY-MM-DD-<topic>-spike.md`) to directories (`YYYY-MM-DD-<topic>/spike.md`) with optional `prototypes/` subdirectory.
- **Test enforcement** — planning and implementation workflows now require test creation alongside feature work.

### Changed

- **Spike skill: progressive disclosure** — moved PRD update mapping, anti-patterns, and edge cases to reference files. SKILL.md trimmed from ~2,600 to ~1,850 words.
- **Spike skill: commit cadence** — durable artifacts (spike doc, HTML prototypes) committed incrementally to the original branch to prevent accidental loss.

---

## [1.1.0] - 2026-02-08

### Added

- Brainstorming Phase 5 surfaces "user decision needed" open questions interactively before presenting main options. Multiple choice when natural options exist, free-form when open-ended, defer when not ready.

---

## [1.0.0] - 2026-02-08

Initial release — 11 skills, 13 agents.

Core workflow: brainstorming → research → spike → tech planning → implementing, with multi-agent reviews at each stage.
