extends Panel
## The repeat's report (29 Oct, docs/design/trips.md 1): one card when they're back, over the Map - "Back from <site>",
## the runs and the time, chips for the cleared, the bails and the wounds, how it ended; the sums as tiles (Kills, Kept,
## Tins, Sold at the gate, Scrap, Materials, XP at its share, Levels); the kept finds as chips with why; each run's line
## folded under "Each run"; "Run it again" and "Done". The figures are Sim.repeat_totals of its runs.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Sim := preload("res://scripts/sim/sim.gd")

const W := 1018
const H := 844
const PAD := 24
const INNER := W - 2 * PAD
const LINE_H := 30
const LINES_ROWS := 6             # each run's lines, two columns of six
const KEPT_ROWS := 3
const BTN_W := 220

var sim
var unfolded := false
var title: Label
var sub: Label
var chips: Chips
var ended: Label
var tiles: Array = []
var kept_head: Label
var kept: Chips
var each: Button
var lines: Array[Label] = []
var note: Label
var again: Button
var done: Button
var _site := -1


func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, Pal.WARN))
	title = UI.label(self, Rect2(PAD, 16, INNER, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	sub = UI.label(self, Rect2(PAD, 58, INNER, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	chips = Chips.new(INNER * 0.6, 4)
	chips.position = Vector2(PAD, 94)
	add_child(chips)
	ended = UI.label(self, Rect2(PAD + INNER * 0.6 + 8, 94, INNER * 0.4 - 8, Chips.CHIP_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	tiles = UI.tile_row(self, PAD, 138, INNER, 4) + UI.tile_row(self, PAD, 138 + UI.TILE_H + 8, INNER, 4)
	var ky: float = 138 + 2 * UI.TILE_H + 8 + 20
	kept_head = UI.head(self, Rect2(PAD, ky, INNER, UI.HEAD_H), Words.REPEAT["kept_head"])
	kept = Chips.new(INNER, 12)
	kept.position = Vector2(PAD, ky + UI.HEAD_H + 6)
	add_child(kept)
	var ey: float = ky + UI.HEAD_H + 6 + KEPT_ROWS * (Chips.CHIP_H + Chips.ROW_GAP) + 14
	each = UI.button(self, Rect2(PAD, ey, 200, 40), false)
	each.pressed.connect(func():
		unfolded = not unfolded
		show_state(sim))
	@warning_ignore("integer_division")
	var cw: float = (INNER - 16) / 2.0
	for k in range(2 * LINES_ROWS):                 # two columns, no spare (the fix round, 30 Oct)
		var col: int = 0 if k < LINES_ROWS else 1
		var row: int = k % LINES_ROWS
		lines.append(UI.label(self, Rect2(PAD + col * (cw + 16), ey + 48 + row * LINE_H, cw, LINE_H - 2), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var by: float = H - PAD - Pal.BUTTON_H
	done = UI.button(self, Rect2(W - PAD - BTN_W, by, BTN_W, Pal.BUTTON_H), false)
	done.pressed.connect(_done)
	again = UI.button(self, Rect2(W - PAD - 2 * BTN_W - 12, by, BTN_W, Pal.BUTTON_H), true)
	again.pressed.connect(_again)
	note = UI.label(self, Rect2(PAD, by, W - 2 * PAD - 2 * BTN_W - 24, Pal.BUTTON_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	visible = false


func show_state(s) -> void:
	sim = s
	var rep: Dictionary = sim.repeat_report
	var was: bool = visible
	visible = not rep.is_empty() and not sim.away()
	if not visible:
		unfolded = false
		return
	if not was:
		unfolded = rep.get("runs", []).size() <= 2 * LINES_ROWS     # open when every run's line fits (the review: an empty card folded)
	_site = int(rep["site"])
	var site: String = Sim.repeat_place_name(rep)     # (BUILD61 review) a County place's own name, not its host site's
	var tot: Dictionary = Sim.repeat_totals(rep)
	var n: int = int(tot["runs"])
	UI.fit(title, [Words.REPEAT["title"] % Words.mid(site), Words.REPEAT["title"] % Words.mid(site.trim_prefix("The "))])
	UI.fit(sub, [Words.REPEAT["sub"] % [n, "" if n == 1 else "s", Fmt.clock(float(rep.get("time", 0.0)))]])
	var b: int = int(tot["bails"])
	var wn: int = int(tot["wounds"])
	chips.show_chips([{"forms": [Words.REPEAT["cleared"] % int(tot["cleared"])], "colour": Pal.GOOD},
		{"forms": [Words.REPEAT["bailed"] % [b, "" if b == 1 else "s"]], "colour": Pal.BAD if b > 0 else Pal.TEXT_2},
		{"forms": [Words.REPEAT["wounds"] % [wn, "" if wn == 1 else "s"]], "colour": Pal.WARN if wn > 0 else Pal.TEXT_2}], 1, true)
	var end_w: String = str(Words.REPEAT.get("ended_" + str(rep.get("ended", "done")), ""))
	UI.fit(ended, [end_w % str(rep.get("reason", "")) if end_w.contains("%s") else end_w])     # the reason it ended, said (the language pass), kept mid-sentence by the sim (U3: no lowered HP)
	var lv0: int = int(rep.get("lv0", 1))
	var lv1: int = int(rep.get("lv1", lv0))
	var sold: int = int(tot["sold"])
	var rows: Array = [
		[Words.REPEAT["kills"], [Fmt.group(int(tot["kills"]))]],
		[Words.REPEAT["kept"], [Fmt.group(int(tot["kept"]))]],
		[Words.REPEAT["tins"], Fmt.money_forms(float(tot["tins"]))],
		[Words.REPEAT["sold_row"], [Words.REPEAT["sold_val"] % [sold, Fmt.money(float(tot["sold_tins"]))], Words.REPEAT["sold_val"] % [sold, Fmt.money_k(float(tot["sold_tins"]))], "%d" % sold] if sold > 0 else [Words.REPEAT["none"]]],
		[Words.REPEAT["scrap"], [Fmt.group(int(tot["scrap"]))]],
		[Words.REPEAT["mats"], [Fmt.group(int(tot["mats"]))]],
		[Words.REPEAT["xp"] % int(round(float(rep.get("share", Data.REPEAT_XP[0])) * 100.0)), [Fmt.group(int(round(float(tot["xp"])))), Fmt.num(float(tot["xp"]))]],
		[Words.REPEAT["levels"], [Words.REPEAT["levels_same"] % lv1] if lv1 == lv0 else [Words.REPEAT["levels_up"] % [lv0, lv1]]],
	]
	for k in range(tiles.size()):
		UI.set_tile(tiles[k], str(rows[k][0]), rows[k][1])
	# the kept finds, by name and why, a count when more than one
	var by: Dictionary = {}
	var order: Array = []
	for kd in rep.get("kept", []):
		var key: String = "%s|%s" % [str(kd["name"]), str(kd["why"])]
		if not by.has(key):
			by[key] = {"name": str(kd["name"]), "why": str(kd["why"]), "rarity": int(kd.get("rarity", 0)), "n": 0}
			order.append(key)
		by[key]["n"] = int(by[key]["n"]) + 1
	order.sort_custom(func(x, y): return int(by[x]["rarity"]) > int(by[y]["rarity"]))     # the rarest first: what a full card leaves off is the commons
	var kc: Array = []
	for key in order:
		var e: Dictionary = by[key]
		var cnt: String = (" ×%d" % int(e["n"])) if int(e["n"]) > 1 else ""
		kc.append({"forms": ["%s · %s%s" % [e["name"], e["why"], cnt]], "colour": Pal.tone_color(Pal.rarity_tone(int(e["rarity"]))) if int(e["rarity"]) > 0 else Pal.TEXT_2})
	if kc.is_empty():
		kc.append({"forms": [Words.REPEAT["kept_none"]], "colour": Pal.TEXT_3})
	# never cut silently (the review): what doesn't fit is a count, the last chip
	kept.show_chips(kc, KEPT_ROWS, false)
	var fit_n: int = kept.shown()
	while fit_n < kc.size() and fit_n > 0:
		var more: Dictionary = {"forms": [Words.REPEAT["more"] % (kc.size() - (fit_n - 1))], "colour": Pal.TEXT_3}
		kept.show_chips(kc.slice(0, fit_n - 1) + [more], KEPT_ROWS, false)
		if kept.shown() == fit_n:
			break
		fit_n -= 1

	UI.fit_button(each, [Words.REPEAT["each_open"] if unfolded else Words.REPEAT["each"]])
	var runs: Array = rep.get("runs", [])
	for k in range(lines.size()):
		var l: Label = lines[k]
		l.visible = unfolded
		l.text = ""
		if not unfolded:
			continue
		var n_hidden: int = run_hidden(runs.size())     # past the lines: the latest shown, the first line says which aren't
		if n_hidden > 0 and k == 0:
			l.text = Words.REPEAT["not_shown_one"] if n_hidden == 1 else Words.REPEAT["not_shown"] % n_hidden
			l.add_theme_color_override("font_color", Pal.TEXT_3)
			continue
		var j: int = (n_hidden + k - 1) if n_hidden > 0 else k
		if j < 0 or j >= runs.size():
			continue
		var r: Dictionary = runs[j]
		var how: String = Words.REPEAT["run_out"] if bool(r.get("timed_out", false)) else (Words.REPEAT["run_bail"] if bool(r.get("bail", false)) else (Words.REPEAT["run_cleared"] if bool(r.get("cleared", false)) else Words.REPEAT["run_home"]))
		var kl: int = int(r.get("kills", 0))
		UI.fit(l, [Words.REPEAT["run_line"] % [int(r["n"]), how, kl, "" if kl == 1 else "s", Fmt.money(float(r.get("tins", 0.0)))], Words.REPEAT["run_line"] % [int(r["n"]), how, kl, "" if kl == 1 else "s", Fmt.money_k(float(r.get("tins", 0.0)))], "Run %d · %s" % [int(r["n"]), how]])
		l.add_theme_color_override("font_color", Pal.BAD if bool(r.get("bail", false)) else Pal.TEXT_2)
	var why: String = sim.repeat_block(_site)
	again.disabled = why != ""
	var cnt_n: int = sim.repeat_count()
	UI.fit_button(again, [Words.REPEAT["again"], (Words.REPEAT["button_short"] % cnt_n) if cnt_n > 0 else Words.REPEAT["button_full_short"]])
	UI.fit(note, [why, ""])
	UI.fit_button(done, [Words.REPEAT["done"]])


## The runs a report's lines leave out (the fix round, 30 Oct): none while every run has a line; past that the first line
## says which aren't shown and the rest show the latest.
static func run_hidden(n_runs: int) -> int:
	return 0 if n_runs <= 2 * LINES_ROWS else n_runs - (2 * LINES_ROWS - 1)


func _again() -> void:
	if sim == null or _site < 0:
		return
	sim.repeat_seen()
	sim.start_repeat(_site)
	acted.emit()


func _done() -> void:
	if sim != null:
		sim.repeat_seen()
		acted.emit()


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [title, sub, ended, kept_head, each, note, again, done]
	out.append_array(chips.text_nodes())
	out.append_array(kept.text_nodes())
	for t in tiles:
		out.append_array([t["key"], t["value"]])
	for l in lines:
		if l.visible and l.text != "":
			out.append(l)
	return out
