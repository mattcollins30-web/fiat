extends Control
## The Map's fifth tab, the order (18 Oct, docs/design/rebuild.md §5; the canvas "Fiat – The rebuild", Order): the
## true pinnacles as three columns - their place's art, who holds it, the level, the odds, what they drop - and Go, or
## the rebuild that opens them. The art is a stand-in plate until the slice reads (Matt's call 6).
##
## Signals: `acted` after a run sets off.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const COL_GAP := 16
@warning_ignore("integer_division")
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3
const PAD := 20
const INNER := COL_W - 2 * PAD
const ART_H := 300
const LINE_H := 28

var sim
var only := ""                     # the drawn Map (19 Oct): one place's card, at the Map's right, the pin picked
var _cols: Array = []               # {panel, art, state, place, who, words: [Label, Label], chips, odds, drops_head, drops, button, note, key}
var _shown := ""


func _init(top: float) -> void:
	position = Vector2(0, top)
	size = Vector2(Pal.GRID_W, Pal.ROOM_H - top)
	mouse_filter = Control.MOUSE_FILTER_PASS
	for k in range(Data.PINNACLES.size()):
		var p: Dictionary = Data.PINNACLES[k]
		var x: float = k * (COL_W + COL_GAP)
		var panel := UI.panel(self, Rect2(x, 0, COL_W, size.y), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
		panel.clip_contents = true
		var c := {"panel": panel, "key": p["key"]}
		var art := TextureRect.new()
		art.position = Vector2(1, 1)
		art.size = Vector2(COL_W - 2, ART_H)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture = UI.place_texture(str(p["art"]))
		panel.add_child(art)
		c["art"] = art
		c["state"] = UI.label(panel, Rect2(PAD, 14, INNER, 24), "", "SemiBold", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.track(c["state"], 2)
		c["place"] = UI.label(panel, Rect2(PAD, ART_H - 56, INNER, 44), "", "SemiBold", Pal.HEADLINE - 6, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.shadow(c["state"])
		UI.shadow(c["place"])
		var y := ART_H + 16.0
		c["who"] = UI.label(panel, Rect2(PAD, y, INNER, 34), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		y += 38
		c["words"] = [UI.label(panel, Rect2(PAD, y, INNER, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false),
			UI.label(panel, Rect2(PAD, y + LINE_H, INNER, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)]
		y += 2 * LINE_H + 10
		c["chips"] = Chips.new(INNER, 3)
		c["chips"].position = Vector2(PAD, y)
		panel.add_child(c["chips"])
		y += Chips.CHIP_H + 14
		c["odds"] = UI.label(panel, Rect2(PAD, y, INNER, 30), "", "SemiBold", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		y += 42
		c["drops_head"] = UI.head(panel, Rect2(PAD, y, INNER, UI.HEAD_H), "Drops")
		y += UI.HEAD_H + 4
		c["drops"] = UI.label(panel, Rect2(PAD, y, INNER, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var fy: float = size.y - PAD - Pal.BUTTON_H
		c["button"] = UI.button(panel, Rect2(PAD, fy, INNER, Pal.BUTTON_H), true)
		c["button"].pressed.connect(_go.bind(p["key"]))
		c["note"] = UI.label(panel, Rect2(PAD, fy, INNER, Pal.BUTTON_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
		_cols.append(c)


func show_state(s) -> void:
	sim = s
	var reads := ""
	for p in Data.PINNACLES:
		reads += str(sim.order_odds_now(p["key"]))
	var sig := "%s|%s|%s|%d|%d|%d|%s" % [str(sim.rebuilt), str(sim.order_beaten), reads, sim.reach, int(sim.on_mission()), int(sim.hp), str(sim.can_deploy())]
	sig += "|" + str(Data.PINNACLES.map(func(pn): return sim.order_known(str(pn["key"]))))     # the names scramble with it (20 Oct)
	if sig == _shown:
		return
	_shown = sig
	for c in _cols:
		_show_col(c)


func _show_col(c: Dictionary) -> void:
	var k: String = c["key"]
	var p: Dictionary = Data.pinnacle(k)
	var open: bool = sim.order_open(k)
	c["state"].text = "OPEN" if open else "SHUT"
	c["state"].add_theme_color_override("font_color", Pal.ACCENT if open else Pal.TEXT_3)
	c["art"].modulate = Color(0.75, 0.75, 0.75) if open else Color(0.3, 0.3, 0.32)
	var known: bool = sim.order_known(k)     # 20 Oct: scrambled till found
	var en := func(t: String) -> String: return t if known else Fmt.scramble(t)
	c["place"].text = en.call(str(p["place"]))
	c["place"].add_theme_color_override("font_color", Pal.TEXT if open else Pal.TEXT_2)
	c["who"].text = en.call(str(p["who"]))
	c["who"].add_theme_color_override("font_color", Pal.TEXT if open else Pal.TEXT_2)
	UI.wrap(c["words"], en.call(str(Words.PINNACLE_WORDS.get(k, ""))))
	var beaten: int = int(sim.order_beaten.get(k, 0))
	var chips: Array = [{"forms": ["Level %d" % sim.order_level(k)], "colour": Pal.TEXT_2}]
	if beaten > 0:
		chips.append({"forms": ["Beaten %d" % beaten], "colour": "good"})
	c["chips"].visible = open
	c["chips"].show_chips(chips if open else [], 1)
	if open:
		var od: Array = sim.order_odds_now(k)
		var settled: bool = bool(od[1])
		var odds: float = float(od[0])
		var tone := "good" if odds >= 0.9 else ("warn" if odds >= 0.6 else "bad")
		UI.fit(c["odds"], ["%s to clear · %s" % [Fmt.pct(odds), Words.odds_words(odds).to_lower()], "%s to clear" % Fmt.pct(odds)] if settled else ["Reading the odds"])
		c["odds"].add_theme_color_override("font_color", Pal.tone_color(tone) if settled else Pal.TEXT_3)
	else:
		c["odds"].text = ""
	var drop: Array = []
	if p.has("first") and beaten == 0:
		drop.append(en.call(sim.thing_label(str(p["first"]))))
	if str(p.get("drop", "")) != "":
		drop.append(en.call(sim.thing_label(str(p["drop"]))))
	var u_words: String = "their unique" if beaten > 0 else en.call(str(p["unique"]))
	UI.fit(c["drops"], [" · ".join(drop + [u_words]), " · ".join(drop + ["their unique"]), " · ".join(drop)])
	var why: String = sim.order_block(k)
	c["button"].visible = open and why == ""
	c["note"].visible = not c["button"].visible
	UI.fit_button(c["button"], ["Go: %s" % Words.mid(en.call(str(p["place"]))), "Go"])
	UI.fit(c["note"], [why, ""])
	(c["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.ACCENT if open else Pal.CARD_LINE


func _go(k: String) -> void:
	if sim != null and sim.deploy_order(k):
		_shown = ""
		acted.emit()


## One place's card at the Map's right (the drawn Map, 19 Oct): the pin picked; "" shows all three (unused now).
func set_only(k: String) -> void:
	only = k
	for n in range(_cols.size()):
		var c: Dictionary = _cols[n]
		c["panel"].visible = k == "" or c["key"] == k
		c["panel"].position.x = (2 * (COL_W + COL_GAP)) if k != "" else n * (COL_W + COL_GAP)


## For the tests: a column by its pinnacle's key.
func col(k: String) -> Dictionary:
	for c in _cols:
		if c["key"] == k:
			return c
	return {}


func text_nodes() -> Array:
	var out: Array = []
	for c in _cols:
		if not c["panel"].visible:
			continue
		out.append_array([c["state"], c["place"], c["who"], c["odds"], c["drops_head"], c["drops"]] + c["words"])
		if c["chips"].visible:
			out.append_array(c["chips"].text_nodes())
		if c["button"].visible:
			out.append(c["button"])
		if c["note"].visible:
			out.append(c["note"])
	return out
