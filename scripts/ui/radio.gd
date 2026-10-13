extends Control
## The Radio as map juicing (9 Oct, docs/design/juicing.md, Radio-J A on the canvas; Matt: the Radio was "a ways
## off the PoE system of juicing a map with stupid modifiers for stupid rewards"). The sites with a ladder down
## the left - each its depth, its words as pips by tier, what it pays. The picked site on the right: the totals
## (you get / they bring), a row a word (tier, name, bite in amber, pay in green, its pool), the seven crafts in
## notes. The book under it: every word known, the rest as what would teach them; the map's standing words and
## Clear air's filter set there. Before the depths open: nothing on the air, the sky, the papers read.
##
## Signals: `acted` after anything changes; `choose(i, key)` for a craft that wants a word (Call in, Hold);
## `choose_book(kind)` for "standing0", "standing1", "filter" - main opens its menu for those.

signal acted
signal choose(i: int, key: String)
signal choose_book(kind: String)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const Atlas := preload("res://scripts/ui/atlas.gd")
const Words := preload("res://scripts/sim/words.gd")

const PAD := 20
const HEAD_H := Pal.BAND_H         # the rooms' one band (10 Oct, Bands-U A): 84 → 180
const BODY_Y := HEAD_H + 8
const LIST_W := 330
const ROW_H := 54                  # 74 → 54 (12 Oct): twelve sites on show with the Outskirts - the name and depth, then the pips and the pay on one line
const ROW_GAP := 6
const VIEW_W := 170                # the air / the map, at the band's right under its lines (12 Oct: the map moved here from Runs)
const VIEW_H := 28
const VIEW_Y := 88
const RIGHT_X := LIST_W + 12
const RIGHT_W := Pal.GRID_W - RIGHT_X
const DETAIL_H := 530              # 566 → 530: the words, the crafts and the hint, no slack
const WORD_H := 34
const WORD_GAP := 3
const WORDS_MAX := 8                # six of the site's own at most, and two standing words
const CRAFT_H := 56
const CRAFT_GAP := 6
const BOOK_Y := BODY_Y + DETAIL_H + 8
const BOOK_H := Pal.ROOM_H - BOOK_Y
const BOOK_COLS := 6
const PIP_W := 14
const HEARD_X := LIST_W + 40         # the last line heard: from past the band's words to its right edge
const HEARD_Y := HEAD_H - 44
var _heard: Label
var _heard_pill: Panel
const TIER_COLOURS := [Color("a9afb6"), Color("7fb2e5"), Color("e3a33b"), Color("b07be0")]
const POOL_COLOURS := {"general": Color("a9afb6"), "zone": Color("7fb2e5"), "deep": Color("b07be0"), "start": Color("a9afb6"), "paper": Color("a9afb6")}

var head_band := {}                # the heading's painted place (10 Oct, Rooms-B)
var sim
var selected := -1
var _kicker: Label
var _headline: Label
var _unit: Label
var _chips: Chips
var _rows: Array = []              # {button, name, depth, pips: [Panel], pay}
var _title: Label
var _sub: Label
var _odds: Label
var _get_box: Panel
var _get_head: Label
var _get: Label
var _bring_box: Panel
var _bring_head: Label
var _bring: Label
var _words: Array = []             # {panel, badge, badge_label, name, bite, pay, pool}
var _crafts: Array = []            # {button, name, price, words, key}
var _hint: Label
var _quiet: Array = []             # the campaign's lines: nothing on the air
var _book_title: Label
var _book_note: Label
var _book: Array = []              # labels, BOOK_COLS a row
var _stand: Array = []             # the standing words' buttons
var _filter: Button
var _shown := ""
var view := "air"                  # "air": the sites and their words; "map": the endgame's tree (12 Oct, from Runs)
var _air: Control                  # everything of the air's, shown or hidden together
var _atlas                         # the map (atlas.gd), the room's whole height
var _views: Array = []             # the two buttons, the air and the map


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	head_band = UI.head_art(head, "The radio")       # art/places/the_radio.png (Rooms-B)
	_kicker = UI.label(head, Rect2(PAD, 8, 330, 24), "The Radio", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, 330, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, 200, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(Pal.BAND_TEXT_W, 6)                 # down the shaded left under the headline (Bands-U A)
	_chips.position = Vector2(PAD, Pal.BAND_CHIPS_Y)
	head.add_child(_chips)
	# the last line heard on the air (12 Oct, the lore pass): at the band's foot, right, on a glass pill as Training's
	_heard_pill = UI.panel(head, Rect2(0, HEARD_Y, 10, 28), UI.box(Color(0.06, 0.07, 0.08, 0.62), 10))
	_heard_pill.visible = false
	_heard = UI.label(head, Rect2(HEARD_X, HEARD_Y, Pal.GRID_W - PAD - HEARD_X, 28), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for i in range(Data.TIERS.size()):
		var y: float = BODY_Y + i * (ROW_H + ROW_GAP)
		var b := Button.new()
		b.position = Vector2(0, y)
		b.size = Vector2(LIST_W, ROW_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick.bind(i))
		add_child(b)
		var r := {"button": b, "pips": []}
		r["name"] = UI.label(b, Rect2(12, 4, LIST_W - 90, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["depth"] = UI.label(b, Rect2(LIST_W - 130, 4, 118, 26), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
		for k in range(WORDS_MAX):
			var p := UI.panel(b, Rect2(12 + k * (PIP_W + 4), 35, PIP_W, 9), UI.box(Pal.RAIL_RULE, 3))
			r["pips"].append(p)
		r["pay"] = UI.label(b, Rect2(12 + WORDS_MAX * (PIP_W + 4) + 6, 27, LIST_W - 24 - WORDS_MAX * (PIP_W + 4) - 6, 24), "", "Regular", Pal.CELL_TEXT - 2, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
		_rows.append(r)
	var detail := UI.panel(self, Rect2(RIGHT_X, BODY_Y, RIGHT_W, DETAIL_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = RIGHT_W - 2 * PAD
	_title = UI.label(detail, Rect2(PAD, 8, 440, 36), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(detail, Rect2(PAD + 450, 14, iw - 450 - 330, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_odds = UI.label(detail, Rect2(PAD + iw - 320, 14, 320, 26), "", "Regular", Pal.CELL_TEXT, Pal.WARN, HORIZONTAL_ALIGNMENT_RIGHT, false)
	var half: float = (iw - 10) / 2.0
	_get_box = UI.panel(detail, Rect2(PAD, 52, half, 70), UI.box(Pal.CARD, 7, 1, Pal.GOOD.darkened(0.45)))
	_get_head = UI.label(_get_box, Rect2(14, 4, half - 28, 23), "YOU GET", "SemiBold", Pal.CELL_TEXT - 3, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
	_get = UI.label(_get_box, Rect2(14, 30, half - 28, 32), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
	_bring_box = UI.panel(detail, Rect2(PAD + half + 10, 52, half, 70), UI.box(Pal.CARD, 7, 1, Pal.WARN.darkened(0.45)))
	_bring_head = UI.label(_bring_box, Rect2(14, 4, half - 28, 23), "THEY BRING", "SemiBold", Pal.CELL_TEXT - 3, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT, false)
	_bring = UI.label(_bring_box, Rect2(14, 30, half - 28, 32), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(WORDS_MAX):
		var p := UI.panel(detail, Rect2(PAD, 132 + k * (WORD_H + WORD_GAP), iw, WORD_H), UI.box(Pal.CARD, 7, 1, Pal.CARD_LINE))
		var w := {"panel": p}
		w["badge"] = UI.panel(p, Rect2(10, 6, 40, 22), UI.box(TIER_COLOURS[0], 4))
		w["badge_label"] = UI.label(w["badge"], Rect2(0, -1, 40, 23), "", "SemiBold", Pal.CELL_TEXT - 3, Pal.BG, HORIZONTAL_ALIGNMENT_CENTER)
		w["name"] = UI.label(p, Rect2(62, 5, 230, 24), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		w["bite"] = UI.label(p, Rect2(300, 5, 330, 24), "", "Regular", Pal.CELL_TEXT, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT, false)
		w["pay"] = UI.label(p, Rect2(640, 5, iw - 640 - 100, 24), "", "Regular", Pal.CELL_TEXT, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
		w["pool"] = UI.label(p, Rect2(iw - 92, 5, 82, 24), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
		_words.append(w)
	var cw: float = (iw - (Data.CRAFTS.size() - 1) * CRAFT_GAP) / Data.CRAFTS.size()
	var cy: float = 132 + WORDS_MAX * (WORD_H + WORD_GAP) + 4
	for k in range(Data.CRAFTS.size()):
		var c: Dictionary = Data.CRAFTS[k]
		var b := Button.new()
		b.position = Vector2(PAD + k * (cw + CRAFT_GAP), cy)
		b.size = Vector2(cw, CRAFT_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_craft.bind(c["key"]))
		b.mouse_entered.connect(_hover.bind(c["key"]))
		b.mouse_exited.connect(_hover.bind(""))
		detail.add_child(b)
		UI.style_button(b, false)
		var t := {"button": b, "key": c["key"]}
		t["name"] = UI.label(b, Rect2(10, 2, cw - 20, 26), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["price"] = UI.label(b, Rect2(10, 2, cw - 20, 26), "", "Regular", Pal.CELL_TEXT - 3, Color("c9b98f"), HORIZONTAL_ALIGNMENT_RIGHT)
		t["words"] = UI.label(b, Rect2(10, 28, cw - 20, 23), "", "Regular", Pal.CELL_TEXT - 4, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		_crafts.append(t)
	_hint = UI.label(detail, Rect2(PAD, cy + CRAFT_H + 6, iw, 26), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(3):
		_quiet.append(UI.label(detail, Rect2(PAD, 60 + k * 34, iw, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var book := UI.panel(self, Rect2(RIGHT_X, BOOK_Y, RIGHT_W, BOOK_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_book_title = UI.label(book, Rect2(PAD, 6, 330, 28), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_book_note = UI.label(book, Rect2(PAD + 340, 8, iw - 340 - 3 * 214, 26), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		var sb := UI.button(book, Rect2(PAD + iw - (3 - k) * 214 + 6, 4, 208, 32), false)
		sb.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 2)
		sb.pressed.connect(func(): choose_book.emit("standing%d" % k))
		_stand.append(sb)
	_filter = UI.button(book, Rect2(PAD + iw - 214 + 6, 4, 208, 32), false)
	_filter.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 2)
	_filter.pressed.connect(func(): choose_book.emit("filter"))
	var bw: float = (iw - (BOOK_COLS - 1) * 6) / BOOK_COLS
	var rows: int = int(ceil(Data.WORDS.size() / float(BOOK_COLS)))
	for k in range(Data.WORDS.size()):
		var col: int = k % BOOK_COLS
		var row: int = k / BOOK_COLS
		_book.append(UI.label(book, Rect2(PAD + col * (bw + 6), 42 + row * ((BOOK_H - 50) / rows), bw, 23), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	# the air's whole room in one holder, so the map can take the room (12 Oct: the map moved here from Runs)
	_air = Control.new()
	_air.size = size
	_air.mouse_filter = Control.MOUSE_FILTER_PASS
	for ch in get_children():
		remove_child(ch)
		_air.add_child(ch)
	add_child(_air)
	_atlas = Atlas.new(Pal.ROOM_H)
	_atlas.visible = false
	_atlas.acted.connect(func(): acted.emit())
	add_child(_atlas)
	for k in range(2):
		var vb := UI.button(self, Rect2(Pal.GRID_W - PAD - (2 - k) * (VIEW_W + 6) + 6, VIEW_Y, VIEW_W, VIEW_H), false)
		vb.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 1)
		vb.pressed.connect(_pick_view.bind(["air", "map"][k]))
		_views.append(vb)


func show_state(s) -> void:
	sim = s
	if view == "map" and not sim.campaign_done():
		view = "air"
	_views[0].text = "The air"
	_views[1].text = "The Dial" if sim.campaign_done() else "The Dial · locked"     # the endgame's tree (13 Oct, Matt: was the map)
	_views[1].disabled = not sim.campaign_done()
	UI.style_button(_views[0], view == "air")
	UI.style_button(_views[1], view == "map")
	_air.visible = view == "air"
	_atlas.visible = view == "map"
	if view == "map":
		_shown = ""
		_atlas.show_state(sim)
		return
	if selected < 0 or not sim.tier_open(selected):
		selected = _first_site()
	var sig := "%d|%s|%s|%s|%s|%d|%s|%s|%s|%s|%s|%s|%d|%d|%s|%s" % [selected, str(sim.words), str(sim.sealed), str(sim.depth), str(sim.best_depth), sim.notes, str(sim.book.size()) + "/" + str(sim.heard.size()), str(sim.atlas),
		str(sim.standing), sim.filtered, str(sim.on_mission()), str(sim.yard_picks.get("radio", [])), int(sim.odds_now(selected) * 100.0) if selected >= 0 else 0,
		sim.yard_rank("radio"), sim.sky_words(selected) if selected >= 0 else "", str(sim.odds_settled(selected)) if selected >= 0 else ""]
	if sig == _shown:
		return
	_shown = sig
	var on_air: bool = sim.campaign_done()
	var juiced := 0
	for i in range(Data.TIERS.size()):
		if sim.juiceable(i) and not sim.words[i].is_empty():
			juiced += 1
	UI.fit(_kicker, ["The Radio · on the air" if on_air else "The Radio · nothing on the air", "The Radio"])
	_headline.text = ("%d" % juiced) if on_air else "Quiet"
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.size.x = 350 - _unit.position.x
	UI.fit(_unit, (["sites juiced", "juiced"] if juiced != 1 else ["site juiced", "juiced"]) if on_air else ["until the depths", ""])
	var known: int = sim.words_known().size()
	_chips.show_chips([{"tag": "Notes", "forms": ["%d" % sim.notes], "colour": Color("c9b98f")},
		{"tag": "Codes known", "forms": ["%d of %d" % [known, Data.WORDS.size()]], "colour": Pal.TEXT_2},
		{"forms": [sim.sky_words(selected) if selected >= 0 else "", ""], "colour": Pal.TEXT_3},
		{"forms": ["codes stay until you change them", "they stay"], "colour": Pal.TEXT_3}], 3)
	_show_heard()
	for i in range(_rows.size()):
		_show_row(i)
	_show_detail(on_air)
	_show_book(on_air)


## The last line the radio said, on its pill; nothing before the first.
func _show_heard() -> void:
	var line := ""
	if not sim.heard.is_empty():
		var r: Dictionary = sim.radio_line(str(sim.heard.back()))
		line = str(r.get("text", ""))           # no speaker (13 Oct, Matt)
	UI.fit(_heard, [line, line.get_slice(". ", 0) + ("." if line.contains(". ") else ""), ""] if line != "" else [""])
	_heard_pill.visible = _heard.text != ""
	if _heard_pill.visible:
		var w: float = ceilf(UI.text_width(_heard, _heard.text)) + 24.0
		_heard_pill.position.x = _heard.position.x + _heard.size.x + 12.0 - w
		_heard_pill.size.x = w


func _first_site() -> int:
	for i in range(Data.TIERS.size()):
		if sim.juiceable(i):
			return i
	return 0


func _show_row(i: int) -> void:
	var r: Dictionary = _rows[i]
	var open: bool = sim.tier_open(i)
	r["button"].visible = open
	if not open:
		return
	var on: bool = i == selected
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var sb := UI.box(Pal.CARD if on else (Pal.BUTTON if st == "hover" else Pal.PANEL), 7, 2 if on else 1, Pal.ACCENT if on else Pal.CARD_LINE)
		if st == "focus":
			sb = UI.box(Color.TRANSPARENT, 7, 2, Pal.TEXT)
		r["button"].add_theme_stylebox_override(st, sb)
	UI.fit(r["name"], [sim.tier(i)["name"], str(sim.tier(i)["name"]).trim_prefix("The ")])
	var dtext := "D%d" % int(sim.depth[i])
	if sim.sealed[i]:
		dtext = "◈ sealed · " + dtext
	UI.fit(r["depth"], [dtext, "D%d" % int(sim.depth[i])])
	var mx: int = sim.max_words(i) if sim.juiceable(i) else 0
	for k in range(WORDS_MAX):
		var p: Panel = r["pips"][k]
		p.visible = k < mx
		if k < mx:
			var col: Color = Pal.RAIL_RULE
			if k < sim.words[i].size():
				col = TIER_COLOURS[clampi(sim.word_tier_now(i, int(sim.words[i][k]["t"])), 1, 4) - 1]
			(p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = col
	var pay: String = ""
	if sim.juiceable(i):
		pay = sim.word_total_words(i)[0]
	var plain: String = "silent" if sim.juiceable(i) else ("plain: codes from depth 2" if sim.campaign_done() else "plain")
	UI.fit(r["pay"], [_cap(pay) if pay != "" else plain, _cap(pay.get_slice(" · ", 0)) if pay != "" else plain, _cap(pay.get_slice(" · ", 0).get_slice(" ", 0)) if pay != "" else plain.get_slice(":", 0)])
	r["pay"].add_theme_color_override("font_color", Pal.GOOD if pay != "" else Pal.TEXT_3)


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


func _show_detail(on_air: bool) -> void:
	var i := selected
	var live: bool = on_air and i >= 0 and sim.juiceable(i)
	for l in _quiet:
		l.visible = not on_air
	for n in [_get_box, _bring_box, _hint]:
		n.visible = on_air
	for c in _crafts:
		c["button"].visible = on_air
	if not on_air:
		_title.size.x = 440
		UI.fit(_title, ["Nothing on the air"])
		UI.fit(_sub, [""])
		UI.fit(_odds, [""])
		UI.fit(_quiet[0], ["The depths open when the City's head is beaten. Until then the sites are as they are; only the sky changes them.", "The depths open when the campaign is done; until then only the sky changes a site."])
		UI.fit(_quiet[1], [_cap(sim.sky_words(i)) + ".", ""])
		UI.fit(_quiet[2], ["Papers you read now are kept: each carries a code the Radio keeps for when the depths open. %d read so far." % sim.book.size(), "%d papers read: each carries a code." % sim.book.size()])
		for w in _words:
			w["panel"].visible = false
		return
	var t: Dictionary = sim.tier(i)
	var zone: String = Data.ZONES[int(t["zone"])]["name"]
	_title.size.x = 440
	UI.fit(_title, [t["name"]])
	_title.size.x = ceilf(UI.text_width(_title, _title.text)) + 2
	_sub.position.x = _title.position.x + _title.size.x + 16
	_sub.size.x = _odds.position.x - 16 - _sub.position.x
	var cap: int = sim.word_tier_cap(int(sim.depth[i]))
	var tiers: String = ("tiers I-%s" % Data.WORD_TIER_NAMES[cap - 1]) if cap > 1 else "tier I"
	if live:
		UI.fit(_sub, ["%s · depth %d · %s · %d of %d codes" % [zone, int(sim.depth[i]), tiers, sim.words[i].size(), sim.max_words(i)],
			"D%d · %s · %d of %d codes" % [int(sim.depth[i]), tiers, sim.words[i].size(), sim.max_words(i)], "D%d · %d of %d" % [int(sim.depth[i]), sim.words[i].size(), sim.max_words(i)], "D%d" % int(sim.depth[i])])
	else:
		UI.fit(_sub, ["%s · depth %d · plain: codes from depth 2" % [zone, int(sim.depth[i])], "D%d · codes from depth 2" % int(sim.depth[i]), "D%d" % int(sim.depth[i])])
	var odds: float = sim.odds_now(i)
	UI.fit(_odds, ["odds %s to clear" % Fmt.pct(odds) if sim.odds_settled(i) else "reading the odds", Fmt.pct(odds) if sim.odds_settled(i) else "reading"])
	var tw: Array = sim.word_total_words(i) if live else ["", ""]
	UI.fit(_get, [_cap(tw[0]) if tw[0] != "" else "Nothing yet", _cap(tw[0]).get_slice(" · ", 0) if tw[0] != "" else "Nothing"])
	UI.fit(_bring, [_cap(tw[1]) if tw[1] != "" else "Nothing yet", _cap(tw[1]).get_slice(" · ", 0) if tw[1] != "" else "Nothing"])
	var act: Array = sim.active_words(i) if live else []
	for k in range(WORDS_MAX):
		var w: Dictionary = _words[k]
		var on: bool = k < act.size()
		w["panel"].visible = on
		if not on:
			continue
		var name: String = act[k][0]
		var tier: int = int(act[k][1])
		var standing: bool = not (name in sim.word_names(i))
		(w["badge"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = TIER_COLOURS[clampi(tier, 1, 4) - 1]
		w["badge_label"].text = Data.WORD_TIER_NAMES[clampi(tier, 1, 4) - 1]
		UI.fit(w["name"], [name])
		var ww: Array = sim.word_words(name, tier)
		UI.fit(w["bite"], ["▲ " + _cap(ww[0]), "▲ " + _cap(ww[0].get_slice(", ", 0))])
		UI.fit(w["pay"], ["● " + _cap(ww[1]), "● " + _cap(ww[1].get_slice(", ", 0))])
		var learn: String = str(Data.word_of(name)["learn"])
		var pool: String = "standing" if standing else {"start": "general", "paper": "general", "zone": "zone", "deep": "deep"}[learn]
		UI.fit(w["pool"], [pool])
		w["pool"].add_theme_color_override("font_color", Pal.ACCENT if standing else POOL_COLOURS.get(learn, Pal.TEXT_3))
	for c in _crafts:
		var key: String = c["key"]
		var cd := Data.craft_of(key)
		var why: String = sim.word_craft_block(i, key)
		c["button"].disabled = why != ""
		UI.fit(c["name"], [cd["name"]])
		c["price"].text = "%d n" % sim.word_craft_cost(i, key)
		var room: float = c["name"].size.x - UI.text_width(c["name"], c["name"].text) - 12.0
		if UI.text_width(c["price"], c["price"].text) > room:
			c["price"].text = "%d" % sim.word_craft_cost(i, key)
		UI.fit(c["words"], [str(cd["words"]), str(cd["words"]).get_slice(";", 0), ""])
	_hover("")


func _hover(key: String) -> void:
	if sim == null or selected < 0 or not sim.campaign_done():
		return
	var i := selected
	if key == "":
		var note: String = "Crafts cost notes × the site's depth; the codes stay until you change them."
		if sim.sealed[i]:
			note = "Sealed by a Twist: nothing but Clear, at ten times the price."
		elif not sim.juiceable(i):
			note = "Codes from depth 2: step the ladder down on the Map."
		UI.fit(_hint, [note, note.get_slice(";", 0) + "."])
		return
	var cd := Data.craft_of(key)
	var why: String = sim.word_craft_block(i, key)
	var line: String = "%s · %s · %d notes%s" % [cd["name"], str(cd["sentence"]).trim_suffix("."), sim.word_craft_cost(i, key), "" if why == "" else " · " + why]
	UI.fit(_hint, [line, "%s · %d notes%s" % [cd["name"], sim.word_craft_cost(i, key), "" if why == "" else " · " + why]])


func _show_book(on_air: bool) -> void:
	var known: Array = sim.words_known() if on_air else []
	UI.fit(_book_title, ["The book · %d code%s known" % [known.size(), "" if known.size() == 1 else "s"], "The book · %d" % known.size()])
	UI.fit(_book_note, ["a paper read gives its code", "papers carry codes", ""])
	for k in range(Data.WORDS.size()):
		var w: Dictionary = Data.WORDS[k]
		var l: Label = _book[k]
		var name: String = w["name"]
		if name in known:
			var tag: String = "  ✕" if (name == sim.filtered and sim.atlas_rank("clear_air") > 0) else ("  ★" if name in sim.standing else "")
			UI.fit(l, [name + tag, name])
			l.add_theme_color_override("font_color", POOL_COLOURS.get(str(w["learn"]), Pal.TEXT_2))
		else:
			var how: String = "· · ·"
			match str(w["learn"]):
				"paper":
					how = "? %s" % str(w["paper"]).trim_prefix("A ").trim_prefix("An ")
				"deep":
					how = "? D%d paper" % int(w["depth"])
				"zone":
					how = "? %s at D2" % str(Data.ZONES[int(w["zone"])]["name"]).trim_prefix("The ")
			UI.fit(l, [how, "?"])
			l.add_theme_color_override("font_color", Pal.TEXT_3.darkened(0.25))
	for k in range(2):
		var b: Button = _stand[k]
		b.visible = on_air and sim.standing_open(k)
		if b.visible:
			var sw: String = sim.standing[k] if k < sim.standing.size() else ""
			b.text = ("★ %s" % sw) if sw != "" else "★ Standing code"
			if UI.text_width(b, b.text) + 24.0 > b.size.x:
				b.text = "★ " + sw.get_slice(" ", 0) if sw != "" else "★ Standing"
	_filter.visible = on_air and sim.atlas_rank("clear_air") > 0
	if _filter.visible:
		_filter.text = ("✕ %s" % sim.filtered) if sim.filtered != "" else "✕ Never hear…"
		if UI.text_width(_filter, _filter.text) + 24.0 > _filter.size.x:
			_filter.text = "✕ " + sim.filtered.get_slice(" ", 0)


func _pick(i: int) -> void:
	selected = i
	_shown = ""
	acted.emit()


func _craft(key: String) -> void:
	if selected < 0:
		return
	if key == "call" or key == "hold":
		if sim.can_word_craft(selected, key):
			choose.emit(selected, key)
		return
	if sim.word_craft(selected, key):
		_shown = ""
		acted.emit()


## For the smoke.
func row(i: int) -> Dictionary:
	return _rows[i]


func craft_button(key: String) -> Button:
	for c in _crafts:
		if c["key"] == key:
			return c["button"]
	return null


func word_row(k: int) -> Dictionary:
	return _words[k]


## The air or the map (12 Oct): the map once the campaign's done.
func _pick_view(v: String) -> void:
	if v == "map" and not sim.campaign_done():
		return
	view = v
	_shown = ""
	show_state(sim)
	acted.emit()


## The tests' hands on the map: a rank of a passive, and the map started again.
func _rank(key: String) -> void:
	_atlas.selected = key
	_atlas._on_take()


func _reset_map() -> void:
	_atlas._on_reset()


func text_nodes() -> Array:
	if view == "map":
		return _views + _atlas.text_nodes()
	var out: Array = [_kicker, _headline, _unit, _title, _sub, _odds, _book_title, _book_note, _heard] + _views
	out.append_array(_chips.text_nodes())
	for r in _rows:
		if r["button"].visible:
			out.append_array([r["name"], r["depth"], r["pay"]])
	if _get_box.visible:
		out.append_array([_get_head, _get, _bring_head, _bring, _hint])
	for w in _words:
		if w["panel"].visible:
			out.append_array([w["name"], w["bite"], w["pay"], w["pool"], w["badge_label"]])
	for c in _crafts:
		if c["button"].visible:
			out.append_array([c["name"], c["price"], c["words"]])
	for l in _quiet:
		if l.visible:
			out.append(l)
	out.append_array(_book)
	for b in _stand + [_filter]:
		if b.visible:
			out.append(b)
	return out


func line_pairs() -> Array:
	if view == "map":
		return []                          # the map's heads stack their lines (Runs never paired them either)
	var out: Array = [[_headline, _unit]]
	for r in _rows:
		if r["button"].visible:
			out.append([r["name"], r["depth"]])
	for c in _crafts:
		if c["button"].visible:
			out.append([c["name"], c["price"]])
	return out
