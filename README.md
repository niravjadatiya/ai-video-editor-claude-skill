# HyperFrames Reels Kit

A Claude Code workspace kit for making short talking-head reels with the
[HyperFrames](https://hyperframes.dev) plugin: footage intake, cheap media analysis, local Gujarati
transcription (whisper.cpp large-v3) with Gujlish captions, B-roll shot lists with a reusable library,
SFX placement rules, frame review, and house editing rules.

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
git init && git add . && git commit -m "HyperFrames Reels Kit"
gh repo create hyperframes-reels-kit --public --source=. --push
```
