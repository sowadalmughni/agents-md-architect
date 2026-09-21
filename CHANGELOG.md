# Changelog

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
