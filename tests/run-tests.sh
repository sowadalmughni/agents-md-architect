#!/usr/bin/env bash
# =============================================================================
# agents-md-architect — Test Suite for scripts/detect-instruction-files.sh
# Md. Sowad Al-Mughni | Kitalon Labs | www.kitalonlabs.com
#
# USAGE:  bash tests/run-tests.sh
#
# Builds small, throwaway git repos in a temp directory to exercise every
# branch of scripts/detect-instruction-files.sh, then asserts the verdict
# output contains the expected marker text. Nothing here is committed as a
# static fixture — each case is constructed next to the assertion that
# depends on its exact shape, and the temp directory is removed on exit.
#
# Every HOME is overridden to an empty throwaway directory by default, so
# results don't depend on whatever the machine running this happens to have
# in its real ~/.claude/ — except case 9, which deliberately points HOME at
# a fake personal CLAUDE.md to test that it's correctly ignored.
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTOR="$SCRIPT_DIR/../scripts/detect-instruction-files.sh"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

EMPTY_HOME="$TMPROOT/empty-home"
mkdir -p "$EMPTY_HOME"

PASS=0
FAIL=0

assert_contains() {
  local name="$1" output="$2" expected="$3"
  if printf '%s' "$output" | grep -qF "$expected"; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name"
    echo "        expected to find: $expected"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local name="$1" output="$2" unexpected="$3"
  if printf '%s' "$output" | grep -qF "$unexpected"; then
    echo "  FAIL: $name"
    echo "        expected NOT to find: $unexpected"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  fi
}

new_fixture() {
  local dir="$TMPROOT/$1"
  mkdir -p "$dir"
  git init -q "$dir"
  # Normalize the same way the detector does internally (cd + pwd -P), so
  # assertions compare against the same physical-path form the script
  # actually reports — some environments (this repo's own Git Bash /tmp,
  # macOS's /tmp -> /private/tmp) mount a logical path over a different
  # physical one.
  (cd "$dir" && pwd -P)
}

run_detector() {
  local dir="$1" home="${2:-$EMPTY_HOME}"
  HOME="$home" bash "$DETECTOR" "$dir"
}

echo "═══════════════════════════════════════════════════"
echo "  agents-md-architect — detect-instruction-files.sh tests"
echo "═══════════════════════════════════════════════════"
echo ""

echo "Case 1: no instruction files"
dir=$(new_fixture "case1-none")
out=$(run_detector "$dir")
assert_contains "no files -> correct verdict" "$out" "No CLAUDE.md and no AGENTS.md found"

echo "Case 2: CLAUDE.md only"
dir=$(new_fixture "case2-claude-only")
echo "# CLAUDE.md" > "$dir/CLAUDE.md"
out=$(run_detector "$dir")
assert_contains "CLAUDE.md only -> loads CLAUDE.md" "$out" "Claude Code loads: CLAUDE.md"
assert_not_contains "CLAUDE.md only -> no drift risk" "$out" "DRIFT RISK"

echo "Case 3: AGENTS.md only"
dir=$(new_fixture "case3-agents-only")
echo "# AGENTS.md" > "$dir/AGENTS.md"
out=$(run_detector "$dir")
assert_contains "AGENTS.md only -> loads AGENTS.md via fallback" "$out" "Claude Code loads: AGENTS.md (via fallback"

echo "Case 4: CLAUDE.md and AGENTS.md both present, disagreeing (drift)"
dir=$(new_fixture "case4-drift")
echo "Run: npm test" > "$dir/CLAUDE.md"
echo "Run: pnpm test" > "$dir/AGENTS.md"
out=$(run_detector "$dir")
assert_contains "drift -> loads CLAUDE.md" "$out" "Claude Code loads: CLAUDE.md"
assert_contains "drift -> flags drift risk" "$out" "DRIFT RISK"
assert_contains "drift -> shows a diff" "$out" "Diff (CLAUDE.md vs AGENTS.md)"

echo "Case 5: .claude/CLAUDE.md only"
dir=$(new_fixture "case5-nested-claude")
mkdir -p "$dir/.claude"
echo "# nested CLAUDE.md" > "$dir/.claude/CLAUDE.md"
out=$(run_detector "$dir")
assert_contains "nested CLAUDE.md -> loads CLAUDE.md" "$out" "Claude Code loads: CLAUDE.md"
assert_contains "nested CLAUDE.md -> qualifying path shown" "$out" ".claude/CLAUDE.md"

echo "Case 6: .claude/AGENTS.md only (regression test — was previously undetected)"
dir=$(new_fixture "case6-nested-agents")
mkdir -p "$dir/.claude"
echo "# nested AGENTS.md" > "$dir/.claude/AGENTS.md"
out=$(run_detector "$dir")
assert_contains "nested AGENTS.md -> loads AGENTS.md via fallback" "$out" "Claude Code loads: AGENTS.md (via fallback"
assert_contains "nested AGENTS.md -> path shown" "$out" ".claude/AGENTS.md"

echo "Case 7: CLAUDE.local.md only"
dir=$(new_fixture "case7-local")
echo "# local overrides" > "$dir/CLAUDE.local.md"
out=$(run_detector "$dir")
assert_contains "CLAUDE.local.md -> loads CLAUDE.md" "$out" "Claude Code loads: CLAUDE.md"

echo "Case 8: .claude/rules/ as a real directory (regression test — was previously always false)"
dir=$(new_fixture "case8-rules-dir")
mkdir -p "$dir/.claude/rules"
echo "# some rule" > "$dir/.claude/rules/testing.md"
echo "# AGENTS.md" > "$dir/AGENTS.md"
out=$(run_detector "$dir")
assert_contains "rules dir -> detected as non-qualifying" "$out" "Found: .claude/rules/"
assert_contains "rules dir -> AGENTS.md still loads" "$out" "Claude Code loads: AGENTS.md (via fallback"

echo "Case 9: personal ~/.claude/CLAUDE.md does not block the fallback"
dir=$(new_fixture "case9-personal-home")
echo "# AGENTS.md" > "$dir/AGENTS.md"
fakehome="$TMPROOT/fake-home-case9"
mkdir -p "$fakehome/.claude"
echo "# personal global CLAUDE.md" > "$fakehome/.claude/CLAUDE.md"
out=$(run_detector "$dir" "$fakehome")
assert_contains "personal home file -> reported as informational" "$out" "Found: ~/.claude/CLAUDE.md"
assert_contains "personal home file -> does not block fallback" "$out" "Claude Code loads: AGENTS.md (via fallback"

echo "Case 10: walk from a nested subdirectory stops at repo root, not above it"
dir=$(new_fixture "case10-nested-workdir")
mkdir -p "$dir/a/b"
echo "# AGENTS.md" > "$dir/AGENTS.md"
out=$(run_detector "$dir/a/b")
assert_contains "nested workdir -> checks the repo root" "$out" "Checking: $dir"
assert_contains "nested workdir -> checks the intermediate dir" "$out" "Checking: $dir/a"
assert_contains "nested workdir -> checks the working directory itself" "$out" "Checking: $dir/a/b"
checking_lines=$(printf '%s\n' "$out" | grep -c '  Checking: ')
if [ "$checking_lines" -eq 3 ]; then
  echo "  PASS: nested workdir -> walks exactly 3 directories, not past repo root"
  PASS=$((PASS + 1))
else
  echo "  FAIL: nested workdir -> walks exactly 3 directories, not past repo root"
  echo "        expected 3 'Checking:' lines, got $checking_lines"
  FAIL=$((FAIL + 1))
fi
assert_contains "nested workdir -> still finds root AGENTS.md" "$out" "Claude Code loads: AGENTS.md (via fallback"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
