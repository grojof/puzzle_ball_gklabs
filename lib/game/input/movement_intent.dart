/// What the player asks the ball to do, written by the active input and read
/// by the ball (design D4).
class MovementIntent {
  /// Horizontal push from −1 (full left) to 1 (full right).
  double horizontal = 0;

  bool _jumpRequested = false;

  void requestJump() => _jumpRequested = true;

  /// Returns whether a jump was requested since the last call, and clears it.
  bool consumeJump() {
    final requested = _jumpRequested;
    _jumpRequested = false;
    return requested;
  }

  void reset() {
    horizontal = 0;
    _jumpRequested = false;
  }
}
