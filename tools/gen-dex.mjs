// Generates app/assets/data/dex.json and moves.json from @pkmn/dex.
// Run from tools/: npm install && npm run gen-data
import { Dex } from '@pkmn/dex';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(here, '../app/assets/data');
const excluded = new Set(['CAP', 'Custom', 'Future']);

const species = Dex.species
  .all()
  .filter((s) => s.exists && s.num > 0 && s.num <= 1025)
  .filter((s) => !s.forme && !excluded.has(s.isNonstandard))
  .map((s) => ({
    num: s.num,
    name: s.name,
    types: s.types,
    baseStats: s.baseStats,
    gen: s.gen,
    abilities: { normal: s.abilities[0] ?? null, hidden: s.abilities.H ?? null },
  }))
  .sort((a, b) => a.num - b.num);

const moves = Dex.moves
  .all()
  .filter((m) => m.exists && m.num > 0 && !excluded.has(m.isNonstandard))
  .map((m) => ({
    name: m.name,
    type: m.type,
    category: m.category,
    power: m.basePower || 0,
    accuracy: typeof m.accuracy === 'number' ? m.accuracy : null,
    pp: m.pp,
    priority: m.priority || 0,
  }))
  .sort((a, b) => a.name.localeCompare(b.name));

mkdirSync(outDir, { recursive: true });
writeFileSync(resolve(outDir, 'dex.json'), JSON.stringify(species));
writeFileSync(resolve(outDir, 'moves.json'), JSON.stringify(moves));
console.log(
  `wrote ${species.length} species and ${moves.length} moves to ${outDir}`,
);
