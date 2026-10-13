# Third-party components

| Component | Use | Licence | Status |
|---|---|---|---|
| Astro | Site framework | MIT | To confirm against installed package at release |
| Starlight | Docs theme | MIT | To confirm |
| starlight-links-validator | Link checking | MIT | To confirm |
| remark-math, rehype-katex | Math rendering | MIT | To confirm |
| KaTeX | Math rendering | MIT | To confirm |
| Tcl/Tk | Language runtime | BSD-style (Tcl licence) | Not bundled in P0 |
| Wacl (Tcl→WASM) | In-browser Tcl 8.6.6, self-hosted in `public/wacl/` (prebuilt 2017 release from <https://ecky-l.github.io/wacl/releases/wacl.zip>; `LICENSE` copied alongside) | BSD-3-Clause (verified from the repo's LICENSE file and GitHub licence metadata) | Bundled in P1. Contains Tcl itself (BSD-style) and Emscripten runtime code (MIT/UIUC) |
| Preact, @astrojs/preact | Interactive component islands | MIT | To confirm against installed package at release |
| yaml, zod | Quiz/glossary parsing and validation | ISC (yaml), MIT (zod) | To confirm |
| KLayout | Layout viewer | GPL | **Not bundled**; learners install it themselves |

Licences must be verified from each package's own LICENSE file when it is added (run `npm ls` / inspect `node_modules/*/LICENSE`).
