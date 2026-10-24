extends Control
## The fight's skills (24 Oct, milestone 8; the canvas "Skills in the fight", Matt: "this spot"): the energy bar under
## Your HP and the three picture buttons at the frame's foot, between the bars and the hands. On a button: the
## picture, the cost under it in the energy colour (red when it can't be met, the picture grey), a pip - "Auto" or
## "Off" - and the cooldown as a dark sweep with its seconds. Press fires it; right-click switches its auto. The name,
## line, chip and rule on hover. A cast: the button lights and its name stands over the frame for a beat.
## Laid over the frame in the run's own space; the run places it (run.gd) and feeds it each refresh.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")

const BTN := 76
const GAP := 10
const PIC := 56
const BAR_W := 300
const BAR_H := 24
const WORD_S := 1.2                    # the skill's name over the frame, seconds
const FLASH_S := 0.35

var sim
var energy_track: Panel
var _energy_fill: Panel
var energy_text: Label
var buttons: Array = []                # {btn, pic, sweep, secs, cost, pip, id}
var word: Label
var _word_until := 0                   # msec: the name over the frame shows till then
var _flash_until := 0
var _flash_slot := -1
var _cast_seen := -1
static var _PLAIN: StyleBoxFlat = UI.box(Color(Pal.BG, 0.86), 8, 1, Pal.CARD_LINE)
static var _LIT: StyleBoxFlat = UI.box(Color(Pal.BG, 0.86), 8, 2, Pal.TEXT)
static var _pics := {}


## A dark wedge over a picture: the share of the cooldown left, swept clockwise from the top.
class Sweep extends Control:
	var share := 0.0
	func _draw() -> void:
		if share <= 0.0:
			return
		if share >= 0.999:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.045, 0.05, 0.72))     # whole: a wedge of a full turn won't triangulate (the review)
			return
		var c := size / 2.0
		var r: float = maxf(size.x, size.y)
		var pts := PackedVector2Array([c])
		var from := -PI / 2.0 + TAU * (1.0 - share)
		var steps := 24
		for k in range(steps + 1):
			var a: float = from + (TAU * share) * float(k) / float(steps)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_polygon(pts, PackedColorArray([Color(0.04, 0.045, 0.05, 0.72)]))


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_track = UI.panel(self, Rect2(0, 0, BAR_W, BAR_H), UI.box(Pal.TRACK, 4))
	energy_track.mouse_filter = Control.MOUSE_FILTER_PASS
	energy_track.clip_contents = true
	_energy_fill = UI.panel(energy_track, Rect2(0, 0, BAR_W, BAR_H), UI.box(Pal.ENERGY, 4))
	_energy_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_text = UI.label(energy_track, Rect2(0, 0, BAR_W, BAR_H), "", "Medium", 17, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(energy_text)
	energy_track.tooltip_text = "What skills cost. Refills 4 a second, a little quicker with pace, and fills at the start of every fight."
	for i in range(Data.SKILL_SLOTS):
		var b := Button.new()
		b.size = Vector2(BTN, BTN)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", _PLAIN)
		b.add_theme_stylebox_override("hover", UI.box(Color(Pal.SELECT, 0.92), 8, 1, Pal.TEXT_3))
		b.add_theme_stylebox_override("pressed", UI.box(Color(Pal.BUTTON_PRESS, 0.92), 8, 1, Pal.TEXT_3))
		b.add_theme_stylebox_override("disabled", UI.box(Color(Pal.BG, 0.86), 8, 1, Pal.CARD_LINE))
		add_child(b)
		var pic := TextureRect.new()
		pic.position = Vector2((BTN - PIC) / 2.0, 4)
		pic.size = Vector2(PIC, PIC)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pic)
		var sweep := Sweep.new()
		sweep.position = pic.position
		sweep.size = pic.size
		sweep.clip_contents = true
		sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sweep)
		var secs := UI.label(b, Rect2(pic.position, pic.size), "", "SemiBold", 24, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		UI.shadow(secs)
		var cost := UI.label(b, Rect2(0, BTN - 16, BTN, 14), "", "SemiBold", 13, Pal.ENERGY, HORIZONTAL_ALIGNMENT_CENTER)
		var pip := UI.label(b, Rect2(BTN - 34, 3, 30, 13), "", "SemiBold", 11, Pal.GOOD, HORIZONTAL_ALIGNMENT_RIGHT)
		var slot := i
		b.pressed.connect(func(): _press(slot))
		b.gui_input.connect(func(ev): _input_on(slot, ev))
		buttons.append({"btn": b, "pic": pic, "sweep": sweep, "secs": secs, "cost": cost, "pip": pip, "id": ""})
	word = UI.label(self, Rect2(0, 0, 10, 48), "", "SemiBold", 40, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(word)
	word.visible = false


## Laid out in a frame `frame` wide and `frame_h` tall: the bar at `bar_at`, the buttons from `btn_x` at the foot.
func lay_out(frame: Vector2, bar_at: Vector2, btn_x: float) -> void:
	size = frame
	energy_track.position = bar_at
	for i in range(buttons.size()):
		buttons[i]["btn"].position = Vector2(btn_x + i * (BTN + GAP), frame.y - 8 - BTN)
	word.position = Vector2(0, 118)
	word.size = Vector2(frame.x, 48)


## Whether this run has skills to show: a learnt one in a slot (a class change leaves another's slots, never shown).
static func wanted(s) -> bool:
	return s != null and s.on_mission() and s.skill_slots.any(func(id): return str(id) != "" and s.skill_known(str(id)))


## Whether the bar and the buttons show now: on a fight (the search's bar takes the frame's foot between gangs).
static func showing(s) -> bool:
	return wanted(s) and int(s.mission["remaining"]) > 0


func show_state(s) -> void:
	sim = s
	visible = showing(s)
	if not visible:
		return
	var m: Dictionary = sim.mission
	var e: float = sim.energy_now()
	var e_max: float = maxf(1.0, sim.max_energy())
	_energy_fill.size.x = roundf(BAR_W * clampf(e / e_max, 0.0, 1.0))
	energy_text.text = "Your energy %d / %d" % [int(floor(e)), int(round(e_max))]
	var sk: Dictionary = m.get("sk", {})
	var cast: int = int(sk.get("cast", 0))
	if _cast_seen >= 0 and cast > _cast_seen and sk.has("last"):
		var last_id: String = str(sk["last"]["id"])
		word.text = str(sim.skill(last_id).get("name", ""))
		_word_until = Time.get_ticks_msec() + int(WORD_S * 1000.0)
		_flash_slot = int(sk["last"]["slot"])
		_flash_until = Time.get_ticks_msec() + int(FLASH_S * 1000.0)
	_cast_seen = cast
	var now: int = Time.get_ticks_msec()
	word.visible = now < _word_until
	word.modulate.a = clampf(float(_word_until - now) / 300.0, 0.0, 1.0)
	for i in range(buttons.size()):
		var d: Dictionary = buttons[i]
		var id: String = str(sim.skill_slots[i])
		var b: Button = d["btn"]
		b.visible = id != "" and sim.skill_known(id)
		if not b.visible:
			continue
		var info: Dictionary = sim.skill(id)
		if d["id"] != id:
			d["id"] = id
			d["pic"].texture = picture(id)
		var wait: float = sim.skill_wait(i)
		var cd: float = maxf(0.01, sim.skill_cooldown(id))
		var cost: float = sim.skill_cost_now(i)
		var short: bool = cost > e + 0.001
		var known: bool = sim.skill_known(id)
		d["sweep"].share = clampf(wait / cd, 0.0, 1.0) if wait > 0.0 else 0.0
		d["sweep"].queue_redraw()
		d["secs"].text = ("%d" % int(ceil(wait))) if wait > 0.0 else ""
		d["cost"].text = "Free" if cost <= 0.0 else "%d" % int(cost)
		if d.get("short", null) != short:
			d["short"] = short
			d["cost"].add_theme_color_override("font_color", Pal.BAD if short else Pal.ENERGY)     # set on a change only: each is a theme change (the review)
		d["pic"].modulate = Color(0.45, 0.45, 0.45) if (short or not known) else Color.WHITE
		var auto_on: bool = bool(sim.skill_auto[i])
		if d.get("auto", null) != auto_on:
			d["auto"] = auto_on
			d["pip"].text = "Auto" if auto_on else "Off"
			d["pip"].add_theme_color_override("font_color", Pal.GOOD if auto_on else Pal.TEXT_3)
		var lit: bool = now < _flash_until and _flash_slot == i
		if d.get("lit", null) != lit:
			d["lit"] = lit
			b.add_theme_stylebox_override("normal", _LIT if lit else _PLAIN)
		b.tooltip_text = "%s\n%s\n%s\n%s\nRight-click to turn auto %s" % [info["name"], info["line"], chip(sim, id), Data.SKILL_RULES.get(str(info["rule"]), ""), "off" if auto_on else "on"]


## The slot's chip: "25 energy · 8 s" (skills.md §11), the cooldown as it runs for this runner.
static func chip(s, id: String) -> String:
	var info: Dictionary = s.skill(id)
	var cost: int = int(info.get("cost", 0))
	var cd: float = s.skill_cooldown(id)
	var cd_s: String = ("%d s" % int(round(cd))) if absf(cd - roundf(cd)) < 0.05 else ("%.1f s" % cd)
	return ("Free · " if cost <= 0 else "%d energy · " % cost) + cd_s


## A skill's picture: its painting once there (art/skills/<id>.png), else its glyph.
static func picture(id: String) -> Texture2D:
	if _pics.has(id):
		return _pics[id]
	var path := "res://art/skills/%s.png" % id
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else NodeGlyphs.texture(NodeGlyphs.SKILL.get(id, "star"))
	_pics[id] = tex
	return tex


func _press(i: int) -> void:
	if sim != null and sim.press_skill(i):
		_flash_slot = i
		_flash_until = Time.get_ticks_msec() + int(FLASH_S * 1000.0)


func _input_on(i: int, ev: InputEvent) -> void:
	if sim == null:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		sim.set_skill_auto(i, not bool(sim.skill_auto[i]))
		show_state(sim)
		accept_event()


## The words on it, for the fit check.
func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [energy_text]
	for d in buttons:
		if d["btn"].visible:
			out.append_array([d["cost"], d["pip"]])
			if d["secs"].text != "":
				out.append(d["secs"])
	if word.visible:
		out.append(word)
	return out


## Where the buttons are, in the run's space: the numbers keep off them.
func keep_rects() -> Array:
	var out: Array = []
	if not visible:
		return out
	for d in buttons:
		if d["btn"].visible:
			out.append(Rect2(position + d["btn"].position, d["btn"].size))
	return out
