extends Control
## The slice's end (BUILD72): cleared, got out or dead - the kills, headshots, damage done and the time, the haul, and
## Back to the title. The slice is a sandbox: nothing here goes to the game (the line under the title says so).

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Items := preload("res://scripts/sim/items.gd")

signal to_title

const TITLES := {"cleared": "Cleared", "out": "Got out", "died": "Dead"}
const CARD_W := 760.0
const CARD_H := 640.0
const HAUL_ROWS := 8                   # the haul's rows shown; past that, "and N more"
const HAUL_ROW_H := 30.0

var outcome := ""
var _card: Panel
var _title: Label
var _sub: Label
var _note: Label
var _tiles: Array = []
var _haul_head: Label
var _haul: Array = []                 # labels, a find a row
var button: Button


func _init() -> void:
	size = Vector2(1920, 1080)                 # laid out by layout(), not by anchors (the screen's size set by hand)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_card = UI.panel(self, Rect2(0, 0, CARD_W, CARD_H), UI.box(Pal.PANEL, 10, 1, Pal.CARD_LINE))
	_title = UI.label(_card, Rect2(40, 28, CARD_W - 80, 44), "", "Bold", 34, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(_card, Rect2(40, 74, CARD_W - 80, 24), "", "Regular", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_tiles = UI.tile_row(_card, 40, 118, CARD_W - 80, 4)
	_haul_head = UI.head(_card, Rect2(40, 200, CARD_W - 80, 24), "The haul")
	for k in range(HAUL_ROWS + 1):
		_haul.append(UI.label(_card, Rect2(40, 230 + k * HAUL_ROW_H, CARD_W - 80, HAUL_ROW_H), "", "Regular", 17, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	_note = UI.label(_card, Rect2(40, CARD_H - 120, CARD_W - 80, 24), "None of it goes to the stash", "Regular", 15, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	button = UI.button(_card, Rect2(40, CARD_H - 84, 260, 52), true)
	button.text = "Back to the title"
	button.pressed.connect(func() -> void: to_title.emit())
	visible = false


func layout(s: Vector2) -> void:
	size = s
	_card.position = Vector2(roundf((s.x - CARD_W) / 2.0), roundf((s.y - CARD_H) / 2.0))


## The run's end as the world's stats have it: {kills, headshots, damage_done, time_s, haul: [item dicts]}.
func open(outcome_v: String, stats: Dictionary, place := "The car park") -> void:
	outcome = outcome_v
	_title.text = str(TITLES.get(outcome_v, "Not cleared"))
	_title.add_theme_color_override("font_color", Pal.GOOD if outcome_v == "cleared" else (Pal.BAD if outcome_v == "died" else Pal.TEXT))
	_sub.text = UI.dots("%s · %s" % [place, Fmt.mss(float(stats.get("time_s", 0.0)))])
	UI.set_tile(_tiles[0], "Kills", [Fmt.group(int(stats.get("kills", 0)))])
	UI.set_tile(_tiles[1], "Headshots", [Fmt.group(int(stats.get("headshots", 0)))])
	UI.set_tile(_tiles[2], "Damage done", [Fmt.group(int(stats.get("damage_done", 0))), Fmt.short_num(float(stats.get("damage_done", 0)))])
	UI.set_tile(_tiles[3], "Time", [Fmt.mss(float(stats.get("time_s", 0.0)))])
	var haul: Array = stats.get("haul", [])
	for l in _haul:
		l.text = ""
	if haul.is_empty():
		_haul[0].text = "Nothing found"
		_haul[0].add_theme_color_override("font_color", Pal.TEXT_2)
	else:
		_haul[0].add_theme_color_override("font_color", Pal.TEXT)
		var shown: int = haul.size() if haul.size() <= HAUL_ROWS + 1 else HAUL_ROWS
		for k in range(shown):
			UI.fit(_haul[k], [find_words(haul[k])])
		if shown < haul.size():
			_haul[HAUL_ROWS].text = "And %d more" % (haul.size() - shown)
			_haul[HAUL_ROWS].add_theme_color_override("font_color", Pal.TEXT_2)
	visible = true
	layout(get_viewport_rect().size if is_inside_tree() else size)
	if is_inside_tree():
		button.grab_focus()


## A find's line: its name (the item's own, or its base), its count when more than one.
static func find_words(it) -> String:
	if not (it is Dictionary):
		return str(it)
	var nm: String = Items.full_name(it) if it.has("base") else str(it.get("name", "A find"))
	if it.has("base") and it.has("rarity") and not it.has("unique") and int(it["rarity"]) > 0:
		nm = "%s · %s" % [nm, Items.rarity_name(it)]
	var n: int = int(it.get("count", 1))
	return UI.dots(nm if n <= 1 else "%s ×%d" % [nm, n])


func text_nodes() -> Array:
	var out: Array = [_title, _sub, _haul_head, _note, button] + _haul
	for t in _tiles:
		out.append(t["key"])
		out.append(t["value"])
	return out


func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size)
