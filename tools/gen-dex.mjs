// Generates app/assets/data/dex.json, moves.json and zones.json.
//
// Sources:
//  - @pkmn/dex (the data behind Pokémon Showdown): stats, types, abilities,
//    learnsets and evolution rules.
//  - PokeAPI CSV dumps: catch rate, base exp, growth rate, legendary flags.
//  - ItzFallenMe/pokemon-data.json: flavour text, genus, height, weight and
//    human-readable evolution conditions.
//
// Run from tools/: npm install && npm run gen-data
// The downloads are cached in tools/.cache, so reruns work offline.
import { Dex } from '@pkmn/dex';
import {
  createWriteStream,
  existsSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
} from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(here, '../app/assets/data');
const cacheDir = resolve(here, '.cache');
const SOURCES = {
  species:
    'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon_species.csv',
  pokemon:
    'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon.csv',
  names:
    'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon_species_names.csv',
  flavor:
    'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon_species_flavor_text.csv',
  extras:
    'https://raw.githubusercontent.com/ItzFallenMe/pokemon-data.json/master/pokedex.json',
};

mkdirSync(outDir, { recursive: true });
mkdirSync(cacheDir, { recursive: true });
Dex.includeData();

async function download(name, url) {
  const file = resolve(cacheDir, name);
  if (existsSync(file) && readFileSync(file).length > 1000) return file;
  process.stdout.write(`downloading ${name}… `);
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${url} → HTTP ${response.status}`);
  const body = Buffer.from(await response.arrayBuffer());
  await new Promise((done, fail) => {
    const stream = createWriteStream(file);
    stream.on('error', fail);
    stream.end(body, done);
  });
  console.log(`${Math.round(body.length / 1024)} KB`);
  return file;
}

/** Minimal RFC 4180 parser: handles quotes, embedded commas and newlines. */
function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;
  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    if (quoted) {
      if (char === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i += 1;
        } else {
          quoted = false;
        }
      } else {
        field += char;
      }
    } else if (char === '"') {
      quoted = true;
    } else if (char === ',') {
      row.push(field);
      field = '';
    } else if (char === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else if (char !== '\r') {
      field += char;
    }
  }
  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  return rows;
}

function table(file) {
  const rows = parseCsv(readFileSync(file, 'utf8'));
  const header = rows[0];
  return rows.slice(1).map((values) => {
    const entry = {};
    header.forEach((key, index) => {
      entry[key] = values[index];
    });
    return entry;
  });
}

const files = {};
for (const [name, url] of Object.entries(SOURCES)) {
  files[name] = await download(name, url);
}

const speciesRows = table(files.species);
const pokemonRows = table(files.pokemon);
const nameRows = table(files.names);
const flavorRows = table(files.flavor);
const extras = JSON.parse(readFileSync(files.extras, 'utf8'));

const catchRates = new Map();
const baseExp = new Map();
const growthRates = new Map();
const legendary = new Map();
const mythical = new Map();
const growthNames = {
  1: 'slow',
  2: 'medium',
  3: 'fast',
  4: 'medium-slow',
  5: 'slow',
  6: 'erratic',
};
for (const row of speciesRows) {
  const num = Number(row.id);
  catchRates.set(num, Number(row.capture_rate) || 45);
  legendary.set(num, row.is_legendary === '1');
  mythical.set(num, row.is_mythical === '1');
  growthRates.set(num, growthNames[Number(row.growth_rate_id)] ?? 'medium');
}
for (const row of pokemonRows) {
  if (row.is_default !== '1') continue;
  baseExp.set(Number(row.species_id), Number(row.base_experience) || 0);
}

const englishNames = new Map();
for (const row of nameRows) {
  if (row.local_language_id !== '9') continue;
  englishNames.set(Number(row.pokemon_species_id), {
    genus: row.genus,
  });
}

// Latest English flavour text per species. The ItzFallenMe dataset is one
// clean paragraph per Pokémon and wins when it has an entry.
const flavour = new Map();
for (const row of flavorRows) {
  if (row.language_id !== '9') continue;
  const num = Number(row.species_id);
  const version = Number(row.version_id);
  const previous = flavour.get(num);
  if (!previous || version >= previous.version) {
    const text = row.flavor_text.replace(/[\n\r\f]+/g, ' ').replace(/\s+/g, ' ').trim();
    flavour.set(num, { version, text });
  }
}

const extraById = new Map();
for (const entry of extras) {
  const num = Number(entry.id);
  if (!Number.isInteger(num)) continue;
  extraById.set(num, entry);
}

const excluded = new Set(['CAP', 'Custom', 'Future']);

function clean(text) {
  return String(text ?? '')
    .replace(/[\u000c]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function evolutionLabel(evo, extrasEntry) {
  // Prefer the human-readable condition from the community dataset.
  const wanted = String(evo.num);
  const next = extrasEntry?.evolution?.next;
  if (Array.isArray(next)) {
    for (const pair of next) {
      if (Array.isArray(pair) && String(pair[0]) === wanted && pair[1]) {
        return String(pair[1]);
      }
    }
  }
  if (evo.method === 'level-up' && evo.level) return `Level ${evo.level}`;
  if (evo.method === 'use-item' && evo.item) return `Use ${evo.item}`;
  if (evo.method === 'trade') return 'Trade';
  if (evo.method === 'friendship') return 'High friendship';
  return 'Special condition';
}

function evolutionFor(species, extrasEntry) {
  const evolutions = [];
  for (const name of species.evos ?? []) {
    const target = Dex.species.get(name);
    if (!target.exists || target.num !== Math.floor(target.num)) continue;
    let method = 'special';
    let level = null;
    let item = null;
    if (typeof target.evoLevel === 'number') {
      method = 'level-up';
      level = target.evoLevel;
    } else if (target.evoType === 'useItem' && target.evoItem) {
      method = 'use-item';
      item = target.evoItem;
    } else if (target.evoType === 'trade') {
      method = 'trade';
    } else if (
      target.evoType === 'levelFriendship' ||
      target.evoType === 'levelFriendshipDay' ||
      target.evoType === 'levelFriendshipNight'
    ) {
      method = 'friendship';
    } else if (target.evoType === 'levelHold' && target.evoItem) {
      method = 'level-hold';
      item = target.evoItem;
    } else if (target.evoType?.startsWith('level')) {
      method = 'level-up';
    }

    const evo = {
      to: target.num,
      name: target.name,
      method,
      level,
      item,
      condition: '',
    };
    evo.condition = evolutionLabel(evo, extrasEntry);
    evolutions.push(evo);
  }
  return evolutions;
}

function levelUpMoves(learnset) {
  if (!learnset) return [];
  const byLevel = new Map();
  for (const [moveId, sources] of Object.entries(learnset)) {
    let best = null;
    for (const source of sources) {
      const match = /^(\d)L(\d+)$/.exec(source);
      if (!match) continue;
      const gen = Number(match[1]);
      const level = Number(match[2]);
      if (!best || gen > best.gen || (gen === best.gen && level < best.level)) {
        best = { gen, level };
      }
    }
    if (!best) continue;
    if (best.level > 100) continue;
    const move = Dex.moves.get(moveId);
    if (!move.exists) continue;
    const level = best.level === 0 ? 1 : best.level;
    const previous = byLevel.get(move.name);
    if (previous == null || level < previous) byLevel.set(move.name, level);
  }
  return [...byLevel.entries()]
    .map(([name, level]) => ({ name, level }))
    .sort((a, b) => a.level - b.level || a.name.localeCompare(b.name));
}

const species = [];
for (const entry of Dex.species.all()) {
  if (!entry.exists || entry.num <= 0 || entry.num > 1025) continue;
  if (entry.forme) continue;
  if (excluded.has(entry.isNonstandard)) continue;
  const num = entry.num;
  if (species.some((other) => other.num === num)) continue;

  const extra = extraById.get(num);
  const nameRow = englishNames.get(num);
  const learn = await Dex.learnsets.get(entry.id);
  const description =
    clean(extra?.description) ||
    clean(flavour.get(num)?.text) ||
    clean(entry.shortDesc) ||
    '';
  const evolutions = evolutionFor(entry, extra);

  species.push({
    num,
    name: entry.name,
    slug: entry.id,
    types: entry.types,
    baseStats: entry.baseStats,
    gen: entry.gen,
    abilities: {
      normal: entry.abilities[0] ?? null,
      hidden: entry.abilities.H ?? null,
    },
    catchRate: catchRates.get(num) ?? 45,
    baseExp: baseExp.get(num) ?? 0,
    growthRate: growthRates.get(num) ?? 'medium',
    height: extra?.profile?.height ?? null,
    weight: extra?.profile?.weight ?? null,
    genus: clean(extra?.species) || clean(nameRow?.genus) || '',
    description,
    legendary: legendary.get(num) ?? false,
    mythical: mythical.get(num) ?? false,
    evolvesFrom: entry.prevo ?? null,
    evolutions,
    moves: levelUpMoves(learn.learnset),
  });
}

species.sort((a, b) => a.num - b.num);

const moves = Dex.moves
  .all()
  .filter((move) => move.exists && move.num > 0 && !excluded.has(move.isNonstandard))
  .map((move) => ({
    name: move.name,
    type: move.type,
    category: move.category,
    power: move.basePower || 0,
    accuracy: typeof move.accuracy === 'number' ? move.accuracy : null,
    pp: move.pp,
    priority: move.priority || 0,
    description: clean(move.shortDesc) || clean(move.desc) || '',
  }))
  .sort((a, b) => a.name.localeCompare(b.name));

// ---------------------------------------------------------------------------
// Zones: built by type from the real dex, with rarity from catch rate / BST.
// ---------------------------------------------------------------------------

const ZONE_DEFS = [
  {
    slug: 'verdant-route',
    name: 'Verdant Route',
    subtitle: 'Sunlit grass and buzzing hedgerows',
    types: ['Grass', 'Bug', 'Normal', 'Fairy'],
    levels: [3, 9],
    accent: ['#2FA36B', '#A8E063'],
    icon: 'forest',
  },
  {
    slug: 'ember-ridge',
    name: 'Ember Ridge',
    subtitle: 'Ash, cinders and warm stone',
    types: ['Fire', 'Rock', 'Ground', 'Fighting'],
    levels: [8, 16],
    accent: ['#D94F2B', '#F7B267'],
    icon: 'volcano',
  },
  {
    slug: 'tidal-cove',
    name: 'Tidal Cove',
    subtitle: 'Salt spray and shallow reefs',
    types: ['Water', 'Ice', 'Flying'],
    levels: [12, 20],
    accent: ['#1889C9', '#6EDCD9'],
    icon: 'waves',
  },
  {
    slug: 'hollow-cavern',
    name: 'Hollow Cavern',
    subtitle: 'Echoes, moss and old steel',
    types: ['Poison', 'Ghost', 'Dark', 'Steel'],
    levels: [16, 26],
    accent: ['#5B4B8A', '#9A8CFF'],
    icon: 'cave',
  },
  {
    slug: 'storm-plateau',
    name: 'Storm Plateau',
    subtitle: 'Charged air above the clouds',
    types: ['Electric', 'Dragon', 'Flying', 'Steel'],
    levels: [22, 34],
    accent: ['#3560D4', '#7BD3FF'],
    icon: 'storm',
  },
  {
    slug: 'spirit-marsh',
    name: 'Spirit Marsh',
    subtitle: 'Mist, lanterns and whispered legends',
    types: ['Psychic', 'Ghost', 'Fairy', 'Poison'],
    levels: [28, 40],
    accent: ['#8E3FA8', '#F07AB4'],
    icon: 'mist',
  },
];

// Small deterministic PRNG so regenerating does not reshuffle every pool.
function mulberry32(seed) {
  let value = seed >>> 0;
  return () => {
    value += 0x6d2b79f5;
    let t = value;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick(pool, count, random) {
  const copy = [...pool];
  const chosen = [];
  while (copy.length > 0 && chosen.length < count) {
    chosen.push(copy.splice(Math.floor(random() * copy.length), 1)[0]);
  }
  return chosen;
}

function rarityOf(entry) {
  if (entry.legendary || entry.mythical) return 'legendary';
  if (entry.baseStats && Object.values(entry.baseStats).reduce((a, b) => a + b, 0) >= 600) {
    return 'epic';
  }
  if (entry.catchRate <= 25) return 'epic';
  if (entry.catchRate <= 60) return 'rare';
  if (entry.catchRate <= 120) return 'uncommon';
  return 'common';
}

const zones = ZONE_DEFS.map((zone, zoneIndex) => {
  const random = mulberry32(1000 + zoneIndex * 97);
  const candidates = species.filter(
    (entry) =>
      !entry.legendary &&
      !entry.mythical &&
      entry.types.some((type) => zone.types.includes(type)) &&
      entry.baseStats.hp + entry.baseStats.atk + entry.baseStats.def > 120,
  );
  const buckets = { common: [], uncommon: [], rare: [], epic: [] };
  for (const entry of candidates) {
    const rarity = rarityOf(entry);
    if (buckets[rarity]) buckets[rarity].push(entry);
  }
  const spawns = [];
  const counts = { common: 12, uncommon: 9, rare: 6, epic: 3 };
  for (const [rarity, count] of Object.entries(counts)) {
    for (const entry of pick(buckets[rarity], count, random)) {
      spawns.push({
        num: entry.num,
        rarity,
        weight:
          rarity === 'common'
            ? 40
            : rarity === 'uncommon'
              ? 22
              : rarity === 'rare'
                ? 9
                : 2,
      });
    }
  }
  return {
    slug: zone.slug,
    name: zone.name,
    subtitle: zone.subtitle,
    types: zone.types,
    levels: zone.levels,
    accent: zone.accent,
    icon: zone.icon,
    spawns,
  };
});

const payload = {
  version: 3,
  generatedAt: new Date().toISOString().slice(0, 10),
  species,
};

writeFileSync(resolve(outDir, 'dex.json'), JSON.stringify(payload));
writeFileSync(resolve(outDir, 'moves.json'), JSON.stringify(moves));
writeFileSync(resolve(outDir, 'zones.json'), JSON.stringify(zones));

const missingDescription = species.filter((entry) => !entry.description).length;
const missingMoves = species.filter((entry) => entry.moves.length < 2).length;
console.log(
  `wrote ${species.length} species, ${moves.length} moves, ${zones.length} zones to ${outDir}\n` +
    `descriptions missing: ${missingDescription} · learnsets with <2 moves: ${missingMoves}`,
);
for (const zone of zones) {
  const rarity = {};
  for (const spawn of zone.spawns) rarity[spawn.rarity] = (rarity[spawn.rarity] ?? 0) + 1;
  console.log(`  ${zone.name}: ${JSON.stringify(rarity)}`);
}
