extends Control
## The slice's level picker (build 76): opened from the title, before the fight. The car park at a level picked from a
## row either side of the default - the camp's reach (the furthest level it's cleared), or level 12 on a fresh camp (no
## runner, or nothing cleared). The row starts no lower than the first level whose fight differs: under it every level
## plays the car park's first depth (round 5's review). A level's button starts the slice there; Back to the title (or
## Esc) gives the title back.

const SliceTuning := preload("res://slice/tuning.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")

signal picked(level: int)
signal to_title

const LV_W := 112.0                   # a level's button
const LV_H := 84.0
const LV_GAP := 14.0
const PAD := 40.0
const HEAD := 128.0                   # the kicker, the title, the sub line

var levels: Array = []                # the levels offered, low to high
var default_level := 0
var buttons: Array = []               # a button a level, then Back to the title
var _card: Panel
var _kicker: Label
var _title: Label
var _sub: Label
var _mark: Label                      # under the default's button: "Reach" or "Fresh camp"


## A fresh camp: no runner, or a runner who's cleared nothing yet.
static func is_fresh(sim_v) -> bool:
	return sim_v == null or not Array(sim_v.best_depth).any(func(d): return int(d) > 0)


## The first level whose fight differs from the one below it: the site's depth is 1 up to here (Sim.tier_depth), so
## levels 1 to this one all play the same car park.
static func first_level() -> int:
	return Data.TIERS.size() - Data.OUTSKIRTS_SITES


## The default level: the camp's reach, the furthest it's cleared (Sim.deepest_cleared_level), no lower than
## first_level(); level 12 on a fresh camp.
static func default_for(sim_v) -> int:
	if is_fresh(sim_v):
		return SliceTuning.H_LEVEL_FRESH
	return clampi(int(sim_v.deepest_cleared_level()), first_level(), Data.MAX_LEVEL)


## The levels either side of the default, H_LEVEL_STEPS each way, shifted to stay in first_level()..MAX_LEVEL (always
## the full row).
static func levels_round(def: int) -> Array:
	var n: int = 2 * SliceTuning.H_LEVEL_STEPS + 1
	var lo: int = clampi(def - SliceTuning.H_LEVEL_STEPS, first_level(), maxi(first_level(), Data.MAX_LEVEL - n + 1))
	var out: Array = []
	for k in range(n):
		out.append(lo + k)
	return out


func _init() -> void:
	size = Vector2(1920, 1080)                 # laid out by layout(), not by anchors (the screen's size set by hand)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(Pal.BG, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)


## The card for the camp's runner (`cls_v`, `level_v`; `fresh` with no runner) and its default level.
func setup(def: int, cls_v: String, level_v: int, fresh: bool) -> void:
	default_level = def
	levels = levels_round(def)
	var n: int = levels.size()
	var w: float = 2.0 * PAD + n * LV_W + (n - 1) * LV_GAP
	var h: float = HEAD + LV_H + 34.0 + 30.0 + 52.0 + PAD
	_card = UI.panel(self, Rect2(0, 0, w, h), UI.box(Pal.PANEL, 10, 1, Pal.CARD_LINE))
	_kicker = UI.label(_card, Rect2(PAD, 30, w - 2.0 * PAD, 20), "THE ARPG SLICE", "SemiBold", 14, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(_kicker, 1)
	_title = UI.label(_card, Rect2(PAD, 52, w - 2.0 * PAD, 40), "Pick the car park's level", "Bold", 30, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	var who: String = "A fresh camp: a level %d %s" % [level_v, cls_v] if fresh else "%s, level %d · your reach, level %d" % [cls_v, level_v, def]
	_sub = UI.label(_card, Rect2(PAD, 94, w - 2.0 * PAD, 24), "", "Regular", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.fit(_sub, [who, "Your reach, level %d" % def if not fresh else "A fresh camp"])
	for k in range(n):
		var lv: int = int(levels[k])
		var b := UI.button(_card, Rect2(PAD + k * (LV_W + LV_GAP), HEAD, LV_W, LV_H), lv == def)
		b.text = str(lv)
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(_on_level.bind(lv))
		b.tooltip_text = "Level %d" % lv
		buttons.append(b)
		if lv == def:
			_mark = UI.label(_card, Rect2(b.position.x - 20.0, HEAD + LV_H + 8.0, LV_W + 40.0, 22), "Fresh camp" if fresh else "Reach", "SemiBold", 14, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, false)
	var back := UI.button(_card, Rect2(PAD, h - PAD - 52.0, 260, 52), false)
	back.text = "Back to the title"
	back.pressed.connect(_on_title)
	buttons.append(back)
	layout(get_viewport_rect().size if is_inside_tree() else size)


func _ready() -> void:
	layout(get_viewport_rect().size)
	var i: int = levels.find(default_level)
	if i >= 0:
		buttons[i].grab_focus()


func layout(s: Vector2) -> void:
	size = s
	if _card != null:
		_card.position = Vector2(roundf((s.x - _card.size.x) / 2.0), roundf((s.y - _card.size.y) / 2.0))


func _unhandled_input(event: InputEvent) -> void:
	var press: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE) \
			or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	if press and visible:
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		_on_title()


func _on_level(lv: int) -> void:
	picked.emit(lv)


func _on_title() -> void:
	to_title.emit()


## The default level's button.
func default_button() -> Button:
	var i: int = levels.find(default_level)
	return buttons[i] if i >= 0 else null


func text_nodes() -> Array:
	return [_kicker, _title, _sub, _mark] + buttons


func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size)
