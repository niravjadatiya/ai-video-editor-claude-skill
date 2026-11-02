#!/usr/bin/env bash
# Report which shots in videos/<name>/inputs/broll/SHOTLIST.md have a file yet.
# A shot counts as delivered when inputs/broll/<shot-id>.<any video/image ext> exists.
#
# Usage: scripts/broll-status.sh <video-name>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 1 ] || { sed -n 2,5p "$0"; exit 1; }
dir="$ROOT/videos/$1/inputs/broll"
list="$dir/SHOTLIST.md"
[ -f "$list" ] || { echo "No shot list: videos/$1/inputs/broll/SHOTLIST.md" >&2; exit 1; }

# Shot ids are the backticked first cell of each table row: | `b01-city-night` | ...
ids=$(grep -oE '^\| *`[a-z0-9-]+`' "$list" | grep -oE '[a-z0-9-]+' || true)
[ -n "$ids" ] || { echo "Shot list has no shot rows" >&2; exit 1; }

have=0; total=0; missing=()
for id in $ids; do
  total=$((total + 1))
  f=$(find "$dir" -maxdepth 1 -type f -iname "$id.*" ! -iname '*.md' | head -1)
  if [ -n "$f" ]; then
    have=$((have + 1))
    info=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
      -show_entries format=duration -of default=nw=1:nk=1 "$f" 2>/dev/null | paste -sd' ' -)
    need=$(grep -E "^\| *\`$id\`" "$list" | awk -F'|' '{gsub(/ /,"",$3); print $3}')
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null || true)
    warn=""
    if [[ "$need" =~ ^[0-9.]+$ && "$dur" =~ ^[0-9.]+$ ]] && awk "BEGIN{exit !($dur < $need)}"; then
      warn="  ⚠ shorter than the ${need}s needed"
    fi
    printf '  ✓ %-40s %s%s\n' "$(basename "$f")" "$info" "$warn"
  else
    missing+=("$id")
  fi
done
for id in "${missing[@]+"${missing[@]}"}"; do printf '  ✗ %s\n' "$id"; done
echo "B-roll: $have/$total delivered"

# Files dropped in with a name that matches no shot (likely a typo).
while IFS= read -r -d '' f; do
  stem=$(basename "${f%.*}")
  echo "$ids" | grep -qx "$stem" || echo "  ? unmatched file: $(basename "$f")"
done < <(find "$dir" -maxdepth 1 -type f ! -name '*.md' ! -name '.*' -print0)
