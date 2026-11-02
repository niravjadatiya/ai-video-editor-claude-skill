# Editing principles (apply to every video)

## Analyze before editing — cheaply
- Run `scripts/analyze-media.sh <video>` once. Work from `analysis/REPORT.md`, ONE look at each
  `*.sheet.jpg`, and the reference `.srt` transcripts. Don't extract or view extra frames unless a
  specific question can't be answered from these.
- The build workflow transcribes the source footage itself (local, free). Never read a word-level
  `transcript.json` raw: export it once with the CLI's `transcribe <transcript.json> --to srt -o
  analysis/footage.srt` and read the SRT. Caption timing comes from the workflow's scripts; author
  only the caption text/grouping/emphasis they ask for.
- For each reference (skip ones marked "known style"), write the style notes to the path the report
  gives (`library/styles/<name>-<key>.md`), max ~25 lines:
  pacing (cuts/min, avg shot, rhythm over time) · captions (position, size, weight, case, words on
  screen, highlight color) · typography · motion language (easing, speed, entrances) · transitions ·
  zooms/reframes · B-roll and screenshot rhythm · graphics density · color/grade · music/SFX rhythm ·
  layout and safe zones · what NOT to borrow.
- Write `videos/<video>/analysis/STYLE.md`: which reference principles fit THIS footage and which
  don't, and why. Recreate the principles; never copy the reference's content or footage.

## Edit
- Build around the content. Every visual must explain, prove, emphasize a key moment, add useful
  contrast, or help retention. No effects just to look busy.
- Tools when they earn it: clean cuts, captions/kinetic type, B-roll, images/screenshots, screen
  recordings, motion graphics, callouts, zooms/reframes, transitions, generated assets.
- Match the references' pacing, visual density, type feel, motion language, transition style and
  B-roll rhythm, adapted to this content.

## Sound design (SFX)
- Priority: **core** sounds first; **extra★** then **extra** (unverified bulk pack) only when no core
  sound fits the moment. Tell the user in one line which extra files were used so they can check them.
- Source: `library/sfx/` only (search `grep -i <word> library/sfx/INDEX.md`). Copy used files into
  `project/assets/sfx/`. Need a sound that isn't there? Ask the user to add one; don't search online.
- Hang SFX on visual events you already placed: use the composition's own timings, never analyze audio.
  | Moment | Sound |
  | --- | --- |
  | cut to B-roll / scene change | `whoosh-short` (starts ~0.1s before the cut) |
  | big title, section change | `whoosh-cinematic` or `impact-bass-*` |
  | number/stat lands, key word hits | `impact-bass-*` or `pop` |
  | text, icon or callout pops in | `pop` / `click-soft` |
  | build-up to a reveal | `riser`: END lands on the reveal (start = reveal − length; trim with `data-media-start`) |
  | good point / success | `chime` / `sparkle` |
  | myth, mistake, "wrong" | `error` / `glitch-1` |
- Restraint: roughly one SFX every 3–5s in reels, fewer in calm or long videos. Prefer pauses, not over
  key spoken words; vary variants and don't repeat the same sound back-to-back. Follow STYLE.md's
  SFX rhythm when there is a reference.
- Mix: `data-volume` 0.2–0.35, under the voice (and music). Put all SFX on ONE dedicated track so the
  user can mute or nudge them in Studio. Use `/hyperframes-audio` only if something clashes.

## Composition
- Find the important subject in each shot and keep graphics off it: never cover a face; on screen
  recordings/product shots never cover the UI being discussed.
- Respect platform safe zones as defined in `/hyperframes-studio` (captions and key content stay
  clear of the platform's UI overlays).

## Review before the final render
- Run `check`, then `scripts/review-frames.sh <video> <times>` with up to 12 key moments
  (hook, each B-roll/graphic entry, caption-heavy spots, transitions, ending) and look at the one
  `analysis/review.jpg`. Verify: nothing important covered, captions readable, visuals match what is
  said, transitions clean, no unneeded graphics, consistent with STYLE.md. A/V sync: confirm the
  footage clip's start/media offsets in `timeline --json`, not by viewing frames.
- Fix problems, re-check only the changed moments, then open the Studio preview for the user and
  render the final only after they approve. Originals in `inputs/` are never modified.

## House rules (learned from the user's notes on past videos — apply by default)
- **Trim dead air at the start.** Measure loudness (ffmpeg astats RMS) and start the footage ~0.5s
  before speech gets loud (`data-media-start`, shift every timing by the same offset). Never clip the first word.
- **Find the face in the actual frames first.** Speakers often sit low in frame, so put title, name, CTA and
  closing cards in the empty space ABOVE the head (top ~200–650px of 1920), never on the face or chin.
- **Split-screen (paper panel on top):** never tight-crop the speaker. Scale the footage down into a
  rounded window in the bottom half showing head + shoulders (transform `scale` + `clip-path inset(... round)`
  on the wrapper; animating top/height fails `check`).
- **B-roll moments:** B-roll fills the whole 9:16 background; speaker stays on top in a small rounded
  window (bottom-left, ~45% scale), with a short white label chip just above it. Panels/lists keep the split.
- **AI-generated B-roll** often has a watermark (e.g. a ✦ bottom-right). The renderer ignores CSS
  transforms/oversizing on `<video>`, so crop it out of the staged copy in `project/assets/broll/`
  (ffmpeg crop ~10–16% from right/bottom); originals in `inputs/` and `library/` stay untouched.
- **Legal/disclaimer text** goes in a small dark strip at the very bottom of the frame, not mid-frame.
- **Layering:** later DOM elements paint on top. When B-roll is added after cards, give the card hosts
  an explicit `z-index` and re-check that every card is still visible.
- **Checkpoints:** before each major change (adding B-roll, re-layout, trims), copy `index.html` to
  `project/checkpoints/vN-<what>/` so the user can say "restore vN".
- **Default look for talking-head reels** (unless a reference or saved style says otherwise): hook title in
  a white rounded card at the top; warm off-white "paper" panels for lists/claims, revealed item by item on
  the spoken word; Inter bold; green ✓ / red ✗ accents; voice-only (music optional, added later).
