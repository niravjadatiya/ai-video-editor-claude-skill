#!/usr/bin/env bash
# Word-level Gujarati transcript in one run.
#   scripts/transcribe-gu.sh <video-name>
# Writes videos/<name>/project/transcript.json ([{text,start,end}]) and analysis/gu-lines.txt.
#
# Why not `hyperframes transcribe`: on Gujarati, whisper's temperature fallback fires and returns
# garbage ("??") or skips stretches, it's ~5x slower, and the CLI's transcript.json merges Gujarati
# into one word. The CLI can't pass flags, so this calls whisper-cli directly with -nf (no fallback).
# Gujarati is token-heavy: whisper stops at the per-window token cap after ~7s of speech, so audio
# is split at pauses into chunks of <= CHUNK_MAX s, all transcribed in ONE whisper-cli call.
#
# Env: WHISPER_MODEL  name in ~/.cache/hyperframes/whisper/models (default large-v3) or a .bin path
#      CHUNK_MAX (s, default 6)  SIL_DB (default -28)  SIL_D (default 0.1)  KEEP_TMP=1 keeps temp files
set -euo pipefail
name="${1:?usage: scripts/transcribe-gu.sh <video-name>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
V="$ROOT/videos/$name"
MODEL="${WHISPER_MODEL:-large-v3}"
CHUNK_MAX="${CHUNK_MAX:-6}"
SIL_DB="${SIL_DB:--28}"
SIL_D="${SIL_D:-0.1}"
case "$MODEL" in */*) MPATH="$MODEL" ;; *) MPATH="$HOME/.cache/hyperframes/whisper/models/ggml-$MODEL.bin" ;; esac
[ -f "$MPATH" ] || { echo "model not found: $MPATH (download: https://huggingface.co/ggerganov/whisper.cpp)" >&2; exit 1; }

src="$(find "$V/inputs/footage" -maxdepth 1 -type f ! -name '.*' | sort | head -1)"
[ -n "$src" ] || { echo "no footage in $V/inputs/footage" >&2; exit 1; }
mkdir -p "$V/project" "$V/analysis"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/transcribe-gu.XXXXXX")"
[ -n "${KEEP_TMP:-}" ] && echo "tmp: $TMP" || trap 'rm -rf "$TMP"' EXIT
t0=$(date +%s)

# 1. 16 kHz mono wav
ffmpeg -nostdin -loglevel error -y -i "$src" -vn -ac 1 -ar 16000 "$TMP/full.wav"
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/full.wav")

# 2. Cut points = middle of each pause; greedily merge into chunks of <= CHUNK_MAX seconds.
ffmpeg -nostdin -hide_banner -i "$TMP/full.wav" -af "silencedetect=noise=${SIL_DB}dB:d=${SIL_D}" -f null - 2>&1 |
  awk -v dur="$dur" -v max="$CHUNK_MAX" '
    /silence_start/ { s=$NF }
    /silence_end/   { e=$5; m=(s+e)/2; if (m>0.3 && m<dur-0.3) cut[n++]=m }
    END {
      start=0; last=0
      for (i=0;i<n;i++) {
        if (cut[i]-start > max && last>start) { print start, last; start=last }
        last=cut[i]
      }
      if (dur-start > max && last>start) { print start, last; start=last }
      print start, dur
    }' > "$TMP/chunks.txt"

files=(); i=0
while read -r cs ce; do
  i=$((i+1))
  ffmpeg -nostdin -loglevel error -y -ss "$cs" -to "$ce" -i "$TMP/full.wav" -c copy "$TMP/c$i.wav"
  files+=(-f "$TMP/c$i.wav")
done < "$TMP/chunks.txt"
echo "chunks: $i ($(awk '{printf "%s%.1f", (NR>1?" ":""), $2-$1}' "$TMP/chunks.txt") s)"

# 3. One whisper-cli run (model loads once, Metal GPU): no fallback, one segment per word.
whisper-cli -m "$MPATH" -l gu -nf -ml 1 -sow -oj -np "${files[@]}" > "$TMP/whisper.log" 2>&1 ||
  { tail -5 "$TMP/whisper.log" >&2; exit 1; }

# 4. Merge chunk words (offset by chunk start) -> project/transcript.json (previous kept as .prev).
out="$V/project/transcript.json"
[ -f "$out" ] && cp "$out" "$V/project/transcript.prev.json"
rm -f "$V/project/transcript.gu.json"   # stale Gujlish backup would shadow the new transcript
node - "$TMP" "$out" <<'EOF'
const fs = require("fs");
const [tmp, out] = process.argv.slice(2);
const chunks = fs.readFileSync(`${tmp}/chunks.txt`, "utf8").trim().split("\n").map((l) => l.split(" ").map(Number));
const all = [];
chunks.forEach(([cs, ce], i) => {
  const segs = JSON.parse(fs.readFileSync(`${tmp}/c${i + 1}.wav.json`, "utf8")).transcription;
  const r = (ms) => Math.round(cs * 1000 + ms) / 1000;
  const words = segs.filter((s) => s.text.trim());
  if (words.at(-1)?.text.includes("�"))
    console.error(`warn: chunk ${i + 1} (${cs}-${ce}s) hit the token cap; lower CHUNK_MAX`);
  for (const s of words) {
    const start = r(s.offsets.from);
    // partial UTF-8, punctuation-only, or stamped past the chunk end (hallucinated tail)
    if (s.text.includes("�") || !/[\p{L}\p{N}]/u.test(s.text) || start >= ce - 0.02) continue;
    all.push({ text: s.text.trim(), start, end: Math.min(r(s.offsets.to), ce) });
  }
});
fs.writeFileSync(out, JSON.stringify(all, null, 1) + "\n");
console.log(`words: ${all.length}  span: ${all[0]?.start ?? "-"}–${all.at(-1)?.end ?? "-"}s`);
EOF

# 5. Gujarati phrase lines for the one-time Gujlish conversion.
( cd "$V" && node "$ROOT/scripts/gujlish.mjs" export project/transcript.json analysis/gu-lines.txt ) | tail -1
echo "model: $(basename "$MPATH")  time: $(( $(date +%s) - t0 ))s  -> ${out#$ROOT/}"
