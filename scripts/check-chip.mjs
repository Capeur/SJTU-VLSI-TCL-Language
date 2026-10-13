// Keeps every lesson, quiz and lab consistent with the one imaginary chip (src/data/lumen-1.json).
// Code cannot import the JSON (it is Tcl, tested on its own), so this script checks it instead:
//   - set chipName / chipWidth / chipHeight <value>  must match the JSON
//   - any "Lumen-<n>" must be the chip's real name
//   - a block written as {NAME x y w h} must match the block's numbers
//   - "<w> x <h> um" and "<w> × <h>" must be the chip's size or a block's size (also in diagrams)
//   - "Blocks: …" and "Layers: …" lists must match the JSON (all names, same order)
//   - the channel between CORE and SRAM (Week 4 lab): `set channelWidth <n>` and "<n> µm channel/gap
//     between (the) CORE and SRAM" must equal the gap computed from the blocks' x and w
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
    ...walk(path.join(root, 'src/content/glossary'), ['.yaml']),
    ...walk(path.join(root, 'labs'), ['.tcl', '.txt', '.md']),
    ...walk(path.join(root, 'src/assets/diagrams'), ['.svg']),
].filter((f) => !f.endsWith(`${path.sep}demo.mdx`));

const blocks = Object.fromEntries(chip.blocks.map((b) => [b.name, b]));
const sizes = new Set([`${chip.width_um} x ${chip.height_um}`, ...chip.blocks.map((b) => `${b.w} x ${b.h}`)]);
const blockList = chip.blocks.map((b) => b.name).join(' ');
const layerList = chip.layers.join(' ');
// The empty strip between CORE (left) and SRAM (right): SRAM's left edge minus CORE's right edge.
const coreSramGap = blocks.SRAM.x - (blocks.CORE.x + blocks.CORE.w);
const errors = [];
for (const file of files) {
    const rel = path.relative(root, file);
    fs.readFileSync(file, 'utf8').split('\n').forEach((line, i) => {
        const where = `${rel}:${i + 1}`;
        // The value ends at a space, quote, bracket, or prose punctuation (`400`, in an MDX sentence).
        // Values that do not start with a letter or digit ($var, [cmd], the "= 400" trap) are not facts.
        for (const m of line.matchAll(/\bset\s+(chipName|chipWidth|chipHeight)\s+("?)([^\s"}\]`,;<]+)\2/g)) {
            const want = String(chip[chip.tcl_names[m[1]]]);
            const value = m[3].replace(/\.+$/, '');
            if (value !== want && /^[A-Za-z0-9]/.test(value)) errors.push(`${where}: ${m[1]} is ${value}, but Lumen-1 says ${want}`);
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
        // "400 x 300 um" (code) or "400 × 300" (prose, diagrams): the chip's size or one block's size.
        for (const m of [...line.matchAll(/\b(\d+) x (\d+) um\b/g), ...line.matchAll(/\b(\d+) × (\d+)\b/g)]) {
            if (!sizes.has(`${m[1]} x ${m[2]}`)) errors.push(`${where}: "${m[0]}" is not the size of ${chip.name} or of one of its blocks`);
        }
        // The Week 4 lab channel is the real gap between CORE and SRAM.
        for (const m of line.matchAll(/\bset\s+channelWidth\s+([0-9.]+)/g)) {
            if (Number(m[1]) !== coreSramGap) errors.push(`${where}: channelWidth is ${m[1]}, but the gap between CORE and SRAM is ${coreSramGap} um`);
        }
        for (const m of line.matchAll(/\b(\d+) (?:µm|um) (?:wide )?(?:channel|gap) between (?:the )?CORE and SRAM\b/g)) {
            if (Number(m[1]) !== coreSramGap) errors.push(`${where}: "${m[0]}" — the gap between CORE and SRAM is ${coreSramGap} µm`);
        }
        // "Blocks: CORE SRAM …" and "Layers: ACTIVE POLY …" lists must be complete and in the JSON's order.
        for (const [label, want] of [['Blocks', blockList], ['Layers', layerList]]) {
            for (const m of line.matchAll(new RegExp(`\\b${label}: ([A-Z][A-Z0-9]*(?: [A-Z][A-Z0-9]*)+)`, 'g'))) {
                if (m[1] !== want) errors.push(`${where}: "${label}: ${m[1]}" — ${chip.name} says "${label}: ${want}"`);
            }
        }
    });
}
if (errors.length) {
    console.error(`check-chip: ${errors.length} problem(s)\n - ${errors.join('\n - ')}`);
    process.exit(1);
}
console.log(`check-chip: OK — ${files.length} file(s) agree with ${chip.name} (src/data/lumen-1.json)`);
