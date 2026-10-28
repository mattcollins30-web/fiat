extends Panel
## The Fence's exchange (28 Oct, Matt: "contracts should be replaced by currency conversion - notes, tins, scrap with
## varying rates for each"): the grid's place on the Fence's third tab. What you give down the left, what you get down
## the right, a currency a button with what you hold of it; how much of what you give (a share of what's held); what
## that gets at today's rate, the rate against yesterday's; Trade. The sim's exchange_* do the sums.
##
## Signals: `acted` after a trade.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")

const PAD := 20
const COL_GAP := 24
const CUR_H := 52                      # a currency's button: its name over what's held
const CUR_GAP := 8
const CUR_ROWS := 7                    # two a row: tins, notes, scrap, three salvage, seven materials fit
const AMT_H := 40
const SHARES := [0.10, 0.25, 0.50, 1.0]
const TRADE_W := 240
const TRADE_H := 56

var sim
var give := "notes"
var get_cur := "tins"                  # `get` is a Godot method's name
var share := 0.25
var _w := 0.0
var _title: Label
var _sub: Label
var _give_head: Label
var _get_head: Label
var _cols: Array = [[], []]            # per side: {button, name, held, cur}
var _amt_head: Label
var _amts: Array[Button] = []
var _preview: Label
var _rate: Label
var _trade: Button
var _shown := ""


func _init(w: float, h: float) -> void:
	_w = w
	size = Vector2(w, h)
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_PASS
	var inner: float = w - 2 * PAD
	_title = UI.label(self, Rect2(PAD, PAD, inner, 36), "The exchange", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(self, Rect2(PAD, PAD + 38, inner, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var col_w: float = (inner - COL_GAP) / 2.0
	var y: float = PAD + 38 + 28 + 14
	_give_head = UI.head(self, Rect2(PAD, y, col_w, UI.HEAD_H), "You give")
	_get_head = UI.head(self, Rect2(PAD + col_w + COL_GAP, y, col_w, UI.HEAD_H), "You get")
	y += UI.HEAD_H + 4
	var bw: float = (col_w - CUR_GAP) / 2.0
	for side in range(2):
		var x0: float = PAD + side * (col_w + COL_GAP)
		for k in range(CUR_ROWS * 2):
			var bx: float = x0 + (k % 2) * (bw + CUR_GAP)
			@warning_ignore("integer_division")
			var by: float = y + (k / 2) * (CUR_H + CUR_GAP)
			var b := UI.button(self, Rect2(bx, by, bw, CUR_H), false)
			b.pressed.connect(_pick.bind(side, k))
			var nm := UI.label(b, Rect2(12, 4, bw - 24, 24), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			var held := UI.label(b, Rect2(12, 27, bw - 24, 20), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			b.visible = false
			_cols[side].append({"button": b, "name": nm, "held": held, "cur": ""})
	y += CUR_ROWS * CUR_H + (CUR_ROWS - 1) * CUR_GAP + 16
	_amt_head = UI.head(self, Rect2(PAD, y, inner, UI.HEAD_H), "How much · of what you hold")
	y += UI.HEAD_H + 4
	var aw: float = (inner - 3 * CUR_GAP) / 4.0
	for k in range(SHARES.size()):
		var b := UI.button(self, Rect2(PAD + k * (aw + CUR_GAP), y, aw, AMT_H), false)
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		b.text = "All" if SHARES[k] >= 1.0 else "%d%%" % int(round(SHARES[k] * 100))
		b.pressed.connect(_pick_share.bind(k))
		_amts.append(b)
	var fy: float = h - PAD - TRADE_H
	_preview = UI.label(self, Rect2(PAD, fy - 2, inner - TRADE_W - 16, 32), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_rate = UI.label(self, Rect2(PAD, fy + 30, inner - TRADE_W - 16, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_trade = UI.button(self, Rect2(w - PAD - TRADE_W, fy, TRADE_W, TRADE_H), true)
	_trade.pressed.connect(_on_trade)


## What `share` of what's held of the give side comes to: rounded down, All the lot.
func amount() -> int:
	if sim == null:
		return 0
	var held: int = sim.exchange_held(give)
	return held if share >= 1.0 else int(floor(held * share))


func show_state(s) -> void:
	sim = s
	if sim == null:
		return
	var on: Array = sim.exchange_offered()
	var gives: Array = sim.exchange_gives()                  # scrap buy-only (28 Oct, the review): never in You give
	if not gives.has(give):
		give = "notes" if gives.has("notes") else (str(gives[1]) if gives.size() > 1 else "tins")       # notes off the board after the Issue
	if not on.has(get_cur) or get_cur == give:
		get_cur = "tins" if give != "tins" else "scrap"
	var held_sig: Array = on.map(func(c): return sim.exchange_held(c))
	var sig := "%s|%s|%s|%.2f|%d|%s|%s|%.5f|%s|%s" % [str(on) + str(gives), give, get_cur, share, sim.exchange_day, str(held_sig), str(sim.on_mission()), sim.exchange_rate(give, get_cur), str(sim.yard_picks.get("fence", [])), str(sim.issued) + str(Fmt.fiat)]
	if sig == _shown:
		return
	_shown = sig
	var spread: int = int(round(sim.exchange_spread() * 100.0))
	var fixer: String = " · Fixer +%d%%" % int(round((sim.exchange_fixer() - 1.0) * 100.0)) if sim.exchange_fixer() > 1.0 else ""
	UI.fit(_sub, ["Today's rates, new every run home · he keeps %d%% either way%s" % [spread, fixer],
		"Today's rates · he keeps %d%% either way%s" % [spread, fixer], "Today's rates · %d%% kept either way" % spread, "Today · %d%% kept" % spread])
	for side in range(2):
		var mine: String = give if side == 0 else get_cur
		var list: Array = gives if side == 0 else on
		for k in range(_cols[side].size()):
			var c: Dictionary = _cols[side][k]
			var b: Button = c["button"]
			b.visible = k < list.size()
			if not b.visible:
				c["cur"] = ""
				continue
			var cur: String = list[k]
			c["cur"] = cur
			var picked: bool = cur == mine
			UI.style_button(b, picked)
			var other: bool = cur == (get_cur if side == 0 else give)     # the other side's pick: not this side's too
			b.disabled = other
			var tone: Color = Pal.ACCENT_TEXT if picked else (Pal.TEXT_3 if other else Pal.TEXT)
			UI.fit(c["name"], [sim.exchange_name(cur), _short_name(cur)])
			c["name"].add_theme_color_override("font_color", tone)
			var n: int = sim.exchange_held(cur)
			UI.fit(c["held"], ["%s held" % Fmt.group(n), Fmt.group(n), Fmt.short_num(n)])
			c["held"].add_theme_color_override("font_color", Pal.ACCENT_TEXT if picked else (Pal.TEXT_3 if other else Pal.TEXT_2))
	for k in range(_amts.size()):
		UI.style_button(_amts[k], is_equal_approx(share, SHARES[k]))
	var amt: int = amount()
	var got: int = sim.exchange_get(give, get_cur, amt)
	UI.fit(_preview, ["Give %s · get %s" % [_words(give, amt), _words(get_cur, got)], "%s → %s" % [_words(give, amt), _words(get_cur, got)],
		"%s → %s" % [Fmt.short_num(amt), Fmt.short_num(got)]])
	var today: float = sim.exchange_rate(give, get_cur)
	var before: float = sim.exchange_rate(give, get_cur, sim.exchange_day - 1)
	var arrow: String = "▲" if today > before * 1.0005 else ("▼" if today < before * 0.9995 else "–")
	var unit: int = _unit_for(today)
	var r_words: String = "%s %s = %s %s" % [Fmt.group(unit), _noun(give, unit), _num(today * unit), _noun(get_cur, 2)]
	if arrow == "–":
		UI.fit(_rate, ["Today's rate: %s · as yesterday" % r_words, "Today: %s" % r_words, r_words, _num(today * unit)])
	else:
		UI.fit(_rate, ["Today's rate: %s %s · yesterday %s" % [r_words, arrow, _num(before * unit)], "Today: %s %s · was %s" % [r_words, arrow, _num(before * unit)], "%s %s" % [r_words, arrow], "%s %s" % [_num(today * unit), arrow]])
	_rate.add_theme_color_override("font_color", Pal.GOOD if arrow == "▲" else (Pal.BAD if arrow == "▼" else Pal.TEXT_2))
	var block: String = sim.exchange_block(give, get_cur, amt)
	_trade.disabled = block != ""
	UI.fit_button(_trade, ["Trade"] if block == "" else [block, "Can't trade"])


## A currency's name short, for a tight button: the first word.
func _short_name(cur: String) -> String:
	return str(sim.exchange_name(cur)).get_slice(" ", 0)


## `n` of a currency as the line says it: tins as money, the rest by their name.
func _words(cur: String, n: int) -> String:
	if cur == "tins":
		return Fmt.money(n)
	return "%s %s" % [Fmt.group(n), _noun(cur, n)]


## A currency's noun, by the count: a note, two notes; a material or salvage as named, lower case.
func _noun(cur: String, n: int) -> String:
	match cur:
		"tins":
			return Fmt.unit() if n != 1 or Fmt.fiat else "tin"
		"notes":
			return "notes" if n != 1 else "note"
	return str(sim.exchange_name(cur)).to_lower()


## The unit a rate reads in: one, else ten, a hundred... so what it gets is at least one.
static func _unit_for(rate: float) -> int:
	var u := 1
	while rate > 0.0 and rate * u < 1.0 and u < 1000000:
		u *= 10
	return u


static func _num(x: float) -> String:
	if x >= 100.0:
		return Fmt.group(int(round(x)))
	if x >= 10.0:
		return "%.1f" % x
	return "%.2f" % x


func _pick(side: int, k: int) -> void:
	var cur: String = _cols[side][k]["cur"]
	if cur == "":
		return
	if side == 0:
		give = cur
	else:
		get_cur = cur
	_shown = ""
	show_state(sim)


func _pick_share(k: int) -> void:
	share = SHARES[k]
	_shown = ""
	show_state(sim)


func _on_trade() -> void:
	if sim == null:
		return
	if sim.exchange(give, get_cur, amount()):
		_shown = ""
		acted.emit()
	show_state(sim)


## For the tests: a currency's button on a side (0 give, 1 get), or null when it isn't on the board.
func button_of(side: int, cur: String) -> Button:
	for c in _cols[side]:
		if c["cur"] == cur and c["button"].visible:
			return c["button"]
	return null


## For the tests: the amount buttons, 10% to All; the Trade button; the preview and the rate lines.
func amount_buttons() -> Array:
	return _amts


func trade_button() -> Button:
	return _trade


func preview_text() -> String:
	return _preview.text


func rate_text() -> String:
	return _rate.text


## For the tests: every label and button with words.
func text_nodes() -> Array:
	var out: Array = [_title, _sub, _give_head, _get_head, _amt_head, _preview, _rate, _trade]
	out.append_array(_amts)
	for side in range(2):
		for c in _cols[side]:
			if c["button"].visible:
				out.append_array([c["name"], c["held"]])
	return out
