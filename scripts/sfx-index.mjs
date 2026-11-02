#!/usr/bin/env node
// Rebuild library/sfx/INDEX.md.
//   core  = files directly in library/sfx/ (the curated, verified set) — ALWAYS preferred
//   extra = files in library/sfx/extra/ (bulk-imported, unverified) — only when core has no match
// Descriptions come from library/sfx/descriptions.json; files without one are described by their
// name + length, so name your own files descriptively (e.g. whoosh-fast-airy.mp3). Renaming an extra
// file to include "best" (whoosh-3-best.wav) marks it as a preferred extra.
//
// Usage: node scripts/sfx-index.mjs
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const dir = path.join(path.dirname(new URL(import.meta.url).pathname), "..", "library", "sfx");
const descPath = path.join(dir, "descriptions.json");
const desc = fs.existsSync(descPath) ? JSON.parse(fs.readFileSync(descPath, "utf8")) : {};
const AUDIO = /\.(mp3|wav|m4a|aac|ogg|flac|aiff?)$/i;

const secsOf = (f) => {
  try {
    return Number(execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", f], { stdio: ["ignore", "pipe", "ignore"] }).toString().trim());
  } catch {
    return NaN;
  }
};
const lengthTag = (s) => (s < 0.6 ? "short hit" : s < 2 ? "medium" : s < 5 ? "long" : "very long, trim it");

const rows = (sub, tier) => {
  const d = sub ? path.join(dir, sub) : dir;
  if (!fs.existsSync(d)) return [];
  return fs.readdirSync(d).filter((f) => AUDIO.test(f)).sort((a, b) => a.localeCompare(b, undefined, { numeric: true })).map((f) => {
    const s = secsOf(path.join(d, f));
    const rel = sub ? `${sub}/${f}` : f;
    const base = (desc[f] ?? (sub ? path.parse(f).name.replace(/-\d+$/, "").replace(/-/g, " ") : "")).replace(/\|/g, "/");
    const t = tier === "extra" && /best/i.test(f) ? "extra★" : tier;
    return `| \`${rel}\` | ${t} | ${isNaN(s) ? "?" : s.toFixed(2)} | ${[base, lengthTag(s)].filter(Boolean).join(" · ")} |`;
  });
};

const core = rows("", "core");
const extra = rows("extra", "extra");
fs.writeFileSync(
  path.join(dir, "INDEX.md"),
  "# SFX library\n\n" +
    "Priority: **core** (verified) first. Use **extra★**, then **extra** (unverified bulk pack) only when no core sound fits.\n" +
    "Search: `grep -i <word> library/sfx/INDEX.md`. Riser/swell: place so its END lands on the moment.\n\n" +
    "| File | Tier | Secs | Use |\n| ---- | ---- | ---- | --- |\n" +
    [...core, ...extra].join("\n") + "\n",
);
console.log(`Indexed ${core.length} core + ${extra.length} extra sound(s) → library/sfx/INDEX.md`);
