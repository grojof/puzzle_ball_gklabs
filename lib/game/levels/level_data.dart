import 'package:flame_forge2d/flame_forge2d.dart';

class LevelData {
  LevelData({
    required this.ballStart,
    required this.goalPosition,
    required this.floorData,
    required this.rampData,
    required this.boostData,
    required this.checkpointData,
    // Puedes agregar más tipos si lo necesitas
  });

  final Vector2 ballStart;
  final Vector2 goalPosition;
  final List<FloorData> floorData;
  final List<RampData> rampData;
  final List<BoostData> boostData;
  final List<CheckPointData> checkpointData;
}

class FloorData {
  FloorData({required this.position, required this.size});
  final Vector2 position;
  final Vector2 size;
}

class RampData {
  RampData({
    required this.position,
    required this.size,
    required this.inverted,
  });
  final Vector2 position;
  final Vector2 size;
  final bool inverted;
}

class BoostData {
  BoostData({required this.position, required this.type, this.extra});
  final Vector2 position;
  final BoostType type;
  final Map<String, dynamic>? extra; // parámetros extra para el boost
}

enum BoostType { jump, speed, gravity }

class CheckPointData {
  CheckPointData({required this.position});
  final Vector2 position;
}
