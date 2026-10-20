import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

import '../helpers/envelope.dart';

const double _tile = tileSize;

FloorRun floor(double left, double top, {double tiles = 3, double fill = 0}) =>
    FloorRun(
      position: Vec2(left, top),
      size: Vec2(tiles * _tile, _tile + fill),
    );

/// A valid two-run level with a small gap; tests break one rule at a time.
LevelData course({
  List<FloorRun>? floors,
  List<Ramp> ramps = const [],
  List<Boost> boosts = const [],
  List<Checkpoint> checkpoints = const [],
  List<SpikeStrip> hazards = const [],
  List<MovingPlatform> platforms = const [],
  List<LaserBarrier> lasers = const [],
  List<CurvedRun> curves = const [],
  List<Trampoline> trampolines = const [],
  List<Loop> loops = const [],
  List<AdrenalineZone> adrenaline = const [],
  List<Fan> fans = const [],
  List<Bumper> bumpers = const [],
  List<Pendulum> pendulums = const [],
  List<Seesaw> seesaws = const [],
  Vec2 ballStart = const Vec2(0.75, 3),
  Vec2? goal,
}) {
  final runs = floors ?? [floor(0, 4), floor(4.5 + 1.5, 4)];
  return LevelData(
    seed: 'test',
    level: 1,
    ballStart: ballStart,
    goal: goal ?? Vec2(runs.last.right - _tile / 2, runs.last.top - 1.75),
    floors: runs,
    ramps: ramps,
    boosts: boosts,
    checkpoints: checkpoints,
    hazards: hazards,
    platforms: platforms,
    lasers: lasers,
    curves: curves,
    trampolines: trampolines,
    loops: loops,
    adrenaline: adrenaline,
    fans: fans,
    bumpers: bumpers,
    pendulums: pendulums,
    seesaws: seesaws,
    sections: const [],
    estimatedDuration: 10,
  );
}

void main() {
  const validator = LevelValidator(envelope: testEnvelope);
  List<String> check(LevelData level, {double margin = 0.5}) =>
      validator.validate(level, margin: margin);

  group('LevelValidator', () {
    test('accepts a valid course', () {
      expect(check(course()), isEmpty);
    });

    test('rejects a level without floors', () {
      expect(check(course(floors: const [], goal: const Vec2(0, 0))), [
        'the level has no floor',
      ]);
    });

    test('rejects overlapping floors', () {
      expect(
        check(course(floors: [floor(0, 4), floor(3, 4)])),
        contains(startsWith('floors overlap')),
      );
    });

    test('rejects gaps beyond the reach of the current speed', () {
      expect(
        check(course(floors: [floor(0, 4), floor(4.5 + 6, 4)])),
        contains(startsWith('gap of')),
      );
    });

    test('a speed boost allows a wider gap, and a gravity boost too', () {
      final wide = [floor(0, 4), floor(4.5 + 6, 4), floor(10.5 + 4.5 + 6, 4)];
      expect(
        check(
          course(
            floors: wide,
            boosts: const [
              Boost(position: Vec2(3.75, 3.4), type: BoostType.speed),
              Boost(position: Vec2(14.25, 3.4), type: BoostType.gravity),
            ],
          ),
          margin: 0.8,
        ),
        isEmpty,
      );
    });

    test('rejects climbs beyond a jump, unless a jump boost precedes them', () {
      final steps = [floor(0, 4), floor(4.5, 1)];
      expect(check(course(floors: steps)), contains(startsWith('climb of')));
      expect(
        check(
          course(
            floors: [floor(0, 4), floor(4.5, 1, fill: 3)],
            boosts: const [
              Boost(position: Vec2(3.9, 3.4), type: BoostType.jump),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('rejects a ledge that leaves a gap below it', () {
      expect(
        check(course(floors: [floor(0, 4), floor(4.5, 2.3)])),
        contains(startsWith('ledge at')),
      );
    });

    test('accepts drops, and ramps that join their floors', () {
      expect(check(course(floors: [floor(0, 4), floor(4.5, 7)])), isEmpty);
      final joined = course(
        floors: [floor(0, 4), floor(6, 2)],
        ramps: const [
          Ramp(position: Vec2(4.5, 2), size: Vec2(1.5, 2), ascending: true),
        ],
      );
      expect(check(joined), isEmpty);
      final down = course(
        floors: [floor(0, 4), floor(6, 6)],
        ramps: const [
          Ramp(position: Vec2(4.5, 4), size: Vec2(1.5, 2), ascending: false),
        ],
      );
      expect(check(down), isEmpty);
    });

    test('rejects ramps that do not join their floors', () {
      final broken = course(
        floors: [floor(0, 4), floor(6, 3)],
        ramps: const [
          Ramp(position: Vec2(4.5, 2), size: Vec2(1.5, 2), ascending: true),
        ],
      );
      expect(check(broken), contains(startsWith('ramp at')));
    });

    test('checks the start platform and the ball', () {
      expect(
        check(course(floors: [floor(0, 4, tiles: 2), floor(4.5, 4)])),
        contains('start platform shorter than three tiles'),
      );
      expect(
        check(course(ballStart: const Vec2(0.75, 5))),
        contains('ball does not start above the start platform'),
      );
    });

    test('checks the goal run and the goal', () {
      expect(
        check(course(floors: [floor(0, 4), floor(6, 4, tiles: 2)])),
        contains('goal run shorter than three tiles'),
      );
      expect(
        check(course(goal: const Vec2(7, 2.25))),
        contains('goal does not stand at the end of the last run'),
      );
    });

    group('spikes', () {
      // A start run, a long middle run for the spikes, and the goal run.
      final runs = [floor(0, 4), floor(6, 4, tiles: 5), floor(15, 4)];
      List<String> spikes(
        SpikeStrip strip, {
        List<Checkpoint> checkpoints = const [],
        double margin = 0.3,
      }) => check(
        course(floors: runs, hazards: [strip], checkpoints: checkpoints),
        margin: margin,
      );

      test('accepts a strip inside a run that a jump clears', () {
        expect(
          spikes(const SpikeStrip(position: Vec2(7.5, 4), width: 1.5)),
          isEmpty,
        );
      });

      test('rejects a strip wider than a jump from the run-up', () {
        expect(
          spikes(const SpikeStrip(position: Vec2(7.5, 4), width: 4.5)),
          contains(startsWith('spikes of')),
        );
      });

      test('rejects a strip less than a tile from a run end', () {
        expect(
          spikes(const SpikeStrip(position: Vec2(6.5, 4), width: 1.5)),
          contains(endsWith('do not lie inside a run')),
        );
      });

      test('rejects a strip on the start run', () {
        expect(
          spikes(const SpikeStrip(position: Vec2(1.5, 4), width: 1.5)),
          contains(endsWith('lie on the start or goal')),
        );
      });

      test('rejects a strip under a checkpoint', () {
        expect(
          spikes(
            const SpikeStrip(position: Vec2(7.5, 4), width: 1.5),
            checkpoints: const [Checkpoint(Vec2(8, 4))],
          ),
          contains(endsWith('lie under an element')),
        );
      });
    });

    test('rejects a floor run shorter than a tile', () {
      final level = course(
        floors: [
          floor(0, 4),
          const FloorRun(position: Vec2(6, 4), size: Vec2(0, _tile)),
          floor(7.5, 4),
        ],
      );
      expect(check(level), contains(endsWith('is shorter than a tile')));
    });

    test('rejects a crumbling island shorter than a tile', () {
      final level = course(
        floors: [
          floor(0, 4),
          const FloorRun(
            position: Vec2(6, 4),
            size: Vec2(0.75, _tile),
            crumbling: true,
          ),
          floor(8.25, 4),
        ],
      );
      expect(check(level), contains(endsWith('is too short')));
    });

    group('orbs', () {
      const orb = Boost(position: Vec2(3.75, 3.4), type: BoostType.doubleJump);

      test('reject a climb a plain jump makes', () {
        final level = course(
          floors: [floor(0, 4), floor(4.5, 3, fill: 1)],
          boosts: const [orb],
        );
        expect(check(level), contains(endsWith('serves no high climb')));
      });

      test('reject a gap a plain jump clears', () {
        expect(
          check(course(boosts: const [orb])),
          contains(endsWith('serves no long gap')),
        );
      });

      test('allow a climb and a gap within the double jump', () {
        final climb = course(
          floors: [floor(0, 4), floor(4.5, 1.5, fill: 2.5)],
          boosts: const [orb],
        );
        expect(check(climb, margin: 0.8), isEmpty);
        final gap = course(
          floors: [floor(0, 4), floor(4.5 + 9, 4)],
          boosts: const [orb],
        );
        expect(check(gap, margin: 0.8), isEmpty);
      });
    });

    group('ferries', () {
      final runs = [floor(0, 4), floor(14.5, 4)];
      MovingPlatform ferry({double end = 11.35, double speed = 2.2}) =>
          MovingPlatform(
            start: const Vec2(4.65, 4),
            end: Vec2(end, 4),
            size: const Vec2(3, 0.5),
            speed: speed,
            pause: 0.8,
          );

      test('bridge a gap too wide to jump', () {
        expect(check(course(floors: runs, platforms: [ferry()])), isEmpty);
      });

      test('must reach both edges', () {
        expect(
          check(course(floors: runs, platforms: [ferry(end: 10)])),
          contains(endsWith('does not reach its edges')),
        );
      });

      test('move at a speed the ball can ride', () {
        expect(
          check(course(floors: runs, platforms: [ferry(speed: 5)])),
          contains(contains('moves at 5')),
        );
      });

      test('have a clear path', () {
        final blocked = course(
          floors: runs,
          platforms: [ferry()],
          boosts: const [Boost(position: Vec2(9, 3.4), type: BoostType.jump)],
        );
        expect(check(blocked), contains(startsWith('something blocks')));
      });
    });

    group('laser barriers', () {
      LaserBarrier laser({double bottom = -0.5, double top = -10}) =>
          LaserBarrier(
            x: 3,
            top: top,
            bottom: bottom,
            on: 1.4,
            off: 1,
            phase: 0,
          );

      test('accept a barrier above every jump of the route', () {
        expect(check(course(lasers: [laser()])), isEmpty);
      });

      test('reject a barrier a jump reaches', () {
        expect(
          check(course(lasers: [laser(bottom: 2)])),
          contains(endsWith('reaches the route')),
        );
      });

      test('reject a malformed barrier', () {
        expect(
          check(course(lasers: [laser(top: 0)])),
          contains(endsWith('is malformed')),
        );
      });
    });

    test('requires boosts above ground and checkpoints on it', () {
      final floating = course(
        boosts: const [Boost(position: Vec2(5, 3.4), type: BoostType.speed)],
        checkpoints: const [Checkpoint(Vec2(1, 1))],
      );
      final violations = check(floating);
      expect(violations, contains(startsWith('boost at')));
      expect(violations, contains(startsWith('checkpoint at')));
    });
  });

  group('LevelValidator on the new physics', () {
    const validator = LevelValidator(envelope: testEnvelope);
    List<String> check(LevelData level, {double margin = 0.9}) =>
        validator.validate(level, margin: margin);

    group('curves', () {
      CurvedRun bump(double height, {double left = 4.5, double? width}) =>
          CurvedRun.bumps(
            kind: height > 0 ? CurveKind.hill : CurveKind.halfPipe,
            left: left,
            ground: 4,
            bumps: [(width ?? 4.4 * height.abs(), height)],
          );

      test('accept hills and half-pipes that join their runs', () {
        for (final height in [2.0, -2.0]) {
          final curve = bump(height);
          expect(
            check(
              course(
                floors: [floor(0, 4), floor(curve.right, 4)],
                curves: [curve],
              ),
            ),
            isEmpty,
          );
        }
      });

      test('reject a curve with no run before it or none after it', () {
        final curve = bump(2);
        expect(
          check(
            course(
              floors: [floor(0, 4), floor(curve.right + 1, 4)],
              curves: [curve],
            ),
          ),
          contains(endsWith('does not join its floors')),
        );
        expect(
          check(
            course(
              floors: [floor(0, 4), floor(curve.right + 3, 4)],
              curves: [bump(2, left: 5)],
            ),
          ),
          contains(endsWith('does not join its floors')),
        );
      });

      test('accept slopes up and down that join their runs', () {
        final up = CurvedRun.slope(left: 4.5, from: 4, to: 2, width: 4.4);
        expect(
          check(
            course(floors: [floor(0, 4), floor(up.right, 2)], curves: [up]),
          ),
          isEmpty,
        );
        final down = CurvedRun.slope(left: 4.5, from: 4, to: 6, width: 4.4);
        expect(
          check(
            course(floors: [floor(0, 4), floor(down.right, 6)], curves: [down]),
          ),
          isEmpty,
        );
      });

      test('reject a slope that turns back or ends level', () {
        final wavy = CurvedRun(kind: CurveKind.slope, points: bump(2).points);
        expect(
          check(
            course(floors: [floor(0, 4), floor(wavy.right, 4)], curves: [wavy]),
          ),
          contains(endsWith('is malformed')),
        );
        const turning = CurvedRun(
          kind: CurveKind.slope,
          points: [Vec2(4.5, 4), Vec2(5, 3.8), Vec2(5.5, 3.9)],
        );
        expect(
          check(
            course(floors: [floor(0, 4), floor(5.5, 3.9)], curves: [turning]),
          ),
          contains(endsWith('is malformed')),
        );
      });

      test('reject a curve too steep or the wrong way up', () {
        final steep = bump(2, width: 3);
        expect(
          check(
            course(
              floors: [floor(0, 4), floor(steep.right, 4)],
              curves: [steep],
            ),
          ),
          contains(endsWith('is malformed')),
        );
        final upsideDown = CurvedRun(
          kind: CurveKind.hill,
          points: bump(-2).points,
        );
        expect(
          check(
            course(
              floors: [floor(0, 4), floor(upsideDown.right, 4)],
              curves: [upsideDown],
            ),
          ),
          contains(endsWith('is malformed')),
        );
        final pipeUp = CurvedRun(
          kind: CurveKind.halfPipe,
          points: bump(2).points,
        );
        expect(
          check(
            course(
              floors: [floor(0, 4), floor(pipeUp.right, 4)],
              curves: [pipeUp],
            ),
          ),
          contains(endsWith('is malformed')),
        );
      });
    });

    group('trampolines', () {
      const pad = Trampoline(position: Vec2(3, 4), width: 1.5);

      test('reject one before a climb or level ground, not a pit', () {
        for (final next in [floor(4.5, 0, fill: 4), floor(4.5, 4)]) {
          expect(
            check(
              course(floors: [floor(0, 4), next], trampolines: const [pad]),
            ),
            contains(endsWith('serves no pit')),
          );
        }
      });

      test('allow a gap within the bounce from an island', () {
        final runs = [
          floor(0, 4),
          floor(6, 4, tiles: 1),
          floor(6 + 1.5 + 9, 4),
        ];
        expect(check(course(floors: runs)), contains(startsWith('gap of')));
        expect(
          check(
            course(
              floors: runs,
              trampolines: const [Trampoline(position: Vec2(6, 4), width: 1.5)],
            ),
          ),
          isEmpty,
        );
      });

      test('must lie on a run', () {
        expect(
          check(
            course(
              trampolines: const [Trampoline(position: Vec2(3, 2), width: 1.5)],
            ),
          ),
          contains(endsWith('does not lie on a run')),
        );
      });
    });

    group('loops', () {
      const loop = Loop(foot: Vec2(10, 4), radius: loopRadius);
      final boost = Boost(
        position: Vec2(loop.left - loopBoostLead, 3.4),
        type: BoostType.speed,
      );
      final runs = [floor(0, 4, tiles: 10)];

      test('accept a loop with its boost on a long enough run', () {
        expect(
          check(course(floors: runs, loops: const [loop], boosts: [boost])),
          isEmpty,
        );
      });

      test('reject a loop off its run, without a boost, or blocked', () {
        expect(
          check(
            course(
              floors: [floor(0, 4, tiles: 8)],
              loops: const [loop],
              boosts: [boost],
            ),
          ),
          contains(endsWith('does not stand on a run')),
        );
        expect(
          check(course(floors: runs, loops: const [loop])),
          contains(endsWith('has no speed boost')),
        );
        expect(
          check(
            course(
              floors: runs,
              loops: const [loop],
              boosts: [boost],
              checkpoints: const [Checkpoint(Vec2(10, 4))],
            ),
          ),
          contains(startsWith('something blocks the loop')),
        );
      });
    });

    group('surfaces', () {
      FloorRun surfaced(double left, FloorSurface surface) => FloorRun(
        position: Vec2(left, 4),
        size: const Vec2(3 * _tile, _tile),
        surface: surface,
      );

      test('mud shortens the gaps and climbs after it', () {
        final gap = [
          floor(0, 4),
          surfaced(4.5, FloorSurface.mud),
          floor(13, 4),
        ];
        expect(check(course(floors: gap)), contains(startsWith('gap of')));
        final plainGap = [
          floor(0, 4),
          surfaced(4.5, FloorSurface.plain),
          floor(13, 4),
        ];
        expect(check(course(floors: plainGap)), isEmpty);
        final climb = [
          floor(0, 4),
          surfaced(4.5, FloorSurface.mud),
          floor(9, 2, fill: 2),
        ];
        expect(check(course(floors: climb)), contains(startsWith('climb of')));
      });

      test('gap shares read the reach from the surface', () {
        final gap = [
          floor(0, 4),
          surfaced(4.5, FloorSurface.ice),
          floor(11, 4),
        ];
        expect(validator.gapShares(course(floors: gap)), hasLength(1));
      });

      test('reject backward belts faster than the ball pushes', () {
        const fast = LevelValidator(
          envelope: MovementEnvelope(
            jumpHeight: 2.65,
            flightTime: 1.5,
            topSpeed: 8.3,
            speedCurve: [3, 8.3],
            jumpBoostHeight: 6.4,
            speedBoostJumpDistance: 21.5,
            speedBoostGain: 15.5,
            gravityBoostJumpDistance: 28,
            doubleJumpHeight: 5.3,
            doubleJumpDistance: 22,
            curveExitSpeed: 4,
            trampolineHeight: 4.8,
            trampolineFlightTime: 2,
            trampolineDistance: 14,
            beltSpeed: 5,
            iceGrip: 0.33,
            mudTopSpeed: 3.3,
            mudJumpHeight: 1.75,
            mudFlightTime: 1.2,
            loopEntrySpeed: 11,
            rushGain: 1.25,
            fanClearance: 0.9,
            fanCatchDepth: 3,
            fanRiseSpeed: 2,
            seesawExitSpeed: 5,
            seesawJumpHeight: 1.5,
            bumperHopRise: 2,
          ),
        );
        final belt = [
          floor(0, 4),
          surfaced(4.5, FloorSurface.conveyorBackward),
          floor(9.5, 4),
        ];
        expect(
          fast.validate(course(floors: belt), margin: 0.9),
          contains(startsWith('backward belts')),
        );
        expect(check(course(floors: belt)), isEmpty);
      });
    });
  });

  group('LevelValidator on adrenaline zones', () {
    const validator = LevelValidator(envelope: testEnvelope);
    List<String> check(LevelData level) =>
        validator.validate(level, margin: 0.9);

    test('a rush allows a wider gap', () {
      final runs = [floor(0, 4, tiles: 8), floor(12 + 11.2, 4)];
      expect(check(course(floors: runs)), contains(startsWith('gap of')));
      expect(
        check(
          course(
            floors: runs,
            adrenaline: const [AdrenalineZone(left: 1, right: 27)],
          ),
        ),
        isEmpty,
      );
    });

    test('zones are well formed and hold no checkpoint', () {
      expect(
        check(course(adrenaline: const [AdrenalineZone(left: 5, right: 2)])),
        contains(endsWith('is malformed')),
      );
      expect(
        check(
          course(
            adrenaline: const [
              AdrenalineZone(left: 1, right: 4),
              AdrenalineZone(left: 3, right: 6),
            ],
          ),
        ),
        contains(endsWith('is malformed')),
      );
      expect(
        check(
          course(
            adrenaline: const [AdrenalineZone(left: 1, right: 4)],
            checkpoints: const [Checkpoint(Vec2(2, 4))],
          ),
        ),
        contains(endsWith('holds a checkpoint')),
      );
    });
  });

  group('LevelValidator on the dynamic elements', () {
    List<String> strict(LevelData level) => check(level, margin: 0.9);

    group('fans', () {
      const hover = 4 - 0.5 - 0.2;
      const base = 4.0 + 3;
      const top = base - 2 * (base - hover);
      final pit = [floor(0, 4), floor(24.5, 4)];

      test('accept fans spanning a pit, high and deep enough', () {
        expect(
          strict(
            course(
              floors: pit,
              fans: const [Fan(left: 4.5, right: 24.5, base: base, top: top)],
            ),
          ),
          isEmpty,
        );
        // Split, with a tile between columns.
        expect(
          strict(
            course(
              floors: pit,
              fans: const [
                Fan(left: 4.5, right: 13.75, base: base, top: top),
                Fan(left: 15.25, right: 24.5, base: base, top: top),
              ],
            ),
          ),
          isEmpty,
        );
      });

      test('reject a lull too wide, narrow split columns, or a short span', () {
        expect(
          strict(
            course(
              floors: pit,
              fans: const [
                Fan(left: 4.5, right: 12, base: base, top: top),
                Fan(left: 17, right: 24.5, base: base, top: top),
              ],
            ),
          ),
          contains(startsWith('fans over x=4.5 leave too wide a lull')),
        );
        expect(
          strict(
            course(
              floors: pit,
              fans: const [
                Fan(left: 4.5, right: 6, base: base, top: top),
                Fan(left: 6.5, right: 24.5, base: base, top: top),
              ],
            ),
          ),
          contains(startsWith('fans over x=4.5 leave too wide a lull')),
        );
        expect(
          strict(
            course(
              floors: pit,
              fans: const [Fan(left: 4.5, right: 20, base: base, top: top)],
            ),
          ),
          contains(startsWith('fans over x=4.5 do not span the pit')),
        );
      });

      test('reject a fan that floats too low or stands too high', () {
        expect(
          strict(
            course(
              floors: pit,
              fans: const [Fan(left: 4.5, right: 24.5, base: base, top: 3)],
            ),
          ),
          contains(startsWith('fan at x=4.5 floats the ball too low')),
        );
        expect(
          strict(
            course(
              floors: pit,
              fans: const [Fan(left: 4.5, right: 24.5, base: 5, top: 1.6)],
            ),
          ),
          contains(startsWith('fan at x=4.5 stands too high to catch')),
        );
      });

      test('accept a fan in the floor that lifts above a wall', () {
        final wall = [floor(0, 4), floor(4.5, -4, fill: 8)];
        const lifting = Fan(left: 3, right: 4.5, base: 4, top: -13.4);
        expect(strict(course(floors: wall, fans: const [lifting])), isEmpty);
        expect(
          strict(
            course(
              floors: wall,
              fans: const [Fan(left: 3, right: 4.5, base: 4, top: -5)],
            ),
          ),
          contains(_violation('fan at x=3.0 does not lift above the wall')),
        );
      });

      test('reject a fan over a run', () {
        expect(
          strict(
            course(fans: const [Fan(left: 1, right: 3, base: 7, top: -1)]),
          ),
          contains(_violation('fan at x=1.0 is misplaced')),
        );
      });
    });

    group('bumpers', () {
      // A wall 6.4 m up, with four bumpers: tops 2.2, 4.0, 5.8 and...
      final wall = [floor(0, 4, tiles: 6), floor(9, 4 - 5.6, fill: 5.6)];
      List<Bumper> zigzag(List<double> tops, {bool swapped = false}) => [
        for (var k = 0; k < tops.length; k++)
          Bumper(
            Vec2(
              9 - bumperWallGap - ((k.isEven != swapped) ? bumperColumnGap : 0),
              4 - tops[k] + climbBumperRadius,
            ),
            radius: climbBumperRadius,
            lean: k == tops.length - 1 ? 0 : (k.isEven ? 1 : -1),
          ),
      ];

      test('accept a climb that zigzags up within its hops', () {
        expect(
          strict(course(floors: wall, bumpers: zigzag([2.2, 4.0]))),
          isEmpty,
        );
      });

      test('reject a climb out of reach, of the wrong shape, or short of its '
          'ledge', () {
        expect(
          strict(
            course(floors: wall, bumpers: zigzag([2.2, 4.0], swapped: true)),
          ),
          contains(_violation('bumper climb at x=9.0 is malformed')),
        );
        expect(
          strict(course(floors: wall, bumpers: zigzag([3.0, 4.6]))),
          contains(_violation('bumper at y=1.0 is out of reach')),
        );
        expect(
          strict(course(floors: wall, bumpers: zigzag([2.2, 3.4]))),
          contains(_violation('ledge at x=9.0 is out of reach')),
        );
      });

      test('accept one low in a riser, and reject one anywhere else', () {
        expect(
          strict(
            course(
              floors: [floor(0, 4), floor(4.5, 2, fill: 2)],
              bumpers: const [
                Bumper(Vec2(4.5 + bumperInset, 4 - bumperRadius)),
              ],
            ),
          ),
          isEmpty,
        );
        expect(
          strict(course(bumpers: const [Bumper(Vec2(2, 1))])),
          contains(startsWith('bumper at (2.000, 1.000) is misplaced')),
        );
      });
    });

    group('pendulums', () {
      Pendulum mace(double x, {double period = 8, double clear = 0.25}) =>
          Pendulum(
            pivot: Vec2(x, 4 - maceClearance - maceRadius - 3),
            length: 3,
            period: period,
            clear: clear,
            phase: 0,
          );
      final run = [floor(0, 4, tiles: 8), floor(13, 4)];

      test('accept a mace with room around it and time to cross', () {
        expect(strict(course(floors: run, pendulums: [mace(6)])), isEmpty);
        expect(strict(course(floors: run, pendulums: [mace(4)])), isNotEmpty);
      });

      test('reject a mace off its run, too wide a swing, no room, or too '
          'little time', () {
        expect(
          strict(course(floors: run, pendulums: [mace(6, clear: 0.35)])),
          contains(_violation('pendulum at x=6.0 is misplaced')),
        );
        expect(
          strict(course(floors: run, pendulums: [mace(1)])),
          contains(_violation('pendulum at x=1.0 is misplaced')),
        );
        expect(
          strict(course(floors: run, pendulums: [mace(4.5), mace(8)])),
          contains(_violation('pendulum at x=8.0 leaves no room')),
        );
        expect(
          strict(course(floors: run, pendulums: [mace(6, period: 2)])),
          contains(_violation('pendulum at x=6.0 leaves')),
        );
      });
    });

    group('seesaws', () {
      const seesaw = Seesaw(
        pivot: Vec2(4.5 + seesawCrack + 1.98, 3.72),
        halfLength: 2,
        rest: 0.28,
        tip: 0.66,
      );

      test('accept one resting level with its run, its bank within a jump', () {
        expect(
          strict(
            course(floors: [floor(0, 4), floor(9.2, 4)], seesaws: [seesaw]),
          ),
          isEmpty,
        );
      });

      test('reject one off its run, malformed, or short of its bank', () {
        const high = Seesaw(
          pivot: Vec2(6.58, 3),
          halfLength: 2,
          rest: 0.28,
          tip: 0.66,
        );
        expect(
          strict(course(floors: [floor(0, 4), floor(9.2, 4)], seesaws: [high])),
          contains(startsWith('seesaw at x=6.58 is misplaced')),
        );
        const flat = Seesaw(
          pivot: Vec2(6.58, 3.72),
          halfLength: 2,
          rest: 0.28,
          tip: 0.2,
        );
        expect(
          strict(course(floors: [floor(0, 4), floor(9.2, 4)], seesaws: [flat])),
          contains(startsWith('seesaw at x=6.58 is misplaced')),
        );
        expect(
          strict(
            course(floors: [floor(0, 4), floor(20, 4)], seesaws: [seesaw]),
          ),
          contains(startsWith('gap of')),
        );
        expect(
          strict(
            course(floors: [floor(0, 4), floor(8.5, 4)], seesaws: [seesaw]),
          ),
          contains(startsWith('seesaw at x=6.58 reaches over its bank')),
        );
      });
    });
  });
}

/// A violation starting with [text], whose whole numbers may print without
/// their ".0", as JavaScript prints them.
Matcher _violation(String text) =>
    matches(RegExp('^${RegExp.escape(text).replaceAll(r'\.0 ', r'(\.0)? ')}'));
