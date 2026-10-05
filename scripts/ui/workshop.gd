extends Control
## The Workshop's screen: the fitted guns and their mounts down the left, the
## stash's attachments for the selected mount as a grid on the right, and a
## compare panel under the grid with Fit, Strip and Sell. The Workshop's own
## level - which mounts the bench can work on - is bought here too; it's the
## camp's cash sink. The Armoury's shape, so it reads the same way.
## Two views of the left column: Guns (the five mounts of each gun) and
## Sockets (the sockets of the guns, the helmet and the armour, and the
## socketables that go in them). The grid follows the view.

signal acted
signal bench(id)                   # the bench's menu for an item, from the Craft view

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const HEAD_H := 64
const ROW_H := 46
const ROW_GAP := 6
const VIEW_H := 36                 # the Guns / Sockets toggle across the top
const SOCK_HEAD_H := 44
const BENCH_H := 136               # title, words, a gap, the upgrade button
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH
const GRID_H := Inventory.HEIGHT
const PANEL_Y := GRID_H + GAP
const PANEL_H := Pal.ROOM_H - PANEL_Y
const PAD := 20
const COL_W := (GRID_W - 3 * PAD) / 2
const GUNS := ["Primary", "Secondary"]
const ROWS_A_GUN := 5              # the most mounts a gun has

var sim
var view := "guns"                 # "guns" or "sockets"
var _views: Array[Button] = []
var _craft: Panel
var _craft_title: Label
var _craft_lines: Array[Label] = []
const CRAFT_LINES := 9
var _socks := {}                   # slot -> {head, label, name, rows: {mount -> {button, mount, fitted}}}
var sel_slot := ""                 # the gun slot whose mount is selected
var sel_mount := ""
var sel_id := -1                   # a stash attachment selected, or -1
var _guns := {}                    # slot -> {head, name, figure, rows: {mount -> {button, mount, fitted}}}
var _inv
var _bench: Panel
var _bench_title: Label
var _bench_words: Label
var _upgrade: Button
var _panel: Panel
var _left_title: Label
var _left_lines: Array[Label] = []
var _right_title: Label
var _right_lines: Array[Label] = []
var _buttons: Array[Button] = []
var _actions: Array = []
var _hint: Label
var _words: Array[Label] = []      # the item's own line, two rows under the figures
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	for i in range(3):
		var vw := (BODY_W - 6) / 3
		var v := UI.button(self, Rect2(i * (vw + 3), 0, vw, VIEW_H), i == 0)
		v.text = ["Guns", "Sockets", "Craft"][i]
		v.pressed.connect(_set_view.bind(["guns", "sockets", "craft"][i]))
		_views.append(v)
	# the Craft view: the picked piece's affixes with their tiers, down the left
	_craft = UI.panel(self, Rect2(0, VIEW_H + ROW_GAP, BODY_W, 420), UI.box(Pal.PANEL, 8))
	_craft.visible = false
	_craft_title = UI.label(_craft, Rect2(PAD, 12, BODY_W - 2 * PAD, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(CRAFT_LINES):
		_craft_lines.append(UI.label(_craft, Rect2(PAD, 56 + i * 30, BODY_W - 2 * PAD, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var y := VIEW_H + ROW_GAP
	for slot in GUNS:
		var g := {}
		var head := UI.panel(self, Rect2(0, y, BODY_W, HEAD_H), UI.box(Pal.PANEL, 8))
		g["head"] = head
		g["label"] = UI.label(head, Rect2(PAD, 0, 200, 26), slot, "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		g["figure"] = UI.label(head, Rect2(BODY_W - PAD - 150, 0, 150, 26), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		g["name"] = UI.label(head, Rect2(PAD, 30, BODY_W - 2 * PAD, 32), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		y += HEAD_H + ROW_GAP
		g["rows"] = []                       # five rows; which mount each shows is the gun's (a bat has a grip and a head)
		for k in range(ROWS_A_GUN):
			var b := Button.new()
			b.position = Vector2(0, y)
			b.size = Vector2(BODY_W, ROW_H)
			b.text = ""
			b.focus_mode = Control.FOCUS_ALL
			b.pressed.connect(_pick_row.bind(slot, k))
			add_child(b)
			var r := {"button": b, "key": ""}
			r["mount"] = UI.label(b, Rect2(PAD, 0, 190, ROW_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			r["fitted"] = UI.label(b, Rect2(PAD, 0, BODY_W - 2 * PAD, ROW_H), "", "Medium", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
			g["rows"].append(r)
			y += ROW_H + ROW_GAP
		y += 10
		_guns[slot] = g
	# the sockets view: the same shape, four groups, two rows each
	y = VIEW_H + ROW_GAP
	for slot in Data.SOCKET_SLOTS:
		var g := {}
		var head := UI.panel(self, Rect2(0, y, BODY_W, SOCK_HEAD_H), UI.box(Pal.PANEL, 8))
		g["head"] = head
		g["label"] = UI.label(head, Rect2(PAD, 0, 150, SOCK_HEAD_H), slot, "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		g["name"] = UI.label(head, Rect2(PAD, 0, BODY_W - 2 * PAD, SOCK_HEAD_H), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		y += SOCK_HEAD_H + ROW_GAP
		g["rows"] = {}
		for k in range(Data.SOCKET_MAX):
			var mount := "socket %d" % (k + 1)
			var b := Button.new()
			b.position = Vector2(0, y)
			b.size = Vector2(BODY_W, ROW_H)
			b.text = ""
			b.focus_mode = Control.FOCUS_ALL
			b.pressed.connect(_pick_mount.bind(slot, mount))
			add_child(b)
			var r := {"button": b}
			r["mount"] = UI.label(b, Rect2(PAD, 0, 190, ROW_H), Items.mount_name(mount), "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			r["fitted"] = UI.label(b, Rect2(PAD, 0, BODY_W - 2 * PAD, ROW_H), "", "Medium", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
			g["rows"][mount] = r
			y += ROW_H + ROW_GAP
		y += 10
		_socks[slot] = g
	_show_view()
	# the bench's level, under the guns
	_bench = UI.panel(self, Rect2(0, Pal.ROOM_H - BENCH_H, BODY_W, BENCH_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_bench_title = UI.label(_bench, Rect2(PAD, 10, BODY_W - 2 * PAD, 30), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_bench_words = UI.label(_bench, Rect2(PAD, 40, BODY_W - 2 * PAD, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_upgrade = UI.button(_bench, Rect2(PAD, BENCH_H - 12 - 44, BODY_W - 2 * PAD, 44), true)
	_upgrade.pressed.connect(_on_upgrade)
	# the grid: the stash's attachments, for the selected mount when one is
	_inv = Inventory.new()
	_inv.position = Vector2(GRID_X, 0)
	_inv.fixed_kind = Data.ATTACHMENT
	_inv.picked.connect(_on_inv_pick)
	_inv.acted.connect(_on_inv_acted)
	add_child(_inv)
	_panel = UI.panel(self, Rect2(GRID_X, PANEL_Y, GRID_W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_left_title = UI.label(_panel, Rect2(PAD, 10, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_right_title = UI.label(_panel, Rect2(PAD * 2 + COL_W, 14, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(4):
		_left_lines.append(UI.label(_panel, Rect2(PAD, 48 + i * 28, COL_W, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_right_lines.append(UI.label(_panel, Rect2(PAD * 2 + COL_W, 48 + i * 28, COL_W, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_hint = UI.label(_panel, Rect2(PAD, PANEL_H - 6 - 44, GRID_W - 2 * PAD, 44), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(2):
		_words.append(UI.label(_panel, Rect2(PAD, 162 + i * 20, GRID_W - 2 * PAD, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(3):
		var b := UI.button(_panel, Rect2(0, PANEL_H - 6 - 44, 240, 44), i == 0)
		b.pressed.connect(_press.bind(i))
		b.visible = false
		_buttons.append(b)
		_actions.append(Callable())


func _style(b: Button, on: bool, tone := "", dim := false) -> void:
	var bg := Pal.SELECT if on else (Pal.BG if dim else Pal.PANEL)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb := UI.box(bg if state != "hover" or on or dim else Pal.CARD, 8)
		if on:
			sb.set_border_width_all(2)
			sb.border_color = Pal.ACCENT
		elif tone != "":
			sb.border_width_left = 6
			sb.border_color = Pal.tone_color(tone)
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))


static func rarity_tone(it: Dictionary) -> String:
	if it.has("set"):
		return "set"
	return ["", "good", "warn", "bad"][it["rarity"]]


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var source: Array = sim.attachments_for(sel_mount) if sel_mount != "" else _all_attachments(view == "sockets")
	var what: String = "Socketables" if view == "sockets" else "Attachments"
	if sel_mount != "":
		what = sel_mount.capitalize() if sel_mount.begins_with("socket") else "%s mount" % Items.mount_name(sel_mount)
	if view == "craft":
		source = _craftable()
		what = "Gear"
	_inv.fixed_kind = "" if view == "craft" else Data.ATTACHMENT
	_inv.show_items(sim, source, sim.stash_used(), sim.stash_cap(), what)
	var sig := _signature()
	if sig == _shown:
		return
	_shown = sig
	for slot in GUNS:
		var g: Dictionary = _guns[slot]
		var gun = sim.equipped[slot]
		if gun == null:
			g["name"].text = "Nothing fitted"
			g["name"].add_theme_color_override("font_color", Pal.TEXT_3)
			g["figure"].text = ""
		else:
			g["name"].text = gun["base"]
			g["name"].add_theme_color_override("font_color", Pal.TEXT)
			UI.fit(g["figure"], ["%.0f dmg/s · %s" % [Items.dps(gun), Items.ammo_words(gun).trim_prefix("Takes ")], "%.0f dmg/s" % Items.dps(gun)])
		var mounts: Array = _mounts_of(gun)
		for k in range(ROWS_A_GUN):
			var r: Dictionary = g["rows"][k]
			var mount: String = mounts[k] if k < mounts.size() else ""
			r["key"] = mount
			var has: bool = mount != ""
			var on: bool = sel_slot == slot and sel_mount == mount and mount != ""
			r["button"].visible = view == "guns"
			r["mount"].text = Items.mount_name(mount) if mount != "" else ("—" if gun != null else "")
			if not has:
				r["fitted"].text = ""
				r["mount"].add_theme_color_override("font_color", Pal.TEXT_3)
				r["button"].disabled = true
				_style(r["button"], false, "", true)
				continue
			r["button"].disabled = false
			r["mount"].add_theme_color_override("font_color", Pal.TEXT_2)
			var a = gun["attachments"][mount]
			if not sim.mount_open(mount):
				r["fitted"].text = "Needs bench %d" % _level_for(mount)
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				_style(r["button"], on, "", true)
			elif a == null:
				r["fitted"].text = "Empty"
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				_style(r["button"], on)
			else:
				r["fitted"].text = a["base"]
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT)
				_style(r["button"], on, rarity_tone(a))
	for slot in Data.SOCKET_SLOTS:
		var g: Dictionary = _socks[slot]
		var gear = sim.equipped[slot]
		var n: int = 0 if gear == null else Items.sockets(gear)
		if gear == null:
			g["name"].text = "Nothing fitted"
			g["name"].add_theme_color_override("font_color", Pal.TEXT_3)
		else:
			if n > 0:
				g["name"].text = gear["base"]
			else:
				# shares the row with the slot's name on the left: 150 px for that
				g["name"].text = "No sockets"
				for o in ["%s: no sockets" % gear["base"], "%s: none" % gear["base"]]:
					if UI.text_width(g["name"], o) <= BODY_W - 2 * PAD - 160:
						g["name"].text = o
						break
			g["name"].add_theme_color_override("font_color", Pal.TEXT if n > 0 else Pal.TEXT_3)
		for mount in g["rows"]:
			var r: Dictionary = g["rows"][mount]
			var has: bool = gear != null and gear["attachments"].has(mount)
			var on: bool = sel_slot == slot and sel_mount == mount
			if not has:
				r["fitted"].text = "—" if gear != null else ""
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				r["mount"].add_theme_color_override("font_color", Pal.TEXT_3)
				r["button"].disabled = true
				_style(r["button"], false, "", true)
				continue
			r["button"].disabled = false
			r["mount"].add_theme_color_override("font_color", Pal.TEXT_2)
			var a = gear["attachments"][mount]
			if not sim.mount_open(mount):
				r["fitted"].text = "Needs a bench"
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				_style(r["button"], on, "", true)
			elif a == null:
				r["fitted"].text = "Empty"
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				_style(r["button"], on)
			else:
				r["fitted"].text = a["base"]
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT)
				_style(r["button"], on, rarity_tone(a))
	# the bench
	# the level and what it fits; under it, what the next level adds, so the
	# upgrade's price buys something the player can read
	var level: Dictionary = Data.WORKSHOP[sim.workshop]
	var fits: String = ", ".join(level["mounts"].map(func(m): return m + "s"))
	UI.fit(_bench_title, ["Bench level %d · %s" % [sim.workshop, fits] if fits != "" else "Bench level %d" % sim.workshop, "Bench level %d" % sim.workshop])
	if sim.workshop >= Data.WORKSHOP.size() - 1:
		_bench_words.text = level["words"]
		_upgrade.visible = false
	else:
		var next: Dictionary = Data.WORKSHOP[sim.workshop + 1]
		var added := []
		for m in next["mounts"]:
			if not (m in level["mounts"]):
				added.append(m + "s")
		UI.fit(_bench_words, ["Next: %s" % _and(added) if not added.is_empty() else next["words"], next["words"]])
		_upgrade.visible = true
		_upgrade.text = "Upgrade for %s" % Fmt.money(sim.workshop_cost())
		_upgrade.disabled = not sim.can_upgrade_workshop()
	_show_panel()


## "optics, muzzles and grips".
static func _and(words: Array) -> String:
	if words.size() <= 1:
		return "" if words.is_empty() else str(words[0])
	return ", ".join(words.slice(0, words.size() - 1)) + " and " + str(words.back())


## The gun's own mounts, in the bench's order, sockets apart.
func _mounts_of(gun) -> Array:
	var out: Array = []
	if gun == null:
		return out
	for mount in Data.MOUNTS:
		if gun["attachments"].has(mount):
			out.append(mount)
	return out


func _pick_row(slot: String, k: int) -> void:
	var key: String = _guns[slot]["rows"][k]["key"]
	if key != "":
		_pick_mount(slot, key)


func _level_for(mount: String) -> int:
	if mount.begins_with("socket"):
		return 1
	for lv in range(Data.WORKSHOP.size()):
		if mount in Data.WORKSHOP[lv]["mounts"]:
			return lv
	return Data.WORKSHOP.size() - 1


## The stash's gun attachments, or its socketables.
func _all_attachments(socketables: bool) -> Array:
	var out: Array = []
	for it in sim.stash:
		if Items.is_attachment(it) and Items.is_socketable(it) == socketables:
			out.append(it)
	out.sort_custom(func(a, b): return Items.score(a) > Items.score(b))
	return out


func _signature() -> String:
	var parts := [view, sel_slot, sel_mount, str(sel_id), str(sim.on_mission()), str(sim.workshop), str(int(sim.cash) / 100), str(_inv.many)]
	for slot in Data.SOCKET_SLOTS:
		var gun = sim.equipped[slot]
		if gun == null:
			parts.append("-")
			continue
		parts.append(str(gun["id"]))
		for mount in gun["attachments"]:
			var a = gun["attachments"][mount]
			parts.append("%s=%s" % [str(mount), "-" if a == null else str(a["id"])])
	for it in sim.stash:
		if Items.is_attachment(it):
			parts.append(str(it["id"]))
	return "|".join(parts)


func _selected_item() -> Dictionary:
	if sel_id < 0:
		return {}
	for it in sim.stash:
		if it["id"] == sel_id:
			return it
	return {}


func _fitted() -> Dictionary:
	if sel_slot == "" or sim.equipped[sel_slot] == null:
		return {}
	var a = sim.equipped[sel_slot]["attachments"].get(sel_mount, null)
	return a if a != null else {}


func _show_panel() -> void:
	for b in _buttons:
		b.visible = false
	var it := _selected_item()
	var fitted := _fitted()
	_say(it if not it.is_empty() else fitted)
	_hint.text = ""
	for l in _left_lines:
		l.text = ""
	for l in _right_lines:
		l.text = ""
	if view == "craft":
		_show_craft(it)
		return
	if sel_mount == "" and it.is_empty():
		_left_title.text = "Select a socket" if view == "sockets" else "Select a mount"
		_right_title.text = ""
		_hint.text = "A socket on the left, or a socketable on the right" if view == "sockets" else "A gun's mount on the left, or an attachment on the right"
		return
	# the left: the selection, or the mount's fitted attachment
	var shown := it if not it.is_empty() else fitted
	if shown.is_empty():
		UI.fit(_left_title, ["%s · %s: empty" % [sel_slot, Items.mount_name(sel_mount)], "%s: empty" % Items.mount_name(sel_mount)])
		_left_lines[0].text = "Nothing in the stash fits" if sim.attachments_for(sel_mount).is_empty() else "Pick one on the right"
	else:
		_left_title.text = shown["base"]
		UI.fit(_left_lines[0], ["%s · %s T%d · %s" % [Items.kind_words(shown), Items.rarity_name(shown), shown["tier"], Fmt.money(shown["value"])],
				"%s · %s T%d" % [Items.kind_words(shown), Items.rarity_name(shown), shown["tier"]],
				"%s · T%d" % [Items.kind_words(shown), shown["tier"]]])
		# the part's figures over two lines when four stats need them
		if UI.text_width(_left_lines[1], Items.att_words(shown)) <= _left_lines[1].size.x:
			_left_lines[1].text = Items.att_words(shown)
			_left_lines[2].text = ""
		else:
			UI.wrap([_left_lines[1], _left_lines[2]], Items.att_words(shown, true))
		_left_lines[3].text = "In the stash" if not it.is_empty() else "Fitted on the %s" % sel_slot.to_lower()
	# the right: what's on the mount now, and the swap
	if not it.is_empty() and Items.is_socketable(it):
		var target_slot := sel_slot if sel_slot != "" else _slot_for("socket")
		var key := sel_mount if sel_mount.begins_with("socket") else _socket_for(target_slot)
		if target_slot == "" or key == "":
			_right_title.text = "Nothing fitted has a socket"
		elif not sim.mount_open(key):
			_right_title.text = "Needs a bench"
		else:
			var gear: Dictionary = sim.equipped[target_slot]
			var cur = gear["attachments"].get(key, null)
			_right_title.text = "Now: %s" % (cur["base"] if cur != null else "empty")
			UI.wrap([_right_lines[0], _right_lines[2]], Items.att_words(cur, true) if cur != null else "")
			_right_lines[1].text = "Into the %s's %s" % [target_slot.to_lower(), key]
			_button(0, "Fit", sim.fit_socket.bind(target_slot, key, it["id"]), not sim.on_mission())
		_button(1, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
	elif not it.is_empty():
		var target_slot := sel_slot if sel_slot != "" else _slot_for(it["mount"])
		if target_slot == "":
			UI.fit(_right_title, ["No %s with a %s mount" % ["bat or blade" if Items.is_melee_mount(it["mount"]) else "gun", it["mount"]],
					"Nothing fitted takes a %s" % it["mount"]])
		elif not sim.mount_open(it["mount"]):
			_right_title.text = "Needs bench level %d" % _level_for(it["mount"])
		else:
			var gun: Dictionary = sim.equipped[target_slot]
			var cur = gun["attachments"].get(it["mount"], null)
			_right_title.text = "Now: %s" % (cur["base"] if cur != null else "empty")
			UI.wrap([_right_lines[0], _right_lines[2]], Items.att_words(cur, true) if cur != null else "")
			_right_lines[1].text = "Fitting it: %.0f → %.0f dmg/s" % [Items.dps(gun), _dps_with(gun, it)]
			_button(0, "Fit", sim.fit.bind(target_slot, it["id"]), not sim.on_mission())
		_button(1, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
	elif not fitted.is_empty():
		_right_title.text = "Fitted"
		_right_lines[0].text = "Strip it back to the stash"
		_button(0, "Strip", sim.strip.bind(sel_slot, sel_mount), not sim.on_mission() and sim.stash_room(1))
	var x := GRID_W - PAD
	for i in range(_buttons.size() - 1, -1, -1):
		if _buttons[i].visible:
			x -= _buttons[i].size.x
			_buttons[i].position.x = x
			x -= 12


## The gun this attachment would go on: the selected gun, else the primary
## if it has the mount, else the secondary.
## For a socketable: the first of the socket slots with an empty socket,
## else the first with any.
func _slot_for(mount: String) -> String:
	if mount == "socket":
		var any := ""
		for slot in Data.SOCKET_SLOTS:
			if sim.equipped[slot] != null and Items.sockets(sim.equipped[slot]) > 0:
				if any == "":
					any = slot
				if _socket_for(slot, true) != "":
					return slot
		return any
	for slot in GUNS:
		if sim.equipped[slot] != null and sim.equipped[slot]["attachments"].has(mount):
			return slot
	return ""


## The socket a socketable goes in on this slot's gear: the first empty one,
## else the first (unless only_empty).
func _socket_for(slot: String, only_empty := false) -> String:
	if slot == "" or sim.equipped[slot] == null:
		return ""
	var first := ""
	for key in sim.equipped[slot]["attachments"]:
		if str(key).begins_with("socket"):
			if sim.equipped[slot]["attachments"][key] == null:
				return key
			if first == "":
				first = key
	return "" if only_empty else first


## The stash's gear the bench can work on.
func _craftable() -> Array:
	var out: Array = []
	for it in sim.stash:
		if not (Items.is_attachment(it) or Items.is_medical(it) or Items.is_ammo(it) or Items.is_paper(it) or it.has("unique")):
			out.append(it)
	out.sort_custom(func(a, b): return a["value"] > b["value"])
	return out


## The Craft view's left column and panel: the piece, its affixes and tiers,
## what the bench would charge; the Bench button opens the menu.
func _show_craft(it: Dictionary) -> void:
	for l in _craft_lines:
		l.text = ""
	if it.is_empty():
		_craft_title.text = "Pick a piece"
		_craft_lines[0].text = "Stash gear only; not parts, meds or uniques"
		_craft_lines[1].text = "Worn gear goes to the bench from the Lock-up"
		_left_title.text = "The bench"
		_right_title.text = ""
		_hint.text = "Bench level %d · %s and %d notes in hand" % [sim.workshop, Fmt.money(sim.cash), sim.notes]
		return
	UI.fit(_craft_title, [Items.full_name(it), it["base"]])
	UI.fit(_craft_lines[0], Items.figure_options(it))
	_craft_lines[1].text = "Level %d · up to T%d can roll" % [Items.ilvl(it), Items.tier_cap(Items.ilvl(it))]
	var lines: Array = Items.affix_lines(it, false, true)
	var short_lines: Array = Items.affix_lines(it, true, true)
	for k in range(3):
		if k < lines.size():
			UI.fit(_craft_lines[2 + k], [lines[k], short_lines[k]])
			_craft_lines[2 + k].add_theme_color_override("font_color", Pal.tier_color(Items.affix_tier(it, k)))
		else:
			_craft_lines[2 + k].text = "No affixes" if k == 0 else ""
			_craft_lines[2 + k].add_theme_color_override("font_color", Pal.TEXT_2)
	var row := 5
	for kind in ["reroll", "add", "socket", "bump"]:
		var cost: int = sim.craft_cost(it, kind)
		if cost >= 0 and row < CRAFT_LINES:
			_craft_lines[row].text = "%s · %s" % [Data.CRAFT[kind]["name"], ("%d notes" % cost) if sim.craft_in_notes(kind) else Fmt.money(cost)]
			row += 1
	_left_title.text = Items.full_name(it)
	_left_lines[0].text = "%s · %s" % [Items.rarity_name(it), ("%d affix%s" % [it["affixes"].size(), "" if it["affixes"].size() == 1 else "es"])]
	_left_lines[1].text = "Prices left; Bench has the rest"
	_right_title.text = "In hand"
	_right_lines[0].text = "%s and %d notes" % [Fmt.money(sim.cash), sim.notes]
	_button(0, "Bench", func(): bench.emit(it["id"]), sim.workshop >= 1 and not sim.on_mission())
	_button(1, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
	var x := GRID_W - PAD
	for i in range(_buttons.size() - 1, -1, -1):
		if _buttons[i].visible:
			x -= _buttons[i].size.x
			_buttons[i].position.x = x
			x -= 12


func _set_view(v: String) -> void:
	if v == view:
		return
	view = v
	sel_slot = ""
	sel_mount = ""
	sel_id = -1
	_show_view()
	if sim != null:
		show_state(sim)


func _show_view() -> void:
	for i in range(3):
		_style(_views[i], ["guns", "sockets", "craft"][i] == view)
	_craft.visible = view == "craft"
	for slot in GUNS:
		var g: Dictionary = _guns[slot]
		g["head"].visible = view == "guns"
		for r in g["rows"]:
			r["button"].visible = view == "guns"
	for slot in Data.SOCKET_SLOTS:
		var g: Dictionary = _socks[slot]
		g["head"].visible = view == "sockets"
		for mount in g["rows"]:
			g["rows"][mount]["button"].visible = view == "sockets"


## The gun's damage a second with this attachment in place of the mount's.
func _dps_with(gun: Dictionary, it: Dictionary) -> float:
	var copy := gun.duplicate(true)
	copy["attachments"][it["mount"]] = it
	return Items.dps(copy)


func _button(i: int, text: String, action: Callable, enabled: bool) -> void:
	var b := _buttons[i]
	b.visible = true
	b.text = text
	b.disabled = not enabled
	b.size.x = ceilf(UI.text_width(b, text)) + 48
	_actions[i] = action


# ------------------------------------------------------------------ acting

func _pick_mount(slot: String, mount: String) -> void:
	sel_slot = slot
	sel_mount = mount
	sel_id = -1
	show_state(sim)


func _on_inv_pick(id: int) -> void:
	if id >= 0:
		sel_id = id
		var it := _selected_item()
		if sel_mount == "" and not it.is_empty() and view != "craft":
			if Items.is_socketable(it):
				sel_slot = _slot_for("socket")
				sel_mount = _socket_for(sel_slot)
			else:
				sel_mount = it["mount"]
				sel_slot = _slot_for(sel_mount)
	elif _inv.many:
		sel_id = -1
	show_state(sim)


func _on_inv_acted() -> void:
	if _selected_item().is_empty():
		sel_id = -1
	acted.emit()


## For the tests.
func _pick_cell(k: int) -> void:
	_inv._pick(k)


func _press(i: int) -> void:
	if _actions[i].is_valid():
		_actions[i].call()
	if _selected_item().is_empty():
		sel_id = -1
	acted.emit()


func _on_upgrade() -> void:
	if sim.upgrade_workshop():
		acted.emit()
	show_state(sim)


## For the tests.
## The item's own line, under the figures: who it was, where it came from.
func _say(it: Dictionary) -> void:
	UI.wrap(_words, "" if it.is_empty() else (Words.UNIQUES.get(it["unique"], Words.item_words(it["base"])) if it.has("unique") else Words.item_words(it["base"])))


func text_nodes() -> Array:
	var out: Array = [_left_title, _right_title, _hint, _bench_title, _bench_words]
	out.append_array(_words)
	if _upgrade.visible:
		out.append(_upgrade)
	out.append_array(_left_lines)
	out.append_array(_right_lines)
	out.append_array(_views)
	if view == "craft":
		out.append(_craft_title)
		out.append_array(_craft_lines)
	elif view == "guns":
		for slot in GUNS:
			var g: Dictionary = _guns[slot]
			out.append_array([g["label"], g["name"], g["figure"]])
			for r in g["rows"]:
				out.append_array([r["mount"], r["fitted"]])
	else:
		for slot in Data.SOCKET_SLOTS:
			var g: Dictionary = _socks[slot]
			out.append_array([g["label"], g["name"]])
			for mount in g["rows"]:
				var r: Dictionary = g["rows"][mount]
				out.append_array([r["mount"], r["fitted"]])
	out.append_array(_inv.text_nodes())
	for b in _buttons:
		if b.visible:
			out.append(b)
	return out


## A mount row's name and fitted text share the row.
func line_pairs() -> Array:
	var out: Array = []
	var groups: Dictionary = _guns if view == "guns" else _socks
	for slot in groups:
		var rows = groups[slot]["rows"]
		for r in (rows if rows is Array else rows.values()):
			if r["fitted"].text != "":
				out.append([r["mount"], r["fitted"]])
		if view == "sockets":
			out.append([groups[slot]["label"], groups[slot]["name"]])
	return out
