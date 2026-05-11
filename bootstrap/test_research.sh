#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

assert_file() {
  if [ ! -f "$1" ]; then
    echo "Expected file: $1" >&2
    exit 1
  fi
}

assert_dir() {
  if [ ! -d "$1" ]; then
    echo "Expected directory: $1" >&2
    exit 1
  fi
}

assert_contains() {
  file=$1
  text=$2
  if ! grep -F "$text" "$file" >/dev/null 2>&1; then
    echo "Expected '$text' in $file" >&2
    exit 1
  fi
}

assert_no_red_flags() {
  out=$(mktemp)
  if grep -R -E 'T[B]D|T[O]DO|F[I]XME|\?\?' "$repo_root/research" >"$out" 2>/dev/null; then
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  rm -f "$out"
}

assert_file "$repo_root/research/README.md"
assert_file "$repo_root/research/index.md"
assert_file "$repo_root/research/templates/repo-note.md"
assert_file "$repo_root/research/templates/paper-note.md"

for dir in \
  "$repo_root/research/repos" \
  "$repo_root/research/repos/skills-instructions" \
  "$repo_root/research/repos/mcp" \
  "$repo_root/research/repos/harness-eval" \
  "$repo_root/research/repos/agent-support-systems" \
  "$repo_root/research/papers" \
  "$repo_root/research/papers/token-efficiency" \
  "$repo_root/research/papers/context-control" \
  "$repo_root/research/papers/memory" \
  "$repo_root/research/papers/subagents-multiagents" \
  "$repo_root/research/papers/tool-use" \
  "$repo_root/research/papers/ai-coding-workflow" \
  "$repo_root/research/papers/error-prevention" \
  "$repo_root/research/papers/domain-specific-coding" \
  "$repo_root/research/synthesis"
do
  assert_dir "$dir"
  assert_file "$dir/README.md"
done

assert_contains "$repo_root/research/index.md" "| Type | Category | Topic | Repository | Paper | URL | Stars snapshot | Citations snapshot | Captured at | Scope fit | Status | Note path | Short reason |"
assert_contains "$repo_root/research/templates/repo-note.md" "## Core Execution Path"
assert_contains "$repo_root/research/templates/repo-note.md" "## Reviewed Paths"
assert_contains "$repo_root/research/templates/paper-note.md" "## Evidence"
assert_contains "$repo_root/research/templates/paper-note.md" "## Reviewed Sources"
assert_contains "$repo_root/research/README.md" "Repository discovery categories"
assert_contains "$repo_root/research/README.md" "Paper discovery topics"

assert_no_red_flags
