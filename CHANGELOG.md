# Changelog

All notable changes to the iterative-engineering plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.4] - 2026-02-09

### Fixed

- **Redundant section review** — skip section-level code review when plan has only one section; Phase 3's final review covers the same code plus simplification. (#27)
- **Sequential review/simplification** — Phase 3 steps are strictly sequential. Simplifier must complete before code review starts. Anti-pattern added for parallelizing code changes with review. (#27)
- **Severity acceptance** — now a separate interaction from next-step options. All severity levels with findings are shown (not just the highest). Recommend re-review after fixes, wrap-up only when clean or skipped. (#27)
- **Code review agent count** — emphasized spawning all 5 reviewers in Full mode to prevent launching only one. (#27)

---

## [1.3.3] - 2026-02-09

### Fixed

- **PRD requirements format** — single markdown table (`ID | Priority | Requirement`) instead of sub-headers per priority. Shorter labels: Must-Have → Must, Nice-to-Have → Nice. (#24)
- **Review recommendations** — always recommend "Review the PRD" on first pass; no recommendation after first review round (let user decide). (#24)
- **Tech plan line references** — reference code by function/class/pattern name, not line numbers that drift. (#24)
- **Doc commits** — PRDs, plans, and research updates committed at every checkpoint instead of left uncommitted across workflow stages. Branch safety gate prevents accidental commits to default branch. (#24)
- **Implementing resume** — Phase 0 no longer skips Phase 1 setup (task creation, HZL detection, workspace isolation) when prior conversation context exists but no tasks were created. Affects both HZL and built-in task tracking. (#26)

### Changed

- **README** — surfaced agent teams with fallback in Reviews section and added doc-commit design decision. (#24)

---

## [1.3.2] - 2026-02-08

### Fixed

- **Auto-tag workflow** — added `contents: write` permission so the GitHub Actions token can push tags. (#21)

---

## [1.3.1] - 2026-02-08

### Changed

- **Spike skill** — restructured for clarity and reliability. (#19)

### Infrastructure

- **Auto-tag releases** — `v<version>` tag created automatically when release PRs merge. (#18)

---

## [1.3.0] - 2026-02-08

### Added

- **Install script** — one-liner `curl | bash` installer for both Claude Code (plugin marketplace) and Codex (skill files). Includes `--uninstall`, retry logic, and idempotent operations. (#16)
- **Codex support** — skills now installable to `~/.codex/skills/` via tarball extraction, with manifest-based cleanup on uninstall. (#16)

---

## [1.2.0] - 2026-02-08

### Added

- **Spike skill: static HTML prototypes** — new spike medium for visual/UX exploration. Self-contained HTML files preserved in `docs/spikes/YYYY-MM-DD-<topic>/prototypes/`. No worktree needed. (#14)
- **Spike skill: standalone mode** — invoke spikes without a PRD or workflow context. Spike doc becomes the primary output. Phase 4 wrap-up handles the no-PRD case. (#14)
- **Spike skill: multi-variant exploration** — "Try a different approach" in the feedback loop. Multiple variants coexist in a single worktree (in-codebase) or as separate HTML files. (#14)
- **Spike skill: directory-based organization** — spike docs moved from flat files (`YYYY-MM-DD-<topic>-spike.md`) to directories (`YYYY-MM-DD-<topic>/spike.md`) with optional `prototypes/` subdirectory. (#14)
- **Test enforcement** — planning and implementation workflows now require test creation alongside feature work. (#13)

### Changed

- **Spike skill: progressive disclosure** — moved PRD update mapping, anti-patterns, and edge cases to reference files. SKILL.md trimmed from ~2,600 to ~1,850 words. (#14)
- **Spike skill: commit cadence** — durable artifacts (spike doc, HTML prototypes) committed incrementally to the original branch to prevent accidental loss. (#14)

---

## [1.1.0] - 2026-02-08

### Added

- Brainstorming Phase 5 surfaces "user decision needed" open questions interactively before presenting main options. Multiple choice when natural options exist, free-form when open-ended, defer when not ready. (#11)

---

## [1.0.0] - 2026-02-08

Initial release — 11 skills, 13 agents. (#10)

Core workflow: brainstorming → research → spike → tech planning → implementing, with multi-agent reviews at each stage.

<!-- Version comparison links -->
[1.3.4]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/tmchow/tmc-marketplace/releases/tag/v1.3.0
