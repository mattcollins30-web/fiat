extends Control
## The County on the Map (25 Oct, the Issue's second campaign: docs/design/the_issue.md §4): four zones across, three
## places down each - the last its head's. A place's card: the host site's plate till the County's is drawn, its name
## and line, the level and the odds, and Go, or what keeps it shut (its zone, the place before, the issued kit worn).
## A zone not yet open reads scrambled, as a shut zone of the City's does.
##
## Signals: `acted` after a run sets off.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const GAP := 16
const ZONE_HEAD_H := 112
const CARD_GAP := 12
const PAD := 14
const ART_H := 84
const GO_H := 48

var sim
var _w := 0.0
var _col_w := 0.0
var _zones: Array = []              # {panel, name, head, want}
var _cards: Array = []              # {key, panel, art, place, words: [Label, Label], status, button, note}
var _shown := ""


func _init(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	_w = rect.size.x
	mouse_filter = Control.MOUSE_FILTER_PASS
	var nz: int = Data.COUNTY_ZONES.size()
	_col_w = (rect.size.x - (nz - 1) * GAP) / nz
	var card_h: float = (rect.size.y - ZONE_HEAD_H - 3 * CARD_GAP) / 3.0
	var inner: float = _col_w - 2 * PAD
	for z in range(nz):
		var x: float = z * (_col_w + GAP)
		var zp := UI.panel(self, Rect2(x, 0, _col_w, ZONE_HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
		var zd := {"panel": zp}
		zd["name"] = UI.label(zp, Rect2(PAD, 10, inner, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		zd["head"] = UI.label(zp, Rect2(PAD, 48, inner, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		zd["want"] = UI.label(zp, Rect2(PAD, 76, inner, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_zones.append(zd)
		var keys: Array = _county_places(z)
		for n in range(keys.size()):
			var k: String = str(keys[n])
			var y: float = ZONE_HEAD_H + CARD_GAP + n * (card_h + CARD_GAP)
			var p := UI.panel(self, Rect2(x, y, _col_w, card_h), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
			p.clip_contents = true
			var c := {"key": k, "panel": p}
			var art := TextureRect.new()
			art.position = Vector2(1, 1)
			art.size = Vector2(_col_w - 2, ART_H)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var own: Texture2D = UI.place_texture(str(Data.county(k)["place"]))     # its own card once drawn (tools/make_county_art_manifest.py)
			art.texture = own if own != null else UI.place_texture(str(Data.TIERS[int(Data.county(k)["site"])]["name"]))     # till then the host's
			p.add_child(art)
			c["art"] = art
			c["place"] = UI.label(p, Rect2(PAD, ART_H - 40, inner, 36), "", "SemiBold", Pal.FLOOR + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			UI.shadow(c["place"])
			c["words"] = [UI.label(p, Rect2(PAD, ART_H + 8, inner, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false),
				UI.label(p, Rect2(PAD, ART_H + 30, inner, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)]
			c["status"] = UI.label(p, Rect2(PAD, ART_H + 56, inner, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			var fy: float = card_h - PAD - GO_H
			c["button"] = UI.button(p, Rect2(PAD, fy, inner, GO_H), true)
			c["button"].add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
			c["button"].pressed.connect(_go.bind(k))
			c["note"] = UI.label(p, Rect2(PAD, fy, inner, GO_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
			_cards.append(c)


static func _county_places(z: int) -> Array:
	var out: Array = []
	for c in Data.COUNTY:
		if int(c["cz"]) == z:
			out.append(str(c["key"]))
	return out


func show_state(s) -> void:
	sim = s
	if sim == null:
		return
	var reads := ""
	for c in Data.COUNTY:
		reads += str(sim.order_odds_now(str(c["key"])))
	var sig := "%s|%s|%d|%d|%d|%s|%d" % [str(sim.order_beaten), reads, sim.reach, sim.issued_worn(), int(sim.on_mission()), str(sim.can_deploy()), int(sim.issued)]
	if sig == _shown:
		return
	_shown = sig
	for z in range(_zones.size()):
		var zd: Dictionary = _zones[z]
		var zone: Dictionary = Data.COUNTY_ZONES[z]
		var open: bool = sim.county_zone_open(z)
		var en := func(t: String) -> String: return t if open else Fmt.scramble(t)
		UI.fit(zd["name"], [en.call(str(zone["name"]))])
		zd["name"].add_theme_color_override("font_color", Pal.TEXT if open else Pal.TEXT_3)
		UI.fit(zd["head"], [Words.COUNTY["head"] % en.call(str(zone["head"])), en.call(str(zone["head"]))])
		var want: int = sim.county_want(z)
		var worn: int = sim.issued_worn()
		UI.fit(zd["want"], [Words.COUNTY["want"] % [want, worn], Words.COUNTY["want_short"] % want])
		zd["want"].add_theme_color_override("font_color", (Pal.GOOD if worn >= want else Pal.BAD) if open else Pal.TEXT_3)
	for c in _cards:
		_show_card(c)


func _show_card(c: Dictionary) -> void:
	var k: String = c["key"]
	var d: Dictionary = Data.county(k)
	var zone_open: bool = sim.county_zone_open(int(d["cz"]))
	var open: bool = sim.order_open(k)
	var en := func(t: String) -> String: return t if zone_open else Fmt.scramble(t)
	c["art"].modulate = Color(0.75, 0.75, 0.75) if open else Color(0.3, 0.3, 0.32)
	UI.fit(c["place"], [en.call(str(d["place"])), en.call(str(d["place"]).trim_prefix("The "))])
	c["place"].add_theme_color_override("font_color", Pal.TEXT if open else Pal.TEXT_2)
	var line: String = str(Words.COUNTY_WORDS.get(k, ""))
	if d.has("who"):
		line = "%s %s" % [line, Words.COUNTY["drops_issued"] + "."]
	UI.wrap(c["words"], line if zone_open else "")     # a shut zone's places keep their lines to themselves
	var beaten: int = int(sim.order_beaten.get(k, 0))
	var bits: Array = [Words.COUNTY["level"] % sim.order_level(k)]
	if beaten > 0:
		bits.append(Words.COUNTY["beaten"] % beaten)
	var tone := Pal.TEXT_2
	if open:
		var od: Array = sim.order_odds_now(k)
		if bool(od[1]):
			bits.append("%s to clear" % Fmt.pct(float(od[0])))
			tone = Pal.tone_color("good" if float(od[0]) >= 0.9 else ("warn" if float(od[0]) >= 0.6 else "bad"))
		else:
			bits.append(Words.COUNTY["odds_reading"])
	UI.fit(c["status"], [" · ".join(bits), " · ".join(bits.slice(0, 1))] if zone_open else [""])
	c["status"].add_theme_color_override("font_color", tone)
	var why: String = sim.order_block(k)
	c["button"].visible = open and why == ""
	c["note"].visible = not c["button"].visible
	UI.fit_button(c["button"], ["Go: %s" % Words.mid(str(d["place"])), "Go"])
	UI.fit(c["note"], [why, ""])
	(c["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.ACCENT if (open and d.has("who")) else Pal.CARD_LINE


func _go(k: String) -> void:
	if sim != null and sim.deploy_order(k):
		_shown = ""
		acted.emit()


## For the tests: a card by its place's key.
func card(k: String) -> Dictionary:
	for c in _cards:
		if c["key"] == k:
			return c
	return {}


func text_nodes() -> Array:
	var out: Array = []
	for zd in _zones:
		out.append_array([zd["name"], zd["head"], zd["want"]])
	for c in _cards:
		out.append_array([c["place"], c["status"]] + c["words"])
		out.append(c["button"] if c["button"].visible else c["note"])
	return out
