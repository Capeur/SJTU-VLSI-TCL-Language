// Teaching layer palette — PRD §13.3. Keep in sync with labs/common/teaching-layers.lyp.
// These are teaching layer numbers, not any foundry's.
export const layers = [
  { name: 'ACTIVE', gds: '1.0', light: '#2e9e4f', dark: '#4fd176' },
  { name: 'POLY', gds: '2.0', light: '#d62828', dark: '#ff6b6b' },
  { name: 'CONTACT', gds: '3.0', light: '#111111', dark: '#f2f2f2' },
  { name: 'METAL1', gds: '4.0', light: '#1d5fd1', dark: '#6ea2ff' },
  { name: 'VIA1', gds: '5.0', light: '#7a7a7a', dark: '#a8a8a8' },
  { name: 'METAL2', gds: '6.0', light: '#c2189b', dark: '#ff6fd8' },
  { name: 'TEXT', gds: '63.0', light: 'currentColor', dark: 'currentColor' },
  { name: 'DERIVED', gds: '100.0', light: '#e8860c', dark: '#ffa940', hatched: true },
] as const;
