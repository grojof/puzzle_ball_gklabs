import 'package:flame/components.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';

/// --- AJUSTES DE CÁMARA ---
/// Tune these values to control camera smoothing and zoom.
class CameraBehaviorConfig {
  /// Suavidad de animación (0.0-1.0, más alto = más rápido)
  static double lerp = 0.01;

  /// Rango para considerar un boost "cercano" (metros)
  static double boostRange = 2.5;

  /// Zoom de la cámara cuando hay boost cerca
  static double boostZoom = 22 / 40;
}

/// Utilidad para animar suavemente el zoom de la cámara
void animateCameraZoom(
  CameraComponent camera,
  double targetZoom, {
  double duration = 0.8,
}) {
  final startZoom = camera.viewfinder.zoom;
  final delta = targetZoom - startZoom;
  double t = 0;
  void step(double dt) {
    t += dt;
    final progress = (t / duration).clamp(0, 1);
    camera.viewfinder.zoom = startZoom + delta * progress;
    if (progress < 1) {
      Future.delayed(const Duration(milliseconds: 18), () => step(0.018));
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
    camera.viewfinder.zoom =
        camera.viewfinder.zoom +
        (CameraBehaviorConfig.boostZoom - camera.viewfinder.zoom) *
            CameraBehaviorConfig.lerp;
  } else {
    camera.viewfinder.zoom =
        camera.viewfinder.zoom +
        (defaultZoom - camera.viewfinder.zoom) * CameraBehaviorConfig.lerp;
  }
}

/// Moves the camera anchor towards the terrain ahead of the ball, using the
/// top of the blocks in the direction of travel to anticipate jumps and drops.
void adjustCameraHeightForTerrain(
  CameraComponent camera,
  List<FloorData> floors,
  Vector2 ballPos, {
  double lookAhead = 0.5,
  double lookBehind = 0.0,
  double lookUp = 0.1,
  double lookDown = 4.0,
  Anchor anchorNormal = const Anchor(0.5, 0.85),
  Anchor anchorLower = const Anchor(
    0.5,
    0.95,
  ), // cámara baja, muestra más abajo
  Anchor anchorHigher = const Anchor(
    0.5,
    0.7,
  ), // cámara alta, muestra más arriba
  void Function(Anchor anchor)? setTargetAnchor,
  double? ballVelocityX,
}) {
  if (floors.isEmpty) return;
  final movingRight = (ballVelocityX ?? 0) >= 0;
  final dxMin = movingRight ? 0.1 : -lookBehind;
  final dxMax = movingRight ? lookAhead : -0.1;
  // Busca bloques solo en la dirección de movimiento
  final tilesInPath = floors.where((f) {
    final dx = f.position.x - ballPos.x;
    final left = f.position.x - f.size.x / 2;
    final right = f.position.x + f.size.x / 2;
    final overlapsX = ballPos.x >= left && ballPos.x <= right;
    final inPath = dx >= dxMin && dx <= dxMax;
    return overlapsX || inPath;
  }).toList();

  if (tilesInPath.isEmpty) {
    if (setTargetAnchor != null) {
      setTargetAnchor(anchorLower);
    } else {
      camera.viewfinder.anchor = anchorLower;
    }
    // print('Sin bloques: camara baja (ver abajo)');
    return;
  }

  // --- Anticipación: analizar bloques cercanos y lejanos ---
  // Definir rangos
  const nearRange = 2.0; // metros cercanos
  const farRange = 6.0; // metros lejanos
  final nearBlocks = tilesInPath.where((f) {
    final dx = f.position.x - ballPos.x;
    if (movingRight && dx <= 0) return false;
    if (!movingRight && dx >= 0) return false;
    return dx.abs() <= nearRange;
  }).toList();
  final farBlocks = tilesInPath.where((f) {
    final dx = f.position.x - ballPos.x;
    if (movingRight && dx <= 0) return false;
    if (!movingRight && dx >= 0) return false;
    return dx.abs() > nearRange && dx.abs() <= farRange;
  }).toList();

  double avgY(List<FloorData> blocks) {
    if (blocks.isEmpty) return ballPos.y;
    double sumY = 0;
    for (final f in blocks) {
      final topY = f.position.y - f.size.y / 2;
      sumY += topY;
    }
    return sumY / blocks.length;
  }

  final avgYNear = avgY(nearBlocks);
  final avgYFar = avgY(farBlocks);
  final diffNear = avgYNear - ballPos.y;

  // Umbrales para decidir si subir, bajar o mantener
  const thresholdUp = -0.5;
  const thresholdDown = 0.5;
  // diferencia significativa para anticipar
  const anticipationThreshold = 1.0;

  // Dynamic anticipation from the mean distance of far blocks.
  var anchorY = anchorNormal.y;
  var anticipated = false;

  if (farBlocks.isNotEmpty) {
    // Distancia media vertical de los bloques lejanos
    final avgFarVert =
        farBlocks
            .map((f) => (f.position.y - f.size.y / 2) - ballPos.y)
            .reduce((a, b) => a + b) /
        farBlocks.length;
    // Ajusta este valor según el máximo salto/caída de tu juego
    const maxVert = 1000.0;
    // El multiplicador es la distancia vertical normalizada (0..1)
    final multV = (avgFarVert.abs() / maxVert).clamp(0.0, 1.0);
    final verticalDiff = avgYFar - ballPos.y;
    if (verticalDiff > anticipationThreshold) {
      // Drop ahead: anticipate more the further and lower the ground is.
      anchorY = anchorNormal.y + (anchorLower.y - anchorNormal.y) * multV;
      anticipated = true;
    } else if (verticalDiff < -anticipationThreshold) {
      // Climb ahead: anticipate more the further and higher the ground is.
      anchorY = anchorNormal.y + (anchorHigher.y - anchorNormal.y) * multV;
      anticipated = true;
    }
  }

  // Dynamic anticipation from the vertical distance to the nearest block.
  // Find the vertically nearest block, below or above.
  var extra = 0.0;
  if (tilesInPath.isNotEmpty) {
    // Distancia vertical al bloque más cercano (por debajo o por encima)
    final verticalDistances = tilesInPath
        .map((f) => (f.position.y - f.size.y / 2) - ballPos.y)
        .toList();
    final minDistBelow = verticalDistances
        .where((d) => d > 0)
        .fold<double?>(
          null,
          (prev, d) => prev == null ? d : (d < prev ? d : prev),
        );
    final minDistAbove = verticalDistances
        .where((d) => d < 0)
        .fold<double?>(
          null,
          (prev, d) => prev == null ? d : (d > prev ? d : prev),
        );
    const maxExtra = 0.25; // Máximo extra a sumar/restar al anchor
    const maxDist = 8.0; // Distancia máxima para normalizar el extra
    if (minDistBelow != null && minDistBelow > 0) {
      // Si el suelo está por debajo, cuanto más lejos, más baja la cámara
      extra = ((minDistBelow / maxDist).clamp(0.0, 1.0)) * maxExtra;
      anchorY -= extra; // CORREGIDO: restar para bajar la cámara (Y menor)
      anticipated = true;
    } else if (minDistAbove != null && minDistAbove < 0) {
      // Si el suelo está por encima, cuanto más lejos, más sube la cámara
      extra = ((-minDistAbove / maxDist).clamp(0.0, 1.0)) * maxExtra;
      anchorY += extra; // CORREGIDO: sumar para subir la cámara (Y mayor)
      anticipated = true;
    }
  }

  // Si no hay anticipación dinámica, usar lógica de bloques cercanos
  if (!anticipated) {
    if (diffNear > thresholdDown) {
      anchorY = anchorLower.y;
    } else if (diffNear < thresholdUp) {
      anchorY = anchorHigher.y;
    } else {
      anchorY = anchorNormal.y;
    }
  }

  final targetAnchor = Anchor(anchorNormal.x, anchorY);
  if (setTargetAnchor != null) {
    setTargetAnchor(targetAnchor);
  } else {
    camera.viewfinder.anchor = targetAnchor;
  }
}

void adjustCameraForBoostsSmooth(
  CameraComponent camera,
  List<BoostData> boosts,
  Vector2 ballPos,
  double defaultZoom,
  double currentZoom,
  void Function(double newZoom) setTargetZoom, {
  double lerp = 0.08,
}) {
  final boostNear = boosts.any(
    (b) => (b.position.x - ballPos.x).abs() < CameraBehaviorConfig.boostRange,
  );

  final targetZoom = boostNear ? CameraBehaviorConfig.boostZoom : defaultZoom;

  // Aplicar interpolación suave directamente
  final newZoom = currentZoom + (targetZoom - currentZoom) * lerp;
  setTargetZoom(newZoom);
}
