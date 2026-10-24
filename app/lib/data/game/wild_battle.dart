import 'dart:math' as math;

import '../models/move_entry.dart';
import '../models/pokemon.dart';
import '../models/pokemon_type.dart';
import '../type_chart.dart';

/// A move slot for the duration of one wild battle. PP is local to the
/// encounter, matching the existing device-local battle model.
class BattleMoveSlot {
  BattleMoveSlot({required this.move, required this.pp});

  final MoveEntry move;
  int pp;

  int get maxPp => math.max(1, move.pp);
  bool get usable => pp > 0;
}

/// A small, offline wild-battle engine.
///
/// Wild battles are intentionally separate from the Showdown-backed trainer
/// and friend battles: they need a catch action and must keep the wild
/// Pokémon's current HP so the existing catch formula can use it. The server
/// remains the authority for PvP.
class WildBattle {
  WildBattle({
    required this.player,
    required this.wild,
    required this.moves,
    math.Random? random,
  }) : playerHp = player.currentHp,
       wildHp = wild.currentHp,
       _random = random ?? math.Random() {
    _buildMoves();
    _log('A wild ${wild.name} appeared!');
  }

  Pokemon player;
  Pokemon wild;
  int playerHp;
  int wildHp;

  final Map<String, MoveEntry> moves;
  final math.Random _random;
  final List<String> _logLines = [];
  final List<BattleMoveSlot> playerMoves = [];
  final List<BattleMoveSlot> wildMoves = [];

  int playerAtkStage = 0;
  int playerDefStage = 0;
  int wildAtkStage = 0;
  int wildDefStage = 0;
  bool playerParalyzed = false;
  bool wildParalyzed = false;
  bool ran = false;

  bool get wildFainted => wildHp <= 0;
  bool get playerFainted => playerHp <= 0;
  bool get over => wildFainted || ran;
  bool get playerWon => wildFainted;
  String get lastMessage => _logLines.isEmpty ? '' : _logLines.last;

  List<String> get log => List.unmodifiable(_logLines);

  /// The catch sheet receives the damaged wild Pokémon, not a fresh copy.
  Pokemon get catchTarget => wild.copyWith(currentHp: wildHp);

  void _buildMoves() {
    playerMoves
      ..clear()
      ..addAll(_slotsFor(player));
    wildMoves
      ..clear()
      ..addAll(_slotsFor(wild));
  }

  List<BattleMoveSlot> _slotsFor(Pokemon pokemon) {
    final slots = <BattleMoveSlot>[];
    final seen = <String>{};
    for (final name in pokemon.moves.take(4)) {
      final move = moves[name.toLowerCase()];
      if (move == null || seen.contains(move.name)) continue;
      seen.add(move.name);
      slots.add(BattleMoveSlot(move: move, pp: math.max(1, move.pp)));
    }
    if (slots.isEmpty) {
      final struggle = moves['struggle'];
      slots.add(
        BattleMoveSlot(
          move:
              struggle ??
              const MoveEntry(
                name: 'Struggle',
                type: PokemonType.normal,
                category: 'Physical',
                power: 50,
                accuracy: null,
                pp: 1,
                priority: 0,
              ),
          pp: 1,
        ),
      );
    }
    return slots;
  }

  BattleMoveSlot? _playerSlot(String name) {
    for (final slot in playerMoves) {
      if (slot.move.name == name && slot.usable) return slot;
    }
    for (final slot in playerMoves) {
      if (slot.usable) return slot;
    }
    return null;
  }

  BattleMoveSlot? _wildSlot() {
    final usable = wildMoves.where((slot) => slot.usable).toList();
    if (usable.isEmpty) return null;
    return usable[_random.nextInt(usable.length)];
  }

  bool _hits(MoveEntry move) {
    final accuracy = move.accuracy;
    if (accuracy == null || accuracy <= 0) return true;
    return _random.nextInt(100) < accuracy;
  }

  double _stageMultiplier(int stage) {
    if (stage >= 0) return (2 + stage) / 2;
    return 2 / (2 - stage);
  }

  int _damage({
    required Pokemon attacker,
    required Pokemon defender,
    required MoveEntry move,
    required int attackStage,
    required int defenseStage,
  }) {
    if (move.isStatus || move.power <= 0) return 0;
    final physical = move.category != 'Special';
    final attack = physical ? attacker.stats.attack : attacker.stats.spAttack;
    final defense = physical
        ? defender.stats.defense
        : defender.stats.spDefense;
    final effectiveAttack = attack * _stageMultiplier(attackStage);
    final effectiveDefense = defense * _stageMultiplier(defenseStage);

    var damage =
        (((2 * attacker.level / 5) + 2) *
                move.power *
                effectiveAttack /
                effectiveDefense) /
            50 +
        2;
    if (attacker.types.contains(move.type)) damage *= 1.5;
    damage *= typeEffectiveness(move.type, defender.types);
    damage *= 0.85 + _random.nextDouble() * 0.15;
    return math.max(1, damage.floor());
  }

  void _log(String line) {
    _logLines.add(line);
    if (_logLines.length > 30) _logLines.removeAt(0);
  }

  List<String> _playerMove(BattleMoveSlot slot) {
    final lines = <String>[];
    if (playerParalyzed && _random.nextDouble() < 0.25) {
      lines.add('${player.displayName} is paralyzed! It can\'t move!');
      _log(lines.last);
      return lines;
    }

    slot.pp -= 1;
    lines.add('${player.displayName} used ${slot.move.name}!');
    if (!_hits(slot.move)) {
      lines.add('It missed!');
      _logAll(lines);
      return lines;
    }

    if (slot.move.isStatus) {
      _applyStatus(byPlayer: true, move: slot.move, lines: lines);
      _logAll(lines);
      return lines;
    }

    final damage = _damage(
      attacker: player,
      defender: wild,
      move: slot.move,
      attackStage: playerAtkStage,
      defenseStage: wildDefStage,
    );
    final effectiveness = typeEffectiveness(slot.move.type, wild.types);
    if (effectiveness == 0) {
      lines.add('It doesn\'t affect ${wild.name}…');
      _logAll(lines);
      return lines;
    }
    wildHp = math.max(0, wildHp - damage);
    if (effectiveness > 1) {
      lines.add('It\'s super effective!');
    } else if (effectiveness < 1) {
      lines.add('It\'s not very effective…');
    }
    if (wildHp <= 0) {
      lines.add('Wild ${wild.name} fainted!');
    }
    _logAll(lines);
    return lines;
  }

  List<String> _wildMove(BattleMoveSlot slot) {
    final lines = <String>[];
    if (wildParalyzed && _random.nextDouble() < 0.25) {
      lines.add('Wild ${wild.name} is paralyzed! It can\'t move!');
      _log(lines.last);
      return lines;
    }

    slot.pp -= 1;
    lines.add('Wild ${wild.name} used ${slot.move.name}!');
    if (!_hits(slot.move)) {
      lines.add('It missed!');
      _logAll(lines);
      return lines;
    }

    if (slot.move.isStatus) {
      _applyStatus(byPlayer: false, move: slot.move, lines: lines);
      _logAll(lines);
      return lines;
    }

    final damage = _damage(
      attacker: wild,
      defender: player,
      move: slot.move,
      attackStage: wildAtkStage,
      defenseStage: playerDefStage,
    );
    final effectiveness = typeEffectiveness(slot.move.type, player.types);
    if (effectiveness == 0) {
      lines.add('It doesn\'t affect ${player.displayName}…');
      _logAll(lines);
      return lines;
    }
    playerHp = math.max(0, playerHp - damage);
    if (effectiveness > 1) {
      lines.add('It\'s super effective!');
    } else if (effectiveness < 1) {
      lines.add('It\'s not very effective…');
    }
    if (playerHp <= 0) {
      lines.add('${player.displayName} fainted!');
    }
    _logAll(lines);
    return lines;
  }

  void _logAll(List<String> lines) {
    _logLines.addAll(lines);
    if (_logLines.length > 30) {
      _logLines.removeRange(0, _logLines.length - 30);
    }
  }

  void _applyStatus({
    required bool byPlayer,
    required MoveEntry move,
    required List<String> lines,
  }) {
    final name = move.name.toLowerCase();
    final target = byPlayer ? 'Wild ${wild.name}' : player.displayName;

    if (name.contains('growl')) {
      if (byPlayer) {
        wildAtkStage = math.max(-6, wildAtkStage - 1);
      } else {
        playerAtkStage = math.max(-6, playerAtkStage - 1);
      }
      lines.add('$target\'s Attack fell!');
    } else if (name.contains('leer') || name.contains('tail whip')) {
      if (byPlayer) {
        wildDefStage = math.max(-6, wildDefStage - 1);
      } else {
        playerDefStage = math.max(-6, playerDefStage - 1);
      }
      lines.add('$target\'s Defense fell!');
    } else if (name.contains('harden') ||
        name.contains('withdraw') ||
        name.contains('defense curl')) {
      if (byPlayer) {
        playerDefStage = math.min(6, playerDefStage + 1);
      } else {
        wildDefStage = math.min(6, wildDefStage + 1);
      }
      lines.add('$target\'s Defense rose!');
    } else if (name.contains('swords dance') || name.contains('growth')) {
      if (byPlayer) {
        playerAtkStage = math.min(6, playerAtkStage + 1);
      } else {
        wildAtkStage = math.min(6, wildAtkStage + 1);
      }
      lines.add('$target\'s Attack rose!');
    } else if (name.contains('recover') ||
        name.contains('synthesis') ||
        name.contains('roost') ||
        name.contains('soft-boiled')) {
      if (byPlayer) {
        playerHp = math.min(player.maxHp, playerHp + player.maxHp ~/ 2);
      } else {
        wildHp = math.min(wild.maxHp, wildHp + wild.maxHp ~/ 2);
      }
      lines.add('$target recovered HP!');
    } else if (name.contains('thunder wave') || name.contains('stun spore')) {
      if (byPlayer) {
        wildParalyzed = true;
      } else {
        playerParalyzed = true;
      }
      lines.add('$target is paralyzed!');
    } else {
      lines.add('But nothing happened!');
    }
  }

  /// Runs one full turn. Returns only the new log lines for the UI.
  List<String> useMove(String moveName) {
    if (over || playerFainted) return const [];
    final playerSlot = _playerSlot(moveName);
    if (playerSlot == null) return const [];
    final wildSlot = _wildSlot();
    final lines = <String>[];

    final playerFirst = player.stats.speed >= wild.stats.speed;
    if (playerFirst) {
      lines.addAll(_playerMove(playerSlot));
      if (!over && !wildFainted && wildSlot != null) {
        lines.addAll(_wildMove(wildSlot));
      }
    } else {
      if (wildSlot != null) lines.addAll(_wildMove(wildSlot));
      if (!playerFainted) lines.addAll(_playerMove(playerSlot));
    }
    return lines;
  }

  /// Sends out a new party member. Used after a faint and for a manual switch.
  List<String> switchTo(Pokemon next, {bool wildAttacks = true}) {
    player = next;
    playerHp = next.currentHp;
    playerAtkStage = 0;
    playerDefStage = 0;
    playerParalyzed = false;
    _buildMoves();
    final lines = <String>['Go, ${next.displayName}!'];
    _log(lines.last);
    if (wildAttacks && !over) {
      final slot = _wildSlot();
      if (slot != null) lines.addAll(_wildMove(slot));
    }
    return lines;
  }

  /// A GBA-style escape attempt. A failure costs the turn.
  List<String> attemptRun() {
    if (over) return const [];
    final playerSpeed = math.max(1, player.stats.speed);
    final wildSpeed = math.max(1, wild.stats.speed);
    final chance = (0.45 + 0.5 * playerSpeed / (playerSpeed + wildSpeed)).clamp(
      0.35,
      0.95,
    );
    if (_random.nextDouble() < chance) {
      ran = true;
      _log('Got away safely!');
      return const ['Got away safely!'];
    }

    final lines = <String>['Can\'t escape!'];
    _log(lines.last);
    final slot = _wildSlot();
    if (slot != null) lines.addAll(_wildMove(slot));
    return lines;
  }

  /// Used when the player has no healthy party members left.
  void markLost() {
    ran = true;
    _log('You have no Pokémon left…');
  }
}

int xpFromWildWin({required int baseExp, required int level}) {
  return math.max(20, (baseExp * (level + 5) / 7).round());
}
