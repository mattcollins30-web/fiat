extends Control
## A night on the air's break (BUILD50 N, act_two.md §3; the canvas's Night board): between two links, on the run screen.
## The chain strip (links done, the next, the next fifth) and the night's clock along the top; the next link's card - its
## place, level, codes, what it drops, its head if a fifth, the odds to clear as the runner stands; what's carried (HP,
## meds, magazines, the pack); Kev's wagers on the next link (or the Radio's tuning on it); the night's haul on the right;
## Next link, Get out with the haul, Tune it and "Auto: keep going" along the foot. Fixed geometry in the run's 1760 x 916.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const People := preload("res://scripts/ui/people.gd")
const Sim := preload("res://scripts/sim/sim.gd")

const W := Pal.RUN_W                    # 1760
const H := Pal.ROOM_H                   # 916
const PAD := 32
const LEFT_W := 1080
const RIGHT_X := PAD + LEFT_W + 24
const RIGHT_W := W - PAD - RIGHT_X      # 592
const TOP_Y := 104
const CARD_H := 420
const PIC_H := 226
const COL_Y := PIC_H + 16
const COL_GAP := 20
const COL_W := (LEFT_W - 2 * 24 - 2 * COL_GAP) / 3.0
const STAND_Y := TOP_Y + CARD_H + 16    # 540
const STAND_H := 100
const ROW_Y := STAND_Y + STAND_H + 16   # 656: Kev's wagers, or the tuning
const ROW_H := 112
const BTN_Y := H - PAD - Pal.BUTTON_H   # 828
const CHAIN_X := 690
const DOT := 44
const LINK_GAP := 20
const CHAIN_MAX := 9                    # circles and the "…" between
const FACE := 96
const KIT_ROWS := 6
const KIT_ROW_H := 40

var sim
var tuning := false                    # the Tune it row open in the wagers' place
var _shown := ""
var _kicker: Label
var _headline: Label
var _clock_head: Label
var _clock: Label
var _chain: Array = []                 # {panel, label}: a link's circle, or "…"
var _card: Panel
var _pic: TextureRect
var _next_kicker: Label
var _next_title: Label
var _head_frame: Panel
var _head_face: TextureRect
var _head_line: Label
var _head_name: Label
var _clear_head: Label
var _clear: Label
var _clear_words: Label
var _codes_head: Label
var _codes: Chips
var _codes_note: Label
var _drops_head: Label
var _drops: Array = []                 # Labels, a line each
var _stand: Array = []                 # {head, value, sub}
var _hp_track: Panel
var _hp_fill: Panel
var _row_head: Label
var _row_btns: Array = []              # three: Kev's wagers, or the tune / retune / twist
var _row_none: Label
var _haul_head: Label
var _tiles: Array = []                 # {panel, key, value}: tins, XP
var _mat_head: Label
var _mats: Chips
var _kit_head: Label
var _kit: Array = []                   # {panel, name, rarity}
var _death: Label
var _timeout: Label                    # a link's own clock out: as a run out of time (fix 50)
var next_btn: Button
var out_btn: Button
var tune_btn: Button
var auto_btn: Button
var _foot: Label


func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := UI.panel(self, Rect2(0, 0, W, H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kicker = UI.label(self, Rect2(PAD, 22, CHAIN_X - PAD - 20, 22), "", "Medium", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(_kicker, 1)
	_headline = UI.label(self, Rect2(PAD, 46, CHAIN_X - PAD - 20, 44), "", "SemiBold", Pal.TITLE + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(CHAIN_MAX):
		var p := UI.panel(self, Rect2(CHAIN_X + k * (DOT + LINK_GAP), 34, DOT, DOT), UI.box(Color.TRANSPARENT, int(DOT / 2.0), 2, Pal.CARD_LINE))
		var l := UI.label(p, Rect2(0, 0, DOT, DOT), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		_chain.append({"panel": p, "label": l})
	_clock_head = UI.label(self, Rect2(W - PAD - 300, 24, 300, 20), Words.NIGHT["clock_head"], "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_clock = UI.label(self, Rect2(W - PAD - 300, 46, 300, 40), "", "SemiBold", Pal.TITLE + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_build_card()
	_build_stand()
	_build_row()
	_build_haul()
	next_btn = UI.button(self, Rect2(PAD, BTN_Y, 290, Pal.BUTTON_H), true)
	next_btn.pressed.connect(_on_next)
	out_btn = UI.button(self, Rect2(PAD + 290 + 16, BTN_Y, 300, Pal.BUTTON_H), false)
	out_btn.pressed.connect(_on_out)
	tune_btn = UI.button(self, Rect2(PAD + 290 + 16 + 300 + 16, BTN_Y, 196, Pal.BUTTON_H), false)
	tune_btn.pressed.connect(_on_tune)
	auto_btn = UI.button(self, Rect2(PAD + 290 + 16 + 300 + 16 + 196 + 16, BTN_Y, 246, Pal.BUTTON_H), false)
	auto_btn.pressed.connect(_on_auto)
	for b in [next_btn, out_btn, tune_btn, auto_btn]:
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG + 2)
	_foot = UI.label(self, Rect2(RIGHT_X, BTN_Y, RIGHT_W, Pal.BUTTON_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	visible = false


func _build_card() -> void:
	_card = UI.panel(self, Rect2(PAD, TOP_Y, LEFT_W, CARD_H), UI.box(Pal.PANEL, 8, 2, Pal.ACCENT))
	var clip := Control.new()
	clip.position = Vector2(2, 2)
	clip.size = Vector2(LEFT_W - 4, PIC_H)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(clip)
	_pic = TextureRect.new()
	_pic.size = clip.size
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_pic)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.15), Color(0, 0, 0, 0.35), Color(Pal.PANEL, 0.95)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	var fade := TextureRect.new()
	fade.texture = gt
	fade.size = clip.size
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(fade)
	_next_kicker = UI.label(_card, Rect2(24, PIC_H - 78, 640, 22), "", "Medium", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(_next_kicker, 1)
	_next_title = UI.label(_card, Rect2(24, PIC_H - 54, 660, 46), "", "SemiBold", Pal.HEADLINE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for l in [_next_kicker, _next_title]:
		UI.shadow(l)
	_head_frame = UI.panel(_card, Rect2(LEFT_W - 24 - FACE - 4, PIC_H - FACE - 16, FACE + 4, FACE + 4), UI.box(Pal.BG, 6, 2, Pal.ACCENT))
	_head_face = People.rect(_head_frame, Vector2(2, 2), FACE / 128.0)
	_head_line = UI.label(_card, Rect2(LEFT_W - 24 - FACE - 16 - 300, PIC_H - 72, 300, 22), Words.NIGHT["head_away"], "Regular", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_head_name = UI.label(_card, Rect2(LEFT_W - 24 - FACE - 16 - 300, PIC_H - 48, 300, 30), "", "SemiBold", Pal.LINE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for l in [_head_line, _head_name]:
		UI.shadow(l)
	var x0: float = 24
	_clear_head = _col_head(x0, Words.NIGHT["clear_head"])
	_clear = UI.label(_card, Rect2(x0, COL_Y + 28, COL_W, 60), "", "SemiBold", Pal.HEADLINE + 10, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT)
	_clear_words = UI.label(_card, Rect2(x0, COL_Y + 96, COL_W, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	x0 += COL_W + COL_GAP
	_codes_head = _col_head(x0, Words.NIGHT["codes_head"])
	_codes = Chips.new(COL_W, 6)
	_codes.position = Vector2(x0, COL_Y + 30)
	_card.add_child(_codes)
	_codes_note = UI.label(_card, Rect2(x0, COL_Y + 124, COL_W, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	x0 += COL_W + COL_GAP
	_drops_head = _col_head(x0, Words.NIGHT["drops_head"])
	for k in range(4):
		_drops.append(UI.label(_card, Rect2(x0, COL_Y + 28 + k * 26, COL_W, 24), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))


func _col_head(x: float, text: String) -> Label:
	var l := UI.label(_card, Rect2(x, COL_Y, COL_W, 20), text, "Medium", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(l, 1)
	return l


func _build_stand() -> void:
	var p := UI.panel(self, Rect2(PAD, STAND_Y, LEFT_W, STAND_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var cw: float = (LEFT_W - 48) / 4.0
	var heads: Array = [Words.NIGHT["hp_head"], Words.NIGHT["meds_head"], Words.NIGHT["mags_head"], Words.NIGHT["pack_head"]]
	for k in range(4):
		var x: float = 24 + k * cw
		var hd := UI.label(p, Rect2(x, 12, cw - 16, 20), heads[k], "Medium", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.track(hd, 1)
		var v := UI.label(p, Rect2(x, 34, cw - 16, 34), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		var sb := UI.label(p, Rect2(x, 70, cw - 16, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_stand.append({"head": hd, "value": v, "sub": sb})
	_hp_track = UI.panel(p, Rect2(24, 76, cw - 40, 6), UI.box(Pal.BG, 3))
	_hp_fill = UI.panel(_hp_track, Rect2(0, 0, cw - 40, 6), UI.box(Pal.BAD, 3))


func _build_row() -> void:
	var p := UI.panel(self, Rect2(PAD, ROW_Y, LEFT_W, ROW_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_row_head = UI.label(p, Rect2(24, 12, LEFT_W - 48, 20), "", "Medium", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(_row_head, 1)
	var bw: float = (LEFT_W - 48 - 2 * 12) / 3.0
	for k in range(3):
		var b := UI.button(p, Rect2(24 + k * (bw + 12), 42, bw, 52), false)
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
		b.pressed.connect(_on_row.bind(k))
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		_row_btns.append(b)
	_row_none = UI.label(p, Rect2(24, 42, LEFT_W - 48, 52), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


func _build_haul() -> void:
	var p := UI.panel(self, Rect2(RIGHT_X, TOP_Y, RIGHT_W, BTN_Y - 16 - TOP_Y), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = RIGHT_W - 48
	_haul_head = UI.label(p, Rect2(24, 20, iw, 20), "", "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(_haul_head, 1)
	var tw: float = (iw - 12) / 2.0
	for k in range(2):
		var tp := UI.panel(p, Rect2(24 + k * (tw + 12), 52, tw, 76), UI.box(Pal.BG, 6))
		var tk := UI.label(tp, Rect2(14, 8, tw - 28, 20), Words.NIGHT["tins"] if k == 0 else Words.NIGHT["xp"], "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var tv := UI.label(tp, Rect2(14, 30, tw - 28, 38), "", "SemiBold", Pal.TITLE - 2, Pal.ACCENT if k == 0 else Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		_tiles.append({"panel": tp, "key": tk, "value": tv})
	_mat_head = UI.label(p, Rect2(24, 144, iw, 22), Words.NIGHT["materials"], "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_mats = Chips.new(iw, 6)
	_mats.position = Vector2(24, 172)
	p.add_child(_mats)
	_kit_head = UI.label(p, Rect2(24, 244, iw, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(KIT_ROWS):
		var kp := UI.panel(p, Rect2(24, 274 + k * (KIT_ROW_H + 6), iw, KIT_ROW_H), UI.box(Pal.CARD, 6))
		var kn := UI.label(kp, Rect2(14, 0, iw - 28 - 130, KIT_ROW_H), "", "Medium", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var kr := UI.label(kp, Rect2(iw - 14 - 120, 0, 120, KIT_ROW_H), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_kit.append({"panel": kp, "name": kn, "rarity": kr})
	_death = UI.label(p, Rect2(24, BTN_Y - 16 - TOP_Y - 44 - 28, iw, 24), Words.NIGHT["death"], "Regular", Pal.CELL_TEXT, Pal.BAD, HORIZONTAL_ALIGNMENT_LEFT, false)
	_timeout = UI.label(p, Rect2(24, BTN_Y - 16 - TOP_Y - 44, iw, 24), Words.NIGHT["timeout_line"], "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


## The break as it stands; laid out once a change (the odds read in, a wager taken, a craft).
func show_state(s) -> void:
	sim = s
	visible = sim.night_break()
	if not visible:
		tuning = false
		return
	var m: Dictionary = sim.mission
	var sg: Dictionary = sim.night_next_sig()
	var od: Array = sim.night_odds_now()
	var key: String = sim.night_wager_key()
	var sig := "%s|%s|%s|%s|%s|%.0f|%d|%s|%s|%s|%s|%s|%s" % [str(sim.night_chain), str(sg), str(od), str(sim.wagers.get(key, {})), str(tuning), sim.hp, sim.notes, str(sim.rig.size()),
		str(m["found"].size()), str(sim.night_auto), str(sim.night_floor), str(sim.night_rules), sim.cls]
	if sig == _shown:
		return
	_shown = sig
	var link: int = sim.night_link()
	var next: int = link + 1
	var results: Array = sim.night_chain.get("results", [])
	var won: bool = not results.is_empty() and bool(results.back())
	UI.fit(_kicker, [Words.NIGHT["kicker"] % str(sim.night_chain.get("cls", sim.cls)).to_upper(), Words.NIGHT["kicker_short"]])
	var nxt: String = Words.NIGHT["the_fifth"] if Sim.night_special(next) != "" else Words.NIGHT["link_n"] % next
	UI.fit(_headline, [(Words.NIGHT["won"] if won else Words.NIGHT["lost"]) % [link, nxt], (Words.NIGHT["won_short"] if won else Words.NIGHT["lost_short"]) % link])
	_show_chain(results, next)
	UI.fit(_clock, [Words.NIGHT["clock_left"] % Fmt.mss(ceilf(sim.night_clock_left())), Fmt.mss(ceilf(sim.night_clock_left()))])
	_show_card(sg, next, od)
	_show_stand(m)
	_show_row(next, key)
	_show_haul()
	var fifth: bool = Sim.night_special(next) != ""
	UI.fit_button(next_btn, [Words.NIGHT["next_btn_fifth"], Words.NIGHT["next_btn"]] if fifth else [Words.NIGHT["next_btn"]])
	next_btn.disabled = sg.is_empty()
	UI.fit_button(out_btn, [Words.NIGHT["out_btn"]])
	UI.fit_button(tune_btn, [Words.NIGHT["tune_close"]] if tuning else [Words.NIGHT["tune_btn"]])
	tune_btn.disabled = sg.is_empty()
	var fl: int = roundi(sim.night_floor * 100.0)
	UI.fit_button(auto_btn, ["%s · %d%%" % [Words.NIGHT["auto"], fl], Words.NIGHT["auto"]])
	UI.style_button(auto_btn, false, "good" if sim.night_auto else "")
	var under: bool = sim.night_auto and bool(od[1]) and float(od[0]) < sim.night_floor - 0.0001
	if under:
		UI.fit(_foot, [Words.NIGHT["auto_under"] % fl])
		_foot.add_theme_color_override("font_color", Pal.WARN)
	else:
		UI.fit(_foot, [Words.NIGHT["foot"], Words.NIGHT["foot"].get_slice(":", 0)])
		_foot.add_theme_color_override("font_color", Pal.TEXT_2)


## The chain: the links done (won green, lost red), the next ringed in amber, those after it, "…", the next fifth dashed.
func _show_chain(results: Array, next: int) -> void:
	var fifth: int = Sim.night_next_fifth(next - 1) if Sim.night_special(next) == "" else next
	var first: int = maxi(1, next - 4)
	var shown: Array = []
	for n in range(first, next + 1):
		shown.append(n)
	var after: int = next + 1
	while shown.size() < CHAIN_MAX - 2 and after < fifth:
		shown.append(after)
		after += 1
	if fifth > shown.back():
		if fifth > shown.back() + 1:
			shown.append(0)                    # the "…"
		shown.append(fifth)
	for k in range(CHAIN_MAX):
		var c: Dictionary = _chain[k]
		c["panel"].visible = k < shown.size()
		if k >= shown.size():
			continue
		var n: int = int(shown[k])
		var sb: StyleBoxFlat = UI.box(Color.TRANSPARENT, int(DOT / 2.0), 2, Pal.CARD_LINE)
		var col: Color = Pal.TEXT_2
		if n == 0:
			c["label"].text = "…"
			sb.set_border_width_all(0)
		else:
			c["label"].text = str(n)
			if n < next:
				var w: bool = n - 1 < results.size() and bool(results[n - 1])
				sb.bg_color = Color(Pal.GOOD if w else Pal.BAD, 0.55)
				sb.border_color = Pal.GOOD if w else Pal.BAD
				col = Pal.TEXT
			elif n == next:
				sb.set_border_width_all(3)
				sb.border_color = Pal.ACCENT
				col = Pal.ACCENT
			elif Sim.night_special(n) != "":
				sb.border_color = Color(Pal.ACCENT, 0.7)
				col = Pal.ACCENT
		c["panel"].add_theme_stylebox_override("panel", sb)
		c["label"].add_theme_color_override("font_color", col)


func _show_card(sg: Dictionary, next: int, od: Array) -> void:
	if sg.is_empty():
		return
	var place: String = sim.signal_place(sg)
	_pic.texture = UI.place_texture(place)
	var special: String = Sim.night_special(next)
	UI.fit(_next_kicker, [(Words.NIGHT["next_kicker_fifth"] if special != "" else Words.NIGHT["next_kicker"]) % next, Words.NIGHT["next_kicker"] % next])
	UI.fit(_next_title, [Words.NIGHT["title"] % [place, sim.signal_level(sg)], place])
	var head: bool = bool(sg.get("head", false))
	for n in [_head_frame, _head_line, _head_name]:
		n.visible = head
	if head:
		var who: String = sim.signal_head_name(sg)
		People.show(_head_face, who)
		UI.fit(_head_name, [who])
	# the odds as the runner stands
	var o: float = float(od[0])
	var tone: Color = Pal.tone_color("good" if o >= 0.9 else ("warn" if o >= 0.6 else "bad"))
	if bool(od[1]):
		_clear.text = Fmt.pct(o)
		_clear.add_theme_color_override("font_color", tone)
		var ow: String = Words.odds_words(o)
		UI.fit(_clear_words, [Words.NIGHT["rest_since"] % ow, ow])
	else:
		_clear.text = "…"
		_clear.add_theme_color_override("font_color", Pal.TEXT_3)
		UI.fit(_clear_words, [Words.NIGHT["reading"]])
	# its codes: by the rules on a rolled link, its own on a held one; the fifth's special after them
	var rolled: bool = bool(sg.get("rolled", false))
	UI.fit(_codes_head, [Words.NIGHT["codes_head"] if rolled else Words.NIGHT["codes_held"]])
	var chips: Array = []
	for wd in sim.signal_words(sg):
		chips.append({"forms": [str(wd["w"])], "colour": Pal.TEXT_2})
	if chips.is_empty():
		chips.append({"forms": [Words.NIGHT["no_codes"]], "colour": Pal.TEXT_3})
	if special != "":
		chips.append({"forms": [Words.NIGHT["fifth_" + special]], "colour": Pal.WARN})
	_codes.show_chips(chips, 3, true)
	var nr: int = sim.night_rules.filter(func(r): return bool(r.get("on", true))).size()
	UI.fit(_codes_note, [(Words.NIGHT["rules_line"] % nr if nr > 0 else Words.NIGHT["rules_none"]) if rolled else Words.NIGHT["held_line"], ""])
	_codes_note.position.y = COL_Y + 30 + _codes.size.y + 8
	# what it drops: its focus first, as the Radio's card reads it (merge 50: T's focus on N's break)
	var lines: Array = []
	var ff: Array = load("res://scripts/ui/radio.gd").focus_forms(sim, sg)
	if not ff.is_empty():
		lines.append(ff)
	var mats: Array = sim.night_materials()
	for mk in (mats[0] as Dictionary):
		if lines.size() >= 2:
			break
		lines.append(Words.NIGHT["drop_mat"] % [sim.thing_name(str(mk)), roundi(float(mats[0][mk]) * 100.0)])
	match special:
		"head":
			lines.append(Words.NIGHT["drop_head"] % sim.signal_head_name(sg))
		"stash":
			lines.append(Words.NIGHT["drop_stash"])
		"fat":
			lines.append(Words.NIGHT["drop_fat"])
	if lines.is_empty():
		lines.append(Words.NIGHT["drop_none"])
	for k in range(_drops.size()):
		var l: Label = _drops[k]
		l.visible = k < lines.size()
		if l.visible:
			if lines[k] is Array:
				UI.fit(l, lines[k])
			else:
				var t: String = str(lines[k])
				UI.fit(l, [t, t.get_slice(":", 0)])


func _show_stand(m: Dictionary) -> void:
	var c: Dictionary = sim.night_carried()
	UI.fit(_stand[0]["value"], ["%d / %d" % [ceili(sim.hp), ceili(sim.max_hp())], "%d" % ceili(sim.hp)])
	_stand[0]["sub"].text = ""
	_hp_fill.size.x = _hp_track.size.x * clampf(sim.hp / maxf(1.0, sim.max_hp()), 0.0, 1.0)
	(_hp_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.BAD if sim.hp < sim.max_hp() * 0.5 else Pal.GOOD
	UI.fit(_stand[1]["value"], [Words.NIGHT["meds"] % int(c["meds"])])
	UI.fit(_stand[1]["sub"], [Words.NIGHT["meds_used"] % int(c["meds_used"])])
	UI.fit(_stand[2]["value"], [Words.NIGHT["mags"] % int(c["mags"])])
	UI.fit(_stand[2]["sub"], [Words.NIGHT["mags_rounds"] % Words.group(int(c["rounds"])), Words.group(int(c["rounds"]))])
	UI.fit(_stand[3]["value"], [Words.NIGHT["pack"] % [sim.pack_used(m), sim.capacity()]])
	UI.fit(_stand[3]["sub"], [Words.NIGHT["pack_sub"]])


## Kev's wagers on the next link, a button each (taken, or Take it); or, with Tune it open, the Radio's three crafts at
## their prices.
func _show_row(next: int, key: String) -> void:
	if tuning:
		UI.fit(_row_head, [Words.NIGHT["crafts_head"] % next])
		_row_none.visible = false
		for k in range(3):
			var b: Button = _row_btns[k]
			var ck: String = str(Sim.SIGNAL_CRAFTS[k])
			var cd: Dictionary = Data.craft_of(ck)
			var why: String = sim.night_craft_block(ck)
			b.visible = true
			b.disabled = why != ""
			b.tooltip_text = why if why != "" else str(cd["sentence"])
			UI.fit_button(b, ["%s · %s" % [cd["name"], Fmt.notes(sim.night_craft_cost(ck))]])
			UI.style_button(b, false)
		return
	UI.fit(_row_head, [Words.NIGHT["wagers_head"] % next])
	var offer: Array = sim.wager_offer(key) if key != "" else []
	_row_none.visible = offer.is_empty()
	if offer.is_empty():
		UI.fit(_row_none, [Words.NIGHT["wagers_none"]])
	for k in range(3):
		var b: Button = _row_btns[k]
		b.visible = k < offer.size()
		if not b.visible:
			continue
		var taken: bool = sim.wager_taken(key, k)
		var w: String = Sim.wager_words(offer[k])
		b.disabled = false
		b.tooltip_text = ""
		UI.fit_button(b, ["%s · %s" % [w, Words.NIGHT["wager_on"] if taken else Words.NIGHT["wager_off"]], w, Sim.wager_cond_chip(offer[k])])
		UI.style_button(b, false, "warn" if taken else "")


func _show_haul() -> void:
	var hl: Dictionary = sim.night_haul()
	var n: int = int(sim.night_chain.get("done", 0))
	UI.fit(_haul_head, [Words.NIGHT["haul_head"] % [n, "" if n == 1 else "S"]])
	UI.fit(_tiles[0]["value"], [Words.group(int(round(float(hl.get("tins", 0.0))))), Fmt.num(float(hl.get("tins", 0.0)))])
	UI.fit(_tiles[1]["value"], [Words.group(int(round(float(hl.get("xp", 0.0))))), Fmt.num(float(hl.get("xp", 0.0)))])
	var chips: Array = []
	var mats: Dictionary = hl.get("materials", {})
	for nm in mats:
		chips.append({"forms": ["%s ×%d" % [nm, int(mats[nm])]], "colour": Pal.TEXT_2})
	if chips.is_empty():
		chips.append({"forms": [Words.NIGHT["no_materials"]], "colour": Pal.TEXT_3})
	_mats.show_chips(chips, 2, true)
	var kit: Array = hl.get("kit", [])
	UI.fit(_kit_head, [Words.NIGHT["kit"] % [kit.size(), "" if kit.size() == 1 else "s"] if not kit.is_empty() else Words.NIGHT["no_kit"]])
	var rows: int = mini(kit.size(), KIT_ROWS)
	var more: int = kit.size() - KIT_ROWS + 1 if kit.size() > KIT_ROWS else 0
	for k in range(KIT_ROWS):
		var r: Dictionary = _kit[k]
		r["panel"].visible = k < rows
		if k >= rows:
			continue
		if more > 0 and k == KIT_ROWS - 1:
			UI.fit(r["name"], [Words.NIGHT["kit_more"] % more])
			r["name"].add_theme_color_override("font_color", Pal.TEXT_2)
			r["rarity"].text = ""
			continue
		var it: Dictionary = kit[k]
		var nm: String = Items.full_name(it)
		UI.fit(r["name"], [nm, str(it.get("base", nm))])
		r["name"].add_theme_color_override("font_color", Pal.tone_color(Pal.item_tone(it)) if Pal.item_tone(it) != "" else Pal.TEXT)
		var rn: int = clampi(int(it.get("rarity", 0)), 0, Data.RARITIES.size() - 1)
		UI.fit(r["rarity"], ["Unique" if it.has("unique") else str(Data.RARITIES[rn]["name"])])


func _on_next() -> void:
	if sim != null and sim.night_next():
		tuning = false
	_shown = ""
	acted.emit()


func _on_out() -> void:
	if sim != null:
		sim.night_get_out()
	_shown = ""
	acted.emit()


func _on_tune() -> void:
	tuning = not tuning
	_shown = ""
	acted.emit()


func _on_auto() -> void:
	if sim != null:
		sim.night_auto = not sim.night_auto
	_shown = ""
	acted.emit()


func _on_row(k: int) -> void:
	if sim == null:
		return
	if tuning:
		sim.night_craft(str(Sim.SIGNAL_CRAFTS[k]))
	else:
		var key: String = sim.night_wager_key()
		sim.take_wager(key, k, not sim.wager_taken(key, k))
	_shown = ""
	acted.emit()


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [_kicker, _headline, _clock_head, _clock, _next_kicker, _next_title, _clear_head, _clear, _clear_words, _codes_head, _codes_note, _drops_head,
		_row_head, _haul_head, _mat_head, _kit_head, _death, _timeout, next_btn, out_btn, tune_btn, auto_btn, _foot]
	for c in _chain:
		if c["panel"].visible:
			out.append(c["label"])
	if _head_frame.visible:
		out.append_array([_head_line, _head_name])
	out.append_array(_codes.text_nodes())
	for l in _drops:
		if l.visible:
			out.append(l)
	for s in _stand:
		out.append_array([s["head"], s["value"], s["sub"]])
	for b in _row_btns:
		if b.visible:
			out.append(b)
	if _row_none.visible:
		out.append(_row_none)
	for t in _tiles:
		out.append_array([t["key"], t["value"]])
	out.append_array(_mats.text_nodes())
	for r in _kit:
		if r["panel"].visible:
			out.append_array([r["name"], r["rarity"]])
	return out
