import 'package:puzzle_ball_gklabs/game/components/pickup_message_component.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';

/// The text of a pickup [message] in the player's language (game-hud spec).
String hudText(AppLocalizations l10n, HudMessage message) => switch (message) {
  HudMessage.doubleJump => l10n.hudDoubleJump,
  HudMessage.checkpoint => l10n.hudCheckpoint,
};
