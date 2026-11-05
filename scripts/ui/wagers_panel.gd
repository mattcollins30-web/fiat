extends Panel
## Kev's wagers (29 Oct, docs/design/endgame_activities.md row 1, trips.md 5): before a watched run - a first clear or
## an armed head on the Map, a signal on the Radio - his offer of one to three, each a harder word for a payout, as a row:
## the word and the pay as chips, Take it beside them. Any can be taken; they stack and go on the next run there.
## The revamp (BUILD49 U, item 19; Matt: "that menu needs a revamp as its pretty bad"): each row a trade read left to
## right - what it costs (its chip and words), "for", what it pays (its chip and a line), the odds with that wager on its
## own ("42% → 18%"), Take it; the odds as you stand and with what's taken at the top; the foot says the odds count them.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Words := preload("res://scripts/sim/words.gd")
const Data := preload("res://scripts/sim/data.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Sim := preload("res://scripts/sim/sim.gd")
const WagerOdds := preload("res://scripts/ui/wager_odds.gd")

const W := 1018
const H := 520
const PAD := 24
const INNER := W - 2 * PAD
const ROW_H := 72
const TAKE_W := 150
const ROWS_Y := 150
const HEADS_Y := 128               # WHAT IT COSTS · WHAT IT PAYS over the rows
const COST_W := 270                # a row's cost, then "for", then the pay
const FOR_W := 44
const PAY_W := 280
const ODDS_W := 180
const BOX_W := 136                 # the top's two odds boxes
const BOX_H := 64

var sim
var key := ""
var place := ""
var title: Label
var kicker: Label
var kev: Label
var rows: Array = []                # {panel, chips, take, cost, cost_words, for, pay, pay_words, odds_key, odds}
var foot: Label
var done: Button
var heads: Array = []               # the two column heads
var boxes: Array = []               # {panel, key, value}: as you stand, with what's taken


func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, Pal.WARN))
	kicker = UI.label(self, Rect2(PAD, 14, INNER - 2 * BOX_W - 30, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	title = UI.label(self, Rect2(PAD, 40, INNER - 2 * BOX_W - 30, 40), Words.WAGERS["title"], "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	kev = UI.label(self, Rect2(PAD, 86, INNER, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		var bx: float = W - PAD - (2 - k) * BOX_W - (1 - k) * 10
		var bp := UI.panel(self, Rect2(bx, 14, BOX_W, BOX_H), UI.box(Pal.BG, 6, 2 if k == 1 else 0, Pal.WARN))
		var bk := UI.label(bp, Rect2(10, 4, BOX_W - 20, 20), Words.U49_WAGERS["stand"] if k == 0 else Words.U49_WAGERS["with_taken"], "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		var bv := UI.label(bp, Rect2(10, 24, BOX_W - 20, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		boxes.append({"panel": bp, "key": bk, "value": bv})
	for k in range(2):
		var hx: float = PAD + 16.0 + (0.0 if k == 0 else float(COST_W + FOR_W))
		var hd := UI.label(self, Rect2(hx, HEADS_Y, 260, 18), Words.U49_WAGERS["costs"] if k == 0 else Words.U49_WAGERS["pays"], "Medium", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.track(hd, 1)
		heads.append(hd)
	for k in range(3):
		var p := UI.panel(self, Rect2(PAD, ROWS_Y + k * (ROW_H + 10), INNER, ROW_H), UI.box(Pal.PANEL, 6, 1, Pal.CARD_LINE))
		var ch := Chips.new(COST_W + FOR_W + PAY_W, 2)
		ch.visible = false                   # the chips' words, kept for the tests: the row's own chips below say them
		p.add_child(ch)
		var r := {"panel": p, "chips": ch}
		r["cost"] = _chip(p, Vector2(16, 10), Pal.BAD)
		r["cost_words"] = UI.label(p, Rect2(16, 42, COST_W - 20, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["for"] = UI.label(p, Rect2(16 + COST_W, 0, FOR_W, ROW_H), Words.U49_WAGERS["for"], "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
		var px: float = 16 + COST_W + FOR_W
		r["pay"] = _chip(p, Vector2(px, 10), Pal.GOOD)
		r["pay_words"] = UI.label(p, Rect2(px, 42, PAY_W - 10, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var ox: float = INNER - TAKE_W - 10 - 12 - ODDS_W
		r["odds_key"] = UI.label(p, Rect2(ox, 8, ODDS_W, 18), Words.U49_WAGERS["odds_with"], "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		r["odds"] = UI.label(p, Rect2(ox, 28, ODDS_W, 34), "", "SemiBold", Pal.LINE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		var b := UI.button(p, Rect2(INNER - TAKE_W - 10, 10, TAKE_W, ROW_H - 20), false)
		b.pressed.connect(_take.bind(k))
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		r["take"] = b
		rows.append(r)
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
	WagerOdds.touch()                          # its reads start now, stepped by the shell (the review)
	show_state(sim)


func show_state(s) -> void:
	sim = s
	if not visible or key == "":
		return
	if sim.runner_busy() and not (sim.night_break() and key == sim.night_wager_key()):     # a night's break: the next link's (BUILD51-U)
		visible = false                     # set off: the offer's spent or gone
		return
	var sig: bool = key.begins_with("sig:")     # a signal's wagers go on that signal's run (the review)
	UI.fit(kicker, [(Words.WAGERS["kicker_sig"] if sig else Words.WAGERS["kicker"]) % place, place])
	UI.fit(kev, [Words.WAGERS["kev"], "Kev"])
	var offer: Array = sim.wager_offer(key)
	_fit_to(offer.size())
	var taken_now: Array = WagerOdds.taken_of(sim, key)
	var b0: Array = WagerOdds.now(sim, key, [])     # as read so far, stepped by the shell (the review)
	var base: float = float(b0[0])
	for k in range(rows.size()):
		var r: Dictionary = rows[k]
		r["panel"].visible = k < offer.size()
		if k >= offer.size():
			continue
		var w: Dictionary = offer[k]
		var taken: bool = sim.wager_taken(key, k)
		r["chips"].show_chips([{"forms": [Sim.wager_cond_chip(w)], "colour": Pal.BAD}, {"forms": [Sim.wager_pay_chip(w)], "colour": Pal.GOOD}], 1, true)
		_set_chip(r["cost"], Sim.wager_cond_chip(w))
		_set_chip(r["pay"], Sim.wager_pay_chip(w))
		UI.fit(r["cost_words"], [cost_words(w)])
		UI.fit(r["pay_words"], [pay_words(w)])
		var w1: Array = WagerOdds.now(sim, key, [k])
		var with_it: float = float(w1[0])
		if bool(b0[1]) and bool(w1[1]):
			r["odds"].text = "%s → %s" % [Fmt.pct(base), Fmt.pct(with_it)]
			r["odds"].add_theme_color_override("font_color", _tone(with_it))
		else:
			UI.fit(r["odds"], [Words.U49_WAGERS["reading"], Words.U49_WAGERS["reading_short"]])
			r["odds"].add_theme_color_override("font_color", Pal.TEXT_3)
		UI.fit_button(r["take"], [Words.WAGERS["taken_btn"]] if taken else [Words.WAGERS["take"]])
		UI.style_button(r["take"], false, "warn" if taken else "")
		r["panel"].add_theme_stylebox_override("panel", UI.box(Pal.PANEL, 6, 2 if taken else 1, Pal.WARN if taken else Pal.CARD_LINE))
	boxes[0]["value"].text = Fmt.pct(base) if bool(b0[1]) else "…"
	boxes[0]["value"].add_theme_color_override("font_color", _tone(base) if bool(b0[1]) else Pal.TEXT_3)
	var a0: Array = WagerOdds.now(sim, key, taken_now) if not taken_now.is_empty() else b0
	var all_in: float = float(a0[0])
	boxes[1]["value"].text = (Fmt.pct(all_in) if bool(a0[1]) else "…") if not taken_now.is_empty() else "—"
	boxes[1]["value"].add_theme_color_override("font_color", _tone(all_in) if not taken_now.is_empty() and bool(a0[1]) else Pal.TEXT_3)
	(boxes[1]["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_width_left = 2 if not taken_now.is_empty() else 0
	for side in ["border_width_right", "border_width_top", "border_width_bottom"]:
		(boxes[1]["panel"].get_theme_stylebox("panel") as StyleBoxFlat).set(side, 2 if not taken_now.is_empty() else 0)
	var fw: String = Words.U49_WAGERS["foot_sig"] if sig else Words.U49_WAGERS["foot"]     # the odds count them now (item 17)
	UI.fit(foot, [fw, fw.get_slice(".", 0) + "."])
	UI.fit_button(done, [Words.WAGERS["done"]])


## The panel to its offer (the review: a fixed height left a card of empty under one wager): the foot and Done under
## the last row.
func _fit_to(n: int) -> void:
	var rows_end: float = ROWS_Y + n * (ROW_H + 10) - 10
	foot.position.y = rows_end + 16
	done.position.y = foot.position.y + 26 + 12
	size.y = done.position.y + Pal.BUTTON_H + PAD


## A chip of its own in a row: a toned panel round its words.
func _chip(parent: Control, at: Vector2, tone: Color) -> Dictionary:
	var p := UI.panel(parent, Rect2(at, Vector2(80, 28)), UI.box(Color(tone, 0.14), 6))
	var l := UI.label(p, Rect2(10, 0, 60, 28), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, tone, HORIZONTAL_ALIGNMENT_LEFT, false)
	return {"panel": p, "label": l}


func _set_chip(c: Dictionary, txt: String) -> void:
	c["label"].text = txt
	var w: float = ceilf(UI.text_width(c["label"], txt))
	c["label"].size.x = w + 2
	c["panel"].size.x = w + 22


static func _tone(o: float) -> Color:
	return Pal.tone_color("good" if o >= 0.9 else ("warn" if o >= 0.6 else "bad"))


## What a wager costs, in words under its chip (Data.WAGER_CONDS' words, the chip's figure not said twice).
static func cost_words(w: Dictionary) -> String:
	for c in Data.WAGER_CONDS:
		if str(c["id"]) == str(w["cond"]):
			var t: String = str(c["words"])
			if t.contains(": "):
				t = t.get_slice(": ", 1)
				t = t.substr(0, 1).to_upper() + t.substr(1)
			return t
	return ""


## What it pays, in a line under its chip.
static func pay_words(w: Dictionary) -> String:
	match str(w["pay"]):
		"notes":
			return Words.U49_WAGERS["pay_notes"]
		"slot":
			var sw: String = str(Data.WAGER_SLOT_WORDS.get(str(w["slot"]), str(w["slot"]).to_lower()))
			return Words.U49_WAGERS["pay_slot"] % (sw.substr(0, 1).to_upper() + sw.substr(1))
		"quality":
			return Words.U49_WAGERS["pay_quality"]
	return ""


func _take(k: int) -> void:
	if sim == null:
		return
	sim.take_wager(key, k, not sim.wager_taken(key, k))
	WagerOdds.touch()
	show_state(sim)
	acted.emit()


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [kicker, title, kev, foot, done] + heads
	for b in boxes:
		out.append_array([b["key"], b["value"]])
	for r in rows:
		if r["panel"].visible:
			out.append_array([r["cost"]["label"], r["cost_words"], r["for"], r["pay"]["label"], r["pay_words"], r["odds_key"], r["odds"]])
			out.append(r["take"])
	return out
