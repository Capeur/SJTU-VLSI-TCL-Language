# Peer review checklist (M40 pull requests)

- [ ] Correct: the lab's acceptance tests pass (`RESULT: PASS n/n`)
- [ ] Naming is descriptive and consistent
- [ ] Errors are handled (`try`/`catch`), with clear messages
- [ ] Comments explain *why*, not *what*
- [ ] Units: computation in integer dbu, display in µm
- [ ] Results databases import into KLayout's marker browser
- [ ] No hard-coded paths; arguments parsed from `argv`
