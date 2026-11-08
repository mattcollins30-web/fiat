extends Control
## (BUILD69-A) The Radio's fifth view, the convoys (docs/design/endgame_rail.md §4; the canvas's Convoys board, approved
## 7 Nov): opens with the County's first place. Kev hears a lorry every few runs, its cargo known before you go: the
## lorries heard down the left with Kev's line under them; the picked one on the right - the cargo, the plan (two of
## the crew: one holds the road, one cracks the load), the read (the odds' word, the clock, the men on the lorry), Hit
## the lorry and Let it pass. The band is the lorry's route. The sim is builder E's (sim.e69_*, $S/e69_notes.md).
##
## Signals: `acted` after a hit (main follows the run to the Map) or a pass.

signal acted
signal went_out                     # (fix 69) a hit started the run: the shell goes to the Map

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const People := preload("res://scripts/ui/people.gd")
const Arm := preload("res://scripts/ui/arm.gd")

const PAD := 20
const HEAD_H := Pal.BAND_H
const BODY_Y := HEAD_H + 8
const BODY_H := Pal.ROOM_H - BODY_Y
const GAP := 12
const BP := 16                        # a box's padding
const LIST_W := 470                   # the lorries heard
const DETAIL_X := LIST_W + GAP
const DETAIL_W := Pal.GRID_W - DETAIL_X
const DIW := DETAIL_W - 2 * BP
const ROW_Y := 84                     # the first lorry under the head and the title
const ROW_H := 100
const ROW_GAP := 10
const ROWS := 3                       # Data.CONVOY69_HELD (the smoke holds them equal)
const PIC_W := 150                    # a lorry's cargo picture
const KEV_LINES := 4
const CARGO_H := 110
const CARGO_PIC := Vector2(240, 84)
const PLAN_Y := CARGO_H + 2 * BP
const ROLE_Y := PLAN_Y + UI.HEAD_H + 6
const ROLE_H := 96
const FACE := 64
const PICK_Y := ROLE_Y + ROLE_H + 10  # the crew to put in the picked role
const PICK_H := 44
const PICK_LABEL_W := 220
const PICKS := 5                      # the crew bar the runner: six classes, one of them you
const TILE_Y := PICK_Y + PICK_H + 14
const TILE_H := 78
const NOTE_Y := TILE_Y + TILE_H + 14
const BTN_H := Pal.BUTTON_H
const ROLES := ["hold", "crack"]
const INFO := Color("7fb7e6")         # the convoys' blue (the canvas's "Convoy heard"; R's Pal.INFO once merged)
## A route's picture: the place its convoy leaves from, borrowed from the places' art (A69 list for the art pass).
const ROUTE_ART69 := ["The Toll Plaza", "The Container Port", "The Treasury", "The Distribution Centre", "The Services", "The Truck Stop"]

var sim
var selected := 0                     # the lorry picked, by its place in the list
var picks := {"hold": "", "crack": ""}     # the crew in each role
var role_on := "hold"                 # the role the crew bar fills
var head_band := {}
var _kicker: Label
var _headline: Label
var _unit: Label
var _sub: Label
var _list_head: Label
var _list_title: Label
var _rows: Array = []                 # {button, cell, name, route, passes}
var _none: Array = []                 # the empty list's two lines
var _kev_head: Label
var _kev: Array = []
var _detail: Panel
var _cargo_cell
var _cargo_head: Label
var _cargo_name: Label
var _cargo_line: Label
var _plan_head: Label
var _roles: Array = []                # {button, face, kicker, name, fx}
var _pick_label: Label
var _picks: Array = []                # the crew bar's buttons
var _tiles: Array = []                # {panel, value, sub}
var _note: Array = []
var _block: Label
var _hit: Button
var _pass: Button
var _empty: Array = []                # the detail's lines with nothing heard
var _pass_arm := Arm.new()            # letting it pass asks twice: it's gone after
var _shown := ""
var _read := {}
var _read_sig := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	head_band = UI.head_art(head, "The radio")
	_kicker = UI.head(head, Rect2(PAD, 8, 440, 24), Words.A69["c_kicker"])     # (fix 69) the kicker as the others are
	_headline = UI.label(head, Rect2(PAD, 32, 440, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, 440, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(head, Rect2(PAD, 84, 600, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_build_list()
	_build_detail()


func _build_list() -> void:
	var lp := UI.panel(self, Rect2(0, BODY_Y, LIST_W, BODY_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = LIST_W - 2 * BP
	_list_head = UI.head(lp, Rect2(BP, 14, iw, UI.HEAD_H), Words.A69["c_list_head"])
	_list_head.add_theme_color_override("font_color", INFO)
	_list_title = UI.label(lp, Rect2(BP, 38, iw, 38), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(ROWS):
		var b := Button.new()
		b.position = Vector2(BP - 4, ROW_Y + k * (ROW_H + ROW_GAP))
		b.size = Vector2(iw + 8, ROW_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick.bind(k))
		lp.add_child(b)
		var r := {"button": b}
		var cell := ItemCell.new()
		cell.position = Vector2(10, 10)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cell)
		r["cell"] = cell
		var tx: float = PIC_W + 24
		var tw: float = iw + 8 - tx - 10
		r["name"] = UI.label(b, Rect2(tx, 10, tw, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["route"] = UI.label(b, Rect2(tx, 40, tw, 24), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["passes"] = UI.label(b, Rect2(tx, 66, tw, 24), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_rows.append(r)
	for k in range(2):
		_none.append(UI.label(lp, Rect2(BP, ROW_Y + 8 + k * 30, iw, 28), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var ky: float = ROW_Y + ROWS * (ROW_H + ROW_GAP) + 4
	var kp := UI.panel(lp, Rect2(BP - 4, ky, iw + 8, BODY_H - ky - BP), UI.box(Pal.CARD, 6, 1, Pal.CARD_LINE))
	_kev_head = UI.label(kp, Rect2(14, 10, iw - 20, 24), "Kev", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(KEV_LINES):
		_kev.append(UI.label(kp, Rect2(14, 36 + k * 28, iw - 20, 28), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))


func _build_detail() -> void:
	_detail = UI.panel(self, Rect2(DETAIL_X, BODY_Y, DETAIL_W, BODY_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var cp := UI.panel(_detail, Rect2(BP, BP, DIW, CARGO_H), UI.box(Pal.CARD, 6))
	_cargo_cell = ItemCell.new()
	_cargo_cell.position = Vector2(12, (CARGO_H - CARGO_PIC.y) / 2.0)
	_cargo_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp.add_child(_cargo_cell)
	var tx: float = 12 + CARGO_PIC.x + 20
	var tw: float = DIW - tx - 12
	_cargo_head = UI.head(cp, Rect2(tx, 12, tw, UI.HEAD_H), Words.A69["c_cargo_head"])
	_cargo_name = UI.label(cp, Rect2(tx, 36, tw, 36), "", "SemiBold", Pal.NAME - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_cargo_line = UI.label(cp, Rect2(tx, 74, tw, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_plan_head = UI.head(_detail, Rect2(BP, PLAN_Y, DIW, UI.HEAD_H), Words.A69["c_plan_head"])
	@warning_ignore("integer_division")
	var rw: int = (DIW - GAP) / 2
	for k in range(ROLES.size()):
		var b := Button.new()
		b.position = Vector2(BP + k * (rw + GAP), ROLE_Y)
		b.size = Vector2(rw, ROLE_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_role.bind(ROLES[k]))
		_detail.add_child(b)
		var r := {"button": b, "role": ROLES[k]}
		r["face"] = People.rect(b, Vector2(14, (ROLE_H - FACE) / 2.0), FACE / 128.0)
		r["plus"] = UI.label(b, Rect2(14, (ROLE_H - FACE) / 2.0, FACE, FACE), "+", "Regular", Pal.TITLE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
		var fx: float = 14 + FACE + 16
		var fw: float = rw - fx - 12
		r["kicker"] = UI.label(b, Rect2(fx, 10, fw, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["name"] = UI.label(b, Rect2(fx, 32, fw, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["fx"] = UI.label(b, Rect2(fx, 64, fw, 22), "", "Regular", Pal.CELL_TEXT, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
		_roles.append(r)
	_pick_label = UI.label(_detail, Rect2(BP, PICK_Y, PICK_LABEL_W, PICK_H), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	@warning_ignore("integer_division")
	var pw: int = (DIW - PICK_LABEL_W - (PICKS - 1) * 8) / PICKS
	for k in range(PICKS):
		var pb := UI.button(_detail, Rect2(BP + PICK_LABEL_W + k * (pw + 8), PICK_Y, pw, PICK_H), false)
		pb.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		pb.pressed.connect(_pick_crew.bind(k))
		_picks.append(pb)
	@warning_ignore("integer_division")
	var tw3: int = (DIW - 2 * GAP) / 3
	for k in range(3):
		var p := UI.panel(_detail, Rect2(BP + k * (tw3 + GAP), TILE_Y, tw3, TILE_H), UI.box(Pal.CARD, 6))
		var t := {"panel": p}
		t["value"] = UI.label(p, Rect2(14, 6, tw3 - 28, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["sub"] = UI.label(p, Rect2(14, 46, tw3 - 28, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_tiles.append(t)
	for k in range(2):
		_note.append(UI.label(_detail, Rect2(BP, NOTE_Y + k * 28, DIW, 28), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var by: float = BODY_H - BP - BTN_H
	_block = UI.label(_detail, Rect2(BP, by - 34, DIW, 26), "", "Regular", Pal.CELL_TEXT_BIG - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var hw: float = roundf(DIW * 0.58)
	_hit = UI.button(_detail, Rect2(BP, by, hw, BTN_H), true)
	_hit.pressed.connect(_on_hit)
	_pass = UI.button(_detail, Rect2(BP + hw + GAP, by, DIW - hw - GAP, BTN_H), false)
	_pass.pressed.connect(_on_pass)
	for k in range(2):
		_empty.append(UI.label(_detail, Rect2(BP, BP + 10 + k * 32, DIW, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))


# ------------------------------------------------------------------ showing

func convoys() -> Array:
	return sim.e69["convoys"] if sim != null else []


func show_state(s) -> void:
	sim = s
	if sim == null:
		return
	if visible:
		sim.e69_convoys_looked()         # the rail's "Convoy heard" goes once the board's been seen
	var cs: Array = convoys()
	selected = clampi(selected, 0, maxi(0, cs.size() - 1))
	var crew: Array = sim.e69_crew_for_roles()
	for r in ROLES:
		if picks[r] != "" and not (picks[r] in crew):
			picks[r] = ""                 # a crew no longer played (a fresh camp, a load)
	var sig := "%s|%d|%s|%s|%s|%d|%s|%d|%s" % [str(cs.map(func(c): return [c["id"], c["passes"]])), selected, str(picks), role_on, str(crew), int(sim.cash), str(sim.on_mission()), sim.e69_runs(), _pass_arm.sig()]
	if sig == _shown:
		return
	_shown = sig
	_show_list(cs)
	_show_detail(cs, crew)


func _show_list(cs: Array) -> void:
	var n: int = cs.size()
	UI.fit(_list_title, [Words.A69["c_title"] % n if n != 1 else Words.A69["c_title_one"], Words.A69["c_title_short"] % n] if n > 0 else [Words.A69["c_title_none"]])
	for k in range(ROWS):
		var r: Dictionary = _rows[k]
		var on: bool = k < n
		r["button"].visible = on
		if not on:
			continue
		var c: Dictionary = cs[k]
		var it: Dictionary = sim.e69_convoy_cargo_item(k)
		r["cell"].visible = not it.is_empty()
		if not it.is_empty():
			r["cell"].show_item(it, false, Vector2(PIC_W, ROW_H - 20))
		UI.fit(r["name"], [cargo_words(c), Items.full_name(it) if not it.is_empty() else ""] + ([str(it["base"])] if not it.is_empty() else []))     # (0.15.4) the base last: "The Quartermaster's Manual" ran 16 px past the row
		UI.fit(r["route"], ["%s · level %d" % [route_title(c), int(c["level"])], "Level %d" % int(c["level"])])
		var passes: int = int(c["passes"])
		UI.fit(r["passes"], [Words.A69["c_passes"] % [passes, "" if passes == 1 else "s"], "%d run%s" % [passes, "" if passes == 1 else "s"]])
		r["passes"].add_theme_color_override("font_color", Pal.ACCENT if k == selected else Pal.TEXT_2)
		_style_row(r["button"], k == selected)
	for k in range(_none.size()):
		_none[k].visible = n == 0
	if n == 0:
		UI.fit(_none[0], [Words.A69["c_none"]])
		UI.fit(_none[1], [Words.A69["c_none2"] % Data.CONVOY69_EVERY, Words.A69["c_none2_short"]])
	var kev: String = ""
	if n > 0:
		var lines: Array = Words.E69["kev"]
		kev = "\"%s\"" % str(lines[int(cs[selected].get("line", 0)) % lines.size()])
	else:
		kev = "\"%s\"" % Words.A69["c_kev_quiet"]
	UI.wrap(_kev, kev)


func _show_detail(cs: Array, crew: Array) -> void:
	var n: int = cs.size()
	var on: bool = n > 0
	for ch in _detail.get_children():
		if ch is Control:
			ch.visible = on
	for l in _empty:
		l.visible = not on
	if not on:
		UI.fit(_empty[0], [Words.A69["c_empty"]])
		UI.fit(_empty[1], [Words.A69["c_empty2"]])
		UI.set_head_art(head_band, UI.place_texture("The radio"))
		UI.fit(_headline, [Words.A69["c_band_none"]])
		_unit.text = ""
		_sub.text = ""     # (fix 69) the empty board says it once (c_none2)
		return
	var c: Dictionary = cs[selected]
	var it: Dictionary = sim.e69_convoy_cargo_item(selected)
	# the band: the lorry's route, its picture the place it leaves from
	UI.set_head_art(head_band, UI.place_texture(route_art(c)))
	UI.fit(_headline, [route_title(c)])
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.size.x = 440 + PAD - _unit.position.x - BAND_SLACK     # (0.15.4) a few px spare: "The docks road" + "out of the docks" ran 3 px past the line
	UI.fit(_unit, [route_from(c), ""])
	var passes: int = int(c["passes"])
	UI.fit(_sub, [Words.A69["c_band_sub"] % [int(c["level"]), passes, "" if passes == 1 else "s"], "Level %d" % int(c["level"])])
	# the cargo
	_cargo_cell.visible = not it.is_empty()
	if not it.is_empty():
		_cargo_cell.show_item(it, false, CARGO_PIC)
	UI.fit(_cargo_name, [Items.full_name(it) if not it.is_empty() else cargo_words(c), cargo_words(c)] + ([str(it["base"])] if not it.is_empty() else []))     # (0.15.4) the base last
	_cargo_name.add_theme_color_override("font_color", Pal.TEXT)
	var kind: String = str(c["cargo"].get("kind", "slot"))
	var what: String = str(Words.A69["c_kind"].get(kind, ""))
	UI.fit(_cargo_line, [Words.A69["c_cargo_line"] % [Items.rarity_name(it), Items.ilvl(it), what] if not it.is_empty() else what,
		Words.A69["c_cargo_line_short"] % [Items.rarity_name(it), Items.ilvl(it)] if not it.is_empty() else what])     # (fix 69) two "·" at most
	# the plan
	for r in _roles:
		var role: String = r["role"]
		var who: String = picks[role]
		UI.fit(r["kicker"], [Words.A69["c_role"][role]])
		var has: bool = who != ""
		r["plus"].visible = not has
		People.show(r["face"], who if has else "")
		UI.fit(r["name"], [Words.A69["c_the"] % who if has else Words.A69["c_pick_one"]])
		UI.fit(r["fx"], role_forms(who if has else best_for(role, crew), role, not has))
		r["fx"].add_theme_color_override("font_color", Pal.GOOD if has else Pal.TEXT_3)
		_style_row(r["button"], role == role_on, not has)
	UI.fit(_pick_label, [Words.A69["c_pick_for"] % str(Words.A69["c_role_low"][role_on]), str(Words.A69["c_role"][role_on]) + ":"])
	for k in range(PICKS):
		var pb: Button = _picks[k]
		pb.visible = k < crew.size()
		if not pb.visible:
			continue
		var who2: String = str(crew[k])
		UI.fit_button(pb, [who2])
		var other: String = picks["crack" if role_on == "hold" else "hold"]
		pb.disabled = who2 == other
		UI.style_button(pb, false, "good" if picks[role_on] == who2 else "")
	if crew.is_empty():
		UI.fit(_pick_label, [Words.A69["c_no_crew"], Words.A69["c_no_crew_short"]])
	# the read
	var rd: Dictionary = _read_for(selected)
	var word: String = str(rd.get("word", ""))
	UI.fit(_tiles[0]["value"], [str(Words.A69["c_odds"].get(word, word.capitalize()))])
	_tiles[0]["value"].add_theme_color_override("font_color", odds_colour(word))
	if bool(rd.get("after", false)):
		UI.fit(_tiles[0]["sub"], [Words.A69["c_after_sub"], ""])     # (fix 69) no figure while a run's out
	else:
		UI.fit(_tiles[0]["sub"], [Words.A69["c_odds_sub"] % roundi(float(rd.get("odds", 0.0)) * 100.0), Words.A69["c_odds_sub_short"] % roundi(float(rd.get("odds", 0.0)) * 100.0)])
	UI.fit(_tiles[1]["value"], [Fmt.clock(float(rd.get("clock_s", c.get("clock_s", 0.0))))])
	UI.fit(_tiles[1]["sub"], [Words.A69["c_clock_sub"], Words.A69["c_clock_sub_short"]])
	UI.fit(_tiles[2]["value"], [Words.A69["c_men"] % int(rd.get("men", c.get("men", 0)))])
	UI.fit(_tiles[2]["sub"], [Words.A69["c_men_sub"], Words.A69["c_men_short"]])
	UI.wrap(_note, Words.A69["c_note"] % [route_name(c), int(c["level"])])
	# the foot
	var block: String = sim.e69_convoy_block(selected, picks["hold"], picks["crack"])
	if block == "" and (picks["hold"] == "" or picks["crack"] == ""):
		block = Words.A69["c_need_two"]
	UI.fit(_block, [block, ""])
	_hit.disabled = block != ""
	UI.fit_button(_hit, [Words.A69["c_hit"]])
	UI.style_button(_hit, block == "")
	var armed: bool = _pass_arm.holds("pass", str(c["id"]))
	UI.fit_button(_pass, UI.ask_forms(Words.A69["c_pass"]) if armed else [Words.A69["c_pass"]])
	UI.style_button(_pass, false, "bad" if armed else "")
	_pass.disabled = sim.on_mission()


## The read for the lorry and the picks, once a change (it sets up the run's figures to read them).
func _read_for(k: int) -> Dictionary:
	var c: Dictionary = sim.e69_convoy(k)
	var key := "%s|%s|%s|%d|%d" % [str(c.get("id", -1)), picks["hold"], picks["crack"], sim.level(), sim.e69_runs()]
	if key != _read_sig or sim.on_mission():
		_read = sim.e69_convoy_read(k, picks["hold"], picks["crack"])
		_read_sig = key
	return _read


func _style_row(b: Button, on: bool, dashed := false) -> void:
	var line: Color = Pal.ACCENT if on else Pal.CARD_LINE
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		var bx := UI.box(Pal.SELECT if st == "hover" else Pal.CARD, 6, 2 if on else 1, line)
		if dashed and not on:
			bx.bg_color = Pal.PANEL
		b.add_theme_stylebox_override(st, bx)


static func odds_colour(word: String) -> Color:
	return {"safe": Pal.GOOD, "fair": Pal.TEXT, "risky": Pal.WARN, "long shot": Pal.BAD}.get(word, Pal.TEXT)


## (fix 69) A route standing alone (a headline, a row's title): its first letter up; in a line, route_name's lower case.
func route_title(c: Dictionary) -> String:
	var r: String = route_name(c)
	return r.substr(0, 1).to_upper() + r.substr(1)


func route_name(c: Dictionary) -> String:
	var rs: Array = Words.E69["routes"]
	return str(rs[int(c.get("route", 0)) % rs.size()])


func route_from(c: Dictionary) -> String:
	var fs: Array = Words.E69["from"]
	return str(fs[int(c.get("route", 0)) % fs.size()])


static func route_art(c: Dictionary) -> String:
	return ROUTE_ART69[int(c.get("route", 0)) % ROUTE_ART69.size()]


## The cargo in a few words: "Bullion carbine", "Gloves: any unique", "A set: the Issuer's two" - E's name for it.
static func cargo_words(c: Dictionary) -> String:
	return str(c.get("cargo", {}).get("name", ""))


## A role's effect for a crew member, long to short; `maybe` reads it as what they'd do ("The Scrapper: ...").
func role_forms(who: String, role: String, maybe: bool) -> Array:
	if who == "":
		return [""]
	var fx: Dictionary = sim.e69_role_effect(who, role)
	var line: String
	if role == "hold":
		line = Words.A69["c_fx_hold"] % absi(int(fx.get("clock_pct", 0)))
	else:
		line = Words.A69["c_fx_crack"] % absi(int(fx.get("men_pct", 0)))
	if maybe:
		return ["%s: %s" % [Words.A69["c_the"] % who, line.substr(0, 1).to_lower() + line.substr(1)], line]
	return [line]


## The crew best at a role, for the empty card's hint.
func best_for(role: String, crew: Array) -> String:
	var best := ""
	var top := -1
	for who in crew:
		var fx: Dictionary = sim.e69_role_effect(str(who), role)
		var v: int = absi(int(fx.get("clock_pct", fx.get("men_pct", 0))))
		if v > top:
			top = v
			best = str(who)
	return best


# ------------------------------------------------------------------ acting

func _pick(k: int) -> void:
	selected = k
	_pass_arm.clear()
	_shown = ""
	show_state(sim)


func _pick_role(role: String) -> void:
	role_on = role
	_shown = ""
	show_state(sim)


func _pick_crew(k: int) -> void:
	var crew: Array = sim.e69_crew_for_roles()
	if k >= crew.size():
		return
	var who: String = str(crew[k])
	picks[role_on] = "" if picks[role_on] == who else who
	if picks[role_on] != "" and picks["crack" if role_on == "hold" else "hold"] == "":
		role_on = "crack" if role_on == "hold" else "hold"     # the next empty role takes the bar
	_shown = ""
	show_state(sim)


func _on_hit() -> void:
	if sim == null or sim.e69_convoy_block(selected, picks["hold"], picks["crack"]) != "":
		return
	if sim.e69_convoy_hit(selected, picks["hold"], picks["crack"]):
		selected = 0
		_shown = ""
		acted.emit()
		went_out.emit()     # (fix 69) to the Map with the run open, as the Radio's Set off


func _on_pass() -> void:
	if sim == null or convoys().is_empty():
		return
	var c: Dictionary = sim.e69_convoy(selected)
	if not _pass_arm.press("pass", str(c["id"])):
		_shown = ""
		show_state(sim)
		return
	if sim.e69_convoy_pass(selected):
		selected = 0
		_shown = ""
		acted.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_pass_arm.clear()
		_shown = ""


# ------------------------------------------------------------------ for the tests

func hit_button() -> Button:
	return _hit


func pass_button() -> Button:
	return _pass


func crew_buttons() -> Array:
	return _picks


func row_buttons() -> Array:
	return _rows.map(func(r): return r["button"])


func text_nodes() -> Array:
	var out: Array = [_kicker, _headline, _unit, _sub, _list_head, _list_title, _kev_head]
	out.append_array(_kev)
	for r in _rows:
		if r["button"].visible:
			out.append_array([r["name"], r["route"], r["passes"]])
	for l in _none + _empty:
		if l.visible:
			out.append(l)
	if not _hit.visible:
		return out
	out.append_array([_cargo_head, _cargo_name, _cargo_line, _plan_head, _pick_label, _block, _hit, _pass])
	for r in _roles:
		out.append_array([r["kicker"], r["name"], r["fx"]])
		if r["plus"].visible:
			out.append(r["plus"])
	for pb in _picks:
		if pb.visible:
			out.append(pb)
	for t in _tiles:
		out.append_array([t["value"], t["sub"]])
	out.append_array(_note)
	return out


const BAND_SLACK := 6.0


func line_pairs() -> Array:
	return [[_headline, _unit]]
