extends Control
## The run view (13 Oct, Matt; docs/design/fight_art.md, concept.md 22.3): a light-gun frame, Time Crisis not an FPS,
## across the run screen's fight and runner boxes. The site's plate; the gang popping up at three depths (far in a
## doorway, mid by the car, near and big), firing at you; the cover you're behind; your hands and gun bottom right.
## A hit jolts the frame and reddens its edges; a kill drops one; the search pans along to the crates. A visualiser
## of what the sim already does - nothing in it changes a number. The slice: the Parade's test art on every site.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Items := preload("res://scripts/sim/items.gd")
const Data := preload("res://scripts/sim/data.gd")
const CratesPanel := preload("res://scripts/ui/crates_panel.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const SkyLayer := preload("res://scripts/ui/sky.gd")
const EventProp := preload("res://scripts/ui/event_prop.gd")

## A shot of yours lands, in the frame's space (13 Oct, Matt: the numbers came with no shot, and while ducked): the run
## screen shows what your gun's done since the last one here, on the one it hit.
signal shot_fired(at: Vector2)
signal gun_fired                          # each of your shots or swings, as it shows (20 Oct: its sound on the flash)
signal they_fired(k: int)                 # figure k up in its firing pose (its sound with it)

## The placement tool on or off: the run screen clears what it lays over the frame (bars, chips, the head) while it's on.
signal placing_changed(on: bool)
signal ducked                             # down behind the wall: the duck's sound (14 Oct)

const W := 588
const H := 262
const DIR := "res://art/fight_test/%s.png"
const FULL_DIR := "res://art/fight/%s.png"       # the full pass (13 Oct, tools/pixellab_fight_manifest.json)
## The fight kit (17 Oct, tools/make_fight_kit_manifest.py): every site's plate and wall again at the bigger frame's
## size (744 wide, drawn as the old 688 - so every slot and the pan keep their numbers), and a pair of hands for every
## gun base (art/fight/hands/<base>.png, 280x210, drawn as the kind's 256x192 were). The kit's plates are read first.
const KIT_DIR := "res://art/fight_new/%s.png"
## The walls tall (23 Oct, tools/make_fight_walls_manifest.py; Matt: ducked "you can see the same tiled wall 3 times"):
## 744x256, one piece reaching the frame's foot at the full duck, so nothing is tiled under them. Read first.
const WALLS_DIR := "res://art/fight_walls/%s.png"
## A boss's own den (25 Oct, Matt: "unique fight art backdrops for each boss including pinnacles";
## tools/make_boss_backdrops_manifest.py): a plate and a cover a head or a pinnacle, read first while he's out.
const BOSS_DIR := "res://art/fight_boss/%s.png"
## The County's places (26 Oct, tools/make_county_art_manifest.py): a plate and a cover a place, read on its runs.
const COUNTY_DIR := "res://art/fight_county/%s.png"
const DUCK_REACH_SLACK := 6.0                     # the jolt's most (3 px x1.5) under a ducked wall
const PLATE_VIEW_W := 688.0                       # a plate's width in the frame's space, whatever its picture's
const COVER_VIEW_W := 688.0
const HANDS_VIEW_W := 256.0 * 0.8                 # the hands' drawn width in the frame's space (the kind's at HANDS_SCALE)
const ZONE_KEYS := ["the_outskirts", "the_estate", "the_town", "the_city"]
const COVER_TOP := H - 48                         # where a cover's drawn top sits, whatever its picture's height
## The three depths: where a figure stands (its feet, in the frame), its scale, how lit.
const SLOTS := [
	{"foot": Vector2(255, 211), "scale": 0.62, "lit": 0.9},     # mid: the middle ground, in from the right (Matt, 13 Oct: more centre)
	{"foot": Vector2(405, 232), "scale": 0.95, "lit": 1.0},     # near: close, left of your gun (Matt: it stood behind it)
	{"foot": Vector2(322, 172), "scale": 0.3, "lit": 0.72},     # far: the Parade's test plate's; each site's own below
]
## Each site's far one, on its own ground (Matt, 13 Oct: "doesn't sit on the floor"): its feet where the plate's floor is,
## a long way off, and its size for that distance - read off each plate.
## And the middle and near ones where a site's ground wants them elsewhere (Matt's playtest, 13 Oct): the Allotments'
## middle one right of the water butt; Ransacked Streets' middle one left of the sofa and the near one right of it;
## the Pleasure Park's both further left.
const SITE_MID := {"the_allotments": Vector2(288, 211), "ransacked_streets": Vector2(178, 211), "the_pleasure_park": Vector2(215, 211)}
const SITE_NEAR := {"ransacked_streets": Vector2(322, 232), "the_pleasure_park": Vector2(362, 232)}
const SITE_FAR := {     # down the middle where the ground goes away, between the middle one and the near one
	"the_allotments": [Vector2(340, 162), 0.28], "the_garden_centre": [Vector2(330, 154), 0.24],
	"top_farm": [Vector2(320, 154), 0.25], "ransacked_streets": [Vector2(380, 182), 0.28],
	"the_parade": [Vector2(320, 178), 0.30], "the_retail_park": [Vector2(322, 152), 0.24],
	"the_pleasure_park": [Vector2(288, 170), 0.28], "shopping_centre": [Vector2(322, 182), 0.31],
	"the_bank": [Vector2(325, 175), 0.42], "the_services": [Vector2(318, 165), 0.24],
	"the_hospital": [Vector2(318, 154), 0.24], "the_barracks": [Vector2(322, 174), 0.26],
}
## The search's crates on the ground (Matt, 13 Oct: they floated): the one being opened near on the left, the next two
## further down the street, each its feet on the tarmac and a shadow under it.
const CRATE_SPOTS := [
	{"foot": Vector2(175, 212), "scale": 0.9},
	{"foot": Vector2(285, 201), "scale": 0.72},
	{"foot": Vector2(372, 185), "scale": 0.55},
]
## The crate just opened (14 Oct, Matt: "the open versions of the boxes don't actually show"): set down open at the
## front left, a little bigger than the rest, its finds named over it, for OPEN_S; it fades its last OPEN_FADE_S, and goes
## at once when a gang comes. Mockup docs/design/mockups/search_mockup4.png.
const OPEN_SPOT := {"foot": Vector2(72, 214), "scale": 1.2}
const OPEN_S := 2.0
const OPEN_FADE_S := 0.5
const PLATE_AT := Vector2(-50, -20)       # the plate's crop for the fight; the search pans a further PAN along
const PAN := 50.0
const COVER_Y := H - 72
const COVER_X := -20.0                    # the cover's left at no pan: its 688 still past the right edge at the search's pan (x1.4)
const HANDS_AT := Vector2(W - 235, H - 178)
const HANDS_SCALE := 0.8
const HANDS_CORNER := Vector2(W + 6, H + 6)     # where the hands' drawn bottom-right sits: each gun's picture in the corner
const DOWN_S := 0.7                       # a kill's fall
const POP_S := 0.35                       # a figure coming in: a fade where it stands (Matt, 13 Oct: rising up through the floor read wrong)
const JOLT_S := 0.2
const RED_S := 0.45
## The hits (27 Oct, Matt: "more of a violent impact for hitting them"; the canvas's "Hit registers, take 2"): a solid
## hit holds the frame, knocks the figure back and tilts it, sprays from the spot by type and knocks a chunk off its
## bar; a kill holds longer, bursts bigger and throws the body back. A big hit on you jolts the frame.
const STOP_S := 0.05                       # a solid hit's hold
const STOP_KILL_S := 0.12
const STOP_GAP := 0.3                      # a hold only this long after the last one ends: a stream of hits never slows the frame (the review)
const KICK_S := 0.18                       # the knock-back's spring
const KICK_PX := 10.0
const KICK_DEG := 5.0
const THROW_PX := 28.0                     # a kill's throw, over the fall
const THROW_DEG := 18.0
const FLASH_S := 0.12                      # a hit's white
const SPRAY := {"physical": [Color("b3121b"), Color("8a0c12")], "bleed": [Color("d8262e"), Color("8a0c12")], "fire": [Color("ffb347"), Color("ff6a1a")],
	"frost": [Color("cfe9ff"), Color("8fc6f0")], "poison": [Color("7ed07a"), Color("3f8f3a")], "shock": [Color("fff3a0"), Color("ffd84a")]}
const BIG_HURT := 0.1                      # a hit on you this share of your max HP jolts the frame
const LOW_RED := 0.3                       # under a third of your HP the red holds this much

static var _tex := {}

var _plate: TextureRect
var prop                                   # a run event in the scene (1 Nov, event_prop.gd): test art, on the gang's slots
var _dogs_on := false                      # the dogs are being fought: they stand in the gang's places, the gang's art hidden
var _site_key := "-"                      # the site the plate and cover are of
var _zone_key := "the_estate"             # its zone's gang
var _boss_key := ""                       # the head when he's out, "" else
var _cover_y: float = COVER_Y
var _own_site := false                     # the site's own plate is up (its far slot with it)
var _kit_site := false                     # and it's the kit's pair (its slots placed apart from the old pair's)
var _cover_s := 1.0                        # the wall's picture scaled to COVER_VIEW_W
var _hs := HANDS_SCALE                     # the hands' picture scaled to HANDS_VIEW_W
var _mz: Dictionary = {}                   # the flash for the picture up: its kind's shape, at this picture's muzzle
var _hands_at := HANDS_AT                 # the hands' top-left for the gun's picture                   # the cover's top-left y: its drawn top at COVER_TOP
var _figs: Array = []                     # {rect, state: "", t, fire_t, next_fire}
var _crates: Array = []                   # the crates in the street while searching
var _cover: TextureRect
var _sky                                   # the sky's layer (23 Oct): night, rain, fog over the scene
var _shadows: Array = []                   # a shadow under each crate
var _open_c: TextureRect                   # the crate just opened, open (OPEN_SPOT)
var _open_sh: TextureRect
var _open_tag: Label                       # "Opened · 2 finds" over it
var _open_left := 0.0                      # its seconds still up
var _open := {}                            # {name, key, finds} while it's up
var _open_for = null                       # the queue and the crate in hand it last saw: a step on is an opening
var _open_ci := -1
var _open_seen := 0.0                      # the game's clock at the last look: a step on seen long after isn't "just"
const OPEN_FRESH_S := 2.0
var _glass: Control                        # the magnifying glass over the crate being opened, its ring the search's progress
var _search_p := 0.0
var _hands: TextureRect
var _red: TextureRect
var _marker: Label
var _pan := 0.0
var _pan_to := 0.0
var _on_you := 0
var _kills_seen := -1
var _hp_seen := -1.0
var _jolt := 0.0
var _stop_t := 0.0                         # the hit-stop: the frame held
var _since_stop := 99.0                    # since the last hold ended
var _last_hit := {}                        # the last shot's figure and spot, for its impact
var _low_hp := false
var _red_a := 0.0
var _shot_t := 0.0
var _rof := 1.0
var _firing := false
var _reloading := false                    # the gun in hand reloading, nothing else firing (28 Oct, magazines): no shots
var _recoil := 0.0
## A melee weapon's swing (14 Oct, Matt: "we need an attack frame for melee ... the action just hangs"): in engine, no
## new art. The weapon's arm (the picture split from the off hand where there's a clean gap between them) winds back,
## chops toward the one it's hitting and settles, round the forearm; the hit - its marker, its number - lands on the
## chop, and a streak follows the head through it. A gun keeps its kick.
const SWING_BACK := 0.12                  # radians, the wind-up (clockwise: the head back; more lift than lean, so it stays in frame)
const SWING_FWD := -0.46                  # the chop (anticlockwise: the head down toward them)
const SWING_LIFT := Vector2(-6, -18)      # the wind-up's lift, in the picture's pixels
const SWING_LUNGE := Vector2(-40, 14)     # the chop's reach toward the street
const SWING_UP := 0.35                    # the swing's share winding up
const SWING_CONTACT := 0.55               # where in it the chop lands
const STREAK_S := 0.16                    # a streak point's life
var _melee := false
## Your muzzle flash (15 Oct, parked item 9: "doesn't work on shotgun or bolt gun" - there wasn't one): at each picture's
## muzzle (read off the art, in its pixels), its shape the gun's, on the shot's beat with the kick; none on a blade or
## a hammer. The improvised pictures, the SMG's and the pistol's are to be redrawn down the sight (the art pass): their
## points move with them.
const MUZZLE := {
	"pistol": {"at": Vector2(124, 31), "dir": Vector2(0.05, -1), "len": 16.0, "wide": 9.0, "s": 0.06},     # 16 Oct: off the new hands (the revolver held up and away)
	"rifle": {"at": Vector2(38, 50), "dir": Vector2(-1, -0.42), "len": 38.0, "wide": 8.0, "s": 0.07},
	"shotgun": {"at": Vector2(27, 43), "dir": Vector2(-1, -0.36), "len": 30.0, "wide": 16.0, "s": 0.08, "barrels": 2},
	"smg": {"at": Vector2(77, 47), "dir": Vector2(-1, -0.12), "len": 10.0, "wide": 6.0, "s": 0.04},     # the suppressor's end: a short flash
	"improvised": {"at": Vector2(115, 24), "dir": Vector2(-0.8, -0.6), "len": 10.0, "wide": 10.0, "s": 0.05, "spark": true},     # the nail gun's nose
}
var _kind := ""                           # the hands' kind (_hands_kind), for the flash
var _flash: Control
var _hand_l: TextureRect                  # the off hand, still (a melee picture split in two)
var _hand_r: TextureRect                  # the weapon's arm, swinging
var _swing := -1.0                        # time into a swing; below 0 none
var _swing_len := 0.3
var _swing_k := -1                        # the one it's at
var _swing_off := Vector2.ZERO            # the hands' shift through it
var _streak: Control                      # the head's path through the chop
var _trail: Array = []                    # [point in the frame, age]
static var _splits := {}                  # a picture's split column, its pivot and the weapon's tip
var _marker_t := 0.0
var _run_seen := -1
var _duck := 0.0                          # 0 up, 1 down behind the wall (13 Oct, Matt: "you never duck")
var _duck_t := 0.0                        # how long left down
var _duck_next := 4.0                     # till the next duck while under fire
const DUCK_COVER := 80.0
const DUCK_HANDS := 150.0
const DUCK_SCENE := 10.0

## The elements (13 Oct, Matt: "in engine rather than with art"): on them, a tint and a particle each on every one
## that's up - fire's flames, poison's bubbles, bleed's drips, frost's flakes and a slowness, shock's flicker and
## arcs; on you, the frame's edges in the colour of what's on you, breathing. Nothing here changes a number.
const FX_ELEMENTS := ["fire", "poison", "bleed", "frost", "shock"]
const FX_TINT := {"fire": Color(1.3, 0.78, 0.55), "poison": Color(0.72, 1.15, 0.62), "bleed": Color(1.12, 0.72, 0.72),
	"frost": Color(0.62, 0.86, 1.5), "shock": Color(1.0, 1.0, 1.0)}
const FROST_SLOW := 0.5                   # chilled: they fire and pop at half the pace
var _them_fx := {}                        # element -> true while it's on them
var _you_fx := {}                         # element -> true while it's on you
var _edges := {}                          # element -> its TextureRect, the frame's edges in its colour
var _fx_t := 0.0                          # the clock the breathing and the flicker run off
var _arcs: Array = []                     # a Line2D a figure: shock's arc
## A bar over each of them (15 Oct, Matt: "it's odd having 3 enemies and one bar shared"; hpbars_mockup.png A): the one
## you're hitting outlined amber with its HP over it and the dots' shares at its end, the rest full till their turn; the
## head's bigger. Drawn on a layer scaled back to the screen's pixels, so the words stay crisp in the scaled frame.
var _bars_layer: Control
var _target_k := -1                       # the one you're hitting: your shots land on it, a kill drops it
var _bar_info := {"hp": 1.0, "of": 1.0, "dots": {}, "boss": false}
var _hp_tag: Label                        # "83 / 120" over the one you're hitting
const BAR_H := 9
const BAR_H_HIT := 12
const BAR_H_HEAD := 14
const BAR_W_HEAD := 170.0

## A texture by name: the full pass's (art/fight) first, the test's (art/fight_test) else; imported if the editor's seen
## it, else read straight off the disk.
static func tex(nm: String) -> Texture2D:
	if _tex.has(nm):
		return _tex[nm]
	var t: Texture2D = null
	var scene: bool = nm.ends_with("_plate") or nm.ends_with("_cover")
	var dirs: Array = ([BOSS_DIR, COUNTY_DIR] if scene else []) + ([WALLS_DIR] if nm.ends_with("_cover") else []) + ([KIT_DIR] if scene else []) + [FULL_DIR, DIR]
	for dir in dirs:
		var path: String = dir % nm
		if ResourceLoader.exists(path):
			t = load(path)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null:
				img.generate_mipmaps()
				t = ImageTexture.create_from_image(img)
		if t != null:
			_tex_from[nm] = dir
			break
	_tex[nm] = t
	return t


## The folder a picture was found in (the smoke: the walls from art/fight_walls/).
static var _tex_from := {}
static func tex_from(nm: String) -> String:
	tex(nm)
	return str(_tex_from.get(nm, ""))


## The first of the names that has a picture (the site's own, then the slice's).
static func tex_of(names: Array) -> Texture2D:
	for n in names:
		var t := tex(str(n))
		if t != null:
			return t
	return null


## Where a picture's drawn part ends, in its own pixels (a figure's feet, a cover's top): its used rect, cached.
static var _used := {}
## Where a wall's body starts (17 Oct, Matt: the kit's walls showed only their tips - the Allotments' weeds, the Retail
## Park's shrubs): the first row at least WALL_SOLID across drawn, so what pokes above it pokes above COVER_TOP; a
## picture with no such row keeps its highest drawn one.
const WALL_SOLID := 0.6
static var _wall_tops := {}
static func wall_top(t: Texture2D) -> float:
	if t == null:
		return 0.0
	var key: int = t.get_instance_id()
	if not _wall_tops.has(key):
		var top: float = used_of(t).position.y
		var img := t.get_image()
		if img != null:
			img = img.duplicate()
			if img.is_compressed():
				img.decompress()
			var w: int = img.get_width()
			for y in range(img.get_height()):
				var n := 0
				for x in range(w):
					if img.get_pixel(x, y).a > 0.5:
						n += 1
				if n >= WALL_SOLID * w:
					top = maxf(top, float(y))
					break
		_wall_tops[key] = top
	return _wall_tops[key]


static func used_of(t: Texture2D) -> Rect2:
	if t == null:
		return Rect2()
	var key: int = t.get_instance_id()
	if not _used.has(key):
		var img := t.get_image()
		_used[key] = Rect2(img.get_used_rect()) if img != null else Rect2(Vector2.ZERO, t.get_size())
	return _used[key]


static func has_art() -> bool:
	return tex("parade_plate") != null


func _init() -> void:
	size = Vector2(W, H)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := UI.panel(self, Rect2(0, 0, W, H), UI.box(Pal.BG, 8))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate = _rect(tex("parade_plate"))
	for k in range(SLOTS.size()):
		var r := _rect(tex("gang_stand"))
		r.visible = false
		_figs.append({"rect": r, "state": "", "t": 0.0, "fire_t": 0.0, "next_fire": randf_range(0.4, 1.6)})
	for f in _figs:
		f["fx"] = {}
		for el in ["fire", "poison", "bleed", "frost"]:
			f["fx"][el] = _emitter(el)
		f["shock_t"] = 0.0
		f["shock_next"] = randf_range(0.1, 0.4)
		var arc := Line2D.new()
		arc.width = 2.0
		arc.default_color = Pal.ELEMENT_COLOURS["shock"].lerp(Color.WHITE, 0.4)
		arc.visible = false
		add_child(arc)
		_arcs.append(arc)
	for k in range(3):
		var sh := _rect(_shadow_tex())
		sh.visible = false
		_shadows.append(sh)
		var c := _rect(null)
		c.visible = false
		_crates.append(c)
	_open_sh = _rect(_shadow_tex())
	_open_sh.visible = false
	_open_c = _rect(null)
	_open_c.visible = false
	# the figures stand in depth order: the far one behind, the near one in front
	move_child(_figs[2]["rect"], _plate.get_index() + 1)
	# the sky (23 Oct, parked item 8): night's and fog's wash and the rain in the air between the gang and the wall,
	# under the wall, the hands, the bars and the numbers
	_sky = SkyLayer.new(Vector2(W, H), true)     # the fight's fog thinner (23 Oct)
	add_child(_sky)
	prop = EventProp.new()
	prop.view = self
	prop.size = Vector2(W, H)
	add_child(prop)
	move_child(prop, _sky.get_index())         # with the figures: under the sky, the wall and the hands
	_cover = _rect(null)
	_site("")
	_hands = _rect(null)                       # the gun's own, set by show_state (and its corner with it)
	_hands.scale = Vector2(HANDS_SCALE, HANDS_SCALE)
	_hands.position = HANDS_AT
	_streak = Streak.new()
	_streak.view = self
	_streak.size = Vector2(W, H)
	_streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_streak)
	move_child(_streak, _hands.get_index())  # behind the hands
	for side in ["l", "r"]:
		var h := TextureRect.new()
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		h.visible = false
		_hands.add_child(h)
		if side == "l":
			_hand_l = h
		else:
			_hand_r = h
	for el in ["fire", "poison", "bleed"]:
		var e := TextureRect.new()
		e.texture = _vignette(Pal.ELEMENT_COLOURS[el], 0.7)
		e.size = Vector2(W, H)
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		e.modulate = Color(1, 1, 1, 0)
		add_child(e)
		_edges[el] = e
	_red = TextureRect.new()
	_red.texture = _vignette()
	_red.size = Vector2(W, H)
	_red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_red.modulate = Color(1, 1, 1, 0)
	add_child(_red)
	_bars_layer = Control.new()
	_bars_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bars_layer)
	for f in _figs:
		var fb := FigBar.new()
		fb.visible = false
		_bars_layer.add_child(fb)
		f["bar"] = fb
	_hp_tag = UI.label(_bars_layer, Rect2(0, 0, 120, 24), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	UI.shadow(_hp_tag)
	_hp_tag.visible = false
	_open_tag = UI.label(self, Rect2(0, 0, 160, 22), "", "Medium", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, false)
	UI.shadow(_open_tag)
	_open_tag.visible = false
	_glass = Glass.new()
	_glass.ring = Pal.ACCENT
	_glass.visible = false
	add_child(_glass)
	_flash = Flash.new()
	_flash.visible = false
	add_child(_flash)
	move_child(_flash, _hands.get_index() + 1)     # over the gun's end
	_marker = UI.label(self, Rect2(0, 0, 24, 24), "✕", "Bold", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(_marker)
	_marker.visible = false
	_placer = preload("res://scripts/ui/fight_placement.gd").new()
	_placer.view = self
	_placer.size = Vector2(W, H)
	add_child(_placer)
	_v66_make()                                  # (BUILD66-V) the headshot's pop, the jam, the hard man's plate, the streak, Last Stand


## A slot on this site: the far one's on the site's own ground when its own plate's up.
func slot_of(k: int) -> Dictionary:
	if placing and _edit.size() == 3:
		return _edit[k]
	return site_slot(slot_key(), k)


## The key a site's slots are placed under: the kit's pair apart from the old pair (17 Oct: the new plates aren't the
## old ones' ground), "" for the test plate's.
func slot_key() -> String:
	if not _own_site:
		return ""
	return _site_key + ("@kit" if _kit_site else "")


## A site's slot k ("" for the test plate's): where F3/F5 put it (data/fight_slots.tres), else its own in the tables
## below, else the common one.
static func site_slot(key: String, k: int) -> Dictionary:
	var placed: Dictionary = saved_sites()
	var base: String = stage_base(key)
	var tries: Array = [key, key.trim_suffix("@kit")]     # the kit's pair not placed yet: where the old pair's were, as a start
	if base != key.trim_suffix("@kit"):
		tries += [base + ("@kit" if key.ends_with("@kit") else ""), base]     # a stage not placed yet: its site's own (BUILD57)
	for at in tries:
		if placed.has(at) and placed[at] is Array and placed[at].size() == 3:
			var row: Array = placed[at][k]
			return {"foot": Vector2(float(row[0]), float(row[1])), "scale": float(row[2]), "lit": SLOTS[k]["lit"]}
	key = base
	if k == 2 and SITE_FAR.has(key):
		return {"foot": SITE_FAR[key][0], "scale": SITE_FAR[key][1], "lit": SLOTS[2]["lit"]}
	var own: Dictionary = (SITE_MID if k == 0 else SITE_NEAR) if k < 2 else {}
	if own.has(key):
		return {"foot": own[key], "scale": SLOTS[k]["scale"], "lit": SLOTS[k]["lit"]}
	return SLOTS[k]


## What F3/F5 has saved (data/fight_slots.tres), read once; use_saved() after a save.
const SLOTS_FILE := "res://data/fight_slots.tres"
static var _saved_sites = null
static func saved_sites() -> Dictionary:
	if _saved_sites == null:
		_saved_sites = {}
		if ResourceLoader.exists(SLOTS_FILE):
			var r = load(SLOTS_FILE)
			if r != null and r.get("sites") is Dictionary:
				_saved_sites = r.sites
	return _saved_sites


static func use_saved(sites: Dictionary) -> void:
	_saved_sites = sites


# ------------------------------------------------------------------ the placement tool (F3, debug builds)

var placing := false                      # F3's on: the fight holds still, the three stand where they're being put
var _edit: Array = []                     # the three slots as they're being dragged
var _placer: Control                      # fight_placement.gd


## Whether F3 can start here: a debug build, the run screen up, a site with its own art (its slots are its own).
func can_place() -> bool:
	return OS.is_debug_build() and _shown() and _own_site


func set_placing(on: bool) -> void:
	placing = on
	placing_changed.emit(on)
	_bars_layer.visible = not on              # the tool holds the frame clear
	_flash.visible = false
	if on:
		_edit = []
		for k in range(3):
			_edit.append(site_slot(slot_key(), k).duplicate())
		for k in range(_figs.size()):
			var f: Dictionary = _figs[k]
			if not f.has("who"):
				f["who"] = "a"
			f["boss"] = ""
			f["state"] = "up"
			f["t"] = 0.0
		_duck = 0.0
		_duck_t = 0.0
	else:
		_edit = []
		for k in range(_figs.size()):
			_set_state(k, "")                 # the fight picks up as it was: as many come in as are on you


func set_slot(k: int, foot: Vector2, sc: float) -> void:
	if k >= 0 and k < _edit.size():
		_edit[k] = {"foot": foot, "scale": sc, "lit": SLOTS[k]["lit"]}


## Placing: the plate at rest, all three standing on their slots, nothing firing, flashing or burning.
func _place_tick() -> void:
	_plate.position = PLATE_AT
	_cover.position = Vector2(COVER_X, _cover_y)
	_hands.position = _hands_at
	_marker.visible = false
	_red.modulate.a = 0.0
	for k in range(_figs.size()):
		var f: Dictionary = _figs[k]
		var r: TextureRect = f["rect"]
		var slot: Dictionary = slot_of(k)
		r.visible = true
		r.texture = _fig_tex(f, "stand")
		if r.texture != null:
			r.size = r.texture.get_size()
		r.modulate.a = 1.0
		r.scale = Vector2(slot["scale"], slot["scale"])
		var u: Rect2 = used_of(r.texture)
		var anchor: Vector2 = Vector2(u.get_center().x, u.end.y) if u.size.y > 0.0 else Vector2(r.size.x * 0.5, r.size.y)
		r.position = slot["foot"] - anchor * slot["scale"]
		r.self_modulate = Color(slot["lit"], slot["lit"], slot["lit"], 1.0)
		_arcs[k].visible = false
		for el in f["fx"]:
			f["fx"][el].emitting = false
	if _placer != null:
		_placer.queue_redraw()


## The site's plate and cover (its own, else the Parade's test pair), and the wall's fill cut from the cover. A stage's
## key (`<site>_2`) takes its own plate on its own wall when drawn, else the site's wall (BUILD57, stages.md §6).
func _site(key: String) -> void:
	_site_key = key
	var base: String = stage_base(key)
	var own_ct: Texture2D = scene_cover(key)
	var own: bool = tex(key + "_plate") != null and own_ct != null     # the site's pair, or the Parade's: never one of each
	_own_site = own
	_kit_site = own and (kit_pair(key) or (base != key and kit_pair(base)))     # a stage's plate is drawn at the kit's size, on its site's ground
	_plate.texture = tex(key + "_plate") if own else tex("parade_plate")
	if _plate.texture != null:
		_plate.size = _plate.texture.get_size()
		_plate.scale = Vector2.ONE * (PLATE_VIEW_W / _plate.size.x)     # the kit's 744 drawn as the old 688: the slots and the pan keep their numbers
	var ct: Texture2D = own_ct if own else tex("parade_cover")
	_cover.texture = ct
	if ct == null:
		return
	_cover.size = ct.get_size()
	_cover_s = COVER_VIEW_W / _cover.size.x
	_cover.scale = Vector2.ONE * _cover_s
	_cover_y = COVER_TOP - wall_top(ct) * _cover_s     # the body's top at COVER_TOP, not its tallest weed (17 Oct)
	# the wall runs to the frame's foot at the full duck by itself (art/fight_walls/, 23 Oct): the tiled fill that
	# carried a short wall's bricks down under it is gone (Matt: "you can see the same tiled wall 3 times"); the smoke
	# holds every site's wall to cover_reaches


## Whether a wall's picture runs to the frame's foot at the full duck, by itself (23 Oct): its top at COVER_TOP,
## raised DUCK_COVER, its foot past H by the jolt's slack.
static func cover_reaches(ct: Texture2D) -> bool:
	if ct == null:
		return false
	var s: float = COVER_VIEW_W / ct.get_width()
	return COVER_TOP - wall_top(ct) * s - DUCK_COVER + ct.get_height() * s >= H + DUCK_REACH_SLACK


## Whether a site's plate and wall are the kit's (art/fight_new/), both.
static func kit_pair(key: String) -> bool:
	if boss_pair(key):
		return true                          # a den's pair is drawn at the kit's size
	for nm in [key + "_plate", key + "_cover"]:
		var path: String = KIT_DIR % nm
		if not (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
			return false
	return true


## The run's scene for its stage (BUILD55-U, docs/design/stages.md §6): `<site>_2` / `<site>_3` for the 2/3 and the 3/3
## when that stage's plate is drawn, else the site's own. A stage's plate stands on the site's wall unless the stage has
## a wall of its own (BUILD57: §6's call 7, a new plate per stage on the site's existing wall). A signal (depth 4 and
## on) and the 1/3 read the site's.
static func stage_key(m: Dictionary) -> String:
	var key: String = Items.slug(str(Data.TIERS[int(m["tier"])]["name"]))
	var st: int = int(m.get("stage", m.get("t", {}).get("depth", 1))) if m.get("signal", {}).is_empty() else 1     # A's mission["stage"]; the depth a campaign run stands at else
	if st >= 2 and st <= Data.STAGES and tex("%s_%d_plate" % [key, st]) != null:
		return "%s_%d" % [key, st]
	return key


## The site a stage's key is of (`the_allotments_2` -> `the_allotments`, an "@kit" slot key's too); any other key as it
## is (BUILD57).
static func stage_base(key: String) -> String:
	var k: String = key.trim_suffix("@kit")
	for st in range(2, Data.STAGES + 1):
		var suf: String = "_%d" % st
		if k.ends_with(suf):
			var b: String = k.trim_suffix(suf)
			for t in Data.TIERS:
				if Items.slug(str(t["name"])) == b:
					return b
			for c in Data.COUNTY:
				if Items.slug(str(c["place"])) == b:
					return b                     # a County place's stage (BUILD61-U)
	return k


## A scene's wall: its own, else for a stage its site's (BUILD57).
static func scene_cover(key: String) -> Texture2D:
	var ct: Texture2D = tex(key + "_cover")
	var base: String = stage_base(key)
	if ct == null and base != key:
		ct = tex(base + "_cover")
	return ct


## The head's own fight (BUILD55-U, §4: mission["head_fight"]): his den's key from the first man, "" on any other run.
static func head_den(m: Dictionary) -> String:
	if not bool(m.get("head_fight", false)):
		return ""
	var nm: String = str(m.get("boss", {}).get("name", ""))
	if nm == "" and not Data.county(str(m.get("county", ""))).is_empty():
		nm = str(Data.county(str(m["county"])).get("who", ""))     # a County head's own fight (BUILD61-U): his, not the host site's head
	if nm == "":
		for b in Data.BOSSES:
			if int(b["tier"]) == int(m["tier"]):
				nm = str(b["name"])
	return Items.slug(nm) if nm != "" else ""


## A boss's own plate and cover are both on disk (art/fight_boss).
static func boss_pair(key: String) -> bool:
	return _pair_in(BOSS_DIR, key) or _pair_in(COUNTY_DIR, key)     # a County place's pair is drawn at the kit's size too


static func _pair_in(dir: String, key: String) -> bool:
	for nm in [key + "_plate", key + "_cover"]:
		var path: String = dir % nm
		if not (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
			return false
	return true


## The County zone's crew a run meets (its place's zone's: "the_motorway"...), "" off the County.
static func county_gang(m: Dictionary) -> String:
	var sg: Dictionary = m.get("signal", {})
	var k: String = str(sg.get("order", ""))     # a County run's own crew; a remixed signal brings the crew it was aimed with (the third review's E1)
	var c: Dictionary = Data.county(k)
	return Items.slug(str(Data.COUNTY_ZONES[int(c["cz"])]["name"])) if not c.is_empty() else ""


## A County run's scene (BUILD61-U, docs/design/county_stages.md §5): `<place>_2` / `<place>_3` for the 2/3 and the 3/3
## when that stage's plate is drawn (art/fight_county/), standing on the place's wall unless it has its own; else the
## place's own. The 1/3, a head's fight (his den first, show_state) and a remixed signal read the place's.
static func county_scene(m: Dictionary) -> String:
	var pk: String = county_key(m)
	if pk == "":
		return ""
	var st: int = int(m.get("stage", 1)) if m.has("county") and not bool(m.get("head_fight", false)) else 1
	if st >= 2 and st <= Data.STAGES and tex("%s_%d_plate" % [pk, st]) != null:
		return "%s_%d" % [pk, st]
	return pk


## The County place a run is on (its own, or a remixed signal's), "" for none.
static func county_key(m: Dictionary) -> String:
	var sg: Dictionary = m.get("signal", {})
	var k: String = str(sg.get("county", sg.get("order", "")))
	return Items.slug(str(Data.county(k)["place"])) if not Data.county(k).is_empty() else ""


## A figure's picture for a pose: the head's when he's out, else the zone's member it was given, else the slice's.
func _fig_tex(f: Dictionary, pose: String) -> Texture2D:
	var bk: String = str(f.get("boss", ""))      # whose picture it took when it came up, not who's out now (the review)
	if bk != "":
		var h := tex("head_%s_%s" % [bk, pose])
		if h != null:
			return h
	return tex_of(["gang_%s_%s_%s" % [_zone_key, f.get("who", "a"), pose], "gang_" + pose])


func _rect(t: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if t != null:
		r.size = t.get_size()
	add_child(r)
	return r


## A particle a figure for an element: flames rising, bubbles rising slower, drips falling, flakes drifting down.
func _emitter(el: String) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.local_coords = false
	p.texture = _dot()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.color = Pal.ELEMENT_COLOURS[el]
	var ramp := Gradient.new()
	ramp.set_color(0, Pal.ELEMENT_COLOURS[el].lerp(Color.WHITE, 0.35))
	ramp.set_color(1, Color(Pal.ELEMENT_COLOURS[el], 0.0))
	if el == "fire":                                        # yellow at the root, orange, red going out
		ramp.set_color(0, Color(1.0, 0.92, 0.45))
		ramp.add_point(0.45, Color(1.0, 0.5, 0.15, 0.9))
		ramp.set_color(ramp.get_point_count() - 1, Color(0.8, 0.12, 0.05, 0.0))
	elif el == "bleed":
		ramp.set_color(0, Color(0.75, 0.05, 0.1))
		ramp.set_color(1, Color(0.55, 0.0, 0.05, 0.0))
	elif el == "frost":
		ramp.set_color(0, Color(0.92, 0.97, 1.0))
	p.color_ramp = ramp
	if el in ["fire", "frost"]:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD      # flames and frost glow over the figure
		p.material = mat
	match el:
		"fire":
			p.amount = 36
			p.lifetime = 0.6
			p.direction = Vector2(0, -1)
			p.spread = 14.0
			p.gravity = Vector2(0, -90)
			p.initial_velocity_min = 25.0
			p.initial_velocity_max = 55.0
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.3
		"poison":
			p.amount = 18
			p.lifetime = 1.2
			p.direction = Vector2(0, -1)
			p.spread = 25.0
			p.gravity = Vector2(0, -20)
			p.initial_velocity_min = 10.0
			p.initial_velocity_max = 25.0
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.2
		"bleed":
			p.amount = 16
			p.lifetime = 0.8
			p.direction = Vector2(0, 1)
			p.spread = 8.0
			p.gravity = Vector2(0, 260)
			p.initial_velocity_min = 5.0
			p.initial_velocity_max = 20.0
			p.scale_amount_min = 0.5
			p.scale_amount_max = 0.9
		"frost":
			p.amount = 26
			p.lifetime = 1.4
			p.direction = Vector2(0, 1)
			p.spread = 60.0
			p.gravity = Vector2(0, 18)
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 14.0
			p.scale_amount_min = 0.35
			p.scale_amount_max = 0.7
	add_child(p)
	return p


## A soft flat ellipse: a crate's shadow on the tarmac.
static var _shadow: Texture2D
static func _shadow_tex() -> Texture2D:
	if _shadow != null:
		return _shadow
	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(64):
			var d: float = Vector2((x - 31.5) / 31.5, (y - 7.5) / 7.5).length()
			img.set_pixel(x, y, Color(0, 0, 0, clampf(1.0 - d, 0.0, 1.0) * 0.55))
	_shadow = ImageTexture.create_from_image(img)
	return _shadow


## The magnifying glass: a lens, a ring that fills with the search, a handle down to the right.
class Glass extends Control:
	const R := 15.0
	var p := 0.0
	var ring := Color.WHITE                   # the search's colour, set by the view (an inner class sees no palette)
	func _init() -> void:
		size = Vector2(R * 2 + 24, R * 2 + 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := Vector2(R, R)
		var h := Vector2(0.7071, 0.7071)
		draw_line(c + h * (R + 1), c + h * (R + 16), Color(0, 0, 0, 0.55), 7.0)         # the handle's shadow
		draw_line(c + h * (R + 1), c + h * (R + 15), Color(0.42, 0.27, 0.16), 5.0)
		draw_circle(c, R - 1, Color(0.75, 0.88, 1.0, 0.22))                          # the lens
		draw_arc(c, R, 0.0, TAU, 40, Color(0, 0, 0, 0.55), 5.0)
		draw_arc(c, R, 0.0, TAU, 40, Color(0.85, 0.85, 0.82), 3.0)
		if p > 0.0:
			draw_arc(c, R, -PI / 2.0, -PI / 2.0 + TAU * p, 40, ring, 3.0)      # how far the search is
		draw_arc(c + Vector2(-4, -4), R * 0.45, PI, PI * 1.5, 8, Color(1, 1, 1, 0.6), 2.0)     # a glint


## A soft round dot, the particles' one picture.
static var _dot_tex: Texture2D
static func _dot() -> Texture2D:
	if _dot_tex != null:
		return _dot_tex
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var d: float = Vector2(x - 7.5, y - 7.5).length() / 7.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex


## The edges a hit brings (red), or an element on you brings (its colour): clear in the middle, coloured at the edge.
func _vignette(c := Color(0.75, 0.1, 0.08), strength := 0.85) -> Texture2D:
	@warning_ignore("integer_division")
	var img := Image.create(W / 4, H / 4, false, Image.FORMAT_RGBA8)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var dx: float = absf(float(x) / (img.get_width() - 1) - 0.5) * 2.0
			var dy: float = absf(float(y) / (img.get_height() - 1) - 0.5) * 2.0
			var e: float = clampf((maxf(dx, dy) - 0.45) / 0.55, 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, e * e * strength))
	var t := ImageTexture.create_from_image(img)
	return t


## What the sim says, each refresh: how many are on you, kills, your HP, the search's crates.
func show_state(sim, m: Dictionary) -> void:
	_sky.set_sky(sim.is_night(), sim.fight_weather_of(int(m["tier"])))     # the site's sky as the Map's card had it (23 Oct), dry under a roof (25 Oct)
	if placing:
		return                                   # F3's on: the fight holds still
	if sim.runs_total != _run_seen:
		_run_seen = sim.runs_total                # a new run: nobody up, nothing to drop
		_kills_seen = int(m["kills"])
		_hp_seen = sim.hp
		_duck = 0.0
		_duck_t = 0.0
		_target_k = -1
		for f in _figs:
			f["state"] = ""
			f["rect"].visible = false
	var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	# the site's own art, its zone's gang, the head when he's out
	var site: Dictionary = Data.TIERS[int(m["tier"])]
	_boss_key = Items.slug(str(m["boss"]["name"])) if boss_on else ""
	var place_key: String = county_key(m)
	var den: String = head_den(m) if _boss_key == "" else _boss_key     # the head's own fight: his den from the first man (BUILD55-U)
	var scene_key: String = den if den != "" and _pair_in(BOSS_DIR, den) else (county_scene(m) if place_key != "" and _pair_in(COUNTY_DIR, place_key) else stage_key(m))     # his den while he's out, when it's drawn; a County place's stage's own plate, else the place's (26 Oct, BUILD61-U); the stage's own plate, else the site's (BUILD55-U)
	if scene_key != _site_key:
		_site(scene_key)
	_zone_key = ZONE_KEYS[mini(int(m.get("signal", {}).get("zone", site["zone"])), ZONE_KEYS.size() - 1)]     # the signal's crew, the one the Radio names
	var ck: String = county_gang(m)
	if ck != "" and ["a", "b"].all(func(w): return ["stand", "fire", "down"].all(func(ps): return tex("gang_%s_%s_%s" % [ck, w, ps]) != null)):     # the whole crew drawn, not half (the review)
		_zone_key = ck                         # the County's own crew once drawn (26 Oct, tools/make_county_gangs_manifest.py), else the host's
	var gang: int = 0
	if int(m["remaining"]) > 0:
		gang = 1 if boss_on else mini(int(m["remaining"]), maxi(1, sim.contact(m["t"])))
	_on_you = mini(gang, SLOTS.size())
	_firing = _on_you > 0
	var sec = sim.equipped["Secondary"]
	_reloading = float(sim.mag_now("Primary")[2]) > 0.0 and (sec == null or not sim.has_rounds(sec))
	# what's on them, and on you: the chips' own thresholds (sim.dots_on_them, run.gd's "On you")
	var dots: Dictionary = m.get("dots", {})
	var mine: Dictionary = m.get("my_dots", {})
	var fighting_v: bool = int(m["remaining"]) > 0
	for el in ["fire", "poison", "bleed"]:
		_them_fx[el] = fighting_v and float(dots.get(el, 0.0)) > 0.5
		_you_fx[el] = float(mine.get(el, 0.0)) > 0.5
	for el in Data.MY_AILS:
		_you_fx[el] = float(m.get("my_ails", {}).get(el, 0.0)) > 0.0 and sim.my_ail(m, el) >= 0.05     # frost and shock on you (28 Oct)
	_them_fx["frost"] = fighting_v and float(m.get("chill_t", 0.0)) > 0.0
	_them_fx["shock"] = fighting_v and float(m.get("shock_t", 0.0)) > 0.0
	# a kill: the one in front goes down
	if int(m["kills"]) > _kills_seen:
		var ups: Array = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] in ["pop", "up"])
		for n in range(mini(int(m["kills"]) - _kills_seen, ups.size())):
			# the one you were hitting first (its bar ran out); any of the rest past it (Matt, 13 Oct: not the first every time)
			var pick: int = _target_k if _target_k in ups else ups[randi() % ups.size()]
			ups.erase(pick)
			_set_state(pick, "down")
			_figs[pick]["kick_t"] = 0.0
			_hold(STOP_KILL_S)
			_burst(_chest_of(pick), "physical", 44, 1.5)
			if pick == _target_k:
				_target_k = -1
		_kills_seen = int(m["kills"])
	# a hit on you: the jolt and the red, a hundredth of your HP or more
	_low_hp = sim.hp < sim.max_hp() / 3.0
	if _hp_seen >= 0.0 and sim.hp < _hp_seen - sim.max_hp() * 0.01:
		var hurt: float = (_hp_seen - sim.hp) / maxf(1.0, sim.max_hp())
		if hurt >= BIG_HURT:
			_jolt = JOLT_S                           # a big one: the frame jolts (27 Oct: not every scratch)
		_red_a = maxf(_red_a, clampf(0.35 + hurt * 6.0, 0.35, 1.0))     # the red as strong as the hit
		if sim.hp < _hp_seen - sim.max_hp() * 0.05 and _duck_t <= 0.0:
			if _duck_t <= 0.0 and _firing:
				ducked.emit()                         # only a duck you see (the review)
			_duck_t = randf_range(0.6, 1.0)          # a big one: down behind the wall
	_hp_seen = sim.hp
	# your gun's rate, for the recoil and the marker
	var gun = gun_in_hand(sim)
	_rof = maxf(0.5, minf(4.0, float(Items.base_of(gun).get("rof", 1.0)) * sim.pace())) if gun != null else 1.0
	var ht: Texture2D = hands_tex(gun)
	var melee: bool = ht != null and Items.is_melee(gun)
	_kind = _hands_kind(gun) if gun != null else ""
	if ht != _hands.texture or melee != _melee:
		_hands.texture = ht
		_melee = melee
		if ht != null:
			_hands.size = ht.get_size()
			_hs = hands_scale(ht)
			_hands.scale = Vector2(_hs, _hs)
			_hands_at = HANDS_CORNER - used_of(ht).end * _hs
			_mz = muzzle_of(ht, _kind, Items.slug(Items.art_name(str(gun["base"]))))
		_set_swing_parts(ht)
	_hands.visible = ht != null
	# a run event in the scene (1 Nov): the dogs in the gang's places while they're fought
	prop.set_event(sim.event_now(), float(m["elapsed"]))
	_dogs_on = m.has("dogs_home") and not bool(m["t"].get("crew", false))     # a rival crew (BUILD46-E) is drawn as the zone's gang
	# the search: the view pans along to the crates in the street, the next three (put by while an event's in the street)
	var searching: bool = int(m["remaining"]) <= 0 and m["cleared"]
	_pan_to = PAN if searching else 0.0
	var cs: Array = m.get("crates", [])
	var ci: int = int(m.get("crate_i", 0))
	for k in range(_crates.size()):
		var j: int = ci + k
		var c: TextureRect = _crates[k]
		c.visible = searching and j < cs.size() and not cs[j].get("passed", false) and not prop.holds_street()
		_shadows[k].visible = c.visible
		if c.visible:
			var pic: Array = CratesPanel.crate_texture(str(cs[j]["key"]), false)
			c.texture = pic[0]
			c.modulate = pic[1]
			var spot: Dictionary = CRATE_SPOTS[k]
			var s: float = spot["scale"]
			c.size = c.texture.get_size() if c.texture != null else Vector2(64, 64)
			c.scale = Vector2(s, s)
			c.set_meta("at", spot["foot"] - Vector2(c.size.x * 0.5, c.size.y * 0.95) * s)       # feet on the ground (where they stand at the full pan)
			var sh: TextureRect = _shadows[k]
			sh.scale = Vector2(s, s)
			sh.set_meta("at", spot["foot"] - Vector2(sh.size.x * 0.5, sh.size.y * 0.6) * s)
	# the glass over the one being opened, its ring the search so far (nothing over a crate passed by or once picked clean)
	var t: Dictionary = m["t"]
	_search_p = clampf(float(m.get("search", 0.0)) / maxf(0.01, sim.search_s(t)), 0.0, 1.0) if searching else 0.0
	_glass.visible = searching and _crates[0].visible and ci < cs.size() and not sim.crates_done(m)
	# the one just opened: the queue's step on (past any passed over) puts the last opened down, open
	if not is_same(_open_for, cs):
		_open_for = cs                           # a new search (or none): nothing just opened
		_open_ci = ci
		_open_left = 0.0
	elif ci > _open_ci:
		var j: int = ci - 1
		while j >= _open_ci and j >= 0 and cs[j].get("passed", false):
			j -= 1
		var was: int = _open_ci
		_open_ci = ci
		var fresh: bool = sim.elapsed - _open_seen <= OPEN_FRESH_S      # back from another room, the opening's old news (the review)
		if fresh and j >= maxi(0, was) and j < cs.size() and not cs[j].get("passed", false):
			_show_open(cs[j])
	_open_seen = sim.elapsed
	if not searching:
		_open_left = 0.0                         # a gang: it goes at once
	_open_c.visible = _open_left > 0.0
	_open_sh.visible = _open_c.visible
	_open_tag.visible = _open_c.visible
	_v66_show(sim, m)                            # (BUILD66-V) the shooter mechanics' events and state


## The crate just opened, set down open at OPEN_SPOT for OPEN_S.
func _show_open(q: Dictionary) -> void:
	var pic: Array = CratesPanel.crate_texture(str(q["key"]), true)
	_open_c.texture = pic[0]
	_open_c.modulate = pic[1]
	var s: float = OPEN_SPOT["scale"]
	_open_c.size = _open_c.texture.get_size() if _open_c.texture != null else Vector2(64, 64)
	_open_c.scale = Vector2(s, s)
	_open_c.set_meta("at", OPEN_SPOT["foot"] - Vector2(_open_c.size.x * 0.5, _open_c.size.y * 0.95) * s)
	_open_sh.scale = Vector2(s, s)
	_open_sh.set_meta("at", OPEN_SPOT["foot"] - Vector2(_open_sh.size.x * 0.5, _open_sh.size.y * 0.6) * s)
	var n: int = q.get("finds", []).size()
	_open_tag.text = "Opened · " + CratesPanel.finds_words(n)
	_open_tag.size.x = UI.text_width(_open_tag, _open_tag.text) + 16
	_open_tag.set_meta("at", Vector2(OPEN_SPOT["foot"].x - _open_tag.size.x * 0.5, OPEN_SPOT["foot"].y - _open_c.size.y * 0.95 * s - _open_tag.size.y - 2))
	_open = {"name": str(q["name"]), "key": str(q["key"]), "finds": n}
	_open_left = OPEN_S


## The crate just opened while it's up ({name, key, finds}), or {}: the search bar names it for its moment.
func opened() -> Dictionary:
	return _open if _open_left > 0.0 else {}


func _set_state(k: int, s: String) -> void:
	var f: Dictionary = _figs[k]
	f["state"] = s
	f["t"] = 0.0
	var r: TextureRect = f["rect"]
	r.visible = s != ""
	if s == "pop" or (s == "up" and not f.has("who")):
		f["who"] = "ab"[randi() % 2]           # one of the zone's two, as it comes up
	if s in ["pop", "up"]:
		f["boss"] = _boss_key                  # the head, if he's the one coming up
	r.texture = _fig_tex(f, "down" if s == "down" else "stand")
	r.modulate.a = 0.0 if s == "pop" else 1.0


func _process(dt: float) -> void:
	if not _shown():
		if placing and _placer != null:
			_placer.toggle()                     # off the run screen (a room, the title, a new camp): the tool lets go (the review)
		return                                   # off the run screen: nothing ticks (the review: a run ended mid-fight kept its flames going)
	if placing:
		_place_tick()
		return
	if _stop_t > 0.0 and dt > 0.0:
		var held: float = minf(dt, _stop_t)      # a solid hit: the frame holds a beat, the rest of the step goes on
		_stop_t -= held
		dt -= held
		_since_stop = 0.0
		if dt <= 0.0:
			return
	_since_stop += dt
	# the figures: as many up as are on you, popping in front first; each fires now and then while you're under fire
	var up := 0
	for f in _figs:
		if f["state"] in ["pop", "up"]:
			up += 1
	for k in range(SLOTS.size()):
		if up >= _on_you:
			break
		if _figs[k]["state"] == "":
			_set_state(k, "pop")
			up += 1
	for k in range(SLOTS.size()):
		var f: Dictionary = _figs[k]
		var slot: Dictionary = slot_of(k)
		var r: TextureRect = f["rect"]
		var fdt: float = dt * (FROST_SLOW if _them_fx.get("frost", false) and f["state"] in ["pop", "up"] else 1.0)
		f["t"] += fdt
		if f["state"] in ["pop", "up"] and str(f.get("boss", "")) != _boss_key:
			_set_state(k, "")                        # the head's out (or gone): the gang that was up steps back for him
			up -= 1
			_arcs[k].visible = false
			for el in f["fx"]:
				f["fx"][el].emitting = false
			continue
		if f["state"] in ["pop", "up"] and up > _on_you and not (k == _target_k and _on_you > 0):     # the one being hit stays (the review)
			_set_state(k, "")                        # the gang's thinned with no kill seen (a run ended, the way out)
			up -= 1
			_arcs[k].visible = false
			for el in f["fx"]:
				f["fx"][el].emitting = false
			continue
		var lift := 0.0
		match f["state"]:
			"pop":
				r.modulate.a = clampf(f["t"] / POP_S, 0.0, 1.0)
				if f["t"] >= POP_S:
					f["state"] = "up"
					r.modulate.a = 1.0
			"up":
				f["next_fire"] -= fdt
				if f["next_fire"] <= 0.0:
					f["fire_t"] = 0.25
					f["next_fire"] = randf_range(0.8, 2.2)
					they_fired.emit(k)
				if f["fire_t"] > 0.0:
					f["fire_t"] -= fdt
				r.texture = _fig_tex(f, "fire" if f["fire_t"] > 0.0 else "stand")
			"down":
				lift = -24.0 * clampf(f["t"] / DOWN_S, 0.0, 1.0)
				var thr: float = ease(clampf(f["t"] / (DOWN_S * 0.6), 0.0, 1.0), 0.4)     # thrown back as it drops
				f["kick_x"] = THROW_PX * thr * _away(k)
				f["kick_r"] = THROW_DEG * thr * _away(k)
				r.modulate.a = 1.0 - clampf((f["t"] - DOWN_S * 0.5) / (DOWN_S * 0.5), 0.0, 1.0)
				if f["t"] >= DOWN_S:
					_set_state(k, "")
		if r.texture != null:
			r.size = r.texture.get_size()
		r.scale = Vector2(slot["scale"], slot["scale"])
		var u: Rect2 = used_of(r.texture)                # the feet where the picture's drawn part ends, centred on what's drawn
		var anchor: Vector2 = Vector2(u.get_center().x, u.end.y) if u.size.y > 0.0 else Vector2(r.size.x * 0.5, r.size.y)
		if f["state"] in ["pop", "up"]:
			f["kick_x"] = 0.0
			f["kick_r"] = 0.0
			if float(f.get("kick_t", 0.0)) > 0.0:
				f["kick_t"] = maxf(0.0, float(f["kick_t"]) - dt)
				var kk: float = sin(PI * float(f["kick_t"]) / KICK_S) if float(f["kick_t"]) > 0.0 else 0.0     # out and back
				f["kick_x"] = KICK_PX * kk * _away(k)
				f["kick_r"] = KICK_DEG * kk * _away(k)
		# the tilt about the feet, worked by hand (28 Oct: a pivot at the feet had Godot scale about it too, and every
		# figure smaller than full size stood off its spot); no tilt, the feet exactly where they were
		var th: float = deg_to_rad(float(f.get("kick_r", 0.0)))
		r.pivot_offset = Vector2.ZERO
		r.rotation = th
		r.position = slot["foot"] - (anchor * slot["scale"]).rotated(th) + Vector2(_pan * -0.6 + float(f.get("kick_x", 0.0)), lift - DUCK_SCENE * _duck)
		var lit: float = slot["lit"]
		if float(f.get("hit_t", 0.0)) > 0.0:
			f["hit_t"] = float(f["hit_t"]) - dt
			lit = 2.2                                  # a hit: the figure flashes white
		var tint := Color(lit, lit, lit, 1.0)
		var on_fig: bool = f["state"] in ["pop", "up"]
		for el in FX_TINT:
			if on_fig and _them_fx.get(el, false):
				tint = Color(tint.r * FX_TINT[el].r, tint.g * FX_TINT[el].g, tint.b * FX_TINT[el].b, 1.0)
		if on_fig and _them_fx.get("fire", false):
			var fl: float = 1.0 + 0.12 * sin(_fx_t * 23.0 + k * 2.0)       # the flames' flicker on them
			tint = Color(tint.r * fl, tint.g * fl, tint.b * fl, 1.0)
		# shock: now and then a flash, a twitch and an arc across them
		var arc: Line2D = _arcs[k]
		arc.visible = false
		if on_fig and _them_fx.get("shock", false):
			f["shock_next"] = float(f["shock_next"]) - dt
			if f["shock_next"] <= 0.0:
				f["shock_t"] = 0.07
				f["shock_next"] = randf_range(0.15, 0.5)
			if float(f["shock_t"]) > 0.0:
				f["shock_t"] = float(f["shock_t"]) - dt
				tint = Color(2.0, 2.0, 1.6, 1.0)
				r.position.x += randf_range(-3.0, 3.0)
				_arc(arc, r)
		r.self_modulate = tint
		if _dogs_on:
			r.self_modulate.a = 0.0                    # the dogs are drawn in its place (event_prop.gd)
		# the particles: on the figure while it's up, off when it's down or gone
		var sz: Vector2 = r.size * r.scale
		for el in f["fx"]:
			var p: CPUParticles2D = f["fx"][el]
			var want: bool = on_fig and _them_fx.get(el, false)
			if p.emitting != want:
				p.emitting = want
			p.modulate.a = r.modulate.a               # coming in, its flames come in with it
			if want:
				var s: float = slot_of(k)["scale"]
				p.scale = Vector2(s, s) * 1.6
				p.emission_rect_extents = Vector2(sz.x * 0.28, sz.y * (0.3 if el == "fire" else 0.35)) / p.scale
				p.position = r.position + Vector2(sz.x * 0.5, sz.y * (0.55 if el == "fire" else 0.45)).rotated(r.rotation)     # the body's tilt (the kick, a throw): the flames on it, not where it stood
				p.rotation = r.rotation
	_lay_bars()
	_v66_lay(dt)                                 # (BUILD66-V) the pops, the pills, the plate, the jam
	# ducking: now and then under fire, and on a big hit - the wall comes up, the gun goes down, no shots
	if _firing:
		_duck_next -= dt
		if _duck_next <= 0.0 and _duck_t <= 0.0:
			_duck_t = randf_range(0.7, 1.3)
			ducked.emit()
			_duck_next = randf_range(3.5, 6.5)
	if _duck_t > 0.0:
		_duck_t -= dt
	var down: bool = _duck_t > 0.0 and _firing
	_duck = move_toward(_duck, 1.0 if down else 0.0, dt * 6.0)
	# the pan, the plate and the cover sliding at their depths
	_pan = move_toward(_pan, _pan_to, dt * 60.0)
	var jolt := Vector2.ZERO
	if _jolt > 0.0:
		_jolt -= dt
		jolt = Vector2(randf_range(-4.0, 4.0), randf_range(-3.0, 3.0))
	_plate.position = PLATE_AT + Vector2(-_pan, -DUCK_SCENE * _duck) + jolt
	_cover.position = Vector2(COVER_X - _pan * 1.4, _cover_y - DUCK_COVER * _duck) + jolt * 1.5
	# the crates ride the street as it pans in (the review: they stood still while the plate slid under them)
	for k in range(_crates.size()):
		for n in [_crates[k], _shadows[k]]:
			if n.has_meta("at"):
				n.position = n.get_meta("at") + Vector2(PAN - _pan, 0)
	# the one just opened rides the pan with them, fading its last moment
	if _open_left > 0.0:
		_open_left = maxf(0.0, _open_left - dt)
		var a: float = clampf(_open_left / OPEN_FADE_S, 0.0, 1.0)
		for n in [_open_c, _open_sh, _open_tag]:
			n.visible = _open_left > 0.0
			if n.has_meta("at"):
				n.position = n.get_meta("at") + Vector2(PAN - _pan, 0)
			n.modulate.a = a
	# the glass: over the crate being opened, bobbing a little, circling as it looks
	if _glass.visible:
		var c0: TextureRect = _crates[0]
		var top: Vector2 = c0.position + Vector2(c0.size.x * c0.scale.x * 0.5, 0)
		_glass.position = top + Vector2(10.0 + 6.0 * cos(_fx_t * 2.2), -30.0 + 4.0 * sin(_fx_t * 3.1)) - Vector2(Glass.R, Glass.R)
		_glass.p = _search_p
		_glass.queue_redraw()
	# your gun: a kick back at its rate while there's someone to shoot, the marker on the one you're hitting
	_shot_t -= dt
	if _firing and not _reloading and _jam66_left <= 0.0 and _shot_t <= 0.0 and _duck < 0.2 and _swing < 0.0:     # (BUILD66-V) jammed: a beat with no shots
		_shot_t = 1.0 / _rof
		gun_fired.emit()
		var ups: Array = range(SLOTS.size()).filter(func(k_in): return _figs[k_in]["state"] == "up")
		var k: int = _target_k if _target_k in ups else (ups[randi() % ups.size()] if not ups.is_empty() else -1)     # the one whose bar is going down
		if _target_k >= 0 and _figs[_target_k]["state"] == "pop":
			k = -1                                   # still coming in: the kick, the hit lands once it's up (the review)
		if _melee:
			_swing = 0.0                             # the hit lands on the chop (_swing_step)
			_swing_len = clampf(0.75 / _rof, 0.24, 0.42)
			_swing_k = k
		else:
			_recoil = 0.08
			fire_flash()
			if k >= 0:
				_land_hit(k)
	_swing_step(dt)
	_recoil = maxf(0.0, _recoil - dt)
	_hands.position = _hands_at + Vector2(10, 12) * (_recoil / 0.08) + Vector2(0, DUCK_HANDS * _duck) + jolt + _swing_off * _hs
	_flash_step(dt)
	_marker_t -= dt
	_marker.visible = _marker_t > 0.0
	_fx_t += dt
	for el in _edges:
		var e: TextureRect = _edges[el]
		var target: float = (0.55 + 0.25 * sin(_fx_t * 3.0 + float(FX_ELEMENTS.find(el)))) if _you_fx.get(el, false) else 0.0
		e.modulate.a = move_toward(e.modulate.a, target, dt * 2.5)
	_red_a = maxf(LOW_RED if _low_hp and _firing else 0.0, _red_a - dt / RED_S)     # held under a third of your HP
	_red.modulate.a = _red_a


## Their HP for the bars (run.gd, each look and each number out): `hp` the one you're hitting's as shown (the hits not
## yet out as numbers held on it), `of` a whole one's, `dots` {type: HP still to tick off}, `boss` the head's.
func set_bars(hp: float, of: float, dots: Dictionary, boss: bool) -> void:
	_bar_info = {"hp": hp, "of": maxf(1.0, of), "dots": dots, "boss": boss, "shield": float(_bar_info.get("shield", 0.0))}


## The Lineman's shield (24 Oct, the endgame chase): what's left of it, 0 to 1, drawn over the head's bar.
func set_shield(share: float) -> void:
	_bar_info["shield"] = clampf(share, 0.0, 1.0)


## The bars over each of them, where they stand this frame: the one you're hitting picked if it went (any of them up),
## its bar its HP, the others full; none on one falling or gone; in the frame, over the figure's head.
func _lay_bars() -> void:
	var s: float = scale.x if scale.x > 0.0 else 1.0
	_bars_layer.scale = Vector2(1.0 / s, 1.0 / s)
	if _target_k < 0 or not (_figs[_target_k]["state"] in ["pop", "up"]):
		var ups: Array = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] == "up")
		if ups.is_empty():
			ups = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] == "pop")
		_target_k = ups[randi() % ups.size()] if not ups.is_empty() else -1
	_v66_pick()                                  # (BUILD66-V) which of them is the hard man, before the bars
	_hp_tag.visible = false
	for k in range(_figs.size()):
		var f: Dictionary = _figs[k]
		var fb: FigBar = f["bar"]
		var r: TextureRect = f["rect"]
		fb.visible = _firing and f["state"] in ["pop", "up"] and r.texture != null
		if not fb.visible:
			continue
		var hit: bool = k == _target_k
		var head: bool = bool(_bar_info["boss"]) and str(f.get("boss", "")) != ""
		var hard66: bool = k == _hard66_k            # (BUILD66-V) the hard man's bar: the head's size, gold-edged
		fb.set_hard(hard66)
		var u: Rect2 = used_of(r.texture)
		if u.size.y <= 0.0:
			u = Rect2(Vector2.ZERO, r.size)
		var top: Vector2 = r.position + Vector2(u.get_center().x, u.position.y) * r.scale.x     # the head of the figure, in the frame
		var w: float = BAR_W_HEAD if (head or hard66) else clampf(u.size.x * r.scale.x * s * 0.75, 48.0, 120.0)
		var h: float = BAR_H_HEAD if (head or hard66) else (BAR_H_HIT if hit else BAR_H)
		var at := Vector2(top.x * s - w * 0.5, top.y * s - h - 8.0)
		var tag_h: float = 24.0 if hit else 0.0
		at.x = clampf(at.x, 6.0, W * s - w - 6.0)
		at.y = clampf(at.y, 6.0 + tag_h, H * s - h - 6.0)
		fb.position = at
		fb.size = Vector2(w, h)
		fb.modulate.a = r.modulate.a
		var of: float = float(_bar_info["of"])
		var dots := {}
		var ticking := 0.0
		if hit:
			for ty in _bar_info["dots"]:
				dots[ty] = maxf(0.0, float(_bar_info["dots"][ty])) / of
				ticking += maxf(0.0, float(_bar_info["dots"][ty]))
		fb.look(_v66_share(k, clampf(float(_bar_info["hp"]) / of, 0.0, 1.0) if hit else 1.0), dots, float(_bar_info.get("shield", 0.0)) if (hit and head) else 0.0, hit,
			hit and float(_bar_info["hp"]) > 0.0 and ticking >= float(_bar_info["hp"]))     # the skull (11 Oct): the dots will finish them
		if hit:
			var tag: String = _v66_tag(k, "%d / %d" % [ceili(float(_bar_info["hp"])), int(round(of))])     # (BUILD66-V) the hard man's own
			if tag != _hp_tag.text:
				_hp_tag.text = tag
				_hp_tag.size.x = ceilf(UI.text_width(_hp_tag, _hp_tag.text)) + 8.0
			_hp_tag.position = Vector2(clampf(at.x + w * 0.5 - _hp_tag.size.x * 0.5, 4.0, W * s - _hp_tag.size.x - 4.0), at.y - tag_h)
			_hp_tag.modulate.a = r.modulate.a
			_hp_tag.visible = true


## For the tests: each bar up, in the frame's own space ({k, rect, share, hit, words}), and the HP's words.
func bars() -> Array:
	var out := []
	var s: float = scale.x if scale.x > 0.0 else 1.0
	for k in range(_figs.size()):
		var fb: FigBar = _figs[k]["bar"]
		if fb.visible:
			out.append({"k": k, "rect": Rect2(fb.position / s, fb.size / s), "share": fb.share, "hit": fb.hit, "state": _figs[k]["state"]})
	return out


func hp_words() -> Label:
	return _hp_tag


## One of them's bar: the track, their HP in the bad tone, the dots' shares at its end, amber round the one you're hitting.
class FigBar extends Control:
	var share := 1.0
	var shield := 0.0
	var dots := {}
	var hit := false
	var finish := false
	var hard := false                # (BUILD66-V) the hard man's: gold-edged

	var redraws := 0                 # for the tests: redraws asked for (BUILD43: a bar standing still asks none)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## What the bar shows; drawn again only when it's moved (BUILD43, perf43: three bars redrawn every frame).
	func look(p_share: float, p_dots: Dictionary, p_shield: float, p_hit: bool, p_finish: bool) -> void:
		if p_share == share and p_dots == dots and p_shield == shield and p_hit == hit and p_finish == finish:
			return
		share = p_share
		dots = p_dots
		shield = p_shield
		hit = p_hit
		finish = p_finish
		redraws += 1
		queue_redraw()

	## (BUILD66-V) The hard man's bar or not: drawn again only on the change.
	func set_hard(on: bool) -> void:
		if on != hard:
			hard = on
			redraws += 1
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(UI.box(Color(Pal.BG, 0.88), 3, 3 if hard else (2 if hit else 1), GOLD66 if hard else (Pal.ACCENT if hit else Color(Pal.TEXT_3, 0.8))), r.grow(3.0 if hard else 2.0))     # (BUILD66-V) gold round the hard man's
		var fw: float = roundf(size.x * share)
		draw_rect(Rect2(0, 0, fw, size.y), Pal.tone_color("bad"))
		var right: float = fw
		for ty in Data.TYPES:
			var a: float = float(dots.get(ty, 0.0))
			if a <= 0.0:
				continue
			var sw: float = minf(right, floorf(size.x * a))
			if sw >= 1.0:
				draw_rect(Rect2(right - sw, 0, sw, size.y), Pal.tone_color(ty) if ty != "physical" else Pal.TEXT_3)
				right -= sw
		if shield > 0.0:
			draw_rect(Rect2(0, -8.0, roundf(size.x * shield), 5.0), Pal.tone_color("frost"))     # the Lineman's shield, a strip over the bar: its share of its full
		if finish:
			var sk: float = size.y + 6.0
			draw_texture_rect(NodeGlyphs.texture("skull"), Rect2(-sk - 4.0, (size.y - sk) * 0.5, sk, sk), false, Color(Pal.TEXT, 0.95))


## A shot's flash at the gun's muzzle: its kind's shape for its moment (none on a blade, a hammer or no picture).
func fire_flash() -> void:
	if _melee or not _hands.visible or _mz.is_empty():
		_flash.visible = false                   # a stand-in picture's muzzle is somewhere else (the review)
		return
	var mz: Dictionary = _mz
	_flash.kind = mz
	_flash.left = float(mz["s"])
	_flash.seed_v = randi()
	_flash.visible = true
	_flash.fresh = true
	_flash.position = muzzle_point()
	_flash.queue_redraw()


func _flash_step(dt: float) -> void:
	if not _flash.visible:
		return
	if _flash.fresh:
		_flash.fresh = false                     # drawn at least the frame it fired, however slow the frames (the review)
	else:
		_flash.left -= dt
	if _flash.left <= 0.0 or _melee or not _hands.visible:
		_flash.visible = false
		return
	_flash.position = muzzle_point()
	_flash.queue_redraw()


## Where the gun's muzzle is in the frame this moment (the hands' picture, its scale, the kick), or the hands' corner.
func muzzle_point() -> Vector2:
	if _mz.is_empty():
		return _hands.position
	return _hands.position + (_mz["at"] as Vector2) * _hs


## The gun in your hands (17 Oct, the kit: every gun its own): the primary while it fires - a blade, a burner, or a
## gun with rounds - else the secondary, as the fight does (the sim's dps: the secondary at full behind a dry primary).
static func gun_in_hand(sim) -> Variant:
	var p = sim.equipped["Primary"]
	var s = sim.equipped["Secondary"]
	if p != null and (s == null or sim.has_rounds(p)):
		return p
	return s if s != null else p


## A gun's hands: its base's own picture (art/fight/hands/<base>.png), else its kind's, else the revolver's - but never
## the revolver for a blade or a hammer.
static func hands_tex(gun) -> Texture2D:
	if gun == null:
		return null
	var own: Texture2D = tex("hands/" + Items.slug(Items.art_name(str(gun["base"]))))
	if own != null:
		return own
	var ht: Texture2D = tex_of(["hands_" + _hands_kind(gun), "hands_revolver"])
	if ht != null and Items.is_melee(gun) and tex("hands_" + _hands_kind(gun)) == null:
		return null                                # no revolver for a hammer: nothing till its hands are drawn
	return ht


## A hands picture's scale: drawn HANDS_VIEW_W wide in the frame whatever its pixels (the kind's 256 at 0.8, the kit's 280).
static func hands_scale(t: Texture2D) -> float:
	return HANDS_VIEW_W / maxf(1.0, t.get_size().x) if t != null else HANDS_SCALE


## A picture's flash: its kind's shape (MUZZLE), at the kind's read-off point for the kind's own picture, else at the
## kit picture's muzzle - MUZZLE_AT's where one's been read off by eye, else found in its pixels (find_muzzle); {} for a
## blade, a hammer or a kind without a flash.
## The kit's hands (17 Oct) come up from the frame's foot with the gun raised toward the top left, steeper than the
## kind's pictures; a muzzle the finder misses is put right here, [at, dir] in the picture's pixels.
const MUZZLE_AT := {
	"police_carbine": [Vector2(117, 84), Vector2(-1, -0.5)],     # the finder takes its sight's top; the barrel's end is lower left
	"security_guard_s_carbine": [Vector2(130, 101), Vector2(-1, -0.3)],     # the barrel's end past the front sight (6 Nov, the reroll; was 77, 92)
	"army_smg": [Vector2(77, 79), Vector2(-1, -0.2)],     # the suppressor's end
	"riot_squad_s_smg": [Vector2(131, 84), Vector2(-1, -0.35)],
	"close_protection_smg": [Vector2(103, 84), Vector2(-1, -0.15)],     # the suppressor's end, not the receiver's top (17 Oct, the reroll)
	# BUILD48 item 11 (4 Nov): the SMGs the top-left rule still misses, read off the contact sheet by eye
	"courier_s_smg": [Vector2(127, 78), Vector2(-1, -0.3)],     # the barrel's end; its topmost is the ring sight, its top-left the left glove
	"consular_pdw": [Vector2(112, 76), Vector2(-1, -0.45)],     # the rail's front; the top-left rule finds the foregrip's glove
	"broomhandle_pistol": [Vector2(140, 57), Vector2(0, -1)],     # held straight up: the muzzle is its top; the top-left rule finds the glove
	# BUILD51-C (5 Nov, the flash contact sheet, docs/art/smg_flash_sheet.png): the one gun the sheet showed off its muzzle
	"castle_guard_rifle": [Vector2(126, 70), Vector2(-1, -0.5)],     # the flash hider's end; the top-left rule found the left sleeve (90, 128)
	# 6 Nov: the rerolled and new kit pictures (art.done), each read off by eye at the muzzle's middle - the finder lands
	# on a corner of it, or on the bow's arm
	"regimental_rifle": [Vector2(104, 80), Vector2(-1, -0.55)],     # the flash hider's end
	"three_round_pistol": [Vector2(93, 63), Vector2(-1, -0.3)],     # the suppressor's end
	"select_fire_pistol": [Vector2(101, 46), Vector2(-1, -0.4)],     # the barrel's end
	"humane_killer": [Vector2(93, 50), Vector2(-1, -0.45)],     # the bolt tube's face
	"hand_me_down_nail_gun": [Vector2(73, 59), Vector2(-1, -0.1)],     # the nose's tip
	"compound_bow": [Vector2(87, 94), Vector2(-1, -0.34)],     # the arrow's tip; the top-left rule found the left arm (60, 129)
	# 7 Nov: the County's two new guns in hand (the 18:24 art.done), read off by eye at the muzzle's middle
	"bullion_carbine": [Vector2(128, 98), Vector2(-1, -0.2)],     # the barrel's end past the front sight; the top-left rule finds the front sight's ring
	"sidelock_shotgun": [Vector2(71, 72), Vector2(-1, -0.4)],     # the barrels' ends, up and to the left
}
static var _muzzles := {}
static func muzzle_of(t: Texture2D, kind: String, slug := "") -> Dictionary:
	if t == null or not MUZZLE.has(kind):
		return {}
	if t == tex("hands_" + kind):
		return MUZZLE[kind]
	var key: int = t.get_instance_id()
	if _muzzles.has(key):
		return _muzzles[key]
	var mz: Dictionary = (MUZZLE[kind] as Dictionary).duplicate()
	if MUZZLE_AT.has(slug):
		mz["at"] = MUZZLE_AT[slug][0]
		mz["dir"] = (MUZZLE_AT[slug][1] as Vector2).normalized()
	else:
		var found: Array = find_muzzle(t, kind)
		mz["at"] = found[0]
		mz["dir"] = found[1]
	_muzzles[key] = mz
	return mz


## A kit picture's muzzle and the way it fires, in its pixels: in its upper part (the arms come up from the foot), a
## pistol's topmost drawn pixel, else - a long gun's or an SMG's - the furthest toward the top left; the way it points
## from the gun's middle (the upper part's drawn pixels averaged) out through the muzzle. [at, dir]. (4 Nov, BUILD48
## item 11, Matt: "the flash comes out of the sights not the muzzle": on the kit's hands the gun's raised to the top
## left, so an SMG's topmost pixel was its rear sight; it takes the long guns' rule now.)
static func find_muzzle(t: Texture2D, kind: String) -> Array:
	var img := t.get_image()
	if img == null:
		return [Vector2.ZERO, Vector2(-1, -0.4).normalized()]
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var w: int = img.get_width()
	var h: int = img.get_height()
	var probe: Vector2 = Vector2(0, -1) if kind == "pistol" else Vector2(-1, -0.35).normalized()
	var best := -INF
	var at := Vector2.ZERO
	var sum := Vector2.ZERO
	var n := 0
	for y in range(int(h * 0.62)):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.5:
				var q := Vector2(x, y)
				sum += q
				n += 1
				var d: float = q.dot(probe)
				if d > best:
					best = d
					at = q
	if n == 0:
		return [Vector2.ZERO, probe]
	var mid: Vector2 = sum / n
	var dir: Vector2 = (at - mid).normalized() if at.distance_to(mid) > 4.0 else probe
	# a pixel in from the very edge, still on the gun
	var back: Vector2 = at - dir
	if back.x >= 0 and back.y >= 0 and back.x < w and back.y < h and img.get_pixelv(Vector2i(back)).a > 0.5:
		at = back
	return [at, dir]


## For the tests: the flash up, where, and the kind it's drawn as.
func flash_state() -> Dictionary:
	return {"up": _flash.visible, "at": _flash.position, "kind": _kind}


## The flash: a hot core and a cone of fire along the barrel (two for the double-barrel), or a spark's few lines.
class Flash extends Control:
	var kind := {}
	var left := 0.0
	var seed_v := 0
	var fresh := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _draw() -> void:
		if kind.is_empty():
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_v
		var d: Vector2 = Vector2(kind["dir"]).normalized()
		var n := Vector2(-d.y, d.x)
		var ln: float = float(kind["len"]) * rng.randf_range(0.85, 1.15)
		var wd: float = float(kind["wide"])
		if kind.get("spark", false):
			for i in range(6):
				var a: float = d.angle() + rng.randf_range(-1.1, 1.1)
				var l: float = ln * rng.randf_range(0.6, 1.4)
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * l, Color(1.0, 0.85, 0.45, 0.95), 1.5, true)
			draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.95, 0.8, 0.9))
			return
		var barrels: int = int(kind.get("barrels", 1))
		for b in range(barrels):
			var o: Vector2 = n * (float(b) - (barrels - 1) * 0.5) * wd * 0.45
			var outer := PackedVector2Array([o + n * wd * 0.5, o + d * ln * 0.55 + n * wd * 0.6, o + d * ln, o + d * ln * 0.55 - n * wd * 0.6, o - n * wd * 0.5])
			draw_colored_polygon(outer, Color(1.0, 0.55, 0.15, 0.75))
			var core := PackedVector2Array([o + n * wd * 0.25, o + d * ln * 0.6, o - n * wd * 0.25])
			draw_colored_polygon(core, Color(1.0, 0.92, 0.6, 0.95))
		draw_circle(Vector2.ZERO, wd * 0.45, Color(1.0, 0.97, 0.85, 0.9))


## Which way figure k is knocked: away from the frame's middle.
func _away(k: int) -> float:
	return 1.0 if float(slot_of(k)["foot"].x) >= W * 0.5 else -1.0


## A figure's chest in the frame, for a kill's burst.
func _chest_of(k: int) -> Vector2:
	var r: TextureRect = _figs[k]["rect"]
	var u: Rect2 = used_of(r.texture) if r.texture != null else Rect2()
	if u.size.y <= 0.0:
		u = Rect2(Vector2.ZERO, r.size)
	return r.position + Vector2(u.get_center().x, u.position.y + u.size.y * 0.3) * r.scale.x


## The shot's impact, once its numbers are out (run.gd's _release_hits): `share` of the figure's HP it took. A solid
## one (a twentieth) holds the frame, knocks the figure back, sprays by `ty` and knocks the chunk off its bar.
func impact(ty: String, share: float) -> void:
	if _last_hit.is_empty():
		return
	var k: int = int(_last_hit["k"])
	var at: Vector2 = _last_hit["at"]
	_last_hit = {}
	var solid: bool = share >= 0.05
	_burst(at, ty, 26 if solid else 10, 1.0 if solid else 0.6)
	if not solid or k < 0 or k >= _figs.size() or not (_figs[k]["state"] in ["pop", "up"]):
		return
	_hold(STOP_S)
	_figs[k]["kick_t"] = KICK_S
	var fb: Control = _figs[k]["bar"]
	if fb.visible and k == _target_k:
		_chunk(fb, clampf(share, 0.0, 1.0))     # the bar that shows its HP: the one you're hitting (the review)
	impacts += 1


var impacts := 0                           # solid hits landed (for the tests)


## The frame held `s`, unless a hold ended under STOP_GAP ago (or one's on).
func _hold(s: float) -> void:
	if _stop_t > 0.0 or _since_stop >= STOP_GAP:
		_stop_t = maxf(_stop_t, s)
var bursts := 0                            # sprays made (for the tests)


## A spray from a hit: blood, embers, frost, a green spit or sparks, away from you.
func _burst(at: Vector2, ty: String, n: int, size_k: float) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = maxi(1, n)
	p.lifetime = 0.45
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 60.0 * size_k
	p.initial_velocity_max = 170.0 * size_k
	p.gravity = Vector2(0, 420)
	p.scale_amount_min = 2.0 * size_k
	p.scale_amount_max = 4.5 * size_k
	var cols: Array = SPRAY.get(ty, SPRAY["physical"])
	var g := Gradient.new()
	g.set_color(0, cols[0])
	g.set_color(1, Color(cols[1], 0.0))
	p.color_ramp = g
	p.z_index = 3
	add_child(p)
	p.emitting = true
	bursts += 1
	if is_inside_tree():
		get_tree().create_timer(p.lifetime + 0.2).timeout.connect(p.queue_free)
	else:
		p.queue_free()


## The chunk a solid hit knocks off a bar: it flies off the bar's end and fades.
func _chunk(fb: Control, share: float) -> void:
	var c := ColorRect.new()
	c.color = Pal.BAD
	var w: float = clampf(fb.size.x * share, 4.0, 40.0)
	c.size = Vector2(w, fb.size.y)
	c.position = fb.position + Vector2(fb.size.x * clampf(float(_bar_info.get("hp", 0.0)) / maxf(1.0, float(_bar_info.get("of", 1.0))), 0.0, 1.0), 0.0)
	c.pivot_offset = c.size * 0.5
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars_layer.add_child(c)
	if not is_inside_tree():
		c.queue_free()
		return
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "position", c.position + Vector2(22.0, -26.0), 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "rotation", deg_to_rad(40.0), 0.45)
	tw.tween_property(c, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(c.queue_free)


## A hit on figure k: the marker on them, their flash, and the number's cue (run.gd's _on_view_shot).
func _land_hit(k: int) -> void:
	var r: TextureRect = _figs[k]["rect"]
	var u: Rect2 = used_of(r.texture)
	if u.size.y <= 0.0:
		u = Rect2(Vector2.ZERO, r.size)
	var hit: Vector2 = r.position + Vector2(u.get_center().x, u.position.y + u.size.y * randf_range(0.15, 0.45)) * r.scale.x
	_marker.position = hit - Vector2(12, 12)
	_marker_t = 0.12
	_figs[k]["hit_t"] = FLASH_S
	_last_hit = {"k": k, "at": hit}
	shot_fired.emit(hit)


## A swing's frame: wind up, chop, settle; the hit on the chop - on the one it was at, or whoever's up if they've gone.
func _swing_step(dt: float) -> void:
	var arm: Control = _hand_r
	for i in range(_trail.size() - 1, -1, -1):
		_trail[i][1] += dt
		if _trail[i][1] > STREAK_S:
			_trail.remove_at(i)
	if _swing < 0.0:
		_streak.queue_redraw()
		return
	var p0: float = _swing / _swing_len
	_swing += dt
	var p: float = _swing / _swing_len
	if p0 < SWING_CONTACT and p >= SWING_CONTACT and _duck < 0.2:     # gone down behind the wall mid-swing: no hit (the review); it's held for the next
		var k: int = _swing_k
		if k < 0 or _figs[k]["state"] != "up":
			var ups: Array = range(SLOTS.size()).filter(func(i): return _figs[i]["state"] == "up")
			k = _target_k if _target_k in ups else (ups[0] if not ups.is_empty() else -1)
		if k >= 0:
			_land_hit(k)
		_jolt = maxf(_jolt, 0.05)                 # the knock of it
	var ang := 0.0
	if p < SWING_UP:
		var e: float = ease(p / SWING_UP, 0.5)
		ang = SWING_BACK * e
		_swing_off = SWING_LIFT * e
	elif p < SWING_CONTACT:
		var e: float = ease((p - SWING_UP) / (SWING_CONTACT - SWING_UP), 2.2)
		ang = lerpf(SWING_BACK, SWING_FWD, e)
		_swing_off = SWING_LIFT.lerp(SWING_LUNGE, e)
	elif p < 1.0:
		var e: float = ease((p - SWING_CONTACT) / (1.0 - SWING_CONTACT), -1.6)
		ang = lerpf(SWING_FWD, 0.0, e)
		_swing_off = SWING_LUNGE.lerp(Vector2.ZERO, e)
	else:
		_swing = -1.0
		_swing_off = Vector2.ZERO
	arm.rotation = ang
	if p >= SWING_UP * 0.8 and p <= SWING_CONTACT + 0.12:
		_trail.append([tip_point(), 0.0])
	_streak.queue_redraw()


## The weapon's tip in the frame's space, where it is this frame.
func tip_point() -> Vector2:
	var sp: Dictionary = _split_of(_hands.texture)
	return _hands.get_transform() * (_hand_r.get_transform() * (sp["tip"] - Vector2(sp["x"], 0)))


## A melee picture in two where a clean column parts the off hand from the weapon's (fewer than 1 in 50 of its rows
## drawn on), the arm swinging round its forearm; with no clean column the whole picture swings, as the one part. The
## pivot is the part's, never the hands' own: a pivot on the scaled hands moved them off their corner (Matt, 14 Oct).
func _set_swing_parts(t: Texture2D) -> void:
	_swing = -1.0
	_swing_off = Vector2.ZERO
	_trail.clear()
	_hands.rotation = 0.0
	_hands.pivot_offset = Vector2.ZERO
	_hand_r.rotation = 0.0
	var parts := false
	var split := false
	if _melee and t != null:
		var sp: Dictionary = _split_of(t)
		parts = true
		split = sp["x"] > 0
		var w: float = t.get_size().x
		var h: float = t.get_size().y
		if split:
			var al := AtlasTexture.new()
			al.atlas = t
			al.region = Rect2(0, 0, sp["x"], h)
			_hand_l.texture = al
			_hand_l.size = al.region.size
			_hand_l.position = Vector2.ZERO
		var ar := AtlasTexture.new()
		ar.atlas = t
		ar.region = Rect2(sp["x"], 0, w - sp["x"], h)
		_hand_r.texture = ar
		_hand_r.size = ar.region.size
		_hand_r.position = Vector2(sp["x"], 0)
		_hand_r.pivot_offset = sp["pivot"] - Vector2(sp["x"], 0)
	_hand_l.visible = split
	_hand_r.visible = parts
	_hands.self_modulate.a = 0.0 if parts else 1.0    # its parts draw it


static func _split_of(t: Texture2D) -> Dictionary:
	if t == null:
		return {"x": 0, "pivot": Vector2.ZERO, "tip": Vector2.ZERO}
	var key: int = t.get_instance_id()
	if _splits.has(key):
		return _splits[key]
	var w: int = int(t.get_size().x)
	var h: int = int(t.get_size().y)
	var out := {"x": 0, "pivot": Vector2(w * 0.92, h * 1.02), "tip": Vector2(w * 0.7, 0)}
	var img := t.get_image()
	if img != null:
		if img.is_compressed():
			img = img.duplicate()
			img.decompress()
		var best := -1
		var best_n := h
		for x in range(int(w * 0.4), int(w * 0.75)):
			var n := 0
			for y in range(0, h, 2):
				if img.get_pixel(x, y).a > 0.1:
					n += 1
			if n < best_n:
				best_n = n
				best = x
		@warning_ignore("integer_division")
		if best > 0 and best_n * 2 <= h / 50:
			out["x"] = best
		# the tip: the weapon's highest drawn pixel right of the split
		for y in range(h):
			var found := false
			for x in range(maxi(out["x"], int(w * 0.4)), w):
				if img.get_pixel(x, y).a > 0.3:
					out["tip"] = Vector2(x, y)
					found = true
					break
			if found:
				break
	_splits[key] = out
	return out


## The head's streak through the chop: a fading, thinning line along the trail.
class Streak extends Control:
	var view
	func _draw() -> void:
		var row: Array = view._trail
		for i in range(1, row.size()):
			var a: float = 1.0 - float(row[i][1]) / view.STREAK_S
			draw_line(row[i - 1][0], row[i][0], Color(1, 1, 1, 0.45 * a), lerpf(2.0, 12.0, a), true)


## Where a hit of yours shows its number, in the frame's space: on one that's up, about its chest; with nobody up,
## the street's middle (13 Oct, Matt: the numbers off the chips, on the one you're hitting).
func hit_spot() -> Vector2:
	var ups: Array = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] in ["pop", "up"])
	if ups.is_empty():
		return Vector2(randf_range(300.0, 500.0), randf_range(130.0, 160.0))
	var r: TextureRect = _figs[_target_k if _target_k in ups else ups[randi() % ups.size()]]["rect"]     # off the one being hit (its bar)
	var sz: Vector2 = r.size * r.scale
	return r.position + Vector2(sz.x * 0.5 + randf_range(-12.0, 12.0), sz.y * randf_range(0.3, 0.55))


## Showing all the way up: this and every control it sits in visible (in the tree or not - the smoke's shell isn't).
func _shown() -> bool:
	var n: Node = self
	while n is CanvasItem:
		if not (n as CanvasItem).visible:
			return false
		n = n.get_parent()
	return true


## The hands for the gun in hand: its type (a garage rifle by its rounds), a blade that bleeds by its edge.
static func _hands_kind(gun) -> String:
	if gun == null:
		return ""
	if Items.is_melee(gun):
		return "blade" if float(Items.base_of(gun).get("conv_bleed_pct", 0)) >= 25.0 else "melee"
	var kind: String = str(Items.base_of(gun).get("type", "improvised"))
	if kind == "improvised" and Items.ammo_type(gun) not in ["", "improvised", "none"]:
		kind = Items.ammo_type(gun)
	return kind if kind in ["pistol", "shotgun", "rifle", "smg", "improvised"] else "improvised"


## Shock's arc: a jagged line across the figure's upper half, new each flash.
func _arc(arc: Line2D, r: TextureRect) -> void:
	var sz: Vector2 = r.size * r.scale
	var a: Vector2 = r.position + Vector2(sz.x * 0.2, sz.y * randf_range(0.15, 0.5))
	var b: Vector2 = r.position + Vector2(sz.x * 0.8, sz.y * randf_range(0.15, 0.5))
	var pts := PackedVector2Array()
	for n in range(7):
		var q: Vector2 = a.lerp(b, n / 6.0)
		if n > 0 and n < 6:
			q += Vector2(randf_range(-4.0, 4.0), randf_range(-sz.y * 0.08, sz.y * 0.08))
		pts.append(q)
	arc.points = pts
	arc.visible = true


## For the tests: the elements as shown - on them, the particles emitting and the tint of the first one up; on you, the
## edges' alpha.
func fx() -> Dictionary:
	var them := {}
	for el in ["fire", "poison", "bleed", "frost"]:
		them[el] = _figs.any(func(f): return f["fx"][el].emitting)
	var tint := Color.WHITE
	for f in _figs:
		if f["state"] in ["pop", "up"]:
			tint = f["rect"].self_modulate
			break
	var you := {}
	for el in _edges:
		you[el] = _edges[el].modulate.a
	return {"them": them, "tint": tint, "you": you, "arcs": _arcs.filter(func(a): return a.visible).size()}


## Whether your gun's going off in the frame right now: someone up to shoot at, and you not down behind the wall.
func shooting() -> bool:
	return _firing and not _reloading and _duck < 0.2 and _figs.any(func(f): return f["state"] == "up")


## Whether there's a fight on in the frame at all (down behind the wall counts): the run screen holds your hits for it.
func fighting() -> bool:
	return _firing and _figs.any(func(f): return f["state"] in ["pop", "up"])


## For the tests: what's up, the pan, the red.
## Where a shot of theirs comes from, for the sound (17 Oct): one of the figures up, its place across the frame (-1 the
## left edge, 1 the right) and how near its slot is (0 the far one, 1 the near).
func shooter_spot() -> Dictionary:
	var up: Array = []
	for k in range(_figs.size()):
		if _figs[k]["state"] in ["pop", "up"]:
			up.append(k)
	if up.is_empty():
		return {}
	var k: int = up[randi() % up.size()]
	var s: Dictionary = slot_of(mini(k, SLOTS.size() - 1))
	return {"pan": clampf((float(s["foot"].x) - W / 2.0) / (W / 2.0), -1.0, 1.0), "near": clampf((float(s["scale"]) - 0.3) / 0.65, 0.0, 1.0)}


## Where figure k stands for the sound's pan: across the frame, and how near.
func spot_of(k: int) -> Dictionary:
	if k < 0 or k >= _figs.size():
		return {}
	var s: Dictionary = slot_of(mini(k, SLOTS.size() - 1))
	return {"pan": clampf((float(s["foot"].x) - W / 2.0) / (W / 2.0), -1.0, 1.0), "near": clampf((float(s["scale"]) - 0.3) / 0.65, 0.0, 1.0)}


## How far down behind the wall: 0 up, 1 right down (the sound's low-pass follows it).
func duck_amount() -> float:
	return _duck


func figures_up() -> int:
	var n := 0
	for f in _figs:
		if f["state"] in ["pop", "up"]:
			n += 1
	return n


func state() -> Dictionary:
	return {"on_you": _on_you, "up": figures_up(), "pan_to": _pan_to, "red": _red_a, "crates": _crates.filter(func(c): return c.visible).size(), "duck": _duck, "glass": _glass.visible, "search_p": _search_p, "open": _open_left > 0.0 and _open_c.visible}


# ==================================================================== BUILD66-V: the shooter mechanics on the frame
# (7 Nov, docs/design/endgame_rail.md §1 and the Fight mockup): a headshot pops gold over the man hit, a jam shows over
# your gun with its time left, a hard man carries a plate (HARD MAN, his name, his trait chips) and a gold-edged bar,
# the streak and Last Stand ride the head's row at the frame's top right. All in the bars' layer: the frame's pixels as
# drawn (812 x 362), not its art's. The sim's side is F's (sim.f66_*); the log's lines are the sim's own.
const Words66 := preload("res://scripts/sim/words.gd")
const Fmt66 := preload("res://scripts/ui/fmt.gd")
const GOLD66 := Color("f4c542")            # the headshot's pop and the hard man's edge (the mockup's gold)
const POP66_S := 1.0                       # a headshot's pop: its rise and its fade
const POP66_RISE := 30.0
const POP66_FONT := 30
const POP66_MAX := 3
const POP66_BIG := 1.3                     # a pop's scale as it's born, settling to 1 (the 67 fix round: named, the clearing reads it)
const POP66_SMALLER := [24, 20]            # a pop's sizes when there's no room at its own
const PILL66_H := 28.0                     # the streak's and Last Stand's pills, on the head's row
const PILL66_PAD := 8.0
const PLATE66_PAD := 10.0
const CHIP66_H := 24.0
const STREAK66_FROM := 2                   # the streak shows from two kills: one isn't a streak
const STALE66_S := 1.5                     # an event this old when first seen (back from another room) shows nothing
signal sound66(id: String, pitch: float)   # a headshot's and a jam's sound (run.gd plays it)
var _hud66: Control
var _seq66 := 0
var _run66 := -1
var _pops66: Array = []                    # {label, left}
var _jam66: Panel
var _jam66_l: Label
var _jam66_left := 0.0
var _streak66: Panel
var _streak66_n: Label
var _streak66_w: Label
var _streak66_b: Label
var _ls66: Panel
var _ls66_w: Label
var _ls66_s: Label
var _plate66: Panel
var _plate66_kick: Label
var _plate66_name: Label
var _chips66: Array = []                   # [Panel, Label] a trait
var _hard66 := {}                          # sim.f66_hard_man() as last read; {} with none up
var _hard66_k := -1                        # the figure he is
var _keep66: Array = []                    # what the counters and the plate keep off, the frame's pixels (run.gd's head, chips, countdown)
var _fight66 := false                      # a gang's on you
var _word66 := Rect2()                     # a skill's name across the frame while it shows (run.gd)


func _v66_make() -> void:
	_hud66 = Control.new()
	_hud66.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars_layer.add_child(_hud66)
	_plate66 = UI.panel(_hud66, Rect2(0, 0, 10, 10), UI.box(Color(Pal.BG, 0.92), 6, 2, GOLD66))
	_plate66.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate66_kick = UI.label(_plate66, Rect2(0, 5, 10, 18), Words66.V66["hard"], "SemiBold", 13, GOLD66, HORIZONTAL_ALIGNMENT_CENTER, false)
	_plate66_name = UI.label(_plate66, Rect2(0, 22, 10, 28), "", "SemiBold", 22, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	for i in range(2):
		var cp := UI.panel(_plate66, Rect2(0, 0, 10, CHIP66_H), UI.box(Pal.CARD, 5, 1, Pal.CARD_LINE))
		cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cl := UI.label(cp, Rect2(0, 0, 10, CHIP66_H), "", "Regular", 15, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
		_chips66.append([cp, cl])
	_plate66.visible = false
	_streak66 = UI.panel(_hud66, Rect2(0, 0, 10, PILL66_H), UI.box(Color(Pal.BG, 0.85), 6, 1, Pal.CARD_LINE))
	_streak66.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_streak66_n = UI.label(_streak66, Rect2(PILL66_PAD, 0, 10, PILL66_H), "", "Bold", 22, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_streak66_w = UI.label(_streak66, Rect2(0, 0, 10, PILL66_H), Words66.V66["streak"], "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_streak66_b = UI.label(_streak66, Rect2(0, 0, 10, PILL66_H), "", "Regular", Pal.CELL_TEXT, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
	_streak66.visible = false
	_ls66 = UI.panel(_hud66, Rect2(0, 0, 10, PILL66_H), UI.box(Color(Pal.BG, 0.85), 6, 1, Pal.CARD_LINE))
	_ls66.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ls66_w = UI.label(_ls66, Rect2(PILL66_PAD, 0, 10, PILL66_H), Words66.V66["last_stand"] + " ·", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_ls66_s = UI.label(_ls66, Rect2(0, 0, 10, PILL66_H), "", "SemiBold", Pal.CELL_TEXT, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
	_ls66.visible = false
	_jam66 = UI.panel(_hud66, Rect2(0, 0, 10, PILL66_H), UI.box(Pal.WARN, 6))
	_jam66.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jam66_l = UI.label(_jam66, Rect2(0, 0, 10, PILL66_H), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.ACCENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	_jam66.visible = false


## A label's box to its words (a few pixels' slack), at x; its right edge back.
static func _fit66(l: Label, x: float) -> float:
	l.size.x = ceilf(UI.text_width(l, l.text)) + 4.0
	l.position.x = x
	return x + l.size.x


## Each look (show_state): the new events (the pops, the sounds), and what the frame shows of the rest.
func _v66_show(sim, m: Dictionary) -> void:
	if sim.runs_total != _run66 or sim.f66_last_seq() < _seq66:     # (the review of 66) or a save behind what was seen
		_run66 = sim.runs_total                  # a new run: nothing seen of it yet (its first events are fresh)
		_seq66 = 0
		_jam66_left = 0.0
		for p in _pops66:
			p["label"].queue_free()
		_pops66 = []
	var now: float = float(m.get("elapsed", 0.0))
	_fight66 = int(m["remaining"]) > 0
	for e in sim.f66_events_since(_seq66):
		_seq66 = maxi(_seq66, int(e["seq"]))
		if now - float(e.get("at", now)) > STALE66_S:
			continue
		match str(e["kind"]):
			"headshot":
				_pop66(float(e.get("amount", 0.0)), bool(e.get("hard", false)))
				sound66.emit("kill", 1.35)       # a kill's thump pitched up: the crack of a headshot
			"jam":
				sound66.emit("dry_click", 0.85)  # the dry click, lower: a round that won't go
	# the jam: on the gun in hand (the other's, if that's the one jammed)
	var gun = gun_in_hand(sim)
	var slot: String = "Secondary" if gun != null and gun == sim.equipped["Secondary"] else "Primary"
	_jam66_left = sim.f66_jam_left(slot) if _fight66 else 0.0
	# the streak, from two kills; its bonus when the build has streak_dmg_pct
	var n: int = sim.f66_streak()
	_streak66.visible = n >= STREAK66_FROM
	if _streak66.visible:
		_streak66_n.text = Words66.V66["streak_n"] % n
		_streak66_b.set_meta("pct", roundi(sim.f66_streak_bonus_pct()))
		_fit66(_streak66_n, _fit66(_streak66_w, PILL66_PAD) + 6.0)     # (the fix round) sized with their words, before the frame's lay: the sweep reads them between
	# Last Stand: only on a build that has it
	var ls: String = sim.f66_last_stand_state()
	_ls66.visible = ls != "none"
	if _ls66.visible:
		match ls:
			"ready":
				_ls66_s.text = Words66.V66["ls_ready"]
				_ls66_s.add_theme_color_override("font_color", Pal.GOOD)
			"on":
				_ls66_s.text = Words66.V66["ls_on"] % ("%.1f" % maxf(0.0, sim.f66_last_stand_left()))
				_ls66_s.add_theme_color_override("font_color", Pal.WARN)
			_:
				_ls66_s.text = Words66.V66["ls_used"]
				_ls66_s.add_theme_color_override("font_color", Pal.TEXT_3)
		_fit66(_ls66_s, _fit66(_ls66_w, PILL66_PAD) + 4.0)     # (the fix round) as the streak's
	# the hard man, while his gang's on you
	_hard66 = sim.f66_hard_man() if _fight66 else {}
	if not _hard66.is_empty():
		_plate66_name.text = str(_hard66["name"])
		var words: Array = _hard66.get("trait_words", [])
		for i in range(_chips66.size()):
			_chips66[i][0].visible = i < words.size()
			if i < words.size():
				_chips66[i][1].text = str(words[i])


## Which figure the hard man is (_lay_bars, before the bars): the one in front when he's the man being shot, else one
## of the rest kept while he stands.
func _v66_pick() -> void:
	if _hard66.is_empty() or not _firing:
		_hard66_k = -1
		return
	var ups: Array = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] in ["pop", "up"])
	if bool(_hard66.get("in_front", true)) and _target_k in ups:
		_hard66_k = _target_k
	elif not (_hard66_k in ups) or (_hard66_k == _target_k and ups.size() > 1):
		var rest: Array = ups.filter(func(k): return k != _target_k)
		_hard66_k = rest[0] if not rest.is_empty() else (_target_k if _target_k in ups else -1)


## The bar's share for figure k: his own for the hard man, else what _lay_bars worked out.
func _v66_share(k: int, share: float) -> float:
	return clampf(float(_hard66.get("hp_share", share)), 0.0, 1.0) if k == _hard66_k and k >= 0 else share


## The HP words over the one you're hitting: his own HP when it's the hard man.
func _v66_tag(k: int, words: String) -> String:
	if k != _hard66_k or k < 0 or not _hard66.has("hp"):
		return words
	return "%s / %s" % [Fmt66.group(ceili(float(_hard66["hp"]))), Fmt66.group(roundi(float(_hard66["hp_max"])))]


## A headshot's pop: "HEADSHOT 4,120" in gold over the man hit, rising and fading.
func _pop66(amount: float, hard: bool) -> void:
	var s: float = scale.x if scale.x > 0.0 else 1.0
	_hud66.size = Vector2(W * s, H * s)          # (the fix round) the pieces' box before the frame's first lay: a pop there sits inside it
	var ups: Array = range(SLOTS.size()).filter(func(j): return _figs[j]["state"] in ["pop", "up"])
	var k: int = _hard66_k if hard and _hard66_k in ups else (_target_k if _target_k in ups else (ups[0] if not ups.is_empty() else -1))
	var spot := Vector2(W * 0.5, H * 0.4)
	if k >= 0:
		var r: TextureRect = _figs[k]["rect"]
		var u: Rect2 = used_of(r.texture)
		if u.size.y <= 0.0:
			u = Rect2(Vector2.ZERO, r.size)
		spot = r.position + Vector2(u.get_center().x, u.position.y + u.size.y * 0.3) * r.scale.x
	var fig: String = Fmt66.group(roundi(amount)) if absf(amount) < 1e9 else Fmt66.num(amount)
	var l := UI.label(_hud66, Rect2(0, 0, 10, 40), Words66.V66["headshot"] % fig, "Bold", POP66_FONT, GOLD66, HORIZONTAL_ALIGNMENT_CENTER, false)
	l.add_theme_constant_override("outline_size", 7)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.06, 1.0))
	l.size.x = ceilf(UI.text_width(l, l.text)) + 12.0
	var at := Vector2(spot.x * s - l.size.x * 0.5, spot.y * s - l.size.y * 0.5)
	at.x = clampf(at.x, 6.0, W * s - l.size.x - 6.0)
	at.y = clampf(at.y, 6.0 + POP66_RISE, H * s - l.size.y - 6.0)
	var born: Array = []
	for p in _pops66:
		if p["label"].visible:
			born.append(Rect2(p["label"].position - Vector2(0.0, POP66_RISE), p["label"].size + Vector2(0.0, POP66_RISE)))
	at = _pop66_clear(at, l.size, born)          # (BUILD67-K) born clear of the pops already up: two headshots in one tick sat on one spot until the frame's lay
	l.visible = clear66_ok
	l.position = at
	l.set_meta("from", at)
	l.pivot_offset = l.size * 0.5
	_pops66.append({"label": l, "left": POP66_S})
	while _pops66.size() > POP66_MAX:
		_pops66.pop_front()["label"].queue_free()


## The nearest spot to `at` where a box of `sz` (grown `up` pixels upward: a pop's rise) sits in the frame clear of
## every rect in `keep`: tried outward from where it wants to be, up and down first, then across.
static var _offs66: Array = []
var clear66_ok := true                     # the last _clear66 found a clear spot
func _clear66(at: Vector2, sz: Vector2, keep: Array, up := 0.0) -> Vector2:
	var s: float = scale.x if scale.x > 0.0 else 1.0
	var fr := Rect2(Vector2(6.0, 6.0), Vector2(W * s - 12.0, H * s - 12.0))
	if _offs66.is_empty():
		for dx in range(-30, 31):
			for dy in range(-40, 41):
				_offs66.append(Vector2(dx * 12.0, dy * 6.0))
		_offs66.sort_custom(func(a, b): return absf(a.x) * 1.5 + absf(a.y) < absf(b.x) * 1.5 + absf(b.y))
	clear66_ok = false
	for o in _offs66:
		var r := Rect2(at + o - Vector2(0.0, up), sz + Vector2(0.0, up))
		if fr.encloses(r) and keep.all(func(q): return not q.intersects(r)):
			clear66_ok = true
			return at + o
	return at


## A pop's spot clear of the bars, the HP words, the plate, what run.gd lays over the frame, the jam and the pops
## before it, over its whole rise.
func _pop66_clear(at: Vector2, sz: Vector2, before: Array = []) -> Vector2:
	var keep: Array = pop66_keep() + _keep66 + before
	for n in [_streak66, _ls66]:
		if n.visible:
			keep.append(Rect2(n.position, n.size))
	if _word66.size.x > 0.0:
		keep.append(_word66)
	if _jam66.visible:
		keep.append(Rect2(_jam66.position, _jam66.size))
	var g: Vector2 = sz * (POP66_BIG - 1.0) * 0.5     # (the 67 fix round) cleared at its biggest: it pops in at x1.3 about its middle (the full smoke: 'Your HP' under a pop's first frames)
	return _clear66(at - g, sz + 2.0 * g, keep, POP66_RISE) + g


## What a headshot's pop keeps off: each bar up, the HP words, the hard man's plate (the frame's pixels).
func pop66_keep() -> Array:
	var out: Array = []
	for f in _figs:
		if f["bar"].visible:
			out.append(Rect2(f["bar"].position, f["bar"].size).grow(3.0))
	if _hp_tag.visible:
		out.append(Rect2(_hp_tag.position, _hp_tag.size))
	if _plate66.visible:
		out.append(Rect2(_plate66.position, _plate66.size))
	return out


## Each frame, after the bars: the pops' rise, the pills on the head's row, the plate over the hard man, the jam's tag.
func _v66_lay(dt: float) -> void:
	var s: float = scale.x if scale.x > 0.0 else 1.0
	var fw: float = W * s
	var fh: float = H * s
	_hud66.size = Vector2(fw, fh)                # the frame as drawn: the pieces' box
	# the pills, right to left at the top right: Last Stand at the edge, the streak beside it
	var x: float = fw - 8.0
	if _ls66.visible:
		var e: float = _fit66(_ls66_w, PILL66_PAD)
		e = _fit66(_ls66_s, e + 4.0)
		_ls66.size = Vector2(e + PILL66_PAD, PILL66_H)
		x -= _ls66.size.x
		_ls66.position = Vector2(x, 4.0)
		x -= 8.0
	if _streak66.visible:
		var pct: int = int(_streak66_b.get_meta("pct", 0))
		var forms: Array = [] if pct <= 0 else (Words66.V66["streak_bonus"] as Array).map(func(f): return "· " + str(f) % pct)
		forms.append("")
		for f in forms:
			_streak66_b.text = f
			var e: float = _fit66(_streak66_w, PILL66_PAD)     # "Streak 7" (the editor): the word, then the count
			e = _fit66(_streak66_n, e + 6.0)
			if f != "":
				e = _fit66(_streak66_b, e + 5.0)
			_streak66_b.visible = f != ""
			_streak66.size = Vector2(e + PILL66_PAD, PILL66_H)
			_streak66.position = Vector2(x - _streak66.size.x, 4.0)
			if _keep66.all(func(r): return not r.intersects(Rect2(_streak66.position, _streak66.size))):
				break
		if not _keep66.all(func(r): return not r.intersects(Rect2(_streak66.position, _streak66.size))):
			# (BUILD67-K) no form clear at the top right (a long head over the frame: "Picking it over · each gang bigger than
			# the last" with a streak carried into the search): the nearest clear spot, else not over the words
			_streak66.position = _clear66(_streak66.position, _streak66.size, _keep66)
			_streak66.visible = clear66_ok
	# the plate over the hard man, his bar under it (pushed down when the plate meets the head's row)
	var k: int = _hard66_k
	_plate66.visible = k >= 0 and _figs[k]["bar"].visible
	if _plate66.visible:
		var fb: FigBar = _figs[k]["bar"]
		var cw := 0.0
		var shown: Array = _chips66.filter(func(c): return c[0].visible)
		for c in shown:
			c[1].size.x = ceilf(UI.text_width(c[1], c[1].text)) + 4.0
			c[0].size = Vector2(c[1].size.x + 16.0, CHIP66_H)
			c[1].position = Vector2(8.0, 0.0)
			cw += c[0].size.x
		cw += 6.0 * maxf(0.0, shown.size() - 1.0)
		_plate66_name.size.x = ceilf(UI.text_width(_plate66_name, _plate66_name.text)) + 4.0
		_plate66_kick.size.x = ceilf(UI.text_width(_plate66_kick, _plate66_kick.text)) + 4.0
		var pw: float = maxf(maxf(_plate66_name.size.x, _plate66_kick.size.x), cw) + 2.0 * PLATE66_PAD
		var ph: float = 52.0 + (CHIP66_H + 8.0 if not shown.is_empty() else 4.0)
		_plate66.size = Vector2(pw, ph)
		_plate66_kick.position.x = (pw - _plate66_kick.size.x) * 0.5
		_plate66_name.position.x = (pw - _plate66_name.size.x) * 0.5
		var cx: float = (pw - cw) * 0.5
		for c in shown:
			c[0].position = Vector2(cx, 52.0)
			cx += c[0].size.x + 6.0
		var tag_h: float = 24.0 if _hp_tag.visible and k == _target_k else 0.0
		var at := Vector2(clampf(fb.position.x + fb.size.x * 0.5 - pw * 0.5, 6.0, fw - pw - 6.0), fb.position.y - tag_h - 8.0 - ph)
		at.y = maxf(at.y, 6.0)
		var keep: Array = _keep66.duplicate()
		for n in [_streak66, _ls66]:
			if n.visible:
				keep.append(Rect2(n.position, n.size))
		at = _clear66(at, _plate66.size, keep)
		_plate66.position = at
		var bar_y: float = at.y + ph + 8.0 + tag_h
		var over_bar: bool = at.x < fb.position.x + fb.size.x and at.x + pw > fb.position.x     # moved aside, it leaves the bar be
		if over_bar and fb.position.y < bar_y:
			fb.position.y = minf(bar_y, fh - fb.size.y - 6.0)     # under the plate; the HP words with it
			if tag_h > 0.0:
				_hp_tag.position.y = fb.position.y - tag_h
	# the jam, over your gun
	_jam66_left = maxf(0.0, _jam66_left - dt)
	_jam66.visible = _jam66_left > 0.0 and _hands.visible and _fight66
	if _jam66.visible:
		_jam66_l.text = Words66.V66["jammed"] % ("%.1f" % _jam66_left)
		_jam66_l.size.x = ceilf(UI.text_width(_jam66_l, _jam66_l.text)) + 4.0
		_jam66.size = Vector2(_jam66_l.size.x + 20.0, PILL66_H)
		_jam66_l.position.x = 10.0
		var u: Rect2 = used_of(_hands.texture)
		var top: Vector2 = (_hands.position + u.position * _hs) * s
		var jat := Vector2(top.x + u.size.x * _hs * s * 0.5 - _jam66.size.x * 0.5, top.y - _jam66.size.y - 8.0)
		jat.x = clampf(jat.x, 6.0, fw - _jam66.size.x - 6.0)
		jat.y = clampf(jat.y, 40.0, fh - _jam66.size.y - 6.0)
		var jkeep: Array = _keep66 + pop66_keep()
		for n in [_streak66, _ls66]:
			if n.visible:
				jkeep.append(Rect2(n.position, n.size))
		if _word66.size.x > 0.0:
			jkeep.append(_word66)
		_jam66.position = _clear66(jat, _jam66.size, jkeep)
	# the pops, last: clear of the plate, the jam and the rest where they stand this frame
	var gone: Array = []
	var laid: Array = []
	for p in _pops66:
		p["left"] = float(p["left"]) - dt
		var l: Label = p["label"]
		var age: float = 1.0 - clampf(float(p["left"]) / POP66_S, 0.0, 1.0)
		var from: Vector2 = _pop66_clear(Vector2(l.get_meta("from")), l.size, laid)
		for fs in POP66_SMALLER:
			if clear66_ok or l.get_theme_font_size("font_size") <= fs:
				continue
			l.add_theme_font_size_override("font_size", fs)     # no room at its size (a skill's name across the frame, the countdown): smaller
			l.size = Vector2(ceilf(UI.text_width(l, l.text)) + 12.0, ceilf(l.get_theme_font("font").get_height(fs)) + 6.0)
			l.pivot_offset = l.size * 0.5
			from = _pop66_clear(Vector2(l.get_meta("from")), l.size, laid)
		l.visible = clear66_ok                   # nowhere clear at the smallest: not over other words (its number and its sound still come)
		laid.append(Rect2(from - Vector2(0.0, POP66_RISE), l.size + Vector2(0.0, POP66_RISE)))
		l.position = from - Vector2(0.0, POP66_RISE * ease(age, 0.5))
		l.scale = Vector2.ONE * (1.0 + (POP66_BIG - 1.0) * maxf(0.0, 1.0 - age / 0.15))     # pops in big, settles
		l.modulate.a = clampf(float(p["left"]) / (POP66_S * 0.4), 0.0, 1.0)
		if l.visible and _pop66_hits_words(l):
			l.visible = false                    # (the 67 fix round) where it stands this frame, scaled, still on words: not shown
		if float(p["left"]) <= 0.0:
			gone.append(p)
	for p in gone:
		_pops66.erase(p)
		p["label"].queue_free()


## What run.gd lays over the frame, in the frame's pixels: the counters and the plate keep off `rects`; the jam and the
## pops keep off those and `word` too (a skill's name across the frame, there a moment).
func v66_keep(rects: Array, word := Rect2()) -> void:
	_keep66 = rects
	_word66 = word
	if _hud66 != null:
		_v66_lay(0.0)                            # (BUILD67-K) laid again on what they keep off now: a look's new head, chips or pops sat on the last frame's places till the next frame


## The labels showing (the fit check's), and for the tests what each piece shows, in the frame's pixels.
func v66_text_nodes() -> Array:
	var out: Array = []
	for p in _pops66:
		if p["label"].visible:
			out.append(p["label"])
	if _jam66.visible:
		out.append(_jam66_l)
	if _streak66.visible:
		out.append_array([_streak66_n, _streak66_w])
		if _streak66_b.visible:
			out.append(_streak66_b)
	if _ls66.visible:
		out.append_array([_ls66_w, _ls66_s])
	if _plate66.visible:
		out.append_array([_plate66_kick, _plate66_name])
		for c in _chips66:
			if c[0].visible:
				out.append(c[1])
	return out


func v66_state() -> Dictionary:
	var hb := Rect2()
	if _hard66_k >= 0:
		var fb: FigBar = _figs[_hard66_k]["bar"]
		hb = Rect2(fb.position, fb.size) if fb.visible else Rect2()
	return {"frame": Rect2(Vector2.ZERO, Vector2(W, H) * (scale.x if scale.x > 0.0 else 1.0)),
		"pops": _pops66.map(func(p): return p["label"].text), "pop_rects": _pops66.filter(func(p): return p["label"].visible).map(func(p): return Rect2(p["label"].position, p["label"].size)),
		"pops_shown": _pops66.filter(func(p): return p["label"].visible).size(),
		"jam": _jam66.visible, "jam_text": _jam66_l.text if _jam66.visible else "", "jam_rect": Rect2(_jam66.position, _jam66.size),
		"hands_rect": Rect2(_hands.position * (scale.x if scale.x > 0.0 else 1.0), _hands.size * _hands.scale * (scale.x if scale.x > 0.0 else 1.0)),
		"streak": _streak66.visible, "streak_text": (_streak66_w.text + " " + _streak66_n.text + (" " + _streak66_b.text if _streak66_b.visible else "")) if _streak66.visible else "",
		"streak_rect": Rect2(_streak66.position, _streak66.size),
		"ls": _ls66.visible, "ls_text": (_ls66_w.text + " " + _ls66_s.text) if _ls66.visible else "", "ls_rect": Rect2(_ls66.position, _ls66.size),
		"plate": _plate66.visible, "plate_rect": Rect2(_plate66.position, _plate66.size), "plate_name": _plate66_name.text,
		"plate_chips": _chips66.filter(func(c): return c[0].visible).map(func(c): return c[1].text),
		"chip_rects": _chips66.filter(func(c): return c[0].visible).map(func(c): return Rect2(_plate66.position + c[0].position, c[0].size)),
		"hard_k": _hard66_k, "hard_bar": hb, "hard_edge": _hard66_k >= 0 and _figs[_hard66_k]["bar"].hard,
		"jam_hold": _jam66_left > 0.0}



## (the 67 fix round) A pop as drawn this frame - its rise and its scale about its middle - over the words it keeps off:
## the last word on a pop (the full smoke at 1920x1080 with a skill's name: 'Your HP 437 / 437' under one by 12 px).
func _pop66_hits_words(l: Label) -> bool:
	var r := Rect2(l.position + l.pivot_offset * (Vector2.ONE - l.scale), l.size * l.scale)
	var keep: Array = pop66_keep() + _keep66
	if _word66.size.x > 0.0:
		keep.append(_word66)
	return keep.any(func(q): return Rect2(q).intersects(r))
