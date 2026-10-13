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


## The red edges a hit brings: clear in the middle, red at the frame's edge.
func _vignette() -> Texture2D:
	var img := Image.create(W / 4, H / 4, false, Image.FORMAT_RGBA8)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var dx: float = absf(float(x) / (img.get_width() - 1) - 0.5) * 2.0
			var dy: float = absf(float(y) / (img.get_height() - 1) - 0.5) * 2.0
			var e: float = clampf((maxf(dx, dy) - 0.45) / 0.55, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.75, 0.1, 0.08, e * e * 0.85))
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
	if not visible:
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
		var slot: Dictionary = SLOTS[k]
		var r: TextureRect = f["rect"]
		f["t"] += dt
		if f["state"] in ["pop", "up"] and up > _on_you:
			_set_state(k, "")                        # the gang's thinned with no kill seen (a run ended, the way out)
			up -= 1
			continue
		var lift := 0.0
		match f["state"]:
			"pop":
				lift = 40.0 * (1.0 - clampf(f["t"] / POP_S, 0.0, 1.0))
				if f["t"] >= POP_S:
					f["state"] = "up"
			"up":
				f["next_fire"] -= dt
				if f["next_fire"] <= 0.0:
					f["fire_t"] = 0.25
					f["next_fire"] = randf_range(0.8, 2.2)
				if f["fire_t"] > 0.0:
					f["fire_t"] -= dt
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
		r.self_modulate = Color(lit, lit, lit, 1.0)
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
	_red_a = maxf(0.0, _red_a - dt / RED_S)
	_red.modulate.a = _red_a


## For the tests: what's up, the pan, the red.
func figures_up() -> int:
	var n := 0
	for f in _figs:
		if f["state"] in ["pop", "up"]:
			n += 1
	return n


func state() -> Dictionary:
	return {"on_you": _on_you, "up": figures_up(), "pan_to": _pan_to, "red": _red_a, "crates": _crates.filter(func(c): return c.visible).size(), "duck": _duck}
