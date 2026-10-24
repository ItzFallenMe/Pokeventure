import { createRequire } from 'node:module';

/**
 * The vendored `smogon/pokemon-showdown` build is CommonJS and untyped, so it
 * is loaded through one narrow seam. Everything above this file uses our own
 * types.
 */
const require = createRequire(import.meta.url);

export interface ShowdownStreams {
  omniscient: ShowdownStream;
  p1: ShowdownStream;
  p2: ShowdownStream;
}

export interface ShowdownStream {
  write(data: string): void;
  writeEnd(): Promise<void>;
  [Symbol.asyncIterator](): AsyncIterator<string>;
}

interface ShowdownSim {
  BattleStream: new () => unknown;
  getPlayerStreams(stream: unknown): ShowdownStreams;
  Teams: {
    generate(format: string): unknown;
    pack(team: unknown): string;
  };
  Dex: {
    formats: { get(format: string): { id: string; name: string } };
  };
}

const sim = require('../../../vendor/pokemon-showdown/dist/sim/index.js') as ShowdownSim;

export const SUPPORTED_FORMATS = [
  'gen9randombattle',
  'gen8randombattle',
] as const;

export type SupportedFormat = (typeof SUPPORTED_FORMATS)[number];

export function isSupportedFormat(format: string): format is SupportedFormat {
  return (SUPPORTED_FORMATS as readonly string[]).includes(format);
}

export function createBattleStreams(): ShowdownStreams {
  return sim.getPlayerStreams(new sim.BattleStream());
}

export function generateTeam(format: string): string {
  return sim.Teams.pack(sim.Teams.generate(format));
}

export function formatName(format: string): string {
  return sim.Dex.formats.get(format).name;
}
