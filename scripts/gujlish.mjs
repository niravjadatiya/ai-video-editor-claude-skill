#!/usr/bin/env node
// Swap the words of a word-level transcript.json for Gujlish while keeping every timing,
// so caption workflows (which require captions to match the transcript verbatim) work in Gujlish.
//
// Usage:
//   node scripts/gujlish.mjs export <transcript.json> <lines.txt>
//       Writes the spoken words as phrase lines (split at pauses/punctuation), one phrase per line.
//   node scripts/gujlish.mjs apply <transcript.json> <gujlish.txt>
//       <gujlish.txt> = the same lines rewritten in Gujlish, SAME number of lines and SAME number of
//       space-separated words per line (write a multi-word English phrase joined with "_" if a
//       Gujarati word maps to it). Keeps a backup at transcript.gu.json.
import fs from "node:fs";
import path from "node:path";

const [cmd, jsonPath, txtPath] = process.argv.slice(2);
if (!cmd || !jsonPath || !txtPath) {
  console.error(fs.readFileSync(new URL(import.meta.url), "utf8").split("\n").slice(1, 12).join("\n"));
  process.exit(1);
}

// Always work from the original transcript, so re-applying a corrected file is safe.
const backup = path.join(path.dirname(jsonPath), "transcript.gu.json");
const source = fs.existsSync(backup) ? backup : jsonPath;
const doc = JSON.parse(fs.readFileSync(source, "utf8"));
const all = Array.isArray(doc) ? doc : doc.words;
if (!Array.isArray(all)) throw new Error("No words[] array in " + jsonPath);
const words = all.filter((w) => (w.type ?? "word") === "word" && String(w.text).trim());

// Group into phrases: break after sentence punctuation or a pause > 0.5s.
const phrases = [];
let cur = [];
words.forEach((w, i) => {
  cur.push(w);
  const next = words[i + 1];
  const pause = next ? next.start - w.end : 0;
  if (!next || /[.!?।,]$/.test(String(w.text).trim()) || pause > 0.5) {
    phrases.push(cur);
    cur = [];
  }
});

if (cmd === "export") {
  const lines = phrases.map((p) => p.map((w) => String(w.text).trim()).join(" "));
  fs.writeFileSync(txtPath, lines.join("\n") + "\n");
  console.log(`${lines.length} lines, ${words.length} words → ${txtPath}`);
} else if (cmd === "apply") {
  const lines = fs.readFileSync(txtPath, "utf8").replace(/\n+$/, "").split("\n");
  const errors = [];
  if (lines.length !== phrases.length) errors.push(`line count ${lines.length}, expected ${phrases.length}`);
  phrases.forEach((p, i) => {
    const got = (lines[i] ?? "").trim().split(/\s+/).filter(Boolean).length;
    if (got !== p.length) errors.push(`line ${i + 1}: ${got} words, expected ${p.length}`);
  });
  if (errors.length) {
    console.error("Not applied:\n  " + errors.join("\n  "));
    process.exit(1);
  }
  if (!fs.existsSync(backup)) fs.copyFileSync(jsonPath, backup);
  phrases.forEach((p, i) => {
    const out = lines[i].trim().split(/\s+/);
    p.forEach((w, j) => (w.text = out[j].replace(/_/g, " ")));
  });
  if (!Array.isArray(doc) && typeof doc.text === "string") doc.text = words.map((w) => w.text).join(" ");
  fs.writeFileSync(jsonPath, JSON.stringify(doc, null, 2));
  console.log(`Applied Gujlish to ${words.length} words (backup: ${path.basename(backup)})`);
} else {
  console.error("Unknown command: " + cmd);
  process.exit(1);
}
