extends Control
## The Map's site card (2 Nov, BUILD46-S; docs/design/site_card.md, the canvas "Fiat – The Map's site card" round 3 with
## the designer's changes): one fixed layout - every block the same size and place on every site, only what it shows
## changes. Top to bottom: the picture with the figures standing in it (the gang in the site's picture, or the head in
## his own interior), the stage picker (BUILD55-U: "1/3 · 2/3 · 3/3", and "Head" on a zone's last site, in the old
## Gang / Head toggle's place - one control, the 0.12.2 playtest's item 1), you against them, what it takes, the fix
## chips that act, what you'll bring home, and you here. The buttons under it are missions.gd's, as before.

signal fix(act: String)                 # a fix chip pressed: "kit", "clinic", "meds", "rounds" or "site:<tier>"
signal view_changed                     # a stage or the Head picked on the picker (BUILD55-U): the Map shows it

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Items := preload("res://scripts/sim/items.gd")
const People := preload("res://scripts/ui/people.gd")
const RunView := preload("res://scripts/ui/run_view.gd")
const Run := preload("res://scripts/ui/run.gd")

const PAD := 20
const PIC_H := 190                      # the picture's fixed height (the design doc's "~200-350, fixed once")
const PICK_Y := 196                     # the stage picker, under the picture (BUILD55-U, layout A)
const PICK_H := 48
const SEG_GAP := 6
const PICKED_W := 128                   # "Picked" over "2/3 · level 3", at the row's right
const MATCH_Y := 250                    # you against them (BUILD55-U: under the picker, 196 before)
const FACE := 64
const SIDE_W := 150                     # a portrait's column, its name under it
const MID_X := 110                      # the verdict between: clear of both portraits
const HEAD_Y := PICK_Y                   # an order's place's head row, in the picker's slot (BUILD55-U: a site's head is the picker's Head)
const HEAD_H := 48
const GANG_FACE := 40                   # the head picked: his gang's face behind his, the count on it
const TAKES_Y := 346                    # what it takes
const TAKES_H := 150
const ROW_H := 24
const KEY_W := 150
const FIX_Y := 502                      # the fix chips
const FIX_H := 32
const FIX_GAP := 6
const FIX_MAX := 4
const HOME_Y := 540                     # what you'll bring home
const TILE_Y := 560
const TILE_H := 62
const TILE_GAP := 6
const ICON := 30
const HERE_Y := 628                     # you here, two rows
const BOTTOM := 672                     # missions.gd's note sits under this
const FIG_H := 92                       # a gang's figure standing in the picture
const HEAD_FIG_H := 112                 # the head, alone, a little nearer
const FIG_X := [0.56, 0.73, 0.9]        # the figures' feet across the picture, clear of the title
const SLOTS_MAX := 8                    # the rig's pouches drawn as slots; more say it in words
const WHY_UNDER := 0.6                  # the fix chips show at Risky and worse (missions.gd's, as the reasons were)
const MATERIAL_TONE := Color("d6c27a")

var W := 501.0
var INNER := 461.0
var sim
var site := -1
var head_view := false                  # the picker's Head picked: his den, his gang and him; else the picked stage's gang
var has_head := false
# the stage picker (BUILD55-U): a segment a stage and the Head's, "Picked" and the picked one's level beside them
var pick_box: Control
var segs: Array = []                    # {button, top, sub}: the three stages, then the Head
var picked_key: Label
var picked_val: Label
var gang_frame: Panel                   # the head picked: his gang's face, behind his
var gang_face: TextureRect
var gang_count: Label

# the picture
var pic: Control
var _art: TextureRect
var _fade: TextureRect
var _figs: Array = []                   # TextureRects
var kicker: Label
var title: Label
var sky_box: Panel
var sky: Label
var foot: Label
# you against them
var you_frame: Panel
var you_face: TextureRect
var you_name: Label
var them_frame: Panel
var them_face: TextureRect
var them_name: Label
var count_box: Panel
var count: Label
var verdict: Label
var odds_line: Label
# the head's row
var head_box: Panel
var head_face: TextureRect
var head_name: Label
var head_sub: Label
# what it takes
var takes_box: Panel
var keys: Array = []                    # Labels, a row each: you last, their fire, your fire, meds, rounds
var vals: Array = []
var bar_track: Panel
var bar_fill: Panel
var bar_tick: Panel
var slots: Array = []                   # Panels, the rig's pouches
# the fix chips
var chips: Array = []                   # Buttons
var no_fix: Label
# what you'll bring home
var home_head: Label
var tiles: Array = []                   # {panel, icon, text, edge}
# you here
var here: Label
var here_right: Label
var last: Label


func _init(w := 501.0) -> void:
	W = w
	INNER = w - 2 * PAD
	size = Vector2(W, BOTTOM)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_picture()
	_build_picker()
	_build_match()
	_build_head()
	_build_takes()
	_build_fix()
	_build_home()
	here = UI.label(self, Rect2(PAD, HERE_Y, INNER, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	here_right = UI.label(self, Rect2(PAD + INNER - 140, HERE_Y, 140, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	last = UI.label(self, Rect2(PAD, HERE_Y + 22, INNER, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)


func _build_picture() -> void:
	pic = Control.new()
	pic.size = Vector2(W, PIC_H)
	pic.clip_contents = true
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pic)
	UI.panel(pic, Rect2(0, 0, W, PIC_H), UI.box(Pal.BG, 0))
	_art = TextureRect.new()
	_art.size = pic.size
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.add_child(_art)
	for k in range(FIG_X.size()):
		var f := TextureRect.new()
		f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f.stretch_mode = TextureRect.STRETCH_SCALE
		f.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.visible = false
		pic.add_child(f)
		_figs.append(f)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.1), Color(Pal.CARD, 0.3), Color(Pal.CARD, 0.97)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	_fade = TextureRect.new()
	_fade.texture = gt
	_fade.size = pic.size
	_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fade.stretch_mode = TextureRect.STRETCH_SCALE
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.add_child(_fade)
	kicker = UI.label(pic, Rect2(PAD, 10, INNER - 170, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	title = UI.label(pic, Rect2(PAD, 34, INNER, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	sky_box = UI.panel(pic, Rect2(W - PAD - 160, 10, 160, 28), UI.box(Color(Pal.BG, 0.75), 6))
	sky = UI.label(sky_box, Rect2(8, 0, 144, 28), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, true)
	foot = UI.label(pic, Rect2(PAD, PIC_H - 28, INNER, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for l in [kicker, title, sky, foot]:
		UI.shadow(l)


## A portrait in a frame of its tone: the frame's panel, the face in it.
func _face(x: float, y: float) -> Array:
	var frame := UI.panel(self, Rect2(x - 2, y - 2, FACE + 4, FACE + 4), UI.box(Pal.BG, 8, 2, Pal.CARD_LINE))
	var t := People.rect(frame, Vector2(2, 2), FACE / 128.0)
	return [frame, t]


func _build_match() -> void:
	var lx: float = PAD + (SIDE_W - FACE) / 2.0
	var rx: float = PAD + INNER - SIDE_W + (SIDE_W - FACE) / 2.0
	var a := _face(lx, MATCH_Y + 2)
	you_frame = a[0]
	you_face = a[1]
	gang_frame = UI.panel(self, Rect2(rx - GANG_FACE + 8, MATCH_Y + 2 + FACE - GANG_FACE - 6, GANG_FACE + 4, GANG_FACE + 4), UI.box(Pal.BG, 6, 2, Pal.CARD_LINE))     # behind his (BUILD55-U)
	gang_face = People.rect(gang_frame, Vector2(2, 2), GANG_FACE / 128.0)
	gang_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var gb := UI.panel(gang_frame, Rect2(-10, -12, 38, 20), UI.box(Pal.ACCENT, 9))
	gang_count = UI.label(gb, Rect2(0, 0, 38, 20), "", "SemiBold", Pal.CELL_TEXT - 3, Pal.ACCENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
	gang_frame.visible = false
	var b := _face(rx, MATCH_Y + 2)
	them_frame = b[0]
	them_face = b[1]
	you_name = UI.label(self, Rect2(PAD, MATCH_Y + FACE + 6, SIDE_W, 22), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	them_name = UI.label(self, Rect2(PAD + INNER - SIDE_W, MATCH_Y + FACE + 6, SIDE_W, 22), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	count_box = UI.panel(them_frame, Rect2(FACE - 22, FACE - 18, 40, 22), UI.box(Pal.ACCENT, 10))
	count = UI.label(count_box, Rect2(0, 0, 40, 22), "", "SemiBold", Pal.CELL_TEXT - 2, Pal.ACCENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
	verdict = UI.label(self, Rect2(PAD + MID_X, MATCH_Y + 8, INNER - 2 * MID_X, 36), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	odds_line = UI.label(self, Rect2(PAD + MID_X, MATCH_Y + 44, INNER - 2 * MID_X, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)


func _build_head() -> void:
	head_box = UI.panel(self, Rect2(PAD, HEAD_Y, INNER, HEAD_H), UI.box(Pal.BG, 6))
	var hf := UI.panel(head_box, Rect2(6, 4, 40, 40), UI.box(Pal.PANEL, 6))
	head_face = People.rect(hf, Vector2.ZERO, 40 / 128.0)
	head_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	head_name = UI.label(head_box, Rect2(54, 3, INNER - 54 - 8, 22), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	head_sub = UI.label(head_box, Rect2(54, 24, INNER - 54 - 8, 20), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	head_box.visible = false                 # an order's place's row only (BUILD55-U); a site has the picker here


## The stage picker (BUILD55-U, the canvas StagesCard layout A): a segment a stage - "1/3 ✓" over "Cleared", "2/3" over
## "Not cleared", a shut one greyed with its reason - and "Head" on a zone's last site; "Picked" and the picked one's
## level at the row's right.
func _build_picker() -> void:
	pick_box = Control.new()
	pick_box.position = Vector2(PAD, PICK_Y)
	pick_box.size = Vector2(INNER, PICK_H)
	pick_box.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(pick_box)
	for k in range(Data.STAGES + 1):
		var b := UI.button(pick_box, Rect2(0, 0, 80, PICK_H), false)
		b.text = ""
		var top := UI.label(b, Rect2(0, 3, 80, 24), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
		var sub := UI.label(b, Rect2(0, 25, 80, 19), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
		b.pressed.connect(_seg_pressed.bind(k))
		segs.append({"button": b, "top": top, "sub": sub})
	picked_key = UI.label(pick_box, Rect2(INNER - PICKED_W, 2, PICKED_W, 18), Words.U55["picked"], "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	picked_val = UI.label(pick_box, Rect2(INNER - PICKED_W, 20, PICKED_W, 24), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT, false)


func _build_takes() -> void:
	takes_box = UI.panel(self, Rect2(PAD, TAKES_Y, INNER, TAKES_H), UI.box(Pal.BG, 6))
	var iw: float = INNER - 24
	var ys := [8, 8 + ROW_H + 18, 8 + 2 * ROW_H + 18, 8 + 3 * ROW_H + 18, 8 + 4 * ROW_H + 18]
	for k in range(5):
		keys.append(UI.label(takes_box, Rect2(12, ys[k], KEY_W, ROW_H), Words.SITE_CARD["keys"][k], "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		vals.append(UI.label(takes_box, Rect2(12, ys[k], iw, ROW_H), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false))
	UI.fit(keys[0], [Words.SITE_CARD["keys"][0], Words.SITE_CARD["key_last_short"]])     # "How long you last", else "Your time"
	bar_track = UI.panel(takes_box, Rect2(12, 8 + ROW_H + 4, iw, 10), UI.box(Pal.CARD_LINE, 5))
	bar_fill = UI.panel(bar_track, Rect2(0, 0, 0, 10), UI.box(Pal.GOOD, 5))
	bar_tick = UI.panel(bar_track, Rect2(0, -3, 2, 16), UI.box(Pal.TEXT, 0))
	for k in range(SLOTS_MAX):
		slots.append(UI.panel(takes_box, Rect2(0, ys[3] + 6, 26, 12), UI.box(Pal.GOOD, 3)))


func _build_fix() -> void:
	for k in range(FIX_MAX):
		var b := Button.new()
		b.position = Vector2(PAD, FIX_Y)
		b.size = Vector2(100, FIX_H)
		b.focus_mode = Control.FOCUS_ALL
		b.clip_text = false
		b.add_theme_font_override("font", UI.font("Medium", false))
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
		b.visible = false
		b.pressed.connect(_fix_pressed.bind(k))
		add_child(b)
		chips.append(b)
	no_fix = UI.label(self, Rect2(PAD, FIX_Y, INNER, FIX_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)


func _build_home() -> void:
	home_head = UI.label(self, Rect2(PAD, HOME_Y, INNER, 18), Words.SITE_CARD["home"], "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var tw: float = (INNER - 3 * TILE_GAP) / 4.0
	for k in range(4):
		var p := UI.panel(self, Rect2(PAD + k * (tw + TILE_GAP), TILE_Y, tw, TILE_H), UI.box(Pal.BG, 6))
		var edge := UI.panel(p, Rect2(0, 0, tw, TILE_H), UI.box(Color.TRANSPARENT, 6, 1, Pal.ACCENT))
		var ic := TextureRect.new()
		ic.position = Vector2((tw - ICON) / 2.0, 5)
		ic.size = Vector2(ICON, ICON)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(ic)
		var tx := UI.label(p, Rect2(4, 38, tw - 8, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
		tiles.append({"panel": p, "icon": ic, "text": tx, "edge": edge})


## A segment pressed (BUILD55-U): a stage picks it for Set off; the Head shows his fight. Either marks the site seen
## (its "New" goes from the Map's pin).
func _seg_pressed(k: int) -> void:
	if sim == null or site < 0 or order != "":
		return
	if k >= Data.STAGES:
		if not has_head or segs[k]["button"].disabled:
			return                               # shut till his site's 2/3 (§4)
		head_view = true
	else:
		if not sim.stage_open(site, k + 1):
			return
		sim.set_stage_pick(site, k + 1)
		head_view = false
	sim.mark_site_seen(site)
	view_changed.emit()


var _acts: Array = []
func _fix_pressed(k: int) -> void:
	if k < _acts.size():
		fix.emit(str(_acts[k]))


# ------------------------------------------------------------------ showing

## The card for site i; `why` is what the runner's short of (missions.gd's odds_reasons, each with its "act").
var _why: Array = []
func show_state(s, i: int, why: Array = []) -> void:
	sim = s
	site = i
	_why = why
	if order != "":
		order = ""                              # back to a site from an order's place (BUILD49 U, item 23)
		_art.modulate = Color.WHITE
		foot.tooltip_text = ""
		foot.add_theme_color_override("font_color", Pal.TEXT_2)
		for f in _figs:
			f.modulate = Color.WHITE
		for kk in range(keys.size()):
			keys[kk].add_theme_color_override("font_color", Pal.TEXT_2)
	head_box.visible = false                     # a site's head is the picker's Head (BUILD55-U)
	pick_box.visible = true
	var z: int = int(Data.TIERS[i]["zone"])
	var tiers: Array = Data.ZONES[z]["tiers"]
	var is_open: bool = sim.tier_open(i)
	var b: Dictionary = sim.boss_of(i)
	has_head = not b.is_empty()                  # a zone's last site: the picker's fourth segment
	var showing_head: bool = head_view and has_head and is_open
	_show_picker(i, z, is_open, showing_head)
	_show_picture(i, z, tiers.find(i) + 1, b, showing_head)     # (FIX55) the convoy's a signal's now: no convoy here
	_show_match(i, z, is_open, b, showing_head)
	_show_takes(i, is_open)
	_show_fix(i, is_open)
	_show_home(i, is_open, b, showing_head)
	_show_here(i)


func _show_picture(i: int, z: int, tier_n: int, b: Dictionary, showing_head: bool) -> void:
	var nm: String = str(Data.TIERS[i]["name"])
	var head_key: String = Items.slug(str(b.get("name", ""))) if showing_head else ""
	var plate: Texture2D = RunView.tex(head_key + "_plate") if head_key != "" and RunView.boss_pair(head_key) else null
	_art.texture = plate if plate != null else UI.place_texture(nm)     # the head's own interior; else the site's picture
	UI.fit(kicker, ["%s · Tier %d" % [Data.ZONES[z]["name"], tier_n], "Tier %d" % tier_n])
	UI.fit(title, [nm])
	title.add_theme_color_override("font_color", Pal.TEXT if sim.tier_open(i) else Pal.TEXT_3)
	UI.fit(sky, [sim.clock_words() + " · " + _sky_word(i), sim.clock_words()])
	# the figures: the head alone, or the gang - as many as fight at once, three at most
	var zone_key: String = RunView.ZONE_KEYS[mini(z, RunView.ZONE_KEYS.size() - 1)]
	var n: int = FIG_X.size() if head_key != "" else (mini(FIG_X.size(), maxi(1, int(sim.effective(i)["pool"]))) if sim.tier_open(i) else 0)
	for k in range(_figs.size()):
		var f: TextureRect = _figs[k]
		var t: Texture2D = null
		var him: bool = head_key != "" and k == FIG_X.size() - 1     # the head picked: his gang either side, him in the middle and in front (BUILD55-U)
		if k < n:
			t = RunView.tex("head_%s_stand" % head_key) if him else RunView.tex_of(["gang_%s_%s_stand" % [zone_key, "a" if k % 2 == 0 else "b"], "gang_stand"])
		f.texture = t
		f.visible = t != null
		if t == null:
			continue
		var u: Rect2 = RunView.used_of(t)
		if u.size.y <= 0.0:
			u = Rect2(Vector2.ZERO, t.get_size())
		var h: float = HEAD_FIG_H if him else FIG_H
		var sc: float = h / u.size.y
		f.size = t.get_size() * sc
		var fx: float = W * (FIG_X[1] if him else (FIG_X[[0, 2][k]] if head_key != "" else FIG_X[k]))
		f.position = Vector2(fx - (u.position.x + u.size.x / 2.0) * sc, PIC_H - 30 - u.end.y * sc)
	if showing_head and head_key != "":
		UI.fit(foot, [Words.U55["head_foot"]])     # "His gang first, then him." (BUILD55-U)
	else:
		UI.fit(foot, _foot_forms(i) if sim.tier_open(i) else [""])


## The sky's word for the chip: the weather when there is some, else night or day.
func _sky_word(i: int) -> String:
	var w: String = sim.fight_weather_of(i)
	if w != "":
		return str(Words.SKY.get(w.to_lower(), w.to_lower()))
	return Words.SKY["night"] if sim.is_night() else Words.SKY["day"]


## The picture's foot, long to short: the site's own line, then what the sky and the Radio's words do here ("Rain:
## searches slower"); the conditions alone when both won't fit, the first of them, the line alone last.
func _foot_forms(i: int) -> Array:
	var t: Dictionary = sim.effective(i)
	var parts: Array = []
	for nm in t["intel"]:
		var m: Dictionary = sim.modifier(str(nm))
		var w: String = str(m.get("words", "")).get_slice(", ", 0) if not m.is_empty() else ""
		parts.append(("%s: %s." % [str(nm), w]) if w != "" else "%s." % str(nm))
	var line: String = Words.site_line(str(Data.TIERS[i]["name"]), int(t["depth"])).get_slice(". ", 0).trim_suffix(".") + "."
	var clause: String = line.get_slice(", ", 0).trim_suffix(".") + "."     # a stage's long line to its first clause (BUILD55-U: the Hospital's 3/3)
	if parts.is_empty():
		return [line, clause]
	var conds: String = " ".join(parts)
	var out: Array = [line + " " + conds, conds]
	for n in range(parts.size() - 1, 0, -1):
		out.append(" ".join(parts.slice(0, n)))
	return out + [str(parts[0]).get_slice(":", 0) + ".", line, clause]


func _show_match(i: int, z: int, is_open: bool, b: Dictionary, showing_head: bool) -> void:
	People.show(you_face, sim.cls)
	UI.fit(you_name, ["The %s" % sim.cls, sim.cls] if sim.cls != "" else ["The runner"])
	var odds: float = sim.odds_now(i) if is_open else 0.0
	var read_in: bool = is_open and sim.odds_ready(i)
	if showing_head:
		var hr: Array = sim.head_odds_now(z)       # his own fight's odds as read so far (FIX55, review 1: the shell steps the read in
		odds = float(hr[1])                        # its own slot, main._read_odds; the card runs none): his gang, then him
		read_in = bool(hr[0])
	var tone: Color = Pal.tone_color("good" if odds >= 0.9 else ("warn" if odds >= 0.6 else "bad"))
	var them: String = Run.gang_face(z)
	var them_words: Array = [Words.SITE_CARD["the_gang"]]
	if showing_head:
		them = str(b["name"])
		them_words = [str(b["name"]), str(b["name"]).trim_prefix("The ")]
	People.show(them_face, them)
	UI.fit(them_name, them_words)
	count_box.visible = is_open and not showing_head
	if count_box.visible:
		count.text = "×%d" % int(sim.effective(i)["pool"])
	gang_frame.visible = showing_head     # his gang (×N) behind him (BUILD55-U)
	if gang_frame.visible:
		People.show(gang_face, Run.gang_face(z))
		gang_count.text = "×%d" % head_gang(i)
	for fr in [you_frame, them_frame]:
		(fr.get_theme_stylebox("panel") as StyleBoxFlat).border_color = tone if read_in else Pal.CARD_LINE
	(you_frame.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.GOOD
	for l in [verdict, odds_line]:
		l.tooltip_text = ""
	if not is_open:
		UI.fit(verdict, [Words.SITE_CARD["locked"]])
		verdict.add_theme_color_override("font_color", Pal.TEXT_3)
		var before: int = sim.site_before(i)
		var two: String = Words.U55["stage"] % [2, Data.STAGES]     # a site opens on the one before's 2/3 (BUILD55-U: "After Top Farm 2/3")
		var why: Array = [Words.A55_STAGE["level"] % sim.site_gate(i)] if sim.level_gated(i) and (Data.ZONES[z]["tiers"].find(i) == 0 or sim.stage_done(i - 1) >= 2) \
			else ([Words.U55["after_site"] % [Words.mid(str(Data.TIERS[before]["name"])), two], Words.U55["after_site_short"] % two] if before >= 0 else [""])
		UI.fit(odds_line, why)
		return
	UI.fit(verdict, [Words.odds_words(odds)])
	verdict.add_theme_color_override("font_color", tone if read_in else Pal.TEXT_3)
	UI.fit(odds_line, ["%s to clear" % Fmt.pct(odds)] if read_in else [Words.SITE_CARD["reading"]])
	# how the odds are read, said once on their hover (BUILD49 U, item 13: Matt's death at 100% - the read uses meds
	# under 40% HP, as the bot does)
	for l in [verdict, odds_line]:
		l.tooltip_text = Words.U49_DEATH["odds_tip"]
		l.mouse_filter = Control.MOUSE_FILTER_PASS


## The stage picker (BUILD55-U, the canvas StagesCard layout A and its Head card): the three stages in a row, each "1/3"
## over its state - "Cleared" with a tick, "Not cleared", or shut and greyed with stage_block's reason - the picked one
## amber; a fourth, "Head", on a zone's last site (shut "After 2/3", then "Free" or his price); "Picked" and the picked
## one's level at the row's right.
func _show_picker(i: int, z: int, is_open: bool, showing_head: bool) -> void:
	var n: int = Data.STAGES + (1 if has_head else 0)
	var w: float = floorf((INNER - PICKED_W - 8 - (n - 1) * SEG_GAP) / float(n))
	var pick: int = sim.stage_pick(i)
	var done: int = sim.stage_done(i)
	for k in range(segs.size()):
		var sg: Dictionary = segs[k]
		var bt: Button = sg["button"]
		bt.visible = k < n
		if not bt.visible:
			continue
		bt.position.x = k * (w + SEG_GAP)
		bt.size = Vector2(w, PICK_H)
		for l in [sg["top"], sg["sub"]]:
			l.size.x = w
		var on: bool
		var shut: bool
		var top: String
		var sub: Array
		var sub_tone: Color = Pal.TEXT_2
		if k < Data.STAGES:
			var s: int = k + 1
			var why: String = sim.stage_block(i, s)
			shut = why != ""
			on = is_open and not showing_head and s == pick
			top = Words.U55["stage"] % [s, Data.STAGES] + (" ✓" if done >= s else "")
			if done >= s:
				sub = [Words.U55["cleared"]]
				sub_tone = Pal.GOOD
			elif shut:
				sub = [why] + ([Words.U55["opens_short"] % int(why.get_slice(" ", why.get_slice_count(" ") - 1))] if why.begins_with(Words.A55_STAGE["level"].get_slice("%", 0)) else []) + [Words.SITE_CARD["locked"]]     # the site's own gate in full on the verdict's line
			else:
				sub = [Words.U55["not_cleared"], Words.U55["not_cleared_short"]]     # (FIX55, the language pass) "Open" when it won't fit
		else:
			var site_two: bool = sim.stage_done(i) >= 2
			shut = not is_open or not site_two
			on = showing_head
			top = Words.U55["head"] + (" ✓" if bool(sim.bosses_beaten[z]) else "")
			var cost: int = sim.head_fight_cost(z)
			if shut:
				sub = [Words.U55["after_site_short"] % (Words.U55["stage"] % [2, Data.STAGES])]
			elif cost > 0:
				sub = [Fmt.notes(cost), Fmt.group(cost)]
				sub_tone = Pal.BAD if sim.notes < cost else Pal.TEXT_2
			else:
				sub = [Words.U55["head_free"]]
				sub_tone = Pal.GOOD
		bt.disabled = shut
		UI.style_button(bt, on)
		UI.fit(sg["top"], [top, top.trim_suffix(" ✓")])
		UI.fit(sg["sub"], sub)
		sg["top"].add_theme_color_override("font_color", Pal.ACCENT_TEXT if on else (Pal.TEXT_3 if shut else Pal.TEXT))
		sg["sub"].add_theme_color_override("font_color", Pal.ACCENT_TEXT if on else (Pal.TEXT_3 if shut else sub_tone))
	var lv: int = sim.stage_level(i, Data.STAGE_OPENS if showing_head else pick)     # the head's level is his gate's, the 2/3 (FIX55b)
	var what: String = Words.U55["head"] if showing_head else Words.U55["stage"] % [pick, Data.STAGES]
	UI.fit(picked_val, [Words.U55["picked_line"] % [what, lv], Words.U55["picked_short"] % lv])
	picked_val.add_theme_color_override("font_color", Pal.ACCENT if is_open else Pal.TEXT_3)


## The head's gang (§4): half the site's gangs, at its 3/3 man - as the sim forms his fight.
func head_gang(i: int) -> int:
	return maxi(1, int(sim.head_fight_preview(int(Data.TIERS[i]["zone"])).get("pool", 1)))


## Words for a share, never the figure (the style guide: words over raw numbers).
static func share_words(x: float) -> String:
	for band in [[0.005, "none"], [0.2, "a little"], [0.4, "some"], [0.6, "half"], [0.85, "most"]]:
		if x < float(band[0]):
			return str(band[1])
	return "nearly all"


func _show_takes(i: int, is_open: bool) -> void:
	for l in keys + vals:
		l.visible = is_open
	bar_track.visible = is_open
	for p in slots:
		p.visible = false
	if not is_open:
		return
	var t: Dictionary = sim.effective(i)
	var iw: float = bar_track.size.x
	# you last: the fight against the run's clock, the tick at the fight's end
	var fight: float = sim.estimate(i)
	var clock: float = maxf(1.0, sim.clock_of(i))
	var span: float = maxf(fight, clock)
	var odds: float = sim.odds_now(i)
	var lasted: float = fight
	var forms: Array
	var tone: Color = Pal.GOOD
	if fight > clock:
		forms = [Words.SITE_CARD["over"] % [Fmt.mss(fight), Fmt.mss(clock)], Words.SITE_CARD["over_short"]]     # known without the odds
		lasted = clock
		tone = Pal.BAD
	elif not sim.odds_ready(i):
		forms = [Words.SITE_CARD["reading"]]
		tone = Pal.TEXT_3
	elif odds >= 0.5:
		forms = [Words.SITE_CARD["whole"] % Fmt.mss(fight), Words.SITE_CARD["whole_short"]]
		tone = Pal.GOOD if odds >= 0.9 else Pal.WARN
	else:
		var g: Dictionary = sim.odds_gap(i)
		lasted = clampf(float(g.get("lost_s", fight)), 0.0, fight)
		var lw: String = ("%d s" % roundi(lasted)) if lasted < 60.0 else Fmt.mss(lasted)
		forms = [Words.SITE_CARD["lasted"] % [lw, Fmt.mss(fight)], lw]
		tone = Pal.BAD
	# fitted beside its key, not across it (BUILD50-T: a fight of 12735:56 against the clock ran the value into "How long
	# you last" by 3 px, the line-pair check's red on the bot's act-two camp)
	var room0: float = vals[0].size.x - UI.text_width(keys[0], keys[0].text) - 16.0
	vals[0].text = UI.dots(str(forms.back()))
	for f in forms:
		if UI.text_width(vals[0], UI.dots(str(f))) <= room0:
			vals[0].text = UI.dots(str(f))
			break
	vals[0].add_theme_color_override("font_color", tone)
	bar_fill.size.x = iw * clampf(lasted / span, 0.0, 1.0) if sim.odds_ready(i) or fight > clock else 0.0
	(bar_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = tone
	bar_tick.position.x = clampf(iw * fight / span, 0.0, iw - 2.0)
	# their fire against your resist: the element that does most, else the physical and the armour
	var top := ""
	for ty in Data.ELEMENTS:
		if float(t.get("types", {}).get(ty, 0.0)) > 0.0 and (top == "" or float(t["types"][ty]) > float(t["types"][top])):
			top = ty
	if top != "":
		var r: float = sim.resist(top)
		var top_w: String = top.capitalize()     # sentence case, the values (fix 46, S7)
		UI.fit(vals[1], ["%s · you resist %s" % [top_w, share_words(r)], "%s · resist %s" % [top_w, share_words(r)], top_w])
		vals[1].add_theme_color_override("font_color", Pal.GOOD if r >= 0.4 else (Pal.WARN if r >= 0.2 else Pal.BAD))
	else:
		var mt: float = sim.mitigation()
		UI.fit(vals[1], ["Physical · your armour takes %s" % share_words(mt), "Physical · armour takes %s" % share_words(mt), "Physical"])
		vals[1].add_theme_color_override("font_color", Pal.GOOD if mt >= 0.4 else (Pal.WARN if mt >= 0.2 else Pal.BAD))
	# your fire against their resists: the type they shrug off most of, of what you fire
	var mine: Dictionary = sim.type_dps()
	var worst := ""
	var worst_r := 0.0
	for ty in mine:
		var rr: float = float(t.get("res", {}).get(ty, 0.0))
		if float(mine[ty]) > 0.0 and rr > worst_r:
			worst = str(ty)
			worst_r = rr
	if worst == "":
		UI.fit(vals[2], [Words.SITE_CARD["resist_none"]])
		vals[2].add_theme_color_override("font_color", Pal.GOOD)
	else:
		UI.fit(vals[2], ["%s · they resist %s" % [worst.capitalize(), share_words(worst_r)], "They resist %s" % share_words(worst_r)])
		vals[2].add_theme_color_override("font_color", Pal.WARN if worst_r < 0.4 else Pal.BAD)
	# meds in the rig, as slots while they're few enough to draw
	var cap: int = sim.med_capacity()
	var meds: int = sim.meds_carried()
	if cap > 0 and cap <= SLOTS_MAX:
		vals[3].text = ""
		var x: float = 12 + iw
		for k in range(cap - 1, -1, -1):
			var p: Panel = slots[k]
			x -= 26
			p.position.x = x
			x -= 4
			p.visible = true
			var full: bool = k < meds
			p.add_theme_stylebox_override("panel", UI.box(Pal.GOOD if full else Color.TRANSPARENT, 3, 0 if full else 1, Pal.TEXT_3))
	else:
		UI.fit(vals[3], ["%d of %d" % [meds, cap]] if cap > 0 else [Words.SITE_CARD["no_rig"]])
	vals[3].add_theme_color_override("font_color", Pal.BAD if meds == 0 else Pal.TEXT)
	# the rounds: what goes out against what the fight wants (builder R's plan read: rounds_read)
	var rd: Dictionary = rounds_read(sim, i)
	match str(rd["state"]):
		"short":
			UI.fit(vals[4], [Words.SITE_CARD["rounds_short"] % [Words.group(int(rd["have"])), Words.group(int(rd["want"]))], Words.SITE_CARD["rounds_ok"] % [Words.group(int(rd["have"])), Words.group(int(rd["want"]))]])
			vals[4].add_theme_color_override("font_color", Pal.BAD)
		"enough":
			UI.fit(vals[4], [Words.SITE_CARD["rounds_ok"] % [Words.group(int(rd["have"])), Words.group(int(rd["want"]))], Words.SITE_CARD["rounds_enough"]])
			vals[4].add_theme_color_override("font_color", Pal.GOOD)
		_:
			UI.fit(vals[4], [Words.SITE_CARD["rounds_none"]])
			vals[4].add_theme_color_override("font_color", Pal.TEXT_2)


## The rounds the run carries against what the fight wants: {state: "short"/"enough"/"none", have, want} - builder R's
## plan read (sim.rounds_read: the site's plan as the gate packs it, BUILD46-R; joined at merge 46).
static func rounds_read(s, i: int) -> Dictionary:
	var r: Array = s.rounds_read(i)
	if r.is_empty():
		return {"state": "none", "have": 0, "want": 0}
	return {"state": "short" if int(r[0]) < int(r[1]) else "enough", "have": int(r[0]), "want": int(r[1])}


## The fix chips: what's short, each a button that goes where it's fixed - the rounds' first, the site before last.
func fix_rows(i: int, is_open: bool) -> Array:
	if not is_open:
		return []
	var out: Array = []
	var rd: Dictionary = rounds_read(sim, i)
	if str(rd["state"]) == "short":
		out.append({"forms": [Words.SITE_CARD["fix_rounds"]], "colour": "bad", "act": "rounds"})     # the figures are the Rounds row's: said once (the language pass)
	if sim.odds_ready(i) and sim.odds_now(i) < WHY_UNDER:
		var first: Array = _why.filter(func(r): return str(r.get("act", "")).begins_with("site:"))
		for r in _why:
			if not str(r.get("act", "")).begins_with("site:") and not (r.get("act", "") == "rounds" and not out.is_empty() and out[0]["act"] == "rounds"):
				out.append(r)
		out.append_array(first)
	return out


## The chips' widths: the button's words and its padding (the fit check's 32).
func _chip_w(txt: String) -> float:
	return ceilf(UI.text_width(chips[0], txt)) + 32.0


func _show_fix(i: int, is_open: bool) -> void:
	var all_rows: Array = fix_rows(i, is_open)
	var green: Array = all_rows.filter(func(r): return str(r.get("act", "")).begins_with("site:"))
	var rows: Array = all_rows.filter(func(r): return not str(r.get("act", "")).begins_with("site:")).slice(0, FIX_MAX - green.size()) + green
	# the row is one line: every chip at its shortest must fit, the green one (where to grind) kept to the last; then
	# each takes its longest form that leaves the rest room for their shortest
	var short_w := func(r: Dictionary) -> float: return _chip_w(str(r["forms"].back()) + " ›")
	var total := func(rs: Array) -> float:
		var t := 0.0
		for r in rs:
			t += short_w.call(r)
		return t + FIX_GAP * maxf(0.0, rs.size() - 1)
	while rows.size() > 1 and total.call(rows) > INNER:
		var drop: int = rows.size() - 1
		while drop > 0 and str(rows[drop].get("act", "")).begins_with("site:"):
			drop -= 1
		rows.remove_at(drop)
	_acts = []
	var x: float = PAD
	var k := 0
	for r in rows:
		var b: Button = chips[k]
		var rest: float = total.call(rows.slice(k + 1)) + (float(FIX_GAP) if k + 1 < rows.size() else 0.0)
		var fitted: String = str(r["forms"].back()) + " ›"
		for f in r["forms"]:
			if x + _chip_w(str(f) + " ›") + rest <= PAD + INNER:
				fitted = str(f) + " ›"
				break
		var tone: Color = Pal.tone_color(str(r["colour"])) if r["colour"] is String else r["colour"]
		b.text = fitted
		b.size.x = _chip_w(fitted)
		b.position.x = x
		_chip_style(b, tone)
		b.visible = true
		_acts.append(str(r.get("act", "kit")))
		x += b.size.x + FIX_GAP
		k += 1
	for j in range(k, chips.size()):
		chips[j].visible = false
	no_fix.visible = k == 0
	UI.fit(no_fix, [Words.SITE_CARD["no_fix"]] if is_open and sim.odds_ready(i) else [""])


static func _chip_style(b: Button, tone: Color) -> void:
	var key := tone.to_html()
	if b.get_meta("chip_tone", "") == key:
		return
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var sb := UI.box(Color(tone, 0.28 if st in ["hover", "hover_pressed"] else 0.14), 6, 1, Color(tone, 0.55))
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, tone)
	b.set_meta("chip_tone", key)


func _show_home(i: int, is_open: bool, b: Dictionary, showing_head: bool) -> void:
	var t: Dictionary = sim.effective(i)
	var p_odds: float = sim.paper_odds(i)
	var waits: Array = sim.waits_at(i)
	var mk: String = str(Data.SITE_MATERIAL[i]) if i < Data.SITE_MATERIAL.size() else ""
	var rows: Array = []
	rows.append({"icon": "res://art/crates/cardboard.png", "forms": [Words.SITE_CARD["gear"] % int(sim.wear_of(int(t["level"]))), "Level %d" % int(sim.wear_of(int(t["level"])))], "colour": Pal.TEXT})
	# the second: a head's thing left here (it turns up on the next clear), the head's own when he's shown, else scrap
	if not waits.is_empty():
		var nm: String = sim.room_thing(str(waits[0]))
		rows.append({"icon": "res://art/items/%s.png" % Items.slug(nm), "forms": _thing_forms(nm), "colour": Pal.WARN, "edge": true, "tip": Words.SITE_CARD["left_tip"]})
	elif showing_head and not b.is_empty() and _head_thing_due(b):
		var tn: String = str(b["opens"].values()[0])
		rows.append({"icon": "res://art/items/%s.png" % Items.slug(tn), "forms": _thing_forms(tn), "colour": Pal.WARN, "edge": true})
	elif showing_head:
		rows.append({"icon": "res://art/crates/safe.png", "forms": [Words.SITE_CARD["his_own"], Words.SITE_CARD["his_own_short"]], "colour": Pal.WARN})
	else:
		rows.append({"icon": "res://art/items/scrap.png", "forms": [Words.SITE_CARD["scrap"]], "colour": Pal.TEXT})
	rows.append({"icon": "res://art/items/paper.png", "forms": [Words.SITE_CARD["paper"] % maxi(1, roundi(1.0 / maxf(p_odds, 0.001))), "1 in %d" % maxi(1, roundi(1.0 / maxf(p_odds, 0.001)))], "colour": Pal.TEXT})
	if mk == "":
		rows.append({"icon": "", "forms": [Words.SITE_CARD["no_material"] % Words.mid(str(Data.ZONES[int(Data.TIERS[i]["zone"])]["name"])), Words.SITE_CARD["no_material_short"]], "colour": Pal.TEXT_3})
	else:
		rows.append({"icon": "res://art/items/%s.png" % mk, "forms": [sim.thing_name(mk)], "colour": MATERIAL_TONE if sim.campaign_done() else Pal.TEXT_3,
			"tip": "" if sim.campaign_done() else Words.SITE_CARD["material_later"]})
	for k in range(tiles.size()):
		var tl: Dictionary = tiles[k]
		var r: Dictionary = rows[k]
		tl["panel"].modulate = Color.WHITE if is_open else Color(1, 1, 1, 0.5)
		var path: String = str(r["icon"])
		tl["icon"].texture = Run.icon_tex([path]) if path != "" else null
		if tl["icon"].texture == null and path != "":
			tl["icon"].texture = Run.icon_tex(["res://art/ui/scrap.png"])
		UI.fit(tl["text"], r["forms"])
		tl["text"].add_theme_color_override("font_color", r["colour"])
		tl["edge"].visible = r.get("edge", false)
		tl["panel"].tooltip_text = str(r.get("tip", ""))
		tl["panel"].mouse_filter = Control.MOUSE_FILTER_PASS if str(r.get("tip", "")) != "" else Control.MOUSE_FILTER_IGNORE


## A head's thing still to come off him: its room shut.
func _head_thing_due(b: Dictionary) -> bool:
	for room in b.get("opens", {}):
		if not sim.room_open(str(room)):
			return true
	return false


static func _thing_forms(nm: String) -> Array:
	var out: Array = [nm]
	if nm.contains("'s "):
		out.append("The " + nm.get_slice("'s ", 1))     # "The Carpet Man's ledger" -> "The ledger"
	out.append(nm.get_slice(" ", nm.get_slice_count(" ") - 1).capitalize())
	return out


func _show_here(i: int) -> void:
	var r: Dictionary = sim.site_record(i)
	var L: Dictionary = Words.SITE_CARD
	UI.fit(here_right, sim.site_state_forms(i) if sim.tier_open(i) else [""])
	var forms: Array
	if int(r["tries"]) == 0:
		forms = [L["here_never"]]
	elif int(r["clears"]) == 0:
		forms = [L["here_tried"] % Words.count_of(int(r["tries"]), "run"), L["here_tried_short"]]
	else:
		var c: int = int(r["clears"])
		var times: String = Words.count_of(c, "time")     # the house count (the language pass): never a hard-coded "once"
		forms = [L["here_cleared"] % [times, Fmt.mss(float(r["best"]))], L["here_cleared_short"] % times]
	# the record and the site's crates share the row: the record's longest form that leaves the crates their room
	var room: float = INNER - (UI.text_width(here_right, here_right.text) + 16.0 if here_right.text != "" else 0.0)
	here.text = UI.dots(str(forms.back()))
	for f in forms:
		if UI.text_width(here, UI.dots(str(f))) <= room:
			here.text = UI.dots(str(f))
			break
	if str(r["last"]) == "":
		UI.fit(last, [L["last_none"]])
		return
	var at: String = Fmt.mss(float(r["last_t"]))
	var how: String = str(L["ends"].get(str(r["last"]), str(r["last"]).to_lower()))
	var full: String = L["full"] if bool(r["last_full"]) else ""
	UI.fit(last, [L["last"] % [how, at] + full, L["last"] % [how, at]])


## Every label and button with words, for the fit checks.
func text_nodes() -> Array:
	var out: Array = [kicker, title, sky, foot, you_name, them_name, verdict, odds_line, no_fix, home_head, here, here_right, last]
	if head_box.visible:
		out.append_array([head_name, head_sub])     # an order's place's row (BUILD55-U: a site's is the picker)
	if pick_box.visible:
		for sg in segs:
			if sg["button"].visible:
				out.append_array([sg["top"], sg["sub"]])
		out.append_array([picked_key, picked_val])
	if gang_frame.visible:
		out.append(gang_count)
	if count_box.visible:
		out.append(count)
	out.append_array(keys + vals)
	for b in chips:
		if b.visible:
			out.append(b)
	for tl in tiles:
		out.append(tl["text"])
	return out


## Key and value sharing a row, for the line check.
func line_pairs() -> Array:
	var out: Array = []
	for k in range(keys.size()):
		out.append([keys[k], vals[k]])
	out.append([here, here_right])
	return out


# ------------------------------------------------------------------ the order's places (BUILD49 U, item 23)

var _order_od: Array = [0.0, false]
var order := ""                         # the order's place shown ("grid", "archive", "mint"), "" for a site


## The order's places drawn by the site card (BUILD49 U, item 23; Matt: "these need updating with the rest of the site
## overhaul we did"): the head's fight as a site's head is - his portrait against yours with the verdict between, his own
## row (name, level, his line) with no Gang / Head toggle (the head's fight alone), how long you last, their fire and
## yours, meds and rounds, what you'll bring home with his drop and his unique, the fix chips. Read on the place laid on
## its host site, as a run there is (sim.order_sig), its odds the place's own (sim.order_odds_now). A shut place keeps its
## card and picture, the figures greyed, the verdict "Locked" and the rebuild that opens it.
func show_order(s, k: String, why: Array = []) -> void:
	sim = s
	order = k
	_why = why
	var p: Dictionary = Data.pinnacle(k)
	var i: int = int(p["site"])
	site = i
	var open: bool = sim.order_open(k)
	has_head = true
	var sg: Dictionary = sim.order_sig(k)
	_order_od = sim.order_odds_now(k) if open else [0.0, false]     # read before the place is laid on (it reads nothing while one is)
	var swapped := false
	var home = null
	if open and sim._sig.is_empty():
		sim._sig_on(sg)
		home = sim._surv_cache.get(i, null)
		var key: String = "order/%s/%d" % [k, int(sg["depth"])]
		if sim._sig_odds.has(key):
			sim._surv_cache[i] = sim._sig_odds[key]
		else:
			sim._surv_cache.erase(i)
		swapped = true
	_order_picture(k, p, open)
	_order_match(k, p, open)
	_order_head(k, p, open)
	_show_takes(i, open)
	_order_takes_shut(open)
	_show_fix(i, open)
	_order_home(k, p, open)
	_order_here(k, open)
	if swapped:
		if home != null:
			sim._surv_cache[i] = home
		else:
			sim._surv_cache.erase(i)
		sim._sig_off()


func _order_picture(k: String, p: Dictionary, open: bool) -> void:
	var n: int = Data.PINNACLES.map(func(x): return str(x["key"])).find(k)
	_art.texture = UI.place_texture(str(p.get("art", p["place"])))
	_art.modulate = Color.WHITE if open else Color(0.55, 0.55, 0.58)
	UI.fit(kicker, [Words.U49_ORDER["kicker"] % Words.U49_ORDER["nth"][clampi(n, 0, 2)], Words.U49_ORDER["kicker_short"]])
	UI.fit(title, [str(p["place"])])
	title.add_theme_color_override("font_color", Pal.TEXT if open else Pal.TEXT_2)
	UI.fit(sky, [sim.clock_words() + " · " + (Words.SKY["night"] if sim.is_night() else Words.SKY["day"]), sim.clock_words()])
	var head_key: String = Items.slug(str(p["who"]))
	var t: Texture2D = RunView.tex("head_%s_stand" % head_key)
	for kk in range(_figs.size()):
		_figs[kk].visible = false
	if t != null:
		var f: TextureRect = _figs[0]
		var u: Rect2 = RunView.used_of(t)
		if u.size.y <= 0.0:
			u = Rect2(Vector2.ZERO, t.get_size())
		var sc: float = HEAD_FIG_H / u.size.y
		f.texture = t
		f.size = t.get_size() * sc
		f.position = Vector2(W * FIG_X[1] - (u.position.x + u.size.x / 2.0) * sc, PIC_H - 30 - u.end.y * sc)
		f.modulate = Color.WHITE if open else Color(0.5, 0.5, 0.5)
		f.visible = true
	if k == "mint" and not sim.issued:
		var pv: Dictionary = sim.issue_preview()
		var fx: String = Fmt.group(int(round(float(pv["fiat"]))))
		UI.fit(foot, Words.MINT_WARN["forms"].map(func(fm): return fm % fx))     # the Issue converts everything (the third review's A1(a)): said on the picture's foot
		foot.tooltip_text = Words.MINT_WARN["tip"] % [fx, float(pv["kit_k"])]
		foot.mouse_filter = Control.MOUSE_FILTER_PASS
		foot.add_theme_color_override("font_color", Pal.WARN)
	else:
		UI.fit(foot, [Words.U49_ORDER["alone"], Words.U49_ORDER["alone_short"]])
		foot.tooltip_text = ""
		foot.add_theme_color_override("font_color", Pal.TEXT_2)


func _order_match(_k: String, p: Dictionary, open: bool) -> void:
	People.show(you_face, sim.cls)
	UI.fit(you_name, ["The %s" % sim.cls, sim.cls] if sim.cls != "" else ["The runner"])
	People.show(them_face, str(p["who"]))
	UI.fit(them_name, [str(p["who"]), str(p["who"]).trim_prefix("The ")])
	count_box.visible = false
	(you_frame.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.GOOD
	for l in [verdict, odds_line]:
		l.tooltip_text = ""
	if not open:
		UI.fit(verdict, [Words.SITE_CARD["locked"]])
		verdict.add_theme_color_override("font_color", Pal.TEXT_3)
		(them_frame.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.CARD_LINE
		var rb: String = str(Data.rebuild(str(p["opened_by"])).get("name", "")).trim_prefix("The ").to_lower()
		UI.fit(odds_line, [Words.U49_ORDER["after"] % rb, Words.U49_ORDER["after_mid"] % rb, Words.U49_ORDER["after_short"]])
		return
	var od: Array = _order_od
	var o: float = float(od[0])
	var tone: Color = Pal.tone_color("good" if o >= 0.9 else ("warn" if o >= 0.6 else "bad"))
	(them_frame.get_theme_stylebox("panel") as StyleBoxFlat).border_color = tone if od[1] else Pal.CARD_LINE
	UI.fit(verdict, [Words.odds_words(o)] if od[1] else [Words.SITE_CARD["reading"]])
	verdict.add_theme_color_override("font_color", tone if od[1] else Pal.TEXT_3)
	UI.fit(odds_line, ["%s to clear" % Fmt.pct(o)] if od[1] else [""])
	for l in [verdict, odds_line]:
		l.tooltip_text = Words.U49_DEATH["odds_tip"]
		l.mouse_filter = Control.MOUSE_FILTER_PASS


## His own row where a site's head row sits: his face, "The Lineman · level 30", his line; no toggle (his fight alone).
func _order_head(k: String, p: Dictionary, open: bool) -> void:
	head_face.get_parent().visible = true
	People.show(head_face, str(p["who"]))
	head_face.modulate = Color.WHITE if open else Color(0.6, 0.6, 0.6)
	head_box.visible = true                  # his row in the picker's slot (BUILD55-U)
	pick_box.visible = false
	gang_frame.visible = false
	head_name.add_theme_color_override("font_color", Pal.TEXT if open else Pal.TEXT_2)
	UI.fit(head_name, ["%s · level %d" % [p["who"], sim.order_level(k)], str(p["who"])])
	var line: String = str(Words.PINNACLE_WORDS.get(k, ""))
	UI.fit(head_sub, [line, line.get_slice(". ", 0).trim_suffix(".") + ".", ""])


## A shut place's rows: their keys greyed, a dash for each figure, "Opens with the place" on the first.
func _order_takes_shut(open: bool) -> void:
	if open:
		return
	for k in range(keys.size()):
		keys[k].visible = true
		keys[k].add_theme_color_override("font_color", Pal.TEXT_3)
		vals[k].visible = true
		vals[k].text = Words.U49_ORDER["opens"] if k == 0 else "—"
		vals[k].add_theme_color_override("font_color", Pal.TEXT_3)


## What you'll bring home: his drop (the first win's own first), a unique of his, the item level, the drop or the host
## site's material.
func _order_home(k: String, p: Dictionary, open: bool) -> void:
	var beaten: int = int(sim.order_beaten.get(k, 0))
	var rows: Array = []
	var first_due: bool = p.has("first") and beaten == 0
	var lead: String = str(p["first"]) if first_due else str(p.get("drop", ""))
	var lw: String = sim.thing_label(lead)
	rows.append({"icon": "res://art/items/%s.png" % lead, "forms": [lw, sim.thing_name(lead), lw.get_slice(" ", lw.get_slice_count(" ") - 2) + " " + lw.get_slice(" ", lw.get_slice_count(" ") - 1) if lw.get_slice_count(" ") > 1 else lw], "colour": Pal.WARN})
	rows.append({"icon": "res://art/items/%s.png" % Items.slug(str(p["unique"])), "forms": [Words.U49_ORDER["unique"]], "colour": Pal.UNIQUE, "tip": "%s or %s" % [p["unique"], p.get("unique2", p["unique"])]})
	var lv: int = sim.order_level(k)
	rows.append({"icon": "res://art/crates/cardboard.png", "forms": [Words.SITE_CARD["gear"] % int(sim.wear_of(lv)), "Level %d" % int(sim.wear_of(lv))], "colour": Pal.TEXT})
	var i: int = int(p["site"])
	var mk: String = str(p.get("drop", "")) if first_due else (str(Data.SITE_MATERIAL[i]) if i < Data.SITE_MATERIAL.size() else "")
	rows.append({"icon": "res://art/items/%s.png" % mk if mk != "" else "", "forms": [sim.thing_name(mk)] if mk != "" else [""], "colour": MATERIAL_TONE})
	for kk in range(tiles.size()):
		var tl: Dictionary = tiles[kk]
		var r: Dictionary = rows[kk]
		tl["panel"].modulate = Color.WHITE if open else Color(1, 1, 1, 0.5)
		var path: String = str(r["icon"])
		tl["icon"].texture = Run.icon_tex([path]) if path != "" else null
		if tl["icon"].texture == null and path != "":
			tl["icon"].texture = Run.icon_tex(["res://art/ui/scrap.png"])
		UI.fit(tl["text"], r["forms"])
		tl["text"].add_theme_color_override("font_color", r["colour"])
		tl["edge"].visible = kk == 0
		tl["panel"].tooltip_text = str(r.get("tip", ""))
		tl["panel"].mouse_filter = Control.MOUSE_FILTER_PASS if str(r.get("tip", "")) != "" else Control.MOUSE_FILTER_IGNORE


func _order_here(k: String, _open: bool) -> void:
	var beaten: int = int(sim.order_beaten.get(k, 0))
	here_right.text = ""
	UI.fit(here, [Words.U49_ORDER["beaten"] % Words.count_of(beaten, "time") if beaten > 0 else Words.SITE_CARD["here_never"]])
	last.text = ""
