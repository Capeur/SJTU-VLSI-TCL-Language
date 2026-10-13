# Third-party components

| Component | Use | Licence | Status |
|---|---|---|---|
| Astro | Site framework | MIT | To confirm against installed package at release |
| Starlight | Docs theme | MIT | To confirm |
| starlight-links-validator | Link checking | MIT | To confirm |
| remark-math, rehype-katex | Math rendering | MIT | To confirm |
| KaTeX | Math rendering | MIT | To confirm |
| Tcl/Tk | Language runtime | BSD-style (Tcl licence) | Not bundled in P0 |
| Wacl (Tcl→WASM) | In-browser Tcl, self-hosted in `public/wacl/` | **To verify before bundling (P1)** | Not yet added |
| KLayout | Layout viewer | GPL | **Not bundled**; learners install it themselves |

Licences must be verified from each package's own LICENSE file when it is added (run `npm ls` / inspect `node_modules/*/LICENSE`).
