import 'package:flutter/material.dart';

/// Trainer avatar presets. Kept as icon slugs so they render consistently
/// without downloading art.
const Map<String, ({String label, IconData icon})> trainerAvatars = {
  'explorer': (label: 'Explorer', icon: Icons.explore_rounded),
  'flame': (label: 'Blaze', icon: Icons.local_fire_department_rounded),
  'bolt': (label: 'Spark', icon: Icons.bolt_rounded),
  'leaf': (label: 'Grove', icon: Icons.eco_rounded),
  'star': (label: 'Stargazer', icon: Icons.auto_awesome_rounded),
  'shield': (label: 'Guardian', icon: Icons.shield_rounded),
  'wave': (label: 'Tide', icon: Icons.waves_rounded),
  'moon': (label: 'Nightowl', icon: Icons.nightlight_round),
};

IconData trainerAvatarIcon(String slug) {
  return (trainerAvatars[slug] ?? trainerAvatars['explorer']!).icon;
}

const List<String> trainerTitles = [
  'Rookie',
  'Collector',
  'Ace Trainer',
  'Shiny Hunter',
  'Gym Challenger',
  'Champion',
];
