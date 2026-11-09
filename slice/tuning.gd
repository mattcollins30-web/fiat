extends RefCounted
## The ARPG slice's own figures (build 72): only what the sim has no figure for - sizes in pixels, the feel of
## moving and aiming, timings of the world. Every one a first guess for Matt's hands; the game's maths (damage,
## rate, magazines, reloads, jams, HP) come from the sim through slice/bridge.gd.

# ---------------------------------------------------------------- W: the world
const TILE := 64.0                   # (round 2) the floor's tile: the level's data is in tiles, so CC0 tiles can drop in
const PARK_TILES := Vector2i(90, 50) # (round 2, Matt: "a tad bigger to allow more hiding") 1.42x build 72's area
const PARK_W := 5760.0               # PARK_TILES.x * TILE: three screens of 1920 wide at zoom 1
const PARK_H := 3200.0               # PARK_TILES.y * TILE
const EDGE := 64.0                   # the park's edge wall, a tile
const BAY_W := 160.0                 # a painted bay, 2.5 tiles by 5
const BAY_H := 320.0
const REACH_CELL := 32.0             # the reach check's grid (half a tile)

# ---------------------------------------------------------------- W: the runner
const RUNNER_R := 40.0               # the token, 80 px across (board A)
const MAN_R := 34.0                  # a man's token, when his node gives no radius
const PACE_PX := 330.0               # the runner's speed at pace 0, px a second (the class's pace in % scales it)
const PACE_MIN := 0.6                # the kit's pace never takes him under this share
const ACCEL := 3600.0                # px/s² to full pace: about a tenth of a second (tight, Hotline Miami)
const DECEL := 5200.0                # px/s² to a stop: no slide
const MOVE_DEADZONE := 0.2           # the left stick
const AIM_DEADZONE := 0.3            # the right stick
const AIM_STICK_PX := 520.0          # the pad aims at a point this far out along the stick
const LOCK_DEG := 14.0               # the pad's soft lock-on: a man within this many degrees of the stick
const LOCK_RANGE := 1300.0           # ...and this near, in sight
const SHOT_RANGE := 2200.0           # a round flies this far
const SPREAD_DEG := 1.2              # a round's spread either side (the sim's misses are its own; this is the look)
const BARREL := 58.0                 # the muzzle, out from the runner's centre
const SWAP_S := 0.3                 # a swap to the spare: no fire for this long
const KNOCK_PX := 14.0               # a man knocked back by a hit
const HURT_FLASH_S := 0.12           # the runner's token flashes when hit
const UNDER_FIRE_S := 1.5            # hit within this long, he's under fire (a search slows)

# ---------------------------------------------------------------- W: firing
const TRACER_S := 0.07               # a tracer's life
const FLASH_S := 0.05                # the muzzle flash
const HIT_FLASH_S := 0.09            # a man flashes white
const SPARK_S := 0.18                # a round's spark on cover

# ---------------------------------------------------------------- W: crates and the way out
const CRATE_SIZE := 70.0
const SEARCH_S := 2.0                # a crate searched, held, not under fire
const SEARCH_UNDER_FIRE := 0.5       # under fire it goes this much as fast
const SEARCH_RANGE := 110.0          # from the runner's centre to the crate's edge
const EXIT_W := 260.0                # the way out
const EXIT_H := 260.0
const LEAVE_HOLD_S := 1.5            # X/B held this long in the way out

# ---------------------------------------------------------------- W: the camera
const CAM_LEAD := 0.22               # the camera leans this share of the way toward the aim
const CAM_LEAD_MAX := 280.0          # ...at most this far
const CAM_FOLLOW := 12.0             # catch-up rate a second (higher is tighter)
const SHAKE_FIRE := 1.5              # px, each round
const SHAKE_HIT := 3.0               # a hit landed
const SHAKE_HURT := 7.0              # the runner hit
const SHAKE_MAX := 12.0
const SHAKE_DECAY := 40.0            # px a second
# ---------------------------------------------------------------- G: the gang and the bridge (build 72)
# The site and the clock
const G_SITE_NAME := "The car park"  # the Retail Park's car park (the brief: the Estate's car park)
const G_GANGS := 3                   # three gangs, then the clear
const G_GANG_MAX := 7                # no gang bigger than this (the site's pool over three, +1 a gang)
const G_FIRST_GANG_S := 4.0          # the first gang this long after you're in
const G_CLOCK_X := 0.75              # the sim's gap between gangs (patrol_s) times this: a slice's few minutes
const G_QUIET_MAX_S := 10.0          # the park quiet (every man down): the next gang no longer than this
const G_STEP_UP_S := 1.2            # (round 4) a man of the front down: the next steps up after this beat
const G_HARD_SURE := true            # no hard man by the last gang: it brings one (the slice shows him)
# Their fire
const MAN_HP_X := 0.5                # (merge, the coordinator's call for feel) a man's HP: the sim's times this - at 1 a man  (round 4, Matt: "0.5x HP is the better setting")
                                     # takes ~38 rounds, at 0.25 ~10; the pause's "Gang HP" switches it live (README)
const MAG_X := 2.5                   # (round 2, Matt: "12 rounds with that gun is too few") a test knob: a magazine holds the
                                     # game's figure times this in the slice only; the pause's "Magazine" switches ×1, ×2.5, ×4
const SITE_LEVEL_UNDER := 2          # (merge) the car park's level: the runner's less this, at least 1
const G_MAN_DPS_X := 1.0             # their fire: the sim's times this (1: the game's maths)
const G_MAN_ROF := 1.6               # a man's rounds a second: their damage a second (the sim's) over this
const G_MAN_RANGE := 1500.0          # px: a man fires from this near, in sight
const G_REACT_S := [0.35, 0.7]       # his first shot this long after he sees you
const G_SPREAD_DEG := 5.0            # his rounds either side of true
const G_SPREAD_MOVING := 2.0         # ...times this while he's on the move
const G_BURST := [3, 5]              # rounds a burst, then a pause
const G_BURST_PAUSE := [0.6, 1.2]
const G_PINNED_SLOW := 2.0           # pinned (the meter full), his pauses this many times longer and he keeps his head down
# Their feet
const G_MAN_SPEED := 230.0           # px a second
const G_MAN_ACCEL := 1400.0
const G_LEG_SLOW_S := 3.0            # a leg shot: this long slower
const G_LEG_SLOW_X := 0.45           # ...at this share of his pace
const G_REPOSITION_S := [3.0, 6.0]   # between moves from cover to cover
const G_FLANK_SHARE := 0.4           # this share of a gang go round the side
const G_FLANK_DIST := 700.0          # px off the line between you and them
const G_RETREAT_HP := 0.3            # under this share of his HP he falls back to cover away from you
const G_ARRIVE_PX := 24.0            # at his spot
const G_SEPARATE_PX := 90.0          # men keep this far apart
const G_STUCK_S := 0.6               # no headway this long: he steps round
const G_MAN_R := 34.0               # a man's token (W's MAN_R, board A)
const G_RUNNER_R := 40.0            # the runner's token, for their rounds (W's RUNNER_R)
const G_FLASH_S := 0.09             # a man flashes when hit
const G_HARD_R := 44.0               # the hard man's token radius (a man's is W's MAN_R)
# The bridge
const G_AIM_HEAD_PCT := 0.0          # aimed at the head: no extra (the sim's roll stands; a knob for Matt's hands)
const G_AIM_PICK_R := 260.0          # an aimed skill takes the man nearest the aim within this
const G_NET_R := 320.0               # Net every hole: everyone this near the aim
const G_TRAP_R := 70.0               # Gin trap: a man this near its spot steps in
const G_TRAP_HOLD_S := 0.8           # ...and is held this long
const G_POT_UNDER := 0.25            # One for the pot: a man under this share of his HP (the skill's line)
const G_PIN_GRACE_S := 0.5           # the meter drains once he's not been shot at for this long
const G_SEARCH_X := 0.1              # a crate's search: the sim's search_s times this (20 s a search there)
const G_CRATE_FINDS := 1             # finds a crate
const G_SPARE_MAGS := 2              # spare magazines a gun at least (the rig's are the sim's; the slice's minimum)
const G_MED_SLOTS := 4
const G_EVENTS_KEPT := 40
const G_BOX_ROUNDS := 250            # (the review, 9 Nov) a runner with no box of his gun's rounds in the pack: one of this many
