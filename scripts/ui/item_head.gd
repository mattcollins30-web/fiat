extends Control
## An item's head on a panel, the way the mockup's option B lays it out: the
## name, a row of chips for what it is (slot, type, rarity, level, cells), and
## the headline figure big with its unit and a tail ("takes SMG rounds · 600
## carried"). Under it, the affixes as chips in the tier's colour with a T-tag
## inside, over two rows, and a muted "open" line when the bench could add
## one. Every screen with an item panel (the Lock-up, the fence, the clinic,
## the run's pick) mounts one in its left column; the right column stays the
## screen's own (the compare, the shelf's price, the pack's room).

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Chips := preload("res://scripts/ui/chips.gd")

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
var _tail: Label
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
	tail_y = headline_y + head_h
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
	var fsize: int = Pal.TITLE if compact else Pal.HEADLINE
	_figure = UI.label(self, Rect2(0, headline_y, width, head_h), "", "SemiBold", fsize, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(self, Rect2(0, headline_y, width, head_h), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_tail = UI.label(self, Rect2(0, tail_y, width, TAIL_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_affixes = Chips.new(width)
	_affixes.position = Vector2(0, rows_y)
	add_child(_affixes)
	for k in range(rows):
		var y := rows_y + affix_h + 4 + k * row_h
		_rows.append(UI.label(self, Rect2(0, y, width, row_h), "", "Regular", Pal.CELL_TEXT_BIG + 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))


## `tail` follows the headline: "takes SMG rounds · 600 carried". `extra` is a
## line for the fourth row when there's no open affix to say (a set's words).
## `cells`: the cells chip, left off where the panel's kicker carries the cells.
func show_item(it: Dictionary, sim, tail = "", extra = "", cells := true) -> void:
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
	var h := Items.headline(it)
	if (tail is String and tail == "") and Items.base_res_words(it) != "":
		tail = Items.base_res_words(it)        # a resist built into the base (the welder's mask): the tail says so
	if it["slot"] == Data.ATTACHMENT and not Items.is_socketable(it):
		var own: String = Items.att_words(it, true, true)
		var first: String = own.get_slice(", ", 0)
		h = [first.get_slice(" ", 0), first.substr(first.find(" ") + 1)] if first.contains(" ") else [first, ""]
		var rest: String = own.substr(first.length()).trim_prefix(", ")
		tail = rest if tail == "" or tail == own else rest
	_figure.text = h[0]
	var fw: float = ceilf(UI.text_width(_figure, h[0]))
	_unit.position.x = fw + 10
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
	# the affixes as chips: the tier tag inside, the words short, in the tier's colour; two rows
	var lines: Array = Items.affix_lines(it, false, false)
	var short_lines: Array = Items.affix_lines(it, true, false)
	var n: int = lines.size()
	var chips_a := []
	for k in range(n):
		var tier: int = Items.affix_tier(it, k)
		chips_a.append({"forms": [lines[k], short_lines[k]], "colour": Pal.tier_color(tier), "tag": "T%d" % tier})
	# after them, as muted chips: the open slots ("1 open at the bench"), a set's words in the set's tone, or "No affixes"
	var open: bool = not it.has("unique") and not Items.is_ammo(it) and not Items.is_paper(it) and not Items.is_medical(it) and not Items.is_grenade(it) and int(it["rarity"]) < Data.RARITIES.size() - 1 and Items.allowed_affixes(it["slot"]).size() > n
	var plain: bool = Items.is_ammo(it) or Items.is_paper(it) or Items.is_medical(it) or Items.is_grenade(it)
	var has_extra: bool = (not extra.is_empty()) if extra is Array else (str(extra) != "")
	if has_extra:
		chips_a.append({"forms": extra if extra is Array else [str(extra)], "colour": Pal.SET if not plain else Pal.TEXT_2})
	elif open:
		var left: int = Data.RARITIES.size() - 1 - int(it["rarity"])
		chips_a.append({"forms": ["%d open at the bench" % left, "%d open" % left], "colour": Pal.TEXT_2})
	elif n == 0 and not plain:
		chips_a.append({"forms": ["No affixes"], "colour": Pal.TEXT_2})
	_affixes.show_chips(chips_a, AFFIX_ROWS)
	_affixes.visible = not chips_a.is_empty()


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
		out.append([Items.type_word(it) if Items.type_word(it) != "" else str(Items.base_of(it).get("type", "")), ""])
	elif slot == Data.MEDICAL:
		out.append(["Med", ""])
	elif slot == Data.GRENADE:
		out.append(["Grenade", ""])
		out.append([str(Items.base_of(it)["type"]).capitalize(), str(Items.base_of(it)["type"])])
	elif slot == Data.PAPER:
		out.append(["Paper", ""])
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
	var plain: bool = slot == Data.AMMO or slot == Data.PAPER or slot == Data.MEDICAL or slot == Data.GRENADE
	if not plain or int(it["rarity"]) > 0:
		out.append([Items.rarity_name(it), rarity_tone])
	if not plain:
		out.append(["Level %d" % Items.ilvl(it), ""])
	var cells: int = Items.size(it)
	if cells > 1 and cells_chip:
		out.append(["%d cells" % cells, ""])
	return out


func text_nodes() -> Array:
	var out: Array = [_title, _figure, _unit, _tail]
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
