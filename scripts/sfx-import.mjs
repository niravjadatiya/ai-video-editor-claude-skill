#!/usr/bin/env node
// Import a downloaded SFX pack (one folder per category) as LOWER-PRIORITY "extra" sounds.
// Copies (never moves) into library/sfx/extra/<category>-<n>.<ext>; a "Background Music" folder
// goes to library/music/. Video files are reduced to their audio. Then rebuilds the index.
//
// Usage: node scripts/sfx-import.mjs <pack-folder>
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const root = path.join(path.dirname(new URL(import.meta.url).pathname), "..");
const pack = process.argv[2];
if (!pack || !fs.statSync(pack, { throwIfNoEntry: false })?.isDirectory()) {
  console.error("Usage: node scripts/sfx-import.mjs <pack-folder>");
  process.exit(1);
}
const extra = path.join(root, "library/sfx/extra");
const music = path.join(root, "library/music");
fs.mkdirSync(extra, { recursive: true });

const ALIASES = {
  woosh: "whoosh", "woosh-sound-effects": "whoosh", glitches: "glitch", "mouse-click": "click",
  "paper-sound-effects": "paper", "typing-sound": "typing", "camera-sound": "camera", "ui-sound": "ui",
  "logo-animation": "logo-reveal", risers: "riser", miscellaneous: "misc",
};
const slug = (s) => s.toLowerCase().replace(/^\d+[.)]\s*/, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
const AUDIO = /\.(mp3|wav|m4a|aac|ogg|flac|aiff?)$/i;
const VIDEO = /\.(mp4|mov|m4v|webm)$/i;

const counters = {};
for (const f of fs.readdirSync(extra)) {
  const m = f.match(/^(.+)-(\d+)\.[^.]+$/);
  if (m) counters[m[1]] = Math.max(counters[m[1]] ?? 0, Number(m[2]));
}

let sfx = 0, tracks = 0, skipped = 0;
for (const dirName of fs.readdirSync(pack).sort()) {
  const dir = path.join(pack, dirName);
  if (!fs.statSync(dir).isDirectory()) continue;
  const files = fs.readdirSync(dir).filter((f) => !f.startsWith(".")).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));

  if (/background music/i.test(dirName)) {
    fs.mkdirSync(music, { recursive: true });
    for (const f of files.filter((f) => AUDIO.test(f))) {
      const dest = path.join(music, slug(path.parse(f).name) + path.extname(f).toLowerCase());
      if (fs.existsSync(dest)) { skipped++; continue; }
      fs.copyFileSync(path.join(dir, f), dest);
      tracks++;
    }
    continue;
  }

  const cat = ALIASES[slug(dirName)] ?? slug(dirName);
  for (const f of files) {
    const src = path.join(dir, f);
    if (!AUDIO.test(f) && !VIDEO.test(f)) { skipped++; continue; }
    const n = (counters[cat] = (counters[cat] ?? 0) + 1);
    if (VIDEO.test(f)) {
      execFileSync("ffmpeg", ["-loglevel", "error", "-y", "-i", src, "-vn", "-c:a", "libmp3lame", "-q:a", "2", path.join(extra, `${cat}-${n}.mp3`)]);
    } else {
      fs.copyFileSync(src, path.join(extra, `${cat}-${n}${path.extname(f).toLowerCase()}`));
    }
    sfx++;
  }
}
console.log(`Imported ${sfx} SFX → library/sfx/extra, ${tracks} music track(s) → library/music, skipped ${skipped}`);
execFileSync("node", [path.join(root, "scripts/sfx-index.mjs")], { stdio: "inherit" });
