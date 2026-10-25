extends Panel
## The loot filter's panel (24 Oct, the endgame chase, phase 5): over the Kit's stash and pick panel, the rules a run's
## finds pass through as it comes home - each a row with its number, its words, its act and its switch - and under
## them the picked rule's editor. The first that fits wins, so a rule moves up with ↑. Changes are made in place:
## there's no Save, the rule is the row.

signal closed
signal changed

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const W := 904
const H := 916
const PAD := 22
const HEAD_BTN_H := 44
const LIST_Y := 100
const ROW_H := 40
const ROW_GAP := 6
const EDIT_Y := LIST_Y + 8 * (ROW_H + ROW_GAP) + 10           # 478
const EDIT_ROW_H := 40
const EDIT_ROW_GAP := 8
const EDIT_LABEL_W := 120
const NUM_W := 28
const ACT_W := 130
const SWITCH_W := 76
const UP_W := 56
## The editor's choices: the slot a rule asks for ("" any; Body and Bags the groups), the gun type, the best affix's tier.
const SLOTS := ["", "Primary", "Secondary", "Body", "Bags"]
const GUNS := ["", "smg", "rifle", "shotgun", "pistol", "melee", "improvised"]
const TIERS := [0, 3, 4, 5]
const ACTS := ["keep", "highlight", "scrap"]
const ACT_TONE := {"keep": "good", "highlight": "warn", "scrap": "bad"}

var sim
var picked := -1                   # the rule the editor shows
var _title: Label
var _sub: Label
var _add: Button
var _on: Button
var _close: Button
var _rows: Array = []              # [{"num", "words", "act", "on", "up"}] a row each, LOOT_RULES_MAX of them
var _none: Label
var _edit_head: Label
var _delete: Button
var _hint: Label
var _edit_labels: Array = []
var _kind_btns: Array = []
var _from: Button
var _to: Button
var _slot_btns: Array = []
var _gun_btns: Array = []
var _tier_btns: Array = []
var _act_btns: Array = []
var _note: Label


func _init() -> void:
	size = Vector2(W, H)
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_STOP           # the stash under it takes no click
	_title = UI.label(self, Rect2(PAD, 16, 300, 40), Words.LOOT_RULES["title"], "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_close = UI.button(self, Rect2(W - PAD - 110, 14, 110, HEAD_BTN_H), false)
	_close.text = Words.LOOT_RULES["close"]
	_close.pressed.connect(func(): closed.emit())
	_on = UI.button(self, Rect2(W - PAD - 110 - 8 - 150, 14, 150, HEAD_BTN_H), false)
	_on.pressed.connect(_toggle_all)
	_add = UI.button(self, Rect2(W - PAD - 110 - 8 - 150 - 8 - 170, 14, 170, HEAD_BTN_H), true)
	_add.text = Words.LOOT_RULES["add"]
	_add.pressed.connect(_add_rule)
	_sub = UI.label(self, Rect2(PAD, 62, W - 2 * PAD, 26), Words.LOOT_RULES["sub"], "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var words_w: float = W - 2 * PAD - NUM_W - 8 - ACT_W - 8 - SWITCH_W - 8 - UP_W - 8
	for i in range(8):
		var y: float = LIST_Y + i * (ROW_H + ROW_GAP)
		var num := UI.label(self, Rect2(PAD, y, NUM_W, ROW_H), "%d" % (i + 1), "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT)
		var words := UI.button(self, Rect2(PAD + NUM_W + 8, y, words_w, ROW_H), false)
		words.alignment = HORIZONTAL_ALIGNMENT_LEFT
		words.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 2)
		words.pressed.connect(_pick.bind(i))
		var x: float = PAD + NUM_W + 8 + words_w + 8
		var act := UI.button(self, Rect2(x, y, ACT_W, ROW_H), false)
		act.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 2)
		act.pressed.connect(_cycle_act.bind(i))
		var sw := UI.button(self, Rect2(x + ACT_W + 8, y, SWITCH_W, ROW_H), false)
		sw.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 2)
		sw.pressed.connect(_toggle_rule.bind(i))
		var up := UI.button(self, Rect2(x + ACT_W + 8 + SWITCH_W + 8, y, UP_W, ROW_H), false)
		up.text = Words.LOOT_RULES["up"]
		up.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 2)
		up.pressed.connect(_move_up.bind(i))
		up.tooltip_text = Words.LOOT_RULES["up_tip"]
		act.tooltip_text = Words.LOOT_RULES["act_tip"]
		_rows.append({"num": num, "words": words, "act": act, "on": sw, "up": up})
	_none = UI.label(self, Rect2(PAD, LIST_Y, W - 2 * PAD, ROW_H), Words.LOOT_RULES["none"], "Regular", Pal.CELL_TEXT + 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	# the editor
	UI.panel(self, Rect2(PAD, EDIT_Y - 6, W - 2 * PAD, 1), UI.box(Pal.CARD_LINE, 0))
	_edit_head = UI.label(self, Rect2(PAD, EDIT_Y + 4, 300, 32), Words.LOOT_RULES["edit_head"], "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_hint = UI.label(self, Rect2(PAD + 160, EDIT_Y + 8, 500, 26), Words.LOOT_RULES["pick"], "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_delete = UI.button(self, Rect2(W - PAD - 120, EDIT_Y, 120, ROW_H), false)
	_delete.text = Words.LOOT_RULES["delete"]
	_delete.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 2)
	_delete.pressed.connect(_delete_rule)
	var heads: Array = [Words.LOOT_RULES["kind"], Words.LOOT_RULES["rarity"], Words.LOOT_RULES["slot"], Words.LOOT_RULES["gun"], Words.LOOT_RULES["affix"], Words.LOOT_RULES["then"]]
	for k in range(heads.size()):
		var y: float = _edit_y(k)
		_edit_labels.append(UI.label(self, Rect2(PAD, y, EDIT_LABEL_W, EDIT_ROW_H), heads[k], "Regular", Pal.CELL_TEXT + 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_kind_btns = _chips(0, [Words.LOOT_RULES["plain"], Words.LOOT_RULES["kinds"]], _set_kind)
	_from = _chip_at(1, PAD + EDIT_LABEL_W, 200)
	_from.pressed.connect(_step.bind("rarity"))
	_to = _chip_at(1, PAD + EDIT_LABEL_W + 208, 200)
	_to.pressed.connect(_step.bind("upto"))
	_slot_btns = _chips(2, SLOTS.map(func(sl): return Words.LOOT_RULES["any"] if sl == "" else str(sl)), _set_slot)
	_slot_btns[SLOTS.find("Body")].tooltip_text = Words.LOOT_RULES["body_tip"]
	_slot_btns[SLOTS.find("Bags")].tooltip_text = Words.LOOT_RULES["bags_tip"]
	_gun_btns = _chips(3, GUNS.map(func(g): return _gun_word(g)), _set_gun)
	_tier_btns = _chips(4, TIERS.map(func(t): return Words.LOOT_RULES["any"] if t == 0 else ("T%d" % t if t >= 5 else "T%d+" % t)), _set_tier)
	_act_btns = _chips(5, ACTS.map(func(a): return Words.LOOT_RULES[a]), _set_act)
	_note = UI.label(self, Rect2(PAD, H - 44, W - 2 * PAD, 26), Words.LOOT_RULES["note"], "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)


static func _edit_y(k: int) -> float:
	return EDIT_Y + ROW_H + 12 + k * (EDIT_ROW_H + EDIT_ROW_GAP)


static func _gun_word(g: String) -> String:
	if g == "":
		return Words.LOOT_RULES["any"]
	return "SMG" if g == "smg" else g.capitalize()


func _chip_at(k: int, x: float, w: float) -> Button:
	var b := UI.button(self, Rect2(x, _edit_y(k), w, EDIT_ROW_H), false)
	b.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 1)
	return b


## A row of chips as wide as their words, each pressing `fn` with its index.
func _chips(k: int, texts: Array, fn: Callable) -> Array:
	var out := []
	var x: float = PAD + EDIT_LABEL_W
	for i in range(texts.size()):
		var b := _chip_at(k, x, 0)
		b.text = str(texts[i])
		b.size.x = ceilf(UI.text_width(b, b.text)) + 32.0
		b.pressed.connect(fn.bind(i))
		out.append(b)
		x += b.size.x + 6
	return out


func show_state(s) -> void:
	sim = s
	if picked >= sim.loot_rules.size():
		picked = sim.loot_rules.size() - 1
	var n: int = sim.loot_rules.size()
	_none.visible = n == 0
	for i in range(_rows.size()):
		var row: Dictionary = _rows[i]
		var has: bool = i < n
		for key in row:
			row[key].visible = has
		if not has:
			continue
		var r: Dictionary = sim.loot_rules[i]
		var on: bool = bool(r.get("on", true))
		UI.fit_button(row["words"], [sim.loot_rule_words(r)])
		UI.style_button(row["words"], false, "")
		row["words"].add_theme_color_override("font_color", Pal.ACCENT if i == picked else (Pal.TEXT if on else Pal.TEXT_3))
		row["act"].text = Words.LOOT_RULES[str(r.get("act", "keep"))]
		UI.style_button(row["act"], false, ACT_TONE[str(r.get("act", "keep"))] if on else "")
		row["on"].text = Words.LOOT_RULES["row_on"] if on else Words.LOOT_RULES["row_off"]
		UI.style_button(row["on"], false, "good" if on else "")
		row["up"].disabled = i == 0
	_add.disabled = n >= sim.LOOT_RULES_MAX
	_add.tooltip_text = Words.LOOT_RULES["full"] if _add.disabled else ""
	_on.text = Words.LOOT_RULES["on"] if sim.loot_rules_on else Words.LOOT_RULES["off"]
	UI.style_button(_on, false, "good" if sim.loot_rules_on else "")
	_show_editor()


func _show_editor() -> void:
	var has: bool = picked >= 0 and picked < sim.loot_rules.size()
	_hint.visible = not has
	_delete.visible = has
	for l in _edit_labels:
		l.visible = has
	for group in [_kind_btns, _slot_btns, _gun_btns, _tier_btns, _act_btns, [_from, _to]]:
		for b in group:
			b.visible = has
	if not has:
		return
	var r: Dictionary = sim.loot_rules[picked]
	var special: bool = str(r["kind"]) == "special"
	_edit_head.text = "%s %d" % [Words.LOOT_RULES["edit_head"], picked + 1]
	_mark(_kind_btns, 1 if special else 0)
	var names: Array = Data.RARITIES.map(func(x): return str(x["name"]))
	_from.text = Words.LOOT_RULES["from"] % names[int(r["rarity"])]
	_to.text = Words.LOOT_RULES["to"] % names[int(r["upto"])]
	_mark(_slot_btns, SLOTS.find(str(r["slot"])))
	_mark(_gun_btns, GUNS.find(str(r["gun"])))
	_mark(_tier_btns, TIERS.find(int(r["tier"])))
	_mark(_act_btns, ACTS.find(str(r["act"])), ACT_TONE[str(r["act"])])
	# a special rule asks nothing more: the rows it ignores go quiet
	for group in [_slot_btns, _gun_btns, _tier_btns, [_from, _to]]:
		for b in group:
			b.disabled = special
	_act_btns[ACTS.find("scrap")].disabled = special
	_act_btns[ACTS.find("scrap")].tooltip_text = Words.LOOT_RULES["never_tip"] if special else ""
	for b in _gun_btns:
		b.disabled = special or not (str(r["slot"]) in ["", "Primary", "Secondary"])


## The chosen chip lit; the rest plain.
func _mark(btns: Array, on: int, tone := "") -> void:
	for i in range(btns.size()):
		UI.style_button(btns[i], i == on and tone == "", tone if i == on else "")


func _rule() -> Dictionary:
	return sim.loot_rules[picked] if picked >= 0 and picked < sim.loot_rules.size() else {}


func _done() -> void:
	changed.emit()
	show_state(sim)


func _pick(i: int) -> void:
	picked = i
	show_state(sim)


func _add_rule() -> void:
	if sim.loot_rule_add():
		picked = sim.loot_rules.size() - 1
	_done()


func _delete_rule() -> void:
	if not _rule().is_empty():
		sim.loot_rules.remove_at(picked)
		picked = mini(picked, sim.loot_rules.size() - 1)
	_done()


func _toggle_all() -> void:
	sim.loot_rules_on = not sim.loot_rules_on
	_done()


func _toggle_rule(i: int) -> void:
	sim.loot_rules[i]["on"] = not bool(sim.loot_rules[i].get("on", true))
	_done()


func _cycle_act(i: int) -> void:
	var r: Dictionary = sim.loot_rules[i]
	r["act"] = ACTS[(ACTS.find(str(r["act"])) + 1) % ACTS.size()]
	if str(r["kind"]) == "special" and str(r["act"]) == "scrap":
		r["act"] = "keep"                  # a unique, a set piece, a mythic: kept or highlighted, never scrapped
	_done()


func _move_up(i: int) -> void:
	sim.loot_rule_up(i)
	if picked == i:
		picked = i - 1
	elif picked == i - 1:
		picked = i
	_done()


func _set_kind(k: int) -> void:
	var r := _rule()
	if not r.is_empty():
		r["kind"] = "special" if k == 1 else "any"
		if k == 1 and str(r["act"]) == "scrap":
			r["act"] = "keep"
	_done()


## From and To step through the rarities; From never passes To, nor To From.
func _step(key: String) -> void:
	var r := _rule()
	if r.is_empty():
		return
	var top: int = Data.RARITIES.size() - 1
	if key == "rarity":
		r["rarity"] = (int(r["rarity"]) + 1) % (int(r["upto"]) + 1)
	else:
		var v: int = int(r["upto"]) + 1
		r["upto"] = v if v <= top else int(r["rarity"])
	_done()


func _set_slot(k: int) -> void:
	var r := _rule()
	if not r.is_empty():
		r["slot"] = SLOTS[k]
		if not (SLOTS[k] in ["", "Primary", "Secondary"]):
			r["gun"] = ""                  # a gun type asked of a helmet: nothing would fit
	_done()


func _set_gun(k: int) -> void:
	var r := _rule()
	if not r.is_empty():
		r["gun"] = GUNS[k]
	_done()


func _set_tier(k: int) -> void:
	var r := _rule()
	if not r.is_empty():
		r["tier"] = TIERS[k]
	_done()


func _set_act(k: int) -> void:
	var r := _rule()
	if not r.is_empty() and not (str(r["kind"]) == "special" and ACTS[k] == "scrap"):
		r["act"] = ACTS[k]
	_done()


## For the tests: every label and button showing.
func text_nodes() -> Array:
	var out := [_title, _sub, _note, _edit_head, _hint, _none]
	for row in _rows:
		out.append_array([row["num"], row["words"], row["act"], row["on"], row["up"]])
	out.append_array(_edit_labels + _kind_btns + _slot_btns + _gun_btns + _tier_btns + _act_btns + [_from, _to, _delete, _add, _on, _close])
	return out.filter(func(n): return n.visible)
