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

## A shot of yours lands, in the frame's space (13 Oct, Matt: the numbers came with no shot, and while ducked): the run
## screen shows what your gun's done since the last one here, on the one it hit.
signal shot_fired(at: Vector2)

## The placement tool on or off: the run screen clears what it lays over the frame (bars, chips, the head) while it's on.
signal placing_changed(on: bool)

const W := 588
const H := 262
const DIR := "res://art/fight_test/%s.png"
const FULL_DIR := "res://art/fight/%s.png"       # the full pass (13 Oct, tools/pixellab_fight_manifest.json)
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

static var _tex := {}

var _plate: TextureRect
var _site_key := "-"                      # the site the plate and cover are of
var _zone_key := "the_estate"             # its zone's gang
var _boss_key := ""                       # the head when he's out, "" else
var _cover_y := COVER_Y
var _own_site := false                     # the site's own plate is up (its far slot with it)
var _hands_at := HANDS_AT                 # the hands' top-left for the gun's picture                   # the cover's top-left y: its drawn top at COVER_TOP
var _figs: Array = []                     # {rect, state: "", t, fire_t, next_fire}
var _crates: Array = []                   # the crates in the street while searching
var _cover: TextureRect
var _cover_fill: TextureRect               # the wall's brick carried on down under it, for the duck (Matt: "too short when crouching")
var _shadows: Array = []                   # a shadow under each crate
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
var _red_a := 0.0
var _shot_t := 0.0
var _rof := 1.0
var _firing := false
var _recoil := 0.0
## A melee weapon's swing (14 Oct, Matt: "we need an attack frame for melee ... the action just hangs"): in engine, no
## new art. The weapon's arm (the picture split from the off hand where there's a clean gap between them) winds back,
## chops toward the one it's hitting and settles, round the forearm; the hit - its marker, its number - lands on the
## chop, and a streak follows the head through it. A gun keeps its kick.
const SWING_BACK := 0.24                  # radians, the wind-up (clockwise: the head back and up)
const SWING_FWD := -0.46                  # the chop (anticlockwise: the head down toward them)
const SWING_LIFT := Vector2(8, -10)       # the wind-up's lift, in the picture's pixels
const SWING_LUNGE := Vector2(-40, 14)     # the chop's reach toward the street
const SWING_UP := 0.35                    # the swing's share winding up
const SWING_CONTACT := 0.55               # where in it the chop lands
const STREAK_S := 0.16                    # a streak point's life
var _melee := false
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

## A texture by name: the full pass's (art/fight) first, the test's (art/fight_test) else; imported if the editor's seen
## it, else read straight off the disk.
static func tex(name: String) -> Texture2D:
	if _tex.has(name):
		return _tex[name]
	var t: Texture2D = null
	for dir in [FULL_DIR, DIR]:
		var path: String = dir % name
		if ResourceLoader.exists(path):
			t = load(path)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null:
				img.generate_mipmaps()
				t = ImageTexture.create_from_image(img)
		if t != null:
			break
	_tex[name] = t
	return t


## The first of the names that has a picture (the site's own, then the slice's).
static func tex_of(names: Array) -> Texture2D:
	for n in names:
		var t := tex(str(n))
		if t != null:
			return t
	return null


## Where a picture's drawn part ends, in its own pixels (a figure's feet, a cover's top): its used rect, cached.
static var _used := {}
static func used_of(t: Texture2D) -> Rect2:
	if t == null:
		return Rect2()
	var key: int = t.get_instance_id()
	if not _used.has(key):
		var img := t.get_image()
		_used[key] = Rect2(img.get_used_rect()) if img != null else Rect2(Vector2.ZERO, t.get_size())
	return _used[key]


## A site's name as its files' (The Allotments -> the_allotments).
static func site_key(name: String) -> String:
	return name.to_lower().replace(" ", "_").replace("'", "")


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
	# the figures stand in depth order: the far one behind, the near one in front
	move_child(_figs[2]["rect"], _plate.get_index() + 1)
	_cover = _rect(null)
	_cover_fill = _rect(null)
	_cover_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cover_fill.stretch_mode = TextureRect.STRETCH_TILE
	move_child(_cover_fill, _cover.get_index())     # under the cover's coping
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
	_glass = Glass.new()
	_glass.ring = Pal.ACCENT
	_glass.visible = false
	add_child(_glass)
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
	return site_slot(_site_key if _own_site else "", k)


## A site's slot k ("" for the test plate's): where F3/F5 put it (data/fight_slots.tres), else its own in the tables
## below, else the common one.
static func site_slot(key: String, k: int) -> Dictionary:
	var placed: Dictionary = saved_sites()
	if placed.has(key) and placed[key] is Array and placed[key].size() == 3:
		var row: Array = placed[key][k]
		return {"foot": Vector2(float(row[0]), float(row[1])), "scale": float(row[2]), "lit": SLOTS[k]["lit"]}
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
	if on:
		_edit = []
		for k in range(3):
			_edit.append(site_slot(_site_key, k).duplicate())
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


func set_slot(k: int, foot: Vector2, scale: float) -> void:
	if k >= 0 and k < _edit.size():
		_edit[k] = {"foot": foot, "scale": scale, "lit": SLOTS[k]["lit"]}


## Placing: the plate at rest, all three standing on their slots, nothing firing, flashing or burning.
func _place_tick() -> void:
	_plate.position = PLATE_AT
	_cover.position = Vector2(COVER_X, _cover_y)
	_cover_fill.position = _cover.position + Vector2(0, _cover.size.y - 1)
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
	_plate.texture = tex(key + "_plate") if own else tex("parade_plate")
	if _plate.texture != null:
		_plate.size = _plate.texture.get_size()
	var ct: Texture2D = tex(key + "_cover") if own else tex("parade_cover")
	_cover.texture = ct
	_cover_fill.texture = null
	if ct == null:
		return
	_cover.size = ct.get_size()
	_cover_y = COVER_TOP - used_of(ct).position.y
	# the wall's body, cut out as its own picture (an AtlasTexture won't tile in a TextureRect): not the coping,
	# nothing caught on it
	var y0: int = int(ct.get_height() * 0.72)
	_cover_fill.texture = ImageTexture.create_from_image(ct.get_image().get_region(Rect2i(0, y0, ct.get_width(), ct.get_height() - y0)))
	_cover_fill.size = Vector2(ct.get_width(), H)


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
	if placing:
		return                                   # F3's on: the fight holds still
	if sim.runs_total != _run_seen:
		_run_seen = sim.runs_total                # a new run: nobody up, nothing to drop
		_kills_seen = int(m["kills"])
		_hp_seen = sim.hp
		_duck = 0.0
		_duck_t = 0.0
		for f in _figs:
			f["state"] = ""
			f["rect"].visible = false
	var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	# the site's own art, its zone's gang, the head when he's out
	var site: Dictionary = Data.TIERS[int(m["tier"])]
	if site_key(str(site["name"])) != _site_key:
		_site(site_key(str(site["name"])))
	_zone_key = ZONE_KEYS[mini(int(site["zone"]), ZONE_KEYS.size() - 1)]
	_boss_key = site_key(str(m["boss"]["name"])) if boss_on else ""
	var gang: int = 0
	if int(m["remaining"]) > 0:
		gang = 1 if boss_on else mini(int(m["remaining"]), maxi(1, sim.contact(m["t"])))
	_on_you = mini(gang, SLOTS.size())
	_firing = _on_you > 0
	# what's on them, and on you: the chips' own thresholds (sim.dots_on_them, run.gd's "On you")
	var dots: Dictionary = m.get("dots", {})
	var mine: Dictionary = m.get("my_dots", {})
	var fighting: bool = int(m["remaining"]) > 0
	for el in ["fire", "poison", "bleed"]:
		_them_fx[el] = fighting and float(dots.get(el, 0.0)) > 0.5
		_you_fx[el] = float(mine.get(el, 0.0)) > 0.5
	_them_fx["frost"] = fighting and float(m.get("chill_t", 0.0)) > 0.0
	_them_fx["shock"] = fighting and float(m.get("shock_t", 0.0)) > 0.0
	# a kill: the one in front goes down
	if int(m["kills"]) > _kills_seen:
		var ups: Array = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] in ["pop", "up"])
		for n in range(mini(int(m["kills"]) - _kills_seen, ups.size())):
			var pick: int = ups[randi() % ups.size()]      # any of them, not the first every time (Matt, 13 Oct)
			ups.erase(pick)
			_set_state(pick, "down")
		_kills_seen = int(m["kills"])
	# a hit on you: the jolt and the red, a hundredth of your HP or more
	if _hp_seen >= 0.0 and sim.hp < _hp_seen - sim.max_hp() * 0.01:
		_jolt = JOLT_S
		_red_a = 1.0
		if sim.hp < _hp_seen - sim.max_hp() * 0.05 and _duck_t <= 0.0:
			_duck_t = randf_range(0.6, 1.0)          # a big one: down behind the wall
	_hp_seen = sim.hp
	# your gun's rate, for the recoil and the marker
	var gun = sim.equipped["Primary"]
	_rof = maxf(0.5, minf(4.0, float(Items.base_of(gun).get("rof", 1.0)) * sim.pace())) if gun != null else 1.0
	var ht: Texture2D = tex_of(["hands_" + _hands_kind(gun), "hands_revolver"]) if gun != null else null
	if ht != null and Items.is_melee(gun) and tex("hands_" + _hands_kind(gun)) == null:
		ht = null                                  # no revolver for a hammer: nothing till its hands are drawn
	var melee: bool = ht != null and Items.is_melee(gun)
	if ht != _hands.texture or melee != _melee:
		_hands.texture = ht
		_melee = melee
		if ht != null:
			_hands.size = ht.get_size()
			_hands_at = HANDS_CORNER - used_of(ht).end * HANDS_SCALE
		_set_swing_parts(ht)
	_hands.visible = ht != null
	# the search: the view pans along to the crates in the street, the next three
	var searching: bool = int(m["remaining"]) <= 0 and m["cleared"]
	_pan_to = PAN if searching else 0.0
	var cs: Array = m.get("crates", [])
	var ci: int = int(m.get("crate_i", 0))
	for k in range(_crates.size()):
		var j: int = ci + k
		var c: TextureRect = _crates[k]
		c.visible = searching and j < cs.size() and not cs[j].get("passed", false)
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
		if f["state"] in ["pop", "up"] and up > _on_you:
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
				if f["fire_t"] > 0.0:
					f["fire_t"] -= fdt
				r.texture = _fig_tex(f, "fire" if f["fire_t"] > 0.0 else "stand")
			"down":
				lift = -24.0 * clampf(f["t"] / DOWN_S, 0.0, 1.0)
				r.modulate.a = 1.0 - clampf((f["t"] - DOWN_S * 0.5) / (DOWN_S * 0.5), 0.0, 1.0)
				if f["t"] >= DOWN_S:
					_set_state(k, "")
		if r.texture != null:
			r.size = r.texture.get_size()
		r.scale = Vector2(slot["scale"], slot["scale"])
		var u: Rect2 = used_of(r.texture)                # the feet where the picture's drawn part ends, centred on what's drawn
		var anchor: Vector2 = Vector2(u.get_center().x, u.end.y) if u.size.y > 0.0 else Vector2(r.size.x * 0.5, r.size.y)
		r.position = slot["foot"] - anchor * slot["scale"] + Vector2(_pan * -0.6, lift - DUCK_SCENE * _duck)
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
				p.position = r.position + Vector2(sz.x * 0.5, sz.y * (0.55 if el == "fire" else 0.45))
	# ducking: now and then under fire, and on a big hit - the wall comes up, the gun goes down, no shots
	if _firing:
		_duck_next -= dt
		if _duck_next <= 0.0 and _duck_t <= 0.0:
			_duck_t = randf_range(0.7, 1.3)
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
	_cover_fill.position = _cover.position + Vector2(0, _cover.size.y - 1)
	# the crates ride the street as it pans in (the review: they stood still while the plate slid under them)
	for k in range(_crates.size()):
		for n in [_crates[k], _shadows[k]]:
			if n.has_meta("at"):
				n.position = n.get_meta("at") + Vector2(PAN - _pan, 0)
	# the glass: over the crate being opened, bobbing a little, circling as it looks
	if _glass.visible:
		var c0: TextureRect = _crates[0]
		var top: Vector2 = c0.position + Vector2(c0.size.x * c0.scale.x * 0.5, 0)
		_glass.position = top + Vector2(10.0 + 6.0 * cos(_fx_t * 2.2), -30.0 + 4.0 * sin(_fx_t * 3.1)) - Vector2(Glass.R, Glass.R)
		_glass.p = _search_p
		_glass.queue_redraw()
	# your gun: a kick back at its rate while there's someone to shoot, the marker on the one you're hitting
	_shot_t -= dt
	if _firing and _shot_t <= 0.0 and _duck < 0.2 and _swing < 0.0:
		_shot_t = 1.0 / _rof
		var ups: Array = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] == "up")
		var k: int = ups[randi() % ups.size()] if not ups.is_empty() else -1     # whoever's in your sights, not the same one every time
		if _melee:
			_swing = 0.0                             # the hit lands on the chop (_swing_step)
			_swing_len = clampf(0.75 / _rof, 0.24, 0.42)
			_swing_k = k
		else:
			_recoil = 0.08
			if k >= 0:
				_land_hit(k)
	_swing_step(dt)
	_recoil = maxf(0.0, _recoil - dt)
	_hands.position = _hands_at + Vector2(10, 12) * (_recoil / 0.08) + Vector2(0, DUCK_HANDS * _duck) + jolt + _swing_off * HANDS_SCALE
	_marker_t -= dt
	_marker.visible = _marker_t > 0.0
	_fx_t += dt
	for el in _edges:
		var e: TextureRect = _edges[el]
		var target: float = (0.55 + 0.25 * sin(_fx_t * 3.0 + float(FX_ELEMENTS.find(el)))) if _you_fx.get(el, false) else 0.0
		e.modulate.a = move_toward(e.modulate.a, target, dt * 2.5)
	_red_a = maxf(0.0, _red_a - dt / RED_S)
	_red.modulate.a = _red_a


## A hit on figure k: the marker on them, their flash, and the number's cue (run.gd's _on_view_shot).
func _land_hit(k: int) -> void:
	var r: TextureRect = _figs[k]["rect"]
	var u: Rect2 = used_of(r.texture)
	if u.size.y <= 0.0:
		u = Rect2(Vector2.ZERO, r.size)
	var hit: Vector2 = r.position + Vector2(u.get_center().x, u.position.y + u.size.y * randf_range(0.15, 0.45)) * r.scale.x
	_marker.position = hit - Vector2(12, 12)
	_marker_t = 0.12
	_figs[k]["hit_t"] = 0.08
	shot_fired.emit(hit)


## A swing's frame: wind up, chop, settle; the hit on the chop - on the one it was at, or whoever's up if they've gone.
func _swing_step(dt: float) -> void:
	var arm: Control = _hand_r if _hand_r.visible else _hands
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
			k = ups[0] if not ups.is_empty() else -1
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
	if _hand_r.visible:
		return _hands.get_transform() * (_hand_r.get_transform() * (sp["tip"] - Vector2(sp["x"], 0)))
	return _hands.get_transform() * sp["tip"]


## A melee picture in two where a clean column parts the off hand from the weapon's (fewer than 1 in 50 of its rows
## drawn on), the arm swinging round its forearm; with no clean column the whole picture swings. A gun: none of it.
func _set_swing_parts(t: Texture2D) -> void:
	_swing = -1.0
	_swing_off = Vector2.ZERO
	_trail.clear()
	_hands.rotation = 0.0
	_hand_r.rotation = 0.0
	var split := false
	if _melee and t != null:
		var sp: Dictionary = _split_of(t)
		_hands.pivot_offset = sp["pivot"]
		if sp["x"] > 0:
			split = true
			var w: float = t.get_size().x
			var h: float = t.get_size().y
			var al := AtlasTexture.new()
			al.atlas = t
			al.region = Rect2(0, 0, sp["x"], h)
			var ar := AtlasTexture.new()
			ar.atlas = t
			ar.region = Rect2(sp["x"], 0, w - sp["x"], h)
			_hand_l.texture = al
			_hand_l.size = al.region.size
			_hand_l.position = Vector2.ZERO
			_hand_r.texture = ar
			_hand_r.size = ar.region.size
			_hand_r.position = Vector2(sp["x"], 0)
			_hand_r.pivot_offset = sp["pivot"] - Vector2(sp["x"], 0)
	_hand_l.visible = split
	_hand_r.visible = split
	_hands.self_modulate.a = 0.0 if split else 1.0    # its two halves draw it


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
		var tr: Array = view._trail
		for i in range(1, tr.size()):
			var a: float = 1.0 - float(tr[i][1]) / view.STREAK_S
			draw_line(tr[i - 1][0], tr[i][0], Color(1, 1, 1, 0.45 * a), lerpf(2.0, 12.0, a), true)


## Where a hit of yours shows its number, in the frame's space: on one that's up, about its chest; with nobody up,
## the street's middle (13 Oct, Matt: the numbers off the chips, on the one you're hitting).
func hit_spot() -> Vector2:
	var ups: Array = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] in ["pop", "up"])
	if ups.is_empty():
		return Vector2(randf_range(300.0, 500.0), randf_range(130.0, 160.0))
	var r: TextureRect = _figs[ups[randi() % ups.size()]]["rect"]
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
	return _firing and _duck < 0.2 and _figs.any(func(f): return f["state"] == "up")


## Whether there's a fight on in the frame at all (down behind the wall counts): the run screen holds your hits for it.
func fighting() -> bool:
	return _firing and _figs.any(func(f): return f["state"] in ["pop", "up"])


## For the tests: what's up, the pan, the red.
func figures_up() -> int:
	var n := 0
	for f in _figs:
		if f["state"] in ["pop", "up"]:
			n += 1
	return n


func state() -> Dictionary:
	return {"on_you": _on_you, "up": figures_up(), "pan_to": _pan_to, "red": _red_a, "crates": _crates.filter(func(c): return c.visible).size(), "duck": _duck, "glass": _glass.visible, "search_p": _search_p}
