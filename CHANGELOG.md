# Changelog

## [1.1.0] — 2026-09-21

### Fixed

- `scripts/detect-instruction-files.sh` — the `.claude/rules` check used `[ -f ... ]` against what is documented as a directory of `.md` files, not a file, so it silently never fired. Changed to `[ -d ... ]`.
- `scripts/detect-instruction-files.sh` — the walk only checked `AGENTS.md`, not `.claude/AGENTS.md`, even though Claude Code reads both. A repo using the latter got a false "no AGENTS.md found" verdict. Added the missing check.
- `scripts/detect-instruction-files.sh` — **found during manual end-to-end verification, not by the fixture suite:** `WORKDIR` was normalized with `cd ... && pwd`, but `REPO_ROOT` (from `git rev-parse --show-toplevel`) never went through the same normalization. On any setup where git and bash can report the identical directory as different strings — a Windows short (8.3) name vs. the long name, a `C:/` prefix vs. `/c/`, or a mounted/symlinked path like this repo's own Git Bash `/tmp` or macOS's `/tmp` → `/private/tmp` — the walk's boundary check silently never matched, so it fell through to the filesystem root instead of stopping at the repo root. Fixed by running both through the same `cd ... && pwd -P` pipeline. Confirmed against a constructed sample project where the working directory path used a short-name form: before the fix, the walk checked 12 directories up to `/`; after, it checked exactly 1 (the repo root).
- `SKILL.md`, `README.md`, `reference/agents-md-vs-claude-md.md` — the "walk from the repository root" language was stated as unqualified fact. Anthropic's own docs only say "the working directory and every directory above it," without stating where the walk stops. Reworded throughout to state git-repo-root as this tool's practical scoping choice, not a confirmed platform limit, and to name the cases it doesn't cover (`--add-dir`, unusual nested-repo layouts).

### Added

- `allowed-tools: Read, Grep, Glob, Write, Edit` in `SKILL.md` frontmatter, so the skill's file operations don't need a permission prompt for actions the skill's own workflow already requires.
- Dynamic `` !`command` `` context injection in `SKILL.md`'s Step 1, running `scripts/detect-instruction-files.sh` automatically the moment the skill loads. The verdict (and drift diff, when applicable) is already in context — no Claude-initiated Bash call, no extra round-trip. The manual `bash scripts/detect-instruction-files.sh` invocation in the README's Quick Start is unaffected.
- `tests/run-tests.sh` — 10 fixture-based test cases covering every branch of the detector (no files, CLAUDE.md only, AGENTS.md only, drift, `.claude/CLAUDE.md`, `.claude/AGENTS.md`, `CLAUDE.local.md`, `.claude/rules/` as a real directory, a simulated personal `~/.claude/CLAUDE.md`, and a nested working directory that must stop the walk at repo root), including regression tests for all three bugs above. Builds throwaway git repos in a temp directory; nothing is committed as a static fixture.
- `.github/workflows/ci.yml` — runs shellcheck on both shell scripts, validates both plugin manifest JSON files, and runs the test suite on every push and PR.
- A "Development" section in `README.md` documenting how to run the test suite.

### Design Decisions

- These fixes came from actually reviewing the shipped v1.0.0 content line-by-line against Anthropic's docs after being asked for an honest rating, rather than from a bug report — the v1.0.0 release itself skipped its own planned end-to-end verification step. This release is that verification, done for real, plus the regression tests that make sure it stays true.
- The repository-root hedging follows the same rule the skill already enforces on itself (never overclaim what Claude Code actually does): an inferred scoping convenience is now labeled as this tool's choice, not asserted as verified platform behavior.

## [1.0.0] — 2026-09-21

### Added

- `SKILL.md` — Four invocation modes: New Project Setup, Migration Mode, Drift Audit Mode, Compatibility Check. Opens by stating the exact, corrected fallback rule (AGENTS.md is a fallback when no CLAUDE.md exists, not a replacement) to prevent the skill from ever overclaiming what Claude Code v2.1.277+ actually does.
- `reference/agents-md-vs-claude-md.md` — Full timeline (AGENTS.md released August 2025 by OpenAI, contributed to the Linux Foundation's Agentic AI Foundation December 2025, 60,000+ project adoption, native support in Codex/Cursor/Devin/Gemini CLI/Copilot/Windsurf/Cline/Amp/Aider before Claude Code). Documents the exact directory-walk rule Claude Code v2.1.277 uses, including which files count (CLAUDE.md, .claude/CLAUDE.md, CLAUDE.local.md at any level root-to-cwd) and which do not (personal ~/.claude/CLAUDE.md, org-managed files, .claude/rules, added-directory CLAUDE.md). Documents both the `@AGENTS.md` import method and the symlink method for teams who want a CLAUDE.md with Claude-specific extensions layered on top of a shared AGENTS.md. Notes platform exclusions (Bedrock, Vertex, Foundry) and that the change does not extend to the Skills system.
- `templates/agents-md-base.md` — Cross-tool instruction file template covering the standard sections (setup commands, tech stack, testing, code style, security, PR conventions) plus the differentiator: Module Boundaries and Data Flow Rules sections that embed real architectural constraints, not just build commands. Includes a clearly separated, deliberately minimal Tool-Specific Notes section to keep Claude-only content out of the shared body.
- `templates/claude-md-import-shim.md` — Thin CLAUDE.md template using the `@AGENTS.md` import syntax for teams with genuine Claude-specific extensions, plus the symlink fallback and a verification procedure to confirm the import actually resolves rather than being read as literal text.
- `scripts/detect-instruction-files.sh` — Implements the exact root-to-working-directory walk Claude Code uses. Correctly excludes non-qualifying files (personal global CLAUDE.md, `.claude/rules`) from blocking the fallback determination. Detects drift when both a qualifying CLAUDE.md and an AGENTS.md exist, and runs a content diff between them when exactly one of each is found. States a clear verdict: which file Claude Code is actually loading, right now, for this specific working directory.
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` — makes the repo installable as a Claude Code plugin via `/plugin marketplace add sowadalmughni/agents-md-architect` and `/plugin install agents-md-architect@sowadalmughni`, in addition to the existing manual-clone and `npx skills add` install paths.
- `LICENSE` — MIT.

### Design Decisions

- The skill states the corrected mechanics (fallback, not replacement) as a rule that cannot be overridden, specifically because the common misconception ("AGENTS.md replaced CLAUDE.md") is false and would produce visibly wrong marketing or documentation content if left unchecked.
- Detection always precedes generation. The skill never assumes which file is being read; it runs the actual walk every time.
- The recommended target state treats AGENTS.md as the single source of truth and CLAUDE.md as either absent or a content-free import pointer, structurally eliminating drift rather than relying on teams to remember to keep two files in sync.
- Architectural content (module boundaries, data flow rules) is treated as the skill's core differentiator against the many AGENTS.md generators that only produce setup-command lists.
