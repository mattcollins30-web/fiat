extends Control
## The run view (13 Oct, Matt; docs/design/fight_art.md, concept.md 22.3): a light-gun frame, Time Crisis not an FPS,
## across the run screen's fight and runner boxes. The site's plate; the gang popping up at three depths (far in a
## doorway, mid by the car, near and big), firing at you; the cover you're behind; your hands and gun bottom right.
## A hit jolts the frame and reddens its edges; a kill drops one; the search pans along to the crates. A visualiser
## of what the sim already does - nothing in it changes a number. The slice: the Parade's test art on every site.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Items := preload("res://scripts/sim/items.gd")
const CratesPanel := preload("res://scripts/ui/crates_panel.gd")

const W := 588
const H := 262
const DIR := "res://art/fight_test/%s.png"
## The three depths: where a figure stands (its top-left in the frame), its scale, how lit.
const SLOTS := [
	{"at": Vector2(300, 92), "scale": 0.62, "lit": 0.9},     # mid: by the car - the first on you
	{"at": Vector2(440, 50), "scale": 0.95, "lit": 1.0},     # near: close, popping up
	{"at": Vector2(70, 95), "scale": 0.42, "lit": 0.75},     # far: in a doorway
]
const PLATE_AT := Vector2(-50, -20)       # the plate's crop for the fight; the search pans a further PAN along
const PAN := 50.0
const COVER_Y := H - 72
const HANDS_AT := Vector2(W - 235, H - 178)
const HANDS_SCALE := 0.95
const DOWN_S := 0.7                       # a kill's fall
const POP_S := 0.25                       # a figure popping up from behind
const JOLT_S := 0.2
const RED_S := 0.45

static var _tex := {}

var _plate: TextureRect
var _figs: Array = []                     # {rect, state: "", t, fire_t, next_fire}
var _crates: Array = []                   # the crates in the street while searching
var _cover: TextureRect
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

## A texture by name from the test art: imported if the editor's seen it, else read straight off the disk.
static func tex(name: String) -> Texture2D:
	if _tex.has(name):
		return _tex[name]
	var path: String = DIR % name
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			img.generate_mipmaps()
			t = ImageTexture.create_from_image(img)
	_tex[name] = t
	return t


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
		var c := _rect(null)
		c.visible = false
		_crates.append(c)
	# the figures stand in depth order: the far one behind, the near one in front
	move_child(_figs[2]["rect"], _plate.get_index() + 1)
	_cover = _rect(tex("parade_cover"))
	_cover.position = Vector2(PLATE_AT.x, COVER_Y)
	_hands = _rect(tex("hands_revolver"))
	_hands.scale = Vector2(HANDS_SCALE, HANDS_SCALE)
	_hands.position = HANDS_AT
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
	_marker = UI.label(self, Rect2(0, 0, 24, 24), "✕", "Bold", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(_marker)
	_marker.visible = false


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
	_hands.visible = gun != null and not Items.is_melee(gun)     # the slice has a revolver's hands; melee shows none yet
	# the search: the view pans along to the crates in the street, the next three
	var searching: bool = int(m["remaining"]) <= 0 and m["cleared"]
	_pan_to = PAN if searching else 0.0
	var cs: Array = m.get("crates", [])
	var ci: int = int(m.get("crate_i", 0))
	for k in range(_crates.size()):
		var j: int = ci + k
		var c: TextureRect = _crates[k]
		c.visible = searching and j < cs.size() and not cs[j].get("passed", false)
		if c.visible:
			var pic: Array = CratesPanel.crate_texture(str(cs[j]["key"]), false)
			c.texture = pic[0]
			c.modulate = pic[1]
			var s: float = [1.0, 0.8, 0.65][k]
			c.size = c.texture.get_size() if c.texture != null else Vector2(64, 64)
			c.scale = Vector2(s, s)
			c.position = [Vector2(200, 150), Vector2(320, 140), Vector2(400, 132)][k]


func _set_state(k: int, s: String) -> void:
	var f: Dictionary = _figs[k]
	f["state"] = s
	f["t"] = 0.0
	var r: TextureRect = f["rect"]
	r.visible = s != ""
	r.texture = tex("gang_down") if s == "down" else tex("gang_stand")
	r.modulate.a = 1.0


func _process(dt: float) -> void:
	if not _shown():
		return                                   # off the run screen: nothing ticks (the review: a run ended mid-fight kept its flames going)
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
		var slot: Dictionary = SLOTS[k]
		var r: TextureRect = f["rect"]
		var fdt: float = dt * (FROST_SLOW if _them_fx.get("frost", false) and f["state"] in ["pop", "up"] else 1.0)
		f["t"] += fdt
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
				lift = 40.0 * (1.0 - clampf(f["t"] / POP_S, 0.0, 1.0))
				if f["t"] >= POP_S:
					f["state"] = "up"
			"up":
				f["next_fire"] -= fdt
				if f["next_fire"] <= 0.0:
					f["fire_t"] = 0.25
					f["next_fire"] = randf_range(0.8, 2.2)
				if f["fire_t"] > 0.0:
					f["fire_t"] -= fdt
				r.texture = tex("gang_fire") if f["fire_t"] > 0.0 else tex("gang_stand")
			"down":
				lift = -24.0 * clampf(f["t"] / DOWN_S, 0.0, 1.0)
				r.modulate.a = 1.0 - clampf((f["t"] - DOWN_S * 0.5) / (DOWN_S * 0.5), 0.0, 1.0)
				if f["t"] >= DOWN_S:
					_set_state(k, "")
		if r.texture != null:
			r.size = r.texture.get_size()
		r.scale = Vector2(slot["scale"], slot["scale"])
		r.position = slot["at"] + Vector2(_pan * -0.6, lift - DUCK_SCENE * _duck)
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
			if want:
				var s: float = SLOTS[k]["scale"]
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
	_cover.position = Vector2(PLATE_AT.x - _pan * 1.4, COVER_Y - DUCK_COVER * _duck) + jolt * 1.5
	for c in _crates:
		pass
	# your gun: a kick back at its rate while there's someone to shoot, the marker on the one you're hitting
	_shot_t -= dt
	if _firing and _shot_t <= 0.0 and _duck < 0.2:
		_shot_t = 1.0 / _rof
		_recoil = 0.08
		var ups: Array = range(SLOTS.size()).filter(func(k): return _figs[k]["state"] == "up")
		if not ups.is_empty():
			var k: int = ups[randi() % ups.size()]      # whoever's in your sights, not the same one every time
			var r: TextureRect = _figs[k]["rect"]
			_marker.position = r.position + Vector2(r.size.x * r.scale.x * 0.5 - 12, r.size.y * r.scale.y * randf_range(0.15, 0.45))
			_marker_t = 0.12
			_figs[k]["hit_t"] = 0.08
	_recoil = maxf(0.0, _recoil - dt)
	_hands.position = HANDS_AT + Vector2(10, 12) * (_recoil / 0.08) + Vector2(0, DUCK_HANDS * _duck) + jolt
	_marker_t -= dt
	_marker.visible = _marker_t > 0.0
	_fx_t += dt
	for el in _edges:
		var e: TextureRect = _edges[el]
		var target: float = (0.55 + 0.25 * sin(_fx_t * 3.0 + float(FX_ELEMENTS.find(el)))) if _you_fx.get(el, false) else 0.0
		e.modulate.a = move_toward(e.modulate.a, target, dt * 2.5)
	_red_a = maxf(0.0, _red_a - dt / RED_S)
	_red.modulate.a = _red_a


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


## For the tests: what's up, the pan, the red.
func figures_up() -> int:
	var n := 0
	for f in _figs:
		if f["state"] in ["pop", "up"]:
			n += 1
	return n


func state() -> Dictionary:
	return {"on_you": _on_you, "up": figures_up(), "pan_to": _pan_to, "red": _red_a, "crates": _crates.filter(func(c): return c.visible).size(), "duck": _duck}
