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
const AIM_STICK_PX := 1000.0         # the pad aims at a point this far out along the stick (build 76: 500 px on screen at the
                                     # half zoom, about round 4's 520; the camera's lean follows it)
const LOCK_DEG := 14.0               # the pad's soft lock-on: a man within this many degrees of the stick
const LOCK_RANGE := 1800.0           # ...and this near, in sight (build 76: the zoomed-out screen's half width is 1920)
const SHOT_RANGE := 2200.0           # a round flies this far
const SPREAD_DEG := 1.2              # a round's spread either side (the sim's misses are its own; this is the look)
const BARREL := 58.0                 # the muzzle, out from the runner's centre
const SWAP_S := 0.3                 # a swap to the spare: no fire for this long
const KNOCK_PX := 14.0               # (10 Nov) a second of a gun's hits shoves a man this far: a round's shove is this over its rate (a shell's shared by its pellets)
const KNOCK_MAX_PX := 20.0           # ...and no more than this is ever outstanding
const KNOCK_SPEED := 300.0           # ...given at this pace, px a second
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
const CAM_ZOOM := 0.5                # (build 76, board D; Matt: "the view is also too zoomed in") half the old zoom: a 64 px
                                     # tile 32 px on screen, figures 34-40 px - the camera shows twice the ground
const CAM_LEAD := 0.3                # (build 76) the camera leans this share of the way toward the aim (the mouse's lean
                                     # settles at 0.43 of its distance from the runner: further when it's pushed out)
const CAM_LEAD_MAX := 760.0          # ...at most this far (world px; 380 on screen)
# (round 7, board H; Matt: "the skill bar needs to sit outside of the play as the player can walk behind it and miss
# things") The HUD's band along the screen's foot: the play is the screen above it, and the camera stops at its top.
const HUD_BAND_H := 156.0
# (round 7, board G) The dodge: Space, the way he's walking (his aim's way stood still). Nothing lands on him in it.
const DODGE_PX := 240.0               # how far: three of his own widths
const DODGE_S := 0.25                 # ...in this long
const DODGE_EVERY_S := 2.0            # from one dodge to the next
# (round 7, board G) Three kinds of men, each a question the gun alone answers badly. Each gang brings these among its
# plain men, its last ones (one plain man at least; the hard man is none of them). Every figure is a first guess.
const G_MEN_BY_GANG := [["rusher"], ["rusher", "marksman"], ["rusher", "marksman", "thrower"]]
const G_RUSH_HP_X := 0.6              # the rusher: a man's HP times this
const G_RUSH_PACE_X := 1.6            # ...his pace times this
const G_RUSH_REACH_PX := 26.0         # ...he swings from this far past touching
const G_RUSH_SWING_S := 1.2           # ...this often
const G_RUSH_FIRE_S := 2.0            # ...a swing worth this many seconds of a man's fire
const G_MARK_HP_X := 0.8              # the marksman: a man's HP times this
const G_MARK_AIM_S := 1.5             # ...his line on the runner this long, unbroken, before he fires
const G_MARK_REST_S := 2.5            # ...then this long before he lines up again
const G_MARK_FIRE_S := 3.0            # ...his round worth this many seconds of a man's fire
const G_MARK_FRAC := 0.1              # ...he takes cover this share of the way to the runner (a plain man's 0.35)
const G_THROW_EVERY_S := 8.0          # the thrower: a bottle this often, the runner in sight
const G_THROW_RANGE_PX := 1400.0      # ...from this near
const G_THROW_FLY_S := 1.2            # ...on the ground this long after it leaves his hand (the circle's warning)
const G_THROW_R_PX := 240.0           # ...burning a circle of this radius
const G_THROW_BURN_S := 3.0           # ...for this long
const G_THROW_FIRE_S := 2.0           # ...the whole burn worth this many seconds of a man's fire, stood in it
const G_THROW_TICK_S := 0.5           # ...taken a tick at a time
# (round 7, board G) Hit feedback: the crosshair's mark for a round landed, and the man's flinch.
const G_MARK_S := 0.12                # a hit's ticks on the crosshair last this long (white; a headshot's red)
const G_MARK_KILL_S := 0.3            # ...a kill's cross this long
const G_FLINCH_S := 0.15              # hit, he's off his aim this long before his next round
const G_FLINCH_EVERY_S := 0.6         # ...no more often than this (a stream of hits doesn't hold him silent)
const CAM_FOLLOW := 12.0             # catch-up rate a second (higher is tighter)
const SHAKE_FIRE := 1.5              # px, each round
const SHAKE_HIT := 3.0               # a hit landed
const SHAKE_HURT := 7.0              # the runner hit
const SHAKE_MAX := 12.0
const SHAKE_DECAY := 40.0            # px a second
# ---------------------------------------------------------------- W: line of sight (build 76, board D)
const FOG_ALPHA := 0.78              # what the cover hides from him: board D's darkness
const FOG_MARGIN := 400.0            # the fog's ground past the view (the lead and the shake never show its edge)
const SIGHT_SIDE := 0.8              # a man is seen if his centre or a point this share of his radius to either side is
const LAST_SEEN_S := 4.0             # a man lost from sight: his "Last seen" mark fades over this long
const MARK_FONT := 14.0              # the mark's words, px on screen
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
const MAN_HP_X := 0.06               # (10 Nov, Matt: "Enemy HP is off - you don't do any damage to them": about 12 landed rounds of the test Poacher's rifle a man at level 12; 0.5 before, 96-133 rounds since round 5's real rates) # (merge, the coordinator's call for feel) a man's HP: the sim's times this - at 1 a man  (round 4, Matt: "0.5x HP is the better setting")
                                     # the pause's "Gang HP" switches it live (README)
const SITE_LEVEL_UNDER := 2          # (merge) the car park's level: the runner's less this, at least 1
const TEST_RUNNER_UNDER := 3         # (10 Nov) a camp's runner more than this many levels under the car park picked: the test Poacher plays it
const G_MAN_DPS_X := 1.0             # their fire: the sim's times this (1: the game's maths)
const G_MAN_ROF := 5.0               # (build 76) a man's rounds a second within a burst (was 1.6, one round at a time)
const G_MAN_RANGE := 1500.0          # px: a man fires from this near, in sight
const G_REACT_S := [0.35, 0.7]       # his first shot this long after he sees you
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

# ---------------------------------------------------------------- G: the guns and their fire (build 76)
# Matt (9 Nov): "the fire rate feels off too from something that's supposed to be an AR"; "i dont seem to be taking much
# if any damage". Board D: each gun fires at its type's rate with its type's magazine; a round's damage is the gun's
# damage a second (the sim's chain, so a build's totals stand) over that rate; rounds travel and the first thing in their
# path stops them, cover too. The game's gun types (rifle, smg, pistol, shotgun, improvised, melee) split by rate into
# the slice's kinds; each kind's figures:
#   rate: rounds a second (auto), or the cap on presses (semi, pump); mag: the magazine (big: a base whose own magazine
#   is over its type's has this instead); fire: "auto" held, "semi" a press a round, "pump" a press a shell of pellets,
#   "swing" a press a blow; spread: degrees either side of the aim.
#   (round 6) kick: degrees a round fired adds to the spread; kick_max: the most it adds. First guesses, all of them.
const G_KINDS := {
	"ar": {"name": "AR", "rate": 10.0, "mag": 30, "big": 30, "fire": "auto", "spread": 2.0, "kick": 0.5, "kick_max": 5.0},
	"smg": {"name": "SMG", "rate": 13.0, "mag": 30, "big": 30, "fire": "auto", "spread": 3.5, "kick": 0.45, "kick_max": 6.0},
	"rifle": {"name": "Rifle", "rate": 3.0, "mag": 10, "big": 20, "fire": "semi", "spread": 0.8, "kick": 0.9, "kick_max": 3.0},
	"bolt": {"name": "Bolt rifle", "rate": 1.0, "mag": 5, "big": 5, "fire": "semi", "spread": 0.3, "kick": 1.5, "kick_max": 1.5},
	"pistol": {"name": "Pistol", "rate": 6.0, "mag": 12, "big": 15, "fire": "semi", "spread": 1.5, "kick": 0.7, "kick_max": 3.5},
	"revolver": {"name": "Revolver", "rate": 3.0, "mag": 6, "big": 6, "fire": "semi", "spread": 1.2, "kick": 1.2, "kick_max": 3.0},
	"shotgun": {"name": "Shotgun", "rate": 1.2, "mag": 6, "big": 8, "fire": "pump", "spread": 7.0, "kick": 1.5, "kick_max": 3.0, "pellets": 8},
	"improvised": {"name": "Improvised", "rate": 2.0, "mag": 10, "big": 20, "fire": "semi", "spread": 2.0, "kick": 0.8, "kick_max": 3.0},
	"melee": {"name": "Melee", "rate": 1.5, "mag": 0, "big": 0, "fire": "swing", "spread": 0.0, "kick": 0.0, "kick_max": 0.0},
}
const G_KICK_HOLD_S := 0.14           # (round 6) the kick holds this long after a round (over an AR's beat), then settles
const G_KICK_SETTLE_S := 0.35         # ...from its most to nothing in this long
# (10 Nov, Matt: "we also need right click to aim down sights with the main weapon with left click just being hip
# firing"; then, after two runs dead at a third of rounds landing, "too hard to hit enemies") Sights: the right button
# held, the main gun only. Hip fire is the gun as it was.
const G_SIGHTS_SPREAD_X := 0.4        # the gun's own spread times this down the sights (the rifle's 2 degrees: 0.8)
const G_SIGHTS_KICK_X := 0.5          # ...and the kick built counts this much
const G_SIGHTS_PACE_X := 0.5          # he walks at this share of his pace
const G_SIGHTS_LEAD := 0.38           # the camera leans this share of the way to the aim (CAM_LEAD from the hip; the review: at 0.45 the
                                      # mouse at the screen's top put him under the HUD's bar - the lean feeds the aim, lead / (1 - lead))
const G_SIGHTS_LEAD_MAX := 900.0      # ...at most this far (CAM_LEAD_MAX from the hip)
const G_CROSS_MIN_PX := 9.0           # the crosshair's gap on screen at its least; past it the gap is the spread at the aim
const G_CROSS_TICK_PX := 9.0          # ...and a tick's length on screen
const G_AR_ROF := 2.0                # a rifle at the game's rate of this or more is an AR (the Regimental rifle's 2.45)
const G_BOLT_ROF := 1.0              # ...under this a bolt or lever rifle; between, a semi-auto rifle
const G_REVOLVER_ROF := 1.0          # a pistol under this rate (or named a revolver) is a revolver
const G_PRESS_KEEP_S := 0.15         # a press while the gun's cap holds it is kept this long, then fires
const G_ROUND_PX_S := 2600.0         # the runner's rounds: px a second (a 64 px tile, 32 on screen at half zoom)
const G_ROUND_RANGE := 2600.0        # ...and how far they fly
const G_TRACER_PX := 70.0            # a round's tracer: this long behind it
const G_MELEE_REACH := 120.0         # a swing: from the runner's edge, this far
const G_MELEE_ARC_DEG := 50.0        # ...this many degrees either side of the aim
# Their fire
const G_THEIR_ROUND_PX_S := 1500.0   # their rounds: slower than his, you see them come
const G_THEIR_RANGE := 1900.0
const G_HIT_OPEN := 0.4              # Matt's figure on the board: this share of their rounds land on a runner in the open;
                                     # their aim's error is spread so a round crosses his token this often (led for his move)
const G_LEAD := 1.0                  # they lead a moving runner by this share of the round's flight
const G_MOVING_X := 0.75             # a man on the move: his share of hits times this
const THEIR_DMG_X := 2.0             # the "Gang damage" test knob's start (10 Nov: ×2, its own - round 6's tie to gang HP gone; ×2 / ×3 / ×1 on the pause, live:
                                     # ctx["their_dmg_x"]); a round's damage is the sim's damage a second over their rate, times this
# (round 6, board E) Leaning out: a man behind cover with no line to the runner steps sideways to the nearest spot with
# one, fires while he's out, and ducks back - so about three have him in sight and their fire lands at the game's rate.
const G_LEAN_STEP_PX := 40.0         # he looks for his line this far sideways at a time
const G_LEAN_STEPS := 10             # ...this many steps either way; none, and he moves to other cover
const G_LEAN_CLEAR_PX := 30.0        # ...and stands this far past the first, his rounds clear of the cover's corner
const G_LEAN_FIRST_S := [0.2, 0.5]   # at his cover: this long before he first leans out
const G_LEAN_OUT_S := [4.0, 6.5]     # out of cover firing this long
const G_DUCK_MAX_S := 2.0              # ducking back takes the walk at a hit leg's pace and this long over, at most (a man shoved off his way back is in cover where he stands)
const G_LEAN_BACK_S := [0.3, 0.7]    # ...then behind it this long (G_PINNED_SLOW times longer pinned)
const G_LEAN_BLIND_X := 3.0          # out with nothing to shoot at, his time out runs this many times faster
const G_LEANS := [2, 3]                # he leans out this many times from a spot, then moves to other cover
const G_NO_LEAN_STEP := 0.6          # nowhere to lean out: his next cover is this far of the way to the runner (0.35 as a rule)
const G_LEAN_REACT_X := 0.5          # leaning out he knew where to look: G_REACT_S times this
# (round 6, board E) The search: nobody of the front has seen him for G_SEARCH_AFTER_S - two walk to where they last saw
# him, look about and spread to cover either side; the rest hold. Still lost, they search again nearer where he is.
const G_SEARCH_AFTER_S := 2.5
const G_SEARCHERS := 2
const G_SEARCH_WALK_S := 8.0         # a searcher who can't reach the spot looks about where he's got to after this
const G_SEARCH_NEAR_PX := 90.0       # at the spot
const G_LOOK_S := 1.5                # looking about
const G_LOOK_SWEEP := 4.0            # ...his head's swing: how fast it turns back and forth
const G_LOOK_TURN := 2.2             # ...and how far (radians a second at its fastest)
const G_SPREAD_PX := 420.0           # then to cover this far to one side
const G_SEARCH_AGAIN_S := 6.0        # still lost: the next search after this
const G_SEARCH_CLOSER_PX := 450.0    # ...this much nearer where he really is (a hidden runner is found in the end)
const G_HOLD_CHECK_S := 0.5          # the waiting men: how often the gang checks they're out of his sight
const G_HOLD_FILE_PX := 70.0   # the waiting men out of his sight: a place each, this far apart, in the cover's shadow
const G_HOLD_FILE := 10        # ... and this many rows deep at most
# ---------------------------------------------------------------- H: the start, the HUD, the pause (build 76)
const H_LEVEL_FRESH := 12            # the level picker's default on a fresh camp (the level-14 test Poacher's car park)
const H_LEVEL_STEPS := 3             # the picker offers this many levels either side of the default

# -- sound (round 6, board E part 2): the game's own sounds, placed
const SOUND_PAN_PX := 1900.0         # a man this far to one side sounds wholly from that side (about half the view across)
const SOUND_FAR_PX := 2400.0         # a man's shot from this far is at its faintest
const SOUND_LOW_HP := 0.25           # under this much of his HP the game's low-HP loop plays (the game's own rule)
