// Tiny scanner for the two things build scripts need from MDX files:
//   1. fenced ```tcl run … ``` blocks (PRD §8.3)
//   2. JSX component tags and their attributes, e.g. <PredictOutput code={`…`} expected="…" />
// MDX content is trusted (it is in this repo), so attribute expressions are evaluated with Function.
import fs from 'node:fs';
import path from 'node:path';

export function walk(dir, exts, out = []) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) walk(full, exts, out);
        else if (exts.some((e) => entry.name.endsWith(e))) out.push(full);
    }
    return out;
}

/** Info-string attributes: tcl run expect="a\nb" drvlite */
export function parseInfo(info) {
    const attrs = {};
    const re = /([a-zA-Z0-9_-]+)(?:=(?:"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)'))?/g;
    let m;
    while ((m = re.exec(info))) {
        const raw = m[2] ?? m[3];
        attrs[m[1]] = raw === undefined ? true : raw.replace(/\\n/g, '\n').replace(/\\(["'\\])/g, '$1');
    }
    return attrs;
}

export function fencedBlocks(text) {
    const blocks = [];
    const re = /^```tcl[ \t]+([^\n]*)\n([\s\S]*?)^```[ \t]*$/gm;
    let m;
    while ((m = re.exec(text))) {
        const attrs = parseInfo(m[1]);
        if (attrs.run) blocks.push({ code: m[2].replace(/\n$/, ''), attrs });
    }
    return blocks;
}

/** Find <Name …> / <Name … /> tags; returns [{ name, props }]. Handles "…", {`…`}, {[…]}, {{…}}. */
export function componentTags(text, names) {
    const tags = [];
    const startRe = new RegExp(`<(${names.join('|')})(?=[\\s/>])`, 'g');
    let m;
    while ((m = startRe.exec(text))) {
        let i = startRe.lastIndex;
        const props = {};
        for (;;) {
            while (/\s/.test(text[i])) i++;
            if (text[i] === '/' || text[i] === '>') break;
            const nameMatch = /^[A-Za-z_:][\w:.-]*/.exec(text.slice(i));
            if (!nameMatch) throw new Error(`mdx-scan: cannot parse attributes of <${m[1]}> near: ${text.slice(i, i + 40)}`);
            const attr = nameMatch[0];
            i += attr.length;
            if (text[i] !== '=') { props[attr] = true; continue; }
            i++;
            if (text[i] === '"' || text[i] === "'") {
                const q = text[i]; const end = text.indexOf(q, i + 1);
                props[attr] = text.slice(i + 1, end); i = end + 1;
            } else if (text[i] === '{') {
                let depth = 0, j = i, inTpl = false, inStr = null;
                for (; j < text.length; j++) {
                    const c = text[j];
                    if (inTpl) { if (c === '\\') j++; else if (c === '`') inTpl = false; continue; }
                    if (inStr) { if (c === '\\') j++; else if (c === inStr) inStr = null; continue; }
                    if (c === '`') inTpl = true;
                    else if (c === '"' || c === "'") inStr = c;
                    else if (c === '{') depth++;
                    else if (c === '}' && --depth === 0) break;
                }
                props[attr] = new Function(`return (${text.slice(i + 1, j)})`)();
                i = j + 1;
            } else throw new Error(`mdx-scan: unsupported attribute value in <${m[1]}>`);
        }
        tags.push({ name: m[1], props });
    }
    return tags;
}
