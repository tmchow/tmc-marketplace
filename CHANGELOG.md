# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] - 2026-02-10

### Fixed

- **External reviewer Bash permissions** — external reviewer agents (gemini-reviewer, codex-reviewer, claude-reviewer) couldn't invoke their CLIs because subagents can't get interactive Bash permission approval. Replaced the 3 agent files with inline CLI execution in the code-review skill, where Bash calls happen in the main agent context. ([#38](https://github.com/tmchow/tmc-marketplace/pull/38))
- **External reviewers now opt-in** — in Full mode, the user is asked whether to include external model CLIs before running them, rather than launching automatically. ([#38](https://github.com/tmchow/tmc-marketplace/pull/38))
- **Missing Codex `--uncommitted` path** — added `codex review --uncommitted` for standalone/no-commits-yet scenarios. ([#38](https://github.com/tmchow/tmc-marketplace/pull/38))

---

## [1.4.0] - 2026-02-09

### Added

- **External reviewers (Gemini, Codex, Claude)** — 3 new agents invoke competing model provider CLIs for independent, model-diverse code review perspectives. Each self-identifies and skips when sharing the host platform's model provider. Full mode only. ([#35](https://github.com/tmchow/tmc-marketplace/pull/35))
- **Diff-anchored three-tier scoping** — all 5 built-in reviewers now follow primary/secondary/pre-existing scope tiers, with pre-existing issues tagged separately and excluded from merge verdicts. ([#35](https://github.com/tmchow/tmc-marketplace/pull/35))
- **Code review strategy doc** — `docs/CODE_REVIEW_STRATEGY.md` documenting the ensemble review architecture, execution model, and design principles. ([#35](https://github.com/tmchow/tmc-marketplace/pull/35))
- **Fix execution strategy** — after code review, fixes are applied in severity order (Critical → High → Medium → Low) with re-review between severity tiers. ([#36](https://github.com/tmchow/tmc-marketplace/pull/36))

### Fixed

- **Interactive question enforcement** — all user-facing prompts across skills now use the interactive question tool (AskUserQuestion) instead of plain-text prompts that get lost in output. ([#36](https://github.com/tmchow/tmc-marketplace/pull/36))

---

## [1.3.5] - 2026-02-09

### Fixed

- **Severity acceptance two-path flow** — redesigned as two prompts: accept recommended fixes (Critical+High) or choose severity levels via multi-select. Medium/Low-only reviews no longer skipped. Code-review omits Fix order when invoked from implementing to prevent competing signals. ([#29](https://github.com/tmchow/tmc-marketplace/pull/29))

### Changed

- **Changelog** — moved to repo root (repo-wide, not plugin-specific). Backfilled PR references and version comparison links per Keep a Changelog spec. ([#30](https://github.com/tmchow/tmc-marketplace/pull/30), [#31](https://github.com/tmchow/tmc-marketplace/pull/31))
- **Conventional commits** — added commit and PR title conventions to AGENTS.md. ([#31](https://github.com/tmchow/tmc-marketplace/pull/31))

---

## [1.3.4] - 2026-02-09

### Fixed

- **Redundant section review** — skip section-level code review when plan has only one section; Phase 3's final review covers the same code plus simplification. ([#27](https://github.com/tmchow/tmc-marketplace/pull/27))
- **Sequential review/simplification** — Phase 3 steps are strictly sequential. Simplifier must complete before code review starts. Anti-pattern added for parallelizing code changes with review. ([#27](https://github.com/tmchow/tmc-marketplace/pull/27))
- **Severity acceptance** — now a separate interaction from next-step options. All severity levels with findings are shown (not just the highest). Recommend re-review after fixes, wrap-up only when clean or skipped. ([#27](https://github.com/tmchow/tmc-marketplace/pull/27))
- **Code review agent count** — emphasized spawning all 5 reviewers in Full mode to prevent launching only one. ([#27](https://github.com/tmchow/tmc-marketplace/pull/27))

---

## [1.3.3] - 2026-02-09

### Fixed

- **PRD requirements format** — single markdown table (`ID | Priority | Requirement`) instead of sub-headers per priority. Shorter labels: Must-Have → Must, Nice-to-Have → Nice. ([#24](https://github.com/tmchow/tmc-marketplace/pull/24))
- **Review recommendations** — always recommend "Review the PRD" on first pass; no recommendation after first review round (let user decide). ([#24](https://github.com/tmchow/tmc-marketplace/pull/24))
- **Tech plan line references** — reference code by function/class/pattern name, not line numbers that drift. ([#24](https://github.com/tmchow/tmc-marketplace/pull/24))
- **Doc commits** — PRDs, plans, and research updates committed at every checkpoint instead of left uncommitted across workflow stages. Branch safety gate prevents accidental commits to default branch. ([#24](https://github.com/tmchow/tmc-marketplace/pull/24))
- **Implementing resume** — Phase 0 no longer skips Phase 1 setup (task creation, HZL detection, workspace isolation) when prior conversation context exists but no tasks were created. Affects both HZL and built-in task tracking. ([#26](https://github.com/tmchow/tmc-marketplace/pull/26))

### Changed

- **README** — surfaced agent teams with fallback in Reviews section and added doc-commit design decision. ([#24](https://github.com/tmchow/tmc-marketplace/pull/24))

---

## [1.3.2] - 2026-02-08

### Fixed

- **Auto-tag workflow** — added `contents: write` permission so the GitHub Actions token can push tags. ([#21](https://github.com/tmchow/tmc-marketplace/pull/21))

---

## [1.3.1] - 2026-02-08

### Changed

- **Spike skill** — restructured for clarity and reliability. ([#19](https://github.com/tmchow/tmc-marketplace/pull/19))

### Infrastructure

- **Auto-tag releases** — `v<version>` tag created automatically when release PRs merge. ([#18](https://github.com/tmchow/tmc-marketplace/pull/18))

---

## [1.3.0] - 2026-02-08

### Added

- **Install script** — one-liner `curl | bash` installer for both Claude Code (plugin marketplace) and Codex (skill files). Includes `--uninstall`, retry logic, and idempotent operations. ([#16](https://github.com/tmchow/tmc-marketplace/pull/16))
- **Codex support** — skills now installable to `~/.codex/skills/` via tarball extraction, with manifest-based cleanup on uninstall. ([#16](https://github.com/tmchow/tmc-marketplace/pull/16))

---

## [1.2.0] - 2026-02-08

### Added

- **Spike skill: static HTML prototypes** — new spike medium for visual/UX exploration. Self-contained HTML files preserved in `docs/spikes/YYYY-MM-DD-<topic>/prototypes/`. No worktree needed. ([#14](https://github.com/tmchow/tmc-marketplace/pull/14))
- **Spike skill: standalone mode** — invoke spikes without a PRD or workflow context. Spike doc becomes the primary output. Phase 4 wrap-up handles the no-PRD case. ([#14](https://github.com/tmchow/tmc-marketplace/pull/14))
- **Spike skill: multi-variant exploration** — "Try a different approach" in the feedback loop. Multiple variants coexist in a single worktree (in-codebase) or as separate HTML files. ([#14](https://github.com/tmchow/tmc-marketplace/pull/14))
- **Spike skill: directory-based organization** — spike docs moved from flat files (`YYYY-MM-DD-<topic>-spike.md`) to directories (`YYYY-MM-DD-<topic>/spike.md`) with optional `prototypes/` subdirectory. ([#14](https://github.com/tmchow/tmc-marketplace/pull/14))
- **Test enforcement** — planning and implementation workflows now require test creation alongside feature work. ([#13](https://github.com/tmchow/tmc-marketplace/pull/13))

### Changed

- **Spike skill: progressive disclosure** — moved PRD update mapping, anti-patterns, and edge cases to reference files. SKILL.md trimmed from ~2,600 to ~1,850 words. ([#14](https://github.com/tmchow/tmc-marketplace/pull/14))
- **Spike skill: commit cadence** — durable artifacts (spike doc, HTML prototypes) committed incrementally to the original branch to prevent accidental loss. ([#14](https://github.com/tmchow/tmc-marketplace/pull/14))

---

## [1.1.0] - 2026-02-08

### Added

- Brainstorming Phase 5 surfaces "user decision needed" open questions interactively before presenting main options. Multiple choice when natural options exist, free-form when open-ended, defer when not ready. ([#11](https://github.com/tmchow/tmc-marketplace/pull/11))

---

## [1.0.0] - 2026-02-08

Initial release — 11 skills, 13 agents. ([#10](https://github.com/tmchow/tmc-marketplace/pull/10))

Core workflow: brainstorming → research → spike → tech planning → implementing, with multi-agent reviews at each stage.

<!-- Version comparison links -->
[1.4.1]: https://github.com/tmchow/tmc-marketplace/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.5...v1.4.0
[1.3.5]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.4...v1.3.5
[1.3.4]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/tmchow/tmc-marketplace/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/tmchow/tmc-marketplace/releases/tag/v1.3.0
[1.2.0]: https://github.com/tmchow/tmc-marketplace/compare/438b3a4...e83aba2
[1.1.0]: https://github.com/tmchow/tmc-marketplace/compare/cca60ff...438b3a4
[1.0.0]: https://github.com/tmchow/tmc-marketplace/compare/88dcd58...cca60ff
