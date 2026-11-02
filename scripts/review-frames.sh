#!/usr/bin/env bash
# Snapshot chosen moments of a video's HyperFrames edit and tile them into ONE image, so the
# pre-render review costs one image read instead of one per frame.
#
# Usage: scripts/review-frames.sh <video-name> <t1,t2,...>     (seconds, up to 12, e.g. 1.5,6,12.2)
# Writes videos/<name>/analysis/review.jpg (frames left→right, top→bottom, in the given order).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 2 ] || { sed -n 2,6p "$0"; exit 1; }
proj="$ROOT/videos/$1/${VARIANT:-project}"
[ -f "$proj/index.html" ] || { echo "No HyperFrames project at videos/$1/${VARIANT:-project}" >&2; exit 1; }
n=$(echo "$2" | tr ',' '\n' | grep -c .)
[ "$n" -le 12 ] || { echo "Use at most 12 timestamps" >&2; exit 1; }
PLUGIN_CLI=$(ls -d "$HOME"/.claude/plugins/cache/hyperframes/hyperframes/*/skills/hyperframes/scripts/plugin-cli.mjs | sort -V | tail -1)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

(cd "$proj" && node "$PLUGIN_CLI" snapshot --at "$2" --no-end -o "$tmp/snaps" >/dev/null 2>&1) \
  || { echo "snapshot failed — run it directly to see the error" >&2; exit 1; }

i=0
for t in $(echo "$2" | tr ',' ' '); do
  f=$(ls "$tmp"/snaps/*.png | awk -v t="$t" -F/ '{ s=$NF; sub(/^at-/,"",s); sub(/s\.png$/,"",s); if (s+0 == t+0) print }' | head -1)
  [ -n "$f" ] || f=$(ls "$tmp"/snaps/*.png | sed -n "$((i + 1))p")
  ffmpeg -hide_banner -loglevel error -y -i "$f" -vf "scale=640:640:force_original_aspect_ratio=decrease,pad=640:640:(ow-iw)/2:(oh-ih)/2:color=black" "$tmp/$(printf '%02d' $i).png"
  i=$((i + 1))
done
cols=$(( i < 4 ? i : 4 )); rows=$(( (i + cols - 1) / cols ))
mkdir -p "$ROOT/videos/$1/analysis"
ffmpeg -hide_banner -loglevel error -y -framerate 1 -i "$tmp/%02d.png" -vf "tile=${cols}x${rows}:padding=4:color=white" -frames:v 1 -q:v 4 "$ROOT/videos/$1/analysis/review.jpg"
echo "videos/$1/analysis/review.jpg — frames at: $2"
