#!/usr/bin/env bash
# =============================================================================
# AGENTS.md Architect — Instruction File Detector
# Md. Sowad Al-Mughni | Kitalon Labs | www.kitalonlabs.com
# https://github.com/sowadalmughni/agents-md-architect
#
# USAGE:  bash scripts/detect-instruction-files.sh [working-directory]
#
# Implements the rule Claude Code v2.1.277+ uses to decide between CLAUDE.md
# and AGENTS.md: walk the working directory and every directory above it,
# looking for CLAUDE.md, .claude/CLAUDE.md, or CLAUDE.local.md at each level.
# If any exist, AGENTS.md is never consulted, regardless of whether AGENTS.md
# is also present. This script does NOT check for a personal ~/.claude/CLAUDE.md
# or an org-managed file, because those do not count toward the walk either,
# per Anthropic's documented behavior.
#
# NOTE ON THE WALK BOUNDARY: Anthropic's own docs never state explicitly
# whether the walk stops at the git repository root or continues to the
# filesystem root — the documented wording is just "working directory and
# every directory above it." This script uses the git repository root as its
# boundary, matching how every example in Anthropic's docs is framed and how
# instruction files are used in practice. It will NOT see a CLAUDE.md/AGENTS.md
# placed above your repo root, in a directory added via `--add-dir`, or in an
# unusual nested-repo layout. Treat the verdict below as accurate for the
# common case, not as a guarantee for every possible setup.
# =============================================================================

WORKDIR="${1:-$(pwd)}"
WORKDIR="$(cd "$WORKDIR" && pwd -P)"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  AGENTS.MD ARCHITECT — INSTRUCTION FILE DETECTOR"
echo "  https://github.com/sowadalmughni/agents-md-architect"
echo "═══════════════════════════════════════════════════"
echo "  Working directory: $WORKDIR"
echo "═══════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────
# 1. Find the repository root (git root, or filesystem root if no git).
#    See the walk-boundary note in the file header: this is this script's
#    practical scoping choice, not a directly confirmed platform limit.
# ─────────────────────────────────────────────────────
REPO_ROOT=$(git -C "$WORKDIR" rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "  Not inside a git repository — walking all the way to filesystem root."
  echo "  Outside a git repo there's no natural boundary to stop at, so this"
  echo "  walk is broader than the git-repo case above, not narrower."
  REPO_ROOT="/"
else
  # Normalize through the same cd+pwd -P pipeline as WORKDIR. Git and bash can
  # report the identical directory as different strings (e.g. a Windows short
  # 8.3 name vs. the long name, a C:/ prefix vs. /c/, or a symlinked path like
  # macOS's /tmp -> /private/tmp) — without this, the walk below would never
  # match REPO_ROOT and would silently fall through to the filesystem root.
  REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
fi

echo "  Repository root: $REPO_ROOT"
echo ""

# ─────────────────────────────────────────────────────
# 2. Walk from repo root down to working directory
# ─────────────────────────────────────────────────────
echo "── Walking root → working directory ─────────────"
echo ""

declare -a QUALIFYING_CLAUDE_FILES=()
declare -a AGENTS_FILES=()

# Build the list of directories from REPO_ROOT to WORKDIR
CURRENT="$WORKDIR"
declare -a WALK_DIRS=()
while true; do
  WALK_DIRS=("$CURRENT" "${WALK_DIRS[@]}")
  if [ "$CURRENT" = "$REPO_ROOT" ] || [ "$CURRENT" = "/" ]; then
    break
  fi
  CURRENT="$(dirname "$CURRENT")"
done

for dir in "${WALK_DIRS[@]}"; do
  echo "  Checking: $dir"

  if [ -f "$dir/CLAUDE.md" ]; then
    echo "    ⚠  Found: CLAUDE.md — QUALIFIES, blocks AGENTS.md fallback"
    QUALIFYING_CLAUDE_FILES+=("$dir/CLAUDE.md")
  fi

  if [ -f "$dir/.claude/CLAUDE.md" ]; then
    echo "    ⚠  Found: .claude/CLAUDE.md — QUALIFIES, blocks AGENTS.md fallback"
    QUALIFYING_CLAUDE_FILES+=("$dir/.claude/CLAUDE.md")
  fi

  if [ -f "$dir/CLAUDE.local.md" ]; then
    echo "    ⚠  Found: CLAUDE.local.md — QUALIFIES, blocks AGENTS.md fallback"
    QUALIFYING_CLAUDE_FILES+=("$dir/CLAUDE.local.md")
  fi

  if [ -f "$dir/AGENTS.md" ]; then
    echo "    ℹ  Found: AGENTS.md (read by Claude Code only if NO qualifying CLAUDE.md exists anywhere in this walk)"
    AGENTS_FILES+=("$dir/AGENTS.md")
  fi

  if [ -f "$dir/.claude/AGENTS.md" ]; then
    echo "    ℹ  Found: .claude/AGENTS.md (read by Claude Code only if NO qualifying CLAUDE.md exists anywhere in this walk)"
    AGENTS_FILES+=("$dir/.claude/AGENTS.md")
  fi
done

# ─────────────────────────────────────────────────────
# 3. Check non-qualifying locations, for user awareness only
# ─────────────────────────────────────────────────────
echo ""
echo "── Non-qualifying files (for awareness — these do NOT block the fallback) ──"
echo ""

if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  echo "  ℹ  Found: ~/.claude/CLAUDE.md (personal global file)"
  echo "     This does NOT count toward the walk. It does not block AGENTS.md"
  echo "     from being loaded for this project."
fi

if [ -d "$WORKDIR/.claude/rules" ]; then
  echo "  ℹ  Found: .claude/rules/"
  echo "     This does NOT count toward the walk either."
fi

# ─────────────────────────────────────────────────────
# 4. Verdict
# ─────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "  VERDICT"
echo "═══════════════════════════════════════════════════"
echo ""

if [ "${#QUALIFYING_CLAUDE_FILES[@]}" -gt 0 ]; then
  echo "  Claude Code loads: CLAUDE.md"
  echo ""
  echo "  Qualifying file(s) found in the walk:"
  for f in "${QUALIFYING_CLAUDE_FILES[@]}"; do
    echo "    - $f"
  done
  echo ""

  if [ "${#AGENTS_FILES[@]}" -gt 0 ]; then
    echo "  🔴 DRIFT RISK — AGENTS.md ALSO EXISTS AND IS BEING IGNORED BY CLAUDE CODE"
    echo ""
    echo "  Found AGENTS.md at:"
    for f in "${AGENTS_FILES[@]}"; do
      echo "    - $f"
    done
    echo ""
    echo "  Every other agent that reads this repo (Codex, Cursor, Copilot, Gemini CLI,"
    echo "  Windsurf, Cline, Amp, Aider) is following AGENTS.md. Claude Code is"
    echo "  following the CLAUDE.md above instead. If the two files disagree on"
    echo "  anything — test commands, module boundaries, conventions — different"
    echo "  agents on this project are silently operating under different rules."
    echo ""
    echo "  RECOMMENDED FIX:"
    echo "    1. Compare the two files below."
    echo "    2. Make AGENTS.md the single source of truth for all shared content."
    echo "    3. Replace CLAUDE.md with an import shim (see templates/claude-md-import-shim.md)"
    echo "       or delete it entirely if it has no Claude-specific content."
    echo ""

    # Attempt a content diff if exactly one of each qualifying file exists
    if [ "${#QUALIFYING_CLAUDE_FILES[@]}" -eq 1 ] && [ "${#AGENTS_FILES[@]}" -eq 1 ]; then
      echo "  ── Diff (CLAUDE.md vs AGENTS.md) ──────────────"
      diff -u "${QUALIFYING_CLAUDE_FILES[0]}" "${AGENTS_FILES[0]}" 2>/dev/null | head -60
      echo ""
      echo "  (Showing first 60 lines of diff. Content differences above are exactly"
      echo "  what different agents on this project are currently disagreeing about.)"
    fi
  else
    echo "  No AGENTS.md found. No drift risk from this specific failure mode,"
    echo "  but this project is invisible to every non-Claude agent that expects"
    echo "  AGENTS.md. Consider running New Project Setup mode to generate one,"
    echo "  with CLAUDE.md converted to an import shim."
  fi

elif [ "${#AGENTS_FILES[@]}" -gt 0 ]; then
  echo "  Claude Code loads: AGENTS.md (via fallback, Claude Code v2.1.277+)"
  echo ""
  echo "  AGENTS.md found at:"
  for f in "${AGENTS_FILES[@]}"; do
    echo "    - $f"
  done
  echo ""
  echo "  🟢 No qualifying CLAUDE.md found in the walk. This project is on the"
  echo "  cross-tool standard and Claude Code is reading the same file every"
  echo "  other supported agent reads. No drift risk from this failure mode."
  echo ""
  echo "  Note: this assumes /config → Project instructions is set to the default"
  echo "  'claude-md-or-agents-md'. If it has been changed to 'claude-md', Claude"
  echo "  Code will NOT load this AGENTS.md despite the above."
  echo "  Also note: this fallback is not yet available on Bedrock, Vertex, or Foundry."

else
  echo "  No CLAUDE.md and no AGENTS.md found anywhere in the walk."
  echo ""
  echo "  🟡 This project has no instruction file for any AI coding agent."
  echo "  Run New Project Setup mode to generate one:"
  echo "    → see SKILL.md § Invocation Modes → New Project Setup"
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo ""
