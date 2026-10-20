extends Panel
## What a site pays (16 Oct, item 11; the canvas "Fiat - Map tier guide", approved): the map's guide, over the Runs
## room. Depths: a site picked on the left, its ladder as the signals climb it, a row a level from a few under your
## reach - the gear to wear, the gangs and the pay against a campaign run there, the drops, the rarity, the loose
## uniques, and what opens there. Where to farm: the heads and what they carry, each site's own unique and the level it
## drops from, and where each kind of kit leans. All of it read from the sim and the data; nothing here changes it.

signal closed

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")

const PAD := 20
const HEAD_H := 64
const TAB_W := 180
const SITES_W := 290
const SITE_H := 40
const TABLE_X := PAD + SITES_W + 20
const ROW_H := 54
const ROWS := 12
const TABLE_Y := 182
## The table's columns: [heading, width]; the last takes what's left.
const COLS := [["Signal level", 130], ["Gear to wear", 190], ["Gang HP", 100], ["XP and tins", 100], ["Finds", 80], ["Quality", 80], ["Uniques", 80], ["Opens here", 0]]
const COL_GAP := 10
const MARK_TONES := {"set": Pal.SET, "unique": Pal.UNIQUE, "head": Pal.BAD, "convoy": Pal.ACCENT, "deep": Pal.EPIC}
const TYPE_WORDS := {"melee": "melee", "improvised": "improvised", "shotgun": "shotguns", "pistol": "pistols", "smg": "SMGs", "rifle": "rifles"}
const SLOT_WORDS := {"Primary": "primaries", "Secondary": "sidearms", "Helmet": "helmets", "Armour": "armour", "Rig": "rigs", "Backpack": "packs"}
const ROOM_WORDS := {"clinic": "the Clinic", "fence": "the Fence", "yard": "the Yard", "radio": "the Radio", "workshop": "the Workshop"}

var sim
var tab := "depths"
var site := -1                      # the site shown on Depths; -1 picks the deepest open one on first show
var _tabs: Array = []
var _close: Button
var _depths: Control
var _farm: Control
var _site_buttons: Array = []
var _zone_labels: Array = []
var _site_title: Label
var _site_lean: Label
var _site_note: Label
var _heads: Array = []              # the table's headings
var _rows: Array = []               # {panel, cells: [Label], marks: Chips}
var _legend: Label
var _legend2: Label
# where to farm
var _farm_labels: Array = []        # every label on the tab, for the tests' fit
var _farm_sig := ""                 # what the tab was built from: rebuilt only when it moves (the review)


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	UI.label(self, Rect2(PAD, 12, 380, 40), "Site guide", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		var b := UI.button(self, Rect2(PAD + 400 + k * (TAB_W + 8), 12, TAB_W, 40), false)
		b.text = ["By level", "Where to farm"][k]
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		b.pressed.connect(_pick_tab.bind(["depths", "farm"][k]))
		_tabs.append(b)
	_close = UI.button(self, Rect2(Pal.GRID_W - PAD - 48, 12, 48, 40), false)
	_close.text = "×"
	_close.tooltip_text = "Close"
	_close.pressed.connect(func():
		visible = false
		closed.emit())
	UI.panel(self, Rect2(0, HEAD_H, Pal.GRID_W, 1), UI.box(Pal.CARD_LINE, 0))
	_depths = Control.new()
	_depths.size = size
	_depths.mouse_filter = Control.MOUSE_FILTER_IGNORE     # the page is the guide's full size: passing, it took the tabs' and the close's clicks (20 Oct)
	add_child(_depths)
	_farm = Control.new()
	_farm.size = size
	_farm.mouse_filter = Control.MOUSE_FILTER_IGNORE     # the page is the guide's full size: passing, it took the tabs' and the close's clicks (20 Oct)
	add_child(_farm)
	_build_depths()
	visible = false


func _build_depths() -> void:
	var y := 76.0
	for z in range(Data.ZONES.size()):
		_zone_labels.append(UI.label(_depths, Rect2(PAD, y, SITES_W, 22), str(Data.ZONES[z]["name"]).to_upper(), "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
		y += 24
		for i in Data.ZONES[z]["tiers"]:
			var b := UI.button(_depths, Rect2(PAD, y, SITES_W, SITE_H), false)
			b.text = str(Data.TIERS[i]["name"])
			b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
			b.pressed.connect(_pick_site.bind(int(i)))
			_site_buttons.append(b)
			y += SITE_H + 6
		y += 12
	var tw: float = Pal.GRID_W - PAD - TABLE_X
	_site_title = UI.label(_depths, Rect2(TABLE_X, 74, tw, 38), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_site_lean = UI.label(_depths, Rect2(TABLE_X, 114, tw * 0.45, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_site_note = UI.label(_depths, Rect2(TABLE_X + tw * 0.45, 114, tw * 0.55, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	var x: float = TABLE_X + 14
	for k in range(COLS.size()):
		var w: float = float(COLS[k][1]) if int(COLS[k][1]) > 0 else (Pal.GRID_W - PAD - 14 - x)
		_heads.append(UI.label(_depths, Rect2(x, TABLE_Y - 32, w, 26), str(COLS[k][0]), "Medium", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
		x += w + COL_GAP
	for r in range(ROWS):
		var p := UI.panel(_depths, Rect2(TABLE_X, TABLE_Y + r * ROW_H, tw, ROW_H - 1), UI.box(Color.TRANSPARENT, 0))
		UI.panel(p, Rect2(0, ROW_H - 1, tw, 1), UI.box(Pal.CARD_LINE, 0))
		var row := {"panel": p, "cells": [], "subs": [], "here": false}
		row["edge"] = UI.panel(p, Rect2(0, 0, 3, ROW_H - 1), UI.box(Pal.ACCENT, 0))
		var cx := 14.0
		for k in range(COLS.size() - 1):
			var w: float = float(COLS[k][1])
			var size_k: int = Pal.CELL_TEXT_BIG + 1 if k <= 1 else Pal.CELL_TEXT_BIG
			if k == 1:
				# the gear: its level, and the runner's fifth under it when that's lower
				row["cells"].append(UI.label(p, Rect2(cx, 4, w, 26), "", "SemiBold", size_k, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
				row["subs"].append(UI.label(p, Rect2(cx, 28, w, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT))
			else:
				row["cells"].append(UI.label(p, Rect2(cx, 0, w, ROW_H - 1), "", "SemiBold" if k == 0 else "Regular", size_k, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
			cx += w + COL_GAP
		var mw: float = tw - cx - 10
		var ch := Chips.new(mw, 3)
		ch.position = Vector2(cx, 0)
		p.add_child(ch)
		row["marks"] = ch
		_rows.append(row)
	var ly: float = TABLE_Y + ROWS * ROW_H + 12
	_legend = UI.label(_depths, Rect2(TABLE_X, ly, tw, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_legend2 = UI.label(_depths, Rect2(TABLE_X, ly + 28, tw, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)


## Opens it on the site given (the Runs room's own, as a rule), on the Depths tab unless one's already picked.
func open(s, at := -1) -> void:
	sim = s
	if at >= 0:
		site = at
	visible = true
	show_state(sim)


func show_state(s) -> void:
	sim = s
	if not visible or sim == null:
		return
	if site < 0:
		site = clampi(sim.best_tier, 0, Data.TIERS.size() - 1)
	for k in range(_tabs.size()):
		UI.style_button(_tabs[k], ["depths", "farm"][k] == tab)
	# what isn't known yet is scrambled (20 Oct, Matt): a zone not open, its sites, its head, its uniques
	for z in range(_zone_labels.size()):
		_zone_labels[z].text = (str(Data.ZONES[z]["name"]) if sim.zone_open(z) else Fmt.scramble(str(Data.ZONES[z]["name"]))).to_upper()
	for k in range(_site_buttons.size()):
		_site_buttons[k].text = site_name(sim, k)
		_site_buttons[k].disabled = not known(sim, k)
	if not known(sim, site):
		site = clampi(sim.best_tier, 0, Data.TIERS.size() - 1)
	_depths.visible = tab == "depths"
	_farm.visible = tab == "farm"
	if tab == "depths":
		_show_depths()
	else:
		_show_farm()


func _pick_tab(t: String) -> void:
	tab = t
	_farm_sig = ""
	show_state(sim)


func _pick_site(i: int) -> void:
	site = i
	show_state(sim)


## Whether a site is known yet: its zone open. Unknown, its name and what it carries are scrambled.
static func known(s, i: int) -> bool:
	return s == null or s.zone_open(int(Data.TIERS[i]["zone"]))


static func site_name(s, i: int) -> String:
	var nm: String = str(Data.TIERS[i]["name"])
	return nm if known(s, i) else Fmt.scramble(nm)


## The site's lean, from its drops: the gun type, then its two heaviest slots.
static func lean_words(i: int) -> String:
	var d: Dictionary = Data.TIERS[i]["drops"]
	var slots: Dictionary = d.get("slots", {})
	var order: Array = slots.keys()
	order.sort_custom(func(a, b): return float(slots[a]) > float(slots[b]))
	var parts: Array = [str(TYPE_WORDS.get(str(d.get("type", "")), str(d.get("type", ""))))]
	for s in order:
		var w: String = str(SLOT_WORDS.get(s, str(s).to_lower()))
		if parts.size() < 3 and not (w in parts):
			parts.append(w)
	return "Leans to " + ", ".join(parts.filter(func(p): return p != ""))


func _show_depths() -> void:
	for k in range(_site_buttons.size()):
		var b: Button = _site_buttons[k]
		UI.style_button(b, k == site)
	UI.fit(_site_title, [site_name(sim, site)])
	UI.fit(_site_lean, [lean_words(site), ""])
	var done: bool = sim.campaign_done()
	UI.fit(_site_note, ["A signal at each level here, against a campaign run here" if done else "Signals open with the Radio after the campaign; each row is one signal level here", "A signal at each level here" if done else "Signals: after the campaign", ""])
	var rows: Array = sim.guide_rows(site, sim.guide_from(site, ROWS), ROWS)
	var lv: int = sim.level()
	for r in range(ROWS):
		var row: Dictionary = _rows[r]
		var on: bool = r < rows.size()
		row["panel"].visible = on
		if not on:
			continue
		var g: Dictionary = rows[r]
		var here: bool = bool(g["here"])
		if here != bool(row["here"]):
			(row["panel"] as Panel).add_theme_stylebox_override("panel", UI.box(Pal.BUTTON_HOVER if here else Color.TRANSPARENT, 0))     # only when it moves (the review)
			row["here"] = here
		row["edge"].visible = here
		var c: Array = row["cells"]
		c[0].text = ("▶ %d" % int(g["level"])) if here else "%d" % int(g["level"])
		c[1].text = "Level %d" % int(g["wear"])
		c[1].add_theme_color_override("font_color", Pal.BAD if int(g["wear"]) > lv else Pal.TEXT)
		row["subs"][0].text = ("%d%% at %d" % [roundi(Data.FIND_AT_MINE * 100.0), int(g["mine"])]) if int(g["mine"]) > 0 else ""
		c[1].position.y = 4.0 if row["subs"][0].text != "" else (ROW_H - 1 - c[1].size.y) / 2.0     # centred alone, over its fifth with one
		c[2].text = "×%.2f" % float(g["gangs"]) if float(g["gangs"]) < 100.0 else "×%.0f" % float(g["gangs"])
		c[3].text = "×%.2f" % float(g["pay"]) if float(g["pay"]) < 100.0 else "×%.0f" % float(g["pay"])
		c[4].text = "%+.0f" % float(g["drop"])
		c[5].text = "%+.0f%%" % float(g["rarity"])
		c[6].text = ("%.0f%%" % (float(g["unique"]) * 100.0)) if float(g["unique"]) > 0.0 else "—"
		var items: Array = []
		for m in g["marks"]:
			var text: String = str(m[0])
			var short: String = {"set": "Sets", "unique": "Unique", "deep": text.replace("Deep gear, ", "")}.get(str(m[1]), text)
			items.append({"forms": [text, short], "colour": MARK_TONES.get(str(m[1]), Pal.TEXT_2)})
		row["marks"].show_chips(items, 2 if items.size() > 1 else 1, true)
		row["marks"].position.y = (ROW_H - 1 - (Chips.CHIP_H * (2 if row["marks"].rows_used() > 1 else 1) + (Chips.ROW_GAP if row["marks"].rows_used() > 1 else 0))) / 2.0
	var reach: String = ("▶ your reach (level %d) · " % sim.reach) if sim.room_open("radio") else ""     # the reach is the Radio's: no word of it before
	UI.fit(_legend, [reach + "gear in red is past your level (%d) · %.0f%% of finds come at a level you can wear" % [lv, Data.FIND_AT_MINE * 100.0],
		reach + "red: past your level (%d) · %.0f%% at yours" % [lv, Data.FIND_AT_MINE * 100.0], "red: past level %d" % lv])
	UI.fit(_legend2, ["Gang HP, XP and tins against a campaign run here · a signal's codes and extras on top · Mythics: 1 in %s finds, anywhere" % _thousands(Data.MYTHIC_ODDS_IN),
		"Against a campaign run here · Mythics 1 in %s finds" % _thousands(Data.MYTHIC_ODDS_IN)])


static func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


# ------------------------------------------------------------------ where to farm

func _farm_label(rect: Rect2, text: String, weight: String, sz: int, colour: Color) -> Label:
	var l := UI.label(_farm, rect, "", weight, sz, colour, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.fit(l, [text, text.get_slice(" · ", 0)])
	_farm_labels.append(l)
	return l


func _show_farm() -> void:
	var zones_open := ""
	for z in range(Data.ZONES.size()):
		zones_open += "1" if sim.zone_open(z) else "0"
	var fsig := "%d|%d|%s" % [sim.shelf.size(), sim.level(), zones_open]
	if fsig == _farm_sig and not _farm_labels.is_empty():
		return
	_farm_sig = fsig
	for l in _farm_labels:
		l.queue_free()
	_farm_labels.clear()
	var col_w: float = (Pal.GRID_W - 2 * PAD - 2 * 24) / 3.0
	# the heads, and what's anywhere
	var x: float = PAD
	var y := 80.0
	_farm_label(Rect2(x, y, col_w, 28), "THE HEADS", "Medium", Pal.CELL_TEXT - 1, Pal.TEXT_3)
	y += 34
	for b in Data.BOSSES:
		var i: int = int(b["tier"])
		var k_b: bool = known(sim, i)
		var sc := func(t: String) -> String: return t if k_b else Fmt.scramble(t)
		_farm_label(Rect2(x, y, col_w, 28), "%s · %s" % [sc.call(str(b["name"])), site_name(sim, i)], "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT if k_b else Pal.TEXT_2)
		_farm_label(Rect2(x, y + 28, col_w, 24), " · ".join(b.get("uniques", []).map(func(u): return sc.call(str(u)))), "Regular", Pal.CELL_TEXT, Pal.UNIQUE)
		var opens: Array = (b.get("opens", {}) as Dictionary).keys().map(func(r): return str(ROOM_WORDS.get(r, r)))
		_farm_label(Rect2(x, y + 52, col_w, 24), ("Opens %s · comes back at full strength as a signal's extra" % " and ".join(opens)) if k_b else sc.call("Opens " + " and ".join(opens)), "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2)
		y += 92
	y += 10
	_farm_label(Rect2(x, y, col_w, 28), "ANYWHERE", "Medium", Pal.CELL_TEXT - 1, Pal.TEXT_3)
	y += 32
	_farm_label(Rect2(x, y, col_w, 26), "Mythics · one for each slot · 1 in %s finds" % _thousands(Data.MYTHIC_ODDS_IN), "Regular", Pal.CELL_TEXT, Pal.MYTHIC)
	_farm_label(Rect2(x, y + 28, col_w, 26), "Set pieces · signals from level %d, any site" % (2 + Data.TIERS.size() - 1 - Data.OUTSKIRTS_SITES), "Regular", Pal.CELL_TEXT, Pal.SET)
	_farm_label(Rect2(x, y + 56, col_w, 26), "Loose uniques · %.0f%% from %s on, +%.0f%% a level past %d anywhere, up to %.0f%%" % [Data.UNIQUE_CAMPAIGN * 100.0, Data.ZONES[Data.UNIQUE_FROM_ZONE]["name"], Data.UNIQUE_DROP * 100.0, 1 + Data.TIERS.size() - 1 - Data.OUTSKIRTS_SITES, Data.UNIQUE_CAP * 100.0], "Regular", Pal.CELL_TEXT, Pal.UNIQUE)
	# each site's own unique
	x += col_w + 24
	y = 80.0
	_farm_label(Rect2(x, y, col_w, 28), "A SITE'S OWN UNIQUE", "Medium", Pal.CELL_TEXT - 1, Pal.TEXT_3)
	y += 34
	for i in range(Data.TIERS.size()):
		var u: Dictionary = sim.site_unique(i)
		if u.is_empty():
			continue
		var found: bool = str(u["name"]) in sim.shelf
		var k_s: bool = known(sim, i)
		_farm_label(Rect2(x, y, col_w - 90, 26), str(u["name"]) if k_s else Fmt.scramble(str(u["name"])), "SemiBold", Pal.CELL_TEXT_BIG, Pal.UNIQUE)
		_farm_label(Rect2(x + col_w - 90, y, 90, 26), "level %d" % sim.site_unique_level(i), "Regular", Pal.CELL_TEXT, Pal.TEXT_2)
		_farm_label(Rect2(x, y + 26, col_w, 22), "%s · %s%s" % [u["slot"], site_name(sim, i), " · on the shelf" if found else ""], "Regular", Pal.CELL_TEXT - 1, Pal.GOOD if found else Pal.TEXT_3)
		y += 58
	y += 6
	_farm_label(Rect2(x, y, col_w, 24), "%.0f%% of finds on a signal there, from that level" % (Data.SITE_UNIQUE_DROP * 100.0), "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2)
	_farm_label(Rect2(x, y + 24, col_w, 24), "Once it's on the shelf, a second is 1 in %d of that" % roundi(1.0 / Data.SITE_UNIQUE_AGAIN), "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2)
	# looking for
	x += col_w + 24
	y = 80.0
	_farm_label(Rect2(x, y, col_w, 28), "LOOKING FOR", "Medium", Pal.CELL_TEXT - 1, Pal.TEXT_3)
	y += 34
	for line in looking_for(sim):
		_farm_label(Rect2(x, y, col_w, 26), str(line[0]), "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT)
		_farm_label(Rect2(x, y + 26, col_w, 24), str(line[1]), "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2)
		y += 58


## What leans where, from the sites' drops: [what, where] - each gun type's sites, the sites heaviest in helmets and
## armour, and in rigs and packs; papers from every site.
static func looking_for(s = null) -> Array:
	var out: Array = []
	for ty in ["melee", "improvised", "shotgun", "pistol", "smg", "rifle"]:
		var at: Array = []
		for i in range(Data.TIERS.size()):
			if str(Data.TIERS[i]["drops"].get("type", "")) == ty:
				at.append(site_name(s, i))
		if not at.is_empty():
			out.append([str(TYPE_WORDS[ty]).capitalize() if ty != "smg" else "SMGs", " · ".join(at)])
	for pair in [[["Helmet", "Armour"], "Helmets, armour"], [["Rig", "Backpack"], "Rigs, packs"]]:
		var weights: Array = []
		for i in range(Data.TIERS.size()):
			var slots: Dictionary = Data.TIERS[i]["drops"].get("slots", {})
			var total := 0.0
			var all := 0.0
			for sl in slots:
				all += float(slots[sl])
				if sl in pair[0]:
					total += float(slots[sl])
			weights.append([total / maxf(1.0, all), i])
		weights.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
		out.append([pair[1], " · ".join(weights.slice(0, 3).map(func(w): return site_name(s, int(w[1]))))])
	out.append(["Papers", "Every site; read once the Radio's open"])
	return out


## The labels showing, for the tests' fit.
func text_nodes() -> Array:
	var out: Array = []
	if tab == "depths":
		out.append_array([_site_title, _site_lean, _site_note, _legend, _legend2])
		out.append_array(_heads)
		for row in _rows:
			if row["panel"].visible:
				out.append_array(row["cells"])
				out.append_array(row["subs"])
				out.append_array(row["marks"].text_nodes())
	else:
		out.append_array(_farm_labels)
	return out
