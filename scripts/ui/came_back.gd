extends Panel
## What came back (11 Oct, Matt's list): a card over the Runs screen with every run since the player last looked,
## added up - the runs, the money, the XP, the items, the levels, the dearest find (and whether it beats what's
## worn), and the firsts: a clear, a new depth, a head down, a unique, a paper. Seen puts it away until the next run
## comes home. The sim keeps the tally (sim.came_back), so it lasts through a save and holds what ran while away.
## It sits over the column the last run didn't come from, so that column's Set off is never under it.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")

const W := 501                     # a Runs column's width
const PAD := 20
const INNER := W - 2 * PAD
const LINE_H := 28
const FIRSTS := 3                  # lines for the firsts (the last "and N more" when there are more)
const HEAD_Y := 16
const TILES_Y := HEAD_Y + UI.HEAD_H + 6
const FIND_Y := TILES_Y + UI.TILE_H + 12
const FIND_H := Pal.CELL
const FIRSTS_Y := FIND_Y + FIND_H + 8
const BUTTON_W := 100              # Seen, small, at the head's right: the card stays short enough to clear the tiles above
const BUTTON_H := 36
const H := FIRSTS_Y + FIRSTS * LINE_H + 12

var sim
var _head: Label
var _tiles: Array = []
var _cell                          # the find, drawn as everywhere else
var _find_name: Label
var _find_line: Label
var _firsts: Array[Label] = []
var _seen: Button
var _shown := ""


func _init() -> void:
	size = Vector2(W, H)
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, Pal.GOOD))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_head = UI.head(self, Rect2(PAD, HEAD_Y, INNER - BUTTON_W - 12, UI.HEAD_H), "")
	_tiles = UI.tile_row(self, PAD, TILES_Y, INNER, 4)
	_cell = ItemCell.new()
	_cell.position = Vector2(PAD, FIND_Y)
	_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cell.focus_mode = Control.FOCUS_NONE
	add_child(_cell)
	var tx := PAD + Pal.CELL + 14
	_find_name = UI.label(self, Rect2(tx, FIND_Y + 4, W - PAD - tx, LINE_H), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_find_line = UI.label(self, Rect2(tx, FIND_Y + 4 + LINE_H, W - PAD - tx, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(FIRSTS):
		_firsts.append(UI.label(self, Rect2(PAD, FIRSTS_Y + k * LINE_H, INNER, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	_seen = UI.button(self, Rect2(W - PAD - BUTTON_W, HEAD_Y + UI.HEAD_H / 2.0 - BUTTON_H / 2.0 - 2, BUTTON_W, BUTTON_H), false)
	_seen.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG + 2)
	_seen.text = "Seen"
	UI.style_button(_seen, false)
	_seen.pressed.connect(_on_seen)


## Shown when a run has come home since the last Seen, and never while a run is out (the Runs screen isn't).
func show_state(s) -> void:
	sim = s
	var cb: Dictionary = sim.came_back
	visible = not cb.is_empty() and int(cb.get("runs", 0)) > 0
	if not visible:
		return
	var f: Dictionary = cb.get("find", {})
	var sig := "%s|%d|%s" % [str(cb), sim.level(), _where(f)]
	if sig == _shown:
		return
	_shown = sig
	var runs: int = int(cb["runs"])
	var deaths: int = int(cb.get("deaths", 0))
	_head.text = ("What came back · %d run%s" % [runs, "" if runs == 1 else "s"]).to_upper()
	if deaths > 0:
		_head.text += (" · %d lost" % deaths).to_upper()
	var lv0: int = int(cb.get("lv_from", sim.level()))
	var cash: float = float(cb["cash"])
	var xp: float = float(cb["xp"])
	UI.set_tile(_tiles[0], "Cash", ["+" + Fmt.money(cash), Fmt.money(cash), "£" + _short(cash)], Pal.GOOD if cash > 0.0 else Pal.TEXT)
	UI.set_tile(_tiles[1], "XP", ["+" + Fmt.num(xp), Fmt.num(xp), _short(xp)])
	UI.set_tile(_tiles[2], "Items", ["%d" % int(cb["items"])])
	UI.set_tile(_tiles[3], "Level", ["%d → %d" % [lv0, sim.level()], "%d" % sim.level()] if sim.level() > lv0 else ["%d" % sim.level()], Pal.GOOD if sim.level() > lv0 else Pal.TEXT)
	# the dearest find: the cell as the stash draws it, its arrow if it beats what's worn
	_cell.visible = not f.is_empty()
	if f.is_empty():
		_find_name.text = ""
		UI.fit(_find_line, ["Nothing kept: the pack came home light", "Nothing kept"])
		_find_line.position.y = FIND_Y + (FIND_H - LINE_H) / 2.0
		_find_line.position.x = PAD
		_find_line.size.x = INNER
	else:
		var tx := PAD + Pal.CELL + 14
		_find_line.position = Vector2(tx, FIND_Y + 4 + LINE_H)
		_find_line.size.x = W - PAD - tx
		_cell.show_item(f, false, Vector2(Pal.CELL, Pal.CELL))
		var where := _where(f)
		_cell.set_upgrade(where == "stash" and sim.is_upgrade(f))
		var full: String = Items.full_name(f)
		UI.fit(_find_name, [full, str(f["base"])])
		var worth: String = Fmt.money(float(f.get("value", 0)))
		var rarity: String = Items.rarity_name(f)
		var state: String = {"stash": "▲ beats your %s" % str(f["slot"]).to_lower() if sim.is_upgrade(f) else "in the stash",
			"worn": "worn", "gone": "sold"}[where]
		UI.fit(_find_line, ["%s · %s · %s" % [rarity, worth, state], "%s · %s" % [worth, state], worth])
		_find_line.add_theme_color_override("font_color", Pal.GOOD if state.begins_with("▲") else Pal.TEXT_2)
	# the firsts, then a death's cost
	var lines: Array = cb.get("firsts", []).duplicate()
	if deaths > 0:
		lines.push_front("%s lost with the kit: %s" % ["A runner" if deaths == 1 else "%d runners" % deaths, Fmt.money(float(cb.get("lost", 0)))])
	var extra: int = int(cb.get("more", 0))
	if lines.size() + (1 if extra > 0 else 0) > FIRSTS:
		extra += lines.size() - (FIRSTS - 1)
		lines = lines.slice(0, FIRSTS - 1)
	if extra > 0:
		lines.append("and %d more" % extra)
	if lines.is_empty():
		lines = ["Nothing new: the same streets, a little richer"]
	for k in range(FIRSTS):
		var l: Label = _firsts[k]
		var text: String = str(lines[k]) if k < lines.size() else ""
		UI.fit(l, [text, text.get_slice(":", 0)])
		l.add_theme_color_override("font_color", Pal.BAD if text.contains("lost with the kit") else (Pal.TEXT_2 if text.begins_with("and ") or text.begins_with("Nothing new") else Pal.TEXT))


## A big figure in a quarter-width tile: 1.2k, 47k, 3.4M.
static func _short(x: float) -> String:
	var a := absf(x)
	if a >= 999500.0:                # past that, "1000k" would show
		return "%.1fM" % (a / 1e6)
	if a >= 1e4:
		return "%.0fk" % (a / 1e3)
	if a >= 1e3:
		return "%.1fk" % (a / 1e3)
	return "%d" % int(a)


## Where the find is now: still in the stash, worn, or sold (the junk rules or the Fence).
func _where(f: Dictionary) -> String:
	if f.is_empty() or sim == null:
		return ""
	var id: int = int(f["id"])
	for it in sim.stash:
		if int(it["id"]) == id:
			return "stash"
	for slot in sim.equipped:
		if sim.equipped[slot] != null and int(sim.equipped[slot]["id"]) == id:
			return "worn"
	return "gone"


func _on_seen() -> void:
	sim.came_back_seen()
	visible = false
	acted.emit()


## For the tests: every label and button with text.
func text_nodes() -> Array:
	var out: Array = []
	if not visible:
		return out
	out.append(_head)
	for t in _tiles:
		out.append_array([t["key"], t["value"]])
	out.append_array(_cell.text_nodes())
	for l in [_find_name, _find_line]:
		if l.text != "":
			out.append(l)
	for l in _firsts:
		if l.text != "":
			out.append(l)
	out.append(_seen)
	return out
