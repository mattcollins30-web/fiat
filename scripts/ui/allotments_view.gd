extends Control
## (BUILD69-A) The Workshop's sixth view, the allotments on the Pitch (docs/design/endgame_rail.md §4; the canvas's
## Allotments board, approved 7 Nov): opens with the pumping station's rebuild, grows while it runs. The plots across
## the top - a seed, what its harvest does, the runs left, "Ready to lift"; under them the Bench for the picked plot
## (or a harvest lifted earlier): a piece of kit, its affixes now and after, sure, never rolled - Lift and use, or Lift
## into the shed; the shed down the right: the seeds held (pick one to plant an empty plot) and the harvests lifted.
## The sim is builder E's (sim.e69_*, $S/e69_notes.md).
##
## Signals: `acted` after a plant, a lift or a craft.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")

const BP := 16
const GAP := 12
const BANNER_H := 92
const PLOTS_Y := BANNER_H + GAP
const PLOT_H := 136
const PLOTS := 6                          # Data.ALLOT69_PLOT_REACH (the smoke holds them equal)
const LOW_Y := PLOTS_Y + PLOT_H + GAP
const SHED_W := 464
const PIECE := Vector2(200, 72)
const AFF_ROWS := 6                       # a Legendary's five and the element a harvest adds
const AFF_H := 26
const BOX_Y := 124
const BOX_H := 36 + AFF_ROWS * AFF_H
const BTN_H := 52
const SEED_ROW_H := 30
const SEED_GAP := 4
const LIFT_ROWS := 3

var sim
var sel_plot := 0                         # the plot picked; -1 a lifted harvest instead
var sel_lifted := ""                      # the lifted harvest picked (sel_plot -1)
var sel_piece := 0                        # which of the pieces a harvest fits sits on the Bench
var sel_stat := ""                        # the affix a take-off or a raise works on
var _w := 0.0
var _h := 0.0
var _banner: Panel
var _band := {}
var _kicker: Label
var _title: Label
var _sub: Label
var _count_pill: Panel
var _count: Label
var _plots: Array = []                    # {button, n, name, craft, track, fill, state}
var _bench: Panel
var _b_head: Label
var _b_cell
var _b_name: Label
var _b_line: Label
var _b_other: Button
var _now_box: Panel
var _now_head: Label
var _now: Array = []                      # buttons: an affix to pick
var _after_box: Panel
var _after_head: Label
var _after: Array = []                    # labels
var _b_note: Label
var _b_block: Label
var _use: Button
var _lift: Button
var _b_lines: Array = []                  # an empty or growing plot's words, in the piece's place
var _shed: Panel
var _seeds_head: Label
var _seeds: Array = []                    # {button, name, count, key}
var _lifted_head: Label
var _lifted: Array = []                   # {button, name, count, key}
var _lifted_none: Label
var _shed_note: Label
var _shown := ""


func _init(w: float, h: float) -> void:
	_w = w
	_h = h
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_banner = UI.panel(self, Rect2(0, 0, w, BANNER_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_band = UI.head_art(_banner, "The Allotments")
	_kicker = UI.head(_banner, Rect2(BP + 8, 10, 600, UI.HEAD_H), Words.A69["l_kicker"])
	_kicker.add_theme_color_override("font_color", Pal.GOOD)
	_title = UI.label(_banner, Rect2(BP + 8, 30, 600, 34), Words.A69["l_title"], "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(_banner, Rect2(BP + 8, 64, 700, 24), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_count_pill = UI.panel(_banner, Rect2(w - BP - 400, BANNER_H - 44, 400, 32), UI.box(Color(0.06, 0.07, 0.08, 0.72), 8))
	_count = UI.label(_count_pill, Rect2(12, 2, 376, 28), "", "Medium", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	@warning_ignore("integer_division")
	var pw: int = int(w - (PLOTS - 1) * 10) / PLOTS
	for k in range(PLOTS):
		var b := Button.new()
		b.position = Vector2(k * (pw + 10), PLOTS_Y)
		b.size = Vector2(pw, PLOT_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_plot.bind(k))
		add_child(b)
		var p := {"button": b}
		var iw: float = pw - 28
		p["n"] = UI.label(b, Rect2(14, 8, iw, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		p["name"] = UI.label(b, Rect2(14, 30, iw, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		p["craft"] = UI.label(b, Rect2(14, 58, iw, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		p["track"] = UI.panel(b, Rect2(14, 88, iw, 8), UI.box(Pal.BG, 4))
		p["fill"] = UI.panel(p["track"], Rect2(0, 0, iw, 8), UI.box(Pal.GOOD, 4))
		p["state"] = UI.label(b, Rect2(14, 102, iw, 24), "", "Medium", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		_plots.append(p)
	_build_bench(w - SHED_W - GAP, h - LOW_Y)
	_build_shed(w - SHED_W, SHED_W, h - LOW_Y)


func _build_bench(bw: float, bh: float) -> void:
	_bench = UI.panel(self, Rect2(0, LOW_Y, bw, bh), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = bw - 2 * BP
	_b_head = UI.head(_bench, Rect2(BP, 12, iw, UI.HEAD_H), "")
	_b_cell = ItemCell.new()
	_b_cell.position = Vector2(BP, 40)
	_b_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bench.add_child(_b_cell)
	var tx: float = BP + PIECE.x + 18
	_b_name = UI.label(_bench, Rect2(tx, 42, iw - tx - 210, 32), "", "SemiBold", Pal.NAME - 6, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_b_line = UI.label(_bench, Rect2(tx, 76, iw - tx - 210, 26), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_b_other = UI.button(_bench, Rect2(bw - BP - 210, 48, 210, 40), false)
	_b_other.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
	_b_other.pressed.connect(_other_piece)
	@warning_ignore("integer_division")
	var hw: float = floorf((iw - GAP) / 2.0)
	_now_box = UI.panel(_bench, Rect2(BP, BOX_Y, hw, BOX_H), UI.box(Pal.CARD, 6))
	_now_head = UI.head(_now_box, Rect2(14, 8, hw - 28, UI.HEAD_H), Words.A69["l_now"])
	for k in range(AFF_ROWS):
		var b := Button.new()
		b.position = Vector2(6, 34 + k * AFF_H)
		b.size = Vector2(hw - 12, AFF_H)
		b.focus_mode = Control.FOCUS_ALL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", UI.font("Regular"))
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG - 1)
		b.pressed.connect(_pick_stat.bind(k))
		_now_box.add_child(b)
		_now.append(b)
	_after_box = UI.panel(_bench, Rect2(BP + hw + GAP, BOX_Y, iw - hw - GAP, BOX_H), UI.box(Pal.CARD, 6, 1, Pal.GOOD))
	_after_head = UI.head(_after_box, Rect2(14, 8, iw - hw - GAP - 28, UI.HEAD_H), "")
	_after_head.add_theme_color_override("font_color", Pal.GOOD)
	for k in range(AFF_ROWS):
		_after.append(UI.label(_after_box, Rect2(14, 34 + k * AFF_H, iw - hw - GAP - 28, AFF_H), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	_b_note = UI.label(_bench, Rect2(BP, BOX_Y + BOX_H + 10, iw, 26), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var by: float = bh - BP - BTN_H
	_b_block = UI.label(_bench, Rect2(BP, by - 30, iw, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var uw: float = roundf(iw * 0.58)
	_use = UI.button(_bench, Rect2(BP, by, uw, BTN_H), true)
	_use.pressed.connect(_on_use)
	_lift = UI.button(_bench, Rect2(BP + uw + GAP, by, iw - uw - GAP, BTN_H), false)
	_lift.pressed.connect(_on_lift)
	for k in range(3):
		_b_lines.append(UI.label(_bench, Rect2(BP, 44 + k * 32, iw, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))


func _build_shed(x: float, sw: float, sh: float) -> void:
	_shed = UI.panel(self, Rect2(x, LOW_Y, sw, sh), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = sw - 2 * BP
	_seeds_head = UI.head(_shed, Rect2(BP, 12, iw, UI.HEAD_H), Words.A69["l_seeds"])
	for k in range(Data.SEEDS69_ORDER.size()):
		_seeds.append(_shed_row(Rect2(BP, 40 + k * (SEED_ROW_H + SEED_GAP), iw, SEED_ROW_H), str(Data.SEEDS69_ORDER[k]), true))
	var ly: float = 40 + Data.SEEDS69_ORDER.size() * (SEED_ROW_H + SEED_GAP) + 8
	_lifted_head = UI.head(_shed, Rect2(BP, ly, iw, UI.HEAD_H), Words.A69["l_lifted"])
	for k in range(LIFT_ROWS):
		_lifted.append(_shed_row(Rect2(BP, ly + 26 + k * (SEED_ROW_H + SEED_GAP), iw, SEED_ROW_H), "", false))
	_lifted_none = UI.label(_shed, Rect2(BP, ly + 26, iw, SEED_ROW_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_shed_note = UI.label(_shed, Rect2(BP, sh - BP - 24, iw, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


func _shed_row(r: Rect2, key: String, is_seed: bool) -> Dictionary:
	var b := Button.new()
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_ALL
	_shed.add_child(b)
	var row := {"button": b, "key": key, "seed": is_seed}
	row["name"] = UI.label(b, Rect2(12, 2, r.size.x - 80, r.size.y - 4), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	row["count"] = UI.label(b, Rect2(r.size.x - 72, 2, 60, r.size.y - 4), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	b.pressed.connect(_press_shed.bind(row))
	return row


# ------------------------------------------------------------------ reads

static func seed_name(key: String) -> String:
	return str(Words.E69["seeds"].get(key, key))


## What a seed's harvest does, long to short: "Adds an element: fire", "Takes an affix off", "Raises an affix a tier".
static func craft_forms(key: String) -> Array:
	var sd: Dictionary = Data.SEEDS69.get(key, {})
	match str(sd.get("craft", "")):
		"element":
			var el: Array = Words.E69["elements"].get(str(sd.get("el", "")), ["", ""])     # (fix 69) the forms stored, not cased in code
			return [Words.A69["l_craft_el"] % str(el[0]), Words.A69["l_craft_el_short"] % str(el[0])]
		"remove":
			return [Words.A69["l_craft_off"], Words.A69["l_craft_off_short"]]
		"tier":
			return [Words.A69["l_craft_tier"], Words.A69["l_craft_tier_short"]]
	return [""]


## The harvest on the Bench: the picked plot's when it's ready, else the lifted one picked, else "".
func harvest_key() -> String:
	if sel_plot >= 0:
		return str(sim.e69_plot(sel_plot).get("seed", "")) if sim.e69_plot_ready(sel_plot) else ""
	return sel_lifted if int(sim.e69["lifted"].get(sel_lifted, 0)) > 0 else ""


## The pieces a harvest can work on: what's worn first, then the stash's gear by worth; never a unique, a set piece,
## issued kit or a mythic (their lines are their own). An element only where it fits and isn't there.
func pieces(key: String) -> Array:
	var out: Array = []
	for slot in Data.SLOTS:
		var it = sim.equipped.get(slot)
		if it != null and _takes(it, key):
			out.append(it)
	var rest: Array = sim.stash.filter(func(it): return str(it.get("slot", "")) in Data.SLOTS and _takes(it, key))
	rest.sort_custom(func(a, b): return float(a.get("value", 0)) > float(b.get("value", 0)))
	return out + rest


func _takes(it: Dictionary, key: String) -> bool:
	if Items.is_mag(it) or it.has("unique") or it.has("set") or it.get("issued", false) or it.get("mythic", false) or Array(it.get("affixes", [])).is_empty():
		return false
	if str(Data.SEEDS69.get(key, {}).get("craft", "")) == "element":
		var bl: Dictionary = Words.E69["block"]
		return not (sim.e69_craft_block(key, int(it["id"]), "", sel_plot) in [bl["has_el"], bl["no_room"], bl["fixed"], bl["not_gear"], bl["no_item"]])
	return true


func _worn(it: Dictionary) -> bool:
	for slot in Data.SLOTS:
		var w = sim.equipped.get(slot)
		if w != null and int(w["id"]) == int(it["id"]):
			return true
	return false


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	if sim == null:
		return
	var open: int = sim.e69_plots_open()
	if sel_plot >= open:
		sel_plot = 0 if open > 0 else -1
	if sel_plot < 0 and int(sim.e69["lifted"].get(sel_lifted, 0)) <= 0:
		sel_plot = 0 if open > 0 else -1
		sel_lifted = ""
	var plots: Array = []
	for p in range(open):
		plots.append([sim.e69_plot(p).get("seed", ""), sim.e69_plot_left(p)])
	var sig := "%s|%d|%s|%d|%s|%s|%s|%s|%d|%s|%s" % [str(plots), sel_plot, sel_lifted, sel_piece, sel_stat, str(sim.e69["shed"]), str(sim.e69["lifted"]), str(sim.e69_allot_watered()), sim.deepest_cleared_level(), str(sim.stash.size()), str(Data.SLOTS.map(func(sl): return sim.equipped.get(sl).get("affixes", []) if sim.equipped.get(sl) != null else []))]
	if sig == _shown:
		return
	_shown = sig
	_show_banner(open)
	_show_plots(open)
	_show_bench()
	_show_shed()


func _show_banner(open: int) -> void:
	var water: bool = sim.e69_allot_watered()
	UI.fit(_sub, [Words.A69["l_water"] % [open, "" if open == 1 else "s"] if water else Words.A69["l_dry"], Words.A69["l_water_short"] if water else Words.A69["l_dry_short"]])
	_sub.add_theme_color_override("font_color", Pal.TEXT if water else Pal.WARN)
	var nxt: int = sim.e69_next_plot_reach()
	var most: int = sim.e69_plots_most()
	UI.fit(_count, ["%s · %s" % [Words.A69["l_count"] % [open, most], Words.A69["l_next"] % nxt] if nxt >= 0 else Words.A69["l_count"] % [open, most], Words.A69["l_count"] % [open, most]])
	var cw: float = ceilf(UI.text_width(_count, _count.text)) + 28.0
	_count_pill.position.x = _w - BP - cw
	_count_pill.size.x = cw
	_count.size.x = cw - 24
	_count.position.x = 12


func _show_plots(open: int) -> void:
	for k in range(PLOTS):
		var p: Dictionary = _plots[k]
		var b: Button = p["button"]
		var on: bool = k < open
		b.disabled = not on
		UI.fit(p["n"], [Words.A69["l_plot"] % (k + 1)])
		p["track"].visible = false
		p["state"].add_theme_color_override("font_color", Pal.TEXT)
		var line: Color = Pal.CARD_LINE
		if not on:
			UI.fit(p["name"], [Words.A69["l_shut"]])
			p["name"].add_theme_color_override("font_color", Pal.TEXT_3)
			var at: int = int(Data.ALLOT69_PLOT_REACH[k]) if k < Data.ALLOT69_PLOT_REACH.size() else -1
			UI.fit(p["craft"], [Words.A69["l_opens_at"] % at, Words.A69["l_opens_short"] % at])
			p["state"].text = ""
		else:
			var key: String = str(sim.e69_plot(k).get("seed", ""))
			p["name"].add_theme_color_override("font_color", Pal.TEXT)
			if key == "":
				UI.fit(p["name"], [Words.A69["l_empty"]])
				UI.fit(p["craft"], [Words.A69["l_plant_from"]])
				UI.fit(p["state"], [Words.A69["l_plant"]])
				p["state"].add_theme_color_override("font_color", Pal.ACCENT)
			else:
				UI.fit(p["name"], [seed_name(key)])
				UI.fit(p["craft"], craft_forms(key))
				var left: int = sim.e69_plot_left(k)
				var runs: int = int(Data.SEEDS69[key]["runs"])
				p["track"].visible = true
				var frac: float = clampf(1.0 - float(left) / maxf(1.0, float(runs)), 0.0, 1.0)
				p["fill"].size.x = maxf(8.0, p["track"].size.x * frac)
				p["fill"].add_theme_stylebox_override("panel", UI.box(Pal.GOOD if left == 0 else Pal.ACCENT, 4))
				if left == 0:
					UI.fit(p["state"], [Words.A69["l_ready"]])
					p["state"].add_theme_color_override("font_color", Pal.GOOD)
					line = Pal.GOOD
				else:
					UI.fit(p["state"], [Words.A69["l_left"] % [left, "" if left == 1 else "s"], "%d run%s" % [left, "" if left == 1 else "s"]])
		var picked: bool = on and k == sel_plot
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
			var bx := UI.box(Pal.SELECT if st == "hover" else (Pal.PANEL if not on else Pal.CARD), 8, 2 if picked else 1, (Pal.GOOD if line == Pal.GOOD else Pal.ACCENT) if picked else line)
			b.add_theme_stylebox_override(st, bx)


func _show_bench() -> void:
	var key: String = harvest_key()
	var piece_view: bool = key != ""
	for c in [_b_cell, _b_name, _b_line, _b_other, _now_box, _after_box, _b_note, _b_block, _use, _lift]:
		c.visible = piece_view
	for l in _b_lines:
		l.visible = not piece_view
	if not piece_view:
		_show_bench_words()
		return
	var from_plot: bool = sel_plot >= 0
	_b_head.text = (Words.A69["l_bench_plot"] % (sel_plot + 1) if from_plot else Words.A69["l_bench_lifted"] % seed_name(key)).to_upper()
	UI.fit(_b_head, [_b_head.text, Words.A69["l_bench"].to_upper()])
	var ps: Array = pieces(key)
	if ps.is_empty():
		for c in [_b_cell, _b_name, _b_line, _b_other, _now_box, _after_box, _b_note]:
			c.visible = false
		_b_lines[0].visible = true
		UI.fit(_b_lines[0], [Words.A69["l_no_piece"]])
		_use.disabled = true
		UI.fit_button(_use, [Words.A69["l_use"] if not from_plot else Words.A69["l_lift_use"]])
		_lift.visible = from_plot
		UI.fit_button(_lift, [Words.A69["l_lift"]])
		_lift.disabled = false
		UI.fit(_b_block, [""])
		return
	sel_piece = clampi(sel_piece, 0, ps.size() - 1)
	var it: Dictionary = ps[sel_piece]
	_b_cell.show_item(it, false, PIECE)
	UI.fit(_b_name, [Items.full_name(it)])
	UI.fit(_b_line, ["%s · %s · item level %d" % [Words.A69["l_worn"] if _worn(it) else Words.A69["l_in_stash"], Items.rarity_name(it), Items.ilvl(it)], "%s · item level %d" % [Items.rarity_name(it), Items.ilvl(it)]])
	_b_other.disabled = ps.size() < 2
	UI.fit_button(_b_other, [Words.A69["l_other"], Words.A69["l_other_short"]])
	# the stat: a take-off or a raise needs one; the first it can work on
	var sd: Dictionary = Data.SEEDS69[key]
	var needs_stat: bool = str(sd["craft"]) != "element"
	var affs: Array = it.get("affixes", [])
	if needs_stat:
		var stats: Array = affs.map(func(a): return str(a["stat"]))
		if not (sel_stat in stats) or sim.e69_craft_block(key, int(it["id"]), sel_stat, sel_plot) not in ["", Words.E69["block"]["no_harvest"]]:
			sel_stat = ""
			for st in stats:
				if sim.e69_craft_block(key, int(it["id"]), str(st), sel_plot) == "":
					sel_stat = str(st)
					break
			if sel_stat == "" and not stats.is_empty():
				sel_stat = str(stats[0])
	else:
		sel_stat = ""
	var pv: Dictionary = sim.e69_craft_preview(key, int(it["id"]), sel_stat)
	var before: Array = Items.affix_lines({"affixes": pv.get("before", affs)}, false, true)
	var after: Array = Items.affix_lines({"affixes": pv.get("after", affs)}, false, true)
	for k in range(AFF_ROWS):
		var b: Button = _now[k]
		b.visible = k < before.size()
		if not b.visible:
			continue
		UI.fit_button(b, [str(before[k])])
		var gone: bool = not (str(before[k]) in after)
		var picked: bool = needs_stat and k < affs.size() and str(affs[k]["stat"]) == sel_stat
		b.disabled = not needs_stat
		var tone: Color = Pal.BAD if gone else Pal.TEXT
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
			var bx := UI.box(Pal.SELECT if (st == "hover" and needs_stat) or picked else Color(0, 0, 0, 0), 4, 1 if picked else 0, Pal.ACCENT if picked else Color(0, 0, 0, 0))
			bx.content_margin_left = 8
			b.add_theme_stylebox_override(st, bx)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(c, tone)
	UI.fit(_after_head, [(Words.A69["l_after"] % seed_name(key)).to_upper(), Words.A69["l_after_short"].to_upper()])
	for k in range(AFF_ROWS):
		var l: Label = _after[k]
		if k >= after.size():
			l.text = ""
			continue
		var fresh: bool = not (str(after[k]) in before)
		UI.fit(l, [str(after[k])])                 # a new or raised line in the green (the board's)
		l.add_theme_color_override("font_color", Pal.GOOD if fresh else Pal.TEXT)
	UI.fit(_b_note, [Words.A69["l_sure"] if not needs_stat else Words.A69["l_sure_pick"], Words.A69["l_sure_short"]])
	var block: String = sim.e69_craft_block(key, int(it["id"]), sel_stat, sel_plot)
	UI.fit(_b_block, [block, ""])
	_use.disabled = block != ""
	UI.fit_button(_use, [Words.A69["l_lift_use"] if from_plot else Words.A69["l_use"]])
	UI.style_button(_use, block == "")
	_lift.visible = from_plot
	UI.fit_button(_lift, [Words.A69["l_lift"]])
	_lift.disabled = false


## An empty or a growing plot (or none open): its words in the piece's place.
func _show_bench_words() -> void:
	var lines: Array = ["", "", ""]
	if sel_plot < 0:
		_b_head.text = Words.A69["l_bench"].to_upper()
		lines[0] = Words.A69["l_bench_none"]
	else:
		var key: String = str(sim.e69_plot(sel_plot).get("seed", ""))
		if key == "":
			_b_head.text = (Words.A69["l_plot"] % (sel_plot + 1) + " · " + Words.A69["l_empty"]).to_upper()
			var any: bool = Data.SEEDS69_ORDER.any(func(sk): return int(sim.e69["shed"].get(sk, 0)) > 0)
			lines[0] = Words.A69["l_plant_how"] if any else Words.A69["l_no_seeds"]
			lines[1] = Words.A69["l_seeds_from"]
		else:
			var left: int = sim.e69_plot_left(sel_plot)
			_b_head.text = (Words.A69["l_plot"] % (sel_plot + 1) + " · " + seed_name(key)).to_upper()
			lines[0] = Words.A69["l_growing"] % [left, "" if left == 1 else "s"]
			lines[1] = str(craft_forms(key)[0]) + "."
			if not sim.e69_allot_watered():
				lines[2] = Words.A69["l_dry"]
	for k in range(_b_lines.size()):
		UI.fit(_b_lines[k], [lines[k]])


func _show_shed() -> void:
	var planting: bool = sel_plot >= 0 and sel_plot < sim.e69_plots_open() and str(sim.e69_plot(sel_plot).get("seed", "")) == ""
	for r in _seeds:
		var n: int = int(sim.e69["shed"].get(r["key"], 0))
		UI.fit(r["name"], [("%s · %s" % [Words.A69["l_plant_word"], seed_name(r["key"])]) if planting and n > 0 else seed_name(r["key"]), seed_name(r["key"])])
		r["count"].text = "×%d" % n
		r["name"].add_theme_color_override("font_color", Pal.TEXT if n > 0 else Pal.TEXT_3)
		r["count"].add_theme_color_override("font_color", Pal.TEXT if n > 0 else Pal.TEXT_3)
		r["button"].disabled = not (planting and n > 0)
		_row_style(r["button"], false, planting and n > 0)
	var lifted: Array = Data.SEEDS69_ORDER.filter(func(sk): return int(sim.e69["lifted"].get(sk, 0)) > 0)
	for k in range(LIFT_ROWS):
		var r: Dictionary = _lifted[k]
		r["button"].visible = k < lifted.size()
		if not r["button"].visible:
			continue
		r["key"] = str(lifted[k])
		UI.fit(r["name"], [seed_name(r["key"])])
		r["count"].text = "×%d" % int(sim.e69["lifted"][r["key"]])
		r["button"].disabled = false
		_row_style(r["button"], sel_plot < 0 and sel_lifted == r["key"], true)
	_lifted_none.visible = lifted.is_empty()
	UI.fit(_lifted_none, [Words.A69["l_lifted_none"]])
	UI.fit(_shed_note, [Words.A69["l_shed_note"] % int(Data.SEEDS69["marrow"]["runs"]), Words.A69["l_shed_note_short"]])


func _row_style(b: Button, on: bool, live: bool) -> void:
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UI.box(Pal.SELECT if (st == "hover" and live) else Pal.CARD, 4, 2 if on else (1 if live else 0), Pal.ACCENT if on else Pal.CARD_LINE))


# ------------------------------------------------------------------ acting

func _pick_plot(k: int) -> void:
	sel_plot = k
	sel_lifted = ""
	sel_piece = 0
	sel_stat = ""
	_shown = ""
	show_state(sim)


func _press_shed(row: Dictionary) -> void:
	if sim == null:
		return
	if row["seed"]:
		if sel_plot >= 0 and sim.e69_plant(sel_plot, str(row["key"])):
			_shown = ""
			acted.emit()
		return
	sel_plot = -1
	sel_lifted = str(row["key"])
	sel_piece = 0
	sel_stat = ""
	_shown = ""
	show_state(sim)


func _other_piece() -> void:
	sel_piece += 1
	if sel_piece >= pieces(harvest_key()).size():
		sel_piece = 0
	sel_stat = ""
	_shown = ""
	show_state(sim)


func _pick_stat(k: int) -> void:
	var ps: Array = pieces(harvest_key())
	if ps.is_empty():
		return
	var affs: Array = ps[clampi(sel_piece, 0, ps.size() - 1)].get("affixes", [])
	if k < affs.size():
		sel_stat = str(affs[k]["stat"])
		_shown = ""
		show_state(sim)


func _on_use() -> void:
	var key: String = harvest_key()
	var ps: Array = pieces(key)
	if key == "" or ps.is_empty():
		return
	var it: Dictionary = ps[clampi(sel_piece, 0, ps.size() - 1)]
	if sim.e69_craft(key, int(it["id"]), sel_stat, sel_plot):
		if sel_plot < 0 and int(sim.e69["lifted"].get(sel_lifted, 0)) <= 0:
			sel_lifted = ""
		_shown = ""
		acted.emit()


func _on_lift() -> void:
	if sel_plot >= 0 and sim.e69_lift(sel_plot):
		_shown = ""
		acted.emit()


# ------------------------------------------------------------------ for the tests

func plot_buttons() -> Array:
	return _plots.map(func(p): return p["button"])


func seed_buttons() -> Array:
	return _seeds.map(func(r): return r["button"])


func lifted_buttons() -> Array:
	return _lifted.map(func(r): return r["button"])


func use_button() -> Button:
	return _use


func lift_button() -> Button:
	return _lift


func stat_buttons() -> Array:
	return _now


func text_nodes() -> Array:
	var out: Array = [_kicker, _title, _sub, _count, _b_head, _seeds_head, _lifted_head, _lifted_none, _shed_note]
	for p in _plots:
		out.append_array([p["n"], p["name"], p["craft"], p["state"]])
	for r in _seeds:
		out.append_array([r["name"], r["count"]])
	for r in _lifted:
		if r["button"].visible:
			out.append_array([r["name"], r["count"]])
	for l in _b_lines:
		out.append(l)
	if _use.visible:
		out.append_array([_b_name, _b_line, _b_other, _now_head, _after_head, _b_note, _b_block, _use, _lift])
		for b in _now:
			if b.visible:
				out.append(b)
		out.append_array(_after)
	return out
