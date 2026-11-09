extends Control
## The slice's kit and runner (round 2, 9 Nov; Matt: "It needs an inventory and character sheet during the run to get a
## true feel of things"). Tab, or Back on the pad, holds the fight and shows three columns: the runner's worn kit in the
## game's slot order (a piece picked shows the game's item head: its name, chips, headline and affixes); the rig's meds
## and magazines and the pack's grid with this run's finds (a found med goes in the rig, a found gun is worn, and the
## bridge reads the gun again); and the runner's sheet in the game's own stat words. All on the slice's own Sim: nothing
## here touches the camp.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemHead := preload("res://scripts/ui/item_head.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const SkillBar := preload("res://scripts/ui/skill_bar.gd")
const SliceBridge := preload("res://slice/bridge.gd")
const Words := preload("res://scripts/sim/words.gd")
const SliceTuning := preload("res://slice/tuning.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

signal closed

## The worn kit's order (the game's slot order as the Kit room reads down: head to feet, the guns, the charm, the pack).
const SLOT_ORDER := ["Helmet", "Armour", "Gloves", "Rig", "Primary", "Secondary", "Boots", "Charm", "Backpack"]
const SLOT_WORDS := {"Helmet": "Helmet", "Armour": "Armour", "Gloves": "Gloves", "Rig": "Rig", "Primary": "Primary", "Secondary": "Sidearm",
	"Boots": "Boots", "Charm": "Charm", "Backpack": "Pack"}
const CARD_W := 1840.0
const CARD_H := 1000.0
const PAD := 30.0
const COL_X := [30.0, 620.0, 1210.0]
const COL_W := [560.0, 560.0, 600.0]
const ROW_H := 52.0                    # a worn piece's row
const ROW_GAP := 6.0
const PIC := 44.0
const CELL := 64.0                     # a pack cell
const CELL_GAP := 6.0
const PACK_COLS := 8
const PACK_ROWS := 4
const MED_ROW_H := 44.0
const SHEET_ROWS := 36
const SHEET_ROW_H := 25.0

var world = null
var selected = null                    # the item shown in the item head: worn or found
var selected_from := ""                # "worn" or "pack"
var _card: Panel
var _heads: Array = []
var _worn: Array = []                  # [{button, pic, name, rarity, slot}]
var _head: Control                     # the game's item head
var _meds: Array = []                  # [{pic, name, fig}]
var _rig_lines: Array = []             # the magazines, the box
var _cells: Array = []                 # [{button, pic, count}]
var _more: Label
var _pick_name: Label
var wear_button: Button
var rig_button: Button
var back_button: Button
var _status: Label
var _sheet: Array = []                 # [[key, value]] labels


func _init() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_card = UI.panel(self, Rect2(0, 0, CARD_W, CARD_H), UI.box(Pal.PANEL, 10, 1, Pal.CARD_LINE))
	_build_worn()
	_build_middle()
	_build_sheet()
	visible = false


func _build_worn() -> void:
	var x: float = COL_X[0]
	var w: float = COL_W[0]
	_heads.append(UI.head(_card, Rect2(x, 20, w, 24), "Worn kit"))
	for k in range(SLOT_ORDER.size()):
		var y: float = 52.0 + k * (ROW_H + ROW_GAP)
		var b := UI.button(_card, Rect2(x, y, w, ROW_H), false)
		b.text = ""
		b.pressed.connect(_pick_worn.bind(k))
		var pic := _pic(b, Vector2(4, (ROW_H - PIC) / 2.0), PIC)
		var nm := UI.label(b, Rect2(PIC + 16, 0, w * 0.62 - PIC - 16, ROW_H), "", "SemiBold", 17, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var rar := UI.label(b, Rect2(w * 0.62, 0, w * 0.38 - 14, ROW_H), "", "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_worn.append({"button": b, "pic": pic, "name": nm, "rarity": rar, "slot": SLOT_ORDER[k]})
	_head = ItemHead.new(int(w))
	_head.position = Vector2(x, 52.0 + SLOT_ORDER.size() * (ROW_H + ROW_GAP) + 14.0)
	_card.add_child(_head)


func _build_middle() -> void:
	var x: float = COL_X[1]
	var w: float = COL_W[1]
	_heads.append(UI.head(_card, Rect2(x, 20, w, 24), "The rig"))
	for k in range(4):
		var y: float = 52.0 + k * MED_ROW_H
		var pic := _pic(_card, Vector2(x, y + 2), MED_ROW_H - 4)
		var nm := UI.label(_card, Rect2(x + MED_ROW_H + 8, y, w * 0.6 - MED_ROW_H - 8, MED_ROW_H), "", "Regular", 17, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var fig := UI.label(_card, Rect2(x + w * 0.6, y, w * 0.4, MED_ROW_H), "", "Regular", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT)
		_meds.append({"pic": pic, "name": nm, "fig": fig})
	for k in range(3):
		_rig_lines.append(UI.label(_card, Rect2(x, 236 + k * 26, w, 26), "", "Regular", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT))
	_heads.append(UI.head(_card, Rect2(x, 330, w, 24), "The pack · found this run"))
	for k in range(PACK_COLS * PACK_ROWS):
		@warning_ignore("integer_division")
		var row: int = k / PACK_COLS
		var col: int = k % PACK_COLS
		var b := UI.button(_card, Rect2(x + col * (CELL + CELL_GAP), 362 + row * (CELL + CELL_GAP), CELL, CELL), false)
		b.text = ""
		b.pressed.connect(_pick_pack.bind(k))
		var pic := _pic(b, Vector2(4, 4), CELL - 8)
		var n := UI.label(b, Rect2(CELL - 40, CELL - 22, 36, 20), "", "SemiBold", 13, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		UI.shadow(n)
		_cells.append({"button": b, "pic": pic, "count": n})
	var below: float = 362 + PACK_ROWS * (CELL + CELL_GAP)
	_more = UI.label(_card, Rect2(x, below, w, 24), "", "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT)
	_pick_name = UI.label(_card, Rect2(x, below + 30, w, 28), "", "SemiBold", 18, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	wear_button = UI.button(_card, Rect2(x, below + 66, 270, 52), true)
	wear_button.text = "Wear it"
	wear_button.pressed.connect(wear_selected)
	rig_button = UI.button(_card, Rect2(x + 290, below + 66, 270, 52), false)
	rig_button.text = "Put it in the rig"
	rig_button.pressed.connect(rig_selected)
	_status = UI.label(_card, Rect2(x, below + 128, w, 26), "", "Regular", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	back_button = UI.button(_card, Rect2(x, CARD_H - 82, 270, 52), false)
	back_button.text = "Back to the fight"
	back_button.pressed.connect(func() -> void: closed.emit())


func _build_sheet() -> void:
	var x: float = COL_X[2]
	var w: float = COL_W[2]
	_heads.append(UI.head(_card, Rect2(x, 20, w, 24), "The runner"))
	for k in range(SHEET_ROWS):
		var y: float = 52.0 + k * SHEET_ROW_H
		var key := UI.label(_card, Rect2(x, y, w, SHEET_ROW_H), "", "Regular", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var val := UI.label(_card, Rect2(x, y, w, SHEET_ROW_H), "", "SemiBold", 16, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		_sheet.append([key, val])


func _pic(parent: Node, at: Vector2, side: float) -> TextureRect:
	var t := TextureRect.new()
	t.position = at
	t.size = Vector2(side, side)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func layout(s: Vector2) -> void:
	size = s
	_card.position = Vector2(roundf((s.x - CARD_W) / 2.0), roundf((s.y - CARD_H) / 2.0))


func open(w) -> void:
	world = w
	visible = true
	layout(get_viewport_rect().size if is_inside_tree() else size)
	if selected == null:
		_pick_worn(SLOT_ORDER.find("Primary"))
	refresh()
	if is_inside_tree():
		_worn[SLOT_ORDER.find("Primary")]["button"].grab_focus()


func close() -> void:
	visible = false


func sim():
	return world.ctx["sim"]


func pack() -> Array:
	return world.stats["haul"]


## Everything shown again from the world: the worn kit, the rig, the pack, the sheet, the item picked.
func refresh() -> void:
	if world == null:
		return
	var s = sim()
	for d in _worn:
		var it = s.equipped.get(d["slot"])
		d["pic"].texture = Items.art(it) if it is Dictionary else null
		if it is Dictionary:
			UI.fit(d["name"], [Items.full_name(it), str(it["base"])])
			d["rarity"].text = UI.dots("%s · %s" % [SLOT_WORDS[d["slot"]], Items.rarity_name(it)])
			d["rarity"].add_theme_color_override("font_color", Pal.tone_color(ItemCell.rarity_tone(it)))
			d["name"].add_theme_color_override("font_color", Pal.TEXT)
		else:
			d["name"].text = "Nothing worn"
			d["name"].add_theme_color_override("font_color", Pal.TEXT_3)
			d["rarity"].text = SLOT_WORDS[d["slot"]]
			d["rarity"].add_theme_color_override("font_color", Pal.TEXT_3)
	_show_rig()
	_show_pack()
	show_sheet()
	_show_pick()


func _show_rig() -> void:
	var meds: Array = world.ctx["meds"]
	for k in range(_meds.size()):
		var d: Dictionary = _meds[k]
		var md = meds[k] if k < meds.size() else null
		var has: bool = md is Dictionary and int(md.get("count", 0)) > 0
		d["pic"].texture = Items.art({"base": str(md["base"]), "slot": Data.MEDICAL}) if md is Dictionary else null
		d["pic"].modulate = Color.WHITE if has else Color(1, 1, 1, 0.35)
		if md is Dictionary:
			UI.fit(d["name"], ["%d · %s ×%d" % [k + 1, str(md["name"]), int(md["count"])], "%d · %s" % [k + 1, str(md["name"])]])
			d["fig"].text = "+%d HP · %s s" % [int(md["heal"]), str(snappedf(float(md["use_s"]), 0.1))]
		else:
			d["name"].text = "%d · Empty" % (k + 1)
			d["fig"].text = ""
	var r = world.runner
	for k in range(_rig_lines.size()):
		_rig_lines[k].text = ""
	for k in range(mini(2, r.guns.size())):
		var g: Dictionary = r.guns[k]
		UI.fit(_rig_lines[k], ["%s · %d in, %s" % [str(g["name"]), r.rounds[k], Fmt.count(r.mags[k], "spare magazine")], "%s · %s" % [str(g["name"]), Fmt.count(r.mags[k], "spare")]])
	var boxes: Dictionary = world.ctx.get("boxes", {})
	var parts: Array = []
	for ty in boxes.keys():
		parts.append("%s %s rounds" % [Fmt.group(int(boxes[ty])), str(ty)])
	_rig_lines[2].text = ("Box: %s" % ", ".join(parts)) if not parts.is_empty() else ""


func _show_pack() -> void:
	var p: Array = pack()
	for k in range(_cells.size()):
		var d: Dictionary = _cells[k]
		var on: bool = k < p.size()
		d["button"].visible = on
		if not on:
			continue
		var it = p[k]
		d["pic"].texture = Items.art(it) if it is Dictionary and it.has("base") else null
		var n: int = int(it.get("count", it.get("rounds", 1))) if it is Dictionary else 1
		d["count"].text = ("×%s" % Fmt.group(n)) if n > 1 and not Items.is_ammo(it) else (Fmt.short_num(n) if n > 1 else "")
		var tone: String = ItemCell.rarity_tone(it) if it is Dictionary and it.has("rarity") else ""
		d["button"].add_theme_stylebox_override("normal", UI.box(Pal.CARD, 6, 2, Pal.tone_color(tone) if tone != "" else Pal.CARD_LINE))
	var extra: int = p.size() - _cells.size()
	_more.text = ("And %d more" % extra) if extra > 0 else ("Nothing found yet" if p.is_empty() else "")


func _pick_worn(k: int) -> void:
	var it = sim().equipped.get(SLOT_ORDER[k]) if world != null else null
	selected = it
	selected_from = "worn"
	_show_pick()


func _pick_pack(k: int) -> void:
	var p: Array = pack()
	if k >= p.size():
		return
	selected = p[k]
	selected_from = "pack"
	_status.text = ""
	_show_pick()


## The item picked: the game's item head over it; a found gun can be worn, a found med put in the rig.
func _show_pick() -> void:
	if world == null:
		return
	var it = selected
	_head.visible = it is Dictionary and it.has("base")
	if _head.visible:
		_head.show_item(it, sim(), mag_words(it))
	var found: bool = selected_from == "pack" and it is Dictionary and it.has("base")
	_pick_name.text = Items.full_name(it) if found else ""
	wear_button.visible = found and wear_slot(it) != ""
	rig_button.visible = found and Items.is_medical(it) and not Items.is_cure(it)


## A resist as the Runner room's defence card says it (stats_room.gd): to the cap, and what's past it after a "+".
static func resist_words(s, ty: String) -> String:
	var v: float = s.resist(ty) * 100.0
	var over: float = s.over_cap(ty)
	return ("%.0f%% +%.0f" % [v, over]) if over >= 0.5 else "%.0f%%" % v


## A gun's magazine as the slice plays it, for the item head's tail: "Magazine 35 (14 ×2.5)"; "" for anything else.
func mag_words(it: Dictionary) -> String:
	if not Items.is_gun(it) or Items.mag_size(it) <= 0:
		return ""
	var x: float = float(world.ctx.get("mag_x", SliceTuning.MAG_X))
	var base: int = Items.mag_size(it)
	var played: int = maxi(1, roundi(base * x))
	return ("Magazine %d" % base) if played == base else "Magazine %d (%d ×%s)" % [played, base, str(snappedf(x, 0.01)).trim_suffix(".0")]


## The slot a found piece goes on: a gun its own (Primary or Secondary) when the slice can fire it; "" for none.
static func wear_slot(it: Dictionary) -> String:
	var slot: String = str(it.get("slot", ""))
	if not (slot in ["Primary", "Secondary"]):
		return ""
	if float(Items.base_of(it).get("rof", 0.0)) <= 0.0 or Items.mag_size(it) <= 0:
		return ""
	return slot


## The found gun picked, worn: the bridge reads it as the slot's gun; what was worn goes in the pack.
func wear_selected() -> void:
	if selected_from != "pack" or not (selected is Dictionary):
		return
	var it: Dictionary = selected
	var slot: String = wear_slot(it)
	if slot == "":
		return
	pack().erase(it)
	var got: Array = SliceBridge.wear_gun(world.ctx, slot, it)
	world.runner.wear(got[0])
	if got[1] is Dictionary:
		pack().append(got[1])
	selected = it
	selected_from = "worn"
	_status.text = "Worn as the %s" % str(Words.U61["slots"][slot]).to_lower()
	world.runner.reread(world.ctx)
	refresh()


## The found med picked, into the rig: with its kind's slot, or a free one.
func rig_selected() -> void:
	if selected_from != "pack" or not (selected is Dictionary):
		return
	var it: Dictionary = selected
	if not SliceBridge.rig_med(world.ctx, it):
		_status.text = "All %d pouches are full" % SliceBridge.med_room(world.ctx)
		return
	pack().erase(it)
	selected = null
	selected_from = ""
	_status.text = "In the rig"
	refresh()


## The runner's sheet, in the game's stat words: who, HP, Guard, armour, the resists, the damage and its split, the
## 0.15 stats, pace, the reload, the skills, energy.
func show_sheet() -> void:
	var rows: Array = sheet_rows(world.ctx, world.runner)
	for k in range(_sheet.size()):
		var on: bool = k < rows.size()
		var key: Label = _sheet[k][0]
		var val: Label = _sheet[k][1]
		key.text = ""
		val.text = ""
		if not on:
			continue
		var row: Array = rows[k]
		if row.size() == 1:
			key.text = str(row[0]).to_upper()
			key.add_theme_color_override("font_color", Pal.TEXT_3)
			continue
		key.add_theme_color_override("font_color", Pal.TEXT_2)
		key.text = str(row[0])
		UI.fit(val, row[1] if row[1] is Array else [str(row[1])])


## The sheet as rows: [head] or [key, value or [forms long to short]].
static func sheet_rows(ctx: Dictionary, r) -> Array:
	var s = ctx["sim"]
	var out: Array = []
	out.append([str(ctx["class_name"]), "Level %d" % int(ctx["level"])])
	out.append(["HP", "%s / %s" % [Fmt.group(int(r.hp)), Fmt.group(int(r.hp_max))]])
	out.append(["Guard", "%d / %d" % [int(r.guard), int(r.guard_max)]])
	out.append(["Armour", ["%.0f · %s of a hit stopped" % [s.armour(), Fmt.pct(s.mitigation())], "%.0f · %s stopped" % [s.armour(), Fmt.pct(s.mitigation())]]])
	out.append(["Resists, capped at %d%%" % int(Data.RESIST_CAP)])
	for ty in Data.ELEMENTS:
		out.append([str(ty).capitalize(), resist_words(s, str(ty))])
	out.append(["Damage"])
	var td: Dictionary = s.type_dps()
	var total: float = 0.0
	for ty in td.keys():
		total += float(td[ty])
	out.append(["Total", "%s dmg/s" % Fmt.num(s.dps())])
	var split: Array = td.keys().filter(func(ty): return total > 0.0 and float(td[ty]) / total >= 0.01)
	split.sort_custom(func(a, b): return float(td[a]) > float(td[b]))
	for ty in split.slice(0, 4):
		out.append([str(ty).capitalize(), "%d%% of the total" % roundi(100.0 * float(td[ty]) / total)])     # the split as shares of the total
	out.append(["Shooting"])
	out.append(["Headshot chance", "%.0f%%" % clampf(Data.HEAD66_PCT + s.f66_stat("head_pct"), 0.0, 100.0)])
	out.append(["Headshot damage", "×%s" % str(snappedf(Data.HEAD66_X + s.f66_stat("head_dmg_pct") / 100.0, 0.01))])
	out.append(["Their armour ignored", "%.0f%%" % s.f66_stat("pierce_pct")])
	out.append(["Leg shots", "%.0f%% of hits" % s.f66_stat("leg_pct")])
	out.append(["Arm shots", "%.0f%% of hits" % s.f66_stat("arm_pct")])
	out.append(["Pinning them down", "+%.0f%% quicker" % s.f66_stat("suppress_pct")])
	out.append(["Round back", "%.0f%% a kill" % s.f66_stat("scav_pct")])
	out.append(["Streak bonus", ["+%.0f%% a kill, up to +%.0f%%" % [s.f66_stat("streak_dmg_pct"), float(Data.STREAK66_CAP_PCT)], "+%.0f%% a kill" % s.f66_stat("streak_dmg_pct")]])
	out.append(["Pace", "×%.2f" % s.pace()])
	var g: Dictionary = r.gun() if r != null else {}
	out.append(["Reload", "%s s" % str(snappedf(float(g.get("reload_s", 0.0)), 0.1))])
	out.append(["Energy", "%d / %d" % [int(r.energy), int(r.energy_max)]])
	out.append(["Skills"])
	for sk in ctx.get("skills", []):
		if str(sk.get("id", "")) == "":
			continue
		if not bool(sk.get("in_slice", true)):
			out.append([str(sk["name"]), "Not in the slice"])
		else:
			out.append([str(sk["name"]), SkillBar.chip(s, str(sk["id"]))])
	return out


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		closed.emit()


func text_nodes() -> Array:
	var out: Array = _heads + [_more, _pick_name, wear_button, rig_button, back_button, _status] + _rig_lines
	for d in _worn:
		out.append(d["name"])
		out.append(d["rarity"])
	for d in _meds:
		out.append(d["name"])
		out.append(d["fig"])
	for d in _cells:
		out.append(d["count"])
	for p in _sheet:
		out.append_array(p)
	if _head.visible:
		out.append_array(_head.text_nodes())
	return out


func line_pairs() -> Array:
	var out: Array = _sheet.duplicate()
	return out + (_head.line_pairs() if _head.visible else [])


func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size)


func head_rect() -> Rect2:
	return Rect2(_card.position + _head.position, Vector2(COL_W[0], _head.size.y))
