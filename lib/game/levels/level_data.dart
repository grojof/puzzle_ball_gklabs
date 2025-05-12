import 'package:flame/extensions.dart';

class LevelData {
  const LevelData({
    required this.ballStart,
    required this.goalPosition,
    required this.walls,
    required this.floors,
    required this.obstacles,
  });

  final Vector2 ballStart;
  final Vector2 goalPosition;
  final List<Rect> walls;
  final List<Rect> floors;
  final List<Rect> obstacles;
}
