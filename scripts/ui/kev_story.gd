extends Control
## The Radio's fourth view, Kev's story (20 Oct, Matt: "where are the story beats explained or displayed once you
## complete a mission?"; the canvas "Fiat – The playtest batch", KevStory). Laid out as the mockup RadioDial's story
## (28 Oct, Matt: "the Radio looks crap"): the three beats in a row, each its name, beaten or on now, its three paper
## slots - held in the story blue, wanted dashed, the beats to come scrambled - and his lines when its signal was made
## and when it was beaten; under the row what's on now: the beat's papers held and wanted, or past the third, the
## depot again and what it's for.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Dashed := preload("res://scripts/ui/dashed.gd")

signal to_town                       # the Next strip's button (BUILD49 U, item 21): the Radio's Town tab

const PAD := 20
const HEAD_H := Pal.BAND_H
const BODY_Y := HEAD_H + 8
const BODY_H := Pal.ROOM_H - BODY_Y
const GAP := 12
const SIDE_H := 260                 # what's on now, under the row (316 → 260 for the last beat's Next strip, BUILD49 U item 21)
const NEXT_H := 70                  # the Next strip under the last beat's line
@warning_ignore("integer_division")
const BEAT_W := (Pal.GRID_W - 2 * GAP) / 3
const BEAT_H := BODY_H - SIDE_H - GAP
const CP := 16
const SLOT_TOP := 64
const SLOT_H := 88
const SLOT_GAP := 8
const LINE_H := 30
const QUOTE_TOP := SLOT_TOP + SLOT_H + 22
const QUOTE_LINES := 3              # a line of Kev's, over three at most in a beat's third of the row
const SIDE_LINE_W := 1000           # the side's words wrap short of the panel's width: a paragraph, not one long line

var sim
var _kicker: Label
var _headline: Label
var _unit: Label
var _sub: Label
var _beats: Array = []              # {panel, name, state, slots: [{box, dash, name, state}], made: [Label], won: [Label]}
var _side: Panel
var _side_head: Label
var _side_lines: Array = []
var _shown := ""
var _next: Panel                    # the Next strip (item 21)
var _next_head: Label
var _next_what: Label
var _next_wants: Label
var _next_btn: Button


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	UI.head_art(head, "The radio")
	_kicker = UI.label(head, Rect2(PAD, 8, 420, 24), "Radio · Kev's story", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, 200, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, 400, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(head, Rect2(PAD, 78, 820, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var iw: float = BEAT_W - 2 * CP
	var sw: float = (iw - 2 * SLOT_GAP) / 3.0
	for k in range(Data.STORY_BEATS.size()):
		var p := UI.panel(self, Rect2(k * (BEAT_W + GAP), BODY_Y, BEAT_W, BEAT_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		var c := {"panel": p}
		c["name"] = UI.label(p, Rect2(CP, 14, iw, 34), "", "SemiBold", Pal.FLOOR - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["state"] = UI.label(p, Rect2(CP, 14, iw, 34), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
		c["slots"] = []
		for i in range(3):
			var box := UI.panel(p, Rect2(CP + i * (sw + SLOT_GAP), SLOT_TOP, sw, SLOT_H), UI.box(Pal.CARD, 7, 1, Pal.CARD_LINE))
			var sl := {"box": box}
			sl["dash"] = Dashed.new(box.size)
			box.add_child(sl["dash"])
			sl["name"] = UI.label(box, Rect2(10, 16, sw - 20, 26), "", "SemiBold", Pal.CELL_TEXT - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			sl["state"] = UI.label(box, Rect2(10, 46, sw - 20, 22), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
			c["slots"].append(sl)
		c["made"] = []
		c["won"] = []
		for i in range(QUOTE_LINES):
			c["made"].append(UI.label(p, Rect2(CP, QUOTE_TOP + i * LINE_H, iw, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		for i in range(QUOTE_LINES):
			c["won"].append(UI.label(p, Rect2(CP, QUOTE_TOP + (QUOTE_LINES + i) * LINE_H + 14, iw, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_beats.append(c)
	# the story told (BUILD49 U, item 21; Matt: "Where is the county unlock after this ?"): under Kev's last line, the
	# town's next step - what it wants, and the button to the Town tab
	var lp: Panel = _beats[_beats.size() - 1]["panel"]
	_next = UI.panel(lp, Rect2(CP, BEAT_H - CP - NEXT_H, iw, NEXT_H), UI.box(Pal.CARD.blend(Color(Pal.ACCENT, 0.08)), 7, 1, Color(Pal.ACCENT, 0.6)))
	_next_head = UI.label(_next, Rect2(14, 6, iw - 170, 16), Words.U49_NEXT["head"], "Medium", Pal.CELL_TEXT - 3, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(_next_head, 1)
	_next_what = UI.label(_next, Rect2(14, 22, iw - 170, 24), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_next_wants = UI.label(_next, Rect2(14, 46, iw - 170, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_next_btn = UI.button(_next, Rect2(iw - 12 - 140, (NEXT_H - 42) / 2.0, 140, 42), true)
	_next_btn.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
	_next_btn.text = Words.U49_NEXT["town"]
	_next_btn.pressed.connect(func(): to_town.emit())
	_next.visible = false
	_side = UI.panel(self, Rect2(0, BODY_Y + BEAT_H + GAP, Pal.GRID_W, SIDE_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_side_head = UI.head(_side, Rect2(CP, 14, Pal.GRID_W - 2 * CP, UI.HEAD_H), "")
	for i in range(7):
		_side_lines.append(UI.label(_side, Rect2(CP, 14 + UI.HEAD_H + 10 + i * LINE_H, SIDE_LINE_W, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))


func show_state(s) -> void:
	sim = s
	var held: Array = sim.story_held()
	var sig := "%d|%s|%s|%s|%s|%s" % [sim.story_beat, str(sim.story_at), str(held), str(sim.signals.map(func(x): return int(x.get("story", -1)))), str(sim.rebuilt), str(sim.materials) + str(sim.key_items)]     # the Next strip's wants (item 21)
	if sig == _shown:
		return
	_shown = sig
	var n: int = Data.STORY_BEATS.size()
	var done: int = mini(sim.story_beat, n)
	_headline.text = "%d of %d" % [done, n]
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	UI.fit(_unit, ["beats of Kev's story", "beats"])
	UI.fit(_sub, ["Kev's working out who runs the lorries: three beats, each beat's three papers making its signal.", "Each beat's three papers make its signal."] if done < n
		else ["The story's told. The depot comes round again: the convoy, and once a Pitch, the lorry.", "The story's told; the depot comes round again."])
	var made_on: Array = sim.signals.map(func(x): return int(x.get("story", -1)))
	for k in range(n):
		var c: Dictionary = _beats[k]
		var b: Dictionary = Data.STORY_BEATS[k]
		var beaten: bool = k < sim.story_beat
		var on_now: bool = k == sim.story_now() and not beaten
		var known: bool = beaten or on_now
		var nm: String = "%d · %s" % [k + 1, str(b["name"])]
		c["name"].text = nm if known else "%d · %s" % [k + 1, Fmt.scramble(str(b["name"]))]     # what's to come stays on the air
		c["name"].add_theme_color_override("font_color", Pal.TEXT if known else Pal.TEXT_3)
		if beaten:
			c["state"].text = ("Beaten · %.1f h played" % float(sim.story_at[k])) if sim.story_at.has(k) else "Beaten"
			c["state"].add_theme_color_override("font_color", Pal.GOOD)
		elif on_now:
			c["state"].text = "Its signal held" if k in made_on else "On now · %d of 3 found" % held.size()
			c["state"].add_theme_color_override("font_color", Pal.ACCENT)
		else:
			c["state"].text = "To come"
			c["state"].add_theme_color_override("font_color", Pal.TEXT_3)
		var w: Dictionary = Words.STORY[k]
		var said_made: bool = beaten or (k in made_on)
		UI.wrap(c["made"], str(w["made"]) if said_made else "")
		var won_line: String = str(w["won"])
		if k == n - 1 and beaten:
			won_line = Words.U49_NEXT["kev_last"]     # his last line names the next step (item 21; the text waits for Matt's take)
		UI.wrap(c["won"], won_line if beaten else "")
		for l in c["made"] + c["won"]:
			l.add_theme_color_override("font_color", KEV)
		(c["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = STORY if on_now else Pal.CARD_LINE
		_show_slots(c, k, beaten, on_now, held)
	_show_next(n)
	# what's on now: the beat's papers, or the depot again past the third
	var lines: Array = []
	var beat: int = sim.story_now()
	var papers: Array = sim.story_papers(beat)
	var wanted: Array = papers.filter(func(x): return not (x in held))
	if sim.story_beat >= n:
		_side_head.text = "THE DEPOT AGAIN · %d OF 3 FOUND" % held.size()
		lines.append_array(_wrap_words("The convoy runs again. The depot's three papers make its signal; beating it is the lorry, counted once a Pitch, and after that the convoy's drops.", 4))
	else:
		_side_head.text = ("ON NOW · %s · %d OF 3 FOUND" % [str(Data.STORY_BEATS[beat]["name"]).to_upper(), held.size()])
		lines.append_array(_wrap_words("Its papers come off any signal you beat. The three together in the decoder make its signal: the site and crew fixed, the head at full strength.", 4))
	lines.append("")
	lines.append("Held: %s" % (", ".join(held).to_lower() if not held.is_empty() else "none yet"))
	lines.append("Wanted: %s" % (", ".join(wanted).to_lower() if not wanted.is_empty() else "none: decrypt them together"))
	for i in range(_side_lines.size()):
		var l: Label = _side_lines[i]
		if i < lines.size():
			UI.fit(l, [str(lines[i]), str(lines[i]).get_slice(":", 0)])
		else:
			l.text = ""
		l.add_theme_color_override("font_color", Pal.TEXT if i >= lines.size() - 2 else Pal.TEXT_2)


## The town's next step as the story ends (item 21): the first place on the road not yet built, what it wants and what's
## held of it. "" when every place runs.
static func town_next(s) -> String:
	for k in Words.U49_TOWN_ROAD:
		if int(s.rebuild_rank(str(k))) <= 0:
			return str(k)
	return ""


## What the next place wants, as "copper wire 6 of 20 · cable drums 9 of 10" (long to short).
static func wants_forms(s, key: String) -> Array:
	var cost: Dictionary = s.rebuild_cost(key)
	var parts: Array = []
	for m in cost:
		var nm: String = str(s.thing_label(str(m)))
		parts.append(Words.U49_NEXT["have"] % [nm.to_lower() if not Data.KEY_ITEMS.has(str(m)) else nm, int(s.held_of(str(m))), int(cost[m])])
	var out: Array = []
	for n in range(parts.size(), 0, -1):
		out.append(" · ".join(parts.slice(0, n)))
	return out if not out.is_empty() else [""]


func _show_next(n: int) -> void:
	var nk: String = town_next(sim)
	_next.visible = sim.story_beat >= n and nk != ""
	if not _next.visible:
		return
	UI.fit(_next_what, [Words.U49_NEXT["rebuild"] % Words.mid(str(Data.rebuild(nk)["name"])), str(Data.rebuild(nk)["name"])])
	UI.fit(_next_wants, wants_forms(sim, nk))


## A beat's three paper slots (28 Oct): the one on now its papers held in the story blue and the wanted dashed; a beaten
## one its three, decrypted - the last beat too, once the story's told (4 Nov, BUILD48 item 20, Matt: "story beat but
## still states wanted papers ?": its cards drew the depot again's round); only the "Depot again" panel says what's
## wanted then. One to come, three dashed, unread.
func _show_slots(c: Dictionary, k: int, beaten: bool, on_now: bool, held: Array) -> void:
	var names: Array = sim.story_papers(k)
	for i in range(c["slots"].size()):
		var sl: Dictionary = c["slots"][i]
		var nm: String = str(names[i]) if i < names.size() else ""
		var known: bool = beaten or on_now
		var is_held: bool = on_now and nm in held
		var used: bool = beaten
		var dashed: bool = not (is_held or used)
		sl["dash"].visible = dashed
		sl["dash"].set_colour(Color(STORY, 0.55) if on_now else Dashed.LINE)
		sl["box"].add_theme_stylebox_override("panel", UI.box(Pal.CARD.blend(Color(STORY, 0.1)), 7, 2, STORY) if is_held else (UI.box(Pal.CARD, 7, 1, Pal.CARD_LINE) if used else UI.box(Color(0, 0, 0, 0), 7)))
		_fit_name(sl["name"], nm if known else "?")
		sl["name"].add_theme_color_override("font_color", STORY if is_held else (Pal.TEXT if used else Pal.TEXT_3))
		UI.fit(sl["state"], ["held" if is_held else ("decrypted" if used else "wanted")] if known else [""])
		sl["state"].add_theme_color_override("font_color", STORY if is_held else Pal.TEXT_3)


## A paper's name at 15, 14 or 13 before it loses its "A" (28 Oct: a slot is a third of a beat's width).
func _fit_name(l: Label, nm: String) -> void:
	for sz in [Pal.CELL_TEXT - 1, Pal.CELL_TEXT - 2, Pal.CELL_TEXT - 3]:
		l.add_theme_font_size_override("font_size", sz)
		if UI.text_width(l, nm) <= l.size.x:
			l.text = nm
			return
	UI.fit(l, [nm, nm.trim_prefix("A ").trim_prefix("An ")])


const KEV := Color("f0a868")        # Kev's voice (the Radio's)
const STORY := Color("8fb3d9")      # Kev's story (the Radio's)


## Words over up to `n` lines of the side column's width.
func _wrap_words(text: String, n: int) -> Array:
	var out: Array = []
	var line := ""
	var probe: Label = _side_lines[0]
	for word in text.split(" ", false):
		var trial: String = word if line == "" else line + " " + word
		if line != "" and UI.text_width(probe, trial) > probe.size.x and out.size() < n - 1:
			out.append(line)
			line = word
		else:
			line = trial
	if line != "":
		out.append(line)
	return out


func text_nodes() -> Array:
	var out: Array = [_kicker, _headline, _unit, _sub, _side_head]
	for c in _beats:
		out.append_array([c["name"], c["state"]])
		for sl in c["slots"]:
			out.append_array([sl["name"], sl["state"]])
		for l in c["made"] + c["won"]:
			if l.text != "":
				out.append(l)
	for l in _side_lines:
		if l.text != "":
			out.append(l)
	if _next.visible:
		out.append_array([_next_head, _next_what, _next_wants, _next_btn])
	return out


func line_pairs() -> Array:
	var out: Array = [[_headline, _unit]]
	for c in _beats:
		out.append([c["name"], c["state"]])
	return out
