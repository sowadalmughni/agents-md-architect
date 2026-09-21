# AGENTS.md vs CLAUDE.md: Mechanics, Timeline, and Platform Notes

This is the factual reference this skill's claims are built on. Every statement below traces to Anthropic's own release notes or directly observed tool behavior. Do not extend or generalize past what is documented here without flagging it as inference.

---

## Timeline

**August 2025** — OpenAI releases the AGENTS.md open standard: a single, plain-Markdown, tool-agnostic file that gives any AI coding agent the context it needs (build and test commands, code style, testing instructions, security notes, PR conventions). No required fields, no proprietary syntax.

**Through late 2025** — Codex, Cursor, Devin, Gemini CLI, GitHub Copilot, VS Code, Windsurf, Cline, Amp, and Aider all add native AGENTS.md support. Claude Code does not.

**December 2025** — AGENTS.md is contributed to the Linux Foundation's Agentic AI Foundation. The foundation's launch announcement states more than 60,000 open-source projects had already adopted the standard.

**Through mid-2026** — Anthropic has not committed to native AGENTS.md support. A GitHub issue asking for it accumulates over 4,300 upvotes (later cited elsewhere as 5,200+ reactions on the same cluster). Anthropic's own documentation instead tells developers to force the behavior manually: `ln -s AGENTS.md CLAUDE.md` at the terminal, or import the file's content from inside CLAUDE.md.

**September 18, 2026 — Claude Code v2.1.277.** Native AGENTS.md support ships, as a fallback: in a project with no CLAUDE.md, Claude Code reads AGENTS.md instead. Configurable under Project instructions in `/config`. Not yet available on Bedrock, Vertex, or Foundry.

**September 19, 2026 — Claude Code v2.1.278.** A separate, unrelated change ships alongside it: auto mode for Claude API, Enterprise, Bedrock, Vertex, Foundry, and gateway users now defaults to a server-side classifier with no classifier-overhead billing.

---

## The Exact Fallback Rule

Claude Code's instruction-file loading behaves as one of two modes, controlled by the `instructionFiles` setting in `/config` → Project instructions:

- **`claude-md`** — only CLAUDE.md is loaded, by the engine, exactly as before v2.1.277. AGENTS.md is never consulted. This is the non-default option; choose it explicitly if you want to opt out of the fallback entirely.

- **`claude-md-or-agents-md`** (the default) — a project with no instruction files "of its own" gets its AGENTS.md files loaded instead, in exactly the position and manner CLAUDE.md would have been loaded.

### What "of its own" means, precisely

The check walks from the repository root down to the current working directory and looks for:

- `CLAUDE.md`
- `.claude/CLAUDE.md`
- `CLAUDE.local.md`

If **any** of these exist at **any** level of that walk, the project has instructions "of its own," the fallback does not trigger, and AGENTS.md is ignored entirely — even if AGENTS.md also exists.

### What does NOT count toward that check

These are real files that can exist in a Claude Code session, and none of them block the AGENTS.md fallback, because the nested walk never sees them:

- An organization's centrally managed instruction file
- The user's own personal `~/.claude/CLAUDE.md`
- A `.claude/rules` file
- A CLAUDE.md belonging to an added directory (a directory brought into context that is not part of the walked path)

**Practical consequence:** a developer with a personal global `~/.claude/CLAUDE.md` can still have Claude Code load a given project's AGENTS.md, because the global file was never in the root-to-cwd walk to begin with. Do not assume the presence of any CLAUDE.md-shaped file anywhere in a person's setup blocks the fallback — only a project-scoped one in the actual walked path does.

---

## Platform Availability

AGENTS.md fallback support is not yet available on:

- AWS Bedrock
- Google Vertex
- Microsoft Foundry

Projects on these platforms should assume `claude-md` behavior (CLAUDE.md only, no fallback) regardless of the `/config` setting, until Anthropic extends support.

---

## What This Change Does Not Touch

The AGENTS.md fallback is scoped narrowly to the memory/instruction file Claude Code loads at session start. It explicitly does **not** extend to the Skills system — a project's `.claude/skills` (or equivalent) directory and its SKILL.md files are unaffected by this setting and continue to work exactly as before.

---

## The Import and Symlink Methods (Still Valid, Now Optional)

Before native support shipped, two operator-side patterns let a CLAUDE.md-only Claude Code consume AGENTS.md content. Both remain valid today and are now the correct approach specifically for teams who want a CLAUDE.md to exist (for genuine Claude-specific extensions) while keeping AGENTS.md as the single source of truth for shared content.

### Method 1: Import (recommended)

Claude Code's memory system supports `@path/to/file` import syntax inside CLAUDE.md. A CLAUDE.md consisting of nothing but an import pulls in AGENTS.md's full content at session start, so Claude reads the same shared instructions every other agent reads, plus whatever Claude-specific content is added below the import line.

```markdown
# CLAUDE.md

@AGENTS.md

## Claude Code-specific notes

(Only content that is genuinely Claude-specific belongs below this line —
slash commands, Claude-only tool configuration, etc. Shared architecture,
setup commands, and conventions belong in AGENTS.md, not duplicated here.)
```

This is the pattern `./templates/claude-md-import-shim.md` generates.

### Method 2: Symlink

For a stronger single-source-of-truth guarantee with zero drift risk (there is only one file on disk, under two names), symlink instead of importing:

```bash
ln -s AGENTS.md CLAUDE.md
```

Trade-off versus the import method: a symlink cannot carry any Claude-specific addendum, since both names resolve to the identical file. Use this only when the project genuinely has no Claude-specific content to add.

---

## The Documented Failure Mode This Skill Targets

Independent reports describe repositories where Codex's instructions specified one test command and Claude's specified a different one, because the two instruction files were maintained separately and drifted. This is the direct, predictable consequence of two files with no reconciliation mechanism, compounded by the fact that most contributors do not know CLAUDE.md silently wins over AGENTS.md whenever both exist. A team can believe they are on the cross-tool standard while Claude Code has quietly been following a stale CLAUDE.md the entire time.

The fix is structural, not procedural: eliminate the second independently-maintained file. Either delete CLAUDE.md entirely and let the documented fallback do its job, or replace it with a thin import shim that can never drift because it has no independent content of its own.

---

## Recommended Target State

For a project with more than one AI coding agent in active use (which, per the adoption figures above, is most serious teams as of late 2026):

1. `AGENTS.md` at the repository root is the single source of truth for setup commands, code style, testing instructions, security notes, PR conventions, and architectural constraints.
2. No CLAUDE.md exists, unless genuine Claude-specific content is needed — in which case, a CLAUDE.md exists containing only the `@AGENTS.md` import plus that Claude-specific addendum.
3. Nothing in `.claude/CLAUDE.md` or `CLAUDE.local.md` exists unintentionally at any level between repository root and any working directory a contributor might use, since any one of them silently reactivates CLAUDE.md-only behavior for that path.
