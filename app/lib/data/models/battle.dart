class BattleMove {
  const BattleMove({
    required this.name,
    required this.pp,
    required this.maxPp,
    required this.disabled,
  });

  factory BattleMove.fromJson(Map<String, dynamic> json) {
    return BattleMove(
      name: json['name'] as String? ?? 'Move',
      pp: (json['pp'] as num?)?.toInt() ?? 0,
      maxPp: (json['maxPp'] as num?)?.toInt() ?? 0,
      disabled: json['disabled'] as bool? ?? false,
    );
  }

  final String name;
  final int pp;
  final int maxPp;
  final bool disabled;

  bool get usable => !disabled && pp > 0;
}

class BattleMember {
  const BattleMember({
    required this.slot,
    required this.species,
    required this.level,
    required this.condition,
    required this.hp,
    required this.status,
    required this.active,
    required this.fainted,
    required this.moves,
  });

  factory BattleMember.fromJson(Map<String, dynamic> json) {
    return BattleMember(
      slot: (json['slot'] as num?)?.toInt() ?? 0,
      species: json['species'] as String? ?? 'Pokémon',
      level: (json['level'] as num?)?.toInt() ?? 50,
      condition: json['condition'] as String? ?? '',
      hp: (json['hp'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String?,
      active: json['active'] as bool? ?? false,
      fainted: json['fainted'] as bool? ?? false,
      moves: (json['moves'] as List<dynamic>? ?? [])
          .map((raw) => BattleMove.fromJson(raw as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int slot;
  final String species;
  final int level;
  final String condition;
  final double hp;
  final String? status;
  final bool active;
  final bool fainted;
  final List<BattleMove> moves;

  String get hpLabel => condition.split(' ').first;
}

class BattleOpponent {
  const BattleOpponent({
    required this.species,
    required this.level,
    required this.hp,
    required this.condition,
    required this.status,
    required this.fainted,
  });

  factory BattleOpponent.fromJson(Map<String, dynamic> json) {
    return BattleOpponent(
      species: json['species'] as String? ?? 'Pokémon',
      level: (json['level'] as num?)?.toInt() ?? 50,
      hp: (json['hp'] as num?)?.toDouble() ?? 1,
      condition: json['condition'] as String? ?? '100/100',
      status: json['status'] as String?,
      fainted: json['fainted'] as bool? ?? false,
    );
  }

  final String species;
  final int level;
  final double hp;
  final String condition;
  final String? status;
  final bool fainted;

  String get hpLabel => condition.split(' ').first;
}

class BattleSnapshot {
  const BattleSnapshot({
    required this.id,
    required this.format,
    required this.turn,
    required this.ended,
    required this.winner,
    required this.canAct,
    required this.waiting,
    required this.forceSwitch,
    required this.playerName,
    required this.team,
    required this.active,
    required this.opponent,
    required this.log,
  });

  factory BattleSnapshot.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>? ?? const {};
    final team = (player['team'] as List<dynamic>? ?? [])
        .map((raw) => BattleMember.fromJson(raw as Map<String, dynamic>))
        .toList(growable: false);
    final activeJson = player['active'] as Map<String, dynamic>?;
    final opponentJson = json['opponent'] as Map<String, dynamic>?;

    return BattleSnapshot(
      id: json['id'] as String,
      format: json['format'] as String? ?? 'gen9randombattle',
      turn: (json['turn'] as num?)?.toInt() ?? 0,
      ended: json['ended'] as bool? ?? false,
      winner: json['winner'] as String?,
      canAct: json['canAct'] as bool? ?? false,
      waiting: json['waiting'] as bool? ?? false,
      forceSwitch: json['forceSwitch'] as bool? ?? false,
      playerName: player['name'] as String? ?? 'Trainer',
      team: team,
      active: activeJson == null
          ? _activeOf(team)
          : BattleMember.fromJson(activeJson),
      opponent:
          opponentJson == null ? null : BattleOpponent.fromJson(opponentJson),
      log: (json['log'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  final String id;
  final String format;
  final int turn;
  final bool ended;
  final String? winner;
  final bool canAct;
  final bool waiting;
  final bool forceSwitch;
  final String playerName;
  final List<BattleMember> team;
  final BattleMember? active;
  final BattleOpponent? opponent;
  final List<String> log;

  static BattleMember? _activeOf(List<BattleMember> team) {
    for (final member in team) {
      if (member.active) return member;
    }
    return null;
  }

  bool get playerWon => winner == 'player';
  bool get lost => ended && !playerWon;
  int get faintedCount => team.where((member) => member.fainted).length;
}
