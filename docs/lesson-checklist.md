# Lesson review checklist

- [ ] All §6.3 sections present, in order (header, Chip Story, Goals, Warm-up, Concept, Worked, Faded, Predict→Run→Explain, Traps, Exit quiz, Cheat card, Further reading). Concept/worked pairs may repeat; Predict may sit right after the concept it tests. `node scripts/check-lessons.mjs --verbose` shows the order
- [ ] ≤ 3 goals, each an observable action
- [ ] Warm-up uses 3 questions from *earlier* weeks (1 may come from an earlier lesson of the same week)
- [ ] ≤ 150 words between interactive elements
- [ ] Every new term uses `<GlossaryTerm>`; no unexplained acronyms
- [ ] Reading level grade 9–10
- [ ] Every `tcl run` snippet passes on Tcl 8.6 and 9.0 (or sits in a `<VersionNote>`)
- [ ] Expected outputs come from real runs (no hand-written output in prose; `<Trap>` error/output text is checked by CI)
- [ ] Lumen-1 facts come from `src/data/lumen-1.json` (`npm run validate` runs `check-chip`)
- [ ] Calibre commands carry ✅/⚠️ badges and appear in the status table
- [ ] No Tcl-9-only features from M30 on
- [ ] `sources:` filled; Further reading present; no copied text
- [ ] Diagrams have alt text; light and dark mode checked
- [ ] Frontmatter complete: `ai_assisted`, `reviewed_by`, `review_date`
- [ ] Quiz bank ≥ 25 items, each with an explanation
