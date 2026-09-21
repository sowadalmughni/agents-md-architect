# CLAUDE.md Import Shim

Use this only when a project genuinely needs Claude-specific content layered on top of the shared `AGENTS.md`. If there is no Claude-specific content to add, do not create a CLAUDE.md at all — let the documented fallback (Claude Code v2.1.277+) load `AGENTS.md` directly. An empty or redundant CLAUDE.md is worse than no CLAUDE.md, because its mere presence blocks the fallback for every agent, including Claude, even when it adds nothing.

---

## When to use this shim instead of deleting CLAUDE.md entirely

- The project has Claude Code-specific slash commands or workflows that don't apply to other agents.
- The team runs Claude Code Skills that expect certain CLAUDE.md-level context not expressible in the shared AGENTS.md.
- The organization mandates a CLAUDE.md for policy or tooling reasons outside this project's control.

If none of these apply, delete CLAUDE.md and stop here.

---

## The Shim

```markdown
# CLAUDE.md

@AGENTS.md

## Claude Code-specific notes

[Only content that is genuinely Claude-specific belongs below this line.
Everything else — setup commands, architecture, module boundaries, data flow
rules, testing instructions, code style, security constraints — lives in
AGENTS.md and is imported above. Do not duplicate it here; duplication is
exactly the drift risk this structure exists to eliminate.]

[Example of genuinely Claude-specific content:]
- This project expects the following Claude Code skills to be installed:
  [list, e.g., spec-driven-dev, ai-codebase-audit]
- [Any Claude-only tool configuration, e.g., specific MCP server expectations]
```

---

## Verifying the Import Works

After creating the shim, confirm Claude Code is actually resolving the `@AGENTS.md` import rather than treating it as literal text:

1. Start a new Claude Code session in the project.
2. Ask: "What test command does this project use?" — the answer should match what's documented in `AGENTS.md`'s Setup Commands section, not be missing or wrong.
3. If the import isn't resolving, fall back to the symlink method instead:
   ```bash
   rm CLAUDE.md
   ln -s AGENTS.md CLAUDE.md
   ```
   This guarantees identical content by making both filenames point to the same file on disk, at the cost of not being able to add any Claude-only addendum.

---

## What Goes Wrong Without This Structure

A CLAUDE.md written independently of AGENTS.md, even with the best intentions, drifts. Someone updates the test command in AGENTS.md for the whole team and forgets CLAUDE.md exists as a separate file with the old command still in it. Claude Code, which always prioritizes CLAUDE.md when present, keeps running the stale command indefinitely, silently, with no error — it has no way to know a supposedly-equivalent file elsewhere disagrees with the one it's actually loading.

The import shim structurally prevents this: there is no second copy of the shared content to go stale, only a pointer to the one copy that exists.
