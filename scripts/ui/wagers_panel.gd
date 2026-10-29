extends Panel
## Kev's wagers (29 Oct, docs/design/endgame_activities.md row 1, trips.md 5): before a watched run - a first clear or
## an armed head on the Map, a signal on the Radio - his offer of one to three, each a harder word for a payout, as a row:
## the word and the pay as chips, Take it beside them. Any can be taken; they stack and go on the next run there.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Words := preload("res://scripts/sim/words.gd")
const Sim := preload("res://scripts/sim/sim.gd")

const W := 1018
const H := 520
const PAD := 24
const INNER := W - 2 * PAD
const ROW_H := 64
const TAKE_W := 180
const ROWS_Y := 128

var sim
var key := ""
var place := ""
var title: Label
var kicker: Label
var kev: Label
var rows: Array = []                # {panel, chips, take}
var foot: Label
var done: Button


func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, Pal.WARN))
	kicker = UI.label(self, Rect2(PAD, 14, INNER, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	title = UI.label(self, Rect2(PAD, 40, INNER, 40), Words.WAGERS["title"], "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	kev = UI.label(self, Rect2(PAD, 86, INNER, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(3):
		var p := UI.panel(self, Rect2(PAD, ROWS_Y + k * (ROW_H + 10), INNER, ROW_H), UI.box(Pal.PANEL, 6, 1, Pal.CARD_LINE))
		var ch := Chips.new(INNER - TAKE_W - 48, 2)
		ch.position = Vector2(16, (ROW_H - Chips.CHIP_H) / 2.0)
		p.add_child(ch)
		var b := UI.button(p, Rect2(INNER - TAKE_W - 10, 8, TAKE_W, ROW_H - 16), false)
		b.pressed.connect(_take.bind(k))
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		rows.append({"panel": p, "chips": ch, "take": b})
	foot = UI.label(self, Rect2(PAD, H - PAD - Pal.BUTTON_H - 40, INNER, 26), Words.WAGERS["foot"], "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	done = UI.button(self, Rect2(W - PAD - 220, H - PAD - Pal.BUTTON_H, 220, Pal.BUTTON_H), true)
	done.text = Words.WAGERS["done"]
	done.pressed.connect(func():
		visible = false
		acted.emit())
	visible = false


## Open on a run's offer: the key ("site:3", "sig:17") and the place's name for the kicker.
func open(s, k: String, place_name: String) -> void:
	sim = s
	key = k
	place = place_name
	visible = true
	show_state(sim)


func show_state(s) -> void:
	sim = s
	if not visible or key == "":
		return
	if sim.runner_busy():
		visible = false                     # set off: the offer's spent or gone
		return
	var sig: bool = key.begins_with("sig:")     # a signal's wagers go on that signal's run (the review)
	UI.fit(kicker, [(Words.WAGERS["kicker_sig"] if sig else Words.WAGERS["kicker"]) % place, place])
	UI.fit(kev, [Words.WAGERS["kev"], "Kev"])
	var offer: Array = sim.wager_offer(key)
	_fit_to(offer.size())
	for k in range(rows.size()):
		var r: Dictionary = rows[k]
		r["panel"].visible = k < offer.size()
		if k >= offer.size():
			continue
		var w: Dictionary = offer[k]
		var taken: bool = sim.wager_taken(key, k)
		r["chips"].show_chips([{"forms": [Sim.wager_cond_chip(w)], "colour": Pal.BAD}, {"forms": [Sim.wager_pay_chip(w)], "colour": Pal.GOOD}], 1, true)
		UI.fit_button(r["take"], [Words.WAGERS["taken_btn"]] if taken else [Words.WAGERS["take"]])
		UI.style_button(r["take"], false, "warn" if taken else "")
		r["panel"].add_theme_stylebox_override("panel", UI.box(Pal.PANEL, 6, 2 if taken else 1, Pal.WARN if taken else Pal.CARD_LINE))
	var fw: String = Words.WAGERS["foot_sig"] if sig else Words.WAGERS["foot"]
	UI.fit(foot, [fw, fw.get_slice(".", 0) + "."])
	UI.fit_button(done, [Words.WAGERS["done"]])


## The panel to its offer (the review: a fixed height left a card of empty under one wager): the foot and Done under
## the last row.
func _fit_to(n: int) -> void:
	var rows_end: float = ROWS_Y + n * (ROW_H + 10) - 10
	foot.position.y = rows_end + 16
	done.position.y = foot.position.y + 26 + 12
	size.y = done.position.y + Pal.BUTTON_H + PAD


func _take(k: int) -> void:
	if sim == null:
		return
	sim.take_wager(key, k, not sim.wager_taken(key, k))
	show_state(sim)
	acted.emit()


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [kicker, title, kev, foot, done]
	for r in rows:
		if r["panel"].visible:
			out.append_array(r["chips"].text_nodes())
			out.append(r["take"])
	return out
