extends Control
## The search (board M, 10 Nov; Matt: "the inventory screen needs to be shown when searching crates ... Tarkov style it
## searches as you're in the inventory and then you drag and drop from the crate to the inventory", "with bodies being
## searchable as well as crates"). F at a crate or a body opens it over the fight, which goes on: what he wears on the
## left, what's in the crate top right, the pack as the bag's own grid under it, and the game's compare panel under
## that: a find pressed is shown against what's worn, a ▲ and "Potential upgrade" when it may be worth wearing (the
## bridge's potential_upgrade). Finds turn up one at a time (the world's
## search_tick); a find is dragged (or pressed) into the pack, or dragged straight onto its slot - no pack room needed,
## what he had on goes into the crate. F takes all there's room for. Moving off, Esc, Tab or Close shuts it; what's
## left stays in the crate. The pack is the game's own on the slice's mission: a piece lies where it fits.
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const T := preload("res://slice/tuning.gd")
const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const PickPanel := preload("res://scripts/ui/pick_panel.gd")

signal closed

## Every word the screen puts up (for the language pass).
const WORDS := {
	"crate": "The crate", "prize": "The prize", "body": "The body",
	"sub": "The fight goes on",
	"close": "Close", "take_all": "F · Take all",
	"crate_head": "IN IT", "body_head": "ON HIM", "pack_head": "THE PACK", "worn_head": "WORN",
	"searching": "%d of %d found · searching", "searched": "%d found · searched", "none_crate": "Nothing in it", "none_body": "Nothing on him", "looking": "Searching",
	"cells": "%d/%d cells",
	"full": "No room in the pack for that", "full_n": "No room in the pack for %d of them", "cant": "The runner can't wear that",
	"rig": "%d in the rig", "up": "Potential upgrade",
	"pick_none": "Pick a find", "pick_lines": ["Press one to see it against what's worn", "The ▲ marks a potential upgrade"],
	"in_crate": "In the crate", "on_body": "On him", "in_pack": "In the pack", "worn": "Worn now", "worn_none": "Nothing worn there",
	"take": "Take", "wear": "Wear", "leave": "Put back", "to_rig": "Into the rig",
}
const W := 1440.0
const H := 818.0
const RIGHT_X := 496.0
const RIGHT_W := 920.0
const PICK_H := 304                   # the game's compare panel, as the Kit has it
const SLOTS := [["Charm", 16, 56, 190, 90], ["Backpack", 16, 176, 190, 110], ["Primary", 16, 316, 190, 150], ["Secondary", 16, 496, 190, 150],
	["Helmet", 246, 56, 190, 100], ["Armour", 246, 186, 190, 130], ["Gloves", 246, 346, 190, 90], ["Rig", 246, 466, 190, 90], ["Boots", 246, 586, 190, 90]]
const SLOT_WORDS := {"Backpack": "PACK"}
const CRATE_CELL := 64.0
const CRATE_COLS := 12
const PACK_MAX_CELL := 44.0           # a pack cell's most; a big bag's cells shrink to PACK_MIN_CELL, then the grid scrolls
const PACK_MIN_CELL := 28.0
const PACK_GRID := Vector2(888.0, 150.0)
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
var _pack_scroll: ScrollContainer
var _pack_grid: Control               # the bag's grid: its squares and the pieces on them
var pick                             # the game's compare panel (pick_panel.gd)
var selected := {}                    # the piece picked: shown against what's worn
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
var pack_cell := 0.0                  # a pack cell's size as laid (a check's)


func _init() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE          # the fight shows round it; only the card takes the mouse
	process_mode = Node.PROCESS_MODE_ALWAYS
	_card = UI.panel(self, Rect2(0, 0, W, H), UI.box(Color(Pal.BG, 0.97), 10, 1, Pal.CARD_LINE))
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_title = UI.label(_card, Rect2(24, 12, 220, 40), "", "Bold", 26, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(_card, Rect2(250, 22, 300, 24), WORDS["sub"], "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_clock = UI.label(_card, Rect2(760, 20, 330, 26), "", "SemiBold", 15, Pal.BAD, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_hp = UI.label(_card, Rect2(1080, 20, 90, 26), "", "SemiBold", 15, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_hp_track = UI.panel(_card, Rect2(1180, 28, 110, 10), UI.box(Color(0, 0, 0, 0.6), 3, 0, Pal.CARD_LINE))
	_hp_fill = UI.panel(_hp_track, Rect2(0, 0, 110, 10), UI.box(Pal.GOOD, 3, 0, Pal.GOOD))
	close_button = UI.button(_card, Rect2(1302, 12, 118, 40), false)
	close_button.text = WORDS["close"]
	close_button.pressed.connect(close)
	_worn_panel = UI.panel(_card, Rect2(24, 62, 452, 732), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_worn_head = UI.head(_worn_panel, Rect2(16, 10, 200, 20), WORDS["worn_head"])
	for sl in SLOTS:
		var nm: String = str(sl[0])
		_slot_labels.append(UI.label(_worn_panel, Rect2(sl[1], sl[2] - 20.0, sl[3], 18), str(SLOT_WORDS.get(nm, nm.to_upper())), "SemiBold", 12, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
		var box := UI.panel(_worn_panel, Rect2(sl[1], sl[2], sl[3], sl[4]), UI.box(Color(Pal.BG, 0.8), 6, 1, Pal.CARD_LINE))
		box.mouse_filter = Control.MOUSE_FILTER_STOP
		box.set_drag_forwarding(Callable(), _can_drop.bind("slot:" + nm), _drop.bind("slot:" + nm))
		_slot_boxes[nm] = box
	_rig_label = UI.label(_worn_panel, Rect2(16, 688, 150, 22), "", "Regular", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_crate_panel = UI.panel(_card, Rect2(RIGHT_X, 62, RIGHT_W, 198), UI.box(Pal.PANEL, 8, 2, Pal.ACCENT))
	_crate_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_crate_panel.set_drag_forwarding(Callable(), _can_drop.bind("crate"), _drop.bind("crate"))
	_crate_head = UI.head(_crate_panel, Rect2(16, 10, 90, 20), WORDS["crate_head"])
	_crate_state = UI.label(_crate_panel, Rect2(110, 8, 400, 24), "", "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	take_button = UI.button(_crate_panel, Rect2(728, 6, 176, 34), false)
	take_button.text = WORDS["take_all"]
	take_button.pressed.connect(take_all)
	_pack_panel = UI.panel(_card, Rect2(RIGHT_X, 272, RIGHT_W, 206), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_pack_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_pack_panel.set_drag_forwarding(Callable(), _can_drop.bind("pack"), _drop.bind("pack"))
	_pack_head = UI.head(_pack_panel, Rect2(16, 10, 100, 20), WORDS["pack_head"])
	_pack_state = UI.label(_pack_panel, Rect2(120, 8, 300, 24), "", "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_note = UI.label(_pack_panel, Rect2(300, 8, 604, 24), "", "Regular", 14, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_pack_scroll = ScrollContainer.new()
	_pack_scroll.position = Vector2(16, 44)
	_pack_scroll.size = PACK_GRID
	_pack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pack_panel.add_child(_pack_scroll)
	_pack_grid = Control.new()
	_pack_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	_pack_grid.set_drag_forwarding(Callable(), _can_drop.bind("pack"), _drop.bind("pack"))
	_pack_scroll.add_child(_pack_grid)
	pick = PickPanel.new(int(RIGHT_W), PICK_H)
	pick.r69_no_verdict = false                    # this panel says "Potential upgrade" (the Kit's leave it to the dummy)
	pick.position = Vector2(RIGHT_X, 490)
	_card.add_child(pick)
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
	selected = {}
	_title.text = WORDS["body"] if thing.body else (WORDS["prize"] if thing.prize else WORDS["crate"])
	_crate_head.text = WORDS["body_head"] if thing.body else WORDS["crate_head"]
	if not world.runner_hurt.is_connected(_on_hurt):
		world.runner_hurt.connect(_on_hurt)
	if thing.body and thing.finds.is_empty():
		world._searched(thing)                    # (10 Nov, Matt) nothing on him: said at once, no cell, no wait
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
		_note.text = ""
		_note.add_theme_color_override("font_color", Pal.TEXT_3)
	take_button.disabled = thing.left.is_empty()
	var rig_meds: Array = s.rig.filter(func(x): return Items.is_medical(x))
	_rig_label.text = WORDS["rig"] % rig_meds.size()
	if not selected.is_empty() and not (thing.left.has(selected) or SliceBridge.pack_items(world.ctx).has(selected)):
		selected = {}                             # taken, worn or gone: nothing picked
	var sig := "%d|%s|%s|%s|%s|%s|%s" % [thing.found_n, str(thing.opened), str(selected.get("id", -1)), str(thing.left.map(func(x): return x.get("id"))), str(SliceBridge.pack_items(world.ctx).map(func(x): return [x.get("id"), x.get("pos"), x.get("rot")])),
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
		if SliceBridge.potential_upgrade(world.ctx, it):
			# the ▲: it may be worth wearing (the cell's own arrow is off game-wide since 0.15.3; this is the card's)
			var up := UI.label(c, Rect2(rect.size.x - 20.0, 2, 18, 18), "▲", "SemiBold", 11, Pal.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
			up.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			up.add_theme_stylebox_override("normal", UI.box(Color(Pal.BG, 0.85), 9, 1, Pal.GOOD))
			up.mouse_filter = Control.MOUSE_FILTER_IGNORE
			up.name = "Up"
		c.set_drag_forwarding(_drag.bind(it, from), _can_drop.bind(from), _drop.bind(from))
		c.pressed.connect(func() -> void: select(it))
	else:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cells.append(c)
	return c


func _blank(parent: Control, rect: Rect2, kind: String) -> void:
	var lit: bool = kind == "now" or (kind == "dark" and thing.body)     # (10 Nov, Matt) a body with something on it: its cells lit while it's searched
	var p := UI.panel(parent, rect, UI.box(Color(Pal.BG, 0.9 if kind != "now" else 0.6), 5, 2 if lit else 1, Pal.ACCENT if lit else Pal.CARD_LINE))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "dark":
		UI.label(p, Rect2(0, rect.size.y / 2.0 - 14.0, rect.size.x, 28), "?", "Bold", 18, Pal.ACCENT if lit else Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
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
		_cell(_worn_panel, rig_meds[k], Rect2(170.0 + k * 46.0, 680.0, 40, 40), "")
	# the crate: a cell a find, in the order found - taken ones stand empty; what he put in after them
	var k := 0
	for i in range(thing.finds.size()):
		var at := Rect2(16.0 + (k % CRATE_COLS) * (CRATE_CELL + 8.0), 46.0 + floorf(float(k) / CRATE_COLS) * (CRATE_CELL + 8.0), CRATE_CELL, CRATE_CELL)
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
		_cell(_crate_panel, it, Rect2(16.0 + (k % CRATE_COLS) * (CRATE_CELL + 8.0), 46.0 + floorf(float(k) / CRATE_COLS) * (CRATE_CELL + 8.0), CRATE_CELL, CRATE_CELL), "crate")
		k += 1
	# the pack: the bag's own shape, a square a cell, each piece where it lies
	var pw: int = int(s.pack_w())
	var rows: int = int(s.pack_rows())
	var cap: int = int(s.capacity())
	var gap := 4.0
	var cs: float = floorf(clampf(minf((PACK_GRID.x - 12.0 - (pw - 1) * gap) / pw, (PACK_GRID.y - (rows - 1) * gap) / maxf(1.0, rows)), PACK_MIN_CELL, PACK_MAX_CELL))
	pack_cell = cs
	for y in range(rows):
		for x in range(pw):
			if y * pw + x < cap:
				_blank(_pack_grid, Rect2(x * (cs + gap), y * (cs + gap), cs, cs), "empty")
	var loose := 0                                # a piece with no place (a smaller bag put on): in a row under the grid, to wear or put back
	for it in SliceBridge.pack_items(world.ctx):
		if not (it.get("pos") is Array):
			_cell(_pack_grid, it, Rect2(loose * (cs + gap), rows * (cs + gap) + 6.0, cs, cs), "pack")
			loose += 1
			continue
		var fp: Vector2i = Items.footprint(it)
		if bool(it.get("rot", false)):
			fp = Vector2i(fp.y, fp.x)
		_cell(_pack_grid, it, Rect2(float(it["pos"][0]) * (cs + gap), float(it["pos"][1]) * (cs + gap), fp.x * cs + (fp.x - 1) * gap, fp.y * cs + (fp.y - 1) * gap), "pack")
	_pack_grid.custom_minimum_size = Vector2(pw * (cs + gap), rows * (cs + gap) + (cs + 10.0 if loose > 0 else 0.0))
	_show_pick(s)


## The piece picked against what's worn in its slot (the game's compare panel), and what can be done with it.
func _show_pick(s) -> void:
	if selected.is_empty():
		pick.show_empty(WORDS["pick_none"], WORDS["pick_lines"])
		pick.set_verdict("", "", [])
		pick.set_buttons([])
		return
	var in_crate: bool = thing.left.has(selected)
	var held = s.mission
	s.mission = null                              # the panel reads the piece as the Kit does, not "out on a run"
	pick.show_pick(selected, s, WORDS["in_pack"] if not in_crate else (WORDS["on_body"] if thing.body else WORDS["in_crate"]))
	var slot: String = str(selected.get("slot", ""))
	var worn = s.equipped.get(slot) if s.equipped.has(slot) else null
	if worn != null:
		pick.show_fitted(worn, s, WORDS["worn"])
	elif s.equipped.has(slot):
		pick.show_right_words(WORDS["worn"], WORDS["worn_none"], [])
	s.mission = held
	var up: bool = SliceBridge.potential_upgrade(world.ctx, selected)
	pick.set_verdict(WORDS["up"] if up else "", "good" if up else "", [])
	var it: Dictionary = selected
	var buttons: Array = []
	if s.equipped.has(slot):
		buttons.append({"text": WORDS["wear"], "action": func() -> void: wear(it), "enabled": bool(s.can_wear(it)), "primary": up, "tone": ""})
	if Items.is_medical(it):
		buttons.append({"text": WORDS["to_rig"], "action": func() -> void: to_rig(it), "enabled": true, "primary": false, "tone": ""})
	if in_crate:
		buttons.append({"text": WORDS["take"], "action": func() -> void: take(it), "enabled": true, "primary": not up, "tone": ""})
	else:
		buttons.append({"text": WORDS["leave"], "action": func() -> void: leave(it), "enabled": true, "primary": false, "tone": ""})
	pick.set_buttons(buttons)


## A find or a pack's piece pressed: picked, shown against what's worn.
func select(it: Dictionary) -> void:
	selected = it
	_shown = ""


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
	var ok := false
	if from_crate:
		ok = world.wear_find(thing, it)
	else:
		var got: Dictionary = SliceBridge.wear_from(world.ctx, it)
		ok = bool(got["ok"])
		thing.left.append_array(got["off"])       # (the review) what came off and found no place in the pack: into the crate, not lost
		for x in got["off"]:
			world.stats["haul"].erase(x)
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
	return [_title, _sub, _clock, _hp, close_button, take_button, _crate_head, _crate_state, _pack_head, _pack_state, _worn_head, _rig_label, _note] + _slot_labels + pick.text_nodes()


func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size)
