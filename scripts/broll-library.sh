#!/usr/bin/env bash
# Shared B-roll library in library/broll/, indexed in library/broll/INDEX.md so clips are
# reused across videos instead of regenerated.
#
# Usage:
#   scripts/broll-library.sh search <word>...              index rows matching ALL words
#   scripts/broll-library.sh use <video> <shot-id> <file>  copy a library clip in as that shot
#   scripts/broll-library.sh archive <video>               add the video's new delivered clips
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT/library/broll"
INDEX="$LIB/INDEX.md"
mkdir -p "$LIB"
[ -f "$INDEX" ] || printf '# B-roll library\n\n| File | Secs | Aspect | Description / prompt | First used in |\n| ---- | ---- | ------ | -------------------- | ------------- |\n' > "$INDEX"

usage() { sed -n 2,8p "$0"; exit 1; }
[ $# -ge 1 ] || usage
cmd="$1"; shift

aspect_of() {
  local wh w h
  wh=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$1" 2>/dev/null || true)
  w=${wh%x*}; h=${wh#*x}
  [[ "$w" =~ ^[0-9]+$ && "$h" =~ ^[0-9]+$ ]] || { echo "?"; return; }
  awk -v w="$w" -v h="$h" 'BEGIN{r=w/h; if (r>1.6&&r<1.9) print "16:9"; else if (r>0.5&&r<0.62) print "9:16"; else if (r>0.95&&r<1.05) print "1:1"; else if (r>0.75&&r<0.85) print "4:5"; else print w "x" h}'
}

case "$cmd" in
  search)
    [ $# -ge 1 ] || usage
    rows=$(grep -E '^\| `' "$INDEX" || true)
    for w in "$@"; do rows=$(echo "$rows" | grep -i -- "$w" || true); done
    [ -n "$rows" ] && echo "$rows" || echo "No library match for: $*"
    ;;

  use)
    [ $# -eq 3 ] || usage
    video="$1"; id="$2"; src="$LIB/$(basename "$3")"
    [ -f "$src" ] || { echo "Not in library: $3" >&2; exit 1; }
    dest="$ROOT/videos/$video/inputs/broll/$id.${src##*.}"
    cp "$src" "$dest"
    echo "Reused library/broll/$(basename "$src") as inputs/broll/$(basename "$dest")"
    ;;

  archive)
    [ $# -eq 1 ] || usage
    video="$1"; dir="$ROOT/videos/$video/inputs/broll"; list="$dir/SHOTLIST.md"
    [ -f "$list" ] || { echo "No shot list for $video" >&2; exit 1; }
    added=0
    while IFS= read -r row; do
      id=$(echo "$row" | grep -oE '`[a-z0-9-]+`' | head -1 | tr -d '`')
      f=$(find "$dir" -maxdepth 1 -type f -iname "$id.*" ! -iname '*.md' | head -1)
      [ -n "$f" ] || continue
      sum=$(md5 -q "$f")
      # Skip clips already in the library (e.g. ones brought in with `use`).
      dup=""
      for g in "$LIB"/*; do
        [ -f "$g" ] && [ "$(basename "$g")" != INDEX.md ] && [ "$(md5 -q "$g")" = "$sum" ] && { dup=1; break; }
      done
      [ -z "$dup" ] || continue
      slug=${id#b[0-9][0-9]-}; ext=$(echo "${f##*.}" | tr '[:upper:]' '[:lower:]')
      name="$slug.$ext"; n=2
      while [ -e "$LIB/$name" ]; do name="$slug-$n.$ext"; n=$((n + 1)); done
      cp "$f" "$LIB/$name"
      secs=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" | awk '{printf "%.1f", $1}')
      prompt=$(echo "$row" | awk -F'|' '{print $5}' | sed 's/^ *//; s/ *$//')
      printf '| `%s` | %s | %s | %s | %s |\n' "$name" "$secs" "$(aspect_of "$f")" "$prompt" "$video" >> "$INDEX"
      echo "  + library/broll/$name"
      added=$((added + 1))
    done < <(grep -E '^\| *`[a-z0-9-]+`' "$list")
    echo "Archived $added new clip(s) to library/broll"
    ;;

  *) usage ;;
esac
