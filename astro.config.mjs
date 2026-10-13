import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import preact from '@astrojs/preact';
import starlightLinksValidator from 'starlight-links-validator';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';
import { milestones } from './scripts/curriculum.mjs';

const pad = (n) => String(n).padStart(2, '0');

// One collapsed group per milestone; one collapsed sub-group per week (PRD §6.2).
const sidebar = Object.entries(milestones).map(([ms, m]) => {
  const items = [{ label: 'Overview', slug: `${ms}` }];
  for (let w = m.weeks[0]; w <= m.weeks[1]; w++) {
    items.push({
      label: `Week ${w}`,
      collapsed: true,
      items: [{ autogenerate: { directory: `${ms}/week-${pad(w)}` } }],
    });
  }
  items.push({ label: 'Capstone', slug: `${ms}/capstone` }, { label: 'Exam', slug: `${ms}/exam` });
  return { label: m.title, collapsed: true, items };
});

export default defineConfig({
  site: 'https://capeur.github.io',
  base: '/SJTU-VLSI-TCL-Language',
  markdown: { remarkPlugins: [remarkMath], rehypePlugins: [rehypeKatex] },
  integrations: [
    preact(),
    starlight({
      title: 'Tcl to Tapeout',
      description: 'A free 40-week course: Tcl from zero to VLSI layout scripting.',
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/Capeur/SJTU-VLSI-TCL-Language' }],
      plugins: [starlightLinksValidator()],
      routeMiddleware: './src/routeMiddleware.ts',
      components: { Footer: './src/components/Footer.astro' },
      customCss: ['katex/dist/katex.min.css', './src/styles/tokens.css', './src/styles/components.css'],
      sidebar: [
        { label: 'Start here', slug: 'start-here' },
        { label: 'Roadmap', slug: 'roadmap' },
        ...sidebar,
        { label: 'Playground', slug: 'playground' },
        { label: 'Spaced review', slug: 'review' },
        { label: 'Reference', items: [{ label: 'Overview', slug: 'reference' }, { label: 'Glossary', slug: 'reference/glossary' }, { label: 'Cheat sheets', slug: 'reference/cheatsheets' }] },
        { label: 'Setup', slug: 'setup' },
        { label: 'About', slug: 'about' },
      ],
    }),
  ],
});
