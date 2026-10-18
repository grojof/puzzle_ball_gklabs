import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/components/pickup_message_component.dart';
import 'package:puzzle_ball_gklabs/game/view/hud_text.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';

void main() {
  test('pickup messages read in each language', () {
    String text(String locale, HudMessage message) =>
        hudText(lookupAppLocalizations(Locale(locale)), message);
    expect(text('en', HudMessage.doubleJump), 'Double jump!');
    expect(text('en', HudMessage.checkpoint), 'Checkpoint');
    expect(text('es', HudMessage.doubleJump), '¡Doble salto!');
    expect(text('es', HudMessage.checkpoint), 'Punto de control');
    expect(text('ca', HudMessage.doubleJump), 'Doble salt!');
    expect(text('ca', HudMessage.checkpoint), 'Punt de control');
  });
}
