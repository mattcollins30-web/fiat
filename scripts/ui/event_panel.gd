extends Panel
## A run event's choice (1 Nov, run events; the canvas's boards 1-3, docs/design/run_events.md): the panel under the
## scene, in the crates' and the rig's place, where "Get out now" and "Fill up, then go" live. Someone in need and A
## locked thing: the line, then a button an option with its cost and odds on its face, "Leave" last. A threat: what
## they are, your odds, what they carry, then "Get out now" or "Stand and fight". A trader: who, his standing and the
## scrap you carry, his shelf a row each with its price, the next step greyed, then "Done: back to it". Fixed geometry.

signal picked(key: String)         # an option, "out" (Get out now), "fight" (Stand and fight), "buy:<key>", "done"

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const LINE_Y := UI.HEAD_H + 4
const LINE_H := 28
const LINE_TEXT := Pal.CELL_TEXT_BIG + 2      # 20
const OPT_Y := LINE_Y + 2 * LINE_H + 8         # the options under the two lines
const OPT_H := 52
const OPT_GAP := 6
const FOOT_TEXT := Pal.CELL_TEXT
const FOOT_H := 22
const SHELF_Y := 64
const SHELF_H := 40                           # five rows (the fix round, U4): his four and the next step, over Done
const SHELF_GAP := 4
const PRICE_W := 140                  # "Materials ×3" (the re-review: the price as the standing line says it)
const OPTIONS := 3
const SHELF := 5
const DOGS_BTN_Y := LINE_Y + UI.TILE_H + 8 + 2 * LINE_H + 8     # the dogs' buttons under their line, the note under them (U11)

var _w := 0.0
var _h := 0.0
var _head: Label
var _lines: Array = []             # two labels: the event's line, wrapped
var _opts: Array = []              # {button, name, face} a row
var _feet: Array = []              # two labels: the foot note
var _tiles: Array = []             # the threat's three
var _out: Button                   # Get out now (a threat)
var _fight: Button                 # Stand and fight
var _name: Label                   # the trader's name
var _known: Label                  # his standing and your scrap
var _says: Label
var _shelf: Array = []             # {panel, text, price (Button), more (Label)} a row
var _done: Button
var _keys: Array = []              # the option keys on the buttons, in order
var _shelf_keys: Array = []
var fam := ""                      # the family on show
var _sig := ""
var out_text := ""                 # the run's own words for Get out (run.gd): "Get out now", or the way out's price (U2)


func _init(w: float, h: float) -> void:
	_w = w
	_h = h
	size = Vector2(w, h)
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 0))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_head = UI.head(self, Rect2(0, 0, w, UI.HEAD_H), "")
	for k in range(2):
		_lines.append(UI.label(self, Rect2(0, LINE_Y + k * LINE_H, w, LINE_H), "", "Regular", LINE_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	for k in range(OPTIONS):
		var b := UI.button(self, Rect2(0, OPT_Y + k * (OPT_H + OPT_GAP), w, OPT_H), false)
		b.pressed.connect(_opt.bind(k))
		var nm := UI.label(b, Rect2(14, 0, 10, OPT_H), "", "SemiBold", LINE_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var fc := UI.label(b, Rect2(14, 0, w - 28, OPT_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_opts.append({"button": b, "name": nm, "face": fc})
	var foot_y: float = OPT_Y + OPTIONS * (OPT_H + OPT_GAP) + 4
	for k in range(2):
		_feet.append(UI.label(self, Rect2(0, foot_y + k * FOOT_H, w, FOOT_H), "", "Regular", FOOT_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_tiles = UI.tile_row(self, 0, LINE_Y, w, 3)
	_out = UI.button(self, Rect2(0, h - Pal.BUTTON_H, (w - 12) / 2.0, Pal.BUTTON_H), true)
	_out.pressed.connect(func(): picked.emit("out"))
	_fight = UI.button(self, Rect2((w - 12) / 2.0 + 12, h - Pal.BUTTON_H, (w - 12) / 2.0, Pal.BUTTON_H), false)
	_fight.pressed.connect(func(): picked.emit("fight"))
	_name = UI.label(self, Rect2(0, 0, 10, 32), "", "SemiBold", Pal.CELL_TEXT_BIG + 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_known = UI.label(self, Rect2(0, 4, w, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_says = UI.label(self, Rect2(0, 34, w, 24), "", "Regular", Pal.CELL_TEXT + 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(SHELF):
		var y: float = SHELF_Y + k * (SHELF_H + SHELF_GAP)
		var p := UI.panel(self, Rect2(0, y, w, SHELF_H), UI.box(Pal.BG, 6))
		var tx := UI.label(p, Rect2(12, 0, w - 24 - PRICE_W - 12, SHELF_H), "", "SemiBold", Pal.CELL_TEXT + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var pr := UI.button(p, Rect2(w - 6 - PRICE_W, 4, PRICE_W, SHELF_H - 8), true)
		pr.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
		pr.pressed.connect(_buy.bind(k))
		var more := UI.label(p, Rect2(w - 12 - PRICE_W, 0, PRICE_W, SHELF_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_shelf.append({"panel": p, "text": tx, "price": pr, "more": more})
	_done = UI.button(self, Rect2(0, h - Pal.BUTTON_H, w, Pal.BUTTON_H), false)
	_done.pressed.connect(func(): picked.emit("done"))
	visible = false


func _opt(k: int) -> void:
	if k < _keys.size():
		picked.emit(str(_keys[k]))


func _buy(k: int) -> void:
	if k < _shelf_keys.size():
		picked.emit("buy:" + str(_shelf_keys[k]))


var redraws := 0                   # for the tests: the panel drawn again (U1: never as the dogs' seconds run)
## Everything off; each family turns its own on.
func _all_off() -> void:
	redraws += 1
	for n in [_head, _out, _fight, _name, _known, _says, _done] + _lines + _feet:
		n.visible = false
	for o in _opts:
		o["button"].visible = false
	for t in _tiles:
		t["panel"].visible = false
	for r in _shelf:
		r["panel"].visible = false


## The event on show, from the sim; hidden with none asking. Returns whether it shows.
func show_event(sim) -> bool:
	var ev: Dictionary = sim.event_now()
	var on: bool = not ev.is_empty() and (str(ev["state"]) == "ask")
	visible = on
	if not on:
		fam = ""
		_sig = ""
		return false
	fam = str(ev["fam"])
	# drawn again only when what it shows has moved (the shell asks ten times a second; a redraw under the mouse drops presses)
	# the dogs' countdown and the odds aren't in it (the fix round, U1: a redraw a second lost a held click): they move in
	# place below; the family and its line are (U7: two events alike in their options)
	var sig: String = str([fam, ev.get("line", ""), ev["state"], ev.get("bought", []), sim.event_options(), sim.trader_shelf(), out_text]
		+ ([sim.pack_scrap(sim.mission), sim.can_extract(), sim.pack_materials(sim.mission), int(sim.mission["cash"])] if fam == "trader" else []))     # the scrap the trader's alone (40-E review 1: a find in the dogs' 10 s lost a click)
	if fam == "threat":
		_threat_live(sim, ev)
	if sig == _sig:
		return true
	_sig = sig
	_all_off()
	_head.visible = true
	_head.text = str(Data.EVENT_FAMILIES[fam]["name"]).to_upper()
	match fam:
		"need", "locked", "danger", "stash", "body", "wreck", "broadcast", "weather":     # BUILD46-E: the other six alike
			_show_options(sim, ev)
		"threat":
			_show_threat(sim, ev)
		"trader":
			_show_trader(sim, ev)
	return true


func _show_options(sim, ev: Dictionary) -> void:
	for k in range(2):
		_lines[k].position.y = LINE_Y + k * LINE_H
		_feet[k].position.y = OPT_Y + OPTIONS * (OPT_H + OPT_GAP) + 4 + k * FOOT_H
	_lines_show(str(ev["line"]))
	var opts: Array = sim.event_options()
	_keys = opts.map(func(o): return str(o["key"]))
	for k in range(OPTIONS):
		var row: Dictionary = _opts[k]
		var b: Button = row["button"]
		b.visible = k < opts.size()
		if not b.visible:
			continue
		var o: Dictionary = opts[k]
		b.disabled = not bool(o["ok"])
		UI.style_button(b, false, "")
		_border(b, k == 0 and bool(o["ok"]))
		row["name"].text = str(o["text"])
		row["name"].size.x = ceilf(UI.text_width(row["name"], row["name"].text)) + 4
		var fx: float = 14.0 + row["name"].size.x + 16.0
		row["face"].position.x = fx
		row["face"].size.x = _w - 14.0 - fx
		UI.fit(row["face"], o["face"])
		row["name"].add_theme_color_override("font_color", Pal.TEXT if bool(o["ok"]) else Pal.TEXT_3)
	_feet_show(foot_words(sim, ev))


## The note under a family's options (BUILD46-E: a family each).
func foot_words(sim, ev: Dictionary) -> String:
	match fam:
		"need":
			return Words.EV["need_foot"] % sim.event_pron(ev)[0]
		"stash":
			return Words.EV["stash_tip_foot"] if bool(ev.get("tip", false)) else Words.EV["stash_foot"] % roundi(Data.STASH_TRIP * 100.0)
		"body":
			return Words.EV["body_foot"] % [roundi(Data.BODY_CLUE * 100.0), roundi((Data.BODY_GANG - 1.0) * 100.0), Data.BODY_GANG_NOTES, roundi(Data.BODY_HEAD_CUT * 100.0)]
		"locked", "danger", "wreck", "broadcast", "weather":
			return Words.EV[fam + "_foot"]
	return ""


## The first option's amber edge, as the canvas has it: the one most will take.
func _border(b: Button, lit: bool) -> void:
	var sb: StyleBoxFlat = (b.get_theme_stylebox("normal") as StyleBoxFlat).duplicate()
	sb.set_border_width_all(1)
	sb.border_color = Pal.ACCENT if lit else Pal.CARD_LINE
	b.add_theme_stylebox_override("normal", sb)
	b.set_meta("ui_style_normal", sb)


## What moves while the dogs stand, in place: the count down in their tile ("3 · 10 s"), the odds, Get out's words.
func _threat_live(sim, ev: Dictionary) -> void:
	var n: int = int(ev["n"])
	var left: int = ceili(maxf(0.0, float(ev.get("close_t", 0.0))))
	var crew: bool = str(ev.get("who", "dogs")) == "crew"     # BUILD46-E: a rival crew reads as the dogs do
	UI.set_tile(_tiles[0], Words.EV["crew_key" if crew else "dogs_key"], [Words.EV["dogs_val_in"] % [n, left], Words.EV["dogs_val"] % n])
	if sim.dogs_reading():
		UI.set_tile(_tiles[1], Words.EV["odds_key"], [Words.EV["odds_reading"]], Pal.TEXT_3)     # read a few ms a frame as they stand (BUILD43)
	else:
		var odds: float = sim.dogs_odds()
		UI.set_tile(_tiles[1], Words.EV["odds_key"], ["%d%%" % roundi(odds * 100.0)], Pal.GOOD if odds >= 0.75 else (Pal.WARN if odds >= 0.5 else Pal.BAD))
	if out_text != "" and _out.text != out_text:
		UI.fit_button(_out, [out_text, Words.EV["get_out"]])
	_out.disabled = not sim.can_extract()      # in place, as the rest of the dogs' live words


func _show_threat(sim, ev: Dictionary) -> void:
	_threat_live(sim, ev)
	UI.set_tile(_tiles[2], Words.EV["carry_key"], [carry_words(ev)])
	for t in _tiles:
		t["panel"].visible = true
	for k in range(2):
		_lines[k].position.y = LINE_Y + UI.TILE_H + 8 + k * LINE_H
	_lines_show(str(ev["line"]))
	_out.visible = true
	UI.fit_button(_out, [out_text if out_text != "" else Words.EV["get_out"], Words.EV["get_out"]])
	_out.disabled = not sim.can_extract()
	_out.position.y = DOGS_BTN_Y
	_fight.visible = true
	_fight.text = Words.EV["stand"]
	_fight.position.y = DOGS_BTN_Y
	for k in range(2):
		_feet[k].position.y = DOGS_BTN_Y + Pal.BUTTON_H + 8 + k * FOOT_H
	_feet_show(Words.EV["crew_foot"] if str(ev.get("who", "dogs")) == "crew" else Words.EV["dogs_foot"] % int(Data.DOGS_PUSH_S))


## What a threat carries, in its tile: the dogs nothing, a rival crew notes or a find (BUILD46-E).
static func carry_words(ev: Dictionary) -> String:
	if str(ev.get("who", "dogs")) != "crew":
		return Words.EV["carry_none"]
	return Words.EV["carry_find"] if str(ev.get("carry", "")) == "find" else Words.EV["carry_notes"] % int(ev.get("carry_n", 0))


func _show_trader(sim, ev: Dictionary) -> void:
	_head.visible = false
	_name.visible = true
	_name.text = str(Data.TRADERS[str(ev["who"])]["name"])
	_name.size.x = ceilf(UI.text_width(_name, _name.text)) + 4
	_known.visible = true
	_known.position.x = _name.size.x + 16
	_known.size.x = _w - _known.position.x
	var n: int = int(sim.trader_standing.get(str(ev["who"]), 0))     # as the visit found it: this visit's trades count as it ends
	var scrap: int = sim.pack_scrap(sim.mission)
	var nx: Array = sim.trader_next_step()
	if str(ev["who"]) == "vagabond":
		var tins: String = sim._cash_words(floorf(float(sim.mission["cash"])))     # BUILD46-E: tins and materials, his trade
		var mats: int = sim.pack_materials(sim.mission)
		if nx.is_empty():
			UI.fit(_known, [Words.EV["vag_known_top"][0] % [n, tins, mats], Words.EV["vag_known_top"][1] % [n, tins]])
		else:
			UI.fit(_known, [Words.EV["vag_known"][0] % [n, int(nx[0]), tins, mats], Words.EV["vag_known"][1] % [n, int(nx[0]), tins]])
	elif nx.is_empty():
		UI.fit(_known, Array(Words.EV["trader_known_top"]).map(func(f): return f % [n, scrap]))
	else:
		UI.fit(_known, Array(Words.EV["trader_known"]).map(func(f): return f % [n, int(nx[0]), scrap]))
	_says.visible = true
	UI.fit_sentences(_says, str(ev.get("says", "")))
	var rows: Array = sim.trader_shelf()
	_shelf_keys = rows.map(func(r): return str(r["key"]))
	var k := 0
	for r in rows:
		if k >= SHELF:
			break
		var row: Dictionary = _shelf[k]
		row["panel"].visible = true
		UI.fit(row["text"], [str(r["text"]) + (" · " + str(r["why"]) if str(r.get("why", "")) != "" else ""), str(r["text"]), str(r.get("short", r["text"]))])
		row["text"].add_theme_color_override("font_color", Pal.TEXT if bool(r["ok"]) or bool(r["bought"]) else Pal.TEXT_3)
		row["more"].visible = false
		var b: Button = row["price"]
		b.visible = true
		b.disabled = not bool(r["ok"])
		b.text = Words.EV["bought"] if bool(r["bought"]) else (Words.EV["take_it"] if int(r["price"]) <= 0 else price_words(sim, r))
		UI.style_button(b, bool(r["ok"]))
		k += 1
	if not nx.is_empty() and k < SHELF:
		var row: Dictionary = _shelf[k]
		row["panel"].visible = true
		UI.fit(row["text"], [Words.EV["step_at"] % [int(nx[0]), str(nx[1])], Words.cap1(str(nx[1]))])
		row["text"].add_theme_color_override("font_color", Pal.TEXT_3)
		row["price"].visible = false
		row["more"].visible = true
		row["more"].text = Words.EV["step_more"] % int(nx[2])
	_done.visible = true
	_done.text = Words.EV["done"]


## A shelf row's price on its button: the Scrap man's in scrap, the Vagabond's in tins or materials (BUILD46-E).
static func price_words(sim, r: Dictionary) -> String:
	match str(r.get("pay", "scrap")):
		"tins":
			return Words.EV["price_tins"] % sim._cash_words(float(r["price"]))
		"mat":
			return Words.EV["price_mat"] % int(r["price"])
	return Words.EV["price"] % int(r["price"])


func _lines_show(text: String) -> void:
	for l in _lines:
		l.visible = true
	UI.wrap(_lines, text)


func _feet_show(text: String) -> void:
	for l in _feet:
		l.visible = true
	UI.wrap(_feet, text)


## For the tests: the buttons on show, by what they do.
func buttons() -> Dictionary:
	var out := {}
	for k in range(_keys.size()):
		if k < OPTIONS and _opts[k]["button"].visible:
			out[_keys[k]] = _opts[k]["button"]
	if _out.visible:
		out["out"] = _out
	if _fight.visible:
		out["fight"] = _fight
	if _done.visible:
		out["done"] = _done
	for k in range(_shelf_keys.size()):
		if k < SHELF and _shelf[k]["price"].visible:
			out["buy:" + str(_shelf_keys[k])] = _shelf[k]["price"]
	return out


## Every box with its words on show, for the fit checks: [node, its box in this panel's space].
func boxes() -> Array:
	var out: Array = []
	for n in text_nodes():
		var p: Control = n.get_parent()
		var r := Rect2(n.position, n.size)
		if p != self:
			r.position += p.position
		out.append([n, r])
	return out


func text_nodes() -> Array:
	var out: Array = []
	if not visible:
		return out
	for n in [_head, _out, _fight, _name, _known, _says, _done] + _lines + _feet:
		if n.visible:
			out.append(n)
	for o in _opts:
		if o["button"].visible:
			out.append_array([o["name"], o["face"]])
	for t in _tiles:
		if t["panel"].visible:
			out.append_array([t["key"], t["value"]])
	for r in _shelf:
		if r["panel"].visible:
			out.append(r["text"])
			if r["price"].visible:
				out.append(r["price"])
			if r["more"].visible:
				out.append(r["more"])
	return out


