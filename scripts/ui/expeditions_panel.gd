extends Control
## The Map's Expeditions (29 Oct, docs/design/trips.md 3): over the map and the card while its tab's on. At the left the
## six far places - a picture each (a test panel until painted: art/places/far_<place>.png), its level, its time, what it
## pays and this week's quota. At the right the picked place's send card: the crew (the lead, two hands), the cargo
## slots, what comes back, the risk bar, the quota, Send them; under it the expeditions out and their bars, a Report
## for one back or held. Fixed geometry: 1536 x 844.

signal acted
signal report(id: int)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Items := preload("res://scripts/sim/items.gd")

const W := 1536
const H := 844
const LEFT_W := 520
const PAD := 16
const PLACE_H := 118
const PLACE_GAP := 8
const PIC_W := 150
const RIGHT_X := LEFT_W + 16
const RIGHT_W := W - RIGHT_X
const INNER := RIGHT_W - 2 * PAD
const CREW_W := 312
const CREW_H := 56
const SLOT_W := 150
const SLOT_GAP := 12
const BAR_W := 560
const OUT_ROWS := 3
const OUT_H := 40

var sim
var place := 0                     # the far place picked
var lead := ""                     # the crew picked: a class's runner, two hand ids (-1 none)
var crew: Array = [-1, -1]
var cargo: Array = []              # [{kind, share}] a slot: "" empty
var slot := "Primary"              # London's: the uniques' slot
var lead_said := ""                # the lead's button as shown, for the smoke
var _places: Array = []            # {button, pic, pic_word, name, line, pays, quota}
var _title: Label
var _level: Label
var _sub: Label
var _quota_head: Label
var _quota: Label
var _crew_head: Label
var _lead: Button
var _hands: Array = []             # two Buttons
var _cargo_head: Label
var _slots: Array = []             # {kind: Button, amt: Button}
var _slot_btn: Button
var _back_head: Label
var _back: Label
var _back2: Label
var _risk_head: Label
var _risk_bar: Panel
var _risk_fill: Panel
var _risk_label: Label
var _risk_line: Label
var send: Button
var note: Label
var _out_head: Label
var _outs: Array = []              # {name, bar, fill, left, report}


func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var E: Dictionary = Words.EXPEDITIONS
	var left := UI.panel(self, Rect2(0, 0, LEFT_W, H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	UI.head(left, Rect2(PAD, 10, LEFT_W - 2 * PAD, UI.HEAD_H), E["far_head"])
	for k in range(Data.EXP_PLACES.size()):
		var b := Button.new()
		b.position = Vector2(PAD, 40 + k * (PLACE_H + PLACE_GAP))
		b.size = Vector2(LEFT_W - 2 * PAD, PLACE_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_place.bind(k))
		left.add_child(b)
		var d := {"button": b}
		var pic := Panel.new()
		pic.position = Vector2(8, 8)
		pic.size = Vector2(PIC_W, PLACE_H - 16)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.clip_contents = true
		b.add_child(pic)
		d["pic"] = pic
		var tex := TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.size = pic.size
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.add_child(tex)
		d["tex"] = tex
		d["pic_name"] = UI.label(pic, Rect2(8, 30, PIC_W - 16, 24), "", "SemiBold", 15, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
		d["pic_word"] = UI.label(pic, Rect2(8, 54, PIC_W - 16, 20), E["art"], "Regular", 12, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
		var tx: float = PIC_W + 20
		var tw: float = b.size.x - tx - 10
		d["name"] = UI.label(b, Rect2(tx, 6, tw, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		d["line"] = UI.label(b, Rect2(tx, 33, tw, 22), "", "Medium", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		d["pays"] = UI.label(b, Rect2(tx, 56, tw, 22), "", "Regular", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		d["quota"] = UI.label(b, Rect2(tx, 82, tw, 22), "", "Medium", 13, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		for key in ["name", "line", "pays", "quota"]:
			d[key].mouse_filter = Control.MOUSE_FILTER_IGNORE
		_places.append(d)
	var right := UI.panel(self, Rect2(RIGHT_X, 0, RIGHT_W, H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_title = UI.label(right, Rect2(PAD, 8, INNER - 160, 38), "", "SemiBold", Pal.TITLE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_level = UI.label(right, Rect2(PAD + INNER - 150, 8, 150, 38), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_sub = UI.label(right, Rect2(PAD, 46, INNER, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_quota_head = UI.head(right, Rect2(PAD, 80, INNER, UI.HEAD_H), E["quota_head"])
	_quota = UI.label(right, Rect2(PAD, 104, INNER, 26), "", "Medium", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_crew_head = UI.head(right, Rect2(PAD, 142, INNER, UI.HEAD_H), E["crew_head"])
	_lead = UI.button(right, Rect2(PAD, 168, CREW_W, CREW_H), false)
	_lead.pressed.connect(_next_lead)
	for k in range(2):
		var hb := UI.button(right, Rect2(PAD + (k + 1) * (CREW_W + 16), 168, CREW_W, CREW_H), false)
		hb.pressed.connect(_next_hand.bind(k))
		_hands.append(hb)
	for b in [_lead] + _hands:
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	_cargo_head = UI.head(right, Rect2(PAD, 238, INNER, UI.HEAD_H), "")
	for k in range(Data.EXP_SLOTS_MAX):
		var x: float = PAD + k * (SLOT_W + SLOT_GAP)
		var kb := UI.button(right, Rect2(x, 264, SLOT_W, 48), false)
		kb.pressed.connect(_next_kind.bind(k))
		var ab := UI.button(right, Rect2(x, 316, SLOT_W, 32), false)
		ab.pressed.connect(_next_amount.bind(k))
		for b in [kb, ab]:
			b.add_theme_font_size_override("font_size", 14)
		_slots.append({"kind": kb, "amt": ab})
	_slot_btn = UI.button(right, Rect2(PAD, 360, 360, 36), false)
	_slot_btn.add_theme_font_size_override("font_size", 14)
	_slot_btn.pressed.connect(_next_slot)
	_back_head = UI.head(right, Rect2(PAD, 408, INNER, UI.HEAD_H), E["back_head"])
	_back = UI.label(right, Rect2(PAD, 432, INNER, 26), "", "Medium", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_back2 = UI.label(right, Rect2(PAD, 458, INNER, 24), "", "Regular", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_risk_head = UI.head(right, Rect2(PAD, 494, INNER, UI.HEAD_H), E["risk_head"])
	_risk_bar = UI.panel(right, Rect2(PAD, 522, BAR_W, 22), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
	_risk_fill = UI.panel(_risk_bar, Rect2(0, 0, 0, 22), UI.box(Pal.WARN, 6))
	_risk_label = UI.label(right, Rect2(PAD + BAR_W + 16, 516, INNER - BAR_W - 16, 34), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_risk_line = UI.label(right, Rect2(PAD, 552, INNER, 24), "", "Regular", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	send = UI.button(right, Rect2(PAD, 588, 280, Pal.BUTTON_H), true)
	send.pressed.connect(_send)
	note = UI.label(right, Rect2(PAD + 296, 588, INNER - 296, Pal.BUTTON_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_out_head = UI.head(right, Rect2(PAD, 664, INNER, UI.HEAD_H), "")
	for k in range(OUT_ROWS):
		var y: float = 690 + k * (OUT_H + 8)
		var o := {}
		o["name"] = UI.label(right, Rect2(PAD, y, 430, OUT_H), "", "Medium", 14, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["bar"] = UI.panel(right, Rect2(PAD + 440, y + 12, 220, 16), UI.box(Pal.BG, 5, 1, Pal.CARD_LINE))
		o["fill"] = UI.panel(o["bar"], Rect2(0, 0, 0, 16), UI.box(Pal.GOOD, 5))
		o["left"] = UI.label(right, Rect2(PAD + 672, y, 140, OUT_H), "", "Medium", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["report"] = UI.button(right, Rect2(PAD + INNER - 140, y, 140, OUT_H), false)
		o["report"].add_theme_font_size_override("font_size", 14)
		o["report"].pressed.connect(_report.bind(k))
		_outs.append(o)
	visible = false


## A duration as the place cards say it: "30 min", "1 h 20 min", "3 h".
static func dur(seconds: float) -> String:
	var m: int = int(round(seconds / 60.0))
	@warning_ignore("integer_division")
	var h: int = m / 60
	m = m % 60
	if h == 0:
		return "%d min" % m
	return ("%d h" % h) if m == 0 else ("%d h %d min" % [h, m])


## What a far place pays, in words: "meds, the Clinic's supplies".
func pays_words(p: int) -> String:
	var parts: Array = []
	for kv in Data.EXP_PLACES[p]["pays"]:
		parts.append(_kind_word(str(kv[0])))
	return ", ".join(parts)


func _kind_word(k: String) -> String:
	if k == "tins":
		return sim.money_word()
	return str(Words.EXPEDITIONS.get("k_" + k, k))


func show_state(s) -> void:
	sim = s
	var E: Dictionary = Words.EXPEDITIONS
	_fix_crew()
	for k in range(_places.size()):
		var d: Dictionary = _places[k]
		var pl: Dictionary = Data.EXP_PLACES[k]
		var on: bool = k == place
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			d["button"].add_theme_stylebox_override(st, UI.box(Pal.SELECT if st == "hover" else Pal.PANEL, 6, 2 if on else 1, Pal.ACCENT if on else Pal.CARD_LINE))
		var tex: Texture2D = UI.place_texture("far " + str(pl["key"]))
		d["tex"].texture = tex
		d["pic"].add_theme_stylebox_override("panel", UI.box(Color(Pal.tone_color(["good", "warn", "rare", "epic", "bad", "legendary"][k % 6]), 0.18), 4, 1, Pal.CARD_LINE))
		d["pic_name"].visible = tex == null
		d["pic_word"].visible = tex == null
		UI.fit(d["pic_name"], [str(pl["short"])])
		UI.fit(d["name"], [str(pl["name"]), str(pl["short"])])
		UI.fit(d["line"], ["%s · %s" % [E["level"] % sim.exp_level(k), dur(float(pl["time"]))]])
		UI.fit(d["pays"], [E["pays"] % pays_words(k), pays_words(k)])
		var q: Dictionary = sim.exp_quota(k)
		var done: bool = int(sim.quota_done.get(str(pl["key"]), -1)) == sim.exp_week()
		if q.is_empty():
			d["quota"].text = ""
		elif done:
			UI.fit(d["quota"], [E["quota_met"], "Met this week"])
		else:
			UI.fit(d["quota"], [E["quota_chip"] % ("%d %s" % [int(q["n"]), sim.cargo_name(str(q["kind"])).to_lower()]), E["quota_chip"] % str(int(q["n"]))])
	_show_card()
	_show_outs()


func _show_card() -> void:
	var E: Dictionary = Words.EXPEDITIONS
	var pl: Dictionary = Data.EXP_PLACES[place]
	UI.fit(_title, [str(pl["name"]), str(pl["short"])])
	UI.fit(_level, [E["level"] % sim.exp_level(place)])
	var hs: Array = _crew_ids()
	UI.fit(_sub, ["%s · %s" % [E["pays"] % pays_words(place), dur(sim.exp_time(place, hs))], E["pays"] % pays_words(place)])
	var q: Dictionary = sim.exp_quota(place)
	if q.is_empty():
		UI.fit(_quota, [E["quota_shut"]])
		_quota.add_theme_color_override("font_color", Pal.TEXT_3)
	elif int(sim.quota_done.get(str(pl["key"]), -1)) == sim.exp_week():
		UI.fit(_quota, [E["quota_met"]])
		_quota.add_theme_color_override("font_color", Pal.GOOD)
	else:
		var kn: String = sim.cargo_name(str(q["kind"])).to_lower()
		var left: int = sim.exp_week_left()
		var days: String = E["quota_left"] % [left, "" if left == 1 else "s"]
		UI.fit(_quota, ["%s · %s" % [E["quota"] % [int(q["n"]), kn, str(q["item"])], days], E["quota"] % [int(q["n"]), kn, str(q["item"])], E["quota_short"] % [int(q["n"]), kn, str(q["item"])]])
		_quota.add_theme_color_override("font_color", Pal.GOOD if sim.quota_met_by(place, _cargo_now()) else Pal.ACCENT)
	# the crew
	if lead == "":
		var away_n: int = sim.expeditions.filter(func(e): return sim.roster.has(str(e["lead"]))).size()
		UI.fit_button(_lead, [E["lead_away"] if away_n > 0 else E["lead_none"]])
	else:
		UI.fit_button(_lead, [E["lead"] % [lead, sim.crew_level(lead)], E["lead_short"] % [lead, sim.crew_level(lead)], lead])
	_lead.disabled = sim.exp_leads().size() <= 1 and lead != ""
	var most: int = sim.exp_hands_max()
	for k in range(2):
		var hb: Button = _hands[k]
		if k >= most:
			UI.fit_button(hb, [E["hand_shut"] % ("A hand along" if k == 0 else "Two along"), "Not yet"])
			hb.disabled = true
			continue
		hb.disabled = false
		var h: Dictionary = sim.hand_by_id(int(crew[k]))
		if h.is_empty():
			UI.fit_button(hb, [E["hand_add"] if not _free_hands().is_empty() else E["hand_none"]])
			hb.disabled = _free_hands().is_empty()
		else:
			UI.fit_button(hb, [E["hand"] % [str(h["base"]), Items.hand_trade_line(h)], E["hand"] % [str(h["base"]), Items.hand_trade_short(h)], str(h["base"])])
	# the cargo
	var n_slots: int = sim.exp_slots(hs)
	while cargo.size() < n_slots:
		cargo.append({"kind": "", "share": 1.0})
	UI.fit(_cargo_head, [E["cargo_head"] % n_slots])
	for k in range(_slots.size()):
		var sd: Dictionary = _slots[k]
		var on: bool = k < n_slots
		sd["kind"].visible = on
		sd["amt"].visible = on
		if not on:
			continue
		var c: Dictionary = cargo[k]
		var kind: String = str(c["kind"])
		if kind == "" or sim.cargo_held(kind) <= 0:
			c["kind"] = ""
			UI.fit_button(sd["kind"], [E["cargo_empty"]])
			UI.fit_button(sd["amt"], ["—"])
			sd["amt"].disabled = true
			continue
		sd["amt"].disabled = false
		var n: int = sim.cargo_share(kind, float(c["share"]))
		UI.fit_button(sd["kind"], [E["cargo"] % [Fmt.group(n), sim.cargo_name(kind).to_lower()], E["cargo"] % [Fmt.short_num(n), sim.cargo_name(kind).to_lower()], sim.cargo_name(kind)])
		var pct: String = E["amt_all"] if float(c["share"]) >= 1.0 else "%d%%" % int(round(float(c["share"]) * 100.0))
		UI.fit_button(sd["amt"], [E["cargo_amt"] % [pct, Fmt.money_k(sim.cargo_slot_worth(kind, n))], pct])
	_slot_btn.visible = str(pl["key"]) == "london"
	UI.fit_button(_slot_btn, [E["slot_pick"] % slot, E["slot_short"] % slot])
	# what comes back
	var goods: Array = _cargo_now()
	var worth: float = sim.cargo_worth(goods)
	var ret: float = sim.exp_return_worth(place, worth, hs)
	if worth <= 0.0:
		UI.fit(_back, [E["back_none"]])
	else:
		UI.fit(_back, ["%s · %s" % [E["back"] % [Fmt.money(ret), pays_words(place)], E["quality"] % int(round(sim.exp_quality(worth, hs, place) * 100.0))], E["back"] % [Fmt.money(ret), pays_words(place)], E["back"] % [Fmt.money_k(ret), ""]])
	var wages: int = sim.crew_wages(hs)
	UI.fit(_back2, [E["time_line"] % [dur(sim.exp_time(place, hs)), Fmt.money(wages)] if wages > 0 else E["time_line_free"] % dur(sim.exp_time(place, hs))])
	# the risk
	var odds_read: Array = sim.exp_odds(place, lead, true) if lead != "" else [0.0, false]
	var odds: float = sim.exp_crew_odds(place, lead, hs) if lead != "" else 0.0
	var risk: float = sim.exp_risk(place, lead, hs, worth, odds) if lead != "" else 0.0
	_risk_fill.size.x = BAR_W * risk
	_risk_fill.visible = lead != "" and bool(odds_read[1])
	_risk_fill.add_theme_stylebox_override("panel", UI.box(Pal.BAD if risk >= 0.5 else (Pal.WARN if risk >= 0.2 else Pal.GOOD), 6))
	if lead == "" or not bool(odds_read[1]):
		UI.fit(_risk_label, [E["shut_reading"] if lead != "" else "—"])
		UI.fit(_risk_line, [E["risk_loss"]])
	else:
		UI.fit(_risk_label, [E["risk"] % int(round(risk * 100.0))])
		var hold: float = sim.exp_hold_chance(place, hs, risk)
		UI.fit(_risk_line, ["%s · %s · %s" % [E["risk_odds"] % int(round(odds * 100.0)), E["risk_hold"] % int(round(hold * 100.0)), E["risk_loss"]],
			"%s · %s" % [E["risk_odds"] % int(round(odds * 100.0)), E["risk_hold"] % int(round(hold * 100.0))]])
	var why: String = sim.exp_send_block(place, lead, hs, goods)
	send.disabled = why != ""
	UI.fit_button(send, [E["send"], E["send_short"]])
	UI.fit(note, [why if why != "" else (E["lead_why"] if lead == "" else ""), ""])
	lead_said = _lead.text


func _show_outs() -> void:
	var E: Dictionary = Words.EXPEDITIONS
	UI.fit(_out_head, [E["out_head"] % [sim.exp_busy(), sim.exp_at_once()]])
	for k in range(_outs.size()):
		var o: Dictionary = _outs[k]
		var e: Dictionary = sim.expeditions[k] if k < sim.expeditions.size() else {}
		for key in ["name", "bar", "left", "report"]:
			o[key].visible = not e.is_empty()
		if e.is_empty():
			continue
		var pl: Dictionary = Data.EXP_PLACES[int(e["place"])]
		var nh: int = e["hands"].size()
		var who: String = str(e["lead"]) + ((" + %d hand%s" % [nh, "" if nh == 1 else "s"]) if nh > 0 else "")
		UI.fit(o["name"], [E["out_line"] % [str(pl["name"]), who], E["out_line"] % [str(pl["short"]), who], str(pl["short"])])
		var st: String = str(e["state"])
		var f: float = clampf((sim.elapsed - float(e["t0"])) / maxf(1.0, float(e["dur"])), 0.0, 1.0) if st == "out" else 1.0
		o["fill"].size.x = 220 * f
		o["fill"].add_theme_stylebox_override("panel", UI.box(Pal.BAD if st == "held" else Pal.GOOD, 5))
		if st == "out":
			UI.fit(o["left"], [E["out_left"] % Fmt.clock(float(e["dur"]) - (sim.elapsed - float(e["t0"])))])
		else:
			UI.fit(o["left"], [E["out_held"] if st == "held" else E["out_back"]])
		o["left"].add_theme_color_override("font_color", Pal.BAD if st == "held" else (Pal.GOOD if st == "back" else Pal.TEXT_2))
		o["report"].visible = st != "out"
		UI.fit_button(o["report"], [E["report"]])


## The crew as picked, put right: a lead who's gone or the one selected swapped for the first free; hands away, hurt or
## let go off; hands past the Bunkhouse's count off.
func _fix_crew() -> void:
	var leads: Array = sim.exp_leads()
	if not (lead in leads):
		lead = str(leads[0]) if not leads.is_empty() else ""
	for k in range(2):
		var h: Dictionary = sim.hand_by_id(int(crew[k]))
		if k >= sim.exp_hands_max() or h.is_empty() or not sim.hand_free(h) or (k == 1 and int(crew[1]) == int(crew[0])):
			crew[k] = -1


func _crew_ids() -> Array:
	return crew.filter(func(x): return int(x) >= 0)


func _free_hands() -> Array:
	return sim.hands.filter(func(h): return sim.hand_free(h))


## The cargo as it would go: each slot's share of what's held now.
func _cargo_now() -> Array:
	var out: Array = []
	for k in range(mini(cargo.size(), sim.exp_slots(_crew_ids()))):
		var c: Dictionary = cargo[k]
		if str(c["kind"]) != "" and sim.cargo_held(str(c["kind"])) > 0:
			out.append({"kind": str(c["kind"]), "n": sim.cargo_share(str(c["kind"]), float(c["share"]))})
	return out


func _pick_place(k: int) -> void:
	place = k
	acted.emit()


func _next_lead() -> void:
	var leads: Array = sim.exp_leads()
	if leads.is_empty():
		return
	lead = str(leads[(leads.find(lead) + 1) % leads.size()])
	acted.emit()


## A hand slot: the next free hand not in the other slot, then none.
func _next_hand(k: int) -> void:
	var free: Array = _free_hands().filter(func(h): return int(h["id"]) != int(crew[1 - k]))
	var ids: Array = free.map(func(h): return int(h["id"]))
	ids.append(-1)
	crew[k] = ids[(ids.find(int(crew[k])) + 1) % ids.size()]
	acted.emit()


## A cargo slot's kind: the next held kind no other slot has, then empty.
func _next_kind(k: int) -> void:
	var kinds: Array = sim.cargo_kinds()
	var taken: Array = []
	for j in range(cargo.size()):
		if j != k:
			taken.append(str(cargo[j]["kind"]))
	var opts: Array = kinds.filter(func(x): return not (x in taken))
	opts.append("")
	cargo[k]["kind"] = opts[(opts.find(str(cargo[k]["kind"])) + 1) % opts.size()]
	acted.emit()


func _next_amount(k: int) -> void:
	var shares: Array = Data.EXP_SHARES
	var i: int = shares.find(float(cargo[k]["share"]))
	cargo[k]["share"] = float(shares[(i + 1) % shares.size()])
	acted.emit()


func _next_slot() -> void:
	var slots: Array = Data.SLOTS
	slot = str(slots[(slots.find(slot) + 1) % slots.size()])
	acted.emit()


func _send() -> void:
	if sim != null and sim.send_expedition(place, lead, _crew_ids(), _cargo_now(), slot):
		cargo = []
		crew = [-1, -1]
		acted.emit()


func _report(k: int) -> void:
	if sim != null and k < sim.expeditions.size():
		report.emit(int(sim.expeditions[k]["id"]))


## For the smoke and the shell: the crew and cargo picked set straight in.
func set_pick(p: int, lead_name: String, hand_ids: Array, goods: Array) -> void:
	place = p
	lead = lead_name
	crew = [hand_ids[0] if hand_ids.size() > 0 else -1, hand_ids[1] if hand_ids.size() > 1 else -1]
	cargo = goods.duplicate(true)


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [_title, _level, _sub, _quota_head, _quota, _crew_head, _lead, _cargo_head, _back_head, _back, _back2, _risk_head, _risk_label, _risk_line, send, note, _out_head]
	out.append_array(_hands)
	for d in _places:
		out.append_array([d["name"], d["line"], d["pays"], d["quota"]])
		if d["pic_name"].visible:
			out.append_array([d["pic_name"], d["pic_word"]])
	for sd in _slots:
		if sd["kind"].visible:
			out.append_array([sd["kind"], sd["amt"]])
	if _slot_btn.visible:
		out.append(_slot_btn)
	for o in _outs:
		if o["name"].visible:
			out.append_array([o["name"], o["left"]])
			if o["report"].visible:
				out.append(o["report"])
	return out
