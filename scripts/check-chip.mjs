// Keeps every lesson, quiz and lab consistent with the one imaginary chip (src/data/lumen-1.json).
// Code cannot import the JSON (it is Tcl, tested on its own), so this script checks it instead:
//   - set chipName / chipWidth / chipHeight <value>  must match the JSON
//   - any "Lumen-<n>" must be the chip's real name
//   - a block written as {NAME x y w h} must match the block's numbers
// Usage: node scripts/check-chip.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { walk } from './lib/mdx-scan.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const chip = JSON.parse(fs.readFileSync(path.join(root, 'src/data/lumen-1.json'), 'utf8'));
const files = [
    ...walk(path.join(root, 'src/content/docs'), ['.md', '.mdx']),
    ...walk(path.join(root, 'src/content/quizzes'), ['.yaml']),
    ...walk(path.join(root, 'labs'), ['.tcl', '.txt', '.md']),
].filter((f) => !f.endsWith(`${path.sep}demo.mdx`));

const blocks = Object.fromEntries(chip.blocks.map((b) => [b.name, b]));
const errors = [];
for (const file of files) {
    const rel = path.relative(root, file);
    fs.readFileSync(file, 'utf8').split('\n').forEach((line, i) => {
        const where = `${rel}:${i + 1}`;
        for (const m of line.matchAll(/\bset\s+(chipName|chipWidth|chipHeight)\s+("?)([^\s"}\]]+)\2/g)) {
            const want = String(chip[chip.tcl_names[m[1]]]);
            if (m[3] !== want && !m[3].startsWith('$') && !m[3].startsWith('[')) errors.push(`${where}: ${m[1]} is ${m[3]}, but Lumen-1 says ${want}`);
        }
        for (const m of line.matchAll(/\bLumen-(\d+)\b/g)) {
            if (`Lumen-${m[1]}` !== chip.name) errors.push(`${where}: "${m[0]}" — the chip is called ${chip.name}`);
        }
        for (const m of line.matchAll(/\{([A-Z]+) (\d+) (\d+) (\d+) (\d+)\}/g)) {
            const b = blocks[m[1]];
            if (b && [b.x, b.y, b.w, b.h].join(' ') !== m.slice(2, 6).join(' ')) {
                errors.push(`${where}: block ${m[0]} differs from Lumen-1 {${b.name} ${b.x} ${b.y} ${b.w} ${b.h}}`);
            }
        }
    });
}
if (errors.length) {
    console.error(`check-chip: ${errors.length} problem(s)\n - ${errors.join('\n - ')}`);
    process.exit(1);
}
console.log(`check-chip: OK — ${files.length} file(s) agree with ${chip.name} (src/data/lumen-1.json)`);
