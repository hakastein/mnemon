#!/usr/bin/env bash
#
# bump-version.sh — keep the version string in sync across every manifest.
#
# Mnemon declares its version in more than one manifest. This script is the
# single source of truth for changing it and for verifying the manifests agree.
#
# Usage:
#   ./scripts/bump-version.sh --check     # verify all manifests agree (CI)
#   ./scripts/bump-version.sh X.Y.Z       # set the version everywhere
#
# Requires: jq
set -euo pipefail

cd "$(dirname "$0")/.."

# The .claude-plugin manifest is the canonical source; every file here must match it.
CANONICAL=".claude-plugin/plugin.json"
VERSIONED_FILES=(
  ".claude-plugin/plugin.json"
  ".codex-plugin/plugin.json"
)

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 2; }

read_version() { jq -r '.version' "$1"; }

canonical_version="$(read_version "$CANONICAL")"

check() {
  local ok=0
  echo "Canonical version ($CANONICAL): $canonical_version"
  for f in "${VERSIONED_FILES[@]}"; do
    local v
    v="$(read_version "$f")"
    if [ "$v" != "$canonical_version" ]; then
      echo "  DRIFT: $f = $v" >&2
      ok=1
    else
      echo "  ok:    $f = $v"
    fi
  done
  if [ "$ok" -ne 0 ]; then
    echo "Version drift detected. Run: ./scripts/bump-version.sh $canonical_version" >&2
    exit 1
  fi
  echo "All manifests agree."
}

bump() {
  local new="$1"
  if ! printf '%s' "$new" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "error: '$new' is not a valid X.Y.Z semver" >&2
    exit 2
  fi
  for f in "${VERSIONED_FILES[@]}"; do
    local tmp
    tmp="$(mktemp)"
    jq --arg v "$new" '.version = $v' "$f" > "$tmp"
    mv "$tmp" "$f"
    echo "set $f -> $new"
  done
  echo
  echo "Next: move CHANGELOG.md '## Unreleased' under '## $new — <date>' and commit."
}

case "${1:-}" in
  --check) check ;;
  "" | -h | --help)
    grep -E '^#( |$)' "$0" | sed -E 's/^# ?//'
    ;;
  *) bump "$1" ;;
esac
