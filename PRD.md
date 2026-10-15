# PRD — "Tcl to Tapeout": a 40-week VLSI scripting course website

> **Working title:** *Tcl to Tapeout* (rename freely: replace every occurrence of `{{SITE_NAME}}` / "Tcl to Tapeout").
> **Repository:** public on GitHub, deployed to GitHub Pages.
> **Status:** v1.1 — approved plan from the design session, reviewed milestone by milestone. Source of truth for Claude Code.

---

## 0. Instructions for Claude Code (read first)

1. **Work phase by phase** (§17). Finish one phase, run its acceptance checks, then **stop and ask the human to review** before starting the next phase.
2. **Create a `CLAUDE.md`** at the repo root in Phase 0 that summarises the non-negotiable rules of this PRD: §0, §4, §12, §14 and §15.
3. **Never invent Calibre syntax.** Every Calibre DESIGNrev command shown to learners must carry a status badge (§10.2). Commands not listed as ✅ in §10.2 are ⚠️ and must be presented as "DRV-Lite form; verify against the official Calibre DESIGNrev Reference Manual".
4. **Every Tcl code block that learners can run must be tested in CI** on Tcl 8.6 *and* Tcl 9.0 (§15.2). If a snippet behaves differently between versions, it must be wrapped in a `<VersionNote>` (§7).
5. **Quality benchmark first.** Phase 2 produces one complete "golden week" (Week 3). All later content must match its structure, tone and depth.
6. **Do not copy text** from Siemens manuals, Tcl man pages or tutorials. Paraphrase, then link to the original in the lesson's "Further reading".
7. When a requirement is ambiguous, prefer the simpler option and record the decision in `docs/decisions.md`.
8. **AI-assisted content is never published unreviewed.** This course is produced with AI tools as part of a VLSI course project. Every lesson, lab and quiz bank records `ai_assisted`, `reviewed_by` and `review_date` in its frontmatter (§8.1). Content with an empty `reviewed_by` is built with a visible "Draft — not yet reviewed" banner.
9. **From M30 onwards, use no Tcl-9-only features** in learner code. The Tcl version embedded in Calibre is not publicly documented, so DESIGNrev-style scripts must stay compatible with Tcl 8.6.

**Decisions already taken in the design session (do not reopen):**
- Teach Tcl code that runs on both Tcl 8.6 and 9.0; teach the differences in `<VersionNote>` boxes.
- Weeks 1–10 run entirely in an in-browser playground. Local tclsh is installed in Week 11 (optional earlier).
- **No Calibre licence or Calibre manual is available** to the project or learners. M30–M40 run on DRV-Lite + KLayout only.
- The content format (§3) is the one argued for in the design session; it is explained to learners on `/start-here/` (§6.7).

---

## 1. Product overview

### 1.1 Problem
VLSI layout scripting (Tcl + Calibre DESIGNrev) is learned today from dense vendor manuals that assume programming and chip-design experience. No free, structured path exists that takes a complete beginner to layout automation.

### 1.2 Solution
A free, static, open-source course website that teaches, over **40 weeks at ~3 hours/week**:
- the Tcl language from zero (M10–M20);
- layout creation and analysis using the DESIGNrev scripting style (M30–M40);

using **DRV-Lite**, a free teaching simulator written in pure Tcl, plus **KLayout** (free) as the real-world viewer. No commercial licence is needed.

### 1.3 Target learner
- **Primary:** a high-school student (≈15–18 years old) with **no programming and no science background** beyond arithmetic and the x/y coordinate plane.
- **Secondary:** university students in VLSI courses and junior engineers who want a structured refresher.
- **Device:** desktop or laptop for labs. Lessons must also read well on phones.

### 1.4 Goals
| ID | Goal | Measure |
|---|---|---|
| G1 | A beginner can follow the course with no outside help | Every lesson passes the reading-level and "defined-on-first-use" checks (§12) |
| G2 | Learning is evidence-based | Every lesson contains retrieval practice, worked + faded examples, and spaced review (§3) |
| G3 | No install is needed for Weeks 1–10 | All M10 code runs in the in-browser playground |
| G4 | No commercial licence is needed at any point | All labs run on tclsh + DRV-Lite + KLayout |
| G5 | Honest about Calibre | 100% of Calibre commands shown carry a ✅/⚠️ status badge |
| G6 | Learners finish with a public portfolio | Four capstones live in the learner's own GitHub repo |

### 1.5 Non-goals
- Teaching SVRF rule-file writing, Calibre nmDRC/LVS runs, analog design, or device physics beyond one-paragraph "Chip science" explainers.
- User accounts, servers or databases. The site is fully static.
- Reproducing or replacing the official Calibre documentation.
- Tk (GUI programming).

---

## 2. Course structure at a glance

| Milestone | Weeks | Theme | Capstone | Runs on |
|---|---|---|---|---|
| **M10** | 1–10 | Tcl Syntax Core | Mini Floorplan Checker | Browser playground |
| **M20** | 11–20 | Fluency & OOP | TinyLayout (pure-Tcl layout database) | Local tclsh (+ playground) |
| **M30** | 21–30 | DESIGNrev Core (via DRV-Lite) | Cell Generator → GDS opened in KLayout | Local tclsh + DRV-Lite + KLayout; Layout canvas in browser |
| **M40** | 31–40 | Batch Encyclopedia (via DRV-Lite) | Layout Auditor → RDB + HTML report | Local tclsh + DRV-Lite + KLayout |

**Each capstone reuses the previous one:** Floorplan Checker → TinyLayout → Cell Generator → Layout Auditor.

**Weekly unit** = Lesson A + Lesson B + Lab + Weekly Quiz (+ spaced-review flashcards).
**Totals:** 80 lessons, 40 labs, 40 weekly quizzes, 4 capstones, 4 milestone exams.

**Time budget per week (≈3 h):** 2 lessons × 40 min, a 60 min lab, 20 min review.
In M40, lessons become 20-minute "briefings" and the lab takes most of the week.

---

## 3. Pedagogical requirements

These are product requirements, not suggestions. They come from the research cited in §18.

| ID | Requirement | Rationale |
|---|---|---|
| P1 | Every lesson opens with a **3-question retrieval warm-up** drawn from *earlier* weeks; **1 of the 3 may come from an earlier lesson of the same week** (e.g. Lesson B's warm-up may include one Lesson A item) | Practice testing and distributed practice are the two "high utility" techniques (Dunlosky et al., 2013) |
| P2 | Every concept is taught with a **worked example** first, then a **faded example** (same task with blanks) | Worked-example effect; guidance fading (Sweller) |
| P3 | **Predict → Run → Explain**: the learner commits to a predicted output *before* running code | Exposes wrong mental models of Tcl substitution immediately |
| P4 | Every quiz question gives **immediate corrective feedback** (why the right answer is right, and why the chosen wrong answer is wrong) | Practice testing with feedback yields the strongest learning |
| P5 | Weekly quiz mix of current week vs earlier weeks: **M10 70/30, M20 60/40, M30 60/40, M40 50/50** | Distributed and interleaved practice |
| P6 | **Guidance fades across milestones** (§6.6): M10 has two worked examples and a faded one; M20 has one worked example plus find-the-bug; M30–M40 labs are specs with acceptance tests | Expertise-reversal effect: full scaffolding hurts learners once they are no longer novices |
| P7 | **One running VLSI thread**: every lab works on the same imaginary chip, introduced in Week 1 | Motivation and coherence; M10 rectangles become M30 geometry |
| P8 | Max **3 learning goals** per lesson; one main diagram per concept; no walls of text (≤ 150 words between interactive elements) | Cognitive-load management |
| P9 | Diagrams and the code they explain are shown **side by side**, never on separate pages (Layout canvas, §7) | Avoids split attention |

---

## 4. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Site framework | **Astro + Starlight** | Docs-style sidebar, built-in client-side search, dark mode, MDX |
| Content | **MDX** in `src/content/docs/` | Lessons import components |
| Interactive components | Astro components + small TypeScript islands (Preact or vanilla) | Keep JS bundles small; hydrate only interactive parts |
| In-browser Tcl | **Wacl** (Tcl 8.6 compiled to WebAssembly) | Self-hosted under `public/wacl/`. Fallback: LiveCodes embed SDK (§16) |
| Layout drawing | SVG generated by DRV-Lite (Tcl) and rendered by `<LayoutCanvas>` | |
| Math | KaTeX (`remark-math` + `rehype-katex`) | Used sparingly (units, area) |
| Diagrams | Hand-authored SVG in `src/assets/diagrams/`; Mermaid allowed for flowcharts | |
| Syntax highlighting | Starlight's Expressive Code, with Tcl grammar | |
| Hosting | **GitHub Pages** via GitHub Actions | Set `site` and `base` in `astro.config.mjs` for `https://<user>.github.io/<repo>/` |
| Tcl testing | `tcltest` on Tcl 8.6 and Tcl 9.0 in CI | §15.2 |
| Link checking | `starlight-links-validator` | Fails CI on broken links |
| Package manager | npm (lockfile committed) | |

**Tcl version policy:** all learner code must run on **Tcl 8.6 and Tcl 9.0**. Differences are taught in `<VersionNote>` boxes, starting in M20:
- namespace variable resolution;
- `~` no longer expanded to the home directory;
- strict encoding errors on I/O and the channel `-profile` option.

**Version targets per runtime:**
| Runtime | Tcl version | Consequence |
|---|---|---|
| Browser playground (Wacl) | 8.6.6 | M10 must use only features present in 8.6.6 (`dict`, `lmap`, `try`, TclOO are all available) |
| Learner's machine (M20+) | 8.6.x or 9.0.x | Both must pass CI |
| Calibre (real tool, M30+ "Real Calibre" boxes) | Unknown | No Tcl-9-only features in DESIGNrev-style code (§0 rule 9) |

---

## 5. Repository structure

```
/
├─ PRD.md                      ← this file
├─ CLAUDE.md                   ← rules summary for Claude Code (Phase 0)
├─ README.md                   ← project intro, how to run locally, how to contribute
├─ LICENSE                     ← MIT (code)
├─ LICENSE-CONTENT             ← CC BY-SA 4.0 (lesson text, diagrams, quizzes)
├─ astro.config.mjs
├─ package.json
├─ public/
│  └─ wacl/                    ← Wacl build artifacts (.js, .wasm, .data)
├─ src/
│  ├─ components/              ← §7 components
│  ├─ content/
│  │  ├─ docs/                 ← all pages (§6)
│  │  ├─ quizzes/              ← YAML quiz banks (§8.2)
│  │  └─ glossary/             ← YAML glossary entries (§8.4)
│  ├─ assets/diagrams/
│  └─ styles/                  ← tokens, layer colour palette (§13.3)
├─ drvlite/                    ← DRV-Lite engine (§10)
│  ├─ drvlite.tcl              ← package entry (package provide drvlite 0.1)
│  ├─ lib/                     ← layout.tcl, gds_read.tcl, gds_write.tcl, boolean.tcl, rdb.tcl, svg.tcl, units.tcl
│  ├─ bin/drvlite              ← launcher: `drvlite script.tcl args…`
│  └─ tests/                   ← tcltest suites
├─ labs/
│  └─ m10/week-01/ … m40/week-40/
│     ├─ README.md             ← the lab spec (also rendered on the site)
│     ├─ starter.tcl
│     ├─ data/                 ← input files (.txt, .gds, .rdb)
│     └─ tests/test.tcl        ← acceptance tests (§11)
├─ snippets/                   ← extracted runnable code blocks + expected output (generated, §15.2)
├─ scripts/                    ← build helpers (snippet extraction, quiz validation, defect-GDS generator)
├─ docs/
│  ├─ decisions.md             ← decision log
│  ├─ style-guide.md           ← §12 condensed
│  ├─ calibre-command-status.md← §10.2 table, kept up to date
│  ├─ lesson-checklist.md      ← per-lesson review checklist (§6.3 sections, §12 rules, snippets tested, sources)
│  ├─ peer-review-checklist.md ← learner peer-review checklist for M40 pull requests (§9.4)
│  └─ third-party.md           ← third-party licences (§14)
├─ labs/common/
│  └─ teaching-layers.lyp      ← KLayout layer-properties file matching §13.3
└─ .github/
   ├─ workflows/
   │  ├─ ci.yml                ← build, lint, quiz validation, Tcl tests (8.6 + 9.0), link check
   │  └─ deploy.yml            ← build + deploy to GitHub Pages on push to main
   ├─ PULL_REQUEST_TEMPLATE.md ← includes the lesson checklist
   └─ ISSUE_TEMPLATE/
      ├─ content-error.md
      └─ calibre-syntax-correction.md ← for verified corrections to ⚠️ commands
```

---

## 6. Information architecture & page templates

### 6.1 Sitemap
```
/                                  Home (hero, "start Week 1", roadmap preview)
/start-here/                       How this course works · how to study · weekly rhythm · the imaginary chip
/roadmap/                          Visual 40-week roadmap with milestone capstones; current-week marker (from local progress)
/m10/                              Milestone overview (goals, weeks, capstone, exam)
/m10/week-01/                      Week overview (goals, time plan, links)
/m10/week-01/lesson-a/
/m10/week-01/lesson-b/
/m10/week-01/lab/
/m10/week-01/quiz/
… same pattern for every week up to /m40/week-40/
/m10/capstone/ · /m10/exam/       (same for m20, m30, m40)
/playground/                       Free Tcl sandbox (+ DRV-Lite + Layout canvas toggle)
/review/                           Spaced-review flashcards from completed weeks
/reference/                        Cheat sheets (one per week), Dodekalogue explained, DRV-Lite API, Calibre command status
/reference/glossary/               VLSI + programming glossary
/setup/                            Install tclsh (Windows / macOS / Linux; optional from Week 1, required from Week 11) · install KLayout (needed from Week 21) · get the labs (fork / download)
/about/                            Authors, licence, sources, "not affiliated with Siemens" statement, how to contribute
```

### 6.2 Sidebar
Grouped by milestone and collapsed by default, except the milestone containing the learner's current week. Each week shows a completion tick from local progress.

### 6.3 Lesson page template (M10 full version)

Sections appear **in this order**, each implemented with the components in §7. Two flexibilities (decided in P2, see `docs/decisions.md`):
- **Concept + worked example (sections 4–5) may repeat** as pairs, one pair per new idea (e.g. 4a→5a, 4b→5b). M10 lessons still have two worked examples in total (§6.6).
- **Predict → Run → Explain (section 7) may move up** to sit right after the concept it tests, before the faded example.

`scripts/check-lessons.mjs` checks this order in CI.

| # | Section | Component(s) | Rules |
|---|---|---|---|
| 0 | Header bar | `<LessonMeta>` | Milestone › Week › Lesson; estimated minutes; progress dots |
| 1 | Chip Story | `<ChipStory>` | 1 paragraph + 1 image/diagram tying the topic to the imaginary chip |
| 2 | You will be able to… | `<Goals>` | ≤ 3 goals, each an observable action ("predict the output of…") |
| 3 | Warm-up | `<Quiz mode="warmup">` | 3 questions from earlier weeks, 1 of which may come from an earlier lesson of the same week (none in Week 1 Lesson A) |
| 4 | Concept | prose + 1 diagram | ≤ 150 words between interactive elements; every new term links to the glossary. May repeat with section 5 as concept/worked pairs |
| 5 | Worked example | `<WorkedExample>` | Code with numbered, line-by-line annotations |
| 6 | Faded example | `<FadedExample>` | The same task with 1–3 blanks; instant checking |
| 7 | Predict → Run → Explain | `<PredictOutput>` + `<TclPlayground>` | Learner types a prediction, then runs; mismatch shows the explanation |
| 8 | Common traps | `<Trap>` (×1–3) | Show the real error message and the fix |
| 9 | Exit quiz | `<Quiz mode="exit">` | 3–5 questions, current lesson only |
| 10 | Cheat-sheet card | `<CheatCard>` | ≤ 8 lines; also aggregated into /reference |
| 11 | Further reading | `<FurtherReading>` | Links to the official Tcl man page / KLayout doc / Siemens public KB |

### 6.4 Lab page template
1. Goal (one sentence) and the VLSI context.
2. What you'll practise (links to lessons).
3. Specification (inputs, outputs, examples).
4. "Where to run this" tabs (`<RunWhere>`).
5. Starter code (download link + inline view).
6. Hints, revealed one at a time (`<Hints>`, max 3).
7. "Check your work": exact command to run the acceptance tests and what a pass looks like.
8. Stretch goal (optional).

### 6.5 Weekly quiz page
- 8–12 questions, mixed as in P5.
- Score shown at the end, with every explanation reviewable.
- Wrong answers are added to the learner's review deck (§7, `<Flashcards>`).

### 6.6 Guidance fading by milestone

| Milestone | Worked examples | Faded example | Predict-output | Find-the-bug | Lab style |
|---|---|---|---|---|---|
| M10 | 2 | Yes | Yes (main exercise type) | Occasional | Step-by-step |
| M20 | 1 | No | Yes | **Main exercise type** | Goal + starter file |
| M30 | 1 | No | On the Layout canvas ("predict the shape") | Yes | Small spec + auto-check |
| M40 | 1 (in a 20-min briefing) | No | Rare | Yes | Spec + acceptance tests; optional PR peer review |

### 6.7 Other page templates
**Milestone overview (`/mXX/`):**
1. What you'll be able to do by the end (≤ 5 outcomes).
2. Week list with one-line summaries.
3. Capstone preview and how it builds on the previous capstone.
4. "Where code runs" in this milestone.
5. What's new in the lesson format for this milestone (§6.6), told in plain words. Example: "From now on, you'll get one worked example, then a broken script to fix."
6. Assessment: quiz mix, exam format, capstone rubric.

**Week overview (`/mXX/week-YY/`):** goals, time plan (≈3 h split), links to Lesson A/B, lab, quiz, and "review these first" links to prerequisite lessons.

**`/start-here/` must include "Why this course works":** a learner-friendly (≤ 400 words) explanation of the format:
- quizzing beats rereading;
- spacing beats cramming;
- worked examples first, then less help over time;
- predict before you run.

It cites the §19 learning-science sources and includes a short "how to study each week" checklist.

---

## 7. Component specifications

All components must:
- be keyboard accessible;
- work without JavaScript where they are static (graceful fallback: show code and expected output);
- respect light and dark mode tokens.

| Component | Purpose | Key props / behaviour |
|---|---|---|
| `<LessonMeta>` | Header bar | `milestone`, `week`, `lesson`, `minutes`. Marks the lesson "visited" in progress |
| `<ChipStory>` | VLSI hook | Slot content + optional `image` |
| `<Goals>` | Learning goals | List, max 3 (build-time warning if more) |
| `<TclPlayground>` | Run Tcl in the browser via Wacl | `code` (initial), `readonly?`, `drvlite?` (preloads DRV-Lite), `stdin?`. Buttons: Run, Reset, Copy. Shows stdout, stderr and the error message. Interpreter loads lazily on first Run, with a visible loading state. Hard timeout (e.g. 5 s) with a friendly "infinite loop?" message |
| `<PredictOutput>` | Predict → Run → Explain | `code`, `expected`, `explanation`. Learner must type a prediction before Run unlocks. Compares trimmed output and shows the explanation on mismatch |
| `<WorkedExample>` | Annotated code | `code`, `notes` (array keyed by line number). Hovering or focusing a note highlights its line |
| `<FadedExample>` | Fill-in-the-blank code | `template` with `___1___` markers, `answers` (array of accepted strings or regex), `hint` per blank |
| `<Trap>` | Common mistake | `wrong` code, `error` text, `fix` code, `why` text |
| `<Quiz>` | Retrieval practice | `bank` (quiz file id), `mode` = `warmup` \| `exit` \| `weekly` \| `exam`, `count`, `mix` (current/earlier ratio), `require` (a tag: at least one question with it is always drawn). Question types in §8.2. Immediate feedback per question |
| `<Flashcards>` | Spaced review | Leitner system: 5 boxes with intervals of 1, 3, 7, 14, 30 days. Cards come from quiz items with `review: true` and from questions answered wrongly |
| `<ProgressTracker>` | Local progress | localStorage only, every access wrapped in try/catch, with a working no-storage fallback. Export/import progress as JSON (for moving between devices) |
| `<VersionNote>` | Tcl 8.6 vs 9.0 differences | `since="9.0"`, short text + a code example for each version |
| `<RunWhere>` | Tabs: Playground / Terminal | Disables the Playground tab for code using `exec`, real files or `glob` outside the virtual filesystem |
| `<RealCalibre>` | Real-tool box (M30–M40) | `command`, `status` = `verified` \| `verify`, `source` (URL), `note`. ✅ / ⚠️ badge (§10.2) |
| `<ChipScience>` | One-paragraph VLSI explainer | `title`, slot, optional diagram. Visually distinct aside |
| `<LayoutCanvas>` | Code + live layout drawing side by side (M30+) | `code`, `cell?`. Runs DRV-Lite in Wacl and renders the SVG returned by `drvlite::svg`. Supports pan/zoom, layer visibility toggles, a grid, and coordinate readout on hover. Stacks vertically on mobile |
| `<CheatCard>` | Summary card | Collected automatically into `/reference/cheatsheets/` |
| `<Hints>` | Progressive hints | Up to 3, revealed one at a time |
| `<FurtherReading>` | External links | `links: {title, url, kind}[]` |
| `<GlossaryTerm>` | Inline definition | `term`. Tooltip with a short definition and a link to the glossary |

---

## 8. Content model

### 8.1 Lesson frontmatter (Starlight schema extension, validated with zod)
```yaml
---
title: "Quotes vs braces"
milestone: m10
week: 3
lesson: a                # a | b | lab | quiz | capstone | exam
minutes: 40
goals:
  - Predict the result of a word grouped with "..."
  - Predict the result of a word grouped with {...}
  - Choose the right grouping for a given task
prerequisites: [m10-w02-b]
glossary: [substitution, word, command]
tcl_min: "8.6"
sources:
  - { title: "Tcl(n) — Dodekalogue", url: "https://wiki.tcl-lang.org/10259" }
runs_in: [playground]    # playground | terminal | drvlite | klayout (drives <RunWhere> defaults)
ai_assisted: true
reviewed_by: ""          # name of the human reviewer; empty → "Draft" banner
review_date: ""          # YYYY-MM-DD
---
```

### 8.2 Quiz bank format (`src/content/quizzes/m10-w03.yaml`)
```yaml
- id: m10-w03-q01
  type: predict-output            # mcq | multi-select | predict-output | fill-blank | find-the-bug | order-steps
  lesson: a
  tags: [substitution, braces]
  review: true                    # eligible for spaced-review flashcards
  prompt: "What does this print?"
  code: |
    set x 5
    puts {x is $x}
  answer: "x is $x"
  explanation: >
    Braces stop all substitution, so $x is printed literally.
  distractor_feedback:            # optional, for mcq
    "x is 5": "That would happen with double quotes, not braces."
```
- A build-time script (`scripts/validate-quizzes`) checks unique ids, valid types, and that every `predict-output` answer matches the real tclsh output (§15.2).
- Minimum bank size per week: **25 items** (enough for warm-ups, exit quizzes, the weekly quiz and review).

### 8.3 Snippet convention
A runnable code block in MDX uses the info string ```` ```tcl run ```` and may declare the expected output:
````
```tcl run expect="x is $x"
set x 5
puts {x is $x}
```
````
Blocks marked ```` ```tcl norun ```` are illustrative only. Blocks that use DRV-Lite use ```` ```tcl run drvlite ````.

### 8.4 Glossary entry (`src/content/glossary/substitution.yaml`)
```yaml
term: substitution
short: "When Tcl replaces $name, [command] or \\n with a value before running a command."
long: "…"          # ≤ 120 words, beginner level
see_also: [braces, quotes, command]
first_taught: m10-w02-b
```

---

## 9. Curriculum specification

Each table row is one week: Lesson A, Lesson B, then the Lab.
- "⚠️" marks a Calibre command whose exact arguments must be verified (§10.2).
- "Chip science" items use `<ChipScience>`.

### 9.1 M10 — Tcl Syntax Core (Weeks 1–10)
**Milestone goal:** write a 100-line script that stores, checks and reports data about rectangles on a chip. Runs entirely in the browser playground.

| Wk | Theme | Lesson A | Lesson B | Lab |
|---|---|---|---|---|
| 1 | Hello, chip | What a chip is (city map in layers); what a script is; `puts`; comments | Commands = words separated by spaces; `set`, `$` | Print a "chip passport" (name, size, layers) |
| 2 | Tcl as a calculator | `expr`: integers, decimals, operators; integer-division trap | `[ ]` command substitution; nesting | Compute chip area and cost per chip |
| 3 | **The quoting week** | `"..."` substitutes; `{...}` freezes everything | `\` escapes; the Dodekalogue in plain words; always brace `expr {…}` | "Substitution detective": 15 predict-the-output puzzles |
| 4 | Decisions & loops | `if`/`elseif`/`else`; comparisons | `while`, `for`, `incr`; why bodies are braced | Is this wire wider than the minimum width? |
| 5 | Lists I | Lists as strings of words; `list`, `llength`, `lindex` | `lappend`, `foreach` (incl. several variables) | A rectangle as `{x1 y1 x2 y2}`: width, height |
| 6 | Lists II | `lrange`, `lsearch`, `lsort` (`-integer`, `-index`) | `split`/`join`, `lmap`, nested lists | Sort cells by area |
| 7 | Your own commands | `proc`, arguments, defaults, `return` | Scope, `global`, intro to `upvar`, `args` | Write `rectArea`, `rectOverlaps` |
| 8 | Text handling | `string length/index/range/toupper/trim` | `string match`, `string map`, `format` | Parse and validate layer names like `M1_drawing` |
| 9 | Tables of data | `dict`: create/get/set/exists, `dict for` | `array`; choosing dict vs array | Layer table `M1 → {number 31 purpose drawing}` |
| 10 | When things go wrong | `error`, `catch`, `errorInfo` | `try … on error … finally`; defensive procs | **Capstone + exam** |

**M10 capstone — Mini Floorplan Checker**
- **Input:** a list of blocks `{name x y w h}` plus the chip boundary.
- **The script must:**
  - validate the input with `try`;
  - compute the area of each block and the total;
  - detect overlapping pairs and blocks outside the boundary;
  - print a formatted report.
- **Rubric:** correctness 50%, error handling 25%, readability 25%.

**M10 assessment**
- Weekly quizzes: 70% current week / 30% spaced review.
- **Milestone exam:** 30 items, ≥ 60% predict-the-output, with ≥ 1/3 of all items on Week 3 (quoting and substitution).
- Capstone graded in the browser by the lab grader.

**M10 design decisions (keep them):**
- **Control flow is added in Week 4**, though it is not in the original outline: `proc`, `foreach` and `catch` cannot be taught without it.
- **`expr` comes early (Week 2):** a calculator gives an instant, motivating result and introduces `[ ]` naturally.
- **Quoting gets a whole week (Week 3):** every later milestone, including DESIGNrev scripts, depends on it.
- **The capstone's data model** (`{name x y w h}` rectangles, a boundary) is reused in M20 TinyLayout and becomes real `$L create polygon` geometry in M30. Lessons should say so explicitly ("you'll draw these for real in Week 23").

**M10 out of scope:** `upvar` beyond one simple example, `uplevel`, namespaces, file I/O, regex (all later), Tk.

### 9.2 M20 — Fluency & OOP (Weeks 11–20)
**Milestone goal:** a pure-Tcl mini layout database (TinyLayout) run from the command line. Week 11 is "install day" (Magicsplat on Windows; package manager on macOS/Linux). The playground remains available.

| Wk | Theme | Lesson A | Lesson B | Lab |
|---|---|---|---|---|
| 11 | Real Tcl & introspection | Install tclsh; run `.tcl` files; `argv`, `argc`, `source`; `info patchlevel` | `info exists/commands/procs/args/body/vars` | `chipinfo.tcl <name> <w> <h>` with argument checking |
| 12 | Files I | `open`/`puts`/`close`; modes `r w a` | `file join/exists/dirname/tail/extension`; Tcl 9 `~` change | Save the Floorplan Checker report to `report.txt` |
| 13 | Files II | `gets` loop vs `read` + `split`; `chan configure -encoding/-translation` | `glob`; walking a folder; Tcl 9 encoding errors and `-profile` | Read a folder of `.cell` files into a dict |
| 14 | Other programs | `exec`; exit codes; catching `exec` errors | Pipes `open "\|cmd"`; Windows vs Linux; never `exec` untrusted text | Run a child Tcl script and capture its output |
| 15 | Regex I | Patterns, classes, `+ * ?`; `regexp` | Capture groups; `-all -inline` | Parse a fake check log: `M1.W.1 width 0.04 < 0.05 at (12.3, 4.5)` |
| 16 | Regex II & time | `regsub` | `clock seconds/format/scan`, `clock milliseconds` | Timestamped log summariser: errors per rule, run duration |
| 17 | Namespaces | `namespace eval`, `variable`, `::`; Tcl 9 resolution change | `export`/`import`; ensembles | Package M10 procs into a `::geom` toolkit |
| 18 | TclOO I | `oo::class create`, `constructor`, `method`, `variable`, `my` | Objects are commands (`$r area`); `destroy`; read a real DESIGNrev snippet and spot the `$L method` pattern | `Rect` class: area, move, overlaps |
| 19 | TclOO II | `superclass`, overriding, `next` | `info object` / `info class`; mixins (brief) | `Shape` → `Rect`, `Wire`; a `Cell` holding shapes |
| 20 | Capstone | — | — | **TinyLayout + exam** |

**M20 capstone — TinyLayout**
- **Structure:** a `::tiny` namespace with classes `Layout`, `Cell` and `Shape`.
- **Input:** a simple text layout format parsed with regex; bad lines are rejected with `try`.
- **Run as:** `tclsh tiny.tcl design.txt --report`.
- **Report:** shapes per layer, area per layer, cell hierarchy, run time.
- **Rubric:** adds *code organisation* (appropriate namespaces/classes).

**TinyLayout → DRV-Lite:** the project's *reference solution* of TinyLayout is the architectural seed of DRV-Lite (§10.1). Learners do not have to build DRV-Lite themselves. Week 21 must show them that DRV-Lite is "a grown-up TinyLayout", with the same ideas (layout object, cells, shapes per layer) and DESIGNrev-style method names.

**M20 assessment**
- Weekly quizzes: 60% current week / 40% spaced review (M10 + M20).
- **Milestone exam:** 30 items, centred on **find-the-bug** (≥ 50%), plus predict-the-output and short code-writing tasks.
- Capstone rubric: correctness, error handling, readability, **code organisation**.

**M20 design decisions (keep them):**
- `info` is taught first (Week 11) as a **debugging habit**. Later lessons' "Common traps" should suggest `info exists`, `info body` and similar when relevant.
- **Week 11 install day:**
  - **Windows:** Magicsplat installer. 1.x = Tcl 8.6, 2.x = Tcl 9.0; it adds Tcl to the PATH.
  - **macOS/Linux:** package manager.
  - **Self-check:** `puts [info patchlevel]`.
- `argv`/`argc` are taught in Week 11 because DESIGNrev batch scripts are run as `calibredrv script.tcl <args>`.
- **Week 18 reading exercise:** use a **project-written** snippet in DESIGNrev style (e.g. `set L [layout create]`, `$L create cell TOP`), with a link to the public Siemens KB article. Do not copy Siemens example code.
- Starter files live in `labs/`; forking the repo is presented as a first GitHub skill.

**M20 out of scope:**
- full regex theory (teach only the practical subset needed to read tool logs and reports, which M40 reuses);
- TclOO filters, metaclasses, `oo::objdefine` beyond a mention;
- inheritance deeper than one level (parent → children);
- coroutines, threads, sockets, Tk.

### 9.3 M30 — DESIGNrev Core via DRV-Lite (Weeks 21–30)
**Milestone goal:** generate a hierarchical layout from a batch script, export GDS and verify it in KLayout.

| Wk | Theme | Lesson A | Lesson B | Lab |
|---|---|---|---|---|
| 21 | From chip to drawing | Chip science: masks, layers, polygons, GDSII; tour a layout in KLayout | DRV-Lite: `layout create`, the `$L` handle, `$L create cell` | Create a layout with an empty top cell; inspect it |
| 22 | Layers & coordinates | Layer numbers/datatypes (`17.7`); `$L create layer` | Coordinate grid, vertex lists, user units vs dbu (concept) | One rectangle as a 4-point polygon |
| 23 | Polygons | `$L create polygon cell layer x1 y1 …`; vertex order; Manhattan shapes | Generating coordinates with loops/procs | Draw your initials; reuse `rectArea` |
| 24 | Wires & labels | Wires: centre line + width ⚠️ | `$L create text` ⚠️; the "invalid layer" error and fix | Route a metal wire between two pads, with labels |
| 25 | Save, load, batch | `$L gdsout`; open in KLayout | Batch scripts with `argv` (`drvlite script.tcl args`); `layout create file.gds` | Command-line rectangle generator → `out.gds` |
| 26 | Hierarchy I | Chip science: cell reuse (bit-cells) | `$L create ref` ⚠️: placing a child | 4×4 array of a "bitcell" |
| 27 | Hierarchy II | Rotate/mirror/magnify; transformed coordinates | `$L iterator ref TOP range 0 end` | Instance count per cell |
| 28 | Iterators & queries | `$L iterator poly` | Bounding box and area per layer from iterator output | Per-layer area report to a file |
| 29 | Boolean geometry | Chip science: a gate = poly ∩ active; Venn diagrams | `$L AND l1 l2 lout`; OR/NOT/XOR/SIZE ⚠️; check in KLayout | Find all "transistors": `POLY AND ACTIVE` → count |
| 30 | Capstone | — | — | **Cell Generator + exam** |

**M30 capstone — Cell Generator**
- **Parameters:** rows, columns, pitch, from the command line.
- **The script must:**
  - build a leaf cell from polygons, wires and labels;
  - array it hierarchically;
  - derive one layer with a boolean operation;
  - export GDS and write a report (cell counts, area per layer, run time).
- **Submission:** includes a KLayout screenshot.
- **Rubric:** adds *geometric correctness*, verified by XOR against a reference GDS (zero difference expected).
  - **Automated check:** DRV-Lite `$L XOR` (Manhattan) in the capstone grader.
  - **Manual check:** the learner repeats the XOR in KLayout and includes the screenshot.

**M30 assessment**
- Weekly quizzes: 60% current week / 40% spaced review (M10–M30).
- Labs are auto-checked by DRV-Lite test scripts.
- **Milestone exam:** 30 items, including "predict the shape" items on `<LayoutCanvas>` (draw/choose the resulting geometry), find-the-bug on DESIGNrev-style scripts, and status-badge literacy ("is this the verified Calibre form?").

**M30 design decisions (keep them):**
- **Chip science is spread** across Weeks 21 (masks/layers/GDS), 26 (cell reuse) and 29 (gate = poly ∩ active), each placed just before the code that needs it.
- **Units are introduced as a concept in Week 22** and taught properly in Week 31.
- **Week 29's transistor-counting lab is the milestone's high point.** Write it to feel like a discovery.
- **Honesty, shown to learners:**
  - the `/m30/` overview explains DRV-Lite, the ✅/⚠️ badges, the Manhattan-only limit, and the "not affiliated with Siemens" statement;
  - every lesson's `<RealCalibre>` box shows the real-tool form with its badge;
  - DRV-Lite error messages imitate the real tool's style (e.g. `layout0 create: invalid layer 34`, and the fix `$L create layer 34`).
- Learners have **no Calibre access** (§0). KLayout is the real-world tool used for every visual check.

### 9.4 M40 — Batch Encyclopedia via DRV-Lite (Weeks 31–40)
**Milestone goal:** audit real GDS files and produce results databases viewable in KLayout's marker browser. Lessons are 20-minute briefings; labs ship with acceptance tests.

| Wk | Theme | Briefing | Lab |
|---|---|---|---|
| 31 | Units & grids | dbu vs user units; the GDS `UNITS` record; floating-point traps; rule: compute in integer dbu, display in µm | Unit-conversion procs + off-grid vertex checker |
| 32 | Coordinates through hierarchy | Composing translate/rotate/mirror/magnify; flattening | Absolute position and orientation of every instance |
| 33 | Metadata inspection | Reading a real GDS: top cells, cells, layers, bboxes, empty/unreferenced cells | "Layout passport" report for a given GDS |
| 34 | Industrial batch scripting | `-option` parsing, exit codes, logging, config dicts, progress/timing, folder processing | Batch runner with a non-zero exit code on failure |
| 35 | Results databases I | Chip science: what a DRC run is. RDB structure: checks, results, polygons, cells | Write an RDB and open it in KLayout's marker browser |
| 36 | Results databases II | Parsing RDBs with regex; per-check summaries; run-to-run comparison | "What changed since the last run?" (new / fixed / unchanged) |
| 37 | Writing checks I | Chip science: design rules. Width/spacing/enclosure on Manhattan shapes | Min-width + min-spacing checker → RDB |
| 38 | Writing checks II | Hierarchy-aware checks, caching, timing; duplicate cells differing only in name; naming rules via regex | Duplicate-cell + naming audit |
| 39 | Audit framework | TclOO design: `AuditCheck` base class, subclasses, registry, config, RDB + HTML outputs | Refactor weeks 31–38 into the framework, with tests |
| 40 | Capstone | — | **Layout Auditor + final exam + portfolio** |

**M40 capstone — Layout Auditor**
- **Input:** a multi-cell GDS with **planted defects** generated by `scripts/make-defect-gds.tcl`:
  - off-grid vertices;
  - a width violation;
  - a spacing violation;
  - an empty cell;
  - a duplicated cell;
  - a bad cell name;
  - a misplaced instance.
- **Outputs:** an RDB that imports into KLayout, and an HTML summary.
- **Grading:** defects found and no false positives, checked automatically.
- **Final exam:** cumulative and interleaved across M10–M40.
- **Portfolio page:** explains how learners publish their four capstones in their own GitHub repo.

**M40 assessment**
- Weekly quizzes: 50% current week / 50% interleaved from all milestones.
- Every lab has acceptance tests (§11).
- **Final exam:** 40 items, cumulative and interleaved, roughly 10 per milestone. Mixes predict-the-output, find-the-bug, predict-the-shape and reading an RDB excerpt.
- **Optional peer review:**
  - learners open a pull request with their week's solution in their own fork;
  - a classmate reviews it against `docs/peer-review-checklist.md` (correctness, tests pass, naming, error handling, comments, units handled in integer dbu).

**M40 design decisions (keep them):**
- Lessons are 20-minute **briefings**; the lab takes most of the week.
- Rule taught in Week 31 and enforced in every later lab: **compute in integer dbu, display in µm**.
- **Results-database labs always end in KLayout's marker browser.** A file that doesn't import is a failed lab, whatever the tests say.
- All test GDS files (including the capstone's defect files) are **generated by project scripts**, so nothing proprietary is shipped.
- The four capstones form one story: Floorplan Checker → TinyLayout → Cell Generator → Layout Auditor. The portfolio page presents them in that order.

---

## 10. DRV-Lite engine specification

### 10.1 Purpose and principles
- A **teaching simulator** that mirrors the *shape* of the Calibre DESIGNrev Tcl API (a layout handle with methods), so that learners transfer naturally to the real tool.
- **Pure Tcl, no C extensions.** Must run unchanged in Wacl (browser, Tcl 8.6) and in tclsh 8.6 / 9.0.
- **Grown from TinyLayout.** Start from the project's M20 TinyLayout reference solution (namespaces + TclOO: Layout → Cell → shapes per layer). Expose it through DESIGNrev-style handle commands (`$L create …`), so learners recognise their own M20 design.
- **Feature split by milestone:**
  - **M30 needs:** create commands, GDS read/write, SVG, iterators, transforms, bbox, Manhattan booleans.
  - **M40 adds:** metadata queries, the units API, flattening, off-grid detection, RDB I/O and the defect generator.

  §17 phases follow this split.
- **Clearly not Calibre.** Package name `drvlite`; launcher `drvlite`; never called `calibredrv`. The disclaimer appears in the package header, the README and the site footer.
- **Internal integer database units.** Default: 1 user unit = 1 µm, 1000 dbu per µm (1 dbu = 1 nm). Coordinates given in user units are converted to integers with rounding; an off-grid input raises a warning (or an error in `-strict` mode).

### 10.2 Command set and status

Status meanings:
- **✅ verified**: the command form appears in public Siemens or industry examples (sources in §18).
- **⚠️ verify**: DRV-Lite defines its own argument order. Lessons must say: *"DRV-Lite form — check the exact syntax in the Calibre DESIGNrev Reference Manual"*.

Keep this table mirrored in `docs/calibre-command-status.md` and `/reference/calibre-status/`.

| Command (DRV-Lite) | Status | Behaviour |
|---|---|---|
| `layout create ?file.gds? ?-dt_expand? ?-preserveProperties? ?-preserveTextAttributes?` | ✅ (options accepted; may be no-ops) | Returns a handle command `layout0`, `layout1`, …; loads GDS if a file is given |
| `$L create cell name` | ✅ | Creates an empty cell |
| `$L create layer L` (`L` = `n` or `n.d`) | ✅ | Registers a layer; using an unregistered layer elsewhere raises `layoutN create: invalid layer L` |
| `$L create polygon cell layer x1 y1 x2 y2 …` (flat args or one list) | ✅ | Adds a polygon (closed automatically) |
| `$L create text cell layer x y string` | ⚠️ (command ✅, argument order ⚠️) | Adds a text label |
| `$L create wire cell layer width x1 y1 …` | ⚠️ | Adds a path |
| `$L create ref parent child x y ?mirror? ?angle? ?mag?` | ⚠️ | Adds an instance; angle ∈ {0,90,180,270} |
| `$L gdsout file ?cell?` (alias `$L gds out file`) | ✅ (both spellings seen) | Writes GDSII |
| `$L iterator ref cell range first last` | ✅ (command); return format ⚠️ | Returns a list of `{child x y mirror angle mag}` |
| `$L iterator poly cell layer range first last` | ✅ (command); return format ⚠️ | Returns a list of vertex lists |
| `$L AND l1 l2 lout` | ✅ | Boolean AND into `lout` (Manhattan only) |
| `$L OR / NOT / XOR l1 l2 lout` | ⚠️ | Boolean ops (Manhattan only) |
| `$L SIZE lin lout BY value` | ⚠️ | Grow/shrink (Manhattan only) |
| `$L cells`, `$L layers`, `$L topcell`, `$L bbox cell` | ⚠️ (DRV-Lite names) | Metadata queries |
| `$L units ?user dbu?` | ⚠️ | Get/set units |
| `$L delete` | ⚠️ | Destroys the handle |
| `drvlite::svg $L cell ?-layers list? ?-width px?` | DRV-Lite only | Returns an SVG string (used by `<LayoutCanvas>`) |
| `drvlite::rdb::*` | DRV-Lite only | Results-database writer and reader (§10.6) |

**Error-message style:** `<handle> <method>: <reason>` (e.g. `layout0 create: invalid layer 34`), raised with `return -code error` and a machine-readable `-errorcode {DRVLITE <CATEGORY> …}`.

### 10.3 GDSII reader/writer
- **Records:** HEADER, BGNLIB, LIBNAME, UNITS, ENDLIB, BGNSTR, STRNAME, ENDSTR, BOUNDARY, PATH, TEXT, SREF, AREF (read; written as expanded SREFs in v1), LAYER, DATATYPE, TEXTTYPE, XY, WIDTH, PATHTYPE, STRANS, MAG, ANGLE, STRING, ENDEL.
- Implement the GDS 8-byte real (excess-64, base-16) encode/decode with `binary format`/`binary scan`. Unit tests must cover 0.001, 1e-9, 1.0 and 0.5.
- Round-trip test: write → read → write must be byte-identical for DRV-Lite-generated files.
- Interop test: files written by DRV-Lite must open in KLayout. This is a manual check in Phase 5; automated if KLayout's Python module is available in CI.
- **In the browser:** reading and writing work on Wacl's virtual filesystem. The playground offers "Download .gds" (stretch goal; JS bridge).

### 10.4 Geometry
- Polygons are stored as integer vertex lists per cell per layer.
- Transforms: translate, rotate in multiples of 90°, mirror about x, and magnification (integer results rounded, with a warning).
- Flattening helper `drvlite::flatten $L cell` for checks.

### 10.5 Booleans (Manhattan only)
- Implement AND/OR/NOT/XOR/SIZE for rectilinear polygons, e.g. by decomposition into rectangles plus a scanline merge.
- Non-Manhattan input raises a `DRVLITE NONMANHATTAN` error with the message "not supported by DRV-Lite; use KLayout".
- Correctness tests compare against hand-computed results; when the KLayout Python module is available, also against KLayout's booleans.

### 10.6 Results databases (RDB)
- **Writer A — simplified ASCII RDB** in the style of Calibre's DRC ASCII results: header (top cell, precision), then one block per check with counts and polygon results.
  - **Acceptance:** imports into KLayout's marker browser without errors.
  - The exact Calibre grammar is ⚠️ and must be described to learners as "a simplified subset".
- **Writer B — KLayout `.lyrdb` XML** (micron units) as a fully documented alternative.
- A reader for both formats (used in Week 36).

### 10.7 Launcher
`drvlite/bin/drvlite script.tcl args…` sets `argv`/`argc`, runs `package require drvlite`, sources the script, and exits with the script's exit code. On Windows it is provided as `drvlite.tcl` (run with `tclsh drvlite.tcl …`).

### 10.8 Tests
`tcltest` suites in `drvlite/tests/` covering every command in §10.2, units, GDS round-trip, transforms, booleans and RDB. Target: **≥ 90% of public commands with at least one positive and one error test.** Run on Tcl 8.6 and 9.0.

---

## 11. Labs & automatic checking

- Each lab folder contains `README.md` (spec), `starter.tcl`, optional `data/`, and `tests/test.tcl`.
- `tclsh tests/test.tcl` (or `drvlite tests/test.tcl` from M30) prints one line per test and a final line `RESULT: PASS n/n` or `RESULT: FAIL k/n`. Messages must be beginner-friendly: what was expected, what was received, and which lesson to revisit.
- M10 labs also run in the browser: the lab page embeds the starter in `<TclPlayground>` with a "Check" button that runs the same tests.
- **Solutions:** not committed to the public repo. Hints live in the README. Full solutions are kept in a separate private repository (open item O3).
- Capstone graders are separate test files with the published rubric.

---

## 12. Content writing guidelines

1. **Reading level:** aim for a high-school (grade 9–10) reading level. Short sentences, active voice, "you".
2. **Define every term on first use** with `<GlossaryTerm>`. No unexplained acronyms (VLSI, GDS, DRC, dbu, RDB…).
3. **One idea per paragraph**, ≤ 150 words between interactive elements.
4. **Analogies:** the chip is a city map drawn in layers; keep this metaphor consistent across the course.
5. **Code style:**
   - 4-space indent;
   - always brace `expr` and `if`/`while` conditions;
   - descriptive names (`rectArea`, not `ra`);
   - no clever one-liners in M10.
6. **Every runnable snippet is tested** (§15.2). Expected outputs in text must come from real runs, never be written by hand.
7. **Calibre accuracy:** only use commands from §10.2, always inside `<RealCalibre>` with the correct status. Never present a ⚠️ form as the real syntax.
8. **Citations:** every lesson lists its sources in `sources:` frontmatter and "Further reading". Paraphrase; quotes ≤ 1 short sentence, and rarely.
9. **Inclusive, encouraging tone.** Errors are presented as normal and useful ("the error message is your friend").
10. **Images and diagrams** have alt text that describes what the diagram teaches.

---

## 13. Design & UX requirements

### 13.1 General
- Starlight default theme, customised: readable body width (~70 ch), comfortable line height, clear code font.
- Dark and light mode supported everywhere, including the playground and canvas.
- Mobile: lessons fully readable. The playground is usable but labelled "best on a computer". The Layout canvas stacks under the code.

### 13.2 Visual language
- Milestone colours (accent only): M10, M20, M30, M40, each with an accessible contrast ratio ≥ 4.5:1 for text.
- Callout styles:
  - `ChipScience` (chip icon);
  - `Trap` (warning);
  - `VersionNote` (version tag);
  - `RealCalibre`, with a ✅ green or ⚠️ amber badge (badge text, not colour alone).

### 13.3 Layer colour palette (consistent across canvas, diagrams and KLayout layer-properties file)
Provide `src/styles/layers.ts` and an exported KLayout `.lyp` file in `labs/common/` with **the same colours**:

| Layer (teaching) | GDS | Colour role |
|---|---|---|
| ACTIVE | 1.0 | green |
| POLY | 2.0 | red |
| CONTACT | 3.0 | black/white (theme-aware) |
| METAL1 | 4.0 | blue |
| VIA1 | 5.0 | grey |
| METAL2 | 6.0 | magenta |
| TEXT | 63.0 | text colour |
| DERIVED / RESULT | 100.0+ | orange hatched |

These are teaching layer numbers, not any foundry's. State this on the reference page.

---

## 14. Legal, licensing & trust

- **Code licence:** MIT. **Content licence:** CC BY-SA 4.0.
- **Disclaimer** in the footer, the About page and the DRV-Lite README: *"DRV-Lite is an independent educational simulator. It is not affiliated with, endorsed by, or a replacement for Siemens EDA Calibre®. Calibre and DESIGNrev are trademarks of Siemens. Command forms marked ⚠️ are approximations for learning."*
- No copying of Siemens manual text, figures or examples. Link to public Siemens KB articles instead.
- **Third-party components:** verify and record the licences of Wacl, Tcl (BSD-style), Starlight/Astro (MIT) and KaTeX (MIT) in `docs/third-party.md`. KLayout (GPL) is **not bundled**; learners install it themselves.
- No tracking or analytics in v1. Progress stays in the learner's browser.
- **AI-assistance disclosure** on the About page and in the site footer: the course was produced with AI tools (Claude) as part of a VLSI course project, and every published page has been reviewed by a named human (frontmatter `reviewed_by`).
- **Honest sourcing:** every lesson lists its sources; the About page aggregates them.

---

## 15. Build, CI & deployment

### 15.1 Workflows
- **`ci.yml`** (on every PR and push):
  1. `npm ci && npm run build`
  2. Content schema validation (frontmatter, quizzes, glossary)
  3. Link validation
  4. Snippet tests on Tcl 8.6 and Tcl 9.0 (§15.2)
  5. DRV-Lite test suite on Tcl 8.6 and Tcl 9.0
  6. Lab tests run against the private reference solutions (only when that repository is available; otherwise skipped with a warning)
- **`deploy.yml`:** on push to `main`, build and deploy to GitHub Pages using the official Pages actions. Pages source = GitHub Actions.

### 15.2 Snippet testing
- `scripts/extract-snippets` collects every ```` ```tcl run ```` block and every `predict-output` quiz item into `snippets/<page-id>/<n>.tcl` with its expected output.
- `scripts/run-snippets.tcl` executes each with a timeout (blocks tagged `drvlite` get DRV-Lite preloaded) and compares stdout exactly (after trimming trailing whitespace).
- CI runs it on **both** Tcl 8.6 and 9.0. A mismatch between versions fails CI unless the block is inside a `<VersionNote>` that declares per-version expected outputs.

### 15.3 Performance budgets
- Lesson page without the playground loaded: **< 150 KB JS**, LCP < 2.5 s on a mid-range phone.
- Wacl loads only on first Run (lazy), with a progress indicator.
- Lighthouse accessibility score ≥ 95 on the lesson template.

---

## 16. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Wacl is old (Tcl 8.6.6) or unmaintained | Playground breaks or lacks features | Keep M10 to features present in 8.6.6. Wrap the interpreter behind a `TclRuntime` interface so it can be swapped for the LiveCodes embed or a newer Tcl→WASM build |
| Calibre syntax drifts from DRV-Lite | Learners mislearn | ✅/⚠️ badges; command-status page; invite verified corrections via GitHub issues template "Calibre syntax correction" |
| Pure-Tcl booleans are slow or buggy | Labs fail | Manhattan-only scope; small lab datasets; strong tests; KLayout as the reference |
| Content quality drifts across 80 lessons | Inconsistent course | Golden week (Phase 2) as the benchmark; a per-lesson checklist in the PR template |
| Beginners stall at install (Week 11) | Drop-off | Step-by-step guide with screenshots for each OS; self-check `puts [info patchlevel]`; playground fallback |
| The RDB format is not accepted by KLayout | M40 labs blocked | Writer B (`.lyrdb`) as a guaranteed fallback |

---

## 17. Delivery phases & acceptance criteria

Claude Code: complete one phase, verify its criteria, **stop for human review**.

| Phase | Scope | Acceptance criteria |
|---|---|---|
| **P0 — Foundation** | Repo scaffold (§5), Astro + Starlight, `CLAUDE.md`, licences, README, CI + deploy workflows, PR and issue templates, `docs/` checklists, empty sitemap pages for all 40 weeks (with "Draft" banner) | Site builds and deploys to GitHub Pages; CI green; sidebar shows M10–M40 with all weeks |
| **P1 — Core components** | `LessonMeta`, `Goals`, `ChipStory`, `TclPlayground` (Wacl), `PredictOutput`, `WorkedExample`, `FadedExample`, `Trap`, `Quiz` (all types), `CheatCard`, `Hints`, `GlossaryTerm`, `VersionNote`, `RunWhere`, `ProgressTracker`, `Flashcards`; snippet + quiz validation scripts | A demo page uses every component; keyboard-only walkthrough works; snippet tests run in CI on 8.6 + 9.0 |
| **P2 — Golden week** | Full Week 3 (Lesson A, Lesson B, lab with tests, 25-item quiz bank, cheat cards, glossary entries) + `/start-here/` | Human review sign-off on tone, depth and accuracy; all §6.3 sections present; all snippets pass |
| **P3 — M10** | Weeks 1–2 and 4–10, capstone, exam, M10 overview | Every week complete per template; capstone grader works in the browser |
| **P4 — M20** | `/setup/` install guide, Weeks 11–20, capstone, exam | Labs pass with reference solutions on 8.6 + 9.0; `RunWhere` correctly disables the browser tab where needed |
| **P5 — DRV-Lite core (everything M30 needs)** | Built from the TinyLayout reference solution: layout handle, `layout create ?file.gds?`, cells, layers, polygons, text, wires, refs with transforms (rotate/mirror/magnify), `gdsout` + **GDS writer and reader**, `svg`, iterators (`ref`, `poly`), `bbox`, **Manhattan booleans AND/OR/NOT/XOR + SIZE**, launcher, `LayoutCanvas`, `RealCalibre`, `ChipScience`, `.lyp` palette | DRV-Lite tests pass on 8.6 + 9.0 and in Wacl; GDS round-trip byte-identical; generated GDS opens in KLayout (manual check, screenshot in PR); boolean results match KLayout on the Week 29 dataset (manual check); canvas renders the Week 23 examples in the browser |
| **P6 — M30** | Weeks 21–30, capstone, exam, `/reference/calibre-status/` page | Every Calibre command shown has a status badge; capstone XOR auto-check works; every week's examples run in `<LayoutCanvas>` |
| **P7 — DRV-Lite advanced (M40 additions)** | Metadata queries (`cells`, `layers`, `topcell`), units API, flatten, off-grid detection, RDB writers (simplified ASCII + `.lyrdb`) and readers, defect-GDS generator, HTML report helper | Unit, flatten and RDB tests pass; both RDB formats import into KLayout's marker browser (manual check); the defect generator is reproducible (fixed seed) |
| **P8 — M40** | Weeks 31–40, Layout Auditor capstone + defect datasets, final exam, portfolio guide | Auditor grader detects all planted defects in the reference solution with zero false positives |
| **P9 — Polish** | Accessibility pass, performance budgets, full link check, glossary completeness, About/sources pages | Lighthouse a11y ≥ 95; budgets met; no broken links; every glossary term used is defined |

**Model guidance (optional):** component and infrastructure phases (P0, P1, P5, P7, P9) suit Claude Sonnet in Claude Code. Content-heavy phases (P2, P3, P4, P6, P8) benefit from Claude Opus for technical accuracy and pedagogy. Human review of content is required regardless of model.

---

## 18. Open items

| ID | Question | Default if unanswered |
|---|---|---|
| O1 | Final site name | "Tcl to Tapeout" |
| O2 | Site language(s) | English only in v1; content structure must not block a later i18n (Starlight supports it) |
| O3 | Where reference solutions live | A separate private repo `tcl-to-tapeout-solutions` |
| O4 | ~~Calibre access~~ **Decided:** no licence, no manual. | If access appears later, a verified correction moves a command from ⚠️ to ✅ via the `calibre-syntax-correction` issue template, with the source recorded |
| O5 | Use of an open-source PDK layout (e.g. a public 130 nm design) for the Week 21 KLayout tour | Use a DRV-Lite-generated sample first; add an open PDK example only after licence review |

---

## 19. References (from the design session)

**Tcl**
- Tcl/Tk 9.0 release notes: https://www.tcl-lang.org/software/tcltk/9.0.html
- Dodekalogue (Tcler's Wiki): https://wiki.tcl-lang.org/10259
- Official Tcl tutorial: https://www.tcl-lang.org/man/tcl8.5/tutorial/Tcl0.html
- `chan` (Tcl 9.0) man page: https://dyn.manpages.debian.org/experimental/tcl9.0-doc/chan.3tcl
- `oo::class` (Tcl 8.6) man page: https://docs.activestate.com/activetcl/8.6/tcl/TclCmd/class.html
- Magicsplat — OO in Tcl: https://magicsplat.com/articles/oo.html
- Magicsplat Tcl/Tk for Windows: https://magicsplat.com/tcl-installer
- Wacl (Tcl → WebAssembly): https://github.com/ecky-l/wacl
- LiveCodes Tcl (Wacl-based): https://next.livecodes.io/docs/languages/tcl

**Calibre DESIGNrev (public sources)**
- Siemens KB — Print cell hierarchy path (`$L iterator ref`, batch `calibredrv script.tcl`): https://support.sw.siemens.com/en-US/okba/KB000129095_EN_US/How-to-Print-Cell-Hierarchy-Path-with-Calibre-DESIGNrev-Scripting/media/How_to_Print_Cell_Hierarchy_path_000129095.pdf
- Siemens KB — Find and insert text on a layer (`$L iterator poly`, `$L query text`): https://support.sw.siemens.com/en-US/okba/KB000122456_EN_US/How-to-Find-and-Insert-Text-on-a-Layer-Using-a-Calibre-DESIGNrev-Script/media/How_to_Find_and_Insert_Text_on_a_Layer_Using_a_Calibre_DESIGNrev_Script_000122456.pdf
- Siemens Community — `$L create text` and invalid layer: https://community.sw.siemens.com/s/question/0D5Vb000005G4CwKAK/in-calibre-designrev-when-i-use-the-statement-l-create-text-can-i-use-a-layer-that-does-not-exist-in-gds
- Siemens — DESIGNrev product page: https://eda.sw.siemens.com/en-US/ic/calibre-design/interfaces/designrev/
- Siemens Xcelerator Academy — DESIGNrev Scripting course: https://training.plm.automation.siemens.com/ilt/iltdescription.cfm?pID=253409-TW_____EDA__2014.4_1188
- EDAboard — `layout create`, `create cell/layer/polygon`, `gdsout`: https://www.edaboard.com/threads/learning-to-generate-tcl-script-to-generate-gds-for-calibredrv.245088/
- Dummy-fill script example (`gds out` spelling): https://icode.best/i/69290547997693
- Electronic Design — splitting DRC/ERC errors (`iterator ref`): https://www.electronicdesign.com/technologies/embedded/digital-ics/fpga/article/21793728/programmed-splitting-of-full-chip-calibre-drc-erc-errors-into-sub-block-space
- LVS Debug Solutions — `AND` syntax: https://lvs-debug-solutions.com/calibre_papers

**GDSII, KLayout, RDB**
- KLayout overview (Efabless catalog): https://platform.efabless.com/design_catalog/tools/13
- KLayout Marker Browser (imports Calibre DRC ASCII): https://www.klayout.de/doc/manual/marker_browser.html
- KLayout RDB (`.lyrdb`) format: https://www.klayout.de/rdb_format.html
- KLayout forum — Calibre RDB structure: https://www.klayout.de/forum/discussion/237/issue-during-loading-calibres-rdb-files
- KLayout DRC layer booleans: https://klayout.de/doc/about/drc_ref_layer.html
- GDSII UNITS record: https://docs.rs/gds21/latest/i686-unknown-linux-gnu/struct.GdsUnits.html
- GDSII stream format appendix: https://www.klayout.de/forum/uploads/editor/v2/k4lfi69nrv9k.pdf

**Learning science**
- Dunlosky et al. (2013), APS summary: https://www.psychologicalscience.org/news/releases/which-study-strategies-make-the-grade.html
- Dunlosky et al. (2013), technique ratings summary: https://texasldcenter.org/?p=346
- Sweller — cognitive load teaching strategies: https://www.teachermagazine.com.au/articles/cognitive-load-theory-teaching-strategies
- Worked-example effect: https://en.wikipedia.org/wiki/Worked-example_effect
- Kalyuga et al. — when problem solving beats worked examples: https://www.academia.edu/1405548/When_problem_solving_is

**Site stack**
- Astro Starlight → GitHub Pages template: https://github.com/30DaysOf/astro-starlight-ghpages
- Starlight docs hosting overview: https://docs.railway.com/guides/host-documentation-site
