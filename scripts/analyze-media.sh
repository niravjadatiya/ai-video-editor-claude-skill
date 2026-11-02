#!/usr/bin/env bash
# Cheap, local pre-analysis of a video's footage and reference videos, so the agent reads one
# small text report + one contact-sheet image per file instead of inspecting raw video.
#
# Usage: scripts/analyze-media.sh <video-name> [--no-transcribe]
#
# Writes videos/<name>/analysis/:
#   REPORT.md                    duration, resolution, fps, audio, cuts, pacing per file
#   <file>.sheet.jpg             12 evenly spaced frames, 4x3 grid, left→right, top→bottom
#   <file>.srt                   transcript of reference videos with speech (local whisper large-v3, language auto-detected)
# Reference videos already analyzed for an earlier video (same file content) are reported as
# "known style: library/styles/<file>.md" and skipped.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 1 ] || { sed -n 2,13p "$0"; exit 1; }
name="$1"; transcribe=1
[ "${2:-}" = "--no-transcribe" ] && transcribe=0
vdir="$ROOT/videos/$name"
[ -d "$vdir/inputs" ] || { echo "No such video: videos/$name" >&2; exit 1; }
out="$vdir/analysis"; mkdir -p "$out" "$ROOT/library/styles"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
PLUGIN_CLI=$(ls -d "$HOME"/.claude/plugins/cache/hyperframes/hyperframes/*/skills/hyperframes/scripts/plugin-cli.mjs 2>/dev/null | sort -V | tail -1)

report="$out/REPORT.md"
echo "# Media analysis — $name" > "$report"
echo "Contact sheets: 12 frames, 4x3, read left→right, top→bottom, evenly spaced over the clip." >> "$report"

fmt() { awk -v s="$1" 'BEGIN{printf "%d:%04.1f", s/60, s-int(s/60)*60}'; }

analyze() {
  local f="$1" role="$2" base dur wh fps audio cuts n i t
  base=$(basename "$f")
  if [ "$role" = reference ]; then
    local key; key=$(md5 -q "$f" | cut -c1-10)
    local known; known=$(ls "$ROOT"/library/styles/*-"$key".md 2>/dev/null | head -1 || true)
    if [ -n "$known" ]; then
      printf '\n## %s (reference)\nknown style: library/styles/%s — reuse it, no re-analysis needed\n' "$base" "$(basename "$known")" >> "$report"
      return
    fi
  fi

  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  wh=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$f")
  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of csv=p=0 "$f" | awk -F/ '{ if ($2>0) printf "%.2f", $1/$2; else print $1 }')
  audio=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$f" | head -1)

  # Hard cuts via scene-change detection on a downscaled copy (fast).
  cuts=$(ffmpeg -hide_banner -nostats -i "$f" -an -vf "scale=320:-2,scdet=threshold=12" -f null - 2>&1 \
    | grep -oE 'lavfi\.scd\.time: [0-9.]+' | awk '{print $2}' || true)
  n=$(echo "$cuts" | grep -c . || true)

  {
    printf '\n## %s (%s)\n' "$base" "$role"
    if [ "$role" = reference ]; then
      local slug; slug=$(echo "${base%.*}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')
      printf -- '- save style notes as: library/styles/%s-%s.md\n' "$slug" "$key"
    fi
    printf -- '- %s · %s · %s fps · audio: %s\n' "$(fmt "$dur")" "$wh" "$fps" "${audio:-none}"
    if [ "$n" -gt 0 ]; then
      awk -v d="$dur" -v n="$n" 'BEGIN{printf "- %d cuts · %.1f cuts/min · avg shot %.1fs\n", n, n/(d/60), d/(n+1)}'
      # Shot lengths, to see rhythm (e.g. fast open, slower middle).
      printf -- '- cut times (s): %s\n' "$(echo "$cuts" | awk '{printf "%s%.1f", (NR>1?", ":""), $1}' | cut -c1-600)"
    else
      echo "- no hard cuts detected (single shot or soft transitions)"
    fi
  } >> "$report"

  # Contact sheet: 12 evenly spaced frames.
  local tiles="$tmp/${base}_tiles"; mkdir -p "$tiles"; local times=()
  for i in $(seq 0 11); do
    t=$(awk -v d="$dur" -v i="$i" 'BEGIN{printf "%.2f", d*(i+0.5)/12}')
    times+=("$(fmt "$t")")
    ffmpeg -hide_banner -loglevel error -ss "$t" -i "$f" -frames:v 1 -vf "scale=400:400:force_original_aspect_ratio=decrease,pad=400:400:(ow-iw)/2:(oh-ih)/2:color=black" \
      "$tiles/$(printf '%02d' "$i").png" -y
  done
  ffmpeg -hide_banner -loglevel error -y -framerate 1 -i "$tiles/%02d.png" -vf "tile=4x3:padding=4:color=white" -frames:v 1 -q:v 4 "$out/$base.sheet.jpg"
  printf -- '- sheet: analysis/%s.sheet.jpg (times: %s)\n' "$base" "${times[*]}" >> "$report"

  # Transcript for references with speech; the build workflow transcribes footage itself.
  if [ "$role" = reference ] && [ -n "$audio" ] && [ "$transcribe" = 1 ] && [ -n "$PLUGIN_CLI" ]; then
    if (cd "$tmp" && node "$PLUGIN_CLI" transcribe "$f" --dir "$tmp" -m large-v3 --to srt -o "$out/$base.srt" --optional >/dev/null 2>&1) && [ -s "$out/$base.srt" ]; then
      printf -- '- transcript: analysis/%s.srt (%s words)\n' "$base" "$(grep -vE '^[0-9]+$|-->|^$' "$out/$base.srt" | wc -w | tr -d ' ')" >> "$report"
    else
      echo "- transcript: none (no speech found or transcription unavailable)" >> "$report"
    fi
  fi
}

found=0
for role in references footage; do
  while IFS= read -r -d '' f; do
    found=1; analyze "$f" "${role%s}"
  done < <(find "$vdir/inputs/$role" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.mkv' -o -iname '*.webm' \) -print0 | sort -z)
done
[ "$found" = 1 ] || echo "No videos in inputs/references or inputs/footage" >> "$report"
cat "$report"
