extends Button
## One room on the rail, as a row of the ledger (8 Oct, round two: F on the
## design canvas; the last pass: names only). A stamped square at the left with
## the room's glyph and the name beside it, centred in the row - and, when the
## room wants a decision, the badge under the name (the row is 312 wide and
## the stamp takes 72: a badge beside the name overran it). The lit row takes the cards' colour and its
## stamp goes gold (the reach across the margin to the card went, 8 Oct, Matt:
## "just keep the button as the button").
## The rows share the rail's height: `set_row_height` from the layout. The
## badge carries a word as well as a colour, so colour is never the only signal.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const BADGE_PAD := 10           # each side of the badge's word
const STAMP := 56               # the stamped square
const STAMP_X := 16
const TEXT_X := STAMP_X + STAMP + 16
## The rail's glyphs (13 Oct, the campaign manifest): art/rail/, drawn for the rooms as they're named now; the five a
## boss opens are the things that open them (the deeds, the tool roll, the vet's bag, the ledger, the military radio).
const GLYPH_OF := {"The Yard": "rail/yard", "Stats": "rail/stats", "The Kit": "rail/runner", "The Map": "rail/runs", "Workshop": "rail/workshop", "Training": "rail/training",
	"The Clinic": "rail/clinic", "The Fence": "rail/fence", "Radio": "rail/radio"}
const STAMP_PAINTED := Color("4b525a")   # a painting's stamp, lighter (13 Oct, Matt: the dark ones sank into the dark)

var room: String
var _name: Label
var _stamp: Panel
var _glyph: TextureRect
var _badge: Panel
var _badge_label: Label
var _rule: Panel                # the hairline under the row
var _selected := false
var last := false:              # the last row: no hairline under it (set after the row is built, so the rule follows it)
	set(v):
		last = v
		if _rule != null:
			_rule.visible = not v


func _init(room_name: String) -> void:
	room = room_name
	size = Vector2(Pal.RAIL_W, Pal.RAIL_BTN_H)
	custom_minimum_size = size
	focus_mode = Control.FOCUS_ALL
	text = ""
	_stamp = UI.panel(self, Rect2(STAMP_X, 0, STAMP, STAMP), UI.box(Pal.STAMP, 8, 1, Pal.CARD_LINE))
	_glyph = UI.glyph(_stamp, Rect2(9, 9, STAMP - 18, STAMP - 18), GLYPH_OF.get(room_name, "yard"), Pal.TEXT_2)
	_name = UI.label(self, Rect2(TEXT_X, 0, Pal.RAIL_W - TEXT_X - 18, 36), room_name, "SemiBold", Pal.NAME, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_badge = UI.panel(self, Rect2(TEXT_X, 36, 96, 30), UI.box(Pal.WARN, 15))
	_badge_label = UI.label(_badge, Rect2(0, 0, 96, 30), "", "SemiBold", Pal.FLOOR, Pal.ACCENT_TEXT,
			HORIZONTAL_ALIGNMENT_CENTER, false)
	_badge.visible = false
	_rule = UI.panel(self, Rect2(0, Pal.RAIL_BTN_H - 1, Pal.RAIL_W, 1), UI.box(Pal.RAIL_RULE, 0))
	set_row_height(Pal.RAIL_BTN_H)
	_style(false)


## The row's height from the layout (the rail runs to the log's bottom): the
## stamp and the two lines sit centred in it.
func set_row_height(h: float) -> void:
	size.y = h
	custom_minimum_size.y = h
	_stamp.position.y = floorf((h - STAMP) / 2.0)
	_rule.position.y = h - 1
	_place()


## The name centred in the row; with a badge, the name up and the badge under it.
func _place() -> void:
	var h: float = size.y
	if _badge.visible:
		var top := floorf((h - 66) / 2.0)
		_name.position.y = top
		_badge.position.y = top + 36
	else:
		_name.position.y = floorf((h - 36) / 2.0)


## A room a head hasn't opened yet (13 Oct): not pressable, its name and glyph dimmed, "Shut" under the name.
var _shut := false
func set_shut(on: bool) -> void:
	if on == _shut:
		return
	_shut = on
	disabled = on
	mouse_default_cursor_shape = Control.CURSOR_ARROW if on else Control.CURSOR_POINTING_HAND
	_name.modulate.a = 0.45 if on else 1.0
	_stamp.modulate.a = 0.45 if on else 1.0


func set_selected(on: bool) -> void:
	if on != _selected:
		_selected = on
		_style(on)


func show_status(d: Dictionary) -> void:
	var word: String = d.get("badge", "")
	_badge.visible = word != ""
	_badge_label.text = word
	if word != "":
		# the pill hugs its word, under the name
		var w := ceilf(UI.text_width(_badge_label, word)) + 2 * BADGE_PAD
		_badge.size.x = w
		_badge_label.size.x = w
		(_badge.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(d.get("badge_tone", "warn"))
	_place()


func _style(on: bool) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var bg: Color = Pal.CARD if on else (Pal.RAIL_HOVER if state == "hover" else Color.TRANSPARENT)
		add_theme_stylebox_override(state, UI.box(bg, 0))
	add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 0, 2, Pal.TEXT))
	var sb := _stamp.get_theme_stylebox("panel") as StyleBoxFlat
	var painted: bool = not UI.glyph_mono(GLYPH_OF.get(room, "yard"))
	sb.bg_color = Pal.ACCENT if on else (STAMP_PAINTED if painted else Pal.STAMP)
	sb.border_color = Pal.ACCENT if on else Pal.CARD_LINE
	if UI.glyph_mono(GLYPH_OF.get(room, "yard")):
		_glyph.modulate = Pal.ACCENT_TEXT if on else Pal.TEXT_2       # a line drawing takes the stamp's ink; a painting is itself
	_rule.visible = not last


## Pixels between the badge and the row's right edge, or INF with no badge (the
## badge sits under the name, so it never meets it).
func badge_gap() -> float:
	if not _badge.visible:
		return INF
	return Pal.RAIL_W - 18 - (_badge.position.x + _badge.size.x)


func text_nodes() -> Array:
	return [_name, _badge_label]
