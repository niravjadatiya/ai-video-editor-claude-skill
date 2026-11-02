# SFX library (bring your own)

Sound files are not bundled: the common free sources (e.g. Pixabay) allow free use in your videos but
not re-hosting the files themselves. Download your own and drop them here.

1. Get free, commercial-use sounds (Pixabay Sound Effects, Freesound CC0, etc.).
2. Name them so the placement rules in `.claude/editing-principles.md` match:
   `whoosh-short`, `whoosh-cinematic`, `impact-bass-1`, `pop`, `click-soft`, `riser`, `chime`, `sparkle`,
   `error`, `glitch-1`, `typing`, `notification` (`.mp3`).
3. Run `node scripts/sfx-index.mjs` to build `INDEX.md`.
4. Keep a `CREDITS.md` of sources and licences.
