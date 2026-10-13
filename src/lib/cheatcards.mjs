// Finds every <CheatCard> in the docs so /reference/cheatsheets/ can aggregate them (PRD §7).
import path from 'node:path';
import fs from 'node:fs';
import { walk, componentTags } from '../../scripts/lib/mdx-scan.mjs';

export function collectCheatCards(docsDir = path.resolve('src/content/docs')) {
    const cards = [];
    for (const file of walk(docsDir, ['.mdx', '.md']).sort()) {
        const rel = path.relative(docsDir, file).replace(/\.mdx?$/, '');
        if (rel === 'demo') continue;                      // the demo page is not course content
        for (const tag of componentTags(fs.readFileSync(file, 'utf8'), ['CheatCard'])) {
            cards.push({ page: rel, title: tag.props.title, lines: tag.props.lines });
        }
    }
    return cards;
}
