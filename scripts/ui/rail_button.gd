extends Button
## One room on the rail, as a row of the ledger (8 Oct, round two: F on the
## design canvas). A stamped square at the left with the room's glyph, the
## name beside it and one status line under - or, when the room wants a
## decision, the badge in the status line's place (the row is 312 wide and the
## stamp takes 72: a badge beside the status overran it). The lit row takes the cards' colour, its
## stamp goes gold, and it reaches across the margin to join the room's card.
## The rows share the rail's height: `set_row_height` from the layout. The
## badge carries a word as well as a colour, so colour is never the only signal.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const BADGE_PAD := 10           # each side of the badge's word
const STAMP := 56               # the stamped square
const STAMP_X := 16
const TEXT_X := STAMP_X + STAMP + 16
const GLYPH_OF := {"The Yard": "yard", "Runs": "runs", "Lock-up": "lockup", "Bench": "bench", "Caravan": "caravan",
	"Clinic": "clinic", "The Fence": "fence", "Radio": "radio"}

var room: String
var _name: Label
var _status: Array[Label] = []
var _stamp: Panel
var _glyph: TextureRect
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
	_stamp = UI.panel(self, Rect2(STAMP_X, 0, STAMP, STAMP), UI.box(Pal.STAMP, 8, 1, Pal.CARD_LINE))
	_glyph = UI.glyph(_stamp, Rect2(9, 9, STAMP - 18, STAMP - 18), GLYPH_OF.get(room_name, "yard"), Pal.TEXT_2)
	_name = UI.label(self, Rect2(TEXT_X, 0, Pal.RAIL_W - TEXT_X - 18, 36), room_name, "SemiBold", Pal.NAME, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_status.append(UI.label(self, Rect2(TEXT_X, 36, Pal.RAIL_W - TEXT_X - 18, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2))
	_badge = UI.panel(self, Rect2(TEXT_X, 36, 96, 30), UI.box(Pal.WARN, 15))
	_badge_label = UI.label(_badge, Rect2(0, 0, 96, 30), "", "SemiBold", Pal.FLOOR, Pal.ACCENT_TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, false)
	_badge.visible = false
	_rule = UI.panel(self, Rect2(0, Pal.RAIL_BTN_H - 1, Pal.RAIL_W, 1), UI.box(Pal.RAIL_RULE, 0))
	_tongue = UI.panel(self, Rect2(Pal.RAIL_W - 2, 0, Pal.MARGIN + 3, Pal.RAIL_BTN_H), UI.box(Pal.CARD, 0))
	_tongue.visible = false
	set_row_height(Pal.RAIL_BTN_H)
	_style(false)


## The row's height from the layout (the rail runs to the log's bottom): the
## stamp and the two lines sit centred in it.
func set_row_height(h: float) -> void:
	size.y = h
	custom_minimum_size.y = h
	_stamp.position.y = floorf((h - STAMP) / 2.0)
	var top := floorf((h - 66) / 2.0)
	_name.position.y = top
	_status[0].position.y = top + 36
	_badge.position.y = top + 36
	_rule.position.y = h - 1
	_tongue.size.y = h


func set_selected(on: bool) -> void:
	if on != _selected:
		_selected = on
		_style(on)


func show_status(d: Dictionary) -> void:
	_status[0].text = d.get("status1", "")
	var word: String = d.get("badge", "")
	_badge.visible = word != ""
	_status[0].visible = word == ""
	_badge_label.text = word
	if word != "":
		# the pill hugs its word, in the status line's place
		var w := ceilf(UI.text_width(_badge_label, word)) + 2 * BADGE_PAD
		_badge.size.x = w
		_badge_label.size.x = w
		(_badge.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(d.get("badge_tone", "warn"))


func _style(on: bool) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var bg: Color = Pal.CARD if on else (Pal.RAIL_HOVER if state == "hover" else Color.TRANSPARENT)
		add_theme_stylebox_override(state, UI.box(bg, 0))
	add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 0, 2, Pal.TEXT))
	var sb := _stamp.get_theme_stylebox("panel") as StyleBoxFlat
	sb.bg_color = Pal.ACCENT if on else Pal.STAMP
	sb.border_color = Pal.ACCENT if on else Pal.CARD_LINE
	if UI.glyph_mono(GLYPH_OF.get(room, "yard")):
		_glyph.modulate = Pal.ACCENT_TEXT if on else Pal.TEXT_2       # a line drawing takes the stamp's ink; a painting is itself
	_tongue.visible = on
	_rule.visible = not last


## Pixels between the badge and the row's right edge, or INF with no badge (the
## badge stands in the status line's place, so it never meets the name).
func badge_gap() -> float:
	if not _badge.visible:
		return INF
	return Pal.RAIL_W - 18 - (_badge.position.x + _badge.size.x)


func text_nodes() -> Array:
	var out: Array = [_name, _badge_label]
	out.append_array(_status)
	return out
