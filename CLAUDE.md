# HyperFrames video workspace

Videos are made with the HyperFrames Claude Code plugin (`hyperframes@hyperframes`).
Route every make/edit/render request through `/hyperframes:hyperframes`.

- **Plugin install:** never run `hyperframes skills update` / `npx skills add`. Run the CLI as
  `node "<PLUGIN_ROOT>/skills/hyperframes/scripts/plugin-cli.mjs" <cmd>` from the video's `project/`
  (PLUGIN_ROOT = `~/.claude/plugins/cache/hyperframes/hyperframes/<version>`).
- **Intake:** `/new-video <name> <files…>` → `scripts/new-video.sh` copies raw files into
  `videos/<name>/inputs/{footage,references,broll,images,audio,docs}` and prints an inventory.
- **Any edit or build:** follow `.claude/editing-principles.md` (cheap analysis via
  `scripts/analyze-media.sh`, reusable reference styles in `library/styles/`, one-image review via
  `scripts/review-frames.sh`).
- **Layout:** `videos/<name>/inputs/` = originals (read-only). `videos/<name>/project/` = HyperFrames
  project, scaffolded by the workflow; stage media into `project/assets/`, renders land in
  `project/renders/`. `library/{brand,fonts,music,sfx,luts,broll}` = shared across videos.
- Reference videos are for style/pacing only; never put their footage in the output.
- **Language:** default is Gujarati (often mixed with English) unless the user says a video is in
  another language; then use that language and normal captions in it. Transcribe Gujarati ONLY with
  `scripts/transcribe-gu.sh <name>` (~100s per 40s, large-v3 on Metal) — never `hyperframes
  transcribe` for Gujarati (its whisper fallback returns "??"/skips speech and it merges words); it
  writes `project/transcript.json` and runs the gu-lines export below. Skip the caption workflow's own
  transcribe step. Captions are **Gujlish**: Gujarati in natural
  Latin spelling, English words in English. Right after transcription, convert ONCE:
  `node scripts/gujlish.mjs export <transcript.json> analysis/gu-lines.txt` (done by the script) → write
  `analysis/gujlish-lines.txt` (same lines, same word count per line) → `node scripts/gujlish.mjs apply
  <transcript.json> analysis/gujlish-lines.txt`. Timings are kept; everything downstream reads Gujlish.
  Never re-read the Gujarati text after that.
- **Text behind the person:** `/embedded-captions` (local subject matting, ~2–3 min CPU per 10s of
  1080p). Default to its rail + 1–2 embedded hero words; full cinematic only if asked (more tokens).
  Single-subject talking head, face visible; split multi-shot footage first.
- **B-roll:** shot list first, build after. Follow `.claude/commands/broll-plan.md`: reuse
  `library/broll/` (search `scripts/broll-library.sh search …`) before asking for new clips; the user
  generates the rest from `inputs/broll/SHOTLIST.md` and says "broll done". Then
  `scripts/broll-status.sh <name>` → `scripts/broll-library.sh archive <name>` → build. Stage clips
  into `project/assets/broll/`; trim/scale in the composition (`data-media-start`, object-fit), no re-encode.
- **Local tools:** voice = Kokoro via `hyperframes tts` (HYPERFRAMES_PYTHON set in
  `.claude/settings.json`); transcription = whisper-cpp. No HeyGen sign-in, no MusicGen, no Docker:
  use `library/music` / `library/sfx` for audio and ask before any paid or sign-in service.
  SFX: `library/sfx/INDEX.md` (rebuild with `node scripts/sfx-index.mjs` after the user adds files);
  placement rules in `.claude/editing-principles.md`.

## Token budget (the user pays per use — keep it lean)

- Trust the intake inventory; don't re-probe media or `cat` large files. Use
  `hyperframes timeline --json` instead of reading every composition file.
- Pipe noisy CLI output through `tail`/`grep` (render progress, npm notices).
- Don't run `snapshot`/`check` after every tiny edit — batch edits, check once, render once.
  Let the user review in Studio `preview` (free, no tokens) before rendering; drafts use `render -q draft`.
- Don't spawn subagents/parallel workers unless the user asks. Keep replies short.
