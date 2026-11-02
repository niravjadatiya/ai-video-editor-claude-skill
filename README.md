# AI Video Editor — Claude Code Skill

> Claude Code only. Requires the HyperFrames plugin (`hyperframes@hyperframes`). MIT licensed, contributions welcome.

A Claude Code workspace kit for making short talking-head reels with the
[HyperFrames](https://hyperframes.dev) plugin: footage intake, cheap media analysis, local Gujarati
transcription (whisper.cpp large-v3) with Gujlish captions, B-roll shot lists with a reusable library,
SFX placement rules, frame review, and house editing rules.

## Before → After (same 30s)

| Raw footage (phone clip) | Edited with this kit |
| :---: | :---: |
| <img src="docs/original.gif" width="240"> | <img src="docs/demo.gif" width="240"> |
| [▶ raw mp4](docs/original.mp4) | [▶ edited mp4 (sound)](docs/demo.mp4) |

Captions, title cards, B-roll, SFX and layout were all added by Claude using this kit.

## Why it's different (key features)

**1. Token-saving by design** — the agent never watches raw video.
- `analyze-media.sh` → one text `REPORT.md` + **one contact-sheet image per clip** (12 frames in a 4×3 grid) instead of dozens of frame reads.
- `review-frames.sh` → up to 12 key moments tiled into **one `review.jpg`** for pre-render QA (1 image read, not 12).
- Transcripts are exported to SRT once; the raw word-level JSON is never read.
- Studio preview is free, so you review there and render once. No subagents, short replies.

**2. Reference-reel styles** — drop in a reel you like; the kit writes a ≤25-line style note
(pacing, captions, typography, motion, transitions, SFX rhythm) to `library/styles/`. Reuse it on any
future video with `style: <name>` and it is never re-analyzed. Recreates the *style*, never copies footage.

**3. B-roll loop (reusable)** — the agent writes `inputs/broll/SHOTLIST.md` with shot ids, durations and a
ready-to-paste generation prompt per shot → you generate and drop the clips in that folder → say
**"broll done"** → `broll-status.sh` checks them → `broll-library.sh archive` saves them to
`library/broll/`. Next video searches the library first (`broll-library.sh search …`) and only asks for new clips.

**4. Audio library** — `library/music/` and `library/sfx/` (auto-indexed with `sfx-index.mjs`).
Sound files are not bundled (licences) — bring your own, see `library/sfx/README.md`. Placement rules are built in: whoosh on cuts, impact on stats, riser ending on the reveal, one SFX per
3–5 s, all on one track at low volume so you can mute them in Studio.

**5. Gujarati → Gujlish captions** — local whisper large-v3 transcription, converted once to natural
Latin-script Gujarati (English words stay English). Any other language works with normal captions.

**6. House rules** — face-safe layouts, dead-air trim, watermark crop, checkpoints (`restore v2`)… all in
`.claude/editing-principles.md`; edit to your taste.

## Requirements

| Package | Used for | Install |
| --- | --- | --- |
| Claude Code + HyperFrames plugin | the whole workflow | `hyperframes@hyperframes` |
| ffmpeg / ffprobe | analysis, contact sheets, trims | `brew install ffmpeg` |
| whisper-cpp (`whisper-cli`) | local transcription | `brew install whisper-cpp` |
| `ggml-large-v3.bin` | Gujarati-capable model | download to `~/.cache/hyperframes/whisper/models/` |
| Node 18+ | Gujlish, SFX index scripts | `brew install node` |
| Python venv with Kokoro | free local voice-over (optional) | set `HYPERFRAMES_PYTHON` |

## Contents
- `CLAUDE.md` — workspace conventions and token budget
- `.claude/commands/` — `/new-video`, `/broll-plan`
- `.claude/skills/reels-workflow/` — skill that routes requests into the workflow
- `.claude/editing-principles.md` — editing, SFX, review and house rules (edit to taste)
- `scripts/` — intake, analysis, transcription, Gujlish, B-roll library, SFX index, frame review
- `library/` — put your brand, fonts, music, SFX, LUTs, B-roll and saved styles here

## Install
1. Install the HyperFrames plugin in Claude Code (`hyperframes@hyperframes`).
2. Copy this repo's contents into your video workspace (or clone it as the workspace).
3. `chmod +x scripts/*.sh`
4. Edit `.claude/settings.json`: set `HYPERFRAMES_PYTHON` to a Python with Kokoro (for TTS) and keep
   `WHISPER_LANG` / `WHISPER_MODEL` (use `en` for English).
5. Download `ggml-large-v3.bin` from whisper.cpp to `~/.cache/hyperframes/whisper/models/`.
6. Requires: ffmpeg, whisper-cpp (`whisper-cli`), Node 18+.

## Use
```
/new-video my-reel path/to/footage.mp4 -- 9:16 reel, 30s
```

## Share
```
git init && git add . && git commit -m "AI Video Editor Claude Skill"
gh repo create ai-video-editor-claude-skill --public --source=. --push
```
