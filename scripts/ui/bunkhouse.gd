extends Control
## (BUILD69-R) The Bunkhouse as its own room on the rail (8 Nov, docs/design/endgame_rail.md §4; the Bunkhouse mockup):
## opens with the Quartermaster's fall (scrambled on the rail before), and holds what the expeditions had - the hands
## hired, the expeditions out and back, the far places. A header strip with the room's name and its line, two views
## under it: the hands (hire and the roster, hands_panel.gd, then the expeditions out and back with their reports)
## and the far places (expeditions_panel.gd whole: the places, the send card, the out list), moved off the Map's tab.
## Fixed geometry: 1536 x 916, the rooms' size.

signal acted
signal went_out                                 # (fix 69) Fetch them started the run: the shell goes to the Map

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const HandsPanel := preload("res://scripts/ui/hands_panel.gd")
const ExpeditionsPanel := preload("res://scripts/ui/expeditions_panel.gd")
const ExpeditionReport := preload("res://scripts/ui/expedition_report.gd")
const HandCell := preload("res://scripts/ui/hand_cell.gd")

const W := Pal.GRID_W                          # 1536
const H := Pal.ROOM_H                          # 916
const HEAD_H := H - ExpeditionsPanel.H         # 72: the far places' panel whole under it
const TAB_W := 220
const TAB_H := 48
const GAP := 10
const PAD := 18
const HANDS_H := 60 + 2 * HandCell.H + 10 + 24 + 16 + 40 + 16     # hands_panel.gd's pool, roster and foot
const OUT_ROWS := 3
const OUT_ROW_H := 56

var sim
var view := "hands"                            # "hands" or "far"
var title: Label
var line: Label
var tab_hands: Button
var tab_far: Button
var hands                                       # hands_panel.gd
var far                                         # expeditions_panel.gd
var report                                      # expedition_report.gd, over the room
var _outs_card: Panel
var _outs_head: Label
var _outs_none: Label
var _outs: Array = []                           # {name, state, report}


func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var R: Dictionary = Words.R69
	var head := UI.panel(self, Rect2(0, 0, W, HEAD_H - GAP), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	title = UI.label(head, Rect2(PAD, 0, 400, 36), R["bunk_title"], "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)     # the name over its line (the mockup's band)
	line = UI.label(head, Rect2(PAD, 34, W - 2 * PAD - 2 * TAB_W - 2 * GAP, 26), R["bunk_line"], "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	tab_hands = UI.button(head, Rect2(W - PAD - 2 * TAB_W - GAP, (HEAD_H - GAP - TAB_H) / 2.0, TAB_W, TAB_H), false)
	tab_hands.pressed.connect(set_view.bind("hands"))
	tab_far = UI.button(head, Rect2(W - PAD - TAB_W, (HEAD_H - GAP - TAB_H) / 2.0, TAB_W, TAB_H), false)
	tab_far.pressed.connect(set_view.bind("far"))
	hands = HandsPanel.new(Rect2(0, HEAD_H, W, HANDS_H))
	hands.acted.connect(_acted)
	add_child(hands)
	var oy: float = HEAD_H + HANDS_H + GAP
	_outs_card = UI.panel(self, Rect2(0, oy, W, H - oy), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_outs_head = UI.head(_outs_card, Rect2(PAD, 10, W - 2 * PAD, UI.HEAD_H), "")
	_outs_none = UI.label(_outs_card, Rect2(PAD, 40, W - 2 * PAD, OUT_ROW_H), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(OUT_ROWS):
		var y: float = 40 + k * (OUT_ROW_H + 6)
		var o := {}
		o["name"] = UI.label(_outs_card, Rect2(PAD, y, 820, OUT_ROW_H), "", "Medium", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["state"] = UI.label(_outs_card, Rect2(PAD + 840, y, 360, OUT_ROW_H), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["report"] = UI.button(_outs_card, Rect2(W - PAD - 220, y + (OUT_ROW_H - TAB_H) / 2.0, 220, TAB_H), true)
		o["report"].pressed.connect(_report.bind(k))
		_outs.append(o)
	far = ExpeditionsPanel.new()
	far.position = Vector2(0, HEAD_H)
	far.acted.connect(_acted)
	far.report.connect(func(id: int):
		report.id = id
		_acted())
	add_child(far)
	report = ExpeditionReport.new()
	report.position = Vector2((W - ExpeditionReport.W) / 2.0, HEAD_H + 40)
	report.acted.connect(_on_report_acted)
	add_child(report)
	visible = false


var _was_out := false                           # the runner out as the room was last shown (a press comes after a paint)
func _on_report_acted() -> void:
	var was: bool = _was_out
	_acted()
	if sim != null and sim.on_mission() and not was:
		went_out.emit()


func _acted() -> void:
	if sim != null:
		show_state(sim)
	acted.emit()


func set_view(v: String) -> void:
	view = v
	if sim != null:
		show_state(sim)


func _report(k: int) -> void:
	if sim != null and k < sim.expeditions.size():
		report.id = int(sim.expeditions[k]["id"])
		_acted()


func show_state(s) -> void:
	sim = s
	_was_out = sim.on_mission()
	var R: Dictionary = Words.R69
	var E: Dictionary = Words.EXPEDITIONS
	var back: int = sim.expeditions.filter(func(e): return str(e["state"]) != "out").size()
	UI.fit_button(tab_hands, [R["bunk_tab_hands"]])
	UI.fit_button(tab_far, [R["bunk_tab_far"]])
	UI.style_button(tab_hands, view == "hands", "good" if view == "hands" else "")
	UI.style_button(tab_far, view == "far", "good" if view == "far" else "")
	hands.visible = view == "hands"
	_outs_card.visible = view == "hands"
	far.visible = view == "far"
	if view == "hands":
		hands.show_state(sim)
		UI.fit(_outs_head, [(E["out_head"] % [sim.exp_busy() - back, sim.exp_at_once()]) + ((" · " + R["bunk_back"] % back) if back > 0 else "")])
		UI.fit(_outs_none, [E["out_none"] if sim.expeditions.is_empty() else ""])
		for k in range(_outs.size()):
			var o: Dictionary = _outs[k]
			var e: Dictionary = sim.expeditions[k] if k < sim.expeditions.size() else {}
			o["name"].visible = not e.is_empty()
			o["state"].visible = not e.is_empty()
			o["report"].visible = not e.is_empty() and str(e["state"]) != "out"
			if e.is_empty():
				continue
			var pl: Dictionary = Data.EXP_PLACES[int(e["place"])]
			var nh: int = e["hands"].size()
			var who: String = str(e["lead"]) + ((" + %d hand%s" % [nh, "" if nh == 1 else "s"]) if nh > 0 else "")
			UI.fit(o["name"], [E["out_line"] % [str(pl["name"]), who], E["out_line"] % [str(pl["short"]), who], str(pl["short"])])
			var st: String = str(e["state"])
			if st == "out":
				UI.fit(o["state"], [E["out_left"] % Fmt.clock(float(e["dur"]) - (sim.elapsed - float(e["t0"])))])
			else:
				UI.fit(o["state"], [E["out_held"] if st == "held" else E["out_back"]])
			o["state"].add_theme_color_override("font_color", Pal.BAD if st == "held" else (Pal.WARN if st == "back" else Pal.TEXT_2))
			UI.fit_button(o["report"], [R["bunk_unload"] if st == "back" else E["report"], E["report"]])
	else:
		far.show_state(sim)
	report.show_state(sim)
	report.move_to_front()


func text_nodes() -> Array:
	var out: Array = [title, line, tab_hands, tab_far]
	if view == "hands":
		out.append_array(hands.text_nodes())
		out.append_array([_outs_head, _outs_none])
		for o in _outs:
			if o["name"].visible:
				out.append_array([o["name"], o["state"]])
			if o["report"].visible:
				out.append(o["report"])
	else:
		out.append_array(far.text_nodes())
	if report.visible:
		out.append_array(report.text_nodes())
	return out
