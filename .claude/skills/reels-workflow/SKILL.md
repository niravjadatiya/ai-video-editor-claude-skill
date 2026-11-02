---
name: reels-workflow
description: Make short talking-head reels with HyperFrames — intake footage, analyze references, Gujarati/Gujlish (or any language) captions, B-roll shot list, SFX, review and render. Use when the user asks to make, edit or caption a video/reel in this workspace.
---

# Reels workflow (HyperFrames)

Entry point for every make/edit/render request: route through `/hyperframes:hyperframes`.
Full rules live in `CLAUDE.md` (workspace conventions + token budget) and
`.claude/editing-principles.md` (analysis, edit, SFX, composition, review, house rules).

Steps: `/new-video <name> <files…>` → analyze (`scripts/analyze-media.sh`) → brief → B-roll
(`/broll-plan`, wait for "broll done") → build → `scripts/review-frames.sh` → Studio preview →
final render only after approval.

Captions: Gujarati is transcribed only with `scripts/transcribe-gu.sh <name>` and converted to
Gujlish with `scripts/gujlish.mjs`; other languages use normal captions in that language.
Keep replies short and token use lean.
