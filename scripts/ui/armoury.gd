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
const PickPanel := preload("res://scripts/ui/pick_panel.gd")

const BODY_W := Body.WIDTH                                    # 420
const CONTAINERS_Y := Body.HEIGHT + 8                         # 568: the body, then the rig and the pack (to 864)
const GAP := 24
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH                                # 904
const GRID_H := Inventory.HEIGHT                               # 588
const PANEL_Y := GRID_H + GAP                                 # 612
const PANEL_H := Pal.ROOM_H - PANEL_Y                         # 304
const PANEL_PAD := 20
const PANEL_LINES := 6             # figure, what it takes, three affixes with their tiers, the swap word
const LINE_H := 26
const COL_W := (GRID_W - 3 * PANEL_PAD) / 2                   # each half of the compare panel

var sim
var selected := {}                 # {"kind": "stash", "id": n} or {"kind": "slot", "slot": s}, or {}
var _body                          # the slots as boxes to drop on
var _inv                           # the stash grid
var _containers                    # the rig and the pack
var _pick                          # the pick panel (pick_panel.gd): the pick against the fitted, the buttons
var _actions: Array = []           # what the panel's buttons do, by index; _press follows the item after
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
	_pick = PickPanel.new(GRID_W, PANEL_H)
	_pick.position = Vector2(GRID_X, PANEL_Y)
	add_child(_pick)
	for i in range(PickPanel.BUTTONS):
		_actions.append(Callable())


## For the tests: the panel's buttons, and the idle toggles (the same buttons, with nothing picked).
var _buttons: Array:
	get:
		return _pick._buttons
var _toggles: Array:
	get:
		return [_pick._buttons[0], _pick._buttons[1]]
var _head:
	get:
		return _pick._heads[0]


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
	return Pal.rarity_tone(int(it["rarity"]))


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


## The compare panel (Pick-A): the pick on the left, what's fitted in its slot
## on the right laid the same, the verdict and the deltas at the foot, the
## buttons for what can be done with it. Sell is the fence's.
func _show_panel() -> void:
	var it := _selected_item()
	if it.is_empty():
		_pick.show_empty("Select an item", ["A slot on the left, or a stash item on the right"])
		# the idle toggles live where the buttons would be
		_pick.set_buttons([
			{"text": "Equip if better ✓" if sim.auto_equip else "Equip if better", "action": _toggle.bind(0), "enabled": true, "primary": false, "tone": "good" if sim.auto_equip else ""},
			{"text": "Sell the junk on return ✓" if sim.auto_sell else "Sell the junk on return", "action": _toggle.bind(1), "enabled": true, "primary": false, "tone": "good" if sim.auto_sell else ""}])
		return
	var buttons := []
	var tail = ""
	var extra = ""
	if Items.is_gun(it):
		tail = [Items.fitted_words(it), _rounds_clause(it)]
	elif Items.is_attachment(it) and not Items.is_socketable(it):
		tail = Items.att_words(it, true, true)
	elif Items.is_ammo(it):
		tail = "feeds %s" % ("the " + Items.base_of(it)["type"] if Items.base_of(it)["type"] != "smg" else "the SMG")
	elif Items.is_paper(it):
		tail = "from before" if not Items.is_deeds(it) else "what the bank was holding"
	if it.has("set"):
		# the set: whose, how many worn, what the next piece brings
		var st: Dictionary = Items.set_named(it["set"])
		var n: int = sim.set_count(it["set"])
		var next_words := ""
		for k in st["bonuses"]:
			if int(k) > n and next_words == "":
				next_words = st["bonuses"][k]["words"]
		var line: String = "%s · %d of %d worn" % [it["set"], n, st["pieces"].size()]
		extra = [("%s · next: %s" % [line, next_words.to_lower()]) if next_words != "" else "%s · the full set" % line, line, "%d of %d worn" % [n, st["pieces"].size()]]
	var where: String = {"stash": "in the stash", "rig": "in the rig", "slot": "fitted"}.get(selected["kind"], "")
	_pick.show_pick(it, sim, "The pick · " + where, tail, extra)
	if Items.rig_item(it):
		buttons = _show_medical(it)
	elif Items.is_paper(it):
		_pick.show_right_words("The drawer" if not Items.is_deeds(it) else "The deeds", "Held, sold or burned: the ending" if Items.is_deeds(it) else ("In the caravan's drawer" if it["base"] in sim.book else "Not read yet"),
			["Read, and kept" if (it["base"] in sim.book and not Items.is_deeds(it)) else "", "The fence buys papers"])
	elif Items.is_attachment(it):
		if Items.is_socketable(it):
			_pick.show_right_words("The bench", "Fitted at the bench", [["Sockets view: into any socket", "Into any socket"], Items.socket_words(it).get_slice(": ", 1)])
		else:
			_pick.show_right_words("The bench", "Fitted at the bench", ["Goes on %s" % Items.mount_words(it["mount"])])
		if sim.workshop >= 1:
			buttons.append({"text": "Bench", "action": func(): bench.emit(it["id"]), "enabled": not sim.on_mission(), "primary": true})
	else:
		var fitted = sim.equipped[it["slot"]]
		var from_stash: bool = selected["kind"] == "stash"
		if from_stash:
			if fitted == null:
				_pick.show_right_words("Fitted now", "Nothing fitted as %s" % it["slot"].to_lower(), ["Equipping adds everything at the left"])
			else:
				var ftail = ""
				if Items.is_gun(fitted):
					ftail = [Items.fitted_words(fitted), _rounds_clause(fitted)]
				_pick.show_fitted(fitted, sim, "Fitted now", ftail)
				var v: Array = PickPanel.verdict_of(it, fitted)
				_pick.set_verdict(v[0], v[1], PickPanel.deltas_of(it, fitted))
			buttons.append({"text": "Equip", "action": sim.equip_item.bind(it["id"]), "enabled": sim.can_equip_item(it["id"]), "primary": true})
			if not sim.can_equip_item(it["id"]) and not sim.on_mission():
				_pick.set_hint("No room in the stash for what comes off")
			if sim.workshop >= 1 and not it.has("unique"):
				buttons.append({"text": "Bench", "action": func(): bench.emit(it["id"]), "enabled": not sim.on_mission(), "primary": false})
		else:
			# fitted: a gun's parts, each with its figures, at the right; the stash's room under
			var lines := []
			for mount in it.get("attachments", {}):
				var a = it["attachments"][mount]
				if a == null or lines.size() >= 3:
					continue
				var figures: String = Items.att_words(a, true) if not Items.is_socketable(a) else Items.socket_words(a).get_slice(": ", 1)
				lines.append(["%s · %s" % [a["base"], figures], a["base"]])
			lines.append("Stash has %d of %d cells" % [sim.stash_used(), sim.stash_cap()])
			_pick.show_right_words("On the runner", "Fitted" if lines.size() > 1 else "Fitted, nothing on it", lines)
			buttons.append({"text": "Unequip", "action": sim.unequip.bind(it["slot"]), "enabled": not sim.on_mission() and sim.stash_room(Items.size(it)), "primary": true})
			if sim.workshop >= 1 and not it.has("unique"):
				buttons.append({"text": "Bench", "action": func(): bench.emit(it["id"]), "enabled": not sim.on_mission(), "primary": false})
	_set_buttons(buttons)


## The panel's buttons, each through _press so the selection follows the item after.
func _set_buttons(buttons: Array) -> void:
	var items := []
	for i in range(buttons.size()):
		_actions[i] = buttons[i]["action"]
		var d: Dictionary = buttons[i].duplicate()
		d["action"] = _press.bind(i)
		items.append(d)
	_pick.set_buttons(items)


## "takes SMG rounds, 600 in the rig", shorter forms after it.
func _rounds_clause(gun: Dictionary) -> Array:
	var takes: String = Items.ammo_words(gun).to_lower().replace("smg", "SMG")
	var n: int = sim.rounds_for(gun)
	if Items.ammo_type(gun) == "":
		return [takes]
	return ["%s, %d in the rig" % [takes, n], "%s, %d" % [takes, n], takes]


## A med or rounds: the rig on the right; Take into it, or Leave it in the stash. Returns the buttons.
func _show_medical(it: Dictionary) -> Array:
	var lines := [("Fired by the %s" % Items.base_of(it)["type"]) if Items.is_ammo(it) else ("Thrown at everyone on you" if Items.is_grenade(it) else "Used under fire, over a few seconds")]
	if Items.is_ammo(it):
		var gun = sim.equipped["Primary"]
		var sec = sim.equipped["Secondary"]
		var feeds := []
		for g in [gun, sec]:
			if g != null and Items.ammo_type(g) == Items.base_of(it)["type"]:
				feeds.append(g["base"])
		lines[0] = ("Feeds the %s" % " and the ".join(feeds).to_lower()) if not feeds.is_empty() else "Nothing fitted fires it"
	var buttons := []
	if selected["kind"] == "rig":
		buttons.append({"text": "Leave in stash", "action": sim.leave.bind(it["id"]), "enabled": not sim.on_mission() and sim.stash_room(1), "primary": true})
	else:
		var room: bool = sim.rig_room(Items.size(it))
		if not room:
			lines.append("No rig fitted" if sim.med_capacity() == 0 else ("The rig is full" if Items.size(it) == 1 else "No room: it takes %d pouches" % Items.size(it)))
		buttons.append({"text": "Take", "action": sim.take.bind(it["id"]), "enabled": not sim.on_mission() and room, "primary": true})
	_pick.show_right_words("The rig", "%d of %d pouches filled" % [sim.rig_used(), sim.med_capacity()], lines)
	return buttons


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
	if was.get("kind", "") == "stash" and not it.is_empty() and Items.rig_item(it):
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
		if sim.equipped.get(it["slot"], null) != null and sim.equipped[it["slot"]]["id"] == it["id"]:
			selected = was                   # still fitted (the bench, say): the slot stays picked
		else:
			selected = {"kind": "stash", "id": it["id"]}
			if _selected_item().is_empty():
				selected = {}
	elif _selected_item().is_empty():
		selected = {}
	acted.emit()


## For the tests: every label with text.
func line_pairs() -> Array:
	return _pick.line_pairs()


func text_nodes() -> Array:
	var out: Array = _pick.text_nodes()
	out.append_array(_containers.text_nodes())
	out.append_array(_body.text_nodes())
	out.append_array(_inv.text_nodes())
	return out
