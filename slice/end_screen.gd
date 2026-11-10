extends Control
## The slice's end (BUILD72): cleared, got out or dead - the kills, headshots, damage done and the time, the haul, and
## Back to the title. (round 6, board E) Accuracy and HP lost join the tiles, and a cleared car park sets his time and
## HP lost against the game's own fight for the same runner and level. The slice is a sandbox: nothing here goes to the game (the line under the title says so).

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Items := preload("res://scripts/sim/items.gd")

signal to_title
signal next_place                     # (boards J to L) a run: on to its next place
signal again                          # ...or this place once more (dead), or the run from its start (done)

const TITLES := {"cleared": "Cleared", "out": "Got out", "died": "Dead"}
const CARD_W := 760.0
const CARD_H := 820.0
const HAUL_ROWS := 8                   # the haul's rows shown; past that, "and N more"
const HAUL_ROW_H := 30.0
const VS_Y := 256.0                    # the game's own fight: its head, the columns, two rows, the note
const VS_ROW_H := 26.0
const HAUL_Y := 400.0                  # the haul under it (in its place when the fight wasn't cleared)

var outcome := ""
var _card: Panel
var _title: Label
var _sub: Label
var _note: Label
var _tiles: Array = []
var _vs_head: Label
var _vs: Array = []                   # the game's own fight: [[key, yours, the game's] a row], the first the columns' heads
var _vs_note: Label
var _haul_head: Label
var _haul: Array = []                 # labels, a find a row
var button: Button
var run_button: Button                # a run's way on: the next place, this one again, another run
var run_way := ""                     # ..."next", "again", "new"; "": no run


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
	_sub = UI.head(_card, Rect2(40, 26, CARD_W - 80, 24), "")
	_title = UI.label(_card, Rect2(40, 50, CARD_W - 80, 44), "", "Bold", 34, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_tiles = UI.tile_row(_card, 40, 110, CARD_W - 80, 3) + UI.tile_row(_card, 40, 110 + UI.TILE_H + 8, CARD_W - 80, 3)
	_vs_head = UI.head(_card, Rect2(40, VS_Y, CARD_W - 80, 24), "You against the runner alone")
	for k in range(3):
		var row: Array = []
		for c in range(3):
			var head: bool = k == 0
			row.append(UI.label(_card, Rect2(40 + [0, 300, 480][c], VS_Y + 28 + k * VS_ROW_H, [280, 160, 160][c], VS_ROW_H), "", "Regular" if head or c == 0 else "SemiBold", 15 if head else 17, Pal.TEXT_3 if head else (Pal.TEXT_2 if c == 0 else Pal.TEXT), HORIZONTAL_ALIGNMENT_LEFT, false))
		_vs.append(row)
	_vs_note = UI.label(_card, Rect2(40, VS_Y + 28 + 3 * VS_ROW_H + 2, CARD_W - 80, 22), "What this runner would expect alone at this level · meds and Guard not counted", "Regular", 15, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_haul_head = UI.head(_card, Rect2(40, HAUL_Y, CARD_W - 80, 24), "The haul")
	for k in range(HAUL_ROWS + 1):
		_haul.append(UI.label(_card, Rect2(40, HAUL_Y + 30 + k * HAUL_ROW_H, CARD_W - 80, HAUL_ROW_H), "", "Regular", 17, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	_note = UI.label(_card, Rect2(40, CARD_H - 120, CARD_W - 80, 24), "None of it goes to the stash", "Regular", 15, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	button = UI.button(_card, Rect2(40, CARD_H - 84, 260, 52), true)
	button.text = "Back to the title"
	button.pressed.connect(func() -> void: to_title.emit())
	run_button = UI.button(_card, Rect2(40, CARD_H - 84, 340, 52), true)
	run_button.visible = false
	run_button.pressed.connect(func() -> void:
		if run_way == "next":
			next_place.emit()
		else:
			again.emit())
	visible = false


func layout(s: Vector2) -> void:
	size = s
	_card.position = Vector2(roundf((s.x - CARD_W) / 2.0), roundf((s.y - CARD_H) / 2.0))


## The run's end as the world's stats have it: {kills, headshots, damage_done, damage_taken, shots, hits, time_s,
## haul: [item dicts]}. `game` is the bridge's game_fight: {level, time_s, hp_lost}, shown against a cleared run.
## `run` (boards J to L), on a run: {i, of, next: the next place's name ("" at the last), level: his level now, xp:
## the XP he got out with}.
func open(outcome_v: String, stats: Dictionary, place := "The car park", game := {}, run := {}) -> void:
	outcome = outcome_v
	run_way = ""
	if not run.is_empty():
		run_way = "again" if outcome_v == "died" else ("next" if str(run.get("next", "")) != "" else "new")
	run_button.visible = run_way != ""
	button.position.x = 40.0 + (356.0 if run_way != "" else 0.0)
	UI.style_button(button, run_way == "")
	match run_way:
		"next":
			UI.fit_button(run_button, ["On to %s" % str(run["next"]), "The next site"])
			_note.text = UI.dots("The haul goes with the runner · the Kit opens first")
		"again":
			UI.fit_button(run_button, ["%s again" % place, "This site again"])
			_note.text = "The runner goes back in with the kit he came with"
		"new":
			run_button.text = "Start again from level 1"
			_note.text = UI.dots("Out of all 3 sites · started with a claw hammer")
		_:
			_note.text = "None of it goes to the stash"
	_title.text = str(TITLES.get(outcome_v, "Not cleared"))
	_title.add_theme_color_override("font_color", Pal.GOOD if outcome_v == "cleared" else (Pal.BAD if outcome_v == "died" else Pal.TEXT))
	var lv: int = int(game.get("level", 0))
	_sub.text = UI.dots(place if lv <= 0 else "%s · Level %d" % [place, lv]).to_upper()
	if not run.is_empty():
		_sub.text = UI.dots("%s · Site %d of %d" % [place, int(run["i"]) + 1, int(run["of"])]).to_upper()
	var shots: int = int(stats.get("shots", 0))
	var lost: int = int(stats.get("damage_taken", 0))
	UI.set_tile(_tiles[0], "Kills", [Fmt.group(int(stats.get("kills", 0)))])
	UI.set_tile(_tiles[1], "Headshots", [Fmt.group(int(stats.get("headshots", 0)))])
	if not run.is_empty():                           # a run: what he takes on in place of the headshots
		UI.set_tile(_tiles[1], "Runner", ["Level %d" % int(run.get("level", 1))] if outcome_v != "died" else ["Level %d · no XP kept" % int(run.get("level", 1)), "Level %d" % int(run.get("level", 1))])
	UI.set_tile(_tiles[2], "Accuracy", ["%d%%" % int(round(100.0 * float(stats.get("hits", 0)) / shots)) if shots > 0 else "No rounds fired"])
	if stats.has("gangs_beaten"):                    # (board I) the loop's measure: how many gangs he saw off before he left
		UI.set_tile(_tiles[3], "Gangs beaten", [Fmt.group(int(stats.get("gangs_beaten", 0)))])
	else:
		UI.set_tile(_tiles[3], "Damage done", [Fmt.group(int(stats.get("damage_done", 0))), Fmt.short_num(float(stats.get("damage_done", 0)))])
	UI.set_tile(_tiles[4], "HP lost", [Fmt.group(lost)])
	UI.set_tile(_tiles[5], "Time", [Fmt.mss(float(stats.get("time_s", 0.0)))])
	var vs: bool = outcome_v == "cleared" and float(game.get("time_s", 0.0)) > 0.0
	var words: Array = [["", "You", "Runner alone"]]
	if vs:
		words.append(["Time", Fmt.mss(float(stats.get("time_s", 0.0))), Fmt.mss(float(game["time_s"]))])
		words.append(["HP lost", Fmt.group(lost), Fmt.group(int(round(float(game.get("hp_lost", 0.0)))))])
	for k in range(_vs.size()):
		for c in range(3):
			_vs[k][c].text = str(words[k][c]) if vs else ""
			_vs[k][c].visible = vs
	_vs_head.visible = vs
	_vs_note.visible = vs
	var haul_y: float = HAUL_Y if vs else VS_Y
	_haul_head.position.y = haul_y
	for k in range(_haul.size()):
		_haul[k].position.y = haul_y + 30 + k * HAUL_ROW_H
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
		(run_button if run_way != "" else button).grab_focus()


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
	var out: Array = [_title, _sub, _vs_head, _vs_note, _haul_head, _note, button, run_button] + _haul
	for row in _vs:
		out.append_array(row)
	for t in _tiles:
		out.append(t["key"])
		out.append(t["value"])
	return out


func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size)
