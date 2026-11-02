---
description: List the B-roll clips to generate (file names + prompts), reusing the shared library first
argument-hint: <video-name> [-- extra direction]
allowed-tools: Bash(scripts/broll-status.sh:*), Bash(scripts/broll-library.sh:*)
---

Arguments: $ARGUMENTS

Plan the B-roll for `videos/<video-name>/`. Nothing gets built until I say **broll done**.

1. Work from what is already known: this conversation, `project/BRIEF.md` if it exists, else
   `inputs/docs/`. Don't open media files. If you don't know what the video is about, ask in one line and stop.
2. Pick only shots that real footage does better than motion graphics (titles, text, charts,
   diagrams and UI are built in HyperFrames, never listed). Usually 3–8 shots.
3. For each shot, first run `scripts/broll-library.sh search <2-3 key words>`. If a clip with the
   right subject and aspect exists, run `scripts/broll-library.sh use <video> <shot-id> <file>` and
   mark the row's prompt as `reused: <file>`. Only list new clips for me to generate.
4. Write `videos/<video-name>/inputs/broll/SHOTLIST.md` (ask before overwriting one that has rows):

   ```
   # B-roll shot list — <video-name>
   Aspect: <16:9 | 9:16 | 1:1> · Save each clip in this folder as <shot-id>.mp4

   | Shot id | Secs | Used at | Prompt |
   | ------- | ---- | ------- | ------ |
   | `b01-city-night-aerial` | 5 | intro, behind title | ... |
   ```

   - Shot id: `bNN-` + 2–4 descriptive lowercase words (they become the library file name, so
     describe the content, not the video: `b03-hands-typing-laptop`, not `b03-scene-two`).
   - Secs: 3–8, slightly longer than needed.
   - Prompt: one self-contained line: subject + action, setting, camera move, lighting/mood,
     style, aspect ratio, "no text, no logos, no watermark". Same look across shots.
5. Reply with ONLY: the folder path, a numbered list `b01-city-night-aerial.mp4 — 5s — <prompt>`
   (reused shots as one line: "reused from library: …"), and "Save them there and say **broll done**."
   Then stop and wait.

When I say **broll done**: run `scripts/broll-status.sh <video>`. If anything is missing,
misnamed or too short, tell me in one line and wait (I may say "go anyway" — then use motion
graphics for missing shots). Otherwise run `scripts/broll-library.sh archive <video>` and start building.
