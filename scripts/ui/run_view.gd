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
	var at: String = key
	if not (placed.has(at) and placed[at] is Array and placed[at].size() == 3):
		at = key.trim_suffix("@kit")              # the kit's pair not placed yet: where the old pair's were, as a start
	if placed.has(at) and placed[at] is Array and placed[at].size() == 3:
		var row: Array = placed[at][k]
		return {"foot": Vector2(float(row[0]), float(row[1])), "scale": float(row[2]), "lit": SLOTS[k]["lit"]}
	key = key.trim_suffix("@kit")
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


## The site's plate and cover (its own, else the Parade's test pair), and the wall's fill cut from the cover.
func _site(key: String) -> void:
	_site_key = key
	var own: bool = tex(key + "_plate") != null and tex(key + "_cover") != null     # the site's pair, or the Parade's: never one of each
	_own_site = own
	_kit_site = own and kit_pair(key)
	_plate.texture = tex(key + "_plate") if own else tex("parade_plate")
	if _plate.texture != null:
		_plate.size = _plate.texture.get_size()
		_plate.scale = Vector2.ONE * (PLATE_VIEW_W / _plate.size.x)     # the kit's 744 drawn as the old 688: the slots and the pan keep their numbers
	var ct: Texture2D = tex(key + "_cover") if own else tex("parade_cover")
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
	var scene_key: String = _boss_key if _boss_key != "" and _pair_in(BOSS_DIR, _boss_key) else (place_key if place_key != "" and _pair_in(COUNTY_DIR, place_key) else Items.slug(str(site["name"])))     # his den while he's out, when it's drawn; a County place's own (26 Oct)
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
	_dogs_on = m.has("dogs_home")
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
	if _firing and not _reloading and _shot_t <= 0.0 and _duck < 0.2 and _swing < 0.0:
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
		var u: Rect2 = used_of(r.texture)
		if u.size.y <= 0.0:
			u = Rect2(Vector2.ZERO, r.size)
		var top: Vector2 = r.position + Vector2(u.get_center().x, u.position.y) * r.scale.x     # the head of the figure, in the frame
		var w: float = BAR_W_HEAD if head else clampf(u.size.x * r.scale.x * s * 0.75, 48.0, 120.0)
		var h: float = BAR_H_HEAD if head else (BAR_H_HIT if hit else BAR_H)
		var at := Vector2(top.x * s - w * 0.5, top.y * s - h - 8.0)
		var tag_h: float = 24.0 if hit else 0.0
		at.x = clampf(at.x, 6.0, W * s - w - 6.0)
		at.y = clampf(at.y, 6.0 + tag_h, H * s - h - 6.0)
		fb.position = at
		fb.size = Vector2(w, h)
		fb.modulate.a = r.modulate.a
		var of: float = float(_bar_info["of"])
		fb.share = clampf(float(_bar_info["hp"]) / of, 0.0, 1.0) if hit else 1.0
		var dots := {}
		var ticking := 0.0
		if hit:
			for ty in _bar_info["dots"]:
				dots[ty] = maxf(0.0, float(_bar_info["dots"][ty])) / of
				ticking += maxf(0.0, float(_bar_info["dots"][ty]))
		fb.dots = dots
		fb.shield = float(_bar_info.get("shield", 0.0)) if (hit and head) else 0.0
		fb.hit = hit
		fb.finish = hit and float(_bar_info["hp"]) > 0.0 and ticking >= float(_bar_info["hp"])     # the skull (11 Oct): the dots will finish them
		fb.queue_redraw()
		if hit:
			_hp_tag.text = "%d / %d" % [ceili(float(_bar_info["hp"])), int(round(of))]
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

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(UI.box(Color(Pal.BG, 0.88), 3, 2 if hit else 1, Pal.ACCENT if hit else Color(Pal.TEXT_3, 0.8)), r.grow(2.0))
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
	"security_guard_s_carbine": [Vector2(77, 92), Vector2(-1, -0.15)],     # and the front sight's, here and below
	"army_smg": [Vector2(77, 79), Vector2(-1, -0.2)],     # the suppressor's end
	"riot_squad_s_smg": [Vector2(131, 84), Vector2(-1, -0.35)],
	"close_protection_smg": [Vector2(103, 84), Vector2(-1, -0.15)],     # the suppressor's end, not the receiver's top (17 Oct, the reroll)
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
## pistol's or an SMG's topmost drawn pixel, else the long gun's furthest toward the top left; the way it points from
## the gun's middle (the upper part's drawn pixels averaged) out through the muzzle. [at, dir].
static func find_muzzle(t: Texture2D, kind: String) -> Array:
	var img := t.get_image()
	if img == null:
		return [Vector2.ZERO, Vector2(-1, -0.4).normalized()]
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var w: int = img.get_width()
	var h: int = img.get_height()
	var probe: Vector2 = Vector2(0, -1) if kind in ["pistol", "smg"] else Vector2(-1, -0.35).normalized()
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
