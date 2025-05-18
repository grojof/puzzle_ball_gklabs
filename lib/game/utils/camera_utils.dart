import 'package:flame/components.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';

/// --- AJUSTES DE CÁMARA ---
/// Puedes modificar estos valores para controlar la suavidad y el zoom de la cámara.
class CameraBehaviorConfig {
  /// Suavidad de animación (0.0-1.0, más alto = más rápido)
  static double lerp = 0.05;

  /// Rango para considerar un boost "cercano" (metros)
  static double boostRange = 1.5;

  /// Zoom de la cámara cuando hay boost cerca
  static double boostZoom = 22;
}

/// Utilidad para animar suavemente el zoom de la cámara
void animateCameraZoom(
  CameraComponent camera,
  double targetZoom, {
  double duration = 0.5,
}) {
  final startZoom = camera.viewfinder.zoom;
  final delta = targetZoom - startZoom;
  double t = 0;
  void step(double dt) {
    t += dt;
    final progress = (t / duration).clamp(0, 1);
    camera.viewfinder.zoom = startZoom + delta * progress;
    if (progress < 1) {
      Future.delayed(const Duration(milliseconds: 16), () => step(0.016));
    }
  }

  step(0);
}

/// Ajusta el zoom de la cámara si hay boosts cercanos
void adjustCameraForBoosts(
  CameraComponent camera,
  List<BoostData> boosts,
  Vector2 ballPos,
  double defaultZoom,
) {
  final boostNear = boosts.any(
    (b) => (b.position.x - ballPos.x).abs() < CameraBehaviorConfig.boostRange,
  );
  if (boostNear) {
    camera.viewfinder.zoom = camera.viewfinder.zoom +
        (CameraBehaviorConfig.boostZoom - camera.viewfinder.zoom) *
            CameraBehaviorConfig.lerp;
  } else {
    camera.viewfinder.zoom = camera.viewfinder.zoom +
        (defaultZoom - camera.viewfinder.zoom) * CameraBehaviorConfig.lerp;
  }
}

/// Ajusta el anchor de la cámara según la mayoría de superficie de bloques en la dirección de movimiento,
/// considerando la parte superior de los bloques como superficie útil para anticipar saltos y caídas.
void adjustCameraHeightForTerrain(
  CameraComponent camera,
  List<FloorData> floors,
  Vector2 ballPos, {
  double lookAhead = 0.5,
  double lookBehind = 0.0,
  double lookUp = 0.1,
  double lookDown = 4.0,
  Anchor anchorNormal = const Anchor(0.5, 0.85),
  Anchor anchorUp = const Anchor(0.5, 0.7),
  Anchor anchorDown = const Anchor(0.5, 0.95),
  void Function(Anchor anchor)? setTargetAnchor,
  double? ballVelocityX,
}) {
  if (floors.isEmpty) return;
  final movingRight = (ballVelocityX ?? 0) >= 0;
  final dxMin = movingRight ? 0.1 : -lookBehind;
  final dxMax = movingRight ? lookAhead : -0.1;
  // Busca bloques solo en la dirección de movimiento, pero considera la proyección horizontal del bloque (superficie superior)
  final tilesInPath = floors.where((f) {
    final dx = f.position.x - ballPos.x;
    final left = f.position.x - f.size.x / 2;
    final right = f.position.x + f.size.x / 2;
    final overlapsX = ballPos.x >= left && ballPos.x <= right;
    final inPath = dx >= dxMin && dx <= dxMax;
    return (overlapsX || inPath);
  }).toList();

  print(
      '[CAM] BallPos: ${ballPos.x.toStringAsFixed(2)}, ${ballPos.y.toStringAsFixed(2)}');
  print('[CAM] tilesInPath: ${tilesInPath.length}');
  for (final f in tilesInPath) {
    final topY = f.position.y - f.size.y / 2;
    final bottomY = f.position.y + f.size.y / 2;
    print(
        '[CAM] Block at x:[${(f.position.x - f.size.x / 2).toStringAsFixed(2)}-${(f.position.x + f.size.x / 2).toStringAsFixed(2)}] y:[${topY.toStringAsFixed(2)}-${bottomY.toStringAsFixed(2)}]');
  }

  if (tilesInPath.isEmpty) {
    print('[CAM] No blocks in path, anchorDown');
    if (setTargetAnchor != null) {
      setTargetAnchor(anchorDown);
    } else {
      camera.viewfinder.anchor = anchorDown;
    }
    return;
  }

  double areaAbove = 0;
  double areaBelow = 0;
  for (final f in tilesInPath) {
    final topY = f.position.y - f.size.y / 2;
    final bottomY = f.position.y + f.size.y / 2;
    if (topY > ballPos.y) {
      areaBelow += f.size.x * f.size.y;
      print(
          '[CAM] Block below: area += ${(f.size.x * f.size.y).toStringAsFixed(2)}');
    } else if (bottomY < ballPos.y) {
      areaAbove += f.size.x * f.size.y;
      print(
          '[CAM] Block above: area += ${(f.size.x * f.size.y).toStringAsFixed(2)}');
    } else {
      areaBelow += f.size.x * f.size.y;
      print(
          '[CAM] Block under/overlap: area += ${(f.size.x * f.size.y).toStringAsFixed(2)}');
    }
  }
  print('[CAM] areaAbove: $areaAbove, areaBelow: $areaBelow');
  Anchor targetAnchor = anchorNormal;
  if (areaBelow > areaAbove) {
    targetAnchor = anchorDown;
    print('[CAM] anchorDown');
  } else if (areaAbove > areaBelow) {
    targetAnchor = anchorUp;
    print('[CAM] anchorUp');
  } else {
    print('[CAM] anchorNormal');
  }
  if (setTargetAnchor != null) {
    setTargetAnchor(targetAnchor);
  } else {
    camera.viewfinder.anchor = targetAnchor;
  }
}
