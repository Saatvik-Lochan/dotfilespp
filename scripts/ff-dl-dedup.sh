#!/usr/bin/env bash
# ff-dl-dedup.sh
#
# Goal: When Firefox creates a renamed download like "file(1).ext" or "file (1).ext",
# move the existing "file.ext" aside to the next available "file(1).ext", "file(2).ext", ...
# and then rename the new download back to "file.ext".
#
# Safety properties (no deletion):
# - Never removes files (no rm).
# - Only uses mv on paths that exist.
# - Never overwrites an existing destination (computes a free name first).
# - If any required file is missing, it does nothing.
#
set -euo pipefail

DIR="${1:-${FF_DEDUP_DIR:-$HOME/Downloads}}"

# prevent running twice
LOCK="${XDG_RUNTIME_DIR:-/tmp}/ff-dl-dedup.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

next_free() {
  local base="$1" ext="$2" n=1 cand
  while :; do
    cand="${base}(${n})${ext}"
    [[ -e "$cand" ]] || { printf '%s\n' "$cand"; return 0; }
    ((n++))
  done
}

handle() {
  local path="$1"
  local name="${path##*/}"
  local dir="${path%/*}"

  # ignore firefox partials and hidden temp-ish files
  [[ "$name" == *.part ]] && return 0

  # Match these patterns (both with and without extension):
  #   foo(1).ext
  #   foo (1).ext
  #   foo(1)
  #   foo (1)
  # We only act on the *new* file that already has the (N) suffix.

  if [[ "$name" =~ ^(.*?)(\ \()([0-9]+)\)(\.[^./]+)?$ ]]; then
    local pre="${BASH_REMATCH[1]}"          # "foo"
    local ext="${BASH_REMATCH[4]:-}"       # ".ext" or ""

    local base="${dir}/${pre}${ext}"       # target canonical name "foo.ext"
    local new="${dir}/${name}"             # the just-downloaded file "foo (1).ext" (or foo(1).ext)

    # Must have both the new and base present; otherwise do nothing.
    [[ -e "$new" ]] || return 0
    [[ -e "$base" ]] || return 0

    # If base and new resolve to same path (shouldn't happen), do nothing.
    [[ "$new" != "$base" ]] || return 0

    # Move old base out of the way to a guaranteed-free numbered name.
    local moved
    moved="$(next_free "${dir}/${pre}" "$ext")"

    # Extra guard: never overwrite.
    [[ ! -e "$moved" ]] || return 0

    mv -- "$base" "$moved"
    mv -- "$new" "$base"
  fi
}

export -f handle next_free

command -v inotifywait >/dev/null 2>&1 || {
  echo "inotifywait not found. Install: inotify-tools" >&2
  exit 1
}

# Watch for completed files:
# - close_write: file closed after writing
# - moved_to: firefox often renames from .part to final name
inotifywait -m -e moved_to -e close_write --format '%w%f' "$DIR" |
while IFS= read -r f; do
  handle "$f" || true
done
