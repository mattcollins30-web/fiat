extends Control
## The Radio's fourth view, Kev's story (20 Oct, Matt: "where are the story beats explained or displayed once you
## complete a mission?"; the canvas "Fiat – The playtest batch", KevStory): the three beats down the left - its
## name, beaten or on now, his lines when its signal was made and when it was beaten - and on the right what's on now:
## the beat's papers held and wanted, or past the third, the depot again and what it's for.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")

const PAD := 20
const HEAD_H := Pal.BAND_H
const BODY_Y := HEAD_H + 8
const BODY_H := Pal.ROOM_H - BODY_Y
const GAP := 12
const SIDE_W := 520                 # what's on now
const LIST_W := Pal.GRID_W - SIDE_W - GAP
@warning_ignore("integer_division")
const BEAT_H := (BODY_H - 2 * GAP) / 3
const CP := 16
const LINE_H := 28
const QUOTE_LINES := 2              # a line of Kev's, over two at most

var sim
var _kicker: Label
var _headline: Label
var _unit: Label
var _sub: Label
var _beats: Array = []              # {panel, name, state, made: [Label], won: [Label]}
var _side: Panel
var _side_head: Label
var _side_lines: Array = []
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	UI.head_art(head, "The radio")
	_kicker = UI.label(head, Rect2(PAD, 8, 420, 24), "Radio · Kev's story", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, 200, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, 400, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(head, Rect2(PAD, 78, 820, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var iw: float = LIST_W - 2 * CP
	for k in range(Data.STORY_BEATS.size()):
		var p := UI.panel(self, Rect2(0, BODY_Y + k * (BEAT_H + GAP), LIST_W, BEAT_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		var c := {"panel": p}
		c["name"] = UI.label(p, Rect2(CP, 10, iw, 32), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["state"] = UI.label(p, Rect2(CP, 10, iw, 32), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
		c["made"] = []
		c["won"] = []
		for i in range(QUOTE_LINES):
			c["made"].append(UI.label(p, Rect2(CP, 48 + i * LINE_H, iw, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		for i in range(QUOTE_LINES):
			c["won"].append(UI.label(p, Rect2(CP, 48 + (QUOTE_LINES + i) * LINE_H + 6, iw, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_beats.append(c)
	_side = UI.panel(self, Rect2(LIST_W + GAP, BODY_Y, SIDE_W, BODY_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var sw: float = SIDE_W - 2 * CP
	_side_head = UI.head(_side, Rect2(CP, 14, sw, UI.HEAD_H), "")
	for i in range(9):
		_side_lines.append(UI.label(_side, Rect2(CP, 14 + UI.HEAD_H + 10 + i * LINE_H, sw, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))


func show_state(s) -> void:
	sim = s
	var held: Array = sim.story_held()
	var sig := "%d|%s|%s|%s" % [sim.story_beat, str(sim.story_at), str(held), str(sim.signals.map(func(x): return int(x.get("story", -1))))]
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
		UI.wrap(c["won"], str(w["won"]) if beaten else "")
		for l in c["made"] + c["won"]:
			l.add_theme_color_override("font_color", KEV)
		(c["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = STORY if on_now else Pal.CARD_LINE
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
		for l in c["made"] + c["won"]:
			if l.text != "":
				out.append(l)
	for l in _side_lines:
		if l.text != "":
			out.append(l)
	return out


func line_pairs() -> Array:
	var out: Array = [[_headline, _unit]]
	for c in _beats:
		out.append([c["name"], c["state"]])
	return out
