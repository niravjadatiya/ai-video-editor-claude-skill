# Contributing

Ideas welcome — keep changes small and token-cheap (this kit's whole point).

## Good first contributions
- **Language packs:** captions for Hindi, Marathi, Tamil… (see `scripts/gujlish.mjs` and the Language note in `CLAUDE.md`). Add a `transcribe-<lang>.sh` or a flag, plus a romanisation step.
- **Styles:** generic, brand-free style notes for `library/styles/` (use `EXAMPLE-talking-head-explainer.md` as the format).
- **SFX / editing rules:** better placement rules in `.claude/editing-principles.md`.
- **Platform support:** Linux/Windows install notes (the scripts are macOS-tested).
- **Bug fixes** in `scripts/` — run with `bash -n` and a sample clip first.

## Ground rules
- Don't commit footage, music, brand assets or anything with personal data. `library/` and `videos/` stay empty in the repo.
- Never add steps that make the agent read raw video or large JSON; add a script that summarises instead.
- Open an issue or PR with: what changed, how you tested it, a before/after if visual.
