# Design

## Context

See proposal.md for the motivation. Today:

- **Physics:**
  - gravity is 12 m/s²;
  - the ball is a 0.2 m circle of about 6.3 kg, pushed at 80 N against a damping of 1.5/s, in the air too;
  - the only moving bodies are the ball and the moving platforms (kinematic).
- **Elements:** lasers keep a rhythm from the game's clock (`isOnAt(time)`), unchanged by respawns. Trampolines set the
  ball's speed on contact instead of relying on restitution.
- **Generator:**
  - exact arithmetic (no transcendental functions), so levels match on the VM and in JavaScript;
  - a measured envelope, a speed model that carries the speed a player can have, and a validator;
  - laser clearance, golden digests, a bot and a local stress run of 680 levels;
  - levels 10, 12 and 14 stay reserved for the logic mechanics.
- **Pacing:** flow phrases (taken without stopping), challenge phrases, break points, adrenaline zones over tense
  phrases, and weights that favor rich kinds with depth.

## Goals / Non-Goals

**Goals:**
- Fans, bumpers, pendulums and seesaws, each with a distinct role, introduced at levels 15, 17, 19 and 21.
- Each measured with the real ball and kept honest by the generator, the validator and the bot.

**Non-Goals:**
- The logic and memory mechanics (later, at levels 10, 12, 14 and on).
- Fans that switch on and off or blow sideways; pendulums that send the ball back; seesaws as ramps on solid ground
  (the author chose against them).

## Decisions

### D1. Fans
- **Data:** `Fan(left, right, base, top)`, a column of air from the fan at `base` up to `top` (world y).
- **Physics:**
  - inside the column, the ball gets an upward acceleration of `g · s · (1 − h / H)`, where `h` is its height above
    the fan, `H` the column's height and `s` = 3 (2 before the first play-test, which found the rise slow);
  - it floats at the hover height `2 H / 3`, where the lift equals gravity, and an extra vertical damping of 0.6/s
    settles its bobbing;
  - the push works as in the air, so the player steers it;
  - the hover height is exact, so the generator can use it.
- **Fan gaps:**
  - a pit 1.1 to 2 times the farthest jump at top speed, so no jump crosses it;
  - the fans' bases stand `fanCatchDepth` below the run, so a ball falling in from a jump's apex is caught;
  - the hover height is `fanClearance` plus 0.2 to 0.8 m above the near run, the higher bank;
  - the far bank lies up to 1.5 m lower;
  - the fans' housings are not solid, and stand on pillars drawn down into the pit.
- **Deep fan gaps:** from depth 0.5, the pit's columns split into two or three of at least two tiles, with at most a
  tile of no wind between them: measured, a ball floating across sinks too little there to miss the next column.
- **Fan climbs:**
  - a fan set in the floor, one tile wide, at the foot of a wall;
  - the wall is higher than a jump boost reaches, up to 10 m, within the level's height band;
  - its hover height is `fanClearance` above the wall's top;
  - a fan climb counts as a climb towards the course's target height.
- **Measured** with the real ball (rounded safely):
  - `fanClearance` 0.9 m: a floating ball's bottom bobs at most 0.76 m below the hover height, after jumping in;
  - `fanCatchDepth` 3 m: a ball that rolls or jumps in never sinks below the run;
  - `fanRiseSpeed` 2 m/s for the duration estimate: about 5 m/s up a wall, under a second to float over a pit.
- **Fall detection:** a fan's base counts as ground in its column, so a ball bobbing in a pit is not taken for a fall.

### D2. Bumpers
- **Data:** `Bumper(center)`, of radius `bumperRadius` (0.35 m).
- **Physics:**
  - a static circle;
  - on contact, the ball's speed along the contact normal becomes `bumperSpeed` (about 9 m/s) outwards, and its speed
    along the surface is kept;
  - this is a set speed, as with trampolines, so the throw does not depend on how hard the ball hit.
- **Bumper climbs** (`bumperClimb`, a challenge kind and a climb). The first play-test found roofs over drop gaps
  senseless (going under hit the roof, so the author went over it), the second found posts on the run after a gap
  broke the immersion, and the author asked for something more skilful: climbing up while alternating between
  bumpers. The third found the climb, with bounces that depended on where the ball landed, extremely hard; the
  author chose leaning throws:
  - a run of four tiles, then a wall;
  - in front of it, two columns of bumpers, `bumperWallGap` (0.9 m) and 3.1 m from the wall, alternating from the far
    column to the near one: two, or deep, half the time, four;
  - the climb's bumpers are wider (`climbBumperRadius`, 0.5 m), and each `lean`s its throw: a ball landing anywhere on
    its top is thrown up at 11 m/s, slanting 0.45 m sideways per meter up, towards the next bumper; the last throws
    straight up beside the ledge, where the player pushes onto it near the top of the throw;
  - measured, a ball landing up to 0.3 m off a top comes down on the next bumper, 2.2 m across and 1.7 to 1.9 m up,
    within its radius, with no push: the skill is landing on the first, not pushing the wrong way, and the last push;
  - the lowest bumper's top within a jump (90 % of the precision share of the jump's height, from 1.9 to 2.3 m);
  - each next top, and the ledge, a share of `bumperHopRise` above the last, never less than 1.7 m between bumpers,
    or a throw reaches the bumper two above in the same column;
  - the bumpers throw at 11 m/s (9 before);
  - a miss drops the ball back to the run, so it costs time, not a life.
- **Measured:** `bumperHopRise` 2 m: a leaning throw lifts the ball's bottom at least 2.25 m above the bumper's top,
  and a straight one 2.6 m.
- **Bumper risers:** from level 17, half of the short-tread break points line their riser's face with two or three
  bumpers below the lip. An overshoot is kicked back into the gap. A jump from the tread still clears the lip.

### D3. Pendulums
- **Data:** `Pendulum(pivot, length, period, clear, phase)`:
  - the mace is a circle of `maceRadius` (0.45 m) on a solid arm 0.1 m thick;
  - at the bottom of its swing the mace's lowest point is 0.1 m above the run, so it sweeps the lane.
- **Rhythm:**
  - the angle is `A · sin(2π (t + phase) / period)`, from the game's clock as the lasers are;
  - the generator chooses `clear`, the share of each half swing during which the mace is above the lane, from 0.2 to
    0.3, and the arm's length from 2.5 to 3.5 m;
  - the game derives the amplitude `A` from them (`A = θb / cos(π · clear)`, where `θb` is the angle at which the mace
    leaves the lane);
  - those ranges keep `A` under 60°, which a unit test checks;
  - so the generator needs no trigonometry: the reach strip's half-width is `√(L² − (L − d)²) + maceRadius`, with
    `d` the lane's height, using only a square root, which is exact on every platform.
- **Physics:**
  - a kinematic body, whose angular velocity each step is set to reach the scheduled angle at the next step;
  - a mace that meets the ball throws it straight away from the mace at `knockSpeed` (10 m/s), as a bumper does, so a
    hit is hard (the first play-test found the plain push too soft);
  - the ball is a bullet, so a fast mace never passes through it.
- **Pendulum runs** (`pendulums`, a challenge kind, also tense for the adrenaline rush):
  - one mace, or two or three from depth 0.5;
  - each mace has a waiting room of two tiles (`pendulumRoom`) before its reach strip, out of every strip;
  - the run ends in a gap or a drop, so a knock forwards can throw the ball off.
- **Sizing:**
  - the crossing time is computed with the speed curve, from rest at the back of the waiting room to beyond the strip
    plus the ball: the ball reaches the lane at speed, so the maces swing faster than from rest at its edge;
  - the period is set so the crossing takes a share of the clear time `clear × period`, from the precision interval;
  - the duration estimate adds half a period for each mace;
  - inside an adrenaline zone the ball only crosses faster, so the rest-based sizing stays honest.

### D4. Seesaws
- **Data:** `Seesaw(pivot, halfLength, rest, tip)`, where `rest` and `tip` are the vertical offsets of the plank's ends
  from the pivot when leaning back and when tipped forwards.
  - The ends' horizontal offsets are `√(halfLength² − offset²)`, so the generator again needs only square roots.
  - At rest the near end is at the run's height, 0.1 m from its edge, and the far end is up. Its slope is at most
    0.15, so pushing rolls up to the pivot.
  - Tipped, the far end is down, with a slope of about 0.35.
- **Physics:**
  - a light dynamic plank on a revolute joint whose limits are the two tilts, with a little angular damping;
  - it turns about its centre of mass, half its thickness below the top surface's pivot, so it is balanced: it rests
    at its back limit until the ball passes the pivot, and then tips at once (a counterweight made it tip too late);
  - a fast ball may leave the plank before it has tipped all the way, which only lengthens its jump;
  - the pivot's support is drawn down into the pit and does not collide.
- **Seesaw section** (`seesaw`, a flow kind):
  - a run of two tiles, the seesaw over a pit, then a gap from its tipped far end to the far bank;
  - deep levels may chain two seesaws.
- **Measured:** `seesawExitSpeed` 5 m/s, the least speed of a ball pushed from rest on the near end when it nears
  the far end (5.2 m/s on the shortest plank), and `seesawJumpHeight` 1.5 m, the height of a jump from there (1.59 m
  on the longest). Gaps after a seesaw use the jump model with them, as gaps after mud use mud's speed and jump.
- **Respawn:** every seesaw goes back to its rest pose with no motion.

### D5. Difficulty curve
- **Introductions:**
  - `fanGap` and `fanClimb` at 15;
  - `bumperClimb` at 17, and bumper risers in break points from 17;
  - `pendulums` at 19;
  - `seesaw` at 21.

  Level 19 is a breather. It still introduces its element, as level 9 does.
- **Base weights:** `fanGap` 0.6, `fanClimb` 0.4, `bumperClimb` 0.7, `pendulums` 0.6, `seesaw` 0.6. All five are rich
  kinds, which grow more common with depth.
- **Kinds:**
  - flow kinds gain `seesaw`, and the climbs gain `fanClimb` and `bumperClimb`;
  - tense kinds gain `pendulums`;
  - plain climbs are unchanged.

### D5b. Vertical travel
The new kinds mostly keep their height, and a level whose featured kinds all do could stay flat: the stress probes
showed about one long level in ten spanning less than 15 m, already before this change. Three rules keep courses
traveling their band without changing the levels' character:
- once the course has taken more than 60 s of estimated play to reach its target height, each landing slopes on
  towards it, a rounded slope that is not counted as an obstacle;
- gaps that rise or fall lean towards the target height two to one, as do trampoline islands and the bank after a
  seesaw;
- sections that climb or descend away from the target height weigh a third.

### D11. Curves that carry obstacles
The first play-test found wavy stretches empty. A hill or a half-pipe carries an obstacle with a probability of
`0.5 + 0.4 d`:
- a hill: spikes in a valley between two single bumps, on a run of a tile, the strip and a tile, or, once speed
  boosts are known and half the time, one or two bumps followed by a speed boost and a long gap;
- a half-pipe: a speed boost and a long gap after it, once speed boosts are known.

Both reuse the spikes' and the speed boost's sections, so the validator's rules already cover them.

### D6. Validator, clearance and falls
- **Validator:**
  - **fans:**
    - columns span their pit or stand at their wall;
    - banks and ledges lie at least `fanClearance` below the hover height;
    - bases lie `fanCatchDepth` below the run;
    - windless stretches are within a glide;
    - nothing solid stands in a column but the floor fan's own ground;
  - **bumper climbs:** the columns alternate from the far one to the near one, the lowest top is within a jump,
    each step and the ledge within a hop, with a tile of run before the far column;
  - **pendulums:**
    - waiting rooms are out of every strip;
    - the strips are on one run;
    - the crossing from rest takes no longer than the clear time;
  - **seesaws:** the near end is at the run's height, and the gap from the tipped far end is within the seesaw jump.
- **Laser clearance:**
  - no laser overlaps a fan column, a mace's sweep or a seesaw's arc;
  - fan columns count their hover heights among the heights a ball can reach.
- **Fall detection:** fan bases count as ground (D1).

### D7. Game components and feedback
- **Components:**
  - `FanComponent`: a sensor that lifts the ball while inside;
  - `BumperComponent`: static;
  - `PendulumComponent`: kinematic;
  - `SeesawComponent`: dynamic, with its joint and reset.
- **The ball:** it gains `bump(normal)` for bumpers, and it becomes a bullet.
- **Looks** (ADR-0010, `ElementPalette`):
  - **fan:** a steel housing with spinning blades, and pale streaks of air rising through the column, thinning
    towards its top;
  - **bumper:** a bright violet-magenta cap, a chrome ring and a glow, flashing and swelling for 0.2 s when it throws
    the ball;
  - **pendulum:** a riveted pivot bracket, a dark arm and a studded iron mace with hazard-red accents, its swing arc
    traced faintly on the backdrop;
  - **seesaw:** a banded wooden plank on a triangular fulcrum, with a post down into the pit.

  Each is a cached picture, with only its transform and animation changing per frame.
- **Audio:** `GameSound.bumper` (a bright ding), `GameSound.thud` (a mace's heavy hit) and `GameSound.whoosh` (entering
  a column). `tool/audio/synth.sh`, which replaces `heartbeat.sh`, synthesizes them and the heartbeat with ffmpeg and
  normalizes them like the other effects.
- **Haptics:** `Haptic.hit`, the device's sharp vibration, for a bumper or a mace.

### D8. Bot
- **Fans:**
  - in a fan gap it floats and pushes on, easing off once above the far bank's edge;
  - in a fan climb it waits against the wall until above the top, then pushes over.
- **Bumper climbs:** it stands before the lowest bumper and jumps onto it, then steers each flight onto the top of
  the next bumper, keeping clear of a bumper's side until above it and moving out from under the bumper above; from
  the last it pushes onto the ledge once above it.
- **Pendulums:**
  - it stops in each waiting room;
  - it reads the pendulum's schedule from the level data and the game's clock;
  - it goes when the lane stays clear for its crossing time.
- **Seesaws:** it pushes through and jumps at the tipped far end, as at a ledge.

### D9. Stress and play-test
- **Stress run:**
  - levels [1–11, 13, 15, 17, 19, 21, 25, 45, 120, 300];
  - 20 seeds and two bot runs each, so 800 levels, in files of at most 119 tests;
  - it must pass.
- **Playthrough test:** it adds levels 15, 17, 19 and 21.
- **Play-test:** the author plays levels 15, 17, 19, 21 and a deep one on the phone, with frame time measured.

### D10. Versions and records
- `generatorVersion` becomes 6, with new golden digests on the VM and in Chrome.
- ADR-0016 records how each element plays and why: fans upwards and always on, maces that push, seesaws over pits, and
  bumpers as climbs and risers, and curves that carry obstacles.

## Risks / Trade-offs

- **[A mace's knock is chaotic]** → It never sends the ball back by itself, and waiting rooms are out of reach. The
  bot proves the way through, and the stress run covers every level with pendulums.
- **[Fan bobbing feels floaty or hard to land]** → The lift factor and the damping set it. The clearance is measured
  on the settled ball, and the author's play-test judges the feel.
- **[A seesaw jitters or catapults]** → Its limits, damping and light plank are measured, and the jump after it is
  sized from the measured worst case.
- **[A bumper climb is too hard]** → A miss only drops the ball back to the run, and the steps are sized from the
  measured throw with the level's precision; the throws lean onto the next bumper by themselves; the bot climbs
  walls of two and four bumpers.
- **[Frame time]** → The new bodies are few and their art is cached. The frame time is measured on the reference
  phone.

## Migration Plan

No data change. Savegames keep their level numbers and get new courses (`generatorVersion` 6).
**Rollback:** revert the pull request.
