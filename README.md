# agents-md-architect

A Claude Code skill that generates and maintains a project's AI agent instruction file, and tells you the truth about a change most people have wrong.

**The correction:** Claude Code did not switch from CLAUDE.md to AGENTS.md. Version 2.1.277 (September 18, 2026) added AGENTS.md as a fallback: if no CLAUDE.md exists anywhere in the directory walk from the repository root to your working directory, Claude Code reads AGENTS.md instead. If a CLAUDE.md exists, it still wins, unconditionally, with zero change in behavior.

**Why that distinction matters:** AGENTS.md is a real cross-tool standard, not a Claude Code feature. OpenAI released it in August 2025, contributed it to the Linux Foundation's Agentic AI Foundation, and by the time Claude Code caught up, over 60,000 open-source projects had already adopted it, read natively by Codex, Cursor, Devin, Gemini CLI, GitHub Copilot, Windsurf, Cline, Amp, and Aider. A repository with a CLAUDE.md is invisible to every one of those other tools. A repository with both files, maintained independently, drifts: one documented failure mode has Codex following one test command and Claude following a different one from a stale, disagreeing file.

This skill fixes the structural problem, not just the symptom. It detects exactly which file Claude Code is actually loading given the real walk rule (including the parts most people get wrong), generates a tool-agnostic AGENTS.md with real architectural content, and eliminates the drift by making AGENTS.md the single source of truth.

---

## Install

```bash
# Via npx
npx skills add sowadalmughni/agents-md-architect

# Via Claude Code marketplace
/plugin marketplace add sowadalmughni/agents-md-architect
/plugin install agents-md-architect@sowadalmughni

# Manually — personal (follows you across projects)
mkdir -p ~/.claude/skills
git clone https://github.com/sowadalmughni/agents-md-architect.git ~/.claude/skills/agents-md-architect

# Manually — project-level
mkdir -p .claude/skills
git clone https://github.com/sowadalmughni/agents-md-architect.git .claude/skills/agents-md-architect
```

---

## Quick Start

**Find out which file Claude Code is actually loading right now:**

```bash
bash .claude/skills/agents-md-architect/scripts/detect-instruction-files.sh .
```

This walks from your repository root to your working directory, exactly the way Claude Code does, and gives you a verdict:

```text
VERDICT
  Claude Code loads: CLAUDE.md

  🔴 DRIFT RISK — AGENTS.md ALSO EXISTS AND IS BEING IGNORED BY CLAUDE CODE

  Found AGENTS.md at:
    - /repo/AGENTS.md

  Every other agent that reads this repo (Codex, Cursor, Copilot, Gemini CLI,
  Windsurf, Cline, Amp, Aider) is following AGENTS.md. Claude Code is
  following the CLAUDE.md above instead.
```

Or invoke via Claude:
> *"Set up agent instructions for this project"*
> *"Generate a CLAUDE.md" / "Generate an AGENTS.md"*
> *"Why is Claude Code doing something different than Cursor on this repo?"*
> *"Migrate this project from CLAUDE.md to AGENTS.md"*

---

## What Gets Detected

The script implements the exact rule Claude Code uses, including the two nuances almost everyone gets wrong:

| Counts toward the walk (blocks AGENTS.md fallback) | Does NOT count (fallback still works) |
| --- | --- |
| `CLAUDE.md` at any level from root to working directory | Your personal `~/.claude/CLAUDE.md` |
| `.claude/CLAUDE.md` at any level | An organization-managed instruction file |
| `CLAUDE.local.md` at any level | A `.claude/rules` file |
| — | A CLAUDE.md belonging to an added directory |

A developer can have a personal global CLAUDE.md and still get AGENTS.md loaded correctly for a given project. A stray CLAUDE.md two directories up in a monorepo still silently overrides AGENTS.md for every subdirectory beneath it. The detector shows you which is actually true for your repo instead of leaving it to assumption.

---

## What's Included

```text
agents-md-architect/
├── .claude-plugin/
│   ├── plugin.json                       ← Plugin manifest, for /plugin install
│   └── marketplace.json                  ← Marketplace manifest, for /plugin marketplace add
├── SKILL.md                              ← 4 invocation modes, the corrected fallback rule stated up front
├── README.md                             ← This file
├── CHANGELOG.md
├── LICENSE                                ← MIT
├── reference/
│   └── agents-md-vs-claude-md.md         ← Full timeline, exact walk rule, import/symlink methods, platform notes
├── templates/
│   ├── agents-md-base.md                 ← Cross-tool file with module boundaries + data flow rules, not just commands
│   └── claude-md-import-shim.md          ← Thin @AGENTS.md import for teams needing Claude-specific extensions
└── scripts/
    └── detect-instruction-files.sh       ← Walks root-to-cwd, states the real verdict, diffs on drift
```

---

## The Differentiator

Most AGENTS.md files in the wild are setup-command lists — install steps, test runners, lint commands. Necessary, but shallow. `templates/agents-md-base.md` goes further: module boundaries an agent must not cross, the data flow it must trace before writing a route or a query, and the dependency direction that prevents the disconnected-schema, unwired-integration failure mode common in AI-generated codebases. Because AGENTS.md is read by every major coding agent now, this closes the context-blind generation gap for the whole multi-agent team a project actually uses, not one vendor's tool.

---

## Related Skills

Part of the Kitalon Labs AI engineering skill collection:

| Skill | Focus |
| --- | --- |
| **agents-md-architect** | Cross-tool instruction file architecture, drift detection |
| [spec-driven-dev](https://github.com/sowadalmughni/spec-driven-dev) | Architecture approval before code generation |
| [ai-codebase-audit](https://github.com/sowadalmughni/ai-codebase-audit) | Full six-failure-mode project audit |
| [vibe-debt-scanner](https://github.com/sowadalmughni/vibe-debt-scanner) | Module-level code quality debt score |
| [rls-security-check](https://github.com/sowadalmughni/rls-security-check) | Row Level Security specialist |
| [finops-guardian](https://github.com/sowadalmughni/finops-guardian) | Infrastructure cost curve classification |

---

## About

Built by **Md. Sowad Al-Mughni** — founder of [Kitalon Labs](https://www.kitalonlabs.com), an AI-native product studio.

- Website: [www.kitalonlabs.com](https://www.kitalonlabs.com)
- GitHub: [github.com/sowadalmughni](https://github.com/sowadalmughni)

---

## License

MIT — use freely, attribution appreciated.
