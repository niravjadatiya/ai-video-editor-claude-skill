---
description: Start a video — intake files, analyze footage + references, settle the brief, list B-roll, build, review
argument-hint: <video-name> [--move] [--as footage|references|broll|images|audio|docs] <files/folders...> [-- what you want]
allowed-tools: Bash(scripts/new-video.sh:*), Bash(scripts/analyze-media.sh:*), Bash(scripts/broll-status.sh:*), Bash(scripts/broll-library.sh:*), Bash(scripts/review-frames.sh:*)
---

Raw arguments: $ARGUMENTS

Read `.claude/editing-principles.md` once and follow it throughout.

1. **Intake.** Split the arguments at a standalone `--`. Run everything before it, unchanged:
   `scripts/new-video.sh <those arguments>` (quote paths with spaces). On failure show the error and stop.
2. **Request.** The text after `--`, else `inputs/docs/brief.md`. If neither says what to make, ask in
   ONE short message (type, platform/aspect, length) and stop.
3. **Analyze.** If there is footage or a reference video, run `scripts/analyze-media.sh <name>` and
   write the style notes + `analysis/STYLE.md` as the principles say. References are optional: if I
   name a saved style ("style: <name>") use that `library/styles/` file instead; with neither, skip
   the style part and let the HyperFrames workflow propose a look.
4. **Brief.** Use `/hyperframes:hyperframes` to settle the brief (project in `videos/<name>/project/`),
   informed by STYLE.md. Ask everything you need in ONE message. Stop before building scenes.
5. **B-roll — never skip silently.** Always stop here and ask. Unless I already said "no B-roll",
   follow `.claude/commands/broll-plan.md` (library first, then `inputs/broll/SHOTLIST.md`) and wait for
   **broll done** or "skip B-roll". If you think none is needed, say why in one line and still wait for my OK.
   Build only after this answer. When the brief is settled in step 4, mention that the B-roll list comes next.
6. **Build**, then **review** exactly as the principles say. Open the Studio preview and wait for my
   OK (or my batched notes) before the final render.
7. Keep replies short: no file dumps, no restating plans I already approved.
