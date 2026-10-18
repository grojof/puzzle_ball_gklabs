import 'package:flame/cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/ball_envelope.dart';

import '../helpers/game_helpers.dart';
import '../helpers/level_bot.dart';

/// Plays generated levels with a bot, so a level the validator accepts but
/// the real physics cannot complete fails here (level-generation spec).
void main() {
  late Images images;
  setUpAll(() async => images = await testImages());

  // One level per introduction, plus deep levels.
  for (final number in [1, 2, 3, 4, 5, 6, 7, 8, 45, 120, 300]) {
    testBotCompletes(
      () => images,
      levelGenerator.generate(seed: 'bot', level: number),
      number,
    );
  }
}
