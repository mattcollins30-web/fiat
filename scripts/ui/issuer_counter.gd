extends Panel
## The Issuer's counter (25 Oct, the Issue: docs/design/the_issue.md; the canvas 'The Issuer's counter'): the Fence's
## fifth tab once the town's on fiat. His rate (the Fence buys at it), the fiat in circulation and what it's done to
## prices; issued kit, a piece a slot, stamped and numbered, sold for fiat; the burn, which takes fiat out and the
## prices down with it.
##
## Signals: `acted` after a buy or a burn.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")

const PAD := 20
const ROW_H := 62
const ROW_GAP := 6
const BUY_W := 190
const FIG_W := 230

var sim
var _w := 0.0
var _said: Label
var _figs: Array = []                  # [cap, value] x3: the rate, the circulation, the prices
var _rows: Array = []                  # {panel, icon, name, rule, buy, slot}
var _burn_title: Label
var _burn_line: Label
var _burn: Button
var _want: Label
var _shown := ""


func _init(w: float, h: float) -> void:
	_w = w
	size = Vector2(w, h)
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_PASS
	UI.label(self, Rect2(PAD, PAD, 300, 36), Words.ISSUED["tab"], "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_said = UI.label(self, Rect2(PAD + 220, PAD + 6, w - 2 * PAD - 220, 28), Words.ISSUED["said"], "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var y := PAD + 48.0
	for k in range(3):
		var x: float = PAD + k * (FIG_W + 16)
		var cap := UI.label(self, Rect2(x, y, FIG_W, 22), [Words.ISSUED["rate"], Words.ISSUED["circ"], Words.ISSUED["prices"]][k], "SemiBold", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		var val := UI.label(self, Rect2(x, y + 22, FIG_W, 40), "", "Bold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		_figs.append([cap, val])
	y += 76
	UI.head(self, Rect2(PAD, y, w - 2 * PAD, UI.HEAD_H), Words.ISSUED["head"].to_upper() + " · STAMPED, NUMBERED, A RULE EACH")
	y += UI.HEAD_H + 6
	for u in Data.ISSUED:
		var row := {"slot": str(u["slot"])}
		var p := UI.panel(self, Rect2(PAD, y, w - 2 * PAD, ROW_H), UI.box(Pal.PANEL, 6))
		row["panel"] = p
		var icon := ItemCell.new()
		icon.position = Vector2(8, 7)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(icon)
		row["icon"] = icon
		var tw: float = w - 2 * PAD - 86 - BUY_W - 24
		row["name"] = UI.label(p, Rect2(86, 6, tw, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		row["rule"] = UI.label(p, Rect2(86, 32, tw, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var b := UI.button(p, Rect2(w - 2 * PAD - BUY_W - 10, 10, BUY_W, ROW_H - 20), true)
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		b.pressed.connect(_buy.bind(str(u["slot"])))
		row["buy"] = b
		_rows.append(row)
		y += ROW_H + ROW_GAP
	y += 8
	var bp := UI.panel(self, Rect2(PAD, y, w - 2 * PAD, ROW_H), UI.box(Pal.PANEL, 6))
	_burn_title = UI.label(bp, Rect2(14, 6, w - 2 * PAD - BUY_W - 40, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_burn_line = UI.label(bp, Rect2(14, 32, w - 2 * PAD - BUY_W - 40, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_burn = UI.button(bp, Rect2(w - 2 * PAD - BUY_W - 10, 10, BUY_W, ROW_H - 20), false)
	_burn.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
	_burn.text = Words.ISSUED["burn_go"]
	_burn.pressed.connect(_on_burn)
	y += ROW_H + 10
	_want = UI.label(self, Rect2(PAD, y, w - 2 * PAD, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)


func show_state(s) -> void:
	sim = s
	if sim == null:
		return
	var sig := "%d|%.3f|%d|%d|%d|%d" % [int(sim.cash), sim.fiat_rate, int(sim.circulation), sim.reach, sim.stash.size(), sim.issued_worn()]
	if sig == _shown:
		return
	_shown = sig
	var r: float = sim.fiat_rate
	_figs[0][1].text = "%.2f" % r
	_figs[0][1].add_theme_color_override("font_color", Pal.GOOD if r > 1.005 else (Pal.BAD if r < 0.995 else Pal.ACCENT))
	UI.fit(_figs[1][1], [Fmt.money(sim.circulation), Fmt.short_num(sim.circulation)])
	_figs[2][1].text = "×%.2f" % sim.circ_mult()
	for row in _rows:
		var u: Dictionary = sim.issued_def(row["slot"])
		var it: Dictionary = sim.issued_piece(row["slot"])
		row["icon"].show_item(it, false, Vector2(64, 48))
		UI.fit(row["name"], ["%s · %s · item level %d" % [u["name"], row["slot"], Items.ilvl(it)], "%s · %s" % [u["name"], row["slot"]], str(u["name"])])
		UI.fit(row["rule"], [str(u["words"]), str(u.get("short", u["words"]))])
		var block: String = sim.issued_block(row["slot"])
		var price: int = sim.issued_price(row["slot"])
		UI.fit_button(row["buy"], (["Buy · %s" % Fmt.money(price), Fmt.money(price)]) if block == "" else [block, Fmt.money(price)])
		row["buy"].disabled = block != ""
		UI.style_button(row["buy"], block == "", "" if block == "" else "")
	_burn_title.text = Words.ISSUED["burn"] % Fmt.money(sim.burn_price())
	UI.fit(_burn_line, [Words.ISSUED["burn_line"] % [sim.circ_mult(), sim.circ_mult_after_burn()], "Prices ×%.2f → ×%.2f" % [sim.circ_mult(), sim.circ_mult_after_burn()]])
	_burn.disabled = not sim.can_burn()
	var want: int = int(Data.ISSUED_WANT[0])
	UI.fit(_want, [Words.ISSUED["want"] % [want, "" if want == 1 else "s"] + " · %d worn" % sim.issued_worn(), Words.ISSUED["want"] % [want, "" if want == 1 else "s"]])


func _buy(slot: String) -> void:
	if sim != null and sim.buy_issued(slot):
		_shown = ""
		acted.emit()


func _on_burn() -> void:
	if sim != null and sim.burn():
		_shown = ""
		acted.emit()


## For the tests: every label's words fit its box.
func labels() -> Array:
	var out: Array = [_said, _burn_title, _burn_line, _want]
	for f in _figs:
		out.append_array(f)
	for row in _rows:
		out.append_array([row["name"], row["rule"]])
	return out
