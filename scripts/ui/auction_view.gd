extends Panel
## (BUILD69-A) The Fence's back room, the auction (docs/design/endgame_rail.md §4; the canvas's Auction board, approved
## 7 Nov): the Fence's sixth tab once the Issue's on. Market day every few runs: four lots across (a unique, a set
## piece, issued kit, now and then a sealed crate); the picked lot under them - its piece, the bids, what the rivals
## do, Bid and Drop out; your fiat down the right - what's held in bids, what's free, your bids, the last market.
## The sim is builder E's (sim.e69_*, $S/e69_notes.md).
##
## Signals: `acted` after a bid or a drop.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const ItemHead := preload("res://scripts/ui/item_head.gd")

const BP := 16
const GAP := 12
const HEAD_H := 64
const LOTS_Y := HEAD_H + GAP
const LOTS := 4                         # Data.AUCTION69_KINDS (the smoke holds them equal)
const LOT_H := 150
const LOT_PIC := Vector2(180, 56)
const DETAIL_Y := LOTS_Y + LOT_H + GAP
const SIDE_W := 464
const BID_ROWS := 3
const BID_ROW_H := 34
const RIVALS := 2
const RIVAL_H := 60
const YOUR_ROWS := 4
const LAST_ROWS := 3
const BTN_H := 52
const BID_MORE_STEPS := 2               # the second Bid button: the least bid and this many steps more
const SEALED_ART69 := "crates/sealed"  # the sealed crate's own picture (art71, 9 Nov)

var sim
var selected := 0
var _w := 0.0
var _h := 0.0
var _kicker: Label
var _title: Label
var _closes: Label
var _next: Label
var _lots: Array = []                   # {button, kind, cell, name, key, value}
var _detail: Panel
var _d_head: Label
var _d_cell
var _d_crate: TextureRect
var _d_rule: Label
var _d_line: Label
var _bids_head: Label
var _bid_rows: Array = []               # {panel, who, fig}
var _rivals_head: Label
var _rival_cards: Array = []            # {panel, who, line}
var _win: Label
var _win_tail: Label
var _bid: Button
var _bid_more: Button
var _drop: Button
var _block: Label
var _shut: Array = []                   # the detail's lines with no market on
var _side: Panel
var _fiat_head: Label
var _fiat: Label
var _held: Array = []                   # [key, value] x2: held in bids, free to bid
var _yours_head: Label
var _yours: Array = []                  # {panel, name, fig}
var _yours_none: Label
var _last_head: Label
var _last: Array = []                   # [key, value]
var _last_none: Label
var _foot: Array = []
var _shown := ""


func _init(w: float, h: float) -> void:
	_w = w
	_h = h
	size = Vector2(w, h)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_PASS
	var hp := UI.panel(self, Rect2(0, 0, w, HEAD_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_kicker = UI.head(hp, Rect2(BP, 8, 520, UI.HEAD_H), Words.A69["a_kicker"])
	_kicker.add_theme_color_override("font_color", Pal.ACCENT)
	_title = UI.label(hp, Rect2(BP, 26, 520, 34), "", "SemiBold", Pal.TITLE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_closes = UI.label(hp, Rect2(w - BP - 520, 6, 520, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_next = UI.label(hp, Rect2(w - BP - 520, 36, 520, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	@warning_ignore("integer_division")
	var lw: int = int(w - (LOTS - 1) * GAP) / LOTS
	for k in range(LOTS):
		var b := Button.new()
		b.position = Vector2(k * (lw + GAP), LOTS_Y)
		b.size = Vector2(lw, LOT_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick.bind(k))
		add_child(b)
		var l := {"button": b}
		l["kind"] = UI.label(b, Rect2(14, 8, lw - 28, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var cell := ItemCell.new()
		cell.position = Vector2((lw - LOT_PIC.x) / 2.0, 32)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cell)
		l["cell"] = cell
		l["crate"] = _crate_rect(b, Rect2(cell.position, LOT_PIC))
		l["name"] = UI.label(b, Rect2(14, 92, lw - 28, 26), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		l["key"] = UI.label(b, Rect2(14, 120, 120, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		l["value"] = UI.label(b, Rect2(14, 118, lw - 28, 24), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_lots.append(l)
	_build_detail(w - SIDE_W - GAP, h - DETAIL_Y)
	_build_side(w - SIDE_W, SIDE_W, h - DETAIL_Y)


func _build_detail(dw: float, dh: float) -> void:
	_detail = UI.panel(self, Rect2(0, DETAIL_Y, dw, dh), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = dw - 2 * BP
	_d_head = UI.head(_detail, Rect2(BP, 12, iw, UI.HEAD_H), "")
	var cell := ItemCell.new()
	cell.position = Vector2(BP, 40)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(cell)
	_d_cell = cell
	_d_crate = _crate_rect(_detail, Rect2(cell.position, Vector2(200, 64)))
	var tx: float = BP + 200 + 16
	_d_rule = UI.label(_detail, Rect2(tx, 44, iw - tx + BP, 28), "", "Medium", Pal.CELL_TEXT_BIG + 1, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_d_line = UI.label(_detail, Rect2(tx, 72, iw - tx + BP, 26), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_bids_head = UI.label(_detail, Rect2(BP, 112, iw, 22), Words.A69["a_bids"], "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(BID_ROWS):
		var p := UI.panel(_detail, Rect2(BP, 136 + k * (BID_ROW_H + 4), iw, BID_ROW_H), UI.box(Pal.CARD, 4))
		var r := {"panel": p}
		r["who"] = UI.label(p, Rect2(12, 4, iw - 200, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["fig"] = UI.label(p, Rect2(iw - 192, 4, 180, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_bid_rows.append(r)
	var ry: float = 136 + BID_ROWS * (BID_ROW_H + 4) + 6
	_rivals_head = UI.label(_detail, Rect2(BP, ry, iw, 22), Words.A69["a_rivals"], "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	@warning_ignore("integer_division")
	var cw: int = int(iw - GAP) / RIVALS
	for k in range(RIVALS):
		var p := UI.panel(_detail, Rect2(BP + k * (cw + GAP), ry + 24, cw, RIVAL_H), UI.box(Pal.CARD, 6))
		var r := {"panel": p}
		r["who"] = UI.label(p, Rect2(12, 4, cw - 24, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["line"] = UI.label(p, Rect2(12, 32, cw - 24, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_rival_cards.append(r)
	var wy: float = ry + 24 + RIVAL_H + 10
	var wp := UI.panel(_detail, Rect2(BP, wy, iw, 36), UI.box(Pal.CARD, 6))
	_win = UI.label(wp, Rect2(12, 5, iw * 0.5, 26), Words.A69["a_win"], "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_win_tail = UI.label(wp, Rect2(iw * 0.5, 5, iw * 0.5 - 12, 26), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	var by: float = dh - BP - BTN_H
	_block = UI.label(_detail, Rect2(BP, by - 30, iw, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var bw: float = roundf(iw * 0.4)
	@warning_ignore("integer_division")
	var rest: float = floorf((iw - bw - 2 * GAP) / 2.0)
	_bid = UI.button(_detail, Rect2(BP, by, bw, BTN_H), true)
	_bid.pressed.connect(_on_bid.bind(0))
	_bid_more = UI.button(_detail, Rect2(BP + bw + GAP, by, rest, BTN_H), false)
	_bid_more.pressed.connect(_on_bid.bind(BID_MORE_STEPS))
	_drop = UI.button(_detail, Rect2(BP + bw + GAP + rest + GAP, by, iw - bw - rest - 2 * GAP, BTN_H), false)
	_drop.pressed.connect(_on_drop)
	for k in range(2):
		_shut.append(UI.label(_detail, Rect2(BP, BP + 8 + k * 32, iw, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))


func _build_side(x: float, sw: float, sh: float) -> void:
	_side = UI.panel(self, Rect2(x, DETAIL_Y, sw, sh), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = sw - 2 * BP
	_fiat_head = UI.head(_side, Rect2(BP, 12, iw, UI.HEAD_H), Words.A69["a_fiat"])
	_fiat = UI.label(_side, Rect2(BP, 34, iw, 46), "", "Bold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		var key := UI.label(_side, Rect2(BP, 84 + k * 28, iw * 0.6, 26), [Words.A69["a_held"], Words.A69["a_free"]][k], "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var val := UI.label(_side, Rect2(BP + iw * 0.6, 84 + k * 28, iw * 0.4, 26), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_held.append([key, val])
	_yours_head = UI.head(_side, Rect2(BP, 148, iw, UI.HEAD_H), Words.A69["a_yours"])
	for k in range(YOUR_ROWS):
		var p := UI.panel(_side, Rect2(BP, 174 + k * 34, iw, 30), UI.box(Pal.CARD, 4))
		var r := {"panel": p}
		r["name"] = UI.label(p, Rect2(10, 2, iw * 0.55 - 10, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["fig"] = UI.label(p, Rect2(iw * 0.55, 2, iw * 0.45 - 10, 26), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_yours.append(r)
	_yours_none = UI.label(_side, Rect2(BP, 176, iw, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var ly: float = 174 + YOUR_ROWS * 34 + 8
	_last_head = UI.head(_side, Rect2(BP, ly, iw, UI.HEAD_H), Words.A69["a_last"])
	for k in range(LAST_ROWS):
		var key := UI.label(_side, Rect2(BP, ly + 26 + k * 24, 60, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var val := UI.label(_side, Rect2(BP + 64, ly + 26 + k * 24, iw - 64, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_last.append([key, val])
	_last_none = UI.label(_side, Rect2(BP, ly + 26, iw, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		_foot.append(UI.label(_side, Rect2(BP, sh - BP - 48 + k * 24, iw, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))


## The sealed crate's picture, kept to its box.
static func _crate_rect(parent: Control, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.position = r.position
	t.size = r.size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture = UI.glyph_texture(SEALED_ART69)
	t.visible = false
	parent.add_child(t)
	return t


# ------------------------------------------------------------------ showing

func market() -> Dictionary:
	return sim.e69["market"] if sim != null else {}


func show_state(s) -> void:
	sim = s
	if sim == null:
		return
	if is_visible_in_tree():
		sim.e69_market_looked()
	var mk: Dictionary = market()
	var lots: Array = mk.get("lots", [])
	selected = clampi(selected, 0, maxi(0, lots.size() - 1))
	var sig := "%s|%s|%d|%d|%d|%d|%s" % [str(mk.get("on", false)), str(lots.map(func(l): return [l["high"], l["by"], l.get("you", 0)])), selected, int(sim.cash), int(mk.get("closes", 0)), int(mk.get("next", 0)), str(mk.get("last", []))]
	if sig == _shown:
		return
	_shown = sig
	var on: bool = bool(mk.get("on", false)) and not lots.is_empty()
	_show_head(mk, on)
	for k in range(LOTS):
		var l: Dictionary = _lots[k]
		l["button"].visible = on and k < lots.size()
		if l["button"].visible:
			_show_lot(l, lots[k], k)
	for ch in _detail.get_children():
		if ch is Control:
			ch.visible = on
	for x in _shut:
		x.visible = not on
	if on:
		_show_detail(lots[selected], selected)
	else:
		UI.fit(_shut[0], [Words.A69["a_shut"]])
		var nx: int = int(mk.get("next", 0))
		UI.fit(_shut[1], [Words.A69["a_shut2"] % [nx, "" if nx == 1 else "s"], Words.A69["a_shut2_short"] % [nx, "" if nx == 1 else "s"]])
	_show_side(mk, lots, on)


func _show_head(mk: Dictionary, on: bool) -> void:
	UI.fit(_title, [Words.A69["a_title"] if on else Words.A69["a_title_off"]])
	if on:
		var c: int = int(mk.get("closes", 0))
		UI.fit(_closes, [Words.A69["a_closes"] % [c, "" if c == 1 else "s"], "%d run%s" % [c, "" if c == 1 else "s"]])
		UI.fit(_next, [Words.A69["a_next"] % Data.AUCTION69_EVERY, ""])
	else:
		var nx: int = int(mk.get("next", 0))
		UI.fit(_closes, [Words.A69["a_next_in"] % [nx, "" if nx == 1 else "s"], "%d run%s" % [nx, "" if nx == 1 else "s"]])
		UI.fit(_next, [Words.A69["a_next_off"] % Data.AUCTION69_OPEN_RUNS, ""])


func _show_lot(l: Dictionary, lot: Dictionary, k: int) -> void:
	var kind: String = str(lot["kind"])
	UI.fit(l["kind"], [Words.A69["a_lot"] % [k + 1, str(Words.A69["a_kind"].get(kind, kind))], Words.A69["a_lot_short"] % (k + 1)])
	var it: Dictionary = lot.get("item", {})
	l["cell"].visible = not it.is_empty()
	l["crate"].visible = it.is_empty()
	if not it.is_empty():
		l["cell"].show_item(it, false, LOT_PIC)
	UI.fit(l["name"], [str(lot["name"])])
	if kind == "sealed":
		UI.fit(l["key"], [Words.A69["a_sealed_in"] % sim.e69_sealed_odds_in()])
		UI.fit(l["value"], [Words.A69["a_sealed_what"]])
		l["value"].add_theme_color_override("font_color", Pal.MYTHIC)
	else:
		UI.fit(l["key"], [Words.A69["a_high"]])
		var you: bool = str(lot["by"]) == "you"
		var tail: String = Words.A69["a_you"] if you else Words.A69["a_not_you"]
		UI.fit(l["value"], ["%s · %s" % [Fmt.money(float(lot["high"])), tail], Fmt.money(float(lot["high"]))])
		l["value"].add_theme_color_override("font_color", Pal.GOOD if you else (Pal.BAD if int(lot.get("you", 0)) > 0 else Pal.TEXT))
	# the key's room: up to the figure's words
	l["key"].size.x = maxf(40.0, l["button"].size.x - 28 - UI.text_width(l["value"], l["value"].text) - 12)
	var on: bool = k == selected
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		l["button"].add_theme_stylebox_override(st, UI.box(Pal.SELECT if st == "hover" else Pal.CARD, 8, 2 if on else 1, Pal.ACCENT if on else Pal.CARD_LINE))


func _show_detail(lot: Dictionary, k: int) -> void:
	var it: Dictionary = lot.get("item", {})
	_d_head.text = (Words.A69["a_lot"] % [k + 1, str(lot["name"])]).to_upper()
	UI.fit(_d_head, [_d_head.text, (Words.A69["a_lot_short"] % (k + 1)).to_upper()])
	_d_cell.visible = not it.is_empty()
	_d_crate.visible = it.is_empty()
	if not it.is_empty():
		_d_cell.show_item(it, false, Vector2(200, 64))
		var forms: Array = ItemHead.unique_rule(it)
		var lines: Array = Items.affix_lines(it) if it.has("affixes") else []
		if forms.is_empty():
			forms = [" · ".join(lines.slice(0, 2)), str(lines[0]) if not lines.is_empty() else ""]
		UI.fit(_d_rule, forms)
		UI.fit(_d_line, ["%s · %s · item level %d" % [str(it.get("slot", "")), Items.rarity_name(it), Items.ilvl(it)], "%s · item level %d" % [Items.rarity_name(it), Items.ilvl(it)]])
	else:
		UI.fit(_d_rule, [Words.A69["a_sealed_rule"] % sim.e69_sealed_odds_in()])
		UI.fit(_d_line, [Words.A69["a_sealed_line"] % int(lot.get("level", 0)), ""])
	# the bids, highest first
	var rows: Array = []
	for r in lot["rivals"]:
		if int(r["bid"]) > 0:
			rows.append([str(Words.E69["rivals"].get(str(r["key"]), r["key"])), int(r["bid"]), false])
	if int(lot.get("you", 0)) > 0:
		rows.append([Words.A69["a_you_row"], int(lot["you"]), true])
	rows.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
	for j in range(BID_ROWS):
		var br: Dictionary = _bid_rows[j]
		br["panel"].visible = j < rows.size()
		if j < rows.size():
			UI.fit(br["who"], [str(rows[j][0])])
			UI.fit(br["fig"], [Fmt.money(float(rows[j][1]))])
			br["who"].add_theme_color_override("font_color", Pal.ACCENT if rows[j][2] else Pal.TEXT)
	for j in range(RIVALS):
		var rc: Dictionary = _rival_cards[j]
		rc["panel"].visible = j < lot["rivals"].size()
		if not rc["panel"].visible:
			continue
		var rv: Dictionary = lot["rivals"][j]
		UI.fit(rc["who"], [str(Words.E69["rivals"].get(str(rv["key"]), rv["key"]))])
		var step: int = maxi(1, sim.e69_bid_min(k) - int(lot["high"]))
		if str(rv["style"]) == "late":
			UI.fit(rc["line"], [Words.A69["a_late"], Words.A69["a_late_short"]])
		else:
			UI.fit(rc["line"], [Words.A69["a_steady"] % [Fmt.money(float(step)), Fmt.money(float(rv["top"]))], Words.A69["a_steady_short"] % Fmt.money(float(step))])
	UI.fit(_win, [Words.A69["a_win"], Words.A69["a_win_short"]])
	UI.fit(_win_tail, [Words.A69["a_win_tail"], ""])
	_win_tail.size.x = _win.get_parent().size.x - 12 - (UI.text_width(_win, _win.text) + 36)
	_win_tail.position.x = UI.text_width(_win, _win.text) + 24
	UI.fit(_win_tail, [Words.A69["a_win_tail"], ""])
	# the buttons
	var least: int = sim.e69_bid_min(k)
	var more: int = least + BID_MORE_STEPS * maxi(1, least - int(lot["high"]))
	var b0: String = sim.e69_bid_block(k, least)
	var b1: String = sim.e69_bid_block(k, more)
	UI.fit_button(_bid, [Words.A69["a_bid"] % Fmt.money(float(least)), Fmt.money(float(least))])
	UI.fit_button(_bid_more, [Words.A69["a_bid"] % Fmt.money(float(more)), Fmt.money(float(more))])
	_bid.disabled = b0 != ""
	_bid_more.disabled = b1 != ""
	UI.style_button(_bid, b0 == "")
	UI.fit_button(_drop, [Words.A69["a_drop"]])
	_drop.disabled = int(lot.get("you", 0)) <= 0
	UI.fit(_block, [b0, ""])


func _show_side(mk: Dictionary, lots: Array, _on: bool) -> void:
	var held: int = sim.e69_fiat_held()
	UI.fit(_fiat, [Fmt.money(sim.cash + held), Fmt.short_num(sim.cash + held)])
	UI.fit(_held[0][1], [Fmt.money(float(held))])
	UI.fit(_held[1][1], [Fmt.money(sim.cash)])
	var mine: Array = []
	for k in range(lots.size()):
		if int(lots[k].get("you", 0)) > 0:
			mine.append(k)
	for j in range(YOUR_ROWS):
		var r: Dictionary = _yours[j]
		r["panel"].visible = j < mine.size()
		if not r["panel"].visible:
			continue
		var lot: Dictionary = lots[mine[j]]
		UI.fit(r["name"], [Words.A69["a_lot"] % [int(mine[j]) + 1, str(lot["name"])], Words.A69["a_lot_short"] % (int(mine[j]) + 1)])
		var lead: bool = str(lot["by"]) == "you"
		UI.fit(r["fig"], ["%s · %s" % [Fmt.money(float(lot["you"])), Words.A69["a_leading"] if lead else Words.A69["a_outbid"]], Fmt.money(float(lot["you"]))])
		r["fig"].add_theme_color_override("font_color", Pal.GOOD if lead else Pal.BAD)
	_yours_none.visible = mine.is_empty()
	UI.fit(_yours_none, [Words.A69["a_no_bids"]])
	var last: Array = mk.get("last", [])
	for j in range(LAST_ROWS):
		var on: bool = j < last.size()
		_last[j][0].visible = on
		_last[j][1].visible = on
		if on:
			var r: Dictionary = last[j]
			UI.fit(_last[j][0], [Words.A69["a_won"] if r["won"] else Words.A69["a_lost"]])
			UI.fit(_last[j][1], ["%s · %s" % [str(r["name"]), Fmt.money(float(r["fiat"])) + ("" if r["won"] else " " + Words.A69["a_back"])], str(r["name"])])
	_last_none.visible = last.is_empty()
	UI.fit(_last_none, [Words.A69["a_no_last"]])
	UI.wrap(_foot, Words.A69["a_foot"])


# ------------------------------------------------------------------ acting

func _pick(k: int) -> void:
	selected = k
	_shown = ""
	show_state(sim)


func _on_bid(steps: int) -> void:
	if sim == null:
		return
	var lot: Dictionary = sim.e69_lot(selected)
	if lot.is_empty():
		return
	var least: int = sim.e69_bid_min(selected)
	var amount: int = least + steps * maxi(1, least - int(lot["high"]))
	if sim.e69_bid(selected, amount):
		_shown = ""
		acted.emit()


func _on_drop() -> void:
	if sim != null and sim.e69_drop(selected):
		_shown = ""
		acted.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_shown = ""


# ------------------------------------------------------------------ for the tests

func bid_buttons() -> Array:
	return [_bid, _bid_more, _drop]


func lot_buttons() -> Array:
	return _lots.map(func(l): return l["button"])


func text_nodes() -> Array:
	var out: Array = [_kicker, _title, _closes, _next, _fiat_head, _fiat, _yours_head, _last_head, _yours_none, _last_none]
	out.append_array(_foot)
	for p in _held:
		out.append_array(p)
	for l in _lots:
		if l["button"].visible:
			out.append_array([l["kind"], l["name"], l["key"], l["value"]])
	for r in _yours:
		if r["panel"].visible:
			out.append_array([r["name"], r["fig"]])
	for p in _last:
		out.append_array(p)
	out.append_array(_shut)
	if _bid.visible:
		out.append_array([_d_head, _d_rule, _d_line, _bids_head, _rivals_head, _win, _win_tail, _block, _bid, _bid_more, _drop])
		for r in _bid_rows:
			if r["panel"].visible:
				out.append_array([r["who"], r["fig"]])
		for r in _rival_cards:
			if r["panel"].visible:
				out.append_array([r["who"], r["line"]])
	return out


func labels() -> Array:
	return text_nodes()
