extends Panel
## The Clinic's meds (19 Oct, Matt's Clinic B): every med in the stash and the rig as a card - what it heals in all,
## how long it takes and the HP a second as it goes, where it is - and the rig at the foot, a stash med picked going
## into it. Meds heal as they say: a share every second over their time, stopping at full.
##
## Signals: `acted` after a med goes into the rig.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")

const PAD := 20.0
const GAP := 12.0
const CARD_H := 102.0
const ICON := 72.0
const CARDS := 8                      # two across, four down
const RIG_H := 118.0

var sim
var picked := ""                       # a med's base, picked
var _title: Label
var _sub: Label
var _cards: Array = []                 # {button, icon, name, where, total, chips, base}
var _none: Label
var _rig: Panel
var _rig_head: Label
var _rig_line: Label
var _rig_note: Label
var _into: Button
var _shown := ""


func _init(w: float, h: float) -> void:
	size = Vector2(w, h)
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_title = UI.label(self, Rect2(PAD, 12, 200, 36), "Your meds", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(self, Rect2(PAD + 190, 20, w - 2 * PAD - 190, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var cw: float = (w - 2 * PAD - GAP) / 2.0
	for k in range(CARDS):
		@warning_ignore("integer_division")
		var x: float = PAD + (k % 2) * (cw + GAP)
		@warning_ignore("integer_division")
		var y: float = 60.0 + (k / 2) * (CARD_H + GAP)
		var b := Button.new()
		b.position = Vector2(x, y)
		b.size = Vector2(cw, CARD_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick.bind(k))
		add_child(b)
		var c := {"button": b, "base": ""}
		var icon := ItemCell.new()               # the stash's own cell: its art, or its words where there's none yet
		icon.position = Vector2(10, (CARD_H - ICON) / 2.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icon)
		c["icon"] = icon
		var tx: float = ICON + 22
		c["name"] = UI.label(b, Rect2(tx, 8, cw - tx - 150, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["where"] = UI.label(b, Rect2(cw - 160, 10, 150, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		c["total"] = UI.label(b, Rect2(tx, 36, cw - tx - 10, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var ch := Chips.new(cw - tx - 10)
		ch.position = Vector2(tx, 66)
		ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ch)
		c["chips"] = ch
		for l in [c["name"], c["where"], c["total"]]:
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cards.append(c)
	_none = UI.label(self, Rect2(PAD, 64, w - 2 * PAD, 28), "No meds in the stash or the rig: the shelf has some", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_rig = UI.panel(self, Rect2(PAD, h - PAD - RIG_H, w - 2 * PAD, RIG_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var rw: float = _rig.size.x
	_rig_head = UI.label(_rig, Rect2(16, 12, rw - 300, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_rig_line = UI.label(_rig, Rect2(16, 38, rw - 300, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_rig_note = UI.label(_rig, Rect2(16, 72, rw - 300, 24), "Used under fire, in the order taken", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_into = UI.button(_rig, Rect2(rw - 16 - 250, (RIG_H - Pal.BUTTON_H) / 2.0, 250, Pal.BUTTON_H), false)
	_into.pressed.connect(_put_in)


## The meds there are, by kind: [base, an example, in the stash, in the rig], the rig's first.
func meds() -> Array:
	var by := {}
	var order: Array = []
	for pair in [[sim.rig, "rig"], [sim.stash, "stash"]]:
		for it in pair[0]:
			if not Items.is_medical(it):
				continue
			var b: String = str(it["base"])
			if not by.has(b):
				by[b] = {"it": it, "stash": 0, "rig": 0}
				order.append(b)
			by[b][pair[1]] += Items.stack_size(it) if Items.stacks(it) else 1
	return order.map(func(b): return [b, by[b]["it"], int(by[b]["stash"]), int(by[b]["rig"])])


## A med's card words: [total over the time, a second's, how it ends].
func med_lines(it: Dictionary) -> Array:
	var heal: float = sim.med_heal(it)
	var t: float = sim.use_time(it)
	var total: String = ("%d HP over %s s" % [int(round(heal)), ("%.1f" % t) if t < 10.0 and t != floorf(t) else str(int(t))]) if t > 0.0 else "%d HP at once" % int(round(heal))
	var per: String = ("%d HP a second" % int(round(heal / t))) if t > 0.0 else "all at once"
	var over: float = Items.affix_total(it, "overflow_pct")
	var ends: String = ("%d%% over goes to Guard" % int(over)) if over > 0.0 else "stops at full"
	return [total, per, ends]


func show_state(s) -> void:
	sim = s
	var list := meds()
	var sig := "%s|%s|%d|%d|%s" % [str(list.map(func(m): return [m[0], m[2], m[3]])), picked, sim.rig_used(), sim.med_capacity(), str(sim.on_mission())]
	if sig == _shown:
		return
	_shown = sig
	UI.fit(_sub, ["in the stash and the rig · what each does for you", "what each does for you"])
	_none.visible = list.is_empty()
	if not list.any(func(m): return m[0] == picked):
		picked = ""
		for m in list:
			if int(m[2]) > 0:
				picked = m[0]                 # the first in the stash: what Into the rig would take
				break
	for k in range(_cards.size()):
		var c: Dictionary = _cards[k]
		var b: Button = c["button"]
		b.visible = k < list.size()
		if not b.visible:
			continue
		var m: Array = list[k]
		c["base"] = m[0]
		var it: Dictionary = m[1]
		c["icon"].show_item(it, false, Vector2(ICON, ICON))
		UI.fit(c["name"], [str(m[0])])
		var where: Array = []
		if int(m[2]) > 0:
			where.append("×%d in the stash" % int(m[2]))
		if int(m[3]) > 0:
			where.append(("×%d in the rig" % int(m[3])) if int(m[3]) > 1 else "in the rig")
		UI.fit(c["where"], [" · ".join(where), where[0] if not where.is_empty() else ""])
		c["where"].add_theme_color_override("font_color", Pal.GOOD if int(m[3]) > 0 and int(m[2]) == 0 else Pal.TEXT_2)
		var ln: Array = med_lines(it)
		c["total"].text = ln[0]
		c["chips"].show_chips([{"forms": [ln[1], ln[1].replace(" a second", "/s")], "colour": "good"}, {"forms": [ln[2], ln[2].replace("stops at full", "to full").replace(" over goes to Guard", " to Guard")], "colour": Pal.TEXT_2}], 1, true)
		var on: bool = m[0] == picked
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, UI.box(Pal.SELECT if (st == "hover") else Pal.PANEL, 8, 2 if on else 1, Pal.ACCENT if on else Pal.CARD_LINE))
	# the rig
	var names: Array = []
	var counts := {}
	for it in sim.rig:
		var nm: String = str(it["base"])
		if not counts.has(nm):
			counts[nm] = 0
			names.append(nm)
		counts[nm] += 1
	_rig_head.text = "THE RIG · %d OF %d POUCHES" % [sim.rig_used(), sim.med_capacity()]
	if sim.med_capacity() == 0:
		UI.fit(_rig_line, ["No rig fitted: fit one in the Kit to carry meds", "No rig fitted"])
	else:
		var words: Array = names.map(func(nm): return nm if int(counts[nm]) == 1 else "%s ×%d" % [nm, int(counts[nm])])
		UI.fit(_rig_line, [", ".join(words) if not words.is_empty() else "Empty", "%d in the rig" % sim.rig.size()])
	var in_stash: bool = picked != "" and list.any(func(m): return m[0] == picked and int(m[2]) > 0)
	_into.visible = in_stash
	if in_stash:
		UI.fit_button(_into, ["%s into the rig" % picked, "Into the rig"])
		_into.disabled = sim.on_mission() or not sim.rig_room(1)
		UI.style_button(_into, false)


func _pick(k: int) -> void:
	picked = str(_cards[k]["base"])
	_shown = ""
	show_state(sim)


func _put_in() -> void:
	for it in sim.stash:
		if Items.is_medical(it) and str(it["base"]) == picked:
			if sim.take(it["id"]):
				_shown = ""
				acted.emit()
			return


func text_nodes() -> Array:
	var out: Array = [_title, _sub, _rig_head, _rig_line, _rig_note]
	if _none.visible:
		out.append(_none)
	if _into.visible:
		out.append(_into)
	for c in _cards:
		if c["button"].visible:
			out.append_array([c["name"], c["where"], c["total"]])
			out.append_array(c["chips"].text_nodes())
	return out
