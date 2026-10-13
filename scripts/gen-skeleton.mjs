// Generates placeholder pages for all 40 weeks (PRD §17 P0). Safe to re-run:
// it never overwrites a file that has been edited (no "P0 placeholder" marker).
import { mkdirSync, writeFileSync, existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { milestones, weekThemes } from './curriculum.mjs';

const root = new URL('../src/content/docs/', import.meta.url).pathname;
const labsRoot = new URL('../labs/', import.meta.url).pathname;
const MARK = 'P0 placeholder';

function write(rel, fm, body) {
  const file = join(root, rel);
  if (existsSync(file) && !readFileSync(file, 'utf8').includes(MARK)) return;
  mkdirSync(dirname(file), { recursive: true });
  const front = Object.entries(fm)
    .map(([k, v]) => `${k}: ${typeof v === 'string' ? JSON.stringify(v) : JSON.stringify(v)}`)
    .join('\n');
  writeFileSync(file, `---\n${front}\n---\n\n{/* ${MARK} */}\n\n${body}\n`);
}

const pad = (n) => String(n).padStart(2, '0');
const common = (ms, week, lesson, runs) => ({
  milestone: ms, week, lesson, minutes: 0, goals: [], prerequisites: [], glossary: [],
  tcl_min: '8.6', sources: [], runs_in: [runs], ai_assisted: true, reviewed_by: '', review_date: '',
});

for (const [ms, m] of Object.entries(milestones)) {
  write(`${ms}/index.mdx`, {
    title: m.title, description: `Overview of ${m.title}`,
    sidebar: { label: 'Overview', order: 0 },
  }, `Milestone overview — content arrives in a later phase.\n\nCapstone: **${m.capstone}**.`);

  const [first, last] = m.weeks;
  for (let w = first; w <= last; w++) {
    const wk = `${ms}/week-${pad(w)}`;
    const theme = weekThemes[w];
    const isCap = w === last && ms !== 'm10'; // M10 week 10 still has lessons (PRD §9.1)
    write(`${wk}/index.mdx`, {
      title: `Week ${w}: ${theme}`, ...(({ lesson, ...rest }) => rest)(common(ms, w, 'a', m.runs)),
      sidebar: { label: 'Overview', order: 0 },
    }, `Week overview (goals, time plan, links) — content arrives in a later phase.`);
    const pages = isCap
      ? [['lab', 'Lab']]
      : [['lesson-a', 'Lesson A'], ['lesson-b', 'Lesson B'], ['lab', 'Lab'], ['quiz', 'Quiz']];
    pages.forEach(([slug, label], i) => {
      const lessonKey = slug === 'lesson-a' ? 'a' : slug === 'lesson-b' ? 'b' : slug;
      write(`${wk}/${slug}.mdx`, {
        title: `Week ${w} ${label}`, ...common(ms, w, lessonKey, m.runs),
        sidebar: { label, order: i + 1 },
      }, `${label} for week ${w} (${theme}) — content arrives in a later phase.`);
    });
    // lab folder placeholder
    mkdirSync(join(labsRoot, ms, `week-${pad(w)}`), { recursive: true });
    const keep = join(labsRoot, ms, `week-${pad(w)}`, '.gitkeep');
    if (!existsSync(keep)) writeFileSync(keep, '');
  }
  write(`${ms}/capstone.mdx`, {
    title: `${ms.toUpperCase()} Capstone: ${m.capstone}`, ...common(ms, last, 'capstone', m.runs),
    sidebar: { label: 'Capstone', order: 1 },
  }, `Capstone — content arrives in a later phase.`);
  write(`${ms}/exam.mdx`, {
    title: `${ms.toUpperCase()} Exam`, ...common(ms, last, 'exam', m.runs),
    sidebar: { label: 'Exam', order: 2 },
  }, `Milestone exam — content arrives in a later phase.`);
}

const simple = {
  'start-here': 'Start here', roadmap: 'Roadmap', playground: 'Playground', review: 'Spaced review',
  setup: 'Setup', about: 'About',
};
for (const [slug, title] of Object.entries(simple)) {
  write(`${slug}.mdx`, { title }, `${title} — content arrives in a later phase.`);
}
write('reference/index.mdx', { title: 'Reference' }, 'Cheat sheets, DRV-Lite API and Calibre command status — later phases.');
write('reference/glossary.mdx', { title: 'Glossary' }, 'VLSI and programming glossary — later phases.');
