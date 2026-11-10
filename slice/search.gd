extends Control
## The search (board M, 10 Nov; Matt: "the inventory screen needs to be shown when searching crates ... Tarkov style it
## searches as you're in the inventory and then you drag and drop from the crate to the inventory", "with bodies being
## searchable as well as crates"). F at a crate or a body opens it over the fight, which goes on: what he wears on the
## left, the crate where the Kit's stash sits, the pack under it. Finds turn up one at a time (the world's
## search_tick); a find is dragged (or pressed) into the pack, or dragged straight onto its slot - no pack room needed,
## what he had on goes into the crate. F takes all there's room for. Moving off, Esc, Tab or Close shuts it; what's
## left stays in the crate. The pack is the slice's stash counted in the bag's cells (the bridge's pack_used).
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const T := preload("res://slice/tuning.gd")
const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")

signal closed

## Every word the screen puts up (for the language pass).
const WORDS := {
	"crate": "The crate", "prize": "The prize", "body": "The body",
	"sub": "The fight goes on",
	"close": "Close", "take_all": "F · Take all",
	"crate_head": "IN IT", "body_head": "ON HIM", "pack_head": "THE PACK", "worn_head": "WORN",
	"searching": "%d of %d found · searching", "searched": "%d found · searched", "none_crate": "Nothing in it", "none_body": "Nothing on him", "looking": "Searching",
	"cells": "%d/%d cells",
	"hint": "Drag a find to the pack, or onto its slot. What the runner had on takes its place.",
	"full": "No room in the pack for that", "full_n": "No room in the pack for %d of them", "cant": "The runner can't wear that",
	"more": "And %d more", "rig": "%d in the rig",
}
const W := 1240.0
const H := 600.0
const SLOTS := [["Charm", 16, 92, 150, 58], ["Backpack", 16, 176, 150, 64], ["Primary", 16, 266, 150, 90], ["Secondary", 16, 382, 150, 80],
	["Helmet", 302, 92, 134, 58], ["Armour", 302, 180, 134, 70], ["Gloves", 302, 280, 134, 58], ["Rig", 302, 368, 134, 58], ["Boots", 302, 456, 134, 58]]
const SLOT_WORDS := {"Backpack": "PACK"}
const CRATE_CELL := 88.0
const CRATE_COLS := 7
const PACK_CELL := 78.0
const PACK_COLS := 8
const PACK_SHOWN := 15                # the pack's pieces drawn; past that, "And N more"
const MOVE_OFF_PX := 46.0             # he's walked this far from where he opened it: it shuts

var world = null
var hud = null
var thing = null                      # the crate or the body (slice/crate.gd)
var _card: Panel
var _title: Label
var _sub: Label
var _clock: Label
var _hp: Label
var _hp_track: Panel
var _hp_fill: Panel
var close_button: Button
var take_button: Button
var _crate_panel: Panel
var _pack_panel: Panel
var _worn_panel: Panel
var _crate_head: Label
var _crate_state: Label
var _pack_head: Label
var _pack_state: Label
var _worn_head: Label
var _rig_label: Label
var _more: Label
var _note: Label
var _slot_labels: Array = []
var _slot_boxes := {}                 # slot -> the drop target
var _cells: Array = []                # what's laid on the three panels now, rebuilt when it changes
var _shown := ""
var _note_t := 0.0
var _flash_t := 0.0
var _at := Vector2.ZERO
var _open_t := 0.0
var _flashing := false
var _now_bar: Panel = null            # the bar on the find being turned up
var _now_w := 0.0


func _init() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE          # the fight shows round it; only the card takes the mouse
	process_mode = Node.PROCESS_MODE_ALWAYS
	_card = UI.panel(self, Rect2(0, 0, W, H), UI.box(Color(Pal.BG, 0.97), 10, 1, Pal.CARD_LINE))
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_title = UI.label(_card, Rect2(24, 12, 220, 40), "", "Bold", 26, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(_card, Rect2(250, 22, 300, 24), WORDS["sub"], "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_clock = UI.label(_card, Rect2(560, 20, 330, 26), "", "SemiBold", 15, Pal.BAD, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_hp = UI.label(_card, Rect2(880, 20, 90, 26), "", "SemiBold", 15, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_hp_track = UI.panel(_card, Rect2(980, 28, 110, 10), UI.box(Color(0, 0, 0, 0.6), 3, 0, Pal.CARD_LINE))
	_hp_fill = UI.panel(_hp_track, Rect2(0, 0, 110, 10), UI.box(Pal.GOOD, 3, 0, Pal.GOOD))
	close_button = UI.button(_card, Rect2(1102, 12, 118, 40), false)
	close_button.text = WORDS["close"]
	close_button.pressed.connect(close)
	_worn_panel = UI.panel(_card, Rect2(24, 62, 452, 514), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_worn_head = UI.head(_worn_panel, Rect2(16, 10, 200, 20), WORDS["worn_head"])
	for sl in SLOTS:
		var nm: String = str(sl[0])
		_slot_labels.append(UI.label(_worn_panel, Rect2(sl[1], sl[2] - 20.0, sl[3], 18), str(SLOT_WORDS.get(nm, nm.to_upper())), "SemiBold", 12, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
		var box := UI.panel(_worn_panel, Rect2(sl[1], sl[2], sl[3], sl[4]), UI.box(Color(Pal.BG, 0.8), 6, 1, Pal.CARD_LINE))
		box.mouse_filter = Control.MOUSE_FILTER_STOP
		box.set_drag_forwarding(Callable(), _can_drop.bind("slot:" + nm), _drop.bind("slot:" + nm))
		_slot_boxes[nm] = box
	_rig_label = UI.label(_worn_panel, Rect2(16, 478, 130, 22), "", "Regular", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_crate_panel = UI.panel(_card, Rect2(496, 62, 720, 250), UI.box(Pal.PANEL, 8, 2, Pal.ACCENT))
	_crate_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_crate_panel.set_drag_forwarding(Callable(), _can_drop.bind("crate"), _drop.bind("crate"))
	_crate_head = UI.head(_crate_panel, Rect2(16, 10, 90, 20), WORDS["crate_head"])
	_crate_state = UI.label(_crate_panel, Rect2(110, 8, 400, 24), "", "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	take_button = UI.button(_crate_panel, Rect2(528, 6, 176, 34), false)
	take_button.text = WORDS["take_all"]
	take_button.pressed.connect(take_all)
	_pack_panel = UI.panel(_card, Rect2(496, 326, 720, 250), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_pack_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_pack_panel.set_drag_forwarding(Callable(), _can_drop.bind("pack"), _drop.bind("pack"))
	_pack_head = UI.head(_pack_panel, Rect2(16, 10, 100, 20), WORDS["pack_head"])
	_pack_state = UI.label(_pack_panel, Rect2(120, 8, 300, 24), "", "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_more = UI.label(_pack_panel, Rect2(600, 8, 104, 24), "", "Regular", 14, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_note = UI.label(_pack_panel, Rect2(16, 216, 688, 22), "", "Regular", 14, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	visible = false


func layout(s: Vector2) -> void:
	size = s
	_card.position = Vector2(roundf((s.x - W) / 2.0), roundf(maxf(8.0, (s.y - T.HUD_BAND_H - H) / 2.0)))     # over the play, clear of the band


func open(w, hud_v, thing_v) -> void:
	world = w
	hud = hud_v
	thing = thing_v
	world.roll_crate(thing)
	world.search_thing = thing
	world.runner.hands_full = true
	_at = world.runner.position
	_open_t = 0.0
	_shown = ""
	_note_t = 0.0
	_title.text = WORDS["body"] if thing.body else (WORDS["prize"] if thing.prize else WORDS["crate"])
	_crate_head.text = WORDS["body_head"] if thing.body else WORDS["crate_head"]
	if not world.runner_hurt.is_connected(_on_hurt):
		world.runner_hurt.connect(_on_hurt)
	visible = true
	layout(get_viewport_rect().size if is_inside_tree() else size)
	refresh()


func close() -> void:
	if not visible:
		return
	visible = false
	if world != null and is_instance_valid(world):
		world.search_thing = null
		if world.runner != null:
			world.runner.hands_full = false
	_clear_cells()
	closed.emit()


func _on_hurt(_res) -> void:
	_flash_t = 0.25


func _process(dt: float) -> void:
	if not visible or world == null or not is_instance_valid(world):
		return
	_open_t += dt
	_note_t = maxf(0.0, _note_t - dt)
	_flash_t = maxf(0.0, _flash_t - dt)
	var r = world.runner
	if world.ended or r.is_dead() or not is_instance_valid(thing) or r.position.distance_to(_at) > MOVE_OFF_PX:
		close()
		return
	refresh()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("slice_use") and _open_t > 0.15:
		take_all()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


## The words and the cells as things stand; the cells are laid again only when something moved.
func refresh() -> void:
	var s = world.ctx["sim"]
	var r = world.runner
	var n: int = thing.finds.size()
	if not thing.opened:
		_crate_state.text = UI.dots(WORDS["searching"] % [thing.found_n, n]) if n > 0 else WORDS["looking"]
	elif n == 0:
		_crate_state.text = WORDS["none_body"] if thing.body else WORDS["none_crate"]
	else:
		_crate_state.text = UI.dots(WORDS["searched"] % n)
	_pack_state.text = WORDS["cells"] % [SliceBridge.pack_used(world.ctx), SliceBridge.pack_cap(world.ctx)]
	_hp.text = "%d / %d" % [int(r.hp), int(r.hp_max)]
	_hp_fill.size.x = _hp_track.size.x * clampf(float(r.hp) / maxf(1.0, float(r.hp_max)), 0.0, 1.0)
	_clock.text = str(hud._site_clock.text) if hud != null and is_instance_valid(hud) and hud.get("_site_clock") != null else ""
	if (_flash_t > 0.0) != _flashing:
		_flashing = _flash_t > 0.0
		_card.add_theme_stylebox_override("panel", UI.box(Color(Pal.BG, 0.97), 10, 3 if _flashing else 1, Pal.BAD if _flashing else Pal.CARD_LINE))
	if _now_bar != null and is_instance_valid(_now_bar) and n > 0:
		_now_bar.size.x = _now_w * clampf(thing.progress * n - thing.found_n, 0.0, 1.0)     # the find being turned up: its bar, without laying the cells again
	if _note_t <= 0.0:
		_note.text = WORDS["hint"]
		_note.add_theme_color_override("font_color", Pal.TEXT_3)
	take_button.disabled = thing.left.is_empty()
	var rig_meds: Array = s.rig.filter(func(x): return Items.is_medical(x))
	_rig_label.text = WORDS["rig"] % rig_meds.size()
	var sig := "%d|%s|%s|%s|%s|%s" % [thing.found_n, str(thing.opened), str(thing.left.map(func(x): return x.get("id"))), str(s.stash.map(func(x): return x.get("id"))),
		str(SLOTS.map(func(sl): return s.equipped[sl[0]].get("id") if s.equipped.get(sl[0]) != null else -1)), str(rig_meds.size())]
	if sig == _shown:
		return
	_shown = sig
	_lay(s, rig_meds)


func _clear_cells() -> void:
	for c in _cells:
		if is_instance_valid(c):
			c.get_parent().remove_child(c)
			c.queue_free()
	_cells.clear()


func _cell(parent: Control, it: Dictionary, rect: Rect2, from: String) -> ItemCell:
	var c: ItemCell = ItemCell.new()
	parent.add_child(c)
	c.position = rect.position
	c.show_item(it, false, rect.size)
	c.tooltip_text = Items.full_name(it)
	if from != "":
		c.set_drag_forwarding(_drag.bind(it, from), _can_drop.bind(from), _drop.bind(from))
		if from == "crate":
			c.pressed.connect(func() -> void: take(it))
	else:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cells.append(c)
	return c


func _blank(parent: Control, rect: Rect2, kind: String) -> void:
	var p := UI.panel(parent, rect, UI.box(Color(Pal.BG, 0.9 if kind != "now" else 0.6), 5, 2 if kind == "now" else 1, Pal.ACCENT if kind == "now" else Pal.CARD_LINE))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "dark":
		UI.label(p, Rect2(0, rect.size.y / 2.0 - 14.0, rect.size.x, 28), "?", "Bold", 18, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
	elif kind == "now":
		_now_w = rect.size.x - 16.0
		_now_bar = UI.panel(p, Rect2(8, rect.size.y - 14.0, 0, 6), UI.box(Pal.ACCENT, 2, 0, Pal.ACCENT))
	_cells.append(p)


func _lay(s, rig_meds: Array) -> void:
	_clear_cells()
	# what he wears
	for sl in SLOTS:
		var it = s.equipped.get(sl[0])
		if it != null:
			_cell(_slot_boxes[sl[0]], it, Rect2(2, 2, float(sl[3]) - 4.0, float(sl[4]) - 4.0), "")
	for k in range(mini(rig_meds.size(), 3)):
		_cell(_worn_panel, rig_meds[k], Rect2(170.0 + k * 42.0, 470.0, 36, 36), "")
	# the crate: a cell a find, in the order found - taken ones stand empty; what he put in after them
	var k := 0
	for i in range(thing.finds.size()):
		var at := Rect2(16.0 + (k % CRATE_COLS) * (CRATE_CELL + 8.0), 50.0 + floorf(float(k) / CRATE_COLS) * (CRATE_CELL + 8.0), CRATE_CELL, CRATE_CELL)
		k += 1
		if k > CRATE_COLS * 2:
			break
		if i < thing.found_n:
			if thing.left.has(thing.finds[i]):
				_cell(_crate_panel, thing.finds[i], at, "crate")
			else:
				_blank(_crate_panel, at, "empty")
		else:
			_blank(_crate_panel, at, "now" if i == thing.found_n and not thing.opened else "dark")
	for it in thing.left:
		if thing.finds.has(it) or k >= CRATE_COLS * 2:
			continue
		_cell(_crate_panel, it, Rect2(16.0 + (k % CRATE_COLS) * (CRATE_CELL + 8.0), 50.0 + floorf(float(k) / CRATE_COLS) * (CRATE_CELL + 8.0), CRATE_CELL, CRATE_CELL), "crate")
		k += 1
	# the pack: a cell a piece, the newest first
	var held: Array = SliceBridge.pack_items(world.ctx)
	held.reverse()
	for j in range(mini(held.size(), PACK_SHOWN)):
		_cell(_pack_panel, held[j], Rect2(16.0 + (j % PACK_COLS) * (PACK_CELL + 8.0), 44.0 + floorf(float(j) / PACK_COLS) * (PACK_CELL + 8.0), PACK_CELL, PACK_CELL), "pack")
	_more.text = WORDS["more"] % (held.size() - PACK_SHOWN) if held.size() > PACK_SHOWN else ""


func say(key: String, n := 0) -> void:
	_note.text = WORDS[key] % n if key == "full_n" else WORDS[key]
	_note.add_theme_color_override("font_color", Pal.BAD)
	_note_t = 2.5


# ---------------------------------------------------------------- what the hands do
func take(it: Dictionary) -> bool:
	if not world.take_find(thing, it):
		say("full")
		return false
	return true


func take_all() -> void:
	var n: int = world.take_all(thing)
	if n == 1:
		say("full")
	elif n > 1:
		say("full_n", n)


## A find or a pack's piece onto its slot.
func wear(it: Dictionary) -> bool:
	var from_crate: bool = thing.left.has(it)
	var ok: bool = world.wear_find(thing, it) if from_crate else bool(SliceBridge.wear_from(world.ctx, it)["ok"])
	if ok and not from_crate:
		world.runner.kit_changed(world.ctx)       # (from the crate the world's wear_find has done it)
	elif not ok:
		say("cant")
	return ok


func leave(it: Dictionary) -> bool:
	return world.leave_find(thing, it)


func to_rig(it: Dictionary) -> bool:
	var from_crate: bool = thing.left.has(it)
	if not SliceBridge.rig_from(world.ctx, it):
		say("cant")
		return false
	if from_crate:
		thing.left.erase(it)
		world.stats["haul"].append(it)
	world.runner.kit_changed(world.ctx)
	return true


func _drag(_at_v: Vector2, it: Dictionary, from: String) -> Variant:
	var ghost: ItemCell = ItemCell.new()
	ghost.show_item(it, true, Vector2(64, 64))
	ghost.modulate.a = 0.85
	set_drag_preview(ghost)
	return {"slice_find": it, "from": from}


func _can_drop(_at_v: Vector2, data: Variant, to: String) -> bool:
	if not (data is Dictionary) or not data.has("slice_find"):
		return false
	var it: Dictionary = data["slice_find"]
	if to == "pack":
		return str(data["from"]) == "crate"
	if to == "crate":
		return str(data["from"]) == "pack"
	if to == "slot:Rig" and Items.is_medical(it):
		return true
	return to == "slot:" + str(it.get("slot", ""))


func _drop(_at_v: Vector2, data: Variant, to: String) -> void:
	var it: Dictionary = data["slice_find"]
	if to == "pack":
		take(it)
	elif to == "crate":
		leave(it)
	elif to == "slot:Rig" and Items.is_medical(it):
		to_rig(it)
	else:
		wear(it)
	_shown = ""


func text_nodes() -> Array:
	return [_title, _sub, _clock, _hp, close_button, take_button, _crate_head, _crate_state, _pack_head, _pack_state, _worn_head, _rig_label, _more, _note] + _slot_labels


func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size)
