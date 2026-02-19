# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.9.0] - 2026-02-19

### Changed

- **Brainstorming: scope-first routing** — scope is now assessed from the initial message + a light codebase scan before any questions, replacing the old Phase 1 Q&A-then-assess flow. Three self-contained paths replace the single phase-based workflow with scope conditionals at each phase. ([#63](https://github.com/tmchow/tmc-marketplace/pull/63))
- **Quick path exits fast** — 0-2 questions, confirmation gate, done. No documents, no branch safety gate, no plan-review, no transition menu. Bug fixes and config changes no longer get ceremony they don't need. ([#63](https://github.com/tmchow/tmc-marketplace/pull/63))
- **Standard path drops document requirement** — inline summary in the conversation replaces the mandatory implementation brief that was committed to `docs/prd/`. No commits, no plan-review. Exit options: implement directly or create a tech plan. ([#63](https://github.com/tmchow/tmc-marketplace/pull/63))
- **Design exploration offered at Broad Directions** — for design/interaction-heavy tasks in Full scope, the skill now offers design exploration before locking a direction (after initial scoping questions), not only in Review and Handoff. ([#63](https://github.com/tmchow/tmc-marketplace/pull/63))
- **Tech-planning scope note updated** — clarifies Quick skips tech-planning, Standard may skip it, and reinforces the what/how boundary between brainstorming and tech-planning. ([#63](https://github.com/tmchow/tmc-marketplace/pull/63))

### Added

- **Design exploration skill** — new skill replacing the spike skill. Generates interactive HTML galleries with per-variation tuning controls, star ratings, and structured export for multi-round iteration. Parallel subagent architecture keeps context windows small. Concludes with a design direction document. ([#62](https://github.com/tmchow/tmc-marketplace/pull/62))
- **BRAINSTORMING_STRATEGY.md** — strategy doc capturing design decisions behind the restructure: scope-first routing, three self-contained paths, what/how boundary, no documents for Quick/Standard, design exploration timing. ([#63](https://github.com/tmchow/tmc-marketplace/pull/63))

### Fixed

- **Design exploration sleep-polling** — replaced vague "use platform's built-in mechanism" with explicit `TaskOutput` guidance. Orchestrator no longer uses `sleep N && ls` to poll for subagent completion. ([#63](https://github.com/tmchow/tmc-marketplace/pull/63))

---

## [1.8.0] - 2026-02-17

### Added

- **Scope-aware brainstorming (Quick/Standard/Full)** — after initial Q&A, brainstorming assesses scope and adjusts ceremony. Quick gets focused Q&A and inline sanity check; Standard produces a lightweight implementation brief with full review; Full produces a complete PRD with structured tech planning. ([#60](https://github.com/tmchow/tmc-marketplace/pull/60))
- **Changelog links in READMEs** — both repo and plugin READMEs now link to the changelog, since we don't use GitHub Releases. ([#60](https://github.com/tmchow/tmc-marketplace/pull/60))

### Changed

- **YAGNI reviewer → Complexity & Debt Reviewer** — recalibrated from "is this minimal?" to "is the complexity justified?" Focus shifted to maintenance burden over implementation cost. Added "What NOT to Flag" guardrails (simple additions, user-requested features, proportional edge cases). ([#60](https://github.com/tmchow/tmc-marketplace/pull/60))
- **Simplicity reviewer Section 4** — renamed from "YAGNI Violations" to "Dead Flexibility & Dead Code" to remove overlap with Section 1 (Over-Engineering). Section 1 catches things being built unnecessarily; Section 4 catches things that exist unnecessarily. ([#60](https://github.com/tmchow/tmc-marketplace/pull/60))
- **HZL selection uses plan-size heuristic** — implementing skill now uses plan structure (single section or ≤5 subtasks → built-in tasks; multiple sections or 6+ subtasks → offer HZL) instead of referencing brainstorming's scope assessment. ([#60](https://github.com/tmchow/tmc-marketplace/pull/60))
- **Skill descriptions lead with purpose** — frontmatter descriptions rewritten to show what the skill does before listing triggers, so the slash command menu shows useful info before truncation. ([#60](https://github.com/tmchow/tmc-marketplace/pull/60))

---

## [1.7.5] - 2026-02-15

### Fixed

- **External CLIs use file-based diff instead of inline** — Gemini and Claude now read the diff from a staged `.external-review-diff.txt` file instead of receiving it as a shell argument, avoiding `ARG_MAX` limits on large diffs (~700KB+). Codex switches to the built-in `codex exec review --base` preset which computes its own diff with filesystem access. ([#58](https://github.com/tmchow/tmc-marketplace/pull/58))

---

## [1.7.4] - 2026-02-14

### Changed

- **Tech plan Testing Strategy prompt** — added "New coverage" prompt to the Testing Strategy template, asking planners to identify which test scenarios validate genuinely new behavior vs. existing tests ported to new data shapes. Updated quality checklist to match. ([#56](https://github.com/tmchow/tmc-marketplace/pull/56))

---

## [1.7.3] - 2026-02-13

### Fixed

- **Task ID passed to workers for all task systems** — workers now receive the task ID for both HZL and built-in tasks (previously only HZL), and mark completion in both systems. ([#54](https://github.com/tmchow/tmc-marketplace/pull/54))
- **Subagent rationale clarified** — implementing skill now explains that subagents are always used (even for single-subtask batches) to preserve orchestrator context for reviews and phase transitions, not just for parallelism. ([#54](https://github.com/tmchow/tmc-marketplace/pull/54))

---

## [1.7.2] - 2026-02-13

### Changed

- **"Commit as you go" key principle** — elevated the commit-per-subtask pattern to a top-level key principle in the implementing skill, making incremental commits an explicit expectation rather than buried in the Commit Pattern section. ([#52](https://github.com/tmchow/tmc-marketplace/pull/52))

---

## [1.7.1] - 2026-02-13

### Fixed

- **External reviewers pass file paths instead of inlining content** — external CLIs now receive a document file path and read the file themselves, avoiding context-limit failures on large documents. All three sandbox modes (Gemini `-s`, Codex `--sandbox read-only`, Claude `--max-turns 3`) support workspace file reads. ([#50](https://github.com/tmchow/tmc-marketplace/pull/50))
- **Fix loop step collapsing** — strengthened standalone fix loop guardrails to prevent the model from merging Steps 5–8 into a single question after multiple review rounds, which was eliminating the "fix then re-review" path. ([#50](https://github.com/tmchow/tmc-marketplace/pull/50))

---

## [1.7.0] - 2026-02-11

### Added

- **Standalone fix loops** — code-review and plan-review skills now handle the full fix-review cycle (severity acceptance, subagent fixes, re-review) when invoked standalone or from implementation-wrapup, instead of only returning findings. Implementing still owns its own fix loop. ([#48](https://github.com/tmchow/tmc-marketplace/pull/48))

### Fixed

- **Codex review `--sandbox` flag** — removed invalid `--sandbox read-only` from all `codex review` invocations. The `review` subcommand is inherently read-only and does not accept that flag. ([#47](https://github.com/tmchow/tmc-marketplace/pull/47))

---

## [1.6.0] - 2026-02-10

### Added

- **External plan reviewers (Gemini, Codex, Claude)** — opt-in external CLI reviewers for document reviews (PRDs, brainstorms, tech plans), providing model-diverse perspectives alongside the 4 built-in reviewers. All reviewer sources selected via single multi-select prompt. ([#45](https://github.com/tmchow/tmc-marketplace/pull/45))
- **Document-type-aware persona** — external review prompt adapts perspective by document type: product strategy lens for PRDs/brainstorms, engineering leadership lens for tech plans. ([#45](https://github.com/tmchow/tmc-marketplace/pull/45))
- **Plan review strategy doc** — `docs/PLAN_REVIEW_STRATEGY.md` documenting the ensemble review architecture, safety model, and design decisions for plan review. ([#45](https://github.com/tmchow/tmc-marketplace/pull/45))

### Changed

- **Plan-review flow restructured** — all reviewer sources are now opt-in. Step 2 determines reviewers via multi-select, Step 2a spawns built-in team (if selected), Step 2b runs external CLIs (if selected). ([#45](https://github.com/tmchow/tmc-marketplace/pull/45))
- **Codex plan-review invocation** — uses `codex exec --sandbox read-only` for non-interactive execution (base `codex` starts interactive TUI that hangs from agent Bash tools). ([#45](https://github.com/tmchow/tmc-marketplace/pull/45))

### Removed

- **Unused output template** — deleted `references/review-output-template.md` (was never referenced from SKILL.md). Essential formatting rules inlined into Step 4. ([#45](https://github.com/tmchow/tmc-marketplace/pull/45))

---

## [1.5.0] - 2026-02-10

### Changed

- **Unified external reviewer prompt** — all three external CLIs (Gemini, Codex, Claude) now use the same review prompt template with the diff inlined, replacing per-CLI strategies. Focus areas align with the 5 built-in reviewer domains for easier reconciliation. ([#43](https://github.com/tmchow/tmc-marketplace/pull/43))
- **Prompt template embedded in skill** — the review prompt is embedded directly in SKILL.md and staged locally via Write tool, eliminating all sandbox permission prompts when accessing plugin directory paths. ([#43](https://github.com/tmchow/tmc-marketplace/pull/43))
- **Single Step 1 Bash call** — merge-base, file list, and diff combined into one command with labeled output markers, reducing permission prompts from 3 to 1. ([#43](https://github.com/tmchow/tmc-marketplace/pull/43))
- **Tighter prompt template** — compressed redundant instructions, removed items external CLIs can't evaluate (plan compliance), merged overlapping constraints for ~30% fewer tokens. ([#43](https://github.com/tmchow/tmc-marketplace/pull/43))

### Fixed

- **Gemini plan mode error** — dropped `--approval-mode plan` which requires experimental config that can't be guaranteed. Sandbox (`-s`) is sufficient since diff is inlined and prompt instructs no tool usage. ([#43](https://github.com/tmchow/tmc-marketplace/pull/43))
- **CLI invocation correctness** — Codex uses `review --sandbox read-only` with heredoc stdin, Claude `-p` requires prompt as immediately following argument with flags after. ([#43](https://github.com/tmchow/tmc-marketplace/pull/43))

---

## [1.4.2] - 2026-02-10

### Fixed

- **Per-CLI opt-in selection** — external reviewer question is now multi-select, allowing users to choose individual CLIs (e.g., Gemini only, Codex only, or both) instead of all-or-nothing. Falls back to yes/no when only 1 CLI is available. ([#40](https://github.com/tmchow/tmc-marketplace/pull/40))
- **Invalid Codex CLI flags** — removed `--sandbox read-only` (not a valid flag; `codex review` is inherently read-only) and unreachable `codex exec` fallback. ([#40](https://github.com/tmchow/tmc-marketplace/pull/40))
- **Codex prompt argument conflict** — `codex review --base` and `--uncommitted` are mutually exclusive with custom prompts. Codex now uses its built-in review logic; shared prompt template limited to Gemini and Claude. ([#40](https://github.com/tmchow/tmc-marketplace/pull/40))
- **Removed `timeout` wrapper** — `timeout` is not available on macOS by default. Each CLI already has its own safety mode. ([#40](https://github.com/tmchow/tmc-marketplace/pull/40))
- **Reduced git command overhead** — scope detection now uses exactly 2-3 Bash calls (merge-base once, then file list + diff in parallel) instead of 6+. ([#40](https://github.com/tmchow/tmc-marketplace/pull/40))
- **Avoided `/tmp` permission prompts** — prompts passed via command argument or heredoc stdin instead of temp files. ([#40](https://github.com/tmchow/tmc-marketplace/pull/40))
- **External reviewers marked experimental** — sections labeled "Experimental" across all docs with Codex timing warning (5+ minutes). ([#41](https://github.com/tmchow/tmc-marketplace/pull/41))
- **Post-review prompt now interactive** — "How would you like to proceed?" uses the interactive question tool instead of free-form text output. ([#41](https://github.com/tmchow/tmc-marketplace/pull/41))

---

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
[1.9.0]: https://github.com/tmchow/tmc-marketplace/compare/v1.8.0...v1.9.0
[1.8.0]: https://github.com/tmchow/tmc-marketplace/compare/v1.7.5...v1.8.0
[1.7.5]: https://github.com/tmchow/tmc-marketplace/compare/v1.7.4...v1.7.5
[1.7.4]: https://github.com/tmchow/tmc-marketplace/compare/v1.7.3...v1.7.4
[1.7.3]: https://github.com/tmchow/tmc-marketplace/compare/v1.7.2...v1.7.3
[1.7.2]: https://github.com/tmchow/tmc-marketplace/compare/v1.7.1...v1.7.2
[1.7.1]: https://github.com/tmchow/tmc-marketplace/compare/v1.7.0...v1.7.1
[1.7.0]: https://github.com/tmchow/tmc-marketplace/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/tmchow/tmc-marketplace/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/tmchow/tmc-marketplace/compare/v1.4.2...v1.5.0
[1.4.2]: https://github.com/tmchow/tmc-marketplace/compare/v1.4.1...v1.4.2
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
