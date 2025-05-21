import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';

class TerrainEvent {
  TerrainEvent({
    required this.index,
    required this.type,
    required this.from,
    required this.to,
  });
  final int index;
  final TerrainEventType type;
  final Vector2 from;
  final Vector2 to;
}

enum TerrainEventType {
  flat,
  ascend,
  descend,
  gap,
}

class LevelGenerator {
  static LevelData generate(
    int seed, {
    int segmentCount = 150,
    double tileSize = 1.5,
    double wallHeight = 12.0,
    int minCheckpoints = 1,
    int maxCheckpoints = 4,
    bool enableBoosts = true,
    bool enableCheckpoints = true,
    bool classicMode = false,
    int maxFlatSegmentLength = 4,
    double flatSegmentChance = 0.6,
    double maxHorizontalGap = 5.0,
    double dropChance = 0.25,
    double maxDropHeight = 2.5,
    double maxHeightChange = 3.0,
    double heightVariationChance = 0.3,
    double difficulty = 0.0,
  }) {
    final rand = Random(seed);
    final tiles = _generateBasePath(
        rand,
        segmentCount,
        tileSize,
        maxFlatSegmentLength,
        flatSegmentChance,
        maxHorizontalGap,
        dropChance,
        maxDropHeight,
        maxHeightChange,
        heightVariationChance,
        difficulty);
    final events = _detectTerrainEvents(tiles, tileSize);
    final floorSize = Vector2(tileSize, tileSize / 2);
    final floorData = <FloorData>[];
    final rampData = <RampData>[];
    final boostData = <BoostData>[];
    final checkpointData = <CheckPointData>[];
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      if (tile.hasFloor) {
        floorData.add(FloorData(position: tile.position, size: floorSize));
      }
    }
    _placeRamps(events, rampData, tileSize);
    _placeBoosts(events, boostData, tileSize, difficulty);
    _placeCheckpoints(events, checkpointData, tiles, tileSize, minCheckpoints,
        maxCheckpoints);
    final path = tiles.where((t) => t.hasFloor).map((t) => t.position).toList();
    final ballStart = path.first + Vector2(0, -tileSize);
    var goalPosition = path.last + Vector2(0, -tileSize * 0.8);
    // --- Meta ---
    var overlaps = true;
    var tries = 0;
    while (overlaps && tries < 10) {
      overlaps = false;
      for (final floor in floorData) {
        if ((goalPosition - floor.position).length < tileSize * 0.8) {
          overlaps = true;
          break;
        }
      }
      for (final ramp in rampData) {
        if ((goalPosition - ramp.position).length < tileSize * 0.8) {
          overlaps = true;
          break;
        }
      }
      if (overlaps) {
        goalPosition += Vector2(0, -tileSize * 0.5);
        tries++;
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

  static List<_Tile> _generateBasePath(
      Random rand,
      int segmentCount,
      double tileSize,
      int maxFlatSegmentLength,
      double flatSegmentChance,
      double maxHorizontalGap,
      double dropChance,
      double maxDropHeight,
      double maxHeightChange,
      double heightVariationChance,
      double difficulty) {
    final tiles = <_Tile>[];
    var x = 0.0;
    var y = 4.0;
    var totalFloors = 0;
    var dropsMade = 0;
    var stepsSinceLastDrop = 0;
    var lastJump = false;
    final maxDrops =
        segmentCount ~/ (6 - (difficulty * 2.5).round()).clamp(2, 8);
    const minDistBetweenDrops = 2;
    final minFlat = (1 - difficulty * 1.0).clamp(1, 2).toInt();
    final maxFlat = (maxFlatSegmentLength - (difficulty * 1.5))
        .clamp(1, maxFlatSegmentLength)
        .toInt();
    final localDropChance = dropChance + difficulty * 0.25;
    final localHeightVar = heightVariationChance + difficulty * 0.25;
    final localMaxDrop = maxDropHeight + difficulty * 2.0;
    final localMaxHeight = maxHeightChange + difficulty * 2.0;
    while (totalFloors < segmentCount) {
      // Decide si toca segmento plano, subida, bajada o salto
      final r = rand.nextDouble();
      if (r < flatSegmentChance - difficulty * 0.15) {
        // Segmento plano
        final flatLength = rand.nextInt(maxFlat - minFlat + 1) + minFlat;
        for (var i = 0; i < flatLength && totalFloors < segmentCount; i++) {
          tiles.add(_Tile(Vector2(x, y)));
          x += tileSize;
          totalFloors++;
          stepsSinceLastDrop++;
          lastJump = false;
        }
      } else if (r < flatSegmentChance + 0.35 + difficulty * 0.15) {
        // Subida o bajada larga con rampas encadenadas
        final isAscend = rand.nextBool();
        final numRamps =
            rand.nextInt(2) + 2 + (difficulty > 0.5 ? 1 : 0); // 2-4 rampas
        double lastY = y;
        // Añade un floor ANTES de la subida/bajada para asegurar transición suelo→rampa
        if (tiles.isEmpty || tiles.last.hasFloor == false) {
          tiles.add(_Tile(Vector2(x, lastY)));
          x += tileSize;
          totalFloors++;
          stepsSinceLastDrop++;
        }
        final double prevFloorY = lastY;
        for (var i = 0; i < numRamps; i++) {
          tiles.add(_Tile(Vector2(x, lastY), hasFloor: false));
          x += tileSize;
          lastY +=
              tileSize * (isAscend ? 1 : -1) * (0.5 + rand.nextDouble() * 0.7);
          totalFloors++;
          stepsSinceLastDrop++;
        }
        // Añade un floor al final de la subida/bajada, garantizando el desnivel
        // Si la diferencia de altura no es suficiente, ajusta la altura del suelo final
        if ((lastY - prevFloorY).abs() < tileSize * 0.5) {
          lastY += tileSize * (isAscend ? 1 : -1) * 0.7;
        }
        tiles.add(_Tile(Vector2(x, lastY)));
        x += tileSize;
        y = lastY; // actualiza y para el siguiente segmento
        totalFloors++;
        stepsSinceLastDrop++;
      } else {
        // Salto/gap
        if (totalFloors > 4 &&
            dropsMade < maxDrops &&
            stepsSinceLastDrop >= minDistBetweenDrops) {
          tiles.add(_Tile(Vector2(x, y), hasFloor: false));
          x += tileSize *
              (1.5 +
                  rand.nextDouble() *
                      maxHorizontalGap *
                      (0.7 + difficulty * 0.6));
          y += tileSize *
              (rand.nextBool() ? 1 : -1) *
              (1.0 + rand.nextDouble() * localMaxDrop);
          dropsMade++;
          stepsSinceLastDrop = 0;
          lastJump = true;
        } else {
          // Si no se puede saltar, añade un floor normal
          tiles.add(_Tile(Vector2(x, y)));
          x += tileSize;
          totalFloors++;
          stepsSinceLastDrop++;
          lastJump = false;
        }
      }
    }
    return tiles;
  }

  static List<TerrainEvent> _detectTerrainEvents(
      List<_Tile> tiles, double tileSize) {
    final events = <TerrainEvent>[];
    for (var i = 1; i < tiles.length; i++) {
      final prev = tiles[i - 1];
      final curr = tiles[i];
      print(
          'TILE $i: prev=(${prev.position.x},${prev.position.y},${prev.hasFloor}) curr=(${curr.position.x},${curr.position.y},${curr.hasFloor})');
      // CORRECCIÓN: No saltar eventos si hay transición de rampa a suelo
      // Antes: if (!prev.hasFloor && curr.hasFloor) continue;
      // Ahora: solo saltar si ambos son rampas (sin suelo)
      if (!prev.hasFloor && !curr.hasFloor) continue;
      final dy = curr.position.y - prev.position.y;
      if (!prev.hasFloor || !curr.hasFloor) {
        print('EVENT GAP at $i');
        events.add(TerrainEvent(
            index: i,
            type: TerrainEventType.gap,
            from: prev.position,
            to: curr.position));
      } else if (dy.abs() < tileSize * 0.2) {
        print('EVENT FLAT at $i');
        events.add(TerrainEvent(
            index: i,
            type: TerrainEventType.flat,
            from: prev.position,
            to: curr.position));
      } else if (dy > 0) {
        print('EVENT ASCEND at $i');
        events.add(TerrainEvent(
            index: i,
            type: TerrainEventType.ascend,
            from: prev.position,
            to: curr.position));
      } else if (dy < 0) {
        print('EVENT DESCEND at $i');
        events.add(TerrainEvent(
            index: i,
            type: TerrainEventType.descend,
            from: prev.position,
            to: curr.position));
      }
    }
    return events;
  }

  static void _placeRamps(
      List<TerrainEvent> events, List<RampData> rampData, double tileSize) {
    // DEBUG: print all events to verify ramp candidates
    print('--- Terrain events for ramps ---');
    for (final e in events) {
      print('Event: ${e.type} from ${e.from} to ${e.to}');
    }
    for (final e in events) {
      if (e.type == TerrainEventType.ascend ||
          e.type == TerrainEventType.descend) {
        final horizontalLength = (e.to.x - e.from.x).abs();
        final verticalLength = (e.to.y - e.from.y).abs();
        print('Ramp candidate: horiz=$horizontalLength vert=$verticalLength');
        if (verticalLength < 0.01 || horizontalLength < 0.01) continue;
        final numRamps = (horizontalLength / tileSize).clamp(1, 4).round();
        final rampLength = horizontalLength / numRamps;
        for (int i = 0; i < numRamps; i++) {
          final t0 = i / numRamps;
          final t1 = (i + 1) / numRamps;
          final base = Vector2(
            e.from.x + (e.to.x - e.from.x) * t0,
            e.from.y + (e.to.y - e.from.y) * t0,
          );
          final top = Vector2(
            e.from.x + (e.to.x - e.from.x) * t1,
            e.from.y + (e.to.y - e.from.y) * t1,
          );
          final rampPos = (base + top) / 2;
          print('Adding ramp at $rampPos size $rampLength');
          rampData.add(RampData(
            position: rampPos,
            size: Vector2(rampLength, tileSize / 2),
            inverted: e.type == TerrainEventType.ascend,
          ));
        }
      }
    }
  }

  static void _placeBoosts(List<TerrainEvent> events, List<BoostData> boostData,
      double tileSize, double difficulty) {
    for (final e in events) {
      if (e.type == TerrainEventType.ascend &&
          (e.to.y - e.from.y) > tileSize * (1.5 + difficulty * 0.7)) {
        boostData.add(BoostData(
          position: e.from - Vector2(0, tileSize * 0.5),
          type: BoostType.jump,
        ));
      }
      if (e.type == TerrainEventType.flat &&
          (e.to.x - e.from.x).abs() > tileSize * (2.5 + difficulty * 1.5)) {
        boostData.add(BoostData(
          position: e.from - Vector2(0, tileSize * 0.5),
          type: BoostType.speed,
        ));
      }
      if (e.type == TerrainEventType.gap &&
          (e.to.x - e.from.x).abs() > tileSize * (4.0 + difficulty * 2.0) &&
          (e.to.y - e.from.y).abs() > tileSize * 2.0) {
        boostData.add(BoostData(
          position: e.from - Vector2(0, tileSize * 0.5),
          type: BoostType.gravity,
        ));
      }
    }
  }

  static void _placeCheckpoints(
      List<TerrainEvent> events,
      List<CheckPointData> checkpointData,
      List<_Tile> tiles,
      double tileSize,
      int minCheckpoints,
      int maxCheckpoints) {
    // Example: place after every Nth event of type ascend or gap
    final checkpointIndices = <int>{};
    for (final e in events) {
      if (e.type == TerrainEventType.ascend || e.type == TerrainEventType.gap) {
        checkpointIndices.add(e.index);
      }
    }
    for (final idx in checkpointIndices.take(maxCheckpoints)) {
      checkpointData.add(CheckPointData(
        position: tiles[idx].position - Vector2(0, tileSize * 0.5),
      ));
    }
  }
}

class _Tile {
  _Tile(this.position, {this.hasFloor = true});
  final Vector2 position;
  final bool hasFloor;
}
