extends Button
## One room on the rail, as a row of the ledger (8 Oct: the rail C with A's join,
## on the design canvas). The room's name with its figure at the right in the
## cards' number style - or a badge there when the room wants a decision - and
## one status line under. The lit row takes the cards' colour, a gold edge and
## the name in gold, and reaches across the margin to join the room's card. The
## badge carries a word as well as a colour, so colour is never the only signal.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const BADGE_PAD := 10           # each side of the badge's word (14 put Unique on The Fence's name)
const RIGHT := Pal.RAIL_W - 20  # the figure's and the badge's right edge
const PAD_L := 20               # past the lit edge

var room: String
var _name: Label
var _status: Array[Label] = []
var _figure: Label
var _badge: Panel
var _badge_label: Label
var _rule: Panel                # the hairline under the row
var _tongue: Panel              # the lit row's reach across the margin to the card
var _selected := false
var last := false               # the last row: no hairline under it


func _init(room_name: String) -> void:
	room = room_name
	size = Vector2(Pal.RAIL_W, Pal.RAIL_BTN_H)
	custom_minimum_size = size
	focus_mode = Control.FOCUS_ALL
	text = ""
	_name = UI.label(self, Rect2(PAD_L, 12, 190, 40), room_name, "SemiBold", Pal.NAME, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_status.append(UI.label(self, Rect2(PAD_L, 52, Pal.RAIL_W - PAD_L - 20, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2))
	_figure = UI.label(self, Rect2(RIGHT - 120, 12, 120, 40), "", "SemiBold", Pal.NAME, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT)
	_badge = UI.panel(self, Rect2(RIGHT - 96, 14, 96, 36), UI.box(Pal.WARN, 18))
	_badge_label = UI.label(_badge, Rect2(0, 0, 96, 36), "", "SemiBold", Pal.FLOOR, Pal.ACCENT_TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, false)
	_badge.visible = false
	_rule = UI.panel(self, Rect2(0, Pal.RAIL_BTN_H - 1, Pal.RAIL_W, 1), UI.box(Pal.RAIL_RULE, 0))
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tongue = UI.panel(self, Rect2(Pal.RAIL_W - 2, 0, Pal.MARGIN + 3, Pal.RAIL_BTN_H), UI.box(Pal.CARD, 0))
	_tongue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tongue.visible = false
	_style(false)


func set_selected(on: bool) -> void:
	if on != _selected:
		_selected = on
		_style(on)


func show_status(d: Dictionary) -> void:
	_status[0].text = d.get("status1", "")
	var word: String = d.get("badge", "")
	_badge.visible = word != ""
	_badge_label.text = word
	# the figure, or the badge in its place: the row carries one thing at the right
	_figure.text = "" if word != "" else str(d.get("figure", ""))
	if word != "":
		# the pill hugs its word, right-aligned; ui_check proves it clears the name
		var w := ceilf(UI.text_width(_badge_label, word)) + 2 * BADGE_PAD
		_badge.position.x = RIGHT - w
		_badge.size.x = w
		_badge_label.size.x = w
		(_badge.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(d.get("badge_tone", "warn"))


func _style(on: bool) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var bg: Color = Pal.CARD if on else (Pal.RAIL_HOVER if state == "hover" else Color.TRANSPARENT)
		var sb := UI.box(bg, 0)
		if on:
			sb.border_width_left = 6
			sb.border_color = Pal.ACCENT
		add_theme_stylebox_override(state, sb)
	add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 0, 2, Pal.TEXT))
	_name.add_theme_color_override("font_color", Pal.ACCENT if on else Pal.TEXT)
	_figure.add_theme_color_override("font_color", Pal.TEXT if on else Pal.TEXT_2)
	_tongue.visible = on
	_rule.visible = not on and not last


## Pixels between the end of the room's name and what sits at the right (the
## badge, or the figure), or INF with nothing there.
func badge_gap() -> float:
	var name_end: float = _name.position.x + UI.text_width(_name, _name.text)
	if _badge.visible:
		return _badge.position.x - name_end
	if _figure.text != "":
		return RIGHT - UI.text_width(_figure, _figure.text) - name_end
	return INF


func text_nodes() -> Array:
	var out: Array = [_name, _badge_label, _figure]
	out.append_array(_status)
	return out
