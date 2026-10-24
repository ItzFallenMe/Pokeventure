enum QrKind { friend, battle }

class QrPayload {
  const QrPayload({required this.kind, required this.code});

  final QrKind kind;
  final String code;
}

final _prefixed = RegExp(
  r'^pokeventure://(friend|battle)/([A-Za-z0-9]{4,12})$',
  caseSensitive: false,
);
final _bare = RegExp(r'^[A-Za-z0-9]{4,12}$');

String friendQrPayload(String code) => 'pokeventure://friend/$code';

String battleQrPayload(String code) => 'pokeventure://battle/$code';

QrPayload? parseQrPayload(String raw) {
  final value = raw.trim();

  final match = _prefixed.firstMatch(value);
  if (match != null) {
    return QrPayload(
      kind: match.group(1)!.toLowerCase() == 'battle'
          ? QrKind.battle
          : QrKind.friend,
      code: match.group(2)!.toUpperCase(),
    );
  }

  if (_bare.hasMatch(value)) {
    return QrPayload(kind: QrKind.friend, code: value.toUpperCase());
  }
  return null;
}
