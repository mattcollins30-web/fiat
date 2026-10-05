extends Control
## The Armoury's screen - the first thing in the shell that isn't eight cards.
## Tarkov's layout in text: the body's slots down the left, the stash as a
## grid on the right, and under the grid a compare panel for whatever is
## selected against what's fitted in its slot, with Equip, Unequip and Sell.
## Fixed geometry inside the card grid's 1536 x 864, like everything else.
##
## A stash cell has no picture yet, so it carries the slot's short name, the
## item's headline figure, its tier, and its rarity as the border - the
## shape an icon will drop into later.

signal acted
signal bench(id)                   # the bench's menu for this item

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const Containers := preload("res://scripts/ui/containers.gd")
const Body := preload("res://scripts/ui/body.gd")

const BODY_W := Body.WIDTH                                    # 420
const CONTAINERS_Y := Body.HEIGHT + 8                         # 568: the body, then the rig and the pack (to 864)
const GAP := 24
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH                                # 974
const GRID_H := Inventory.HEIGHT                               # 588
const PANEL_Y := GRID_H + GAP                                 # 612
const PANEL_H := Pal.ROOM_H - PANEL_Y                         # 252
const PANEL_PAD := 20
const PANEL_LINES := 6             # figure, what it takes, three affixes with their tiers, the swap word
const LINE_H := 26
const COL_W := (GRID_W - 3 * PANEL_PAD) / 2                   # each half of the compare panel

var sim
var selected := {}                 # {"kind": "stash", "id": n} or {"kind": "slot", "slot": s}, or {}
var _body                          # the slots as boxes to drop on
var _inv                           # the stash grid
var _containers                    # the rig and the pack
var _panel: Panel
var _left_title: Label
var _left_lines: Array[Label] = []
var _right_title: Label
var _right_lines: Array[Label] = []
var _chips: Array[Label] = []      # the swap's changes, one each, green up and red down
var _overall: Label                # the swap in one word, at the right of the panel's title row
var _buttons: Array[Button] = []
var _actions: Array = []
var _toggles: Array[Button] = []   # idle: equip if better, sell the junk - shown with nothing selected
var _hint: Label
var _words: Array[Label] = []      # the item's own line, two rows under the figures
var _shown := ""                   # what the screen last drew, so a refresh that changes nothing redraws nothing


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the body: drag gear from the stash onto its slot; drag it off to the stash
	_body = Body.new()
	_body.picked.connect(_pick_slot)
	_body.equip.connect(_on_equip_drop)
	add_child(_body)
	# the rig and the pack, as grids: drag a med or a stack from the stash onto
	# the rig; drag a rig slot back; the pack is what a run brings home
	_containers = Containers.new()
	_containers.position = Vector2(0, CONTAINERS_Y)
	_containers.picked.connect(_on_rig_pick)
	_containers.take.connect(_on_take)
	_containers.leave.connect(_on_leave)
	add_child(_containers)
	_inv = Inventory.new()
	_inv.position = Vector2(GRID_X, 0)
	_inv.drag_src = "stash"
	_inv.accepts = ["rig", "body"]
	_inv.picked.connect(_on_inv_pick)
	_inv.acted.connect(_on_inv_acted)
	_inv.dropped.connect(_on_stash_drop)
	add_child(_inv)
	_panel = UI.panel(self, Rect2(GRID_X, PANEL_Y, GRID_W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_left_title = UI.label(_panel, Rect2(PANEL_PAD, 10, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_right_title = UI.label(_panel, Rect2(PANEL_PAD * 2 + COL_W, 14, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(PANEL_LINES):
		_left_lines.append(UI.label(_panel, Rect2(PANEL_PAD, 48 + i * LINE_H, COL_W, LINE_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_right_lines.append(UI.label(_panel, Rect2(PANEL_PAD * 2 + COL_W, 48 + i * LINE_H, COL_W, LINE_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(8):
		var c := UI.label(_panel, Rect2(0, 0, 10, 30), "", "SemiBold", Pal.FLOOR, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
		c.visible = false
		_chips.append(c)
	# the swap in one word, on the left column's fourth line - its own label so
	# it can be coloured without touching the lines above it
	_overall = UI.label(_panel, Rect2(PANEL_PAD, 48 + 5 * LINE_H, COL_W, LINE_H), "", "SemiBold", Pal.FLOOR, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
	_hint = UI.label(_panel, Rect2(PANEL_PAD, PANEL_H - 6 - 44, GRID_W - 2 * PANEL_PAD, 44), "",
			"Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(2):
		_words.append(UI.label(_panel, Rect2(PANEL_PAD, 48 + 6 * LINE_H + 4 + i * 20, GRID_W - 2 * PANEL_PAD, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(3):
		var b := UI.button(_panel, Rect2(0, PANEL_H - 6 - 44, 240, 44), i == 0)
		b.pressed.connect(_press.bind(i))
		b.visible = false
		_buttons.append(b)
		_actions.append(Callable())
	for i in range(2):
		var tb := UI.button(_panel, Rect2(0, PANEL_H - 6 - 44, 240, 44), false)
		tb.pressed.connect(_toggle.bind(i))
		tb.visible = false
		_toggles.append(tb)


## "Bandage ×5, Medkit" - items by name with counts.
static func _counted(items: Array) -> String:
	var counts := {}
	var order := []
	for it in items:
		if not counts.has(it["base"]):
			counts[it["base"]] = 0
			order.append(it["base"])
		counts[it["base"]] += 1
	var out := []
	for name in order:
		out.append(name if counts[name] == 1 else "%s ×%d" % [name, counts[name]])
	return ", ".join(out)


## The body's slots, in order, for the tests.
func row_names() -> Array:
	return Data.SLOTS.duplicate()


static func rarity_tone(it: Dictionary) -> String:
	return ["", "good", "warn", "bad"][it["rarity"]]


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	_inv.show_items(sim, sim.stash, sim.stash_used(), sim.stash_cap(), "Stash")
	_body.selected = selected.get("slot", "") if selected.get("kind", "") == "slot" else ""
	_body.show_state(sim)
	_containers.selected = selected["id"] if selected.get("kind", "") == "rig" else -1
	_containers.show_state(sim)
	# main.gd refreshes ten times a second; rebuilding the buttons that often
	# hides and shows them under the mouse, which drops presses. Redraw only
	# when what's shown has changed.
	var sig := _signature()
	if sig == _shown:
		return
	_shown = sig
	_show_panel()


## Everything the screen's look depends on, as one string.
func _signature() -> String:
	var parts := [str(selected), str(sim.on_mission()), str(sim.stash.size()), str(_inv.many), str(sim.workshop), str(sim.auto_equip), str(sim.auto_sell)]
	var sel := _selected_item()
	if not sel.is_empty():
		parts.append(str(sel["affixes"]) + str(sel.get("ilvl", 0)) + str(sel["attachments"].keys()))   # the bench changes these in place
	for slot in Data.SLOTS:
		parts.append(str(sim.equipped[slot]["id"]) if sim.equipped[slot] != null else "-")
	for it in sim.rig:
		parts.append("r" + str(it["id"]))
	for it in sim.stash:
		parts.append(str(it["id"]))
	return "|".join(parts)


func _affix_words(it: Dictionary) -> String:
	var a := Items.affix_lines(it, true)
	if a.is_empty():
		return Items.rarity_name(it)
	return ", ".join(a)


## The compare panel: the selection on the left, what's fitted in its slot on
## the right with the deltas, the buttons for what can be done with it.
func _show_panel() -> void:
	for b in _buttons:
		b.visible = false
	for c in _chips:
		c.visible = false
	_overall.text = ""
	var it := _selected_item()
	_say(it)
	for l in _left_lines:
		l.text = ""
	for l in _right_lines:
		l.text = ""
	for tb in _toggles:
		tb.visible = false
	if it.is_empty():
		_left_title.text = "Select an item"
		_right_title.text = ""
		_hint.text = "A slot on the left, or a stash item on the right"
		# the idle toggles live here, where the buttons would be
		_toggles[0].visible = true
		_toggles[0].text = "Equip if better ✓" if sim.auto_equip else "Equip if better"
		_toggles[1].visible = true
		_toggles[1].text = "Sell the junk on return ✓" if sim.auto_sell else "Sell the junk on return"
		var x := GRID_W - PANEL_PAD
		for k in [1, 0]:
			var tb: Button = _toggles[k]
			tb.size.x = ceilf(UI.text_width(tb, tb.text)) + 48
			x -= tb.size.x
			tb.position.x = x
			x -= 12
			UI.style_button(tb, false, "good" if (sim.auto_equip if k == 0 else sim.auto_sell) else "")
		_lay_buttons()                       # none showing: the hint gets the strip up to the toggles
		_hint.size.x = maxf(80.0, x - PANEL_PAD)
		if UI.text_width(_hint, _hint.text) > _hint.size.x:
			UI.fit(_hint, [_hint.text, _hint.text.get_slice(",", 0)])
		return
	_hint.text = ""
	UI.fit(_left_title, [Items.full_name(it), it["base"]])
	UI.fit(_left_lines[0], Items.figure_options(it))
	var mounts: String = ("%d attachment slots, empty" % it["attachments"].size()) if it["attachments"].size() > 0 else ""
	if Items.is_gun(it):
		UI.fit(_left_lines[1], ["%s · %s" % [Items.ammo_words(it), mounts.to_lower()] if mounts != "" else Items.ammo_words(it), Items.ammo_words(it)])
	else:
		_left_lines[1].text = mounts
	# the affixes, one a line with its tier; "No affixes" on a plain thing
	var lines: Array = Items.affix_lines(it, false, true)
	var short_lines: Array = Items.affix_lines(it, true, true)
	for k in range(3):
		if k < lines.size():
			UI.fit(_left_lines[2 + k], [lines[k], short_lines[k]])
		else:
			_left_lines[2 + k].text = "No affixes" if k == 0 else ""
	if it.has("set"):
		# the set: whose, how many worn, what the next piece brings
		var st: Dictionary = Items.set_named(it["set"])
		var n: int = sim.set_count(it["set"])
		var next_words := ""
		for k in st["bonuses"]:
			if int(k) > n and next_words == "":
				next_words = st["bonuses"][k]["words"]
		var line: String = "%s · %d of %d worn" % [it["set"], n, st["pieces"].size()]
		UI.fit(_left_lines[4], ["%s · next: %s" % [line, next_words.to_lower()] if next_words != "" else "%s · the full set" % line, line])
		_left_lines[4].add_theme_color_override("font_color", Pal.SET)
	else:
		_left_lines[4].add_theme_color_override("font_color", Pal.TEXT_2)
	_right_lines[3].text = ""
	if Items.is_medical(it) or Items.is_ammo(it):
		_show_medical(it)
		_lay_buttons()
		return
	if Items.is_attachment(it):
		_left_lines[0].text = "%s mount, %s T%d" % [it["mount"].capitalize(), Items.rarity_name(it), it["tier"]]
		UI.fit(_left_lines[1], [Items.att_words(it), Items.att_words(it, true)])
		_left_lines[2].text = ""
		_right_title.text = "Fitted at the bench"
		_right_lines[0].text = "Goes on a gun's %s mount" % it["mount"]
		_right_lines[1].text = ""
		_right_lines[2].text = ""
		_right_lines[2].add_theme_color_override("font_color", Pal.TEXT_2)
		_button(0, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
		_lay_buttons()
		return
	var fitted = sim.equipped[it["slot"]]
	var from_stash: bool = selected["kind"] == "stash"
	if from_stash:
		if fitted == null:
			_right_title.text = "Nothing fitted as %s" % it["slot"].to_lower()
			_right_lines[0].text = "Equipping adds everything above"
			_right_lines[1].text = ""
			_right_lines[2].text = ""
		else:
			var fh := Items.headline(fitted)
			_right_title.text = "Fitted: " + fitted["base"]
			_right_lines[0].text = "%s %s · %s T%d" % [fh[0], fh[1], Items.rarity_name(fitted), fitted["tier"]]
			var flines: Array = Items.affix_lines(fitted, false, true)
			var fshort: Array = Items.affix_lines(fitted, true, true)
			for k in range(3):
				if k < flines.size():
					UI.fit(_right_lines[1 + k], [flines[k], fshort[k]])
				else:
					_right_lines[1 + k].text = "No affixes" if k == 0 else ""
			_right_lines[4].text = ""
			_show_swap(it, fitted)
		_button(0, "Equip", sim.equip_item.bind(it["id"]), sim.can_equip_item(it["id"]))
		if not sim.can_equip_item(it["id"]) and not sim.on_mission():
			_hint.text = "No room in the stash for what comes off"
		_button(1, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
		if sim.workshop >= 1 and not it.has("unique"):
			_button(2, "Bench", func(): bench.emit(it["id"]), not sim.on_mission())
	else:
		_right_title.text = "Fitted"
		if sim.workshop >= 1 and not it.has("unique"):
			_button(1, "Bench", func(): bench.emit(it["id"]), not sim.on_mission())
		_right_lines[0].text = "Unequip to put it in the stash"
		_right_lines[1].text = "Stash has %d of %d cells" % [sim.stash_used(), sim.stash_cap()]
		_right_lines[2].text = ""
		_button(0, "Unequip", sim.unequip.bind(it["slot"]), not sim.on_mission() and sim.stash_room(Items.size(it)))
	_lay_buttons()


## The item's own line, under the figures: who it was, where it came from.
func _say(it: Dictionary) -> void:
	UI.wrap(_words, "" if it.is_empty() else (Words.UNIQUES.get(it["unique"], Words.item_words(it["base"])) if it.has("unique") else Words.item_words(it["base"])))


func _lay_buttons() -> void:
	var x := GRID_W - PANEL_PAD
	for i in range(_buttons.size() - 1, -1, -1):
		if _buttons[i].visible:
			x -= _buttons[i].size.x
			_buttons[i].position.x = x
			x -= 12
	# the hint shares the strip with the buttons: it stops where they start
	_hint.size.x = maxf(80.0, x - PANEL_PAD)
	if _hint.text != "" and UI.text_width(_hint, _hint.text) > _hint.size.x:
		UI.fit(_hint, [_hint.text, _hint.text.get_slice(";", 0), _hint.text.get_slice(",", 0), _hint.text.get_slice(" for ", 0)])


## A med: in the stash it can be taken; in the rig it can be left behind.
func _show_medical(it: Dictionary) -> void:
	_right_title.text = "The rig"
	_right_lines[0].text = "%d of %d pouches filled" % [sim.rig_used(), sim.med_capacity()]
	_right_lines[1].text = ("Fired by the %s" % Items.base_of(it)["type"]) if Items.is_ammo(it) else "Used under fire, over a few seconds"
	if Items.is_ammo(it):
		var gun = sim.equipped["Primary"]
		var sec = sim.equipped["Secondary"]
		var feeds := []
		for g in [gun, sec]:
			if g != null and Items.ammo_type(g) == Items.base_of(it)["type"]:
				feeds.append(g["base"])
		_right_lines[1].text = ("Feeds the %s" % " and the ".join(feeds).to_lower()) if not feeds.is_empty() else "Nothing fitted fires it"
	_right_lines[2].text = ""
	_right_lines[2].add_theme_color_override("font_color", Pal.TEXT_2)
	if selected["kind"] == "rig":
		_button(0, "Leave in stash", sim.leave.bind(it["id"]), not sim.on_mission() and sim.stash_room(1))
	else:
		var room: bool = sim.rig_room(Items.size(it))
		_right_lines[2].text = "" if room else ("No rig fitted" if sim.med_capacity() == 0 else ("The rig is full" if Items.size(it) == 1 else "No room: it takes %d pouches" % Items.size(it)))
		_button(0, "Take", sim.take.bind(it["id"]), not sim.on_mission() and room)
		_button(1, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)


## What fitting the selection changes: [[delta, words], ...], the headline
## figure first, then each affix that differs.
func _deltas(it: Dictionary, fitted: Dictionary) -> Array:
	var out: Array = []
	var a := Items.headline(it)
	var b := Items.headline(fitted)
	var d := float(a[0]) - float(b[0])
	if absf(d) >= 0.5:
		out.append([d, "%.0f %s" % [absf(d), {"damage/s": "dmg/s", "armour": "arm", "capacity": "cap"}.get(a[1], a[1])]])
	for ax in Data.AFFIXES:
		var da := Items.affix_total(it, ax["stat"]) - Items.affix_total(fitted, ax["stat"])
		if absf(da) >= 0.5:
			out.append([da, "%.0f%s %s" % [absf(da), "%" if ax["stat"].ends_with("_pct") else "", ax["short"]]])
	return out


## The swap as chips - "▲ 9 dmg/s" green, "▼ 3 arm" red - flowed over the right
## column's last two lines, and one word for the whole thing by the slot's score.
func _show_swap(it: Dictionary, fitted: Dictionary) -> void:
	var deltas := _deltas(it, fitted)
	var x0 := PANEL_PAD * 2 + COL_W
	var x := x0
	var row := 0
	var shown := 0
	for d in deltas:
		if shown >= _chips.size():
			break
		var c := _chips[shown]
		var up: bool = d[0] > 0
		c.text = "%s %s" % ["▲" if up else "▼", d[1]]
		c.add_theme_color_override("font_color", Pal.GOOD if up else Pal.BAD)
		var w := ceilf(UI.text_width(c, c.text)) + 2
		if x + w > x0 + COL_W and x > x0:
			row += 1
			x = x0
		if row >= 2:
			break
		c.position = Vector2(x, 48 + (4 + row) * LINE_H)
		c.size = Vector2(w, LINE_H)
		c.visible = true
		x += w + 18
		shown += 1
	if deltas.is_empty():
		_right_lines[4].text = "No change"
	var gain := Items.score(it) - Items.score(fitted)
	if absf(gain) < 0.05:
		_overall.text = "Sidegrade for this slot"
		_overall.add_theme_color_override("font_color", Pal.WARN)
	elif gain > 0:
		_overall.text = "▲ Upgrade for this slot"
		_overall.add_theme_color_override("font_color", Pal.GOOD)
	else:
		_overall.text = "▼ Downgrade for this slot"
		_overall.add_theme_color_override("font_color", Pal.BAD)


func _button(i: int, text: String, action: Callable, enabled: bool) -> void:
	var b := _buttons[i]
	b.visible = true
	b.text = text
	b.disabled = not enabled
	b.size.x = ceilf(UI.text_width(b, text)) + 48
	_actions[i] = action


func _toggle(i: int) -> void:
	if i == 0:
		sim.auto_equip = not sim.auto_equip
	else:
		sim.auto_sell = not sim.auto_sell
	acted.emit()
	show_state(sim)


func _selected_item() -> Dictionary:
	if selected.is_empty() or sim == null:
		return {}
	if selected["kind"] == "slot":
		var it = sim.equipped[selected["slot"]]
		return it if it != null else {}
	if selected["kind"] == "rig":
		for it in sim.rig:
			if it["id"] == selected["id"]:
				return it
		return {}
	for it in sim.stash:
		if it["id"] == selected["id"]:
			return it
	return {}


# ------------------------------------------------------------------ acting

func _pick_slot(slot: String) -> void:
	selected = {"kind": "slot", "slot": slot}
	show_state(sim)


## A rig slot pressed.
func _on_rig_pick(id: int) -> void:
	selected = {"kind": "rig", "id": id}
	_inv.selected = -1
	show_state(sim)


## Drops: a stash item onto the rig takes it; a rig slot onto the stash leaves it.
func _on_take(id: int) -> void:
	if sim.take(id):
		selected = {"kind": "rig", "id": id}
	acted.emit()


func _on_leave(id: int) -> void:
	if sim.leave(id):
		selected = {"kind": "stash", "id": id}
	acted.emit()


func _on_stash_drop(data: Dictionary) -> void:
	if data.get("src", "") == "rig":
		_on_leave(int(data["id"]))
	elif data.get("src", "") == "body":
		var slot: String = data.get("slot", "")
		if sim.unequip(slot):
			selected = {"kind": "stash", "id": int(data["id"])}
		acted.emit()


## A stash item dropped on its slot's box.
func _on_equip_drop(id: int) -> void:
	for it in sim.stash:
		if it["id"] == id and sim.equip_item(id):
			selected = {"kind": "slot", "slot": it["slot"]}
			break
	acted.emit()


## The grid's pick: an id, or -1 when its bars changed or Select-many toggled.
func _on_inv_pick(id: int) -> void:
	if id >= 0:
		selected = {"kind": "stash", "id": id}
	elif _inv.many or (selected.get("kind", "") == "stash" and _selected_item().is_empty()):
		selected = {}
	show_state(sim)


func _on_inv_acted() -> void:
	if _selected_item().is_empty():
		selected = {}
	acted.emit()


## For the tests: the k-th cell on the grid's page.
func _pick_cell(k: int) -> void:
	_inv._pick(k)


func _press(i: int) -> void:
	var it := _selected_item()
	var was: Dictionary = selected.duplicate()
	if _actions[i].is_valid():
		_actions[i].call()
	# follow the item: equipped, it's now in its slot; unequipped, it's in the
	# stash under its id; sold, it's gone
	if was.get("kind", "") == "stash" and not it.is_empty() and (Items.is_medical(it) or Items.is_ammo(it)):
		selected = {}
		for k in range(sim.rig.size()):
			if sim.rig[k]["id"] == it["id"]:
				selected = {"kind": "rig", "id": it["id"]}
	elif was.get("kind", "") == "rig" and not it.is_empty():
		selected = {"kind": "stash", "id": it["id"]}
		if _selected_item().is_empty():
			selected = {}
	elif was.get("kind", "") == "stash" and not it.is_empty() and sim.equipped.has(it["slot"]) \
			and sim.equipped[it["slot"]] != null and sim.equipped[it["slot"]]["id"] == it["id"]:
		selected = {"kind": "slot", "slot": it["slot"]}
	elif was.get("kind", "") == "slot" and not it.is_empty():
		selected = {"kind": "stash", "id": it["id"]}
		if _selected_item().is_empty():
			selected = {}
	elif _selected_item().is_empty():
		selected = {}
	acted.emit()


## For the tests: every label with text.
func text_nodes() -> Array:
	var out: Array = [_left_title, _right_title, _hint, _overall]
	out.append_array(_words)
	out.append_array(_left_lines)
	out.append_array(_right_lines)
	for c in _chips:
		if c.visible:
			out.append(c)
	out.append_array(_containers.text_nodes())
	out.append_array(_body.text_nodes())
	out.append_array(_inv.text_nodes())
	for b in _buttons:
		if b.visible:
			out.append(b)
	for tb in _toggles:
		if tb.visible:
			out.append(tb)
	return out
