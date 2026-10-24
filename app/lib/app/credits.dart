import 'package:url_launcher/url_launcher.dart';

abstract final class Credits {
  static const String creator = 'ItzFallenMe';
  static const String creatorHandle = '@ItzFallenMe';
  static const String creatorUrl = 'https://github.com/ItzFallenMe';
  static const String pokemonDataUrl =
      'https://github.com/ItzFallenMe/pokemon-data.json';

  static Future<bool> openCreator() {
    return launchUrl(
      Uri.parse(creatorUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<bool> openPokemonData() {
    return launchUrl(
      Uri.parse(pokemonDataUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}
