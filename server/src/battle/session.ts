import { randomUUID } from 'node:crypto';

import {
  createBattleStreams,
  generateTeam,
  type ShowdownStreams,
} from './engine.js';

export type BattleSide = 'p1' | 'p2';
export type BattleMode = 'ai' | 'friend';

export interface BattleSessionOptions {
  mode?: BattleMode;
  p1Name?: string;
  p2Name?: string;
}

export interface BattleMoveView {
  name: string;
  pp: number;
  maxPp: number;
  disabled: boolean;
}

export interface BattleMemberView {
  slot: number;
  species: string;
  level: number;
  condition: string;
  hp: number;
  status: string | null;
  active: boolean;
  fainted: boolean;
  /** True when this Pokémon must pick a fainted ally to revive. */
  reviving: boolean;
  moves: BattleMoveView[];
}

export interface BattleOpponentView {
  species: string;
  level: number;
  hp: number;
  condition: string;
  status: string | null;
  fainted: boolean;
}

export interface BattleSnapshot {
  id: string;
  side: BattleSide;
  format: string;
  turn: number;
  ended: boolean;
  winner: 'player' | 'opponent' | null;
  canAct: boolean;
  waiting: boolean;
  forceSwitch: boolean;
  player: {
    name: string;
    team: BattleMemberView[];
    active: BattleMemberView | null;
  };
  opponent: BattleOpponentView | null;
  log: string[];
}

interface Tracker {
  species: string;
  level: number;
  condition: string;
  hp: number;
  status: string | null;
  fainted: boolean;
}

const LOG_TYPES = new Set([
  'turn',
  'move',
  'switch',
  'drag',
  'damage',
  'heal',
  'faint',
  'status',
  'curestatus',
  'boost',
  'unboost',
  'weather',
  'fieldstart',
  'fieldend',
  'sidestart',
  'sideend',
  'crit',
  'supereffective',
  'resisted',
  'immune',
  'miss',
  'cant',
  'fail',
  'activate',
  'enditem',
  'endability',
  'win',
  'tie',
  'message',
  'teamsize',
]);

function cleanName(value: string | undefined, fallback: string): string {
  const cleaned = (value ?? '')
    .replace(/[|\n\r]/g, '')
    .trim()
    .slice(0, 20);
  return cleaned.length >= 2 ? cleaned : fallback;
}

export class BattleSession {
  readonly id = randomUUID();
  readonly format: string;
  readonly mode: BattleMode;
  readonly p1Name: string;
  readonly p2Name: string;
  readonly createdAt = Date.now();
  readonly ready: Record<BattleSide, Promise<void>>;

  private readonly streams: ShowdownStreams;
  private readonly requests: Record<BattleSide, any> = { p1: null, p2: null };
  private readonly versions: Record<BattleSide, number> = { p1: 0, p2: 0 };
  private readonly waiters: Record<BattleSide, Array<() => void>> = {
    p1: [],
    p2: [],
  };
  private readonly resolveReady: Record<BattleSide, () => void>;
  private turn = 0;
  private log: string[] = [];
  private trackers = new Map<string, Tracker>();
  private ended = false;
  private winnerSide: BattleSide | null = null;
  private tie = false;

  private constructor(format: string, options: BattleSessionOptions = {}) {
    this.format = format;
    this.mode = options.mode ?? 'ai';
    this.p1Name = cleanName(options.p1Name, 'Trainer');
    const fallbackP2 = this.mode === 'ai' ? 'AI Trainer' : 'Challenger';
    let p2Name = cleanName(options.p2Name, fallbackP2);
    if (p2Name === this.p1Name) p2Name = `${p2Name.slice(0, 18)} 2`;
    this.p2Name = p2Name;

    this.streams = createBattleStreams();

    let resolveP1 = () => {};
    let resolveP2 = () => {};
    this.ready = {
      p1: new Promise<void>((resolve) => {
        resolveP1 = resolve;
      }),
      p2: new Promise<void>((resolve) => {
        resolveP2 = resolve;
      }),
    };
    this.resolveReady = { p1: resolveP1, p2: resolveP2 };
  }

  static async create(
    format: string,
    options: BattleSessionOptions = {},
  ): Promise<BattleSession> {
    const session = new BattleSession(format, options);
    session.start();

    let timer: NodeJS.Timeout | undefined;
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(
        () => reject(new Error('Battle did not start within 5s')),
        5000,
      );
    });

    try {
      await Promise.race([session.ready.p1, timeout]);
    } finally {
      if (timer) clearTimeout(timer);
    }
    return session;
  }

  private start() {
    void this.consume(this.streams.p1, 'p1');
    void this.consume(this.streams.p2, 'p2');

    const spec = { formatid: this.format };
    const p1 = { name: this.p1Name, team: generateTeam(this.format) };
    const p2 = { name: this.p2Name, team: generateTeam(this.format) };

    this.streams.omniscient.write(
      `>start ${JSON.stringify(spec)}\n` +
        `>player p1 ${JSON.stringify(p1)}\n` +
        `>player p2 ${JSON.stringify(p2)}`,
    );
  }

  private async consume(stream: any, side: BattleSide) {
    for await (const chunk of stream as AsyncIterable<string>) {
      for (const line of String(chunk).split('\n')) {
        if (!line.startsWith('|')) continue;

        if (line.startsWith('|request|')) {
          const request = JSON.parse(line.slice('|request|'.length));

          // Random battles are played with generated teams, so a preview adds
          // nothing. Auto-accept it for both humans and the AI.
          if (request.teamPreview && !request.wait) {
            this.streams[side].write('team 123456');
            continue;
          }

          if (side === 'p2' && this.mode === 'ai') {
            if (!request.wait) this.chooseForBot(request);
            continue;
          }

          this.requests[side] = request;
          // `wait` requests are intermediate: the opponent still has to act.
          // In a friend battle the caller needs its response back immediately
          // so the app can poll, so `wait` also releases the waiter there.
          if (!request.wait) {
            this.versions[side] += 1;
            this.notify(side);
            this.resolveReady[side]();
          } else if (this.mode === 'friend') {
            this.versions[side] += 1;
            this.notify(side);
          }
          continue;
        }

        this.track(line);

        if (side === 'p1') {
          this.appendLog(line);
        }
      }
    }
  }

  private track(line: string) {
    const parts = line.split('|');
    const type = parts[1];
    const token = parts[2];

    if (
      (type === 'switch' || type === 'drag' || type === 'replace') &&
      token &&
      parts[3]
    ) {
      const tracker = this.ensureTracker(token, parts[3]);
      tracker.condition = parts[4] ?? '100/100';
      this.applyCondition(tracker, tracker.condition);
      return;
    }

    if (token && token.includes(':')) {
      const tracker = this.trackers.get(token.split(':')[0] ?? '');
      if (!tracker) return;

      switch (type) {
        case 'damage':
        case 'heal':
          if (parts[3]) {
            tracker.condition = parts[3];
            this.applyCondition(tracker, parts[3]);
          }
          break;
        case 'faint':
          tracker.fainted = true;
          tracker.hp = 0;
          break;
        case 'status':
          tracker.status = parts[3] ?? tracker.status;
          break;
        case 'curestatus':
          tracker.status = null;
          break;
        default:
          break;
      }
      return;
    }

    if (type === 'turn') this.turn = Number(parts[2] ?? 0);
    if (type === 'win') {
      this.ended = true;
      this.winnerSide = parts[2] === this.p2Name ? 'p2' : 'p1';
      this.notifyBoth();
      this.resolveReady.p1();
      this.resolveReady.p2();
    }
    if (type === 'tie') {
      this.ended = true;
      this.tie = true;
      this.notifyBoth();
      this.resolveReady.p1();
      this.resolveReady.p2();
    }
  }

  private ensureTracker(token: string, details: string): Tracker {
    const key = token.split(':')[0] ?? token;
    const existing = this.trackers.get(key);
    if (existing) {
      existing.species = details.split(',')[0]?.trim() ?? existing.species;
      const level = /L(\d+)/.exec(details);
      if (level?.[1]) existing.level = Number(level[1]);
      return existing;
    }

    const tracker: Tracker = {
      species: details.split(',')[0]?.trim() ?? 'Unknown',
      level: Number(/L(\d+)/.exec(details)?.[1] ?? 50),
      condition: '100/100',
      hp: 1,
      status: null,
      fainted: false,
    };
    this.trackers.set(key, tracker);
    return tracker;
  }

  private applyCondition(tracker: Tracker, condition: string) {
    const [hpPart, ...rest] = condition.split(' ');
    const [current, max] = (hpPart ?? '').split('/').map(Number);
    if (Number.isFinite(current) && Number.isFinite(max) && max) {
      tracker.hp = Math.max(0, Math.min(1, (current ?? 0) / max));
    }
    const status = rest.join(' ').trim();
    tracker.status = status.length > 0 ? status : null;
    tracker.fainted =
      tracker.fainted || tracker.hp <= 0 || status === 'fnt';
  }

  private appendLog(line: string) {
    // Effect messages are prefixed with a dash in the protocol (|-damage|).
    const type = (line.split('|')[1] ?? '').replace(/^-/, '');
    if (!LOG_TYPES.has(type)) return;
    this.log.push(line);
    if (this.log.length > 160) this.log.splice(0, this.log.length - 160);
  }

  private chooseForBot(request: any) {
    if (request.forceSwitch?.some(Boolean)) {
      const team: any[] = request.side?.pokemon ?? [];
      // Revival Blessing borrows the switch request but only fainted Pokémon
      // are legal targets.
      const reviving = team.some((mon) => mon.reviving);
      const index = team.findIndex((mon) =>
        reviving
          ? mon.fainted || String(mon.condition).includes('fnt')
          : !mon.active && !String(mon.condition).includes('fnt'),
      );
      this.streams.p2.write(index >= 0 ? `switch ${index + 1}` : 'pass');
      return;
    }

    const active = request.active?.[0];
    const moves: any[] = active?.moves ?? [];
    const usable = moves
      .map((move, index) => ({ move, index }))
      .filter(({ move }) => !move.disabled && (move.pp ?? 0) > 0);

    if (usable.length === 0) {
      this.streams.p2.write('move 1');
      return;
    }
    const pick = usable[Math.floor(Math.random() * usable.length)];
    this.streams.p2.write(`move ${(pick?.index ?? 0) + 1}`);
  }

  private notify(side: BattleSide) {
    const waiters = this.waiters[side];
    this.waiters[side] = [];
    for (const resolve of waiters) resolve();
  }

  private notifyBoth() {
    this.notify('p1');
    this.notify('p2');
  }

  private waitForRequest(
    side: BattleSide,
    beforeVersion: number,
  ): Promise<void> {
    if (this.versions[side] > beforeVersion || this.ended) {
      return Promise.resolve();
    }
    return new Promise<void>((resolve, reject) => {
      const timer = setTimeout(() => {
        const debug = {
          side,
          turn: this.turn,
          ended: this.ended,
          p1: this.requests.p1 && {
            wait: this.requests.p1.wait,
            active: this.requests.p1.active?.[0]?.moves?.length,
            forceSwitch: this.requests.p1.forceSwitch,
          },
          p2: this.requests.p2 && {
            wait: this.requests.p2.wait,
            active: this.requests.p2.active?.[0]?.moves?.length,
            forceSwitch: this.requests.p2.forceSwitch,
          },
          log: this.log.slice(-6),
        };
        console.error('battle request timeout', JSON.stringify(debug));
        reject(new Error('timed out waiting for the next battle request'));
      }, 10_000);
      this.waiters[side].push(() => {
        clearTimeout(timer);
        resolve();
      });
    });
  }

  get isOver(): boolean {
    return this.ended;
  }

  async choose(choice: string, side: BattleSide = 'p1'): Promise<BattleSnapshot> {
    if (this.ended) return this.snapshot(side);

    const before = this.versions[side];

    if (this.mode === 'friend') {
      // In a friend battle the server cannot block until the other human has
      // chosen, so the request is invalidated and the caller polls instead.
      this.requests[side] = null;
      this.streams[side].write(choice);
      await new Promise((resolve) => setTimeout(resolve, 25));
      return this.snapshot(side);
    }

    this.streams[side].write(choice);
    await this.waitForRequest(side, before);
    return this.snapshot(side);
  }

  snapshot(side: BattleSide = 'p1'): BattleSnapshot {
    const request = this.requests[side];
    const team: BattleMemberView[] = (request?.side?.pokemon ?? []).map(
      (mon: any, index: number) => ({
        slot: index + 1,
        species: String(mon.details ?? '').split(',')[0]?.trim() ?? mon.ident,
        level: Number(/L(\d+)/.exec(String(mon.details))?.[1] ?? 50),
        condition: String(mon.condition ?? ''),
        hp: this.conditionToHp(String(mon.condition ?? '')),
        status: this.conditionToStatus(String(mon.condition ?? '')),
        active: Boolean(mon.active),
        fainted: String(mon.condition ?? '').includes('fnt'),
        reviving: Boolean(mon.reviving),
        moves: mon.active
          ? (request?.active?.[0]?.moves ?? []).map((move: any) => ({
              name: move.move,
              pp: move.pp,
              maxPp: move.maxpp,
              disabled: Boolean(move.disabled),
            }))
          : [],
      }),
    );

    const active = team.find((member) => member.active) ?? null;
    const opponentTracker = this.trackers.get(
      side === 'p1' ? 'p2a' : 'p1a',
    );

    return {
      id: this.id,
      side,
      format: this.format,
      turn: this.turn,
      ended: this.ended,
      winner: this.ended
        ? this.tie
          ? null
          : this.winnerSide === side
            ? 'player'
            : 'opponent'
        : null,
      canAct:
        !this.ended &&
        Boolean(request) &&
        !request?.wait &&
        Boolean(request?.active || request?.forceSwitch?.some(Boolean)),
      waiting: this.ended ? false : !request || Boolean(request.wait),
      forceSwitch: Boolean(request?.forceSwitch?.some(Boolean)),
      player: {
        name: side === 'p1' ? this.p1Name : this.p2Name,
        team,
        active,
      },
      opponent: opponentTracker
        ? {
            species: opponentTracker.species,
            level: opponentTracker.level,
            hp: opponentTracker.hp,
            condition: opponentTracker.condition,
            status: opponentTracker.status,
            fainted: opponentTracker.fainted,
          }
        : null,
      log: this.log.slice(-60),
    };
  }

  private conditionToHp(condition: string): number {
    const [current, max] = condition
      .split(' ')[0]!
      .split('/')
      .map(Number);
    if (!Number.isFinite(current) || !Number.isFinite(max) || !max) return 0;
    return Math.max(0, Math.min(1, (current ?? 0) / max));
  }

  private conditionToStatus(condition: string): string | null {
    const parts = condition.split(' ');
    return parts.length > 1 ? parts.slice(1).join(' ') : null;
  }
}
