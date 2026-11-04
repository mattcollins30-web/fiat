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
const People := preload("res://scripts/ui/people.gd")
const Dashed := preload("res://scripts/ui/dashed.gd")

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
# the place card, layout B (BUILD49 U, item 15; Matt: "this needs a rework too"): the site card's row
const CARD_PIC_H := 150
const ROW_Y := 162                 # the party, the verdict, what comes back
const PARTY_W := 300
const BACK_W := 300
const LEAD_FACE := 64
const HAND_W := 48
const CARGO_Y := 318
const CARGO_H := 150
const CARGO_TEXT_W := 206
const CELL_W := 112
const CELL_H := 82
const CELL_GAP := 10
const STEP_H := 26
const FOOT_Y := CARGO_Y + CARGO_H + 14
const OUT_Y := FOOT_Y + Pal.BUTTON_H + 22

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
var _stakes: Label                 # what the hands sent risk (the fix round): shown with a hand picked
var send: Button
var note: Label
var _out_head: Label
var _out_none: Label
var risk_word := ""                # the verdict shown: Safe, Risky, A bad idea (for the smoke)
var _outs: Array = []              # {name, bar, fill, left, report}
# the card's own (item 15)
var _pic: TextureRect
var _kicker: Label
var _party_head: Label
var _lead_frame: Panel
var _lead_face: TextureRect
var _lead_name: Label
var _hands_line: Label
var _verdict: Label
var _risk_why: Label
var _risk_why2: Label
var _back_big: Label
var _back_quality: Label
var _cargo_box: Panel
var _cargo_lines: Array = []
var _out_small: Label


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
	_build_card(right)
	_out_head = UI.head(right, Rect2(PAD, OUT_Y, INNER, UI.HEAD_H), "")
	_out_none = UI.label(right, Rect2(PAD, OUT_Y + 26, INNER, OUT_H), "", "Regular", 14, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(OUT_ROWS):
		var y: float = OUT_Y + 26 + k * (OUT_H + 8)
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


## The place card (BUILD49 U, item 15, layout B): the place's picture as its header, with its level and time, what it
## pays and this week's quota; the site card's row under it - the party (the lead's portrait, the hands' places as
## dashed slots), the verdict between in the odds' words with its one figure, what comes back; the cargo in one strip,
## each slot an item cell with its picture, count and worth and a − / + stepper; Send (greyed at A bad idea, still
## pressable, the reason beside it). Steps not built aren't buttons.
func _build_card(right: Panel) -> void:
	var E: Dictionary = Words.EXPEDITIONS
	var U: Dictionary = Words.U49_EXP
	var head := Control.new()
	head.position = Vector2(1, 1)
	head.size = Vector2(RIGHT_W - 2, CARD_PIC_H)
	head.clip_contents = true
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(head)
	_pic = TextureRect.new()
	_pic.size = head.size
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_pic)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.15), Color(Pal.CARD, 0.95)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	var fade := TextureRect.new()
	fade.texture = gt
	fade.size = head.size
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(fade)
	_kicker = UI.label(right, Rect2(PAD + 8, 10, INNER - 280, 24), U["kicker"], "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_title = UI.label(right, Rect2(PAD + 8, 34, INNER - 280, 44), "", "SemiBold", Pal.HEADLINE - 6, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	var lv_box := UI.panel(right, Rect2(PAD + INNER - 250, 12, 250, 32), UI.box(Color(Pal.BG, 0.8), 6))
	_level = UI.label(lv_box, Rect2(10, 0, 230, 32), "", "Medium", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_sub = UI.label(right, Rect2(PAD + 8, CARD_PIC_H - 34, INNER * 0.55, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_quota_head = UI.head(right, Rect2(PAD + INNER * 0.55 + 8, CARD_PIC_H - 54, INNER * 0.45 - 16, 18), E["quota_head"])
	_quota_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quota = UI.label(right, Rect2(PAD + INNER * 0.55 + 8, CARD_PIC_H - 34, INNER * 0.45 - 16, 26), "", "Medium", Pal.CELL_TEXT - 1, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for l in [_kicker, _title, _sub, _quota, _quota_head]:
		UI.shadow(l)
	# the party
	_party_head = UI.head(right, Rect2(PAD, ROW_Y, PARTY_W, 18), E["crew_head"])
	_crew_head = _party_head
	_lead = Button.new()
	_lead.position = Vector2(PAD, ROW_Y + 24)
	_lead.size = Vector2(LEAD_FACE + 4, LEAD_FACE + 4)
	_lead.focus_mode = Control.FOCUS_ALL
	_lead.pressed.connect(_next_lead)
	_lead.tooltip_text = U["lead_tip"]
	right.add_child(_lead)
	_lead_frame = UI.panel(_lead, Rect2(0, 0, LEAD_FACE + 4, LEAD_FACE + 4), UI.box(Pal.BG, 6, 2, Pal.GOOD))
	_lead_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lead_face = People.rect(_lead_frame, Vector2(2, 2), LEAD_FACE / 128.0)
	for b in [_lead]:
		for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(st, UI.box(Color(0, 0, 0, 0), 6))
	for k in range(2):
		var hb := Button.new()
		hb.position = Vector2(PAD + LEAD_FACE + 14 + k * (HAND_W + 10), ROW_Y + 24 + (LEAD_FACE - HAND_W) / 2.0 + 2)
		hb.size = Vector2(HAND_W, HAND_W)
		hb.focus_mode = Control.FOCUS_ALL
		hb.pressed.connect(_next_hand.bind(k))
		hb.clip_text = true
		hb.add_theme_font_size_override("font_size", 22)
		right.add_child(hb)
		var d := Dashed.new(hb.size)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(d)
		hb.set_meta("dash", d)
		_hands.append(hb)
	_lead_name = UI.label(right, Rect2(PAD, ROW_Y + 24 + LEAD_FACE + 8, PARTY_W, 24), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_hands_line = UI.label(right, Rect2(PAD, ROW_Y + 24 + LEAD_FACE + 32, PARTY_W, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	# the verdict between
	var mx: float = PAD + PARTY_W + 10
	var mw: float = INNER - PARTY_W - BACK_W - 20
	_verdict = UI.label(right, Rect2(mx, ROW_Y + 16, mw, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	_risk_label = UI.label(right, Rect2(mx, ROW_Y + 56, mw, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	_risk_why = UI.label(right, Rect2(mx, ROW_Y + 84, mw, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
	_risk_why2 = UI.label(right, Rect2(mx, ROW_Y + 104, mw, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
	_risk_line = _risk_why
	_risk_head = UI.label(right, Rect2(mx, ROW_Y, mw, 1), "", "Regular", 10, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)     # (the old head: the verdict says it now)
	_risk_head.visible = false
	_risk_bar = UI.panel(right, Rect2(mx, ROW_Y, 1, 1), UI.box(Pal.BG, 0))
	_risk_bar.visible = false
	_risk_fill = UI.panel(_risk_bar, Rect2(0, 0, 0, 1), UI.box(Pal.WARN, 0))
	_stakes = UI.label(right, Rect2(PAD + 236, FOOT_Y + Pal.BUTTON_H + 2, INNER - 236 - 160, 20), "", "Regular", Pal.CELL_TEXT - 3, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT, false)     # what the hands risk, under Send's reason
	# what comes back
	var bx: float = PAD + INNER - BACK_W
	_back_head = UI.head(right, Rect2(bx, ROW_Y, BACK_W, 18), E["back_head"])
	_back_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_back_big = UI.label(right, Rect2(bx, ROW_Y + 22, BACK_W, 34), "", "SemiBold", Pal.TITLE - 6, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_back = UI.label(right, Rect2(bx, ROW_Y + 58, BACK_W, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_back_quality = UI.label(right, Rect2(bx, ROW_Y + 80, BACK_W, 22), "", "Medium", Pal.CELL_TEXT, Pal.GOOD, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_back2 = UI.label(right, Rect2(bx, ROW_Y + 102, BACK_W, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	# the cargo strip
	_cargo_box = UI.panel(right, Rect2(PAD, CARGO_Y, INNER, CARGO_H), UI.box(Pal.PANEL, 8))
	_cargo_head = UI.head(_cargo_box, Rect2(14, 10, CARGO_TEXT_W - 14, 18), "")
	for k in range(4):
		_cargo_lines.append(UI.label(_cargo_box, Rect2(14, 32 + k * 20, CARGO_TEXT_W - 18, 20), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	for k in range(Data.EXP_SLOTS_MAX):
		var x: float = CARGO_TEXT_W + k * (CELL_W + CELL_GAP)
		var kb := Button.new()
		kb.position = Vector2(x, 10)
		kb.size = Vector2(CELL_W, CELL_H)
		kb.focus_mode = Control.FOCUS_ALL
		kb.pressed.connect(_next_kind.bind(k))
		_cargo_box.add_child(kb)
		var ic := TextureRect.new()
		ic.position = Vector2((CELL_W - 40) / 2.0, 18)
		ic.size = Vector2(40, 40)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kb.add_child(ic)
		var worth := UI.label(kb, Rect2(6, 2, CELL_W - 12, 16), "", "Regular", Pal.CELL_TEXT - 4, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var nm := UI.label(kb, Rect2(6, CELL_H - 22, CELL_W - 12, 20), "", "SemiBold", Pal.CELL_TEXT - 3, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		var minus := UI.button(_cargo_box, Rect2(x, 10 + CELL_H + 6, STEP_H, STEP_H), false)
		var plus := UI.button(_cargo_box, Rect2(x + CELL_W - STEP_H, 10 + CELL_H + 6, STEP_H, STEP_H), false)
		var signs: Array = []
		for pair in [[minus, "−"], [plus, "+"]]:
			var sl := UI.label(pair[0], Rect2(0, 0, STEP_H, STEP_H), pair[1], "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)     # the sign as a label: the button's own text keeps 32 px of padding
			signs.append(sl)
		minus.pressed.connect(_step_amount.bind(k, -1))
		plus.pressed.connect(_step_amount.bind(k, 1))
		var amt := UI.label(_cargo_box, Rect2(x + STEP_H + 2, 10 + CELL_H + 6, CELL_W - 2 * STEP_H - 4, STEP_H), "", "Medium", Pal.CELL_TEXT - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)

		_slots.append({"kind": kb, "amt": amt, "icon": ic, "worth": worth, "name": nm, "minus": minus, "plus": plus, "signs": signs})
	_slot_btn = UI.button(_cargo_box, Rect2(14, CARGO_H - 32, CARGO_TEXT_W - 24, 26), false)
	_slot_btn.add_theme_font_size_override("font_size", 13)
	_slot_btn.pressed.connect(_next_slot)
	# Send, its reason beside it, what's out at the right
	send = UI.button(right, Rect2(PAD, FOOT_Y, 220, Pal.BUTTON_H), true)
	send.pressed.connect(_send)
	note = UI.label(right, Rect2(PAD + 236, FOOT_Y, INNER - 236 - 160, Pal.BUTTON_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_out_small = UI.label(right, Rect2(PAD + INNER - 150, FOOT_Y, 150, Pal.BUTTON_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)


## A duration as the place cards say it: "30 min", "1 h 20 min", "3 h" (Fmt.dur, the report's too).
static func dur(seconds: float) -> String:
	return Fmt.dur(seconds)


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
		var lv_t: String = "%s · %s" % [E["level"] % sim.exp_level(k), dur(float(pl["time"]))]
		UI.fit(d["line"], (["%s · %s" % [str(pl["line"]), lv_t]] if pl.has("line") else []) + [lv_t])     # Swansea's "Gone quiet"
		UI.fit(d["pays"], [E["pays"] % pays_words(k), pays_words(k)])
		var q: Dictionary = sim.exp_quota(k)
		var done: bool = int(sim.quota_done.get(str(pl["key"]), -1)) == sim.exp_week()
		if q.is_empty():
			d["quota"].text = ""
		elif done:
			UI.fit(d["quota"], [E["quota_met"], E["quota_met_short"]])
		else:
			UI.fit(d["quota"], [E["quota_chip"] % sim.cargo_words(str(q["kind"]), int(q["n"])), sim.cargo_words(str(q["kind"]), int(q["n"]))])
	_show_card()
	_show_outs()


func _show_card() -> void:
	var E: Dictionary = Words.EXPEDITIONS
	var U: Dictionary = Words.U49_EXP
	var pl: Dictionary = Data.EXP_PLACES[place]
	var hs: Array = _crew_ids()
	_pic.texture = UI.place_texture("far " + str(pl["key"]))
	UI.fit(_title, [str(pl["name"]), str(pl["short"])])
	UI.fit(_level, [U["level"] % [sim.exp_level(place), dur(sim.exp_time(place, hs))], E["level"] % sim.exp_level(place)])
	UI.fit(_sub, [E["pays"] % pays_words(place), pays_words(place)])
	# this week's quota: said once it's built; a step not built says nothing here (item 15)
	var q: Dictionary = sim.exp_quota(place)
	_quota_head.visible = not q.is_empty()
	if q.is_empty():
		_quota.text = ""
	elif int(sim.quota_done.get(str(pl["key"]), -1)) == sim.exp_week():
		UI.fit(_quota, [E["quota_met"], E["quota_met_short"]])
		_quota.add_theme_color_override("font_color", Pal.GOOD)
	else:
		var kn: String = sim.cargo_words(str(q["kind"]), int(q["n"]))
		UI.fit(_quota, [E["quota"] % [kn, str(q["item"])], E["quota_short"] % [kn, str(q["item"])], kn])
		_quota.add_theme_color_override("font_color", Pal.GOOD if sim.quota_met_by(place, _cargo_now()) else Pal.ACCENT)
	# the party: the lead's face (a press, the next lead), the hands' places dashed
	_lead_face.visible = lead != ""
	if lead == "":
		var away_n: int = sim.expeditions.filter(func(e): return sim.roster.has(str(e["lead"]))).size()
		_lead.text = ""
		UI.fit(_lead_name, [E["lead_away"] if away_n > 0 else E["lead_none"]])
		lead_said = E["lead_away"] if away_n > 0 else E["lead_none"]
		_lead_name.add_theme_color_override("font_color", Pal.TEXT_3)
	else:
		People.show(_lead_face, lead)
		UI.fit(_lead_name, [U["lead"] % [lead, sim.crew_level(lead)], "%s · %d" % [lead, sim.crew_level(lead)], lead])
		lead_said = _lead_name.text
		_lead_name.add_theme_color_override("font_color", Pal.TEXT)
	_lead.disabled = sim.exp_leads().size() <= 1 and lead != ""
	(_lead_frame.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.GOOD if lead != "" else Pal.CARD_LINE
	var most: int = sim.exp_hands_max()
	var names: Array = []
	for k in range(2):
		var hb: Button = _hands[k]
		hb.visible = true
		var d: Control = hb.get_meta("dash")
		for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			hb.add_theme_stylebox_override(st, UI.box(Pal.BUTTON_HOVER if st == "hover" else Color(0, 0, 0, 0), 6))
		if k >= most:
			hb.text = ""                           # a step not built: an empty place, not a button (item 15)
			hb.disabled = true
			hb.tooltip_text = E["hand_shut"] % str(Data.yard_building("bunkhouse")["picks"][k][1]["name"])
			d.visible = true
			continue
		var h: Dictionary = sim.hand_by_id(int(crew[k]))
		hb.disabled = h.is_empty() and _free_hands().is_empty()
		d.visible = h.is_empty()
		if h.is_empty():
			hb.text = "+"
			hb.tooltip_text = E["hand_add"] if not _free_hands().is_empty() else (E["hand_none"] if not sim.hands.is_empty() else E["hand_none_hired"])
		else:
			var t: int = int(h.get("tier", 1))
			hb.text = str(h["base"]).substr(0, 1)
			hb.tooltip_text = E["hand"] % [str(h["base"]), t, Items.hand_trade_line(h)]
			names.append(E["hand_short"] % [str(h["base"]), t])
			var r: int = int(h.get("rarity", 0))
			hb.add_theme_stylebox_override("normal", UI.box(Pal.PANEL, 6, 2, Pal.tone_color(Pal.rarity_tone(r)) if r > 0 else Pal.CARD_LINE))
	if not names.is_empty():
		UI.fit(_hands_line, [" · ".join(names), U["hands_n"] % names.size()])
	elif most == 0:
		UI.fit(_hands_line, [U["hands_later"], ""])     # the Bunkhouse's step, in one quiet line
	else:
		UI.fit(_hands_line, [U["hands_none"], ""])
	# the cargo: item cells, a stepper each
	var n_slots: int = sim.exp_slots(hs)
	while cargo.size() < n_slots:
		cargo.append({"kind": "", "share": 1.0})
	UI.fit(_cargo_head, [E["cargo_head"] % n_slots])
	UI.wrap(_cargo_lines, U["cargo_words"])
	for k in range(_slots.size()):
		var sd: Dictionary = _slots[k]
		var on: bool = k < n_slots
		for key in ["kind", "amt", "minus", "plus"]:
			sd[key].visible = on
		if not on:
			continue
		var c: Dictionary = cargo[k]
		var kind: String = str(c["kind"])
		var cell: Button = sd["kind"]
		if kind == "" or sim.cargo_held(kind) <= 0:
			c["kind"] = ""
			sd["icon"].texture = null
			sd["worth"].text = ""
			UI.fit(sd["name"], [U["empty"]])
			sd["name"].add_theme_color_override("font_color", Pal.TEXT_3)
			cell.tooltip_text = U["empty_tip"]
			sd["amt"].text = "—"
			sd["minus"].disabled = true
			sd["plus"].disabled = true
			for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
				cell.add_theme_stylebox_override(st, UI.box(Pal.BUTTON_HOVER if st == "hover" else Pal.BG, 6, 1, Pal.CARD_LINE))
			continue
		var n: int = sim.cargo_share(kind, float(c["share"]))
		var noun: String = sim.cargo_words(kind, n).substr(Fmt.group(n).length() + 1)
		sd["icon"].texture = cargo_picture(kind)
		UI.fit(sd["worth"], [Fmt.money_k(sim.cargo_slot_worth(kind, n))])
		UI.fit(sd["name"], [sim.cargo_words(kind, n), "%s %s" % [Fmt.short_num(n), noun], "%s %s" % [Fmt.short_num(n), noun.get_slice(" ", 0)], Fmt.short_num(n)])     # the count first, always (the UI review's A5)
		sd["name"].add_theme_color_override("font_color", Pal.TEXT)
		cell.tooltip_text = U["cell_tip"]
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			cell.add_theme_stylebox_override(st, UI.box(Pal.BUTTON_HOVER if st == "hover" else Pal.BG, 6, 1, Pal.CARD_LINE))
		var share: float = float(c["share"])
		sd["amt"].text = E["amt_all"] if share >= 1.0 else "%d%%" % int(round(share * 100.0))
		sd["minus"].disabled = share <= float(Data.EXP_SHARES[0]) + 0.001
		sd["plus"].disabled = share >= 1.0 - 0.001
		for j in range(2):
			sd["signs"][j].add_theme_color_override("font_color", Pal.TEXT_3 if [sd["minus"], sd["plus"]][j].disabled else Pal.TEXT)
	_slot_btn.visible = str(pl["key"]) == "london"
	UI.fit_button(_slot_btn, [E["slot_pick"] % slot, E["slot_short"] % slot])
	# what comes back
	var goods: Array = _cargo_now()
	var worth: float = sim.cargo_worth(goods)
	var ret: float = sim.exp_return_worth(place, worth, hs)
	if worth <= 0.0:
		UI.fit(_back_big, [U["back_none"]])
		_back_quality.text = ""
	else:
		UI.fit(_back_big, [U["back"] % Fmt.money_k(ret)])
		UI.fit(_back_quality, [E["quality"] % int(round(sim.exp_quality(worth, hs, place) * 100.0))])
	UI.fit(_back, [_cap1(pays_words(place).replace(", ", " · "))])
	var wages: int = sim.crew_wages(hs)
	UI.fit(_back2, [U["back_time"] % [dur(sim.exp_time(place, hs)), Fmt.money(wages)] if wages > 0 else U["back_time_free"] % dur(sim.exp_time(place, hs))])
	# the risk: one figure, in the odds' words
	var odds_read: Array = sim.exp_odds(place, lead, true) if lead != "" else [0.0, false]
	var odds: float = sim.exp_crew_odds(place, lead, hs) if lead != "" else 0.0
	var risk: float = sim.exp_risk(place, lead, hs, worth, odds) if lead != "" else 0.0
	risk_word = ""
	_risk_why2.text = ""
	if lead == "" or not bool(odds_read[1]):
		UI.fit(_verdict, [E["shut_reading"] if lead != "" else "—"])
		_verdict.add_theme_color_override("font_color", Pal.TEXT_3)
		_risk_label.text = ""
		UI.fit(_risk_why, [E["risk_loss"]])
	else:
		risk_word = E["risk_safe"] if risk < 0.2 else (E["risk_risky"] if risk < 0.5 else E["risk_bad"])     # the Map's verdicts (the UI review's D1)
		var tone: Color = Pal.GOOD if risk < 0.2 else (Pal.WARN if risk < 0.5 else Pal.BAD)
		UI.fit(_verdict, [risk_word])
		_verdict.add_theme_color_override("font_color", tone)
		UI.fit(_risk_label, [U["risk"] % int(round(risk * 100.0)), E["risk"] % int(round(risk * 100.0))])
		var hold: float = sim.exp_hold_chance(place, hs, risk)
		var why_bits: Array = []
		if worth > 0.0:
			why_bits.append(U["why_cargo"])
		if odds < 0.5:
			why_bits.append(U["why_odds"])
		var why_l: String = (_cap1("; ".join(why_bits)) + ".") if not why_bits.is_empty() else U["why_fine"]
		UI.wrap([_risk_why, _risk_why2], "%s %s" % [why_l, U["held"] % int(round(hold * 100.0))])
	_risk_label.add_theme_color_override("font_color", Pal.TEXT)
	UI.fit(_stakes, [E["stakes"], E["stakes_short"]] if not hs.is_empty() else [""])
	var why: String = sim.exp_send_block(place, lead, hs, goods)
	send.disabled = why != ""
	var bad: bool = risk >= 0.5 and risk_word != ""
	UI.style_button(send, not bad)                  # A bad idea: greyed, still pressable, the reason beside (item 15)
	UI.fit_button(send, [E["send"], E["send_short"]])
	var nobody: bool = lead == "" and sim.exp_leads().is_empty() and not sim.expeditions.any(func(e): return sim.roster.has(str(e["lead"])))
	if nobody or why != "":
		UI.fit(note, [E["lead_why"] if nobody else why, ""])     # how to get a lead, when there's nobody (the UI review's A4)
		note.add_theme_color_override("font_color", Pal.TEXT_3)
	elif bad:
		UI.fit(note, [U["bad_note"] % int(round(risk * 100.0)), U["bad_note_short"]])
		note.add_theme_color_override("font_color", Pal.BAD)
	else:
		note.text = ""
	UI.fit(_out_small, [U["out_small"] % [sim.exp_busy(), sim.exp_at_once()]])


## A cargo kind's picture: the material's own, the salvage's or the notes' mark, scrap's for the rest.
static func cargo_picture(kind: String) -> Texture2D:
	for path in ["res://art/items/%s.png" % kind, "res://art/ui/%s.png" % kind, "res://art/items/bandage.png" if kind == "meds" else "", "res://art/items/scrap.png"]:
		if path != "" and ResourceLoader.exists(path):
			return load(path)
	return null


static func _cap1(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1) if t != "" else t


func _show_outs() -> void:
	var E: Dictionary = Words.EXPEDITIONS
	UI.fit(_out_head, [E["out_head"] % [sim.exp_busy(), sim.exp_at_once()]])
	UI.fit(_out_none, [E["out_none"] if sim.expeditions.is_empty() else ""])
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
	for j in range(mini(cargo.size(), sim.exp_slots(_crew_ids()))):     # a slot hidden by a smaller party holds nothing (the fix round)
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


## The cargo's − / + (item 15): a quarter of what's held at a time, between a quarter and all.
func _step_amount(k: int, by: int) -> void:
	var shares: Array = Data.EXP_SHARES
	var i: int = shares.find(float(cargo[k]["share"]))
	if i < 0:
		i = shares.size() - 1
	cargo[k]["share"] = float(shares[clampi(i + by, 0, shares.size() - 1)])
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
	var out: Array = [_kicker, _title, _level, _sub, _quota, _crew_head, _lead_name, _hands_line, _cargo_head, _back_head, _back_big, _back, _back_quality, _back2, _verdict, _risk_label, _risk_why, _risk_why2, _stakes, send, note, _out_small, _out_head, _out_none]
	if _quota_head.visible:
		out.append(_quota_head)
	out.append_array(_cargo_lines)
	for d in _places:
		out.append_array([d["name"], d["line"], d["pays"], d["quota"]])
		if d["pic_name"].visible:
			out.append_array([d["pic_name"], d["pic_word"]])
	for sd in _slots:
		if sd["kind"].visible:
			out.append_array([sd["worth"], sd["name"], sd["amt"]] + sd["signs"])
	if _slot_btn.visible:
		out.append(_slot_btn)
	for o in _outs:
		if o["name"].visible:
			out.append_array([o["name"], o["left"]])
			if o["report"].visible:
				out.append(o["report"])
	return out
