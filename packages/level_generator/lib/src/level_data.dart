import 'package:meta/meta.dart';

/// The width and height of one terrain tile, in meters.
const tileSize = 1.5;

/// An immutable 2D point or size in meters; y grows downwards.
@immutable
class Vec2 {
  /// A point at ([x], [y]).
  const new(this.x, this.y);

  /// Horizontal coordinate, growing to the right.
  final double x;

  /// Vertical coordinate, growing downwards.
  final double y;

  /// The component-wise sum.
  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);

  @override
  bool operator ==(Object other) =>
      other is Vec2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
}

/// A walkable floor run: one solid box from [position] (top-left) of [size].
///
/// Its top is the ground; it may be taller than a tile to fill the space
/// under a ledge.
@immutable
class FloorRun {
  /// A run from [position] (top-left) of [size].
  const new({required this.position, required this.size});

  /// Top-left corner.
  final Vec2 position;

  /// Width and height.
  final Vec2 size;

  /// Left edge.
  double get left => position.x;

  /// Right edge.
  double get right => position.x + size.x;

  /// The ground level, in world y.
  double get top => position.y;

  @override
  bool operator ==(Object other) =>
      other is FloorRun && other.position == position && other.size == size;

  @override
  int get hashCode => Object.hash(position, size);

  @override
  String toString() => 'Floor$position$size';
}

/// A ramp: a right triangle in the box from [position] (top-left) of [size].
///
/// An [ascending] ramp rises to the right: low on its left, high on its right.
@immutable
class Ramp {
  /// A ramp in the box from [position] (top-left) of [size].
  const new({
    required this.position,
    required this.size,
    required this.ascending,
  });

  /// Top-left corner of the ramp's box.
  final Vec2 position;

  /// Width and height of the ramp's box.
  final Vec2 size;

  /// Whether the ramp rises to the right.
  final bool ascending;

  /// Left edge.
  double get left => position.x;

  /// Right edge.
  double get right => position.x + size.x;

  /// The high end's height, in world y.
  double get top => position.y;

  /// The low end's height, in world y.
  double get bottom => position.y + size.y;

  @override
  bool operator ==(Object other) =>
      other is Ramp &&
      other.position == position &&
      other.size == size &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(position, size, ascending);

  @override
  String toString() => 'Ramp$position$size${ascending ? 'up' : 'down'}';
}

/// The kinds of boost.
enum BoostType {
  /// Throws the ball upwards.
  jump,

  /// Throws the ball forwards.
  speed,

  /// Lowers gravity for a while.
  gravity,
}

/// A boost sensor centred at [position].
@immutable
class Boost {
  /// A [type] boost centred at [position].
  const new({required this.position, required this.type});

  /// Centre of the sensor.
  final Vec2 position;

  /// What the boost does.
  final BoostType type;

  @override
  bool operator ==(Object other) =>
      other is Boost && other.position == position && other.type == type;

  @override
  int get hashCode => Object.hash(position, type);

  @override
  String toString() => 'Boost.${type.name}$position';
}

/// A checkpoint sensor centred at [position].
@immutable
class Checkpoint {
  /// A checkpoint centred at [position].
  const new(this.position);

  /// Centre of the sensor.
  final Vec2 position;

  @override
  bool operator ==(Object other) =>
      other is Checkpoint && other.position == position;

  @override
  int get hashCode => position.hashCode;

  @override
  String toString() => 'Checkpoint$position';
}

/// The kinds of section a level is built from, in the order the stages
/// introduce them.
enum SectionKind {
  /// Flat ground.
  flat,

  /// A climb up a ramp.
  rampUp,

  /// A descent down a ramp.
  rampDown,

  /// A gap to jump.
  gap,

  /// A ledge to fall from.
  drop,

  /// A ledge to jump onto.
  stepUp,

  /// A speed boost before a long gap.
  speedBoost,

  /// Gaps separated by short platforms.
  chainedGaps,

  /// A jump boost before a high ledge.
  jumpBoost,

  /// A gravity boost before a long floaty gap.
  gravityBoost,
}

/// One generated level.
@immutable
class LevelData {
  /// A level with all its elements.
  const new({
    required this.seed,
    required this.level,
    required this.ballStart,
    required this.goal,
    required this.floors,
    required this.ramps,
    required this.boosts,
    required this.checkpoints,
    required this.sections,
    required this.estimatedDuration,
  });

  /// The seed the level was generated from.
  final String seed;

  /// The level number, from 1.
  final int level;

  /// Where the ball appears, above the start platform.
  final Vec2 ballStart;

  /// The centre of the goal, standing on the last floor run.
  final Vec2 goal;

  /// Floor runs, left to right.
  final List<FloorRun> floors;

  /// Ramps, left to right.
  final List<Ramp> ramps;

  /// Boosts, left to right.
  final List<Boost> boosts;

  /// Checkpoints, left to right.
  final List<Checkpoint> checkpoints;

  /// The sections the level was built from, in order.
  final List<SectionKind> sections;

  /// Estimated time to play the level, in seconds.
  final double estimatedDuration;

  /// The lowest point of the terrain, in world y (downwards).
  double get lowestPoint {
    var lowest = ballStart.y;
    for (final floor in floors) {
      final bottom = floor.position.y + floor.size.y;
      if (bottom > lowest) lowest = bottom;
    }
    for (final ramp in ramps) {
      if (ramp.bottom > lowest) lowest = ramp.bottom;
    }
    return lowest;
  }

  /// A canonical text form, used to compare levels across platforms.
  String get canonical => [
    'seed=$seed level=$level start=$ballStart goal=$goal',
    ...floors.map((e) => '$e'),
    ...ramps.map((e) => '$e'),
    ...boosts.map((e) => '$e'),
    ...checkpoints.map((e) => '$e'),
  ].join('\n');
}
