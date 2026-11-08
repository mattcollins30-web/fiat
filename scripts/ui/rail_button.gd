extends Button
## One room on the rail, as a row of the ledger (8 Oct, round two: F on the
## design canvas; the last pass: names only). A stamped square at the left with
## the room's glyph and the name beside it, centred in the row - and, when the
## room wants a decision, the badge under the name (the row is 312 wide and
## the stamp takes 72: a badge beside the name overran it), clear of the name's descenders (30 Oct). The lit row takes the cards' colour and its
## stamp goes gold (the reach across the margin to the card went, 8 Oct, Matt:
## "just keep the button as the button").
## The rows share the rail's height: `set_row_height` from the layout. The
## badge carries a word as well as a colour, so colour is never the only signal.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const Fmt := preload("res://scripts/ui/fmt.gd")
const BADGE_PAD := 10           # each side of the badge's word
const STAMP := 56               # the stamped square
const STAMP_X := 16
const TEXT_X := STAMP_X + STAMP + 16
## The name over the badge (30 Oct, parked item 2: "The Map" ran into "Away" in a squeezed rail): the name's box is the
## font's whole height (30 px SemiBold: 38, its descenders inside), the badge a gap under it; 70 in all, inside the
## least row (main.gd RAIL_ROW_MIN, 72). The name and the badge's word can't share a line: "The Pitch" and
## "Can build" need 274 px, the row has 206.
const NAME_H := 38
const BADGE_H := 30
const BADGE_GAP := 2
const STACK_H := NAME_H + BADGE_GAP + BADGE_H
## (BUILD69-R) The status as a chip at the row's top right (8 Nov, docs/design/endgame_rail.md §4, the Main mockup): a
## word in its tone's colour on a dark tint of it, so ten rows fit and the name keeps the row's middle. The name drops
## under the chip only when the two would meet; in a row too short for that the name goes to the floor size.
const CHIP_FONT := Pal.CELL_TEXT_BIG    # 18: the mockup's 13 at its 1920 (a floor-sized chip ran into the names)
const CHIP_H := 23
const CHIP_PAD := 8                     # each side of the chip's word
const CHIP_TOP := 1
const CHIP_RIGHT := 8                   # the chip's right edge to the row's
const CHIP_TINT := 0.26                 # the chip's ground: its tone at this share over the panel
const NAME_SMALL := Pal.FLOOR           # the name in a row too short for the chip over it
const NAME_SMALL_H := 31
const STAMP_PAD := 4                    # the stamp's least space above and below in a short row (the glyph's space cut)
## The rail's glyphs (13 Oct, the campaign manifest): art/rail/, drawn for the rooms as they're named now; the five a
## boss opens are the things that open them (the deeds, the fitter's kit, the vet's bag, the ledger, the military radio).
const GLYPH_OF := {"The Pitch": "rail/yard", "Stats": "rail/stats", "The Kit": "rail/runner", "The Map": "rail/runs", "Workshop": "rail/workshop", "Training": "rail/training",
	"The Clinic": "rail/clinic", "The Fence": "rail/fence", "Radio": "rail/radio", "Bunkhouse": "rail/bunkhouse"}     # the Bunkhouse (BUILD69-R): the Pitch's own picture
const STAMP_PAINTED := Color("4b525a")   # a painting's stamp, lighter (13 Oct, Matt: the dark ones sank into the dark)

var room: String
var _name: Label
var _stamp: Panel
var _glyph: TextureRect
var _badge: Panel
var _badge_label: Label
var _rule: Panel                # the hairline under the row
var _selected := false
var _dot: Panel                 # folded (15 Oct): the badge as a dot on the stamp's corner, its word in the tooltip
var folded := false
var shut_words := ""            # what opens a shut room, for the tooltip
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
	_name = UI.label(self, Rect2(TEXT_X, 0, Pal.RAIL_W - TEXT_X - 18, NAME_H), room_name, "SemiBold", Pal.NAME, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_badge = UI.panel(self, Rect2(TEXT_X, CHIP_TOP, 96, CHIP_H), UI.box(Pal.WARN, 6))     # the chip (BUILD69-R)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_label = UI.label(_badge, Rect2(0, 0, 96, CHIP_H), "", "SemiBold", CHIP_FONT, Pal.WARN,
			HORIZONTAL_ALIGNMENT_CENTER, false)
	_badge.visible = false
	_dot = UI.panel(self, Rect2(STAMP_X + STAMP - 12, 0, 18, 18), UI.box(Pal.WARN, 9, 2, Pal.PANEL))
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.visible = false
	_rule = UI.panel(self, Rect2(0, Pal.RAIL_BTN_H - 1, Pal.RAIL_W, 1), UI.box(Pal.RAIL_RULE, 0))
	set_row_height(Pal.RAIL_BTN_H)
	_style(false)


## The row's height from the layout (the rail runs to the log's bottom): the
## stamp and the two lines sit centred in it. The minimum first (4 Nov, BUILD48 item 8, Matt: "you never fixed the rail
## clipping here when a runner is away"): a size under the old minimum doesn't take, so when the away card came in and
## the rows shrank (101 to 77 at 1920 x 1080) each row kept its old height - its name and badge placed for 101 while its
## stamp and hairline and the next row went at 77: every name low in its row, the badge down over the next. The 30 Oct
## check only ever grew the rows.
func set_row_height(h: float) -> void:
	custom_minimum_size.y = h
	size.y = h
	var st: float = minf(STAMP, h - 2 * STAMP_PAD)     # (BUILD69-R) a short row's stamp gives up its space first
	_stamp.size = Vector2(st, st)
	_glyph.position = Vector2(9, 9) * st / STAMP
	_glyph.size = Vector2(st, st) - 2 * _glyph.position
	_stamp.position.x = STAMP_X + floorf((STAMP - st) / 2.0)
	_stamp.position.y = floorf((h - st) / 2.0)
	_dot.position.y = _stamp.position.y - 6
	_rule.position.y = h - 1
	_place()


## Folded to the glyph (15 Oct, the run on screen; frame_mockup_B): the stamp alone in a row Pal.RAIL_FOLDED_W wide,
## the name and the badge's word in the tooltip, the badge a dot in its tone on the stamp's corner.
func set_folded(on: bool) -> void:
	folded = on
	var w: float = Pal.RAIL_FOLDED_W if on else Pal.RAIL_W
	custom_minimum_size.x = w            # the minimum first: a size under it doesn't take
	size.x = w
	_rule.size.x = w
	_name.visible = not on
	_badge.visible = _badge_label.text != "" and not on
	_dot.visible = _badge_label.text != "" and on and not _shut     # the badge follows the fold at once, not a refresh later (the review)
	_place()
	_tip()


func _tip() -> void:
	var lines: Array = []
	if folded:
		lines.append((Fmt.scramble(room) if _shut else room) + ((" · " + _badge_label.text) if _badge_label.text != "" else ""))
	if shut_words != "":
		lines.append(shut_words)
	tooltip_text = "\n".join(lines)


## (BUILD69-R) The name centred in the row; the chip at the top right. When the chip reaches back over the name's
## words the name goes under it, at the floor size if the row's too short for the name whole under the chip.
func _place() -> void:
	var h: float = size.y
	_badge.position = Vector2(size.x - CHIP_RIGHT - _badge.size.x, CHIP_TOP)
	_name.add_theme_font_size_override("font_size", Pal.NAME)
	_name.size.y = NAME_H
	_name.position.y = floorf((h - NAME_H) / 2.0)
	if not _badge.visible:
		return
	var chip_foot: float = CHIP_TOP + CHIP_H
	if TEXT_X + UI.text_width(_name, _name.text) + 6.0 <= _badge.position.x or _name.position.y >= chip_foot:
		return
	if chip_foot + NAME_H <= h - 1.0:
		_name.position.y = chip_foot
		return
	_name.add_theme_font_size_override("font_size", NAME_SMALL)
	_name.size.y = NAME_SMALL_H
	_name.position.y = maxf(chip_foot, floorf((h - NAME_SMALL_H) / 2.0))


## A room a head hasn't opened yet (13 Oct): not pressable, its glyph dimmed, its name scrambled (20 Oct, Matt: no "Shut").
var _shut := false
func set_shut(on: bool) -> void:
	if on == _shut:
		return
	_shut = on
	disabled = on
	mouse_default_cursor_shape = Control.CURSOR_ARROW if on else Control.CURSOR_POINTING_HAND
	_name.modulate.a = 0.45 if on else 1.0
	_name.text = Fmt.scramble(room) if on else room
	while on and _name.text.length() > 3 and UI.text_width(_name, _name.text) > _name.size.x:
		_name.text = _name.text.substr(0, _name.text.length() - 1)     # the glyphs run wider than the letters: cut to the row
	_stamp.modulate.a = 0.45 if on else 1.0


func set_selected(on: bool) -> void:
	if on != _selected:
		_selected = on
		_style(on)


func show_status(d: Dictionary) -> void:
	var word: String = d.get("badge", "")
	_badge.visible = word != "" and not folded
	_badge_label.text = word
	_dot.visible = word != "" and folded and not _shut      # a shut room is dimmed, its word in the tooltip
	if _dot.visible:
		(_dot.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(d.get("badge_tone", "warn"))
	_tip()
	if word != "":
		# the chip hugs its word (BUILD69-R): the tone's colour on a dark tint of it
		var w := ceilf(UI.text_width(_badge_label, word)) + 2 * CHIP_PAD
		_badge.size.x = w
		_badge_label.size.x = w
		var tone: Color = Pal.tone_color(d.get("badge_tone", "warn"))
		(_badge.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.PANEL.lerp(tone, CHIP_TINT)
		_badge_label.add_theme_color_override("font_color", tone)
	_place()


## (BUILD69-R) The chip's word as shown ("" none; a folded row's is the dot's).
func chip_word() -> String:
	return _badge_label.text


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
	# (BUILD69-R) the chip at the top right: INF when the name sits under it or clear of it on the line, else the
	# pixels between the name's words and the chip
	var fh: float = _name.get_theme_font("font").get_height(_name.get_theme_font_size("font_size"))
	var top: float = _name.position.y + (maxf(_name.size.y, fh) - fh) / 2.0
	if top >= _badge.position.y + _badge.size.y - 0.5:
		return INF
	return _badge.position.x - (_name.position.x + UI.text_width(_name, _name.text))


func text_nodes() -> Array:
	return [] if folded else [_name, _badge_label]
