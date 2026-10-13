# Tcl to Tapeout

A free, static, open-source 40-week course (~3 h/week) that takes a complete beginner from **Tcl** to **VLSI layout scripting** in the style of Calibre DESIGNrev, using **DRV-Lite** (a teaching simulator written in pure Tcl) and **KLayout**. No commercial licence needed.

> **Status:** Phase P0 (foundation). The site structure for all 40 weeks exists; lesson content arrives in later phases. See `PRD.md` §17.

> DRV-Lite is an independent educational simulator. It is not affiliated with, endorsed by, or a replacement for Siemens EDA Calibre®. Calibre and DESIGNrev are trademarks of Siemens. Command forms marked ⚠️ are approximations for learning.

## Run locally
```bash
npm ci
npm run dev        # http://localhost:4321/SJTU-VLSI-TCL-Language/
npm run build      # also validates internal links
npm run preview
```
Requires Node 20+ (developed on Node 24).

## Layout
See `PRD.md` §5. In short: `src/` (site), `drvlite/` (engine), `labs/` (lab specs + tests), `scripts/`, `docs/`.
`npm run gen:skeleton` regenerates placeholder pages (it never overwrites edited ones).

## Deploy
Pushing to `main` runs `.github/workflows/deploy.yml`. In the repository settings, set **Pages → Source = GitHub Actions**.

## Contributing
Read `CLAUDE.md`, `docs/style-guide.md` and `docs/lesson-checklist.md`. Content errors and verified Calibre syntax corrections have issue templates.
All AI-assisted content must be reviewed by a named human before the Draft banner is removed.

## Licences
Code: MIT (`LICENSE`). Content: CC BY-SA 4.0 (`LICENSE-CONTENT`). Third-party: `docs/third-party.md`.
