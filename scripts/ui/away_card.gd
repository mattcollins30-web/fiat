extends Panel
## The runner away on a repeat (29 Oct, docs/design/trips.md 1): a small card at the rail's foot - the site and the run
## out of how many, a bar for the lot, the time left at the pace so far, the bails so far, and "Bring them back" (home
## after the run out). main.gd lays the rail's rows above it while it shows.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const H := 212                     # the card's height; the rail's rows share what's above it
const PAD := 16
const BAR_H := 8
const BTN_H := 44

var sim
var head: Label
var where: Label
var track: Panel
var fill: Panel
var left_l: Label
var bails_l: Label
var kit_l: Label                   # "The kit's with them": the lock said once, where the player looks (the review)
var bring: Button


func _init() -> void:
	size = Vector2(Pal.RAIL_W, H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.WARN))
	var w: float = Pal.RAIL_W - 2 * PAD
	head = UI.label(self, Rect2(PAD, 10, w, 22), Words.REPEAT["away_head"], "Medium", Pal.CELL_TEXT - 2, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT, false)
	where = UI.label(self, Rect2(PAD, 34, w, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	track = UI.panel(self, Rect2(PAD, 70, w, BAR_H), UI.box(Pal.TRACK, 4))
	fill = UI.panel(self, Rect2(PAD, 70, 0, BAR_H), UI.box(Pal.WARN, 4))
	left_l = UI.label(self, Rect2(PAD, 84, w * 0.6, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	bails_l = UI.label(self, Rect2(PAD + w * 0.6, 84, w * 0.4, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	kit_l = UI.label(self, Rect2(PAD, 110, w, 24), Words.REPEAT["away_kit"], "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	bring = UI.button(self, Rect2(PAD, H - PAD - BTN_H, w, BTN_H), false)
	bring.pressed.connect(_bring)
	visible = false


func show_state(s) -> void:
	sim = s
	visible = sim.away()
	if not visible:
		return
	var p: Dictionary = sim.repeat_progress()
	var site: String = str(Data.TIERS[int(p["site"])]["name"])
	if int(p["of"]) > 0:
		UI.fit(where, [Words.REPEAT["away_where"] % [site, int(p["n"]), int(p["of"])], Words.REPEAT["away_where"] % [site.trim_prefix("The "), int(p["n"]), int(p["of"])], "Run %d of %d" % [int(p["n"]), int(p["of"])]])
	else:
		UI.fit(where, [Words.REPEAT["away_where_full"] % [site, int(p["n"])], Words.REPEAT["away_where_full_short"] % [site, int(p["n"])], Words.REPEAT["away_where_full_short"] % [site.trim_prefix("The "), int(p["n"])]])
	fill.size.x = track.size.x * clampf(float(p["share"]), 0.0, 1.0)     # the runs done, or till full the stash's fill
	if not bool(p["out"]):
		UI.fit(left_l, [Words.REPEAT["away_resting_first"] if bool(p.get("first", false)) else Words.REPEAT["away_resting"], "Resting"])
	elif float(p["left"]) >= 0.0:
		UI.fit(left_l, [Words.REPEAT["away_left"] % Fmt.mss(float(p["left"])), Fmt.mss(float(p["left"]))])
	else:
		UI.fit(left_l, [Words.REPEAT["away_left_full"], "Till full"])
	var b: int = int(p["bails"])
	UI.fit(bails_l, [Words.REPEAT["bails_none"] if b == 0 else Words.REPEAT["bails"] % [b, "" if b == 1 else "s"]])
	bails_l.add_theme_color_override("font_color", Pal.TEXT_2 if b == 0 else Pal.BAD)
	bring.disabled = bool(p["stop"])
	UI.fit_button(bring, [Words.REPEAT["coming"], "Coming back"] if bool(p["stop"]) else [Words.REPEAT["bring"], "Bring back"])


func _bring() -> void:
	if sim != null:
		sim.bring_back()
		acted.emit()


func text_nodes() -> Array:
	return [head, where, left_l, bails_l, kit_l, bring] if visible else []
