extends Control
## The pick panel (Pick-A, 6 Oct): the same column twice, so the pick and what's
## fitted in its slot read side by side. Each column: a kicker with the cells
## and a price tag, then the item head (name, chips, the figure, what it takes,
## the affixes as chips). The foot: the verdict and the deltas against the
## fitted, the item's own line under them (or a hint, when there is one), and
## the buttons at the right. The run's pack and the Lock-up's stash share it,
## so the two read the same. Each column sits in its own box on the run
## screen's line (7 Oct, Pick-B), the pick's in the accent, so two pieces of
## gear read as two pieces side by side; the box runs BOX_OUT past the column
## each side, so the column's words keep their width.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const ItemHead := preload("res://scripts/ui/item_head.gd")

const PAD := 20
const KICK_Y := 8
const KICK_H := 24
const HEAD_Y := KICK_Y + KICK_H + 4                           # 36
const FOOT_H := 44
const BUTTONS := 3
const DELTAS := 4
const LINES := 4                                              # the right column's lines when nothing is fitted (a med, a part, a paper)
const TAG_PAD := 8
const BOX_OUT := 8                                            # each piece in its own box (7 Oct): the run screen's line, drawn this far outside the column, so the column keeps its width (the words were cut for it at first)
const BOX_Y := 2

var w: int
var h: int
var col_w: int
var foot_y: int
var _panel: Panel
var _boxes: Array[Panel] = []                                 # one a column: the pick's lined in the accent, the fitted's in the card line
var _kickers: Array[Label] = []
var _tags: Array[Panel] = []
var _tag_labels: Array[Label] = []
var _heads: Array = []                                        # two ItemHeads
var _right_title: Label                                       # the right column as words: a title and lines
var _right_lines: Array[Label] = []
var _empty_title: Label                                       # nothing picked: a title and lines across the panel
var _empty_lines: Array[Label] = []
var _verdict: Label
var _deltas: Array[Label] = []
var _words: Label                                             # the foot's line: the item's own line, always there (18 Oct, Matt: it moved about)
var _flavour_text := ""
var _buttons: Array[Button] = []
var _actions: Array = []
## The compare's three readings (29 Oct, the Compare board's layout A): in the right column under the worn piece's
## name, a row each - its words, the found piece's figure against the worn's - and a small line under it.
const READINGS := 3
const READ_Y := 40                                            # under the right column's title
const READ_ROW := 24
const READ_LINE := 18
const READ_GAP := 4
var _reads: Array = []                                        # [{label, fig, line}]
var readings: Array = []                                      # the readings showing, as the sim gave them (the tests')


func _init(width: int, height: int) -> void:
	w = width
	h = height
	@warning_ignore("integer_division")
	col_w = (w - 3 * PAD) / 2
	foot_y = h - 8 - FOOT_H
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_panel = UI.panel(self, Rect2(0, 0, w, h), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	for k in range(2):
		var x: int = PAD + k * (col_w + PAD)
		var box := UI.panel(_panel, Rect2(x - BOX_OUT, BOX_Y, col_w + 2 * BOX_OUT, foot_y - 8 - BOX_Y), UI.box(Color.TRANSPARENT, 8, 1, Pal.ACCENT if k == 0 else Pal.CARD_LINE))
		box.visible = false
		_boxes.append(box)
		var cx: int = x
		var cw: int = col_w
		_kickers.append(UI.head(_panel, Rect2(cx, KICK_Y, cw - 100, KICK_H), ""))
		var tag := UI.panel(_panel, Rect2(cx + cw - 10, KICK_Y + 1, 10, KICK_H - 2), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
		_tags.append(tag)
		_tag_labels.append(UI.label(tag, Rect2(TAG_PAD, 0, 10, KICK_H - 2), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT))
		var head := ItemHead.new(cw, true)
		head.position = Vector2(cx, HEAD_Y)
		head.visible = false
		_panel.add_child(head)
		_heads.append(head)
	var rx: int = PAD * 2 + col_w
	var rw: int = col_w
	_right_title = UI.label(_panel, Rect2(rx, HEAD_Y, rw, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(LINES):
		_right_lines.append(UI.label(_panel, Rect2(rx, HEAD_Y + 40 + i * 28, rw, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(READINGS):
		var ry: int = HEAD_Y + READ_Y + i * (READ_ROW + READ_LINE + READ_GAP)
		_reads.append({"label": UI.label(_panel, Rect2(rx, ry, rw, READ_ROW), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false),
			"fig": UI.label(_panel, Rect2(rx, ry, rw, READ_ROW), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false),
			"line": UI.label(_panel, Rect2(rx, ry + READ_ROW, rw, READ_LINE), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)})
	_empty_title = UI.label(_panel, Rect2(PAD, 10, w - 2 * PAD, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(LINES):
		_empty_lines.append(UI.label(_panel, Rect2(PAD, 48 + i * 28, w - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_verdict = UI.label(_panel, Rect2(PAD, foot_y, 10, 24), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(DELTAS):
		_deltas.append(UI.label(_panel, Rect2(PAD, foot_y, 10, 24), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false))
	_words = UI.label(_panel, Rect2(PAD, foot_y + 24, 10, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(BUTTONS):
		var b := UI.button(_panel, Rect2(0, foot_y, 240, FOOT_H), i == 0)
		b.pressed.connect(_press.bind(i))
		b.visible = false
		_buttons.append(b)
		_actions.append(Callable())


# ------------------------------------------------------------------ showing

## Nothing picked: a title and lines across the panel; the caller sets the buttons after.
func show_empty(title: String, lines: Array) -> void:
	_clear()
	_empty_title.visible = true
	_empty_title.text = title
	for i in range(LINES):
		_empty_lines[i].visible = true
		_empty_lines[i].text = str(lines[i]) if i < lines.size() else ""


## The pick in the left column. `kicker` is its place ("The pick · in the pack"),
## the cells are added; `tail` is the head's tail (what it takes).
func show_pick(it: Dictionary, sim, kicker: String, tail = "", extra = "") -> void:
	_clear()
	_boxes[0].visible = true
	_kickers[0].visible = true
	_kickers[0].text = (kicker + " · " + _cells(it)).to_upper()
	_tag(0, Fmt.money(sim.sell_price(it)))
	if Items.is_paper(it):
		_tags[0].visible = false              # a paper's worth adds nothing (16 Oct, Matt): the kicker takes the width
		_kickers[0].size.x = col_w
	_heads[0].visible = true
	_heads[0].show_item(it, sim, tail, extra, false)
	if it.has("unique"):
		_flavour_text = Words.UNIQUES.get(it["unique"], Words.item_words(it["base"]))
	elif Items.is_paper(it):
		_flavour_text = Words.paper_words(it["base"], sim.room_open("radio"))     # the code encrypted till the Radio (15 Oct)
	else:
		_flavour_text = Words.item_words(it["base"])
	_lay_flavour()


## The right column as the fitted item, laid the same as the pick.
func show_fitted(fitted: Dictionary, sim, kicker := "Fitted now", tail = "", extra = "") -> void:
	_boxes[1].visible = true
	_kickers[1].visible = true
	_kickers[1].text = (kicker + " · " + _cells(fitted)).to_upper()
	_tag(1, Fmt.money(sim.sell_price(fitted)))
	_heads[1].visible = true
	_heads[1].show_item(fitted, sim, tail, extra, false)


## The right column as the compare's readings (29 Oct, layout A): the worn piece's kicker, price and name, then a row a
## reading - its words, the found piece's figure against the worn's (in the tone of which is ahead), and the small line
## under it. `unit` "dmg/s" for a gun; "" for a body piece, read as the odds against the worn.
func show_readings(fitted: Dictionary, sim, rows: Array, unit: String, kicker := "Fitted now") -> void:
	_boxes[1].visible = true
	_kickers[1].visible = true
	_kickers[1].text = (kicker + " · " + _cells(fitted)).to_upper()
	_tag(1, Fmt.money(sim.sell_price(fitted)))
	_right_title.visible = true
	_right_title.add_theme_color_override("font_color", Pal.TEXT)
	UI.fit(_right_title, [Items.full_name(fitted), str(fitted["base"])])
	readings = rows
	for i in range(READINGS):
		var r: Dictionary = _reads[i]
		var on: bool = i < rows.size()
		for k in ["label", "fig", "line"]:
			r[k].visible = on
		if not on:
			continue
		var row: Dictionary = rows[i]
		var f: float = float(row["found"])
		var wv: float = float(row["worn"])
		var figs: Array = []
		if unit != "":
			figs = ["%s against %s %s" % [_num(f), _num(wv), unit], "%s against %s" % [_num(f), _num(wv)], "%s / %s" % [_num(f), _num(wv)]]
		else:
			var rel: float = (f - wv) / maxf(wv, 0.000001) * 100.0
			figs = ["%s%.0f%% odds" % ["+" if rel >= 0.0 else "−", absf(rel)], "%s%.0f%%" % ["+" if rel >= 0.0 else "−", absf(rel)]]
		var ahead: bool = f > wv * 1.0005
		var behind: bool = f < wv * 0.9995
		r["fig"].add_theme_color_override("font_color", Pal.GOOD if ahead else (Pal.BAD if behind else Pal.TEXT_2))
		r["figs"] = figs
		UI.fit(r["line"], row["line"] if row["line"] is Array else [str(row["line"])])
	# one figure form on every row (the fix round, 29 Oct, the UI review's B1): the longest that fits each row beside one of
	# its words; then each row's words as long as fit beside it
	var n: int = mini(rows.size(), READINGS)
	var fi: int = -1
	var n_forms: int = 0 if n == 0 else Array(_reads[0]["figs"]).size()
	for k in range(n_forms):
		var all_fit := true
		for i in range(n):
			var one := false
			for lf in _read_labels(rows[i]):
				if UI.text_width(_reads[i]["label"], str(lf)) + UI.text_width(_reads[i]["fig"], str(_reads[i]["figs"][k])) + 12.0 <= col_w:
					one = true
			all_fit = all_fit and one
		if all_fit:
			fi = k
			break
	if fi < 0:
		fi = n_forms - 1
	for i in range(n):
		var r: Dictionary = _reads[i]
		var pick_f: String = str(r["figs"][fi])
		var labels: Array = _read_labels(rows[i])
		var pick_l: String = str(labels.back())
		for lf in labels:
			if UI.text_width(r["label"], str(lf)) + UI.text_width(r["fig"], pick_f) + 12.0 <= col_w:
				pick_l = str(lf)
				break
		r["fig"].text = pick_f
		var fw: float = ceilf(UI.text_width(r["fig"], pick_f))
		r["fig"].position.x = PAD * 2 + col_w + col_w - fw
		r["fig"].size.x = fw
		r["label"].size.x = col_w - fw - 12
		r["label"].text = pick_l


## A reading's words, long to short (the designer's for the third: "With your parts moved over").
static func _read_labels(row: Dictionary) -> Array:
	return {"stand": ["As they stand"], "bare": ["Base to base"], "moved": ["With your parts moved over", "Your parts moved over", "Parts moved over"]}.get(str(row["key"]), [str(row["label"])])


## A figure for a reading: whole numbers, thousands with a comma.
static func _num(x: float) -> String:
	return Fmt.num(x) if absf(x) >= 1000.0 else "%.0f" % x


## The right column as words: a kicker, a title and lines (a med's rig, a part's bench, nothing fitted).
func show_right_words(kicker: String, title: String, lines: Array) -> void:
	_boxes[1].visible = kicker != "" or title != "" or not lines.is_empty()     # no box round nothing
	_kickers[1].visible = kicker != ""
	_kickers[1].text = kicker.to_upper()
	_kickers[1].size.x = col_w
	_right_title.visible = true
	_right_title.add_theme_color_override("font_color", Pal.TEXT_2)
	_right_title.text = title
	for i in range(LINES):
		_right_lines[i].visible = true
		_right_lines[i].add_theme_color_override("font_color", Pal.TEXT_2)
		if i < lines.size():
			if lines[i] is Array:
				UI.fit(_right_lines[i], lines[i])
			else:
				_right_lines[i].text = str(lines[i])
		else:
			_right_lines[i].text = ""
	# a line too long for its row wraps onto the empty rows under it, never cut (16 Oct: Kev's story's line clipped)
	var used: int = mini(lines.size(), LINES)
	for i in range(used):
		if lines[i] is String and UI.text_width(_right_lines[i], str(lines[i])) > _right_lines[i].size.x and i == used - 1:
			UI.wrap(_right_lines.slice(i), str(lines[i]))


## The foot's first row: the verdict in its tone, then the deltas, dropped from the right when they don't fit.
func set_verdict(verdict: String, tone: String, deltas: Array) -> void:
	_verdict.text = verdict
	_verdict.visible = verdict != ""
	_verdict.add_theme_color_override("font_color", Pal.tone_color(tone) if tone != "" else Pal.TEXT_2)
	_verdict.size.x = ceilf(UI.text_width(_verdict, verdict)) + 2
	var x: float = PAD + (_verdict.size.x + 18 if verdict != "" else 0.0)
	var room: float = _foot_left_edge()
	for i in range(DELTAS):
		var l := _deltas[i]
		l.visible = false
		if i >= deltas.size():
			continue
		var up: bool = float(deltas[i][0]) > 0.0
		l.text = "%s %s" % ["▲" if up else "▼", deltas[i][1]]
		l.add_theme_color_override("font_color", Pal.GOOD if up else Pal.BAD)
		l.size.x = ceilf(UI.text_width(l, l.text)) + 2
		if x + l.size.x > room:
			break
		l.position.x = x
		l.visible = true
		x += l.size.x + 16
	_lay_foot()                                         # a verdict takes the foot's first row: the item's line to its second


## A hint in place of the item's own line: what stops the button, mostly.
func set_hint(text: String) -> void:
	set_hint_options([text])


## A hint in forms long to short: a warning chip at the front of the pick's tail (18 Oct, Matt: the foot is the item's
## own line, always), the first form that fits.
func set_hint_options(options: Array) -> void:
	_heads[0].set_warning(options)


## The hint shown, or "" (for the tests).
func hint_text() -> String:
	return _heads[0]._tail_chips.words(0) if not _heads[0].warning.is_empty() and _heads[0]._tail_chips.visible else ""


## The buttons at the foot's right: [{text, action, enabled, primary, tone}], the first primary by default.
func set_buttons(items: Array) -> void:
	var x: float = w - PAD
	for i in range(BUTTONS):
		var b := _buttons[i]
		b.visible = i < items.size()
		if not b.visible:
			continue
		var d: Dictionary = items[i]
		b.text = str(d["text"])
		b.disabled = not bool(d.get("enabled", true))
		b.size.x = ceilf(UI.text_width(b, b.text)) + 48
		_actions[i] = d["action"]
		UI.style_button(b, bool(d.get("primary", i == 0)), str(d.get("tone", "")))
	# laid from the right
	for i in range(items.size() - 1, -1, -1):
		if i < BUTTONS:
			x -= _buttons[i].size.x
			_buttons[i].position.x = x
			x -= 12
	_lay_foot()


## The foot's left side stops where the buttons start.
func _foot_left_edge() -> float:
	var x: float = w - PAD
	for b in _buttons:
		if b.visible:
			x = minf(x, b.position.x)
	return x - 12


## The item's own line on the foot, left of the buttons (18 Oct, Matt: the same place on every item): under a verdict, its
## one row; with the foot's two rows free, wrapped to two when it needs them; else the whole sentences that fit.
func _lay_flavour() -> void:
	_words.text = _flavour_text
	_lay_foot()


func _lay_foot() -> void:
	var edge := _foot_left_edge()
	var both: bool = not _verdict.visible
	_words.position = Vector2(PAD, foot_y if both else foot_y + 24)
	_words.size = Vector2(maxf(80.0, edge - PAD), FOOT_H if both else 20)
	_words.autowrap_mode = TextServer.AUTOWRAP_OFF
	_words.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
	_words.add_theme_color_override("font_color", Pal.TEXT_2)
	_words.text = _flavour_text
	_words.visible = _flavour_text != ""
	if _words.visible and UI.text_width(_words, _flavour_text) > _words.size.x:
		var wrapped := false
		if both:
			for sz in [Pal.CELL_TEXT_BIG, Pal.CELL_TEXT, Pal.CELL_TEXT - 1]:
				_words.add_theme_font_size_override("font_size", sz)
				var two: float = 2.0 * _words.get_theme_font("font").get_height(sz) + float(_words.get_theme_constant("line_spacing"))
				if two <= FOOT_H and UI.text_width(_words, _flavour_text) <= 1.9 * _words.size.x:
					_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					if _words.get_line_count() <= 2:     # the wrap as it fell, not the width's guess
						wrapped = true
						break
					_words.autowrap_mode = TextServer.AUTOWRAP_OFF
		if not wrapped:
			_words.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
			UI.fit_sentences(_words, _flavour_text)       # one row: the whole sentences that fit
	# the deltas past the edge go
	for l in _deltas:
		if l.visible and l.position.x + l.size.x > edge:
			l.visible = false


func _clear() -> void:
	for k in range(2):
		_boxes[k].visible = false
		_kickers[k].visible = false
		_tags[k].visible = false
		_heads[k].visible = false
	_right_title.visible = false
	for l in _right_lines:
		l.visible = false
	_empty_title.visible = false
	for l in _empty_lines:
		l.visible = false
	for r in _reads:
		for k in ["label", "fig", "line"]:
			r[k].visible = false
	readings = []
	_verdict.visible = false
	_verdict.text = ""
	for l in _deltas:
		l.visible = false
	_words.text = ""
	_words.visible = false
	_flavour_text = ""
	for b in _buttons:
		b.visible = false


func _tag(k: int, text: String) -> void:
	var l := _tag_labels[k]
	l.text = text
	var tw: float = ceilf(UI.text_width(l, text))
	l.size.x = tw
	var tag := _tags[k]
	tag.visible = true
	tag.size.x = tw + 2 * TAG_PAD
	tag.position.x = PAD + k * (col_w + PAD) + col_w - tag.size.x
	_kickers[k].size.x = col_w - tag.size.x - 12


static func _cells(it: Dictionary) -> String:
	var n: int = Items.size(it)
	return "%d cell%s" % [n, "" if n == 1 else "s"]


## What fitting the pick changes: [[delta, words], ...], the headline figure first, then each affix that differs.
## Never a figure twice and never two units in one sum (29 Oct, the review): the headline only against the same unit (a
## pair of gloves' grip against a pace pair is two figures, each its own line), and a stat the headline already counts
## (armour, cells, loot quality) not again; a pair of gloves leads with its reloads, rate of fire and pace, each base and
## affixes together. A worn base's built-in figure (its role's) counts with the affix of its stat, its pace with pace's.
static func deltas_of(it: Dictionary, fitted: Dictionary) -> Array:
	var out: Array = []
	var covered := {}
	if str(it.get("slot", "")) == Data.GLOVES and str(fitted.get("slot", "")) == Data.GLOVES:
		var fa: Dictionary = Items.glove_figs(it)
		var fb: Dictionary = Items.glove_figs(fitted)
		for k in [["reload_pct", "reload"], ["attack_pct", "RoF"], ["pace", "pace"]]:
			var dg: float = float(fa[k[0]]) - float(fb[k[0]])
			if absf(dg) >= 0.5:
				out.append([dg, "%d%% %s" % [int(round(absf(dg))), k[1]]])
		covered = {"reload_pct": true, "attack_pct": true, "speed_pct": true}
	else:
		var a := Items.headline(it)
		var b := Items.headline(fitted)
		var d := float(a[0]) - float(b[0])
		if str(a[1]) == str(b[1]) and absf(d) >= 0.5:
			out.append([d, "%.0f %s" % [absf(d), {"armour": "arm", "capacity": "cap"}.get(a[1], a[1])]])
		covered = {{"armour": "armour", "capacity": "capacity", "loot quality": "rarity_pct"}.get(str(a[1]), ""): true}
	var seen := {}
	for ax in Data.AFFIXES:
		if seen.has(ax["stat"]) or covered.has(ax["stat"]):
			continue                         # a stat listed twice (a gun's row and an attachment's): one delta (13 Oct)
		seen[ax["stat"]] = true
		var da := _stat_of(it, str(ax["stat"])) - _stat_of(fitted, str(ax["stat"]))
		if absf(da) >= (0.05 if Items.is_tenths(ax["stat"]) else 0.5):
			out.append([da, "%s%s %s" % [Items.fig(ax["stat"], absf(da)), "%" if ax["stat"].ends_with("_pct") or ax["stat"].ends_with("_res") or ax["stat"] == "guard_gang" else "", ax["short"]]])
	return out


## A stat on a piece as the deltas read it (29 Oct): its affixes and its base's built-in figure; a worn base's pace with
## pace's, its resist with the resist's.
static func _stat_of(it: Dictionary, stat: String) -> float:
	if it.is_empty():
		return 0.0
	var v: float = Items.stat_total(it, stat)
	if stat == "speed_pct" and not Items.is_gun(it):
		v += Items.base_pace(it)
	if stat.ends_with("_res"):
		v += float(Items.base_of(it).get("res", {}).get(stat.trim_suffix("_res"), 0.0))
	return v


## The verdict for a pick against what's worn, tried on (sim.compare, 11 Oct): [words, tone]. `moved`: as "Swap, parts
## and all" would leave it (the Kit, when it moves something); else as it stands (the fix round, 29 Oct).
static func verdict_for(sim, it: Dictionary, moved := false) -> Array:
	if sim.wear_lock(it) > 0:
		return ["Level %d to wear" % sim.wear_lock(it), "bad"]     # gear gated by level (15 Oct): the deltas still say what it would do
	match sim.compare(it, -1, moved):
		1:
			return ["▲ Upgrade", "good"]
		-1:
			return ["▼ Downgrade", "bad"]
	return ["Sidegrade", "warn"]


## The foot's line for gear over the runner's level (15 Oct, signals_kit.png), longest first; [] when it can be worn.
static func lock_hints(sim, it: Dictionary) -> Array:
	var lv: int = sim.wear_lock(it)
	if lv <= 0:
		return []
	return ["Level %d to wear, your runner's %d: kept, stashed and sold as any other; it waits for the level" % [lv, sim.level()],
		"Level %d to wear, your runner's %d: it waits for the level" % [lv, sim.level()], "Level %d to wear" % lv]


## The deltas, a gun's damage read as the runner's with it on (its own figure alone missed what a damage % on the
## whole does, the secondary's third, a unique's rule), then each affix that differs.
static func deltas_for(sim, it: Dictionary, fitted: Dictionary, moved := false) -> Array:
	var out: Array = deltas_of(sim.moved_over(it) if moved else it, fitted)
	# the shown ones say why (the fix round, 29 Oct, the UI review's B7): gains first on an upgrade, losses first on a
	# downgrade, each side biggest first; the slot's own figure ahead of them all, below
	var c: int = sim.compare(it, -1, moved) if fitted != null and not fitted.is_empty() else 0
	out.sort_custom(func(x, y):
		var xu: bool = float(x[0]) > 0.0
		var yu: bool = float(y[0]) > 0.0
		if xu != yu:
			return xu if c >= 0 else yu
		return absf(float(x[0])) > absf(float(y[0])))
	if Data.SLOT_SCORE.get(str(it["slot"]), "") == "dps":
		out = out.filter(func(d_in): return not str(d_in[1]).ends_with("dmg/s"))
		var d: float = sim.fit_value(it, "", -1, moved) - sim.fit_value({}, str(it["slot"]))
		if absf(d) >= 0.05:
			out.push_front([d, ("%.1f dmg/s" if absf(d) < 10.0 else "%.0f dmg/s") % absf(d)])
	elif str(it["slot"]) in sim.SURV_SLOTS and fitted != null and not fitted.is_empty():
		# the body's figure first (12 Oct): what the arrow reads for a helmet or a coat, regen and resists in it
		var sg: float = sim.survival_gain(it, moved) * 100.0
		if absf(sg) >= 0.5:
			out.push_front([sg, "%.0f%% odds" % absf(sg)])
	return out


func _press(i: int) -> void:
	if _actions[i].is_valid():
		_actions[i].call()
	acted.emit()


# ------------------------------------------------------------------ the tests

func text_nodes() -> Array:
	var out: Array = []
	for k in range(2):
		if _kickers[k].visible:
			out.append(_kickers[k])
		if _tags[k].visible:
			out.append(_tag_labels[k])
		if _heads[k].visible:
			out.append_array(_heads[k].text_nodes())
	if _right_title.visible:
		out.append(_right_title)
		out.append_array(_right_lines)
	if _empty_title.visible:
		out.append(_empty_title)
		out.append_array(_empty_lines)
	for r in _reads:
		for k in ["label", "fig", "line"]:
			if r[k].visible:
				out.append(r[k])
	if _verdict.visible:
		out.append(_verdict)
	for l in _deltas:
		if l.visible:
			out.append(l)
	if _words.visible and _words.autowrap_mode == TextServer.AUTOWRAP_OFF:
		out.append(_words)                              # a wrapped one fits by its wrap, its two rows checked apart (the smoke)
	for b in _buttons:
		if b.visible:
			out.append(b)
	return out


func line_pairs() -> Array:
	var out := []
	for k in range(2):
		if _heads[k].visible:
			out.append_array(_heads[k].line_pairs())
	return out


## For the tests: the buttons showing, their text.
func button_texts() -> Array:
	var out := []
	for b in _buttons:
		if b.visible:
			out.append(b.text)
	return out


func press(i: int) -> void:
	if i < BUTTONS and _buttons[i].visible and not _buttons[i].disabled:
		_press(i)
