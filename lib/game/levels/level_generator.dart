import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';

class LevelGenerator {
  static LevelData generate(
    int seed, {
    // ──────────────── 📦 Estructura general ────────────────
    int segmentCount = 150,
    double tileSize = 1.5,
    double wallHeight = 12.0,
    int minCheckpoints = 1,
    int maxCheckpoints = 4,
    bool enableBoosts = true,
    bool enableCheckpoints = true,
    bool classicMode = false,
    // ──────────────── 📏 Suelo plano ────────────────
    int maxFlatSegmentLength = 4,
    double flatSegmentChance = 0.6, // 60% de posibilidad de checkpoint
    double maxHorizontalGap = 5.0, // solo usado si no es bloque seguido

    // ──────────────── ⬇️ Caídas (saltos) ────────────────
    double dropChance = 0.25,
    double maxDropHeight = 2.5,

    // ──────────────── ⛰️ Subidas / bajadas ────────────────
    double maxHeightChange = 3.0,
    double heightVariationChance = 0.3,
  }) {
    final rand = Random(seed);
    final path = <Vector2>[];

    var x = 0.0;
    var y = 4.0;
    var totalFloors = 0;
    var dropsMade = 0;
    var stepsSinceLastDrop = 0;
    var lastJump = false;

    final maxDrops = segmentCount ~/ 7;
    const minDistBetweenDrops = 3;
    final tiles = <_Tile>[];

    while (totalFloors < segmentCount) {
      final isFlatSegment = rand.nextDouble() < flatSegmentChance;
      final flatLength =
          isFlatSegment ? rand.nextInt(maxFlatSegmentLength) + 1 : 1;

      for (var i = 0; i < flatLength && totalFloors < segmentCount; i++) {
        tiles.add(_Tile(Vector2(x, y)));

        // Si es un segmento plano, no hay separación
        final gap = isFlatSegment ? 0.0 : rand.nextDouble() * maxHorizontalGap;
        x += tileSize * (1.0 + gap);

        // Variación de altura
        if (!lastJump && rand.nextDouble() < heightVariationChance) {
          final deltaY = tileSize *
              (rand.nextInt((maxHeightChange * 2).round() + 1) -
                      maxHeightChange)
                  .round();
          y = (y + deltaY).clamp(0.0, double.infinity);
        }

        totalFloors++;
        stepsSinceLastDrop++;
        lastJump = false;
      }

      // Intentar colocar una caída
      final canDrop = totalFloors > 4 &&
          dropsMade < maxDrops &&
          stepsSinceLastDrop >= minDistBetweenDrops &&
          rand.nextDouble() < dropChance &&
          (segmentCount - totalFloors) > 4;

      if (canDrop) {
        tiles.add(_Tile(Vector2(x, y), hasFloor: false));
        x += tileSize * (1.0 + rand.nextDouble() * maxHorizontalGap);
        y += tileSize * (1.0 + rand.nextDouble() * maxDropHeight);
        dropsMade++;
        stepsSinceLastDrop = 0;
        lastJump = true;
      }
    }

    // Construcción de componentes físicos
    final floorSize = Vector2(tileSize, tileSize);

    final floorData = <FloorData>[];
    final rampData = <RampData>[];
    final boostData = <BoostData>[];
    final checkpointData = <CheckPointData>[];

    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      if (tile.hasFloor) {
        floorData.add(FloorData(position: tile.position, size: floorSize));
        path.add(tile.position);
      }

      if (i < tiles.length - 1) {
        final curr = tiles[i];
        final next = tiles[i + 1];
        if (!curr.hasFloor || !next.hasFloor) continue;

        final dy = next.position.y - curr.position.y;
        if (dy.abs() >= tileSize * 0.9) {
          final isAscending = dy > 0;
          final rampPos = isAscending
              ? curr.position + Vector2(tileSize, 0)
              : next.position + Vector2(-tileSize, 0);

          rampData.add(
            RampData(
              position: rampPos,
              size: Vector2(tileSize, tileSize),
              inverted: isAscending,
            ),
          );
        }
      }
    }

    final ballStart = path.first + Vector2(0, -tileSize);

    // Calcular posición de la meta (goal)
    var goalPosition = path.last;
    // Verifica que no se solape con ningún Floor ni Ramp
    var overlaps = true;
    var tries = 0;
    while (overlaps && tries < 10) {
      overlaps = false;
      var additionalLiftH = 0.0;
      var additionalLiftV = 0.0;

      for (final floor in floorData) {
        if ((goalPosition - floor.position).length < tileSize) {
          overlaps = true;
          break;
        }
      }

      for (final ramp in rampData) {
        if ((goalPosition - ramp.position).length < tileSize) {
          overlaps = true;
          // Eleva un poco más si hay rampa
          additionalLiftH = tileSize + (tileSize / 2);
          additionalLiftV = 1;
          break;
        }
      }

      if (overlaps) {
        goalPosition +=
            Vector2(additionalLiftH, -((tileSize * 0.6) / 2) - additionalLiftV);
        tries++;
      }
    }

    // Algoritmo para boosts y checkpoints (solo si no es modo clásico)
    if (!classicMode) {
      // Añadir checkpoints según longitud
      if (enableCheckpoints && segmentCount > 20) {
        final numCheckpoints = minCheckpoints +
            (segmentCount ~/ 50).clamp(0, maxCheckpoints - minCheckpoints);
        for (var i = 1; i <= numCheckpoints; i++) {
          final idx = (tiles.length * i ~/ (numCheckpoints + 1))
              .clamp(1, tiles.length - 2);
          checkpointData.add(
            CheckPointData(
              position: tiles[idx].position - Vector2(0, tileSize * 0.5),
            ),
          );
        }
      }
      // Añadir boosts según condiciones
      if (enableBoosts) {
        for (var i = 1; i < tiles.length - 1; i++) {
          final prev = tiles[i - 1];
          final curr = tiles[i];
          final next = tiles[i + 1];
          // Boost de salto: diferencia de altura grande
          if (curr.hasFloor &&
              next.hasFloor &&
              (next.position.y - curr.position.y).abs() > tileSize * 1.2) {
            boostData.add(
              BoostData(
                position: curr.position - Vector2(0, tileSize * 0.5),
                type: BoostType.jump,
              ),
            );
          }
          // Boost de velocidad: rampa larga seguida de salto
          if (curr.hasFloor &&
              next.hasFloor &&
              (next.position.x - curr.position.x).abs() > tileSize * 2.5) {
            boostData.add(
              BoostData(
                position: curr.position - Vector2(0, tileSize * 0.5),
                type: BoostType.speed,
              ),
            );
          }
          // Boost de gravedad: separación horizontal muy grande
          if (!curr.hasFloor &&
              (next.position.x - prev.position.x).abs() > tileSize * 2.5) {
            boostData.add(
              BoostData(
                position: curr.position - Vector2(0, tileSize * 0.5),
                type: BoostType.gravity,
              ),
            );
          }
        }
      }
    }

    return LevelData(
      ballStart: ballStart,
      goalPosition: goalPosition,
      floorData: floorData,
      rampData: rampData,
      boostData: boostData,
      checkpointData: checkpointData,
    );
  }
}

class _Tile {
  _Tile(this.position, {this.hasFloor = true});
  final Vector2 position;
  final bool hasFloor;
}
