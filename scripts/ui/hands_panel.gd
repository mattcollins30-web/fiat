extends Panel
## The Bunkhouse's hands (29 Oct, docs/design/trips.md 3-4): on the Pitch in the place of "What the Pitch gives now"
## while the Bunkhouse is picked and the Quartermaster's down - the pool of six to hire and the roster as item cells
## (hand_cell.gd), the picked one's lines in full at the head, Hire, Let go, New faces and Better faces at the foot.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Items := preload("res://scripts/sim/items.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const HandCell := preload("res://scripts/ui/hand_cell.gd")

const PAD := 16
const GAP := 8
const POOL_Y := 60
const ROSTER_HEAD_Y := POOL_Y + HandCell.H + 10
const ROSTER_Y := ROSTER_HEAD_Y + 24
const FOOT_H := 40

var sim
var picked := -1                  # a hand's id, the pool's or the roster's
var _head: Label
var _detail: Label
var _pool_head: Label
var _roster_head: Label
var _pool: Array = []             # HandCell, six
var _roster: Array = []           # HandCell, the cap at most
var _shut: Label
var _note: Label
var hire: Button
var let_go: Button
var new_faces: Button
var better_faces: Button


func _init(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	var iw: float = size.x - 2 * PAD
	_head = UI.head(self, Rect2(PAD, 10, 180, UI.HEAD_H), Words.EXPEDITIONS["hands_head"])
	_detail = UI.label(self, Rect2(PAD + 190, 8, iw - 190, 26), "", "Regular", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_pool_head = UI.head(self, Rect2(PAD, 36, iw, 20), Words.EXPEDITIONS["pool_head"])
	var pw: float = (iw - (Data.HAND_POOL - 1) * GAP) / Data.HAND_POOL
	for k in range(Data.HAND_POOL):
		var c := HandCell.new(pw)
		c.position = Vector2(PAD + k * (pw + GAP), POOL_Y)
		c.pressed.connect(_pick.bind(c))
		add_child(c)
		_pool.append(c)
	_roster_head = UI.head(self, Rect2(PAD, ROSTER_HEAD_Y, iw, 20), "")
	var most: int = int(Data.HAND_ROSTER[1])
	var rw: float = (iw - (most - 1) * GAP) / most
	for k in range(most):
		var c := HandCell.new(rw)
		c.position = Vector2(PAD + k * (rw + GAP), ROSTER_Y)
		c.pressed.connect(_pick.bind(c))
		add_child(c)
		_roster.append(c)
	_shut = UI.label(self, Rect2(PAD, POOL_Y, iw, 30), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var fy: float = size.y - PAD - FOOT_H
	var bw: float = (iw - 3 * GAP) / 4.0
	hire = UI.button(self, Rect2(PAD, fy, bw, FOOT_H), true)
	hire.pressed.connect(_hire)
	let_go = UI.button(self, Rect2(PAD + bw + GAP, fy, bw, FOOT_H), false)
	let_go.pressed.connect(_let_go)
	new_faces = UI.button(self, Rect2(PAD + 2 * (bw + GAP), fy, bw, FOOT_H), false)
	new_faces.pressed.connect(func(): _reroll(false))
	better_faces = UI.button(self, Rect2(PAD + 3 * (bw + GAP), fy, bw, FOOT_H), false)
	better_faces.pressed.connect(func(): _reroll(true))
	for b in [hire, let_go, new_faces, better_faces]:
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	_note = UI.label(self, Rect2(PAD + 300, ROSTER_HEAD_Y - 2, iw - 300, 22), "", "Regular", 13, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)     # in the roster's head row, clear of the cells (the UI review's B7)


func show_state(s) -> void:
	sim = s
	var E: Dictionary = Words.EXPEDITIONS
	var open: bool = sim.pool_open()
	var pool: Array = sim.hand_pool_now()
	_shut.visible = not open
	UI.fit(_shut, [E["hands_closed"] if not sim.expeditions_open() else E["hands_shut"]])
	if not _ids().has(picked):
		picked = -1
	for k in range(_pool.size()):
		var c = _pool[k]
		c.picked = k < pool.size() and int(pool[k]["id"]) == picked
		c.show_hand(pool[k] if open and k < pool.size() else {})
	for k in range(_roster.size()):
		var c = _roster[k]
		var h: Dictionary = sim.hands[k] if k < sim.hands.size() else {}
		c.picked = not h.is_empty() and int(h["id"]) == picked
		c.show_hand(h, ("out" if sim.hand_out(h) else ("hurt" if sim.hand_hurt(h) else "")) if not h.is_empty() else "")
	_pool_head.visible = open
	_roster_head.visible = open or not sim.hands.is_empty()
	UI.fit(_roster_head, [E["roster_head"] % [sim.hands.size(), sim.roster_cap()]])
	var ph: Dictionary = _hand(picked)
	if ph.is_empty():
		UI.fit(_detail, [E["pick_hand"] if open else "", ""])
	else:
		var lines: Array = [Items.hand_trade_line(ph)] + Items.hand_lines(ph, false)
		var wage: String = E["wage"] % Fmt.money(sim.hand_wage(ph))
		var forms: Array = []
		for n in range(lines.size(), 0, -1):
			forms.append("%s: %s · %s" % [str(ph["base"]), ", ".join(lines.slice(0, n)), wage])     # the wage never dropped (the UI review's B6)
		forms.append("%s · %s" % [str(ph["base"]), wage])
		UI.fit(_detail, forms)
	var in_pool: bool = pool.any(func(h): return int(h["id"]) == picked)
	var why_hire: String = sim.hire_block(picked) if in_pool else E["pick_hand"]
	hire.disabled = why_hire != ""
	UI.fit_button(hire, [E["hire"]])
	var on_roster: bool = not sim.hand_by_id(picked).is_empty()
	let_go.disabled = not on_roster or sim.hand_out(sim.hand_by_id(picked))
	if picked != _armed:
		_armed = -1
	UI.fit_button(let_go, [E["let_go_again"], E["let_go"]] if _armed >= 0 else [E["let_go"]])
	var nf: String = sim.reroll_block(false)
	new_faces.disabled = nf != ""
	UI.fit_button(new_faces, [E["new_faces"] % Fmt.money(sim.reroll_cost(false)), E["new_faces"] % Fmt.money_k(sim.reroll_cost(false))])
	var bf: String = sim.reroll_block(true)
	better_faces.disabled = bf != ""
	UI.fit_button(better_faces, [E["better_faces"] % Fmt.money(sim.reroll_cost(true)), E["better_faces"] % Fmt.money_k(sim.reroll_cost(true))])
	new_faces.visible = open
	better_faces.visible = open
	hire.visible = open
	let_go.visible = open or not sim.hands.is_empty()
	var note := ""
	if open and in_pool and why_hire != "":
		note = why_hire
	elif open and pool.is_empty():
		note = E["pool_empty"]
	elif open and sim.hands.is_empty():
		note = E["roster_none"]
	elif open and bf != "" and nf == "":
		note = bf
	UI.fit(_note, [note])


func _ids() -> Array:
	var out: Array = sim.hand_pool.map(func(h): return int(h["id"]))
	out.append_array(sim.hands.map(func(h): return int(h["id"])))
	return out


func _hand(id: int) -> Dictionary:
	for h in sim.hand_pool + sim.hands:
		if int(h["id"]) == id:
			return h
	return {}


func _pick(c) -> void:
	picked = int(c.id)
	acted.emit()


func _hire() -> void:
	if sim != null and sim.hire_hand(picked):
		acted.emit()


## Let go: a second press within ARM_MS (the UI review's D2: a Legendary level-10 hand lost on one click).
const ARM_MS := 3000
var _armed := -1
var _armed_at := 0
func _let_go() -> void:
	if sim == null:
		return
	if _armed != picked or Time.get_ticks_msec() - _armed_at > ARM_MS:
		_armed = picked
		_armed_at = Time.get_ticks_msec()
		acted.emit()
		return
	_armed = -1
	if sim.let_go(picked):
		picked = -1
	acted.emit()


func _reroll(better: bool) -> void:
	if sim != null and sim.reroll_pool(better):
		picked = -1
		acted.emit()


## For the smoke: the cells shown, the pool's then the roster's.
func cells() -> Array:
	return (_pool + _roster).filter(func(c): return c.visible)


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [_head, _detail, _note]
	for l in [_pool_head, _roster_head, _shut]:
		if l.visible:
			out.append(l)
	for c in _pool + _roster:
		out.append_array(c.text_nodes())
	for b in [hire, let_go, new_faces, better_faces]:
		if b.visible:
			out.append(b)
	return out
