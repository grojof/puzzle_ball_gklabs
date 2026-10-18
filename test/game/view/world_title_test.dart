import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/view/world_title.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';

void main() {
  test('names the world and biome on its first level only', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final es = lookupAppLocalizations(const Locale('es'));
    expect(worldTitle(en, 'seed', 1), 'World 1 · Night Forest');
    expect(worldTitle(en, 'seed', 11), 'World 2 · Desert Dusk');
    expect(worldTitle(en, 'seed', 12), isNull);
    expect(worldTitle(es, 'seed', 21), 'Mundo 3 · Cumbres nevadas');
    expect(worldTitle(es, 'seed', 31), 'Mundo 4 · Cuevas de cristal');
    expect(worldTitle(es, 'seed', 41), 'Mundo 5 · Volcán');
  });
}
