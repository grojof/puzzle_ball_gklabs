import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The width and height of one terrain tile, in meters.
const tileSize = 1.5;

/// The ball's radius, in meters.
const ballRadius = 0.2;

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

/// What a floor run's top is made of, and so how the ball moves on it
/// (level-mechanics spec).
enum FloorSurface {
  /// Plain ground.
  plain,

  /// A conveyor belt carrying the ball forwards.
  conveyorForward,

  /// A conveyor belt carrying the ball backwards.
  conveyorBackward,

  /// Ice: slow to speed up and slow to stop.
  ice,

  /// Mud: slow, and it weakens the jump.
  mud,
}

/// A walkable floor run: one solid box from [position] (top-left) of [size].
///
/// Its top is the ground; it may be taller than a tile to fill the space
/// under a ledge.
@immutable
class FloorRun {
  /// A run from [position] (top-left) of [size].
  const new({
    required this.position,
    required this.size,
    this.crumbling = false,
    this.surface = FloorSurface.plain,
  });

  /// Top-left corner.
  final Vec2 position;

  /// Width and height.
  final Vec2 size;

  /// Whether the run collapses a moment after the ball stands on it.
  final bool crumbling;

  /// What the run's top is made of.
  final FloorSurface surface;

  /// Left edge.
  double get left => position.x;

  /// Right edge.
  double get right => position.x + size.x;

  /// The ground level, in world y.
  double get top => position.y;

  @override
  bool operator ==(Object other) =>
      other is FloorRun &&
      other.position == position &&
      other.size == size &&
      other.crumbling == crumbling &&
      other.surface == surface;

  @override
  int get hashCode => Object.hash(position, size, crumbling, surface);

  @override
  String toString() =>
      'Floor$position$size${crumbling ? 'crumbling' : ''}'
      '${surface == FloorSurface.plain ? '' : surface.name}';
}

/// The kinds of curved terrain.
enum CurveKind {
  /// One or more bumps rising above the ground.
  hill,

  /// A smooth dip below the ground.
  halfPipe,

  /// A rounded slope joining two runs at different heights.
  slope,
}

/// A curved stretch of ground between two floor runs, as its top surface
/// from left to right (design D1 of add-curved-terrain-and-physics).
@immutable
class CurvedRun {
  /// A [kind] curve through [points], left to right.
  const new({required this.kind, required this.points});

  /// A [kind] curve from [left] on level ground at [ground], through
  /// [bumps] in a row, each a width and a height (negative for a dip).
  ///
  /// Each bump follows `16 t² (1 − t)²` scaled to its size, which starts and
  /// ends flat, so the curve joins the ground smoothly; points come at most
  /// [step] meters apart. Only exact operations, so the points are the same
  /// on every platform.
  factory bumps({
    required CurveKind kind,
    required double left,
    required double ground,
    required List<(double, double)> bumps,
  }) {
    final points = [Vec2(left, ground)];
    var x = left;
    for (final (width, height) in bumps) {
      final count = (width / step).ceil();
      for (var i = 1; i <= count; i++) {
        final t = i / count;
        final shape = 16 * t * t * (1 - t) * (1 - t);
        points.add(Vec2(x + width * t, ground - height * shape));
      }
      x += width;
    }
    return CurvedRun(kind: kind, points: List.unmodifiable(points));
  }

  /// A rounded slope from [left] at height [from] to height [to], over
  /// [width]: it follows `3 t² − 2 t³`, which starts and ends flat, so it
  /// joins both runs smoothly, with its steepest slope 1.5 times its height
  /// over its width at the middle. Only exact operations.
  factory slope({
    required double left,
    required double from,
    required double to,
    required double width,
  }) {
    final count = (width / step).ceil();
    return CurvedRun(
      kind: CurveKind.slope,
      points: List.unmodifiable([
        for (var i = 0; i <= count; i++)
          Vec2(
            left + width * (i / count),
            from +
                (to - from) * (i / count) * (i / count) * (3 - 2 * (i / count)),
          ),
      ]),
    );
  }

  /// Whether the curve ends higher than it starts.
  bool get rises => points.last.y < points.first.y;

  /// The longest distance between a curve's points, in meters.
  static const step = 0.5;

  /// What the curve is.
  final CurveKind kind;

  /// The top surface, left to right; its ends are at the height of the
  /// floor runs around it.
  final List<Vec2> points;

  /// Left end.
  double get left => points.first.x;

  /// Right end.
  double get right => points.last.x;

  /// The highest point, in world y.
  double get top => points.map((point) => point.y).reduce(math.min);

  /// The lowest point, in world y.
  double get bottom => points.map((point) => point.y).reduce(math.max);

  /// The surface height at [x], between the points around it.
  double heightAt(double x) {
    if (x <= left) return points.first.y;
    for (var i = 1; i < points.length; i++) {
      final b = points[i];
      if (x <= b.x) {
        final a = points[i - 1];
        return a.y + (b.y - a.y) * (x - a.x) / (b.x - a.x);
      }
    }
    return points.last.y;
  }

  @override
  bool operator ==(Object other) =>
      other is CurvedRun &&
      other.kind == kind &&
      other.points.length == points.length &&
      [for (var i = 0; i < points.length; i++) other.points[i] == points[i]]
          .every((same) => same);

  @override
  int get hashCode => Object.hash(kind, Object.hashAll(points));

  @override
  String toString() => 'Curve.${kind.name}${points.join()}';
}

/// A trampoline pad lying on a floor run, from [position] (its left end on
/// the ground) [width] meters to the right. It throws the ball up to the
/// same height every time (level-mechanics spec).
@immutable
class Trampoline {
  /// A pad from [position] (left end, on the ground) of [width].
  const new({required this.position, required this.width});

  /// The pad's left end, on the ground.
  final Vec2 position;

  /// The pad's length, in meters.
  final double width;

  /// Left edge.
  double get left => position.x;

  /// Right edge.
  double get right => position.x + width;

  /// The ground the pad lies on, in world y.
  double get top => position.y;

  @override
  bool operator ==(Object other) =>
      other is Trampoline && other.position == position && other.width == width;

  @override
  int get hashCode => Object.hash(position, width);

  @override
  String toString() => 'Trampoline$position${width.toStringAsFixed(3)}';
}

/// The radius of a loop's track, in meters.
const loopRadius = 1.75;

/// How far before a loop's left side its speed boost stands, in meters:
/// close enough for the boost's speed to carry the ball around.
const loopBoostLead = 0.75;

/// A vertical loop standing on a floor run, its lowest point at [foot], of
/// [radius] (level-mechanics spec).
@immutable
class Loop {
  /// A loop of [radius] whose lowest point is [foot].
  const new({required this.foot, required this.radius});

  /// The loop's lowest point, on the ground.
  final Vec2 foot;

  /// The track's radius, in meters.
  final double radius;

  /// The loop's centre.
  Vec2 get center => Vec2(foot.x, foot.y - radius);

  /// Left edge.
  double get left => foot.x - radius;

  /// Right edge.
  double get right => foot.x + radius;

  /// The highest point, in world y.
  double get top => foot.y - 2 * radius;

  @override
  bool operator ==(Object other) =>
      other is Loop && other.foot == foot && other.radius == radius;

  @override
  int get hashCode => Object.hash(foot, radius);

  @override
  String toString() => 'Loop$foot${radius.toStringAsFixed(3)}';
}

/// How strongly a fan lifts the ball at its base, as a multiple of gravity:
/// the lift fades to nothing at the column's top, so the ball floats halfway
/// up (design D1 of add-dynamic-elements).
const fanLift = 2.0;

/// A fan blowing a column of air from its [base] up to its [top] (world y),
/// between [left] and [right] (level-mechanics spec).
@immutable
class Fan {
  /// A column from [left] to [right], from [base] up to [top].
  const new({
    required this.left,
    required this.right,
    required this.base,
    required this.top,
  });

  /// The column's left side, in meters.
  final double left;

  /// The column's right side, in meters.
  final double right;

  /// Where the fan stands and the column starts, in world y.
  final double base;

  /// Where the column ends, in world y.
  final double top;

  /// The column's height, in meters.
  double get height => base - top;

  /// The height the ball floats at, in world y: where the lift, fading from
  /// [fanLift] times gravity at the base to none at the top, equals gravity.
  double get hover => base - height * (1 - 1 / fanLift);

  /// Whether [x] lies in the column.
  bool covers(double x) => x >= left && x <= right;

  @override
  bool operator ==(Object other) =>
      other is Fan &&
      other.left == left &&
      other.right == right &&
      other.base == base &&
      other.top == top;

  @override
  int get hashCode => Object.hash(left, right, base, top);

  @override
  String toString() =>
      'Fan(${left.toStringAsFixed(3)}..${right.toStringAsFixed(3)}, '
      '${base.toStringAsFixed(3)}..${top.toStringAsFixed(3)})';
}

/// The radius of a bumper, in meters.
const bumperRadius = 0.35;

/// How high a bumper roof's lower edge hangs above the run under it, in
/// meters: above a rolling ball, below any jump (design D2 of
/// add-dynamic-elements).
const bumperRoofHeight = 1.0;

/// How far a riser's bumper is set into the wall, in meters.
const bumperInset = 0.2;

/// A pinball bumper centred at [center]: touching it throws the ball away
/// from it (level-mechanics spec).
@immutable
class Bumper {
  /// A bumper centred at [center].
  const new(this.center);

  /// The bumper's centre.
  final Vec2 center;

  @override
  bool operator ==(Object other) => other is Bumper && other.center == center;

  @override
  int get hashCode => center.hashCode;

  @override
  String toString() => 'Bumper$center';
}

/// The radius of a pendulum's mace, in meters.
const maceRadius = 0.45;

/// How far above the run a mace's lowest point passes at the bottom of its
/// swing, in meters.
const maceClearance = 0.1;

/// The height of the lane a rolling ball takes, in meters: a mace whose
/// lowest point is below it can hit the ball.
const maceLane = 0.55;

/// A pendulum: a mace on a rigid arm of [length] from [pivot], swinging over
/// a run on a rhythm of [period] seconds, shifted by [phase]. In each half
/// swing the mace is above the lane for [clear] times the period (design D3
/// of add-dynamic-elements).
@immutable
class Pendulum {
  /// A pendulum hanging from [pivot].
  const new({
    required this.pivot,
    required this.length,
    required this.period,
    required this.clear,
    required this.phase,
  });

  /// The point it swings from.
  final Vec2 pivot;

  /// From the pivot to the mace's centre, in meters.
  final double length;

  /// Seconds per full swing, there and back.
  final double period;

  /// The share of the period, in each half swing, during which the mace
  /// stays above the lane.
  final double clear;

  /// Seconds into the swing at time zero.
  final double phase;

  /// The run under it, in world y.
  double get ground => pivot.y + length + maceRadius + maceClearance;

  /// How far either side of the pivot the mace can be in the lane, in
  /// meters: only a square root, exact on every platform.
  double get reach {
    final drop = length - (maceLane - maceClearance);
    return math.sqrt(length * length - drop * drop) + maceRadius;
  }

  /// The left end of the mace's reach in the lane.
  double get left => pivot.x - reach;

  /// The right end of the mace's reach in the lane.
  double get right => pivot.x + reach;

  /// How long the lane stays clear in each half swing, in seconds.
  double get clearTime => clear * period;

  @override
  bool operator ==(Object other) =>
      other is Pendulum &&
      other.pivot == pivot &&
      other.length == length &&
      other.period == period &&
      other.clear == clear &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(pivot, length, period, clear, phase);

  @override
  String toString() =>
      'Pendulum$pivot ${length.toStringAsFixed(3)} '
      '${period.toStringAsFixed(3)}/${clear.toStringAsFixed(3)}'
      '+${phase.toStringAsFixed(3)}';
}

/// How far a seesaw's near end rests past the edge of the run before it,
/// in meters.
const seesawCrack = 0.1;

/// A seesaw: a plank of [halfLength] each side of its [pivot], over a pit.
/// At rest it leans back, its near (left) end [rest] meters below the pivot;
/// tipped forwards, its far end is [tip] meters below it (design D4 of
/// add-dynamic-elements). The ends are the plank's top surface.
@immutable
class Seesaw {
  /// A seesaw on [pivot].
  const new({
    required this.pivot,
    required this.halfLength,
    required this.rest,
    required this.tip,
  });

  /// The point it turns on, on the plank's top surface.
  final Vec2 pivot;

  /// From the pivot to either end, in meters.
  final double halfLength;

  /// How far below the pivot the near end rests, in meters.
  final double rest;

  /// How far below the pivot the far end drops when tipped, in meters.
  final double tip;

  double _across(double offset) =>
      math.sqrt(halfLength * halfLength - offset * offset);

  /// The near end at rest, level with the run before it.
  Vec2 get nearEnd => Vec2(pivot.x - _across(rest), pivot.y + rest);

  /// The far end at rest.
  Vec2 get farEndAtRest => Vec2(pivot.x + _across(rest), pivot.y - rest);

  /// The far end when tipped, which the ball jumps from.
  Vec2 get farEnd => Vec2(pivot.x + _across(tip), pivot.y + tip);

  /// Left edge.
  double get left => nearEnd.x;

  /// Right edge: the far end at rest reaches farthest.
  double get right => farEndAtRest.x;

  @override
  bool operator ==(Object other) =>
      other is Seesaw &&
      other.pivot == pivot &&
      other.halfLength == halfLength &&
      other.rest == rest &&
      other.tip == tip;

  @override
  int get hashCode => Object.hash(pivot, halfLength, rest, tip);

  @override
  String toString() =>
      'Seesaw$pivot ${halfLength.toStringAsFixed(3)} '
      '${rest.toStringAsFixed(3)}/${tip.toStringAsFixed(3)}';
}

/// A strip of spikes lying on a floor run, from [position] (its left end on
/// the ground) [width] meters to the right. Touching it sends the ball back.
@immutable
class SpikeStrip {
  /// A strip from [position] (left end, on the ground) of [width].
  const new({required this.position, required this.width});

  /// The strip's left end, on the ground.
  final Vec2 position;

  /// The strip's length, in meters.
  final double width;

  /// Left edge.
  double get left => position.x;

  /// Right edge.
  double get right => position.x + width;

  /// The ground the strip lies on, in world y.
  double get top => position.y;

  @override
  bool operator ==(Object other) =>
      other is SpikeStrip && other.position == position && other.width == width;

  @override
  int get hashCode => Object.hash(position, width);

  @override
  String toString() => 'Spikes$position${width.toStringAsFixed(3)}';
}

/// A platform that shuttles between [start] and [end] (top-left positions)
/// at [speed], pausing [pause] seconds at each end.
@immutable
class MovingPlatform {
  /// A platform of [size] moving between [start] and [end].
  const new({
    required this.start,
    required this.end,
    required this.size,
    required this.speed,
    required this.pause,
  });

  /// Top-left corner at the near end of the path.
  final Vec2 start;

  /// Top-left corner at the far end of the path.
  final Vec2 end;

  /// Width and height.
  final Vec2 size;

  /// Speed along the path, in m/s.
  final double speed;

  /// The pause at each end, in seconds.
  final double pause;

  @override
  bool operator ==(Object other) =>
      other is MovingPlatform &&
      other.start == start &&
      other.end == end &&
      other.size == size &&
      other.speed == speed &&
      other.pause == pause;

  @override
  int get hashCode => Object.hash(start, end, size, speed, pause);

  @override
  String toString() =>
      'Platform$start->$end$size'
      ' v=${speed.toStringAsFixed(3)} p=${pause.toStringAsFixed(3)}';
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

/// A laser barrier: a vertical beam at [x] from [top] down to [bottom]
/// (world y), on for [on] seconds and off for [off], shifted by [phase].
/// Touching it while on sends the ball back.
@immutable
class LaserBarrier {
  /// A barrier at [x] between [top] and [bottom], with its rhythm.
  const new({
    required this.x,
    required this.top,
    required this.bottom,
    required this.on,
    required this.off,
    required this.phase,
  });

  /// Horizontal position, in meters.
  final double x;

  /// The beam's upper end, in world y.
  final double top;

  /// The beam's lower end, in world y.
  final double bottom;

  /// Seconds lit per cycle.
  final double on;

  /// Seconds dark per cycle.
  final double off;

  /// Seconds into the cycle at time zero.
  final double phase;

  /// Whether the beam is lit at [time] seconds.
  bool isOnAt(double time) => (time + phase) % (on + off) < on;

  @override
  bool operator ==(Object other) =>
      other is LaserBarrier &&
      other.x == x &&
      other.top == top &&
      other.bottom == bottom &&
      other.on == on &&
      other.off == off &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(x, top, bottom, on, off, phase);

  @override
  String toString() =>
      'Laser(${x.toStringAsFixed(3)}, ${top.toStringAsFixed(3)}..'
      '${bottom.toStringAsFixed(3)}) ${on.toStringAsFixed(3)}/'
      '${off.toStringAsFixed(3)}+${phase.toStringAsFixed(3)}';
}

/// A stretch of the course, from [left] to [right], where the ball has an
/// adrenaline rush: its push is stronger (level-mechanics spec).
@immutable
class AdrenalineZone {
  /// A zone from [left] to [right].
  const new({required this.left, required this.right});

  /// Where the zone starts, in meters.
  final double left;

  /// Where the zone ends, in meters.
  final double right;

  /// Whether [x] lies in the zone.
  bool covers(double x) => x >= left && x <= right;

  @override
  bool operator ==(Object other) =>
      other is AdrenalineZone && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(left, right);

  @override
  String toString() =>
      'Adrenaline(${left.toStringAsFixed(3)}..${right.toStringAsFixed(3)})';
}

/// The kinds of boost.
enum BoostType {
  /// Throws the ball upwards.
  jump,

  /// Throws the ball forwards.
  speed,

  /// Lowers gravity for a while.
  gravity,

  /// An orb that charges one jump in mid-air.
  doubleJump,
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

/// A checkpoint whose post stands at [position].
@immutable
class Checkpoint {
  /// A checkpoint standing at [position].
  const new(this.position);

  /// The foot of the post, on the ground.
  final Vec2 position;

  @override
  bool operator ==(Object other) =>
      other is Checkpoint && other.position == position;

  @override
  int get hashCode => position.hashCode;

  @override
  String toString() => 'Checkpoint$position';
}

/// The kinds of section a level is built from.
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

  /// Island hops: gaps separated by short platforms at changing heights.
  chainedGaps,

  /// A jump boost before a high ledge.
  jumpBoost,

  /// A gravity boost before a long floaty gap.
  gravityBoost,

  /// Two or three steps up with short treads between them.
  staircase,

  /// Two or three drops with short treads between them.
  cascade,

  /// A ramp down, a gap and a ramp up back to the same height.
  valley,

  /// A strip of spikes to jump over.
  spikes,

  /// A gap too wide to jump, bridged by a moving platform.
  ferry,

  /// Island hops whose islands crumble.
  crumblingHops,

  /// A double-jump orb before a gap beyond one jump.
  orbGap,

  /// A double-jump orb before a climb beyond one jump.
  orbClimb,

  /// A long climb by four to six tall steps, some with a gap before them.
  tower,

  /// A long way down by drops, ramps down and gaps.
  descent,

  /// One to three bumps in a row.
  hill,

  /// A smooth dip to roll through.
  halfPipe,

  /// Trampoline islands across a pit.
  trampolineHops,

  /// A conveyor belt before a gap.
  conveyor,

  /// Ice before a gap.
  ice,

  /// Mud before a gap or a climb.
  mud,

  /// A speed boost and a vertical loop.
  loop,

  /// The end of a flow phrase where carrying its speed fails: a short tread
  /// before a riser, spikes just past a landing, or a gap right after a
  /// crest (design D3 of flow-and-pacing).
  breakPoint,

  /// Fans that float the ball across a pit too wide to jump.
  fanGap,

  /// A fan at the foot of a wall higher than a jump boost reaches.
  fanClimb,

  /// A drop gap under a roof of bumpers: rolling off clears it, a jump hits
  /// the roof.
  bumperRoof,

  /// Maces swinging over a run, each with room to wait before it.
  pendulums,

  /// A seesaw over a pit, ridden down and jumped from.
  seesaw,
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
    this.hazards = const [],
    this.platforms = const [],
    this.lasers = const [],
    this.curves = const [],
    this.trampolines = const [],
    this.loops = const [],
    this.adrenaline = const [],
    this.fans = const [],
    this.bumpers = const [],
    this.pendulums = const [],
    this.seesaws = const [],
    this.featured = const [],
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

  /// Spike strips, left to right.
  final List<SpikeStrip> hazards;

  /// Moving platforms, left to right.
  final List<MovingPlatform> platforms;

  /// Laser barriers, left to right.
  final List<LaserBarrier> lasers;

  /// Curved stretches of ground, left to right.
  final List<CurvedRun> curves;

  /// Trampolines, left to right.
  final List<Trampoline> trampolines;

  /// Loops, left to right.
  final List<Loop> loops;

  /// Adrenaline zones, left to right.
  final List<AdrenalineZone> adrenaline;

  /// Fans, left to right.
  final List<Fan> fans;

  /// Bumpers, left to right.
  final List<Bumper> bumpers;

  /// Pendulums, left to right.
  final List<Pendulum> pendulums;

  /// Seesaws, left to right.
  final List<Seesaw> seesaws;

  /// The sections the level was built from, in order.
  final List<SectionKind> sections;

  /// The sections this level features, which make up most of its obstacles
  /// and give it its character.
  final List<SectionKind> featured;

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
    for (final curve in curves) {
      if (curve.bottom > lowest) lowest = curve.bottom;
    }
    for (final fan in fans) {
      if (fan.base > lowest) lowest = fan.base;
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
    ...hazards.map((e) => '$e'),
    ...platforms.map((e) => '$e'),
    ...lasers.map((e) => '$e'),
    ...curves.map((e) => '$e'),
    ...trampolines.map((e) => '$e'),
    ...loops.map((e) => '$e'),
    ...adrenaline.map((e) => '$e'),
    ...fans.map((e) => '$e'),
    ...bumpers.map((e) => '$e'),
    ...pendulums.map((e) => '$e'),
    ...seesaws.map((e) => '$e'),
  ].join('\n');
}
