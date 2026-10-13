// Single source of truth for week titles (PRD §9). Used by the skeleton generator and the sidebar.
export const milestones = {
  m10: { title: 'M10 — Tcl Syntax Core', weeks: [1, 10], capstone: 'Mini Floorplan Checker', runs: 'playground' },
  m20: { title: 'M20 — Fluency & OOP', weeks: [11, 20], capstone: 'TinyLayout', runs: 'terminal' },
  m30: { title: 'M30 — DESIGNrev Core via DRV-Lite', weeks: [21, 30], capstone: 'Cell Generator', runs: 'drvlite' },
  m40: { title: 'M40 — Batch Encyclopedia via DRV-Lite', weeks: [31, 40], capstone: 'Layout Auditor', runs: 'drvlite' },
};

export const weekThemes = {
  1: 'Hello, chip', 2: 'Tcl as a calculator', 3: 'The quoting week', 4: 'Decisions & loops',
  5: 'Lists I', 6: 'Lists II', 7: 'Your own commands', 8: 'Text handling', 9: 'Tables of data',
  10: 'When things go wrong', 11: 'Real Tcl & introspection', 12: 'Files I', 13: 'Files II',
  14: 'Other programs', 15: 'Regex I', 16: 'Regex II & time', 17: 'Namespaces', 18: 'TclOO I',
  19: 'TclOO II', 20: 'Capstone', 21: 'From chip to drawing', 22: 'Layers & coordinates',
  23: 'Polygons', 24: 'Wires & labels', 25: 'Save, load, batch', 26: 'Hierarchy I',
  27: 'Hierarchy II', 28: 'Iterators & queries', 29: 'Boolean geometry', 30: 'Capstone',
  31: 'Units & grids', 32: 'Coordinates through hierarchy', 33: 'Metadata inspection',
  34: 'Industrial batch scripting', 35: 'Results databases I', 36: 'Results databases II',
  37: 'Writing checks I', 38: 'Writing checks II', 39: 'Audit framework', 40: 'Capstone',
};
