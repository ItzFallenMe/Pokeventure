/// Turns a raw Showdown protocol line into a readable log entry.
/// Returns null for lines the UI should skip.
String? prettifyBattleLogLine(String line) {
  if (!line.startsWith('|')) return null;

  final parts = line.split('|');
  if (parts.length < 2) return null;

  String at(int index) => index < parts.length ? parts[index] : '';
  final type = at(1);

  String clean(String ident) {
    final value = ident;
    final colon = value.indexOf(': ');
    return colon >= 0 ? value.substring(colon + 2) : value;
  }

  String speciesOf(String ident) => at(3).split(',').first;

  bool isFoe(String ident) => ident.startsWith('p2');

  switch (type) {
    case 'move':
      return '${clean(at(2))} used ${at(3)}!';
    case 'switch':
    case 'drag':
    case 'replace':
      final ident = at(2);
      final species = speciesOf(ident);
      return isFoe(ident) ? 'Foe sent out $species.' : 'Go, $species!';
    case '-damage':
      final hp = at(3).split(' ').first;
      return '${clean(at(2))} took damage ($hp).';
    case '-heal':
      final hp = at(3).split(' ').first;
      return '${clean(at(2))} recovered HP ($hp).';
    case 'faint':
      final ident = at(2);
      return isFoe(ident)
          ? "Foe's ${clean(ident)} fainted!"
          : '${clean(ident)} fainted!';
    case '-status':
      return '${clean(at(2))} is now ${_statusName(at(3))}.';
    case '-curestatus':
      return '${clean(at(2))} recovered from ${_statusName(at(3))}.';
    case '-boost':
      return '${clean(at(2))}: ${_statName(at(3))} rose!';
    case '-unboost':
      return '${clean(at(2))}: ${_statName(at(3))} fell.';
    case '-crit':
      return 'A critical hit!';
    case '-supereffective':
      return "It's super effective!";
    case '-resisted':
      return "It's not very effective…";
    case '-immune':
      return 'It had no effect…';
    case '-miss':
      return 'The attack missed!';
    case '-cant':
      return '${clean(at(2))} could not move!';
    case '-fail':
      return 'But it failed!';
    case '-weather':
      return _weather(at(2));
    case '-sidestart':
      return '${at(3)} was set on '
          '${at(2).startsWith('p1') ? 'your' : "the foe's"} side.';
    case '-sideend':
      return '${at(3)} was removed.';
    case '-enditem':
      return '${clean(at(2))} lost its ${at(3)}.';
    case '-endability':
      return '${clean(at(2))} lost its ability.';
    case 'win':
      return at(2) == 'Trainer'
          ? 'You won the battle!'
          : 'You lost the battle.';
    case 'tie':
      return 'The battle ended in a tie.';
    case 'message':
      return at(2).isEmpty ? null : at(2);
    case 'turn':
      return null;
    default:
      return null;
  }
}

String _statusName(String code) {
  return switch (code) {
    'par' => 'paralyzed',
    'brn' => 'burned',
    'psn' => 'poisoned',
    'tox' => 'badly poisoned',
    'slp' => 'asleep',
    'frz' => 'frozen',
    _ => code.isEmpty ? 'affected' : code,
  };
}

String _statName(String code) {
  return switch (code) {
    'atk' => 'Attack',
    'def' => 'Defense',
    'spa' => 'Sp. Atk',
    'spd' => 'Sp. Def',
    'spe' => 'Speed',
    'accuracy' => 'accuracy',
    'evasion' => 'evasion',
    _ => code.isEmpty ? 'a stat' : code,
  };
}

String? _weather(String code) {
  return switch (code) {
    'RainDance' => 'It started to rain!',
    'Sandstorm' => 'A sandstorm brewed!',
    'SunnyDay' => 'The sunlight turned harsh!',
    'Snowscape' || 'Hail' => 'It started to snow!',
    'none' => 'The weather cleared.',
    _ => null,
  };
}
