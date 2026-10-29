extends Panel
## An expedition's report (29 Oct, docs/design/trips.md 3): one card over the Map when a crew's back or held. Back: what
## came back as chips (the finds in their rarity's colour, the rest counted), the roll and the quota, the hands' levels
## and hurts, Take it and Later. Held: the three ways out - Fetch them (the runner to the hold site: a watched run, its
## head the holder), Pay the ransom, Walk away (the cargo and the hands sent leave the camp) - and Later.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Items := preload("res://scripts/sim/items.gd")

const W := 1018
const H := 640
const PAD := 24
const INNER := W - 2 * PAD
const GOT_ROWS := 4
const HAND_LINES := 2
const BTN_W := 220

var sim
var id := -1                       # the expedition shown; -1 the first due
var title: Label
var sub: Label
var chips: Chips
var got_head: Label
var got: Chips
var hands_head: Label
var hand_lines: Array[Label] = []
var held_line: Label
var ways: Array = []               # {button, note}: fetch, pay, walk
var take: Button
var later: Button


func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, Pal.WARN))
	var E: Dictionary = Words.EXPEDITIONS
	title = UI.label(self, Rect2(PAD, 16, INNER, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	sub = UI.label(self, Rect2(PAD, 58, INNER, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	chips = Chips.new(INNER, 4)
	chips.position = Vector2(PAD, 94)
	add_child(chips)
	got_head = UI.head(self, Rect2(PAD, 136, INNER, UI.HEAD_H), E["rep_got_head"])
	got = Chips.new(INNER, 16)
	got.position = Vector2(PAD, 164)
	add_child(got)
	var hy: float = 164 + GOT_ROWS * (Chips.CHIP_H + Chips.ROW_GAP) + 16
	hands_head = UI.head(self, Rect2(PAD, hy, INNER, UI.HEAD_H), E["rep_hands_head"])
	for k in range(HAND_LINES):
		hand_lines.append(UI.label(self, Rect2(PAD, hy + 28 + k * 28, INNER, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	held_line = UI.label(self, Rect2(PAD, 136, INNER, 30), E["rep_held_line"], "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(3):
		var y: float = 180 + k * 76
		var b := UI.button(self, Rect2(PAD, y, 300, 56), k == 0)
		b.pressed.connect(_way.bind(k))
		var n := UI.label(self, Rect2(PAD + 316, y, INNER - 316, 56), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		ways.append({"button": b, "note": n})
	var by: float = H - PAD - Pal.BUTTON_H
	later = UI.button(self, Rect2(W - PAD - BTN_W, by, BTN_W, Pal.BUTTON_H), false)
	later.pressed.connect(_later)
	take = UI.button(self, Rect2(W - PAD - 2 * BTN_W - 12, by, BTN_W, Pal.BUTTON_H), true)
	take.pressed.connect(_take)
	visible = false


## The report of `id`, or the first due when -1. Shown while there's one.
func show_state(s) -> void:
	sim = s
	var e: Dictionary = sim.exp_by_id(id) if id >= 0 else sim.exp_report_due()
	if not e.is_empty() and (str(e["state"]) == "out" or sim.exp_fetching(int(e["id"]))):
		e = {}
	visible = not e.is_empty()
	if not visible:
		id = -1
		return
	id = int(e["id"])
	var E: Dictionary = Words.EXPEDITIONS
	var pl: Dictionary = Data.EXP_PLACES[int(e["place"])]
	var held: bool = str(e["state"]) == "held"
	UI.fit(title, [(E["rep_held_title"] if held else E["rep_title"]) % Words.mid(str(pl["name"])), (E["rep_held_title"] if held else E["rep_title"]) % str(pl["short"])])
	var nh: int = e["hands"].size()
	UI.fit(sub, [E["rep_sub"] % [str(e["lead"]), nh, "" if nh == 1 else "s", Fmt.money(float(e["worth"]))], E["rep_sub"] % [str(e["lead"]), nh, "" if nh == 1 else "s", Fmt.money_k(float(e["worth"]))]])
	var res: Dictionary = e.get("res", {})
	var top: Array = []
	if bool(res.get("bad", false)):
		top.append({"forms": [E["rep_bad"] % int(round(float(res.get("loss", 0.0)) * 100.0))], "colour": Pal.BAD})
	else:
		top.append({"forms": [E["rep_good"]], "colour": Pal.GOOD})
	if bool(e.get("quota", false)):
		var qi: String = str(res.get("quota_item", ""))
		top.append({"forms": [E["rep_quota"] % [int(round(float(res.get("bonus", 0.0)) * 100.0)), qi if qi != "" else _quota_words(e)], (E["rep_quota"] % [int(round(float(res.get("bonus", 0.0)) * 100.0)), ""]).trim_suffix(" and ")], "colour": Pal.ACCENT})
	chips.show_chips(top, 1, true)
	for w in ways:
		w["button"].visible = held
		w["note"].visible = held
	held_line.visible = held
	got_head.visible = not held
	got.visible = not held
	hands_head.visible = not held
	take.visible = not held
	for l in hand_lines:
		l.visible = not held
	if held:
		var i: int = sim.exp_hold_site(id)
		var fb: String = sim.exp_fetch_block(id)
		ways[0]["button"].disabled = fb != ""
		UI.fit_button(ways[0]["button"], [E["fetch"]])
		var site: String = Words.mid(str(Data.TIERS[i]["name"])) if i >= 0 else ""
		UI.fit(ways[0]["note"], [E["fetch_note"] % site + ("" if fb == "" else " · " + fb), E["fetch_note"] % site])
		var price: int = sim.exp_ransom(id)
		ways[1]["button"].disabled = sim.cash < price
		UI.fit_button(ways[1]["button"], [E["pay"] % Fmt.money(price), E["pay"] % Fmt.money_k(price)])
		UI.fit(ways[1]["note"], [E["shut_held"] % sim.money_word() if sim.cash < price else ""])
		UI.fit_button(ways[2]["button"], [E["walk"]])
		UI.fit(ways[2]["note"], [E["walk_note"]])
	else:
		var items: Array = []
		for it in res.get("items", []):
			items.append({"forms": [Items.full_name(it)], "colour": Pal.tone_color(Pal.item_tone(it)) if Pal.item_tone(it) != "" else Pal.TEXT_2})
		for k in res.get("cur", {}):
			var v = res["cur"][k]
			var words := ""
			match str(k):
				"tins":
					words = Fmt.money(float(v))
				"tokens":
					words = E["tokens"] % [int(v), "" if int(v) == 1 else "s"]
				_:
					words = "%s %s" % [Fmt.group(int(v)), sim.exchange_name(str(k)).to_lower()]
			items.append({"forms": [words], "colour": Pal.TEXT})
		if int(res.get("halves", 0)) > 0:
			items.append({"forms": [E["halves"] % [int(res["halves"]), "" if int(res["halves"]) == 1 else "s"]], "colour": Pal.ACCENT})
		if items.is_empty():
			items.append({"forms": [E["rep_nothing"]], "colour": Pal.TEXT_3})
		got.show_chips(items, GOT_ROWS, true)
		var lines: Array = []
		for u in res.get("ups", []):
			var h: Dictionary = sim.hand_by_id(int(u[0]))
			if h.is_empty():
				continue
			var hurt: bool = int(u[0]) in res.get("hurt", [])
			var line: String = (E["rep_hand_up"] % [str(h["base"]), int(u[1]), int(u[2])]) if int(u[2]) > int(u[1]) else (E["rep_hand_lv"] % [str(h["base"]), int(u[2])])
			if hurt:
				line = E["rep_hurt"] % [line, _dur(float(e["dur"]))]
			lines.append(line)
		hands_head.visible = not lines.is_empty()
		for k in range(hand_lines.size()):
			hand_lines[k].visible = k < lines.size()
			if k < lines.size():
				UI.fit(hand_lines[k], [lines[k]])
		UI.fit_button(take, [E["take"]])
	UI.fit_button(later, [E["later"]])


static func _dur(seconds: float) -> String:
	var m: int = int(round(seconds / 60.0))
	@warning_ignore("integer_division")
	var h: int = m / 60
	m = m % 60
	if h == 0:
		return "%d min" % m
	return ("%d h" % h) if m == 0 else ("%d h %d min" % [h, m])


func _quota_words(e: Dictionary) -> String:
	match str(Data.EXP_PLACES[int(e["place"])]["quota"]):
		"gamble":
			return Words.EXPEDITIONS["q_gamble"]
		"rebuild":
			return Words.EXPEDITIONS["q_rebuild"]
	return Words.EXPEDITIONS["rep_no_quota"]


func _way(k: int) -> void:
	if sim == null or id < 0:
		return
	var ok := false
	match k:
		0:
			ok = sim.exp_fetch(id)
		1:
			ok = sim.exp_pay(id)
		2:
			ok = sim.exp_walk(id)
	if ok:
		if k != 1:
			id = -1
		acted.emit()


func _take() -> void:
	if sim != null and sim.exp_take(id):
		id = -1
		acted.emit()


func _later() -> void:
	if sim != null:
		sim.exp_later(id)
		id = -1
		acted.emit()


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [title, sub, later]
	out.append_array(chips.text_nodes())
	if held_line.visible:
		out.append(held_line)
		for w in ways:
			out.append_array([w["button"], w["note"]])
	else:
		out.append_array([got_head, take])
		out.append_array(got.text_nodes())
		if hands_head.visible:
			out.append(hands_head)
		for l in hand_lines:
			if l.visible:
				out.append(l)
	return out
