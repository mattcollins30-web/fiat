extends Control
## The slice's pause (BUILD72): Esc or Start holds the world still and shows Resume, the controls (board C: keyboard
## and mouse, gamepad and Steam Deck) and Back to the title. Nothing the slice does is kept, so the title is one press.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const SliceBridge := preload("res://slice/bridge.gd")
const SliceTuning := preload("res://slice/tuning.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

signal resumed
signal to_title
signal hp_x_changed(x: float)            # the test setting: the men's HP times this, live
signal dmg_x_changed(x: float)           # (build 76) the test setting: their damage a round times this, live

const HP_STEPS := [0.06, 0.1, 0.04]    # "Gang HP" (10 Nov, by rounds to kill: about 12 of the rifle's a man at level 12 (MAN_HP_X, the start), about 20, about 8)
const DMG_STEPS := [2.0, 3.0, 1.0]     # "Gang damage" (10 Nov, its own again): twice the game's (THEIR_DMG_X, the start), three times, the game's

## Board C's two columns, as drawn: what it does, the key.
const KEYS := [["Move", "W A S D"], ["Aim", "Mouse"], ["Fire", "Left button"], ["Aim down sights", "Right button, held"], ["Dodge", "Space"], ["Swap gun", "Mouse wheel or V"], ["Reload", "R"],
		["Skills", "Q E C"], ["Med from the rig", "1 2 3 4"], ["Search, pick up", "F, held"], ["Get out", "X, held"], ["Kit and runner", "Tab"], ["Pause", "Esc"]]
const PAD := [["Move", "Left stick"], ["Aim", "Right stick, with a lock-on"], ["Fire", "Right trigger"], ["Swap gun", "Y"], ["Reload", "X"],
		["Skills", "LB, RB, LT"], ["Med from the rig", "D-pad"], ["Search, pick up", "A, held"], ["Get out", "B, held"], ["Kit and runner", "Back"], ["Pause", "Start"]]
const COL_W := 560.0
const ROW_H := 42.0
const ROW_GAP := 9.0
const CARD_W := 2.0 * COL_W + 3.0 * 40.0
const HEAD := 112.0                    # the title, the sub line
const FOOT := 124.0                    # the buttons, the test settings' head over theirs

var _card: Panel
var _title: Label
var _sub: Label
var _heads: Array = []
var _rows: Array = []                 # [[what, key]] labels
var buttons: Array = []               # Resume, Back to the title, Gang HP, Gang damage
var hp_x := 1.0
var dmg_x := 1.0
var _test: Label


func _init() -> void:
	size = Vector2(1920, 1080)                 # laid out by layout(), not by anchors (the screen's size set by hand)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var h: float = HEAD + 40.0 + KEYS.size() * (ROW_H + ROW_GAP) + FOOT
	_card = UI.panel(self, Rect2(0, 0, CARD_W, h), UI.box(Pal.PANEL, 10, 1, Pal.CARD_LINE))
	_title = UI.label(_card, Rect2(40, 28, CARD_W - 80, 40), "Paused", "Bold", 30, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(_card, Rect2(40, 70, CARD_W - 80, 26), "The ARPG slice · nothing here is kept", "Regular", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for c in range(2):
		var x: float = 40.0 + c * (COL_W + 40.0)
		var head := UI.label(_card, Rect2(x, HEAD, COL_W, 22), "KEYBOARD AND MOUSE" if c == 0 else "GAMEPAD AND STEAM DECK", "SemiBold", 14, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.track(head, 1)
		_heads.append(head)
		var list: Array = KEYS if c == 0 else PAD
		for k in range(list.size()):
			var y: float = HEAD + 34.0 + k * (ROW_H + ROW_GAP)
			var row := UI.panel(_card, Rect2(x, y, COL_W, ROW_H), UI.box(Pal.CARD, 4))
			var what := UI.label(row, Rect2(14, 0, COL_W - 28, ROW_H), str(list[k][0]), "Regular", 18, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			var key := UI.label(row, Rect2(14, 0, COL_W - 28, ROW_H), str(list[k][1]), "Bold", 18, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
			_rows.append([what, key])
	var by: float = h - 76.0
	for k in range(2):
		var b := UI.button(_card, Rect2(40 + k * 280, by, 260, 52), k == 0)
		b.text = "Resume" if k == 0 else "Back to the title"
		b.pressed.connect(_on_resume if k == 0 else _on_title)
		buttons.append(b)
	var tx: float = CARD_W - 40.0 - 2.0 * 270.0 - 20.0
	for k in range(2):
		var tb := UI.button(_card, Rect2(tx + k * 290.0, by, 270, 52), false)
		tb.pressed.connect(_on_hp_x if k == 0 else _on_dmg_x)
		buttons.append(tb)
	_test = UI.head(_card, Rect2(tx, by - 30, 560, 22), "Test settings")
	show_hp_x(SliceTuning.MAN_HP_X)
	show_dmg_x(SliceTuning.THEIR_DMG_X)
	visible = false


## The men's HP as the slice has it now, on the button.
func show_hp_x(x: float) -> void:
	hp_x = x
	buttons[2].text = "Gang HP %s" % hp_words(x)
	_show_damage()


## ×2, ×0.06: whole, or the knobs' own hundredths (the HUD's x_words).
static func hp_words(x: float) -> String:
	if is_equal_approx(x, roundf(x)):
		return "×%d" % roundi(x)
	return "×%s" % str(snappedf(x, 0.1 if x >= 2.0 else 0.01))


## The knob's step (build 76: their damage a round times this). The button reads the figure in force, the same as the
## HUD's top line (10 Nov: the step itself; round 6's tie to the gang HP knob is gone).
func show_dmg_x(x: float) -> void:
	dmg_x = x
	_show_damage()


func _show_damage() -> void:
	if buttons.size() > 3:
		buttons[3].text = "Gang damage %s" % hp_words(SliceBridge.their_x({"their_dmg_x": dmg_x, "man_hp_x": hp_x}))


func _on_dmg_x() -> void:
	var i: int = DMG_STEPS.find(dmg_x)
	var x: float = DMG_STEPS[(i + 1) % DMG_STEPS.size()]
	show_dmg_x(x)
	dmg_x_changed.emit(x)


func _on_hp_x() -> void:
	var i: int = HP_STEPS.find(hp_x)
	var x: float = HP_STEPS[(i + 1) % HP_STEPS.size()]
	show_hp_x(x)
	hp_x_changed.emit(x)


func layout(s: Vector2) -> void:
	size = s
	_card.position = Vector2(roundf((s.x - _card.size.x) / 2.0), roundf((s.y - _card.size.y) / 2.0))


func open() -> void:
	visible = true
	layout(get_viewport_rect().size if is_inside_tree() else size)
	if is_inside_tree():
		buttons[0].grab_focus()


func close() -> void:
	visible = false


func _on_resume() -> void:
	close()
	resumed.emit()


func _on_title() -> void:
	close()
	to_title.emit()


func text_nodes() -> Array:
	var out: Array = [_title, _sub, _test] + _heads + buttons
	for r in _rows:
		out.append_array(r)
	return out


## Each row's two labels, for the fit checks' line pairs (what it does and its key share a row).
func line_pairs() -> Array:
	return _rows


func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size)
