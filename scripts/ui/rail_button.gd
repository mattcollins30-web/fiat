extends Button
## One room on the rail - 312 x 112. The room's name, two status lines, and a
## badge when the room wants a decision. The badge carries a word as well as a
## colour, so colour is never the only signal.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const BADGE_PAD := 14           # each side of the badge's word
const BADGE_RIGHT := Pal.RAIL_W - 20

var room: String
var _name: Label
var _status: Array[Label] = []
var _badge: Panel
var _badge_label: Label
var _selected := false


func _init(room_name: String) -> void:
	room = room_name
	size = Vector2(Pal.RAIL_W, Pal.RAIL_BTN_H)
	custom_minimum_size = size
	focus_mode = Control.FOCUS_ALL
	text = ""
	_style(false)
	_name = UI.label(self, Rect2(20, 8, 190, 40), room_name, "SemiBold", Pal.NAME, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(2):
		_status.append(UI.label(self, Rect2(20, 48 + i * 30, Pal.RAIL_W - 40, 30), "", "Regular",
				Pal.FLOOR, Pal.TEXT_2))
	_badge = UI.panel(self, Rect2(BADGE_RIGHT - 96, 10, 96, 36), UI.box(Pal.WARN, 18))
	_badge_label = UI.label(_badge, Rect2(0, 0, 96, 36), "", "SemiBold", Pal.FLOOR, Pal.ACCENT_TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, false)
	_badge.visible = false


func set_selected(on: bool) -> void:
	if on != _selected:
		_selected = on
		_style(on)


func show_status(d: Dictionary) -> void:
	_status[0].text = d.get("status1", "")
	_status[1].text = d.get("status2", "")
	var word: String = d.get("badge", "")
	_badge.visible = word != ""
	_badge_label.text = word
	if word != "":
		# the pill hugs its word, right-aligned; ui_check proves it clears the name
		var w := ceilf(UI.text_width(_badge_label, word)) + 2 * BADGE_PAD
		_badge.position.x = BADGE_RIGHT - w
		_badge.size.x = w
		_badge_label.size.x = w
		(_badge.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(d.get("badge_tone", "warn"))


func _style(on: bool) -> void:
	var bg := Pal.SELECT if on else Pal.PANEL
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb := UI.box(bg if state != "hover" or on else Pal.CARD, 8)
		if on:
			sb.border_width_left = 6
			sb.border_color = Pal.ACCENT
		add_theme_stylebox_override(state, sb)
	add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))


## Pixels between the end of the room's name and the badge, or INF with no badge.
func badge_gap() -> float:
	if not _badge.visible:
		return INF
	return _badge.position.x - (_name.position.x + UI.text_width(_name, _name.text))


func text_nodes() -> Array:
	var out: Array = [_name, _badge_label]
	out.append_array(_status)
	return out
