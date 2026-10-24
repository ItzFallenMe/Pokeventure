// Runs one real Showdown random battle, bot vs bot, and prints the protocol.
// Usage: node server/scripts/battle-smoke.mjs
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const {
  BattleStream,
  Dex,
  Teams,
  getPlayerStreams,
} = require('../../vendor/pokemon-showdown/dist/sim/index.js');

const formatId = process.argv[2] ?? 'gen9randombattle';

const stream = new BattleStream();
const streams = getPlayerStreams(stream);

function pickChoice(request) {
  if (request.teamPreview) return 'team 123456';

  if (request.forceSwitch?.some(Boolean)) {
    const slot = request.side.pokemon.findIndex(
      (mon) => !mon.condition.endsWith(' fnt') && mon.active === false,
    );
    return slot >= 0 ? `switch ${slot + 1}` : 'pass';
  }

  const active = request.active?.[0];
  if (!active) return 'pass';

  const usable = active.moves
    .map((move, index) => ({ move, index }))
    .filter(({ move }) => !move.disabled && move.pp > 0);

  if (usable.length > 0) {
    const pick = usable[Math.floor(Math.random() * usable.length)];
    return `move ${pick.index + 1}`;
  }
  return 'move 1';
}

async function playSide(sideStream, label) {
  for await (const chunk of sideStream) {
    for (const line of chunk.split('\n')) {
      if (!line.startsWith('|request|')) continue;
      const request = JSON.parse(line.slice('|request|'.length));
      if (request.wait) continue;
      const choice = pickChoice(request);
      sideStream.write(choice);
      console.log(`[${label}] ${choice}`);
    }
  }
}

let turns = 0;
let winner = null;

const spectator = (async () => {
  for await (const chunk of streams.omniscient) {
    for (const line of chunk.split('\n')) {
      if (line.startsWith('|turn|')) turns = Number(line.slice(7));
      if (line.startsWith('|win|')) winner = line.slice(5);
    }
  }
})();

const spec = { formatid: formatId };
const p1 = { name: 'Bot A', team: Teams.pack(Teams.generate(formatId)) };
const p2 = { name: 'Bot B', team: Teams.pack(Teams.generate(formatId)) };

streams.omniscient.write(
  `>start ${JSON.stringify(spec)}\n` +
    `>player p1 ${JSON.stringify(p1)}\n` +
    `>player p2 ${JSON.stringify(p2)}`,
);

await Promise.all([
  spectator,
  playSide(streams.p1, 'p1'),
  playSide(streams.p2, 'p2'),
]);

console.log(JSON.stringify({ format: Dex.formats.get(formatId).id, turns, winner }));
