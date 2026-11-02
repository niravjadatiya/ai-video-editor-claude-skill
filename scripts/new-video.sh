#!/usr/bin/env bash
# Create (or add files to) a video folder and sort raw files into inputs/.
#
# Usage:
#   scripts/new-video.sh <video-name> [--move] [--as <kind>] <file|folder>... [--as <kind>] <file>...
#
#   <kind>: footage | references | broll | images | audio | docs | auto (default)
#   auto  : video -> footage, image -> images, audio -> audio, everything else -> docs
#   --move: move files instead of copying (saves disk space for big footage)
#
# Prints a compact summary (with duration / resolution for media) so the agent
# does not need to probe each file again.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 1 ] || { sed -n 2,13p "$0"; exit 1; }

name="$1"; shift
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "Video name may only use letters, digits, . _ -" >&2; exit 1; }
dir="$ROOT/videos/$name"
[ -d "$dir" ] || cp -R "$ROOT/videos/_template" "$dir"

kind=auto
op=cp
added=()

auto_kind() {
  case "$(echo "${1##*.}" | tr '[:upper:]' '[:lower:]')" in
    mp4|mov|m4v|mkv|webm|avi|mts|mxf) echo footage ;;
    jpg|jpeg|png|webp|gif|heic|svg|tif|tiff|bmp) echo images ;;
    mp3|wav|m4a|aac|flac|ogg|aif|aiff) echo audio ;;
    *) echo docs ;;
  esac
}

place() {
  local src="$1" k="$kind"
  [ "$k" = auto ] && k="$(auto_kind "$src")"
  local dest="$dir/inputs/$k/$(basename "$src")"
  if [ -e "$dest" ]; then
    echo "skip (already exists): inputs/$k/$(basename "$src")" >&2
    return
  fi
  $op "$src" "$dest"
  added+=("$k/$(basename "$src")")
}

while [ $# -gt 0 ]; do
  case "$1" in
    --as) kind="$2"; shift 2
      case "$kind" in footage|references|broll|images|audio|docs|auto) ;; *) echo "Unknown kind: $kind" >&2; exit 1 ;; esac ;;
    --move) op=mv; shift ;;
    *)
      src="${1/#\~/$HOME}"; shift
      if [ -d "$src" ]; then
        while IFS= read -r -d '' f; do place "$f"; done < <(find "$src" -type f ! -name '.*' -print0)
      elif [ -f "$src" ]; then
        place "$src"
      else
        echo "Not found: $src" >&2; exit 1
      fi ;;
  esac
done

echo "Video folder: videos/$name"
echo "Added ${#added[@]} file(s):"
for rel in "${added[@]+"${added[@]}"}"; do
  f="$dir/inputs/$rel"
  info=""
  case "$rel" in
    footage/*|references/*|broll/*|audio/*)
      info="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate \
        -show_entries format=duration -of default=nw=1:nk=1 "$f" 2>/dev/null | paste -sd' ' -)" ;;
  esac
  printf '  %-60s %8s  %s\n' "inputs/$rel" "$(du -h "$f" | cut -f1)" "$info"
done
[ -d "$dir/project" ] && echo "HyperFrames project already exists: videos/$name/project" || true
