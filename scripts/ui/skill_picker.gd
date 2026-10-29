extends Panel
## The run's three skills (24 Oct, milestone 8; the canvas "Picking the run's three skills"): both lanes, four
## skills each; the three picked carry their slot number and an amber edge, learnt and unpicked ones are plain, ones
## not learnt are faded with "Learn it in Training". A row: the picture, the name, its line, the cost chip and the rule
## (the language pass's words). Press a row to add it or take it out; the order is the fight's buttons'. Over the
## Runs screen's map; the skills button on the card opens it (missions.gd).

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const SkillBar := preload("res://scripts/ui/skill_bar.gd")

const W := 980
const ROW_H := 70
const ROW_STEP := 74
const LANE_H := 28
const HEAD_H := 84
const FOOT_H := 64
const PIC := 56

var sim
var _title: Label
var _sub: Label
var _foot: Label
var _done: Button
var _lanes: Array = []             # Labels
var rows: Array = []               # {panel, btn, pic, badge, badge_text, name, line, chips, id}


func _init() -> void:
	add_theme_stylebox_override("panel", UI.box(Pal.PANEL, 10, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_title = UI.label(self, Rect2(24, 14, W - 48, 36), "Skills for the run", "SemiBold", 28, Pal.TEXT)
	_sub = UI.label(self, Rect2(24, 50, W - 48, 22), "Pick 3 you've learnt. They lock when you set off.", "Regular", 16, Pal.TEXT_2)
	for k in range(2):
		_lanes.append(UI.label(self, Rect2(24, 0, 300, 24), "", "SemiBold", 14, Pal.TEXT_3))
	for k in range(8):
		var row := {}
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(W - 24, ROW_H)
		b.position = Vector2(12, 0)
		add_child(b)
		row["btn"] = b
		var pic := TextureRect.new()
		pic.position = Vector2(14, 7)
		pic.size = Vector2(PIC, PIC)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pic)
		row["pic"] = pic
		row["badge"] = UI.panel(b, Rect2(4, 4, 22, 22), UI.box(Pal.ACCENT, 11))
		row["badge_text"] = UI.label(row["badge"], Rect2(0, 0, 22, 22), "", "SemiBold", 13, Pal.ACCENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		row["name"] = UI.label(b, Rect2(84, 8, 420, 26), "", "SemiBold", 20, Pal.TEXT)
		row["line"] = UI.label(b, Rect2(84, 37, W - 24 - 84 - 14, 22), "", "Regular", 16, Pal.TEXT_2)
		row["chips"] = Chips.new(420)
		b.add_child(row["chips"])
		var k_i := k
		b.pressed.connect(func(): _press(k_i))
		row["id"] = ""
		rows.append(row)
	_foot = UI.label(self, Rect2(24, 0, 640, 26), "", "Regular", 17, Pal.TEXT_2)
	_done = UI.button(self, Rect2(W - 180, 0, 160, 44), true)
	_done.text = "Done"
	_done.pressed.connect(func():
		visible = false
		acted.emit())
	visible = false


func open(s) -> void:
	sim = s
	visible = true
	show_state(s)


func show_state(s) -> void:
	sim = s
	if not visible or sim == null:
		return
	var ids: Array = Data.SKILLS.keys().filter(func(id): return str(Data.SKILLS[id]["cls"]) == sim.cls)
	var lanes: Array = []
	for id in ids:
		if not lanes.has(Data.SKILLS[id]["lane"]):
			lanes.append(Data.SKILLS[id]["lane"])
	var y := HEAD_H
	var r := 0
	for li in range(_lanes.size()):
		var l: Label = _lanes[li]
		l.visible = li < lanes.size()
		if not l.visible:
			continue
		l.text = str(lanes[li]).to_upper()
		l.position.y = y
		y += LANE_H
		for id in ids.filter(func(x): return Data.SKILLS[x]["lane"] == lanes[li]):
			if r >= rows.size():
				break
			_fill_row(rows[r], str(id), y)
			y += ROW_STEP
			r += 1
		y += 8
	for k in range(r, rows.size()):
		rows[k]["btn"].visible = false
	var picked: int = sim.skill_slots.filter(func(x): return str(x) != "").size()
	var learnt: int = sim.skills_learnt().size()
	_foot.text = ("%d learnt · learn more in Training" % learnt) if learnt < Data.SKILL_SLOTS else (("%d of %d picked · press one to take it out" % [picked, Data.SKILL_SLOTS]) if picked >= Data.SKILL_SLOTS else "%d of %d picked" % [picked, Data.SKILL_SLOTS])
	_foot.position.y = y + 16
	_done.position.y = y + 8
	size = Vector2(W, y + FOOT_H)


func _fill_row(row: Dictionary, id: String, y: float) -> void:
	var info: Dictionary = Data.SKILLS[id]
	var b: Button = row["btn"]
	b.visible = true
	b.position.y = y
	row["id"] = id
	var learnt: bool = sim.skill_known(id)
	var slot: int = sim.skill_slots.find(id)
	var on: bool = slot >= 0
	var look := "%s|%s" % [on, learnt]
	if b.get_meta("look", "") != look:            # restyled on a change only (the review: four boxes a row a refresh)
		b.set_meta("look", look)
		for pair in [["normal", Pal.SELECT if on else Color.TRANSPARENT], ["hover", Pal.SELECT if learnt else Color.TRANSPARENT], ["pressed", Pal.BUTTON_PRESS if learnt else Color.TRANSPARENT], ["disabled", Color.TRANSPARENT]]:
			b.add_theme_stylebox_override(pair[0], UI.box(pair[1], 8, 1, Pal.ACCENT if on else Color.TRANSPARENT))
	b.disabled = not learnt or sim.runner_busy()     # away (29 Oct): the skills are the runner's
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if learnt else Control.CURSOR_ARROW
	row["pic"].texture = SkillBar.picture(id)
	var fade := 1.0 if learnt else 0.42
	row["pic"].modulate = Color(1, 1, 1, fade)
	row["name"].text = str(info["name"])
	row["name"].modulate.a = fade
	row["line"].text = str(info["line"])
	row["line"].modulate.a = fade
	row["badge"].visible = on
	row["badge_text"].text = str(slot + 1)
	var chips: Array = [[SkillBar.chip(sim, id), Pal.ENERGY], [str(Data.SKILL_RULES.get(str(info["rule"]), "")), Pal.TEXT_2]] if learnt else [["Learn it in Training", Pal.TEXT_3]]
	row["chips"].show_chips(chips)
	var used: Rect2 = row["chips"].used_rect()
	row["chips"].position = Vector2(b.size.x - 14 - used.size.x, 8)


func _press(k: int) -> void:
	var id: String = rows[k]["id"]
	if id == "" or sim == null:
		return
	var slot: int = sim.skill_slots.find(id)
	if slot >= 0:
		sim.set_skill_slot(slot, "")
	else:
		var free_slot: int = sim.skill_slots.find("")
		if free_slot < 0:
			return
		sim.set_skill_slot(free_slot, id)
	show_state(sim)
	acted.emit()


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [_title, _sub, _foot]
	for l in _lanes:
		if l.visible:
			out.append(l)
	for row in rows:
		if row["btn"].visible:
			out.append_array([row["name"], row["line"]])
	return out
