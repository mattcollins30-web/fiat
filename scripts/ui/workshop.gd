extends Control
## The Workshop's screen: the fitted guns and their mounts down the left, the
## stash's attachments for the selected mount as a grid on the right, and a
## compare panel under the grid with Fit and Strip (Sell is the fence's). The Workshop's own
## level - which mounts the bench can work on - is bought here too; it's the
## camp's cash sink. The Armoury's shape, so it reads the same way.
## Two views of the left column: Guns (the five mounts of each gun) and
## Sockets (the sockets of the guns, the helmet and the armour, and the
## socketables that go in them). The grid follows the view.

signal acted
signal bench(id)                   # the bench's menu for an item, from the Craft view
signal build                       # the Build column's menu (34): rounds, meds, a gun, a grenade for scrap

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const PickPanel := preload("res://scripts/ui/pick_panel.gd")

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const HEAD_H := 64                 # a gun's head: its slot and figure over its name
const CHIPS_H := Chips.CHIP_H + 8  # the chip row under a gun's head
const TILE_COLS := 3               # a gun's mounts as tiles, three across
const TILES := 6                   # five mounts and a spare, two rows
const ROW_GAP := 8
const VIEW_H := 36                 # the Guns / Sockets / Craft toggle, along the band's foot
const VIEW_W := 140
const UPGRADE_W := 270             # the upgrade button at the band's top right
const SOCK_HEAD_H := 44
const BAND_H := 200                # the bench's band: its level, what it fits, what the next level adds
const TOP := BAND_H + 14           # the column under the band
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
var _band: Band
var _bench_words: Label            # the band's unit: what the level fits, or what the next level adds
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
var _pick                          # the pick panel (pick_panel.gd) for the Guns and Sockets views: a part against the one in the mount
var _pick_actions: Array = []
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the band: the bench's level as the headline, the views and the upgrade along its foot
	_band = Band.new(BODY_W, BAND_H, 3)
	add_child(_band)
	_bench_words = _band.unit
	var vy := BAND_H - 14 - VIEW_H
	for i in range(3):
		var v := UI.button(self, Rect2(PAD + i * (VIEW_W + 6), vy, VIEW_W, VIEW_H), i == 0)
		v.text = ["Guns", "Sockets", "Craft"][i]
		v.pressed.connect(_set_view.bind(["guns", "sockets", "craft"][i]))
		_views.append(v)
	_upgrade = UI.button(self, Rect2(BODY_W - PAD - UPGRADE_W, 12, UPGRADE_W, 40), true)
	_upgrade.pressed.connect(_on_upgrade)
	_band.right_from(60)
	# the Craft view: the picked piece's affixes with their tiers, down the left
	_craft = UI.panel(self, Rect2(0, TOP, BODY_W, 420), UI.box(Pal.PANEL, 8))
	_craft.visible = false
	_craft_title = UI.label(_craft, Rect2(PAD, 12, BODY_W - 2 * PAD, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(CRAFT_LINES):
		_craft_lines.append(UI.label(_craft, Rect2(PAD, 56 + i * 30, BODY_W - 2 * PAD, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var y := TOP
	var tw := (BODY_W - 2 * PAD - ROW_GAP * (TILE_COLS - 1)) / TILE_COLS
	for slot in GUNS:
		var g := {}
		var head := UI.panel(self, Rect2(0, y, BODY_W, HEAD_H), UI.box(Pal.PANEL, 8))
		g["head"] = head
		g["label"] = UI.label(head, Rect2(PAD, 0, BODY_W - 2 * PAD, 26), slot, "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		g["figure"] = UI.label(head, Rect2(PAD, 0, BODY_W - 2 * PAD, 26), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		g["name"] = UI.label(head, Rect2(PAD, 30, BODY_W - 2 * PAD, 32), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		y += HEAD_H + 4
		# the gun's chips: its type, rarity, what's fitted
		g["chips"] = Chips.new(BODY_W - 2 * PAD)
		g["chips"].position = Vector2(PAD, y)
		add_child(g["chips"])
		y += CHIPS_H
		g["rows"] = []                       # six tiles; which mount each shows is the gun's (a bat has a grip and a head)
		for k in range(TILES):
			var b := Button.new()
			b.position = Vector2(PAD + (k % TILE_COLS) * (tw + ROW_GAP), y + (k / TILE_COLS) * (UI.TILE_H + ROW_GAP))
			b.size = Vector2(tw, UI.TILE_H)
			b.text = ""
			b.focus_mode = Control.FOCUS_ALL
			b.pressed.connect(_pick_row.bind(slot, k))
			add_child(b)
			var r := {"button": b, "key": ""}
			r["mount"] = UI.label(b, Rect2(10, 4, tw - 20, 22), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			r["fitted"] = UI.label(b, Rect2(10, 26, tw - 20, 30), "", "SemiBold", UI.TILE_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			g["rows"].append(r)
		y += 2 * UI.TILE_H + ROW_GAP + 16
		_guns[slot] = g
	# the sockets view: the same shape, four groups, two rows each
	y = TOP
	var sw := (BODY_W - 2 * PAD - ROW_GAP) / 2
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
			b.position = Vector2(PAD + k * (sw + ROW_GAP), y)
			b.size = Vector2(sw, UI.TILE_H)
			b.text = ""
			b.focus_mode = Control.FOCUS_ALL
			b.pressed.connect(_pick_mount.bind(slot, mount))
			add_child(b)
			var r := {"button": b}
			r["mount"] = UI.label(b, Rect2(10, 4, sw - 20, 22), Items.mount_name(mount), "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			r["fitted"] = UI.label(b, Rect2(10, 26, sw - 20, 30), "", "SemiBold", UI.TILE_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			g["rows"][mount] = r
		y += UI.TILE_H + ROW_GAP + 10
		_socks[slot] = g
	_show_view()
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
	_pick = PickPanel.new(GRID_W, PANEL_H)
	_pick.position = Vector2(GRID_X, PANEL_Y)
	_pick.acted.connect(func(): acted.emit())
	add_child(_pick)
	for i in range(PickPanel.BUTTONS):
		_pick_actions.append(Callable())


func _style(b: Button, on: bool, tone := "", dim := false) -> void:
	var bg := Pal.SELECT if on else (Pal.BG if dim else Pal.PANEL)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb := UI.box(bg if state != "hover" or on or dim else Pal.CARD, 8)
		if on:
			sb.set_border_width_all(2)
			sb.border_color = Pal.PICK
		elif tone != "":
			sb.border_width_left = 6
			sb.border_color = Pal.tone_color(tone)
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))


static func rarity_tone(it: Dictionary) -> String:
	return Pal.item_tone(it)


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
		# the chips: the slot, the type, the rarity in its tone, what's fitted
		g["chips"].visible = view == "guns" and gun != null
		if gun != null:
			var fw: Array = Items.fitted_words(gun)
			var fitted_chip: String = fw[2] if fw.size() > 2 else fw[0]          # "5 fitted", or "nothing fitted" / "no mounts"
			var type_word: String = str(Items.base_of(gun).get("type", "gun"))
			g["chips"].show_chips([[type_word.to_upper() if type_word == "smg" else type_word.capitalize(), Pal.TEXT_2], [Items.rarity_name(gun), Pal.tone_color(rarity_tone(gun)) if rarity_tone(gun) != "" else Pal.TEXT_2],
				[fitted_chip, Pal.GOOD if fw.size() > 2 else Pal.TEXT_2]])
		var mounts: Array = _mounts_of(gun)
		for k in range(TILES):
			var r: Dictionary = g["rows"][k]
			var mount: String = mounts[k] if k < mounts.size() else ""
			r["key"] = mount
			var has: bool = mount != ""
			var on: bool = sel_slot == slot and sel_mount == mount and mount != ""
			r["button"].visible = view == "guns" and (has or (gun != null and k < ROWS_A_GUN))
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
				UI.fit(r["fitted"], _short_names(a["base"]))
				r["fitted"].add_theme_color_override("font_color", Pal.tier_color(int(a.get("tier", 1))))     # the part's tier, as the Lock-up bands it
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
				r["fitted"].add_theme_color_override("font_color", Pal.tier_color(int(a.get("tier", 1))))
				_style(r["button"], on, rarity_tone(a))
	# the bench
	# the level and what it fits; under it, what the next level adds, so the
	# upgrade's price buys something the player can read
	var level: Dictionary = Data.WORKSHOP[sim.workshop]
	var fits: String = ", ".join(level["mounts"].map(func(m): return m + "s"))
	_band.set_words("The yard's works", "The bench", "Level %d" % sim.workshop, "", Pal.ACCENT)
	_band.headline_under_title(true)
	UI.fit(_bench_words, [("fits %s" % fits) if fits != "" else str(level["words"]).to_lower(), str(level["words"]).to_lower(), "fits %d mounts" % level["mounts"].size()])
	if sim.workshop >= Data.WORKSHOP.size() - 1:
		_band.set_right(["The top bench", "%d scrap in hand" % sim.scrap])
		_upgrade.visible = false
	else:
		var next: Dictionary = Data.WORKSHOP[sim.workshop + 1]
		var added := []
		for m in next["mounts"]:
			if not (m in level["mounts"]):
				added.append(m + "s")
		var adds: String = ("Next: %s" % _and(added)) if not added.is_empty() else ("Next: %s" % str(next["words"]).to_lower())
		var adds_short: String = ("Next: %d more mount%s" % [added.size(), "" if added.size() == 1 else "s"]) if not added.is_empty() else "Next level"
		_band.set_right(["Level %d, %s" % [sim.workshop + 1, Fmt.money(sim.workshop_cost())], adds if UI.text_width(_band.right[1], adds) <= _band.RIGHT_W else adds_short, "%d scrap in hand" % sim.scrap])
		_upgrade.visible = true
		var long_up := "Upgrade for %s" % Fmt.money(sim.workshop_cost())
		_upgrade.text = long_up if UI.text_width(_upgrade, long_up) + 32 <= UPGRADE_W else "Upgrade %s" % Fmt.money(sim.workshop_cost())
		_upgrade.disabled = not sim.can_upgrade_workshop()
	# the unit beside the level, fitted once the right-hand lines have taken their width
	var n_mounts: int = level["mounts"].size()
	UI.fit(_bench_words, [("fits %s" % fits) if fits != "" else str(level["words"]).to_lower(), ("fits %d mount%s" % [n_mounts, "" if n_mounts == 1 else "s"]) if n_mounts > 0 else "fits nothing yet", "fits %d" % n_mounts if n_mounts > 0 else "nothing"])
	_show_panel()


## A part's name as it fits a tile: whole, then its first word ("Drum" under
## "Magazine"), then its first word cut to six letters; never an ellipsis.
static func _short_names(base: String) -> Array:
	var words: PackedStringArray = base.split(" ", false)
	var out: Array = [base]
	if words.size() > 1 and words[0].length() >= 3:
		out.append(words[0])
	out.append(words[0].substr(0, 6) if not words.is_empty() else base)
	return out


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
	var parts := [view, sel_slot, sel_mount, str(sel_id), str(sim.on_mission()), str(sim.workshop), str(int(sim.cash) / 100), str(_inv.many),
		str(sim.notes), str(sim.last_craft.get("id", -1))]
	# the craft view's piece changes under the bench: its level, affixes and sockets are in the signature too
	var picked := _selected_item()
	if not picked.is_empty():
		parts.append(str(hash([picked.get("ilvl", 0), picked.get("affixes", []), picked.get("attachments", {}).keys()])))
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
	_hint.size.x = GRID_W - 2 * PAD           # the craft view narrows it to its buttons
	var it := _selected_item()
	var fitted := _fitted()
	_say(it if not it.is_empty() else fitted)
	_hint.text = ""
	for l in _left_lines:
		l.text = ""
	for l in _right_lines:
		l.text = ""
	_panel.visible = view == "craft"
	_pick.visible = view != "craft"
	if view == "craft":
		_show_craft(it)
		return
	# the Guns and Sockets views: the pick panel, a part against the one in the mount (Pick-A)
	if sel_mount == "" and it.is_empty():
		_pick.show_empty("Select a socket" if view == "sockets" else "Select a mount",
			["A socket on the left, or a socketable on the right" if view == "sockets" else "A gun's mount on the left, or an attachment on the right"])
		_set_pick_buttons([])
		return
	var buttons := []
	if it.is_empty():
		# a mount picked: what's on it, or that it's empty
		if fitted.is_empty():
			_pick.show_empty("%s · %s: empty" % [sel_slot, Items.mount_name(sel_mount)],
				["Nothing in the stash fits" if sim.attachments_for(sel_mount).is_empty() else "Pick one on the right"])
			_set_pick_buttons([])
			return
		_pick.show_pick(fitted, sim, "Fitted · %s %s" % [sel_slot.to_lower(), Items.mount_name(fitted["mount"]).to_lower()])
		_pick.show_right_words("The stash", "Strip it back to the stash", ["Stash has %d of %d cells" % [sim.stash_used(), sim.stash_cap()]])
		buttons.append({"text": "Strip", "action": sim.strip.bind(sel_slot, sel_mount), "enabled": not sim.on_mission() and sim.stash_room(1), "primary": true})
		_set_pick_buttons(buttons)
		return
	_pick.show_pick(it, sim, "The pick · in the stash")
	if Items.is_socketable(it):
		var target_slot := sel_slot if sel_slot != "" else _slot_for("socket")
		var key := sel_mount if sel_mount.begins_with("socket") else _socket_for(target_slot)
		if target_slot == "" or key == "":
			_pick.show_right_words("The socket", "Nothing fitted has a socket", [])
		elif not sim.mount_open(key):
			_pick.show_right_words("The socket", "Needs a bench", [])
		else:
			var gear: Dictionary = sim.equipped[target_slot]
			var cur = gear["attachments"].get(key, null)
			if cur != null:
				_pick.show_fitted(cur, sim, "On the %s · %s" % [target_slot.to_lower(), key])
			else:
				_pick.show_right_words("On the %s · %s" % [target_slot.to_lower(), key], "Empty", ["Fitting it fills the socket"])
			buttons.append({"text": "Fit", "action": sim.fit_socket.bind(target_slot, key, it["id"]), "enabled": not sim.on_mission(), "primary": true})
	else:
		var target_slot := sel_slot if sel_slot != "" else _slot_for(it["mount"])
		if target_slot == "":
			_pick.show_right_words("The mount", "Nothing fitted takes a %s" % it["mount"], [["No %s with a %s mount" % ["bat or blade" if Items.is_melee_mount(it["mount"]) else "gun", it["mount"]], ""]])
		else:
			var gun: Dictionary = sim.equipped[target_slot]
			var cur = gun["attachments"].get(it["mount"], null)
			var why: String = sim.fit_refusal(target_slot, it["id"])
			var kicker: String = "On the %s · %s" % [target_slot.to_lower(), Items.mount_name(it["mount"]).to_lower()]
			if cur != null:
				_pick.show_fitted(cur, sim, kicker)
			else:
				_pick.show_right_words(kicker, "Empty", ["Fitting it: %.0f → %.0f dmg/s" % [Items.dps(gun), _dps_with(gun, it)]] if why == "" else [])
			if why == "":
				# the swap, as the gun's damage and each stat the part moves
				var deltas := []
				var d_dps: float = _dps_with(gun, it) - Items.dps(gun)
				if absf(d_dps) >= 0.5:
					deltas.append([d_dps, "%.0f dmg/s" % absf(d_dps)])
				for pair in [["damage_pct", "% dmg"], ["first_pct", "% first"], ["speed_pct", "% pace"], ["patrol_pct", "% delay"], ["conv_fire_pct", "% as fire"], ["conv_frost_pct", "% as frost"], ["conv_poison_pct", "% as poison"], ["conv_shock_pct", "% as shock"], ["conv_bleed_pct", "% as bleed"], ["salt", " armour"], ["wire_pct", "% cash"]]:
					var dv: float = Items.att_stat(it, pair[0]) - (Items.att_stat(cur, pair[0]) if cur != null else 0.0)
					if absf(dv) >= 0.5:
						deltas.append([dv, "%.0f%s" % [absf(dv), pair[1]]])
				var tone: String = "good" if d_dps > 0.5 else ("bad" if d_dps < -0.5 else "warn")
				_pick.set_verdict(("▲ Upgrade" if tone == "good" else ("▼ Downgrade" if tone == "bad" else "Sidegrade")) if cur != null else ("▲ Fits" if d_dps >= -0.5 else "▼ Costs damage"), tone, deltas)
			else:
				_pick.set_hint(why)
			buttons.append({"text": "Fit", "action": sim.fit.bind(target_slot, it["id"]), "enabled": why == "", "primary": true})
	_set_pick_buttons(buttons)


## The pick panel's buttons, each through _press_pick so the selection follows.
func _set_pick_buttons(buttons: Array) -> void:
	var items := []
	for i in range(buttons.size()):
		_pick_actions[i] = buttons[i]["action"]
		var d: Dictionary = buttons[i].duplicate()
		d["action"] = _press_pick.bind(i)
		items.append(d)
	_pick.set_buttons(items)


func _press_pick(i: int) -> void:
	if _pick_actions[i].is_valid():
		_pick_actions[i].call()
	if _selected_item().is_empty():
		sel_id = -1


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
		if not (Items.is_attachment(it) or Items.rig_item(it) or Items.is_paper(it) or it.has("unique") or it.has("set")):
			out.append(it)
	out.sort_custom(func(a, b): return a["value"] > b["value"])
	return out


## The Craft view's left column and panel: the piece, its affixes and tiers,
## what the bench would charge; the Bench button opens the menu.
func _show_craft(it: Dictionary) -> void:
	for l in _craft_lines:
		l.text = ""
	if it.is_empty():
		_craft_title.text = "Pick a piece, or build"
		_craft_lines[0].text = "Stash gear only; not parts, meds, uniques or sets"
		_craft_lines[1].text = "Worn gear goes to the bench from the Lock-up"
		_craft_lines[2].text = "Or build for scrap: rounds, meds, guns, grenades"
		_left_title.text = "The bench"
		_right_title.text = "In hand"
		UI.fit(_right_lines[0], ["%d scrap · %s and %d notes" % [sim.scrap, Fmt.money(sim.cash), sim.notes], "%d scrap · %s · %d notes" % [sim.scrap, Fmt.money(sim.cash), sim.notes], "%ds · %s · %dn" % [sim.scrap, Fmt.money(sim.cash), sim.notes]])
		UI.fit(_right_lines[1], ["Scrap: searched up, scrapped here, ditched", "Scrap: found, scrapped, ditched"])
		_button(0, "Build for scrap", func(): build.emit(), sim.workshop >= 1 and not sim.on_mission())
		var bx := GRID_W - PAD - _buttons[0].size.x
		_buttons[0].position.x = bx
		_hint.size.x = bx - PAD - 12
		if sim.last_craft.get("kind", "") == "build":
			UI.fit(_hint, [str(sim.last_craft["words"]), "Built"])
			_hint.add_theme_color_override("font_color", Pal.GOOD)
		else:
			UI.fit(_hint, ["Bench level %d · %d scrap in hand" % [sim.workshop, sim.scrap], "%d scrap in hand" % sim.scrap])
			_hint.add_theme_color_override("font_color", Pal.TEXT_3)
		return
	UI.fit(_craft_title, [Items.full_name(it), it["base"]])
	# the bench's last job on this piece stays on the hint until the next
	_hint.add_theme_color_override("font_color", Pal.GOOD if sim.last_craft.get("id", -1) == it["id"] else Pal.TEXT_3)
	UI.fit(_craft_lines[0], Items.figure_options(it))
	_craft_lines[1].text = "Level %d · T%d to T%d roll" % [Items.ilvl(it), mini(Items.tier_floor(Items.ilvl(it)), Items.rarity_cap(it)), Items.rarity_cap(it)]     # the level's floor, the rarity's cap
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
	UI.fit(_right_lines[0], ["%s and %d notes · %d scrap" % [Fmt.money(sim.cash), sim.notes, sim.scrap], "%s · %d notes · %d scrap" % [Fmt.money(sim.cash), sim.notes, sim.scrap], "%s · %dn · %ds" % [Fmt.money(sim.cash), sim.notes, sim.scrap]])
	_button(0, "Bench", func(): bench.emit(it["id"]), sim.workshop >= 1 and not sim.on_mission())
	_button(1, "Scrap it (+%d)" % sim.scrap_of(it), sim.scrap_item.bind(it["id"]), sim.workshop >= 1 and not sim.on_mission())
	var x := GRID_W - PAD
	for i in range(_buttons.size() - 1, -1, -1):
		if _buttons[i].visible:
			x -= _buttons[i].size.x
			_buttons[i].position.x = x
			x -= 12
	# the hint stops at the buttons, and shortens if it must
	_hint.size.x = x - PAD
	if sim.last_craft.get("id", -1) == it["id"]:
		UI.fit(_hint, [str(sim.last_craft["words"]), str(sim.last_craft["words"]).get_slice(":", 0), Data.CRAFT.get(sim.last_craft["kind"], {}).get("name", "Built")])
	else:
		UI.fit(_hint, ["Bench level %d · %s and %d notes in hand" % [sim.workshop, Fmt.money(sim.cash), sim.notes], "%s and %d notes in hand" % [Fmt.money(sim.cash), sim.notes], "Bench level %d" % sim.workshop])


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
		g["chips"].visible = view == "guns" and g["chips"].visible
		for r in g["rows"]:
			r["button"].visible = view == "guns" and r["button"].visible
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
	if view != "craft":
		_pick.press(i)                     # the pick panel's button: its action, then the shell's refresh
		return
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
	var out: Array = []
	if view == "craft":
		out.append_array([_left_title, _right_title, _hint])
		out.append_array(_words)
		out.append_array(_left_lines)
		out.append_array(_right_lines)
	else:
		out.append_array(_pick.text_nodes())
	out.append_array(_band.text_nodes())
	if _upgrade.visible:
		out.append(_upgrade)
	out.append_array(_views)
	if view == "craft":
		out.append(_craft_title)
		out.append_array(_craft_lines)
	elif view == "guns":
		for slot in GUNS:
			var g: Dictionary = _guns[slot]
			out.append_array([g["label"], g["name"], g["figure"]])
			if g["chips"].visible:
				out.append_array(g["chips"].text_nodes())
			for r in g["rows"]:
				if r["button"].visible:
					out.append_array([r["mount"], r["fitted"]])
	else:
		for slot in Data.SOCKET_SLOTS:
			var g: Dictionary = _socks[slot]
			out.append_array([g["label"], g["name"]])
			for mount in g["rows"]:
				var r: Dictionary = g["rows"][mount]
				out.append_array([r["mount"], r["fitted"]])
	out.append_array(_inv.text_nodes())
	if view == "craft":
		for b in _buttons:
			if b.visible:
				out.append(b)
	return out


## A mount tile's name sits over its fitted part now, so no pair shares a line;
## the gun's head keeps its slot and figure on one.
func line_pairs() -> Array:
	var out: Array = _pick.line_pairs() if view != "craft" else []
	if view == "guns":
		for slot in GUNS:
			out.append([_guns[slot]["label"], _guns[slot]["figure"]])
	elif view == "sockets":
		for slot in Data.SOCKET_SLOTS:
			out.append([_socks[slot]["label"], _socks[slot]["name"]])
	return out
