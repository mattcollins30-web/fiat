extends Control
## An item's head on a panel, the way the mockup's option B lays it out: the
## name, a row of chips for what it is (slot, type, rarity, level, cells), and
## the headline figure big with its unit and a tail ("takes SMG rounds · 600
## carried"). Under it, the affixes as chips in the tier's colour with a T-tag
## inside, over two rows, and a muted "open" line when the Bench could add
## one. Every screen with an item panel (the Lock-up, the Fence, the Clinic,
## the run's pick) mounts one in its left column; the right column stays the
## screen's own (the compare, the shelf's price, the pack's room).

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Words := preload("res://scripts/sim/words.gd")

const TITLE_H := 36
const CHIP_H := 26
const CHIP_PAD := 8
const CHIP_GAP := 6
const CHIPS := 6
const ROWS := 0                    # the open slots, a set's words and "No affixes" are chips in the affix rows now

var width := 440
var compact := false               # a shorter headline and tighter rows, for the Lock-up's 252 px panel
var head_h := 46                   # the big figure's row
var row_h := 30                    # an affix row
var rows := ROWS
var chips_y := 0
var headline_y := 0
var rows_y := 0
var tail_y := 0
const TAIL_H := 26                 # the tail's own line under the headline
var _title: Label
var _chips: Array[Panel] = []
var _chip_labels: Array[Label] = []
var _figure: Label
var _unit: Label
var _unit_tail: Label              # a magazine's "feeds the over-and-under" after its figure (BUILD46-R)
var _icon: TextureRect             # a magazine's rounds' box before its figure (BUILD46-R)
const ICON := 36
var _tail: Label                   # the tail's words, kept for what reads them; shown as chips (16 Oct, the item card's chips)
var _tail_chips: Chips             # the tail as chips: what it takes, how many, a grade's bonus
var _tchips: Array = []            # the tail's own chips, for a warning laid in front of them
var warning: Array = []            # the warning chip's forms, long to short (18 Oct: the pick's hints, off the foot); [] for none
var _affixes: Chips                # the affixes, chips in their tier's colour, two rows
var _rows: Array[Label] = []       # the open line, a set's words, "No affixes"
const AFFIX_ROWS := 2


func _init(w := 440, small := false) -> void:
	width = w
	compact = small
	head_h = 30 if compact else 46
	row_h = 28
	rows = ROWS
	var gap := 4 if compact else 6
	chips_y = TITLE_H + gap
	headline_y = chips_y + CHIP_H + gap
	# the figure's font is taller than its row (30 px SemiBold: 38 in 30): the tail starts under its descenders, not on
	# them (30 Oct, parked item 6: the Clinic's "Stops" sat on its chip); over it, the gap takes the spill
	var fsize: int = Pal.TITLE if compact else Pal.HEADLINE
	var spill: int = maxi(0, ceili((UI.font("SemiBold", true).get_height(fsize) - head_h) / 2.0))
	tail_y = headline_y + head_h + spill
	rows_y = tail_y + TAIL_H + gap
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var affix_h := AFFIX_ROWS * (Chips.CHIP_H + Chips.ROW_GAP) - Chips.ROW_GAP
	size = Vector2(width, rows_y + affix_h + (4 + rows * row_h if rows > 0 else 0))
	_title = UI.label(self, Rect2(0, 0, width, TITLE_H), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(CHIPS):
		var p := UI.panel(self, Rect2(0, chips_y, 10, CHIP_H), UI.box(Pal.BUTTON, 6))
		p.visible = false
		_chips.append(p)
		_chip_labels.append(UI.label(p, Rect2(CHIP_PAD, 0, 10, CHIP_H), "", "Medium", Pal.CELL_TEXT if compact else Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_figure = UI.label(self, Rect2(0, headline_y, width, head_h), "", "SemiBold", fsize, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(self, Rect2(0, headline_y, width, head_h), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_unit_tail = UI.label(self, Rect2(0, headline_y, width, head_h), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_unit_tail.visible = false
	_icon = TextureRect.new()                 # a magazine's rounds' box (BUILD46-R), before its figure
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.size = Vector2(ICON, ICON)
	_icon.position = Vector2(0, headline_y + (head_h - ICON) / 2.0)
	_icon.visible = false
	add_child(_icon)
	_tail = UI.label(self, Rect2(0, tail_y, width, TAIL_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_tail.visible = false
	_tail_chips = Chips.new(width)
	_tail_chips.position = Vector2(0, tail_y)
	add_child(_tail_chips)
	_affixes = Chips.new(width)
	_affixes.position = Vector2(0, rows_y)
	add_child(_affixes)
	for k in range(rows):
		var y := rows_y + affix_h + 4 + k * row_h
		_rows.append(UI.label(self, Rect2(0, y, width, row_h), "", "Regular", Pal.CELL_TEXT_BIG + 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))


## `tail` follows the headline: "takes SMG rounds · 600 carried". `extra` is a
## line for the fourth row when there's no open affix to say (a set's words).
## `cells`: the cells chip, left off where the panel's kicker carries the cells.
func show_item(it: Dictionary, sim_in, tail = "", extra = "", cells := true) -> void:
	UI.fit(_title, [Items.full_name(it), it["base"]])
	# the chips: what it is, in the order a player asks
	var chips := _chip_words(it, cells)
	var x := 0.0
	for k in range(CHIPS):
		var on := k < chips.size()
		_chips[k].visible = on
		if not on:
			continue
		var words: String = chips[k][0]
		var tone: String = chips[k][1]
		var l := _chip_labels[k]
		l.text = words
		var w: float = ceilf(UI.text_width(l, words)) + 2 * CHIP_PAD
		if x + w > width:
			_chips[k].visible = false      # the row's full: this chip and the rest are left off; the first ones matter most
			for j in range(k + 1, CHIPS):
				_chips[j].visible = false
			break
		_chips[k].position = Vector2(x, chips_y)
		_chips[k].size = Vector2(w, CHIP_H)
		l.size.x = w - 2 * CHIP_PAD
		var colour: Color = Pal.tone_color(tone) if tone != "" else Pal.TEXT_2
		l.add_theme_color_override("font_color", colour)
		_chips[k].add_theme_stylebox_override("panel", UI.box(colour.darkened(0.72) if tone != "" else Pal.BUTTON, 6))
		x += w + CHIP_GAP
	# the headline: the figure big, its unit after, the tail after that. A
	# part's figure is its own first stat, its affixes kept for their rows
	var h := Items.headline(it, sim_in.mag_gun(it) if (sim_in != null and Items.is_mag(it)) else null)
	if Items.is_cure(it):
		h = [str(Words.CURE_CLEARS.get(Items.cure_of(it), str(h[0]) + " " + str(h[1]))), ""]     # the whole line big (30 Oct, parked item 6): "Stops a bleed"
	var own_units: Array = []
	if gun_own and Items.is_gun(it) and sim_in != null:
		var own: Array = r69_gun_figures(sim_in, it)     # (BUILD69-R) the gun's own figures in its dmg/s's place: a shot, the rate, the magazine, the jams
		h = [str(own[0][0]).get_slice(" ", 0), ""]     # the figure; its words the unit's first clause
		var su: String = Words.R69G["shot_unit"]
		var ss: String = Words.R69G["shot_unit_short"]
		var rest_long: Array = own.slice(1).map(func(f): return str(f[0]))
		var rest_short: Array = own.slice(1).map(func(f): return str(f[1]))
		own_units = [" · ".join([su] + rest_long), " · ".join([su] + rest_short), " · ".join([ss] + rest_short), " · ".join([ss] + rest_short.slice(0, 2)), " · ".join([ss, rest_short[0]]), ss]
		h[1] = own_units[0]
	if Items.is_paper(it) and sim_in != null:
		h = paper_headline(it, sim_in)
	if (tail is String and tail == "") and Items.base_res_words(it) != "":
		tail = Items.base_res_words(it)        # a resist built into the base (the welder's mask): the tail says so
	if it["slot"] == Data.ATTACHMENT and not Items.is_socketable(it):
		var own: String = Items.att_words(it, true, true)
		var first: String = own.get_slice(", ", 0)
		h = [first.get_slice(" ", 0), first.substr(first.find(" ") + 1)] if first.contains(" ") else [first, ""]
		var rest: String = own.substr(first.length()).trim_prefix(", ")
		tail = rest if tail == "" or tail == own else rest
		if Items.att_stat(it, "sling_pct") > 0.0:
			# a sling (30 Oct, the approved canvas): its figure the sentence, its chip when it counts
			h = [Words.MAG_WORDS["sling_fig"] % int(round(Items.att_stat(it, "sling_pct"))), ""]
			# its damage as the other parts' (31 Oct, PROBE33: the slings' damage back): "+10% dmg" beside the chip
			var others: Array = Array(own.split(", ")).filter(func(w): return not str(w).ends_with("secondary fire"))
			tail = [[Words.MAG_WORDS["sling_chip"]]] + ([", ".join(others)] if not others.is_empty() else [])
	if Items.is_mag(it):
		# a magazine (30 Oct, the approved canvas): its rounds of its size against the gun it feeds
		h = Items.headline(it, sim_in.mag_gun(it) if sim_in != null else null)     # the same gun as the card's chips, never over its size
		tail = ""                             # its chips go in the two rows under the figure (below)
	if h[1] == "" and UI.text_width(_figure, str(h[0])) > width and Items.att_stat(it, "sling_pct") > 0.0:
		h = ["%d%%" % int(round(Items.att_stat(it, "sling_pct"))), "secondary fire"]     # a narrow card: the figure and its unit
	_figure.text = h[0]
	var fw: float = ceilf(UI.text_width(_figure, h[0]))
	# a magazine (BUILD46-R, the canvas "Fiat – Rounds and magazines"): its rounds' box before the figure, "8 of 8 · Shells",
	# and "feeds the over-and-under" after it when the row has the room (the chip's then left off)
	var ix := 0.0
	_icon.visible = false
	_unit_tail.visible = false
	var mag_grade: String = str(it.get("ammo", "")) if Items.is_mag(it) and int(it.get("rounds", 0)) > 0 else ""
	if mag_grade != "":
		var gun = sim_in.mag_gun(it) if sim_in != null else null
		h = [h[0], Words.MAG_WORDS["unit_grade"] % [Items.mag_cap(it, gun), mag_grade]]
		var tex: Texture2D = Items.art({"slot": Data.AMMO, "base": mag_grade})
		if tex != null:
			_icon.texture = tex
			_icon.visible = true
			ix = ICON + 8.0
	_figure.position.x = ix
	_unit.position.x = ix + fw + 10
	_unit.size.x = maxf(10.0, width - _unit.position.x)
	# the tail's clauses: each a string, or [long, shorter, ...] forms; the fit
	# tries every clause long, then each clause's shorter forms, then fewer clauses
	var clauses: Array = []
	if tail is Array:
		clauses = tail
	elif tail != "":
		clauses = Array(tail.split(" · ", false))
	_unit.text = h[1]
	# the tail on its own line, the whole width: every clause long, then shorter forms, then fewer clauses
	var options := []
	var deepest := 1
	for c in clauses:
		if c is Array:
			deepest = maxi(deepest, c.size())
	# the first clause matters most: its long form is kept while the rest shorten or go
	for form_first in range(deepest):
		for n in range(clauses.size(), 0, -1):
			for form_rest in range(deepest):
				var words := []
				for k in range(n):
					var c = clauses[k]
					var form: int = form_first if k == 0 else form_rest
					words.append(str(c[mini(form, c.size() - 1)]) if c is Array else str(c))
				var line: String = " · ".join(words)
				if not options.has(line):
					options.append(line)
	if options.is_empty():
		options.append("")
	UI.fit(_tail, options)
	# the tail as chips (16 Oct, Matt: "everything on an item a chip but its headline"): a clause a chip, its short
	# forms when the row is full; rounds lead with how many, their grade's bonus a chip in the accent
	var tchips: Array = []
	for c in clauses:
		if (c is Array and not c.is_empty() and str(c[0]) != "") or (c is String and c != ""):
			tchips.append({"forms": c if c is Array else [c], "colour": Pal.TEXT_2})
	var edge: Array = Items.edge_forms(it)
	if not edge.is_empty():
		tchips.push_front({"forms": edge, "colour": Pal.ACCENT})     # the gun type's edge, the first thing under its figure (29 Oct)
	if Items.is_ammo(it):
		var ab := Items.base_of(it)
		h = [h[0], "rounds"]
		if ab.has("damage_pct"):
			tchips.append({"forms": ["+%d%% damage" % int(ab["damage_pct"]), "+%d%%" % int(ab["damage_pct"])], "colour": Pal.ACCENT})
		var gw: String = Items.grade_words(ab).trim_prefix(", ")
		if gw != "":
			tchips.append({"forms": [gw], "colour": Pal.ACCENT})
	elif Items.is_gun(it) and sim_in != null and Items.ammo_type(it) not in ["", "none"]:
		var stack: Dictionary = sim_in.feed_stack(it)
		var bonus: float = sim_in.grade_bonus(it)
		var grade: String = Items.grade_name(stack)     # the rounds' grade, not the magazine they're in (the fix round)
		if grade != "" and bonus > 0.0:
			tchips.append({"forms": ["%s: +%d%% damage" % [grade, int(bonus)], "+%d%% %s" % [int(bonus), Words.mid_base(grade)]], "colour": Pal.ACCENT})
	_unit.text = h[1]
	if not own_units.is_empty():
		_unit.size.x = maxf(10.0, _unit.size.x - 6.0)     # the line check's figure-and-unit read wants a few px spare
		UI.fit(_unit, own_units)     # (BUILD69-R) the longest of the gun's own figures that fits
	if mag_grade != "" and sim_in != null and sim_in.mag_gun(it) is Dictionary:
		var uw: float = ceilf(UI.text_width(_unit, str(h[1])))
		_unit_tail.text = UI.dots(Words.MAG_WORDS["feeds_low"] % Words.mid_base(str(sim_in.mag_gun(it)["base"])))     # the house capital after "·", measured as shown
		_unit_tail.position.x = _unit.position.x + uw + ceilf(UI.text_width(_unit, " "))     # one space, the separator in the words (the language pass)
		_unit_tail.size.x = ceilf(UI.text_width(_unit_tail, _unit_tail.text)) + 2.0
		_unit_tail.visible = _unit_tail.position.x + _unit_tail.size.x <= width
	_tchips = tchips
	warning = []
	_lay_tail()
	# the affixes as chips: the tier tag inside, the words short, in the tier's colour; two rows
	var lines: Array = Items.affix_lines(it, false, false)
	var short_lines: Array = Items.affix_lines(it, true, false)
	var n: int = lines.size()
	var chips_a := []
	# a unique's rule first, in its pink (13 Oct, Matt: the rule decides a unique against another, and no card said it)
	var rule := unique_rule(it)
	if not rule.is_empty():
		chips_a.append({"forms": rule, "colour": Pal.MYTHIC if it.get("mythic", false) else Pal.UNIQUE, "tag": "★"})
	if it.get("stamped", false):
		chips_a.append({"forms": [Words.STAMP["tag"], Words.STAMP["tag_short"]], "colour": Pal.ACCENT})     # stamped at the Bench for the County (26 Oct)
	for k in range(n):
		var tier: int = Items.affix_tier(it, k)
		chips_a.append({"forms": [lines[k], short_lines[k]], "colour": Pal.tier_color(tier), "tag": Words.T67["mark"] if tier >= Data.T67_TIER else "T%d" % tier})     # (BUILD67-I) T6's ◆
	# what its base does to every hit, in the element's colour, after the affixes - first with none, and the one left
	# off before an affix when a full unique runs out of room (14 Oct, Matt: the claw hammer bleeds and its card didn't
	# say; the top row had no room for it beside a long rarity)
	for c in conv_chips(it):
		chips_a.append({"forms": c["forms"], "colour": c["colour"]})
	# a paper's code as chips (16 Oct, Matt): the code, its bite and its pay - garbled glyphs till the Radio's open
	for c in paper_chips(it, sim_in):
		chips_a.append(c)
	# after them, as muted chips: the open slots ("1 open at the Bench"), a set's words in the set's tone, or "No affixes"
	var open: bool = not it.has("unique") and not Items.is_ammo(it) and not Items.is_mag(it) and not Items.is_paper(it) and not Items.is_medical(it) and not Items.is_grenade(it) and int(it["rarity"]) < Data.RARITIES.size() - 1 and Items.allowed_affixes(it["slot"]).size() > n
	var plain: bool = Items.is_ammo(it) or Items.is_mag(it) or Items.is_paper(it) or Items.is_medical(it) or Items.is_grenade(it) or Items.is_supplies(it) or Items.is_material(it)
	var has_extra: bool = (not extra.is_empty()) if extra is Array else (str(extra) != "")
	if has_extra:
		chips_a.append({"forms": extra if extra is Array else [str(extra)], "colour": Pal.SET if not plain else Pal.TEXT_2})
	elif open:
		var left: int = Data.RARITIES.size() - 1 - int(it["rarity"])
		chips_a.append({"forms": ["%d open in the Workshop" % left, "%d open" % left], "colour": Pal.TEXT_2})
	elif n == 0 and not plain:
		chips_a.append({"forms": ["No affixes"], "colour": Pal.TEXT_2})
	# always the short form (16 Oct, Matt: "res not resistance - looks odd when you see them side by side"): a card
	# never goes long because it has room while the one beside it went short
	if Items.is_mag(it):
		# a magazine's own chips (30 Oct, the approved canvas): its size, its reload, its pouches, the gun it feeds
		var mchips: Array = []
		for f in mag_chips(it, sim_in.mag_gun(it) if sim_in != null else null, sim_in):
			if _unit_tail.visible and str(f[0]).begins_with(Words.MAG_WORDS["feeds"].get_slice("%", 0)):
				continue                          # said after the figure (BUILD46-R): said once
			mchips.append({"forms": f, "colour": Pal.TEXT_2})
		chips_a = mchips + chips_a.filter(func(c): return not (str(c["forms"][0]) == "No affixes"))
	for c in chips_a:
		if c.has("forms") and (c["forms"] as Array).size() > 1:
			c["forms"] = [c["forms"].back()]
	_affixes.show_chips(chips_a, AFFIX_ROWS, true)
	_affixes.visible = not chips_a.is_empty()


## A warning in front of the tail's chips (18 Oct, Matt: the flavour always on the foot, so what stops the button - no
## rounds, no room, the level - moved up here): its forms long to short, in the warning's tone; [] takes it off.
func set_warning(forms: Array) -> void:
	warning = forms.filter(func(f): return str(f) != "")
	_lay_tail()


func _lay_tail() -> void:
	var chips: Array = _tchips.duplicate()
	if not warning.is_empty():
		chips.push_front({"forms": warning, "colour": "warn"})
	_tail_chips.show_chips(chips, 1, true)
	if not warning.is_empty() and _tail_chips.shown() == 0:
		_tail_chips.show_chips([chips[0]], 1, true)     # too long beside the tail (the review): the warning alone, the row's whole width
	var first: String = str(warning.back()).get_slice(" · ", 0) if not warning.is_empty() else ""
	if not warning.is_empty() and _tail_chips.shown() == 0 and first != str(warning.back()):
		_tail_chips.show_chips([{"forms": [first], "colour": "warn"}], 1, true)     # still none: its first part (BUILD45: "No magazine · Security guard's carbine to the floor" fitted no form, and the card said nothing)
	_tail_chips.visible = not chips.is_empty()


## A magazine's tail chips (30 Oct, the approved canvas): its size against the gun's own ("The gun's own 8", "×1.5 the
## gun's 8"), its reload against the gun's ("Reloads 1 s quicker"), its pouches past one, and the gun it feeds.
static func mag_chips(it: Dictionary, gun, sim_in) -> Array:
	var out: Array = []
	var own: int = Items.mag_size(gun) if gun is Dictionary else int(Data.MAG_SIZE.get(Items.mag_type(it), 30))
	var cap: int = Items.mag_cap(it, gun)
	if Data.MAG_KINDS.get(Items.mag_kind(it), {}).has("flat"):
		out.append([Words.MAG_WORDS["always"] % cap])     # the Hundred-round drum: its hundred whatever the gun (the fix round)
	elif not (gun is Dictionary):
		out.append([Words.MAG_WORDS["holds"] % cap])     # no worn gun takes it: its type's size (the three-stage review, UI 9)
	elif cap == own:
		out.append([Words.MAG_WORDS["own"] % own])
	else:
		out.append([Words.MAG_WORDS["times"] % [Words.fig1(float(cap) / float(maxi(1, own))), own]])
	var x: float = Items.mag_reload_x(it)
	if absf(x - 1.0) > 0.001:
		var base_s: float = sim_in.reload_s(gun) if (sim_in != null and gun is Dictionary) else float(Data.RELOAD_S.get(Items.mag_type(it), 2.0))
		var ds: float = absf(base_s * (x - 1.0))
		out.append([(Words.MAG_WORDS["quicker"] if x < 1.0 else Words.MAG_WORDS["slower"]) % Words.fig1(ds)])
	if Items.size(it) > 1:
		out.append([Words.MAG_WORDS["pouches"] % Items.size(it)])
	if gun is Dictionary:
		out.append([Words.MAG_WORDS["feeds"] % Words.mid_base(str(gun["base"]))])
	return out


## A paper's headline (16 Oct, Matt: "remove tin price from all papers - adds nothing"): what it is - Kev's story and
## its beat, encrypted, its code, or no code - never its worth.
static func paper_headline(it: Dictionary, sim_in) -> Array:
	var pl: Array = sim_in.paper_lines(it)
	if sim_in.story_of(it) >= 0:
		return [str(pl[0]), str(pl[1]).to_lower()]          # Kev's story, its beat
	if str(pl[0]) != "The Radio":
		return [str(pl[0]), ""]                             # encrypted, the deeds, the drawer: the tail says the rest
	var code: String = sim_in.word_taught_by(str(it["base"]))
	return [code, "code"] if code != "" else ["No code", ""]


## The glyphs an encrypted paper's chips are made of (16 Oct, Matt: "literally scrambled and garbled unicode"): all in
## Inter, so none comes up as a box.
const GARBLE := "ΞЖ§¤ØÞðƷΔΣΠΩψλξζЯЮЩЦФБДЛ¶†‡※∆∑∏≈≠±÷×◊#%&@"


## Words garbled glyph for glyph, the spaces kept: the same paper garbles the same way every time.
static func garble(text: String, key: String) -> String:
	var out := ""
	for i in range(text.length()):
		var ch: String = text[i]
		out += ch if ch == " " else GARBLE[absi(hash(key + str(i))) % GARBLE.length()]
	return out


## A paper's code as chips: its name, its bite and its pay in their colours once the Radio's open; before it, the same
## chips garbled. A paper with no code says so (a line of the before). Kev's papers, the deeds and a rule paper: none.
static func paper_chips(it: Dictionary, sim) -> Array:
	if sim == null or not Items.is_paper(it) or Items.is_deeds(it) or str(it.get("rule", "")) != "" or Items.opens(it) != "" or sim.story_of(it) >= 0:
		return []
	var code: String = sim.word_taught_by(str(it["base"]))
	var parts: Array = []                     # [words, colour]
	if code == "":
		parts.append(["No code: a line of the before", Pal.TEXT_3])
	else:
		var w: Array = sim.word_words(code, maxi(1, sim.word_tier_cap(sim.tier_depth(sim.reach))))
		parts.append([code, Pal.TEXT])
		if str(w[0]) != "":
			parts.append([str(w[0]), Pal.BAD])
		if str(w[1]) != "":
			parts.append([str(w[1]), Pal.GOOD])
	var out: Array = []
	var open: bool = sim.room_open("radio")
	if not open:
		while parts.size() < 3:
			parts.append(["a line of the before", Pal.TEXT_3])     # three garbled chips on every paper: the count gives nothing away (the review)
	for k in range(parts.size()):
		var words: String = str(parts[k][0])
		var forms: Array = [words] if k == 0 else [words, words.get_slice(", ", 0)]     # a shorter form for a narrow card (the review)
		if open:
			if code != "":
				out.append({"forms": forms, "colour": parts[k][1]})     # no code: the line above says so once it's read
		else:
			out.append({"forms": forms.map(func(f): return garble(str(f), str(it["base"]) + str(k))), "colour": Pal.TEXT_3})
	return out


## A unique's rule as chip forms, [long, short], or [] for anything else.
static func unique_rule(it: Dictionary) -> Array:
	if not it.has("unique") and not it.has("pattern"):
		return []
	var named: String = str(it.get("unique", it.get("pattern", "")))     # a pattern carries its unique's rule (24 Oct)
	for u in Data.UNIQUES + Data.ISSUED:
		if u["name"] == named:
			var long: String = str(u.get("words", ""))
			if it.get("issued", false) and long != "":
				return [long + " · kept on a death · counts as a piece of your set", long, str(u.get("short", long))]     # the third review: the screen never said
			return [long, str(u.get("short", long))] if long != "" else []
	return []


## A base's share of every hit as an element, as affix-row chips in the element's colour: "10% of hits as bleed",
## short "10% bleed"; one a kind it has. A part's own figure says it already, so none for a part; none for a secondary.
static func conv_chips(it: Dictionary) -> Array:
	var out := []
	if it["slot"] == Data.ATTACHMENT or it["slot"] == "Secondary":
		return out                        # a secondary's base conversion never reaches the hit (30 Oct, the review's I4): the Primary's alone
	var b: Dictionary = Items.base_of(it)
	for el in ["fire", "frost", "poison", "shock", "bleed"]:
		var v: float = float(b.get("conv_%s_pct" % el, 0))
		if v > 0.0:
			out.append({"forms": ["%d%% of hits as %s" % [int(round(v)), el], "%d%% %s" % [int(round(v)), el]], "colour": Pal.ELEMENT_COLOURS[el], "el": el})
	return out


## [words, tone] a chip: the slot, the type, the rarity (in its tone), the level, the cells.
static func _chip_words(it: Dictionary, cells_chip := true) -> Array:
	var out := []
	var slot: String = it["slot"]
	if slot == Data.ATTACHMENT:
		out.append(["Socketable" if Items.is_socketable(it) else ("Melee part" if Items.is_melee_mount(it.get("mount", "")) else "Gun part"), ""])
		if not Items.is_socketable(it):
			out.append([Items.mount_name(it["mount"]), ""])
	elif slot == Data.AMMO:
		out.append(["Rounds", ""])
		out.append([Items.type_name(str(Items.base_of(it).get("type", ""))), ""])     # sentence case, SMG as it is (30 Oct, parked item 5: "shotgun"); Nails' "Nail" as the magazines (the fix round)
	elif slot == Data.MEDICAL:
		out.append(["Cure" if Items.is_cure(it) else "Med", ""])
		if Items.is_cure(it):
			out.append([str(Items.cure_of(it)).capitalize(), Items.cure_of(it)])     # what it stops, in the element's tone (28 Oct)
	elif slot == Data.GRENADE:
		out.append(["Grenade", ""])
		out.append([str(Items.base_of(it)["type"]).capitalize(), str(Items.base_of(it)["type"])])
	elif slot == Data.PAPER:
		out.append(["Paper", ""])
	elif slot == Data.MATERIAL:
		if not Items.is_scrap(it):
			out.append(["Material", ""])     # a rebuild material as a pack item (1 Nov); scrap's title says it, no chip (the review)
	elif slot == Data.MAGAZINE:
		out.append([Words.MAG_WORDS["chip"], ""])     # a magazine (30 Oct): what it is, its type, its level
		out.append([Items.type_name(Items.mag_type(it)), ""])
		out.append(["Level %d" % int(it.get("tier", 1)), ""])
	else:
		out.append([slot, ""])
		var tw := Items.type_word(it)
		if Items.is_melee(it):
			out.append(["Melee", ""])
		elif tw != "":
			out.append([tw.capitalize() if tw != "SMG" else tw, ""])
	var rarity_tone: String = Pal.item_tone(it)
	if slot == Data.ATTACHMENT and Items.base_of(it).has("type"):
		out.append([Items.only_words(it), ""])
	var plain: bool = slot == Data.AMMO or slot == Data.PAPER or slot == Data.MEDICAL or slot == Data.GRENADE or slot == Data.SUPPLIES or slot == Data.MAGAZINE or slot == Data.MATERIAL
	if not plain or int(it["rarity"]) > 0:
		out.append([Items.rarity_name(it), rarity_tone])
	if not plain:
		# worn gear: the runner's level it needs (15 Oct, gear gated by level); a part: its item level, the Bench's figure
		out.append(["Level %d" % Items.wear_level(it), ""] if slot in Data.SLOTS else ["Item level %d" % Items.ilvl(it), ""])
	var cells: int = Items.size(it)
	if cells > 1 and cells_chip:
		out.append(["%d cells" % cells, ""])
	return out


func text_nodes() -> Array:
	var out: Array = [_title, _figure, _unit]
	if _unit_tail.visible:
		out.append(_unit_tail)
	if _tail_chips.visible:
		out.append_array(_tail_chips.text_nodes())
	for k in range(CHIPS):
		if _chips[k].visible:
			out.append(_chip_labels[k])
	if _affixes.visible:
		out.append_array(_affixes.text_nodes())
	out.append_array(_rows)
	return out


## The figure and its unit share a row: the pair the fit check judges.
func line_pairs() -> Array:
	return [[_figure, _unit]]


# ------------------------------------------------------------------ (BUILD69-R) a gun's own figures

## Set by the gear screens' compare (the pick panel): a gun's headline is its own figures - damage a shot, then the rate,
## the magazine and the jams - in its dmg/s's place (the Kit mockup's table; endgame_rail.md §4). Elsewhere as it was.
var gun_own := false
const Fmt := preload("res://scripts/ui/fmt.gd")


## A gun's own figures, each [long, short]: "1,840 a shot", "0.9 a second", "8 rounds", "jams 1 in 60" / "never jams".
static func r69_gun_figures(sim, gun: Dictionary) -> Array:
	var b: Dictionary = Items.base_of(gun)
	var rof: float = maxf(float(b.get("rof", 1.0)), 0.0001)
	var shot: float = Items.dps_whole(gun) / rof
	var out: Array = [[Words.R69G["shot"] % Fmt.group(int(round(shot))), Words.R69G["shot_short"] % Fmt.short_num(shot)],
		[Words.R69G["rate"] % rof, Words.R69G["rate_short"] % rof]]
	var mag: int = Items.mag_size(gun)
	if mag > 0:
		out.append([Words.R69G["mag"] % mag, Words.R69G["mag_short"] % mag])
	var jam: float = sim.f66_jam_pct(gun) if sim != null else 0.0
	var every: int = int(round(100.0 / jam)) if jam > 0.0 else 0
	out.append([Words.R69G["jams"] % every, Words.R69G["jams_short"] % every] if jam > 0.0 else [Words.R69G["never"], Words.R69G["never_short"]])
	return out
