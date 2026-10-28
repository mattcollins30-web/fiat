extends Control
## The Fence's side on the exchange (28 Oct, Matt: contracts replaced by currency conversion; was his contracts' list,
## 19 Oct, Fence B): today's rates in tins - a row a currency on the board, its worth today with ▲ or ▼ against
## yesterday's - then his mate, as before.
##
## Signals: `mate` for the mate's Buy.

signal mate

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")

const ROW_H := 36.0
const ROW_GAP := 4.0
const ROWS := 12                       # every currency but tins: notes, scrap, three salvage, seven materials
const MOVE_W := 92.0
const WORTH_W := 150.0
const MATE_H := 66.0

var sim
var _head: Label
var _rows: Array = []                  # {panel, name, move, worth, cur}
var _note: Label
var _mate_head: Label
var _mate: Panel
var _mate_name: Label
var _mate_sub: Label
var _mate_price: Label
var _mate_buy: Button
var _shown := ""


func _init(w: float, h: float) -> void:
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_head = UI.head(self, Rect2(0, 0, w, UI.HEAD_H), "Today's rates in tins")
	var y: float = UI.HEAD_H + 6
	for k in range(ROWS):
		var r := {"cur": ""}
		r["panel"] = UI.panel(self, Rect2(0, y, w, ROW_H), UI.box(Pal.PANEL, 6))
		r["name"] = UI.label(r["panel"], Rect2(12, 0, w - 24 - MOVE_W - WORTH_W - 8, ROW_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["move"] = UI.label(r["panel"], Rect2(w - 12 - WORTH_W - 8 - MOVE_W, 0, MOVE_W, ROW_H), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
		r["worth"] = UI.label(r["panel"], Rect2(w - 12 - WORTH_W, 0, WORTH_W, ROW_H), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
		r["panel"].visible = false
		_rows.append(r)
		y += ROW_H + ROW_GAP
	_note = UI.label(self, Rect2(0, 0, w, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var my: float = h - MATE_H
	_mate_head = UI.head(self, Rect2(0, my - UI.HEAD_H - 6, w, UI.HEAD_H), "HIS MATE · NEW EVERY %d RUNS" % Data.MATE_RUNS)
	_mate = UI.panel(self, Rect2(0, my, w, MATE_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_mate_name = UI.label(_mate, Rect2(12, 6, w * 0.5, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_mate_sub = UI.label(_mate, Rect2(12, 36, w * 0.5, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_mate_price = UI.label(_mate, Rect2(w * 0.5, 16, w * 0.5 - 12 - 136, 30), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_mate_buy = UI.button(_mate, Rect2(w - 12 - 128, 12, 128, MATE_H - 24), false)
	_mate_buy.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	_mate_buy.pressed.connect(func(): mate.emit())


func show_state(s) -> void:
	sim = s
	var on: Array = sim.exchange_offered().filter(func(c): return c != "tins")     # tins are the yardstick
	var sig := "%s|%d|%d|%s|%s|%.4f|%s" % [str(on), sim.exchange_day, sim.notes, str(sim.mate), str(sim.on_mission()), sim.inflation(), str(sim.issued) + str(Fmt.fiat)]
	if sig == _shown:
		return
	_shown = sig
	_head.text = ("Today's rates in %s" % Fmt.unit()).to_upper()
	var y: float = UI.HEAD_H + 6
	for k in range(_rows.size()):
		var r: Dictionary = _rows[k]
		r["panel"].visible = k < on.size()
		if not r["panel"].visible:
			r["cur"] = ""
			continue
		var cur: String = on[k]
		r["cur"] = cur
		UI.fit(r["name"], [sim.exchange_name(cur), str(sim.exchange_name(cur)).get_slice(" ", 0)])
		var today: float = sim.exchange_worth(cur)
		var before: float = sim.exchange_worth(cur, sim.exchange_day - 1)
		var pct: float = (today / before - 1.0) * 100.0 if before > 0.0 else 0.0
		if absf(pct) < 0.5:
			r["move"].text = "– 0%"
			r["move"].add_theme_color_override("font_color", Pal.TEXT_3)
		else:
			r["move"].text = "%s %d%%" % ["▲" if pct > 0.0 else "▼", int(round(absf(pct)))]
			r["move"].add_theme_color_override("font_color", Pal.GOOD if pct > 0.0 else Pal.BAD)
		UI.fit(r["worth"], [worth_words(today), _num(today)])
		y = r["panel"].position.y + ROW_H + ROW_GAP
	_note.position.y = y + 4
	UI.fit(_note, ["New rates every run home; ▲ or ▼ against yesterday's", "New rates every run home"])
	if sim.mate.is_empty():
		_mate_name.text = "Not about"
		UI.fit(_mate_sub, ["He comes by every %d runs" % Data.MATE_RUNS, "Every %d runs" % Data.MATE_RUNS])
		_mate_price.text = ""
		_mate_buy.visible = false
	else:
		var mt: String = (" · tier %d" % int(sim.mate["tier"])) if sim.mate.has("tier") else ""
		UI.fit(_mate_name, [str(sim.mate["unique"])])
		_mate_name.add_theme_color_override("font_color", Pal.tone_color(Pal.rarity_tone(4)))
		UI.fit(_mate_sub, ["A unique%s" % mt, "Unique"])
		_mate_price.text = Fmt.notes(int(sim.mate["notes"]))
		_mate_buy.visible = true
		var short: int = int(sim.mate["notes"]) - sim.notes
		_mate_buy.text = "Buy" if short <= 0 else "Short %s" % Fmt.group(short)
		_mate_buy.disabled = not sim.can_buy_mate()


## A worth in tins as the row says it: "512 tins", "26.3 tins"; after the Issue the fiat's, to as many places as it takes.
static func worth_words(x: float) -> String:
	return "%s %s" % [_num(x), Fmt.unit()]


static func _num(x: float) -> String:
	if x >= 100.0:
		return Fmt.group(int(round(x)))
	if x >= 10.0:
		return "%.1f" % x
	if x >= 0.1:
		return "%.2f" % x
	return "%.4f" % x


## For the tests: a row by its place.
func row_of(k: int) -> Dictionary:
	return _rows[k]


func text_nodes() -> Array:
	var out: Array = [_head, _mate_head, _mate_name, _mate_sub, _mate_price, _note]
	if _mate_buy.visible:
		out.append(_mate_buy)
	for r in _rows:
		if r["panel"].visible:
			out.append_array([r["name"], r["move"], r["worth"]])
	return out
