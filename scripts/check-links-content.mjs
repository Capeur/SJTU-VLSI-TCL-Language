// Lists every external link of the course pages (frontmatter `sources:` and <FurtherReading> links) with the
// title of the page it really points to, so a human can spot a link whose target does not match its label
// (for example a "proc" label pointing to a page about strings). Run by hand, NOT in CI: it needs the network
// and page titles change over time.
//   node scripts/check-links-content.mjs [path-filter]      e.g.  npm run check:links-content -- m10/week-07
// Output, one block per link:  ok|??  file:line  /  label  /  url  /  → fetched title
// "??" means the label and the fetched title share no keyword. It is only a hint: always read the titles.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { walk } from './lib/mdx-scan.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const filter = process.argv[2] ?? '';
const files = walk(path.join(root, 'src/content/docs'), ['.md', '.mdx'])
    .filter((f) => path.relative(root, f).includes(filter))
    .sort();

// { title: "…", url: "…" } in frontmatter, or { title: '…', url: '…', kind: … } in a FurtherReading prop.
const linkRe = /title:\s*(["'])((?:(?!\1).)*)\1\s*,\s*url:\s*(["'])(https?:\/\/(?:(?!\3).)*)\3/g;
const links = [];
for (const file of files) {
    fs.readFileSync(file, 'utf8').split('\n').forEach((line, i) => {
        for (const m of line.matchAll(linkRe)) {
            links.push({ where: `${path.relative(root, file)}:${i + 1}`, label: m[2], url: m[4] });
        }
    });
}

const decode = (s) => s.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
    .replace(/&#39;|&#x27;/g, "'").replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n))).replace(/\s+/g, ' ').trim();

const titles = new Map();
async function pageTitle(url) {
    if (!titles.has(url)) {
        titles.set(url, (async () => {
            try {
                const response = await fetch(url, { redirect: 'follow', signal: AbortSignal.timeout(20000), headers: { 'user-agent': 'tcl-to-tapeout link title check' } });
                if (!response.ok) return `(HTTP ${response.status})`;
                const html = await response.text();
                const m = /<title[^>]*>([\s\S]*?)<\/title>/i.exec(html) ?? /<h1[^>]*>([\s\S]*?)<\/h1>/i.exec(html);
                return m ? decode(m[1].replace(/<[^>]+>/g, '')) : '(no title)';
            } catch (error) {
                return `(fetch failed: ${error.cause?.code ?? error.name})`;
            }
        })());
    }
    return titles.get(url);
}

// Words that say nothing about the topic.
const noise = new Set(['tcl', 'tutorial', 'manual', 'page', 'the', 'and', 'for', 'with', 'built', 'commands', 'command', 'man', 'more', 'from', 'your', 'see', 'what', 'how', 'its', 'are', 'all']);
const words = (text) => new Set((text.toLowerCase().match(/[a-z][a-z0-9]{2,}/g) ?? []).filter((w) => !noise.has(w)));
function shares(label, title) {
    // A Tcl manual page ("for manual page - Built-In Commands"): the label must name that command.
    const man = /^(\S+) manual page\b/i.exec(title);
    if (man) {
        const name = man[1] === 'Tcl' ? 'Tcl(n)' : man[1];
        return new RegExp(`(^|[\\s:,(])${name.replace(/[()]/g, '\\$&')}($|[\\s:,;)])`, 'i').test(label);
    }
    const a = words(label);
    return [...words(title)].some((w) => a.has(w) || [...a].some((x) => x.startsWith(w) || w.startsWith(x)));
}

// Fetch a few pages at a time, to be gentle with the servers.
const urls = [...new Set(links.map((l) => l.url))];
for (let i = 0; i < urls.length; i += 6) await Promise.all(urls.slice(i, i + 6).map(pageTitle));

let flagged = 0;
for (const link of links) {
    const title = await pageTitle(link.url);
    const ok = !title.startsWith('(') && shares(link.label, title);
    if (!ok) flagged++;
    console.log(`${ok ? 'ok' : '??'}  ${link.where}\n    label: ${link.label}\n    url:   ${link.url}\n    →      ${title}`);
}
console.log(`\ncheck-links-content: ${links.length} link(s), ${urls.length} distinct URL(s), ${flagged} flagged with ?? (read every title anyway)`);
