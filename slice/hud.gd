extends Control
## The ARPG slice's HUD (BUILD72, board A of "Lesser England - the ARPG slice"): top left the site and the gang clock,
## top right a minimap of the park, bottom left the runner (portrait, HP, Guard, energy, the streak), bottom centre the
## gun (its picture, rounds and spare mags), the three skills on Q/E/R with their cooldowns shaded, the med slots; the
## damage numbers and the headshot's pop over the men; the Last legs banner.
##
## It reads the world each frame into a plain state (read_state), then shows that state (show_state): the smoke feeds
## show_state the longest words it can meet for the fit checks at 1920 x 1080 and 1920 x 1200.
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceTuning := preload("res://slice/tuning.gd")     # (round 2: the test knobs' defaults)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Words := preload("res://scripts/sim/words.gd")
const People := preload("res://scripts/ui/people.gd")
const Items := preload("res://scripts/sim/items.gd")
const SkillBar := preload("res://scripts/ui/skill_bar.gd")

# the board's measures (board A, 1920 x 1080); the bottom row sits on the screen's foot at any height
const EDGE := 24.0                    # the panels' gap from the screen's edge
const SITE_W := 300.0                 # top left: the site and the gang clock
const SITE_H := 116.0                 # (round 4) a line more: "3 on you · 4 waiting"
const MAP_W := 240.0                  # top right: the minimap's panel
const MAP_H := 158.0
const MAP_IN := 16.0                  # the park drawn inside it
const ME_W := 500.0                   # bottom left: the runner
const ME_H := 118.0
const FACE := 64.0                    # the portrait at half its 128 (People: whole or a clean half)
const TILE := 72.0                    # a skill or med slot
const TILE_GAP := 12.0
const GUN_W := 180.0                  # the gun's line (build 76), its picture and its rounds
const BAR_H := 132.0                  # bottom centre's panel
const POP_S := 0.75                   # a damage number's life
const POP_RISE := 46.0                # how far it rises
const POP_MAX := 24                   # numbers on screen at once (the oldest goes)
const SKILL_KEYS := ["Q", "E", "C"]   # (round 2) R reloads now; the third skill is on C
const RELOAD_AT := 0.25               # under this share of the magazine, the reload's prompt shows (round 2)
const NEWS_W := 1200.0                # the events' line, top centre between the site and the minimap
const NEWS_S := 3.0                   # how long a line stays
const HEAD_TONE := Color("f2c14e")    # the headshot's pop (board A)
const MAN_TONE := Color("f08a74")
const EXIT_TONE := Color("5fc28f")
const COVER_TONE := Color("4a5058")

var world = null                      # the slice's world (slice.gd), or null in the fit checks
var state := {}                       # what's shown: read_state's or the smoke's
var pops: Array = []                  # [{label, t, at}] the numbers in flight
var _arrived := 0                     # gangs come so far (the director's gang_arrived)

var _site: Panel
var _site_kicker: Label
var _site_name: Label
var _site_clock: Label
var _waves: Label                     # (round 4, G's waves) "3 on you · 4 waiting" under the gang clock
var _map: Panel
var _map_draw: Control
var _me: Panel
var _face: TextureRect
var _me_name: Label
var _me_hp: Label
var _hp_bar: ColorRect
var _hp_fill: ColorRect
var _guard_bar: ColorRect
var _guard_fill: ColorRect
var _en_bar: ColorRect
var _en_fill: ColorRect
var _me_line: Label
var _me_energy: Label
var _bar: Panel
var _gun_pic: TextureRect
var _gun_line: Label                  # (build 76, board D) "AR · 10 a second" over the rounds
var _gun_rounds: Label
var _gun_spare: Label
var _gun_state: Label
var _reload_bar: ColorRect
var _reload_fill: ColorRect
var _skills: Array = []               # [{panel, pic, shade, secs, key}]
var _meds: Array = []                 # [{panel, pic, plus, key}]
var _banner: Label
var _news: Label                      # the bridge's events (the review): the hard man in, jams, skills, the streak's end
var _news_left := 0.0
var _note_gun: Label                  # "Stand-in gun · ..." when the runner's own can't fire here
var _note_sk: Label                   # "Not in the slice: E" over skills the slice doesn't play
var _reload_hint: Label               # "R · Reload" under a quarter of the magazine (round 2: Matt couldn't find the reload)
var _tests: Label                     # the test settings in force: gang HP, their damage (build 76: the magazine's gone)
var _pop_root: Control


func _init() -> void:
	size = Vector2(1920, 1080)                 # laid out by layout(), not by anchors (the screen's size set by hand)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pop_root = Control.new()
	_pop_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pop_root)
	_build_site()
	_build_map()
	_build_me()
	_build_bar()
	_banner = UI.label(self, Rect2(0, 0, 600, 36), "", "Bold", 26, Pal.WARN, HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(_banner)
	_banner.visible = false
	_news = UI.label(self, Rect2(0, 24, NEWS_W, 30), "", "SemiBold", 20, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(_news)
	_news.visible = false
	_note_gun = UI.label(self, Rect2(0, 0, 20.0 + GUN_W + 20.0, 22), "", "Regular", 15, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT)
	_note_sk = UI.label(self, Rect2(0, 0, 3.0 * TILE + 2.0 * TILE_GAP + 40.0, 22), "", "Regular", 15, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT)
	UI.shadow(_note_gun)
	_reload_hint = UI.label(self, Rect2(0, 0, 20.0 + GUN_W + 20.0, 26), "", "Bold", 18, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	UI.shadow(_reload_hint)
	_tests = UI.label(self, Rect2(0, 58, NEWS_W, 22), "", "Regular", 14, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(_tests)
	UI.shadow(_note_sk)
	layout(Vector2(1920, 1080))


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()


func _on_resize() -> void:
	layout(get_viewport_rect().size if is_inside_tree() else size)


static func _panel_box() -> StyleBoxFlat:
	var sb := UI.box(Color(Pal.PANEL, 0.92), 8, 1, Pal.CARD_LINE)
	return sb


func _build_site() -> void:
	_site = UI.panel(self, Rect2(EDGE, 20, SITE_W, SITE_H), _panel_box())
	_site_kicker = UI.label(_site, Rect2(16, 10, SITE_W - 32, 20), "", "SemiBold", 14, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(_site_kicker, 1)
	_site_name = UI.label(_site, Rect2(16, 30, SITE_W - 32, 30), "", "Bold", 22, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_site_clock = UI.label(_site, Rect2(16, 60, SITE_W - 32, 22), "", "Regular", 15, Pal.TEXT_2)
	_waves = UI.label(_site, Rect2(16, 84, SITE_W - 32, 22), "", "SemiBold", 15, Pal.TEXT)


func _build_map() -> void:
	_map = UI.panel(self, Rect2(0, 20, MAP_W, MAP_H), _panel_box())
	_map_draw = MiniMap.new()
	_map_draw.hud = self
	_map_draw.position = Vector2(MAP_IN, MAP_IN)
	_map_draw.size = Vector2(MAP_W - 2 * MAP_IN, MAP_H - 2 * MAP_IN)
	_map_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.add_child(_map_draw)


func _build_me() -> void:
	_me = UI.panel(self, Rect2(EDGE, 0, ME_W, ME_H), _panel_box())
	_face = TextureRect.new()
	_face.position = Vector2(14, (ME_H - FACE) / 2.0)
	_face.size = Vector2(FACE, FACE)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_me.add_child(_face)
	var x := 14.0 + FACE + 16.0
	var w := ME_W - x - 16.0
	_me_name = UI.label(_me, Rect2(x, 10, w * 0.62, 24), "", "SemiBold", 17, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_me_hp = UI.label(_me, Rect2(x + w * 0.62, 10, w * 0.38, 24), "", "Medium", 16, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	var bars: Array = [[38.0, 14.0, Pal.GOOD], [56.0, 8.0, Pal.INFO], [68.0, 6.0, Pal.ACCENT]]
	var made: Array = []
	for b in bars:
		var back := ColorRect.new()
		back.color = Pal.BG
		back.position = Vector2(x, float(b[0]))
		back.size = Vector2(w, float(b[1]))
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_me.add_child(back)
		var fill := ColorRect.new()
		fill.color = b[2]
		fill.size = back.size
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_child(fill)
		made.append([back, fill])
	_hp_bar = made[0][0]
	_hp_fill = made[0][1]
	_guard_bar = made[1][0]
	_guard_fill = made[1][1]
	_en_bar = made[2][0]
	_en_fill = made[2][1]
	_me_line = UI.label(_me, Rect2(x, 80, w * 0.6, 26), "", "Regular", 14, Pal.TEXT_2)
	_me_energy = UI.label(_me, Rect2(x + w * 0.6, 80, w * 0.4, 26), "", "Regular", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT)


func _bar_w() -> float:
	return 20.0 + GUN_W + 20.0 + 1.0 + 20.0 + 3.0 * TILE + 2.0 * TILE_GAP + 24.0 + 4.0 * TILE + 3.0 * TILE_GAP + 20.0


func _build_bar() -> void:
	_bar = UI.panel(self, Rect2(0, 0, _bar_w(), BAR_H), _panel_box())
	_gun_pic = TextureRect.new()
	_gun_pic.position = Vector2(20, 38)
	_gun_pic.size = Vector2(GUN_W, 34)
	_gun_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gun_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gun_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_gun_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_gun_pic)
	_gun_line = UI.label(_bar, Rect2(20, 12, GUN_W, 24), "", "SemiBold", 16, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_gun_rounds = UI.label(_bar, Rect2(20, 74, 48, 32), "", "Bold", 22, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_gun_spare = UI.label(_bar, Rect2(68, 74, GUN_W - 48, 32), "", "Medium", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT)
	_gun_state = UI.label(_bar, Rect2(20, 74, GUN_W, 32), "", "SemiBold", 16, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT)
	_reload_bar = ColorRect.new()
	_reload_bar.color = Pal.BG
	_reload_bar.position = Vector2(20, 110)
	_reload_bar.size = Vector2(GUN_W, 5)
	_reload_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_reload_bar)
	_reload_fill = ColorRect.new()
	_reload_fill.color = Pal.ACCENT
	_reload_fill.size = _reload_bar.size
	_reload_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reload_bar.add_child(_reload_fill)
	var line := ColorRect.new()
	line.color = Pal.CARD_LINE
	line.position = Vector2(20 + GUN_W + 20, 18)
	line.size = Vector2(1, BAR_H - 36)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(line)
	var x := 20.0 + GUN_W + 20.0 + 1.0 + 20.0
	for k in range(3):
		_skills.append(_slot(x, SKILL_KEYS[k]))
		x += TILE + TILE_GAP
	x += 24.0 - TILE_GAP
	for k in range(4):
		_meds.append(_slot(x, "%d · Med" % (k + 1)))
		x += TILE + TILE_GAP


## A slot: the tile, its picture, the cooldown's shade from the bottom, the seconds left, its key under it.
func _slot(x: float, key: String) -> Dictionary:
	var p := UI.panel(_bar, Rect2(x, 16, TILE, TILE), UI.box(Pal.CARD, 8, 2, Pal.CARD_LINE))
	var pic := TextureRect.new()
	pic.position = Vector2(12, 12)
	pic.size = Vector2(TILE - 24, TILE - 24)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(pic)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.visible = false
	p.add_child(shade)
	var secs := UI.label(p, Rect2(0, 0, TILE, TILE), "", "Bold", 20, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(secs)
	var plus := UI.label(p, Rect2(0, 0, TILE, TILE), "+", "Regular", 26, EXIT_TONE, HORIZONTAL_ALIGNMENT_CENTER)
	plus.visible = false
	var n := UI.label(p, Rect2(TILE - 44, TILE - 24, 38, 20), "", "SemiBold", 14, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	UI.shadow(n)
	var k := UI.label(_bar, Rect2(x - 10, 16 + TILE + 6, TILE + 20, 22), key, "Regular", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER)
	return {"panel": p, "pic": pic, "shade": shade, "secs": secs, "plus": plus, "key": k, "count": n}


## Everything placed for a screen of size s: the top row on the top, the bottom row on the foot, centred across.
func layout(s: Vector2) -> void:
	size = s
	_site.position = Vector2(EDGE, 20)
	_map.position = Vector2(s.x - EDGE - MAP_W, 20)
	_me.position = Vector2(EDGE, s.y - EDGE - ME_H)
	_bar.position = Vector2(roundf((s.x - _bar_w()) / 2.0), s.y - EDGE - BAR_H)
	_banner.position = Vector2(roundf((s.x - _banner.size.x) / 2.0), _bar.position.y - 110)
	_news.position = Vector2(roundf((s.x - NEWS_W) / 2.0), 24)
	_note_gun.position = Vector2(_bar.position.x + 20.0, _bar.position.y - 26)
	_reload_hint.position = Vector2(_bar.position.x + 20.0, _bar.position.y - 56)
	_tests.position = Vector2(roundf((s.x - NEWS_W) / 2.0), 58)
	_note_sk.position = Vector2(_bar.position.x + 20.0 + GUN_W + 20.0 + 1.0 + 20.0, _bar.position.y - 26)


func _process(dt: float) -> void:
	if world != null and is_instance_valid(world):
		drain_events()
		show_state(read_state())
	_tick_pops(dt)
	if _news_left > 0.0:
		_news_left -= dt
		_news.visible = _news_left > 0.0


## The world as the HUD shows it: plain values, so a test can hand the HUD the same shape.
func read_state() -> Dictionary:
	var st := {}
	var ctx: Dictionary = world.ctx if world.get("ctx") is Dictionary else {}
	var r = world.runner
	var site: Dictionary = ctx.get("site", {}) if ctx.get("site") is Dictionary else {}
	st["site"] = str(site.get("place", "The Estate"))
	st["site_level"] = int(site.get("level", 12))
	st["place"] = str(site.get("name", "The car park"))
	st["cleared"] = bool(world.cleared)
	var g = world.gang
	st["gangs"] = int(site.get("gangs", 3))
	st["gang"] = _arrived
	st["next_s"] = -1.0
	if g != null and is_instance_valid(g):
		st["gangs"] = int(g.get("gangs")) if g.get("gangs") != null else st["gangs"]
		st["next_s"] = float(g.get("next_in")) if g.get("next_in") != null else -1.0
		st["on_park"] = int(g.get("alive")) if g.get("alive") != null else 0
		if g.has_method("on_you_count"):
			st["on_you"] = int(g.on_you_count())
			st["waiting"] = int(g.waiting_count())
	st["cls"] = str(ctx.get("class_name", "Poacher"))
	st["level"] = int(ctx.get("level", 1))
	st["portrait"] = str(ctx.get("portrait", ""))
	if r == null or not is_instance_valid(r):
		return st
	st["hp"] = int(r.hp)
	st["hp_max"] = int(r.hp_max)
	st["guard"] = int(r.guard)
	st["guard_max"] = int(r.guard_max)
	st["energy"] = float(r.energy)
	st["energy_max"] = float(r.energy_max)
	st["streak"] = SliceBridge.streak(ctx) if not ctx.is_empty() else 0
	st["last_legs_s"] = float(r.get("last_legs_left")) if r.get("last_legs_left") != null else 0.0
	var gun: Dictionary = r.gun()
	var gi: int = int(r.gun_i)
	st["gun"] = gun
	st["rounds"] = int(r.rounds[gi]) if gi < r.rounds.size() else 0
	st["mag"] = int(gun.get("mag", 0))
	st["mags"] = int(r.mags[gi]) if gi < r.mags.size() else 0
	st["reload_frac"] = (1.0 - float(r.reload_left) / maxf(0.01, float(r.reload_total))) if bool(r.reloading) else -1.0
	st["jammed"] = bool(r.jammed)
	st["jam_s"] = float(r.jam_left)
	st["box"] = int(r.box_rounds()) if r.has_method("box_rounds") else 0
	st["refilling"] = bool(r.get("refilling")) if r.get("refilling") != null else false
	st["stand_in"] = str(gun.get("name", "")) if bool(gun.get("stand_in", false)) else ""
	st["pad"] = bool(world.get("pad")) if world.get("pad") != null else false
	st["man_hp_x"] = float(ctx.get("man_hp_x", SliceTuning.MAN_HP_X))
	st["their_dmg_x"] = float(ctx.get("their_dmg_x", SliceTuning.THEIR_DMG_X))
	var sk: Array = []
	var skills: Array = ctx.get("skills", [])
	for i in range(mini(3, skills.size())):
		var s: Dictionary = skills[i]
		var ss: Dictionary = r.skill_state.get(i, {}) if r.skill_state is Dictionary else {}
		sk.append({"id": str(s.get("id", "")), "name": str(s.get("name", "")), "icon": str(s.get("icon", "")), "cd": float(ss.get("cd", s.get("cd", 1.0))),
				"cd_left": float(ss.get("cd_left", 0.0)), "cost": float(s.get("cost", 0.0)), "in_slice": bool(s.get("in_slice", str(s.get("id", "")) != ""))})
	st["skills"] = sk
	st["meds"] = r.meds.slice(0, 4) if r.meds is Array else []
	return st


## Shows a state (read_state's shape). Missing keys show as nothing, not as an error.
func show_state(st: Dictionary) -> void:
	state = st
	_site_kicker.text = ("%s · level %d" % [str(st.get("site", "")), int(st.get("site_level", 0))]).to_upper()
	_site_name.text = str(st.get("place", ""))
	UI.fit(_site_clock, clock_words(st))
	UI.fit(_waves, wave_words(st))
	_map_draw.queue_redraw()
	# the runner
	_face.texture = face_picture(str(st.get("portrait", "")), str(st.get("cls", "")))
	_face.visible = _face.texture != null
	_me_name.text = UI.dots("%s · level %d" % [str(st.get("cls", "")), int(st.get("level", 0))])
	var hp: int = int(st.get("hp", 0))
	var hp_max: int = maxi(1, int(st.get("hp_max", 1)))
	_me_hp.text = "%s / %s" % [Fmt.group(hp), Fmt.group(hp_max)]
	_hp_fill.size.x = _hp_bar.size.x * clampf(float(hp) / float(hp_max), 0.0, 1.0)
	_hp_fill.color = Pal.BAD if float(hp) / float(hp_max) < 0.25 else Pal.GOOD
	var gm: int = int(st.get("guard_max", 0))
	_guard_bar.visible = gm > 0
	_guard_fill.size.x = _guard_bar.size.x * (clampf(float(st.get("guard", 0)) / float(gm), 0.0, 1.0) if gm > 0 else 0.0)
	var em: float = float(st.get("energy_max", 0.0))
	_en_fill.size.x = _en_bar.size.x * (clampf(float(st.get("energy", 0.0)) / em, 0.0, 1.0) if em > 0.0 else 0.0)
	_me_line.text = UI.dots("Guard %d · %s %d" % [int(st.get("guard", 0)), Words.V66["streak"], int(st.get("streak", 0))])
	_me_energy.text = "%d energy" % int(st.get("energy", 0.0))
	# the gun
	var gun: Dictionary = st.get("gun", {})
	_gun_pic.texture = gun_picture(gun)
	UI.fit(_gun_line, gun_line(gun))
	var rf: float = float(st.get("reload_frac", -1.0))
	var jammed: bool = bool(st.get("jammed", false))
	_reload_bar.visible = rf >= 0.0
	_reload_fill.size.x = _reload_bar.size.x * clampf(rf, 0.0, 1.0)
	_gun_state.visible = jammed or rf >= 0.0
	_gun_rounds.visible = not _gun_state.visible
	_gun_spare.visible = not _gun_state.visible
	if jammed:
		_gun_state.add_theme_color_override("font_color", Pal.BAD)
		_gun_state.text = UI.dots(Words.V66["jammed"] % ("%.1f" % float(st.get("jam_s", 0.0)))) if float(st.get("jam_s", 0.0)) > 0.0 else "Jammed"
	elif rf >= 0.0:
		_gun_state.add_theme_color_override("font_color", Pal.WARN)
		_gun_state.text = "Refilling" if bool(st.get("refilling", false)) else "Reloading"
	var rounds: int = int(st.get("rounds", 0))
	_gun_rounds.text = str(rounds)
	_gun_rounds.add_theme_color_override("font_color", Pal.BAD if rounds == 0 else Pal.TEXT)
	_gun_rounds.size.x = UI.text_width(_gun_rounds, _gun_rounds.text) + 6.0
	_gun_spare.position.x = _gun_rounds.position.x + _gun_rounds.size.x
	_gun_spare.size.x = GUN_W - _gun_rounds.size.x
	var mags: int = int(st.get("mags", 0))
	var box: int = int(st.get("box", 0))
	var mag_n: int = int(st.get("mag", 0))
	if mags <= 0 and box > 0:
		UI.fit(_gun_spare, ["/ %d · %s in the box" % [mag_n, Fmt.group(box)], "/ %d · box %s" % [mag_n, Fmt.group(box)], "/ %d" % mag_n])
	else:
		UI.fit(_gun_spare, ["/ %d · %s" % [mag_n, Fmt.count(mags, "mag")], "/ %d" % mag_n])
	# the reload's prompt: under a quarter of the magazine, a spare or the box to fill it from, not already at it
	var low: bool = mag_n > 0 and float(rounds) < float(mag_n) * RELOAD_AT and not jammed and rf < 0.0 and (mags > 0 or box > 0)
	_reload_hint.visible = low
	_reload_hint.text = ("X · Reload" if bool(st.get("pad", false)) else "R · Reload") if low else ""
	# the test settings in force
	_tests.text = "Test settings: gang HP %s, their damage %s" % [x_words(float(st.get("man_hp_x", SliceTuning.MAN_HP_X))), x_words(float(st.get("their_dmg_x", SliceTuning.THEIR_DMG_X)))]
	_note_gun.visible = str(st.get("stand_in", "")) != ""
	if _note_gun.visible:
		UI.fit(_note_gun, ["Stand-in gun · %s" % str(st["stand_in"]), "Stand-in gun"])
	# the skills
	var sk: Array = st.get("skills", [])
	var energy: float = float(st.get("energy", 0.0))
	var out_keys: Array = []
	for i in range(_skills.size()):
		var d: Dictionary = _skills[i]
		var on: bool = i < sk.size() and str(sk[i].get("id", "")) != ""
		d["pic"].visible = on
		if on and not bool(sk[i].get("in_slice", true)):
			out_keys.append(SKILL_KEYS[i])
			d["pic"].texture = skill_picture(sk[i])
			d["pic"].modulate = Color(1, 1, 1, 0.3)     # not in the slice: there, greyed, never lit
			d["shade"].visible = true
			d["shade"].position = Vector2.ZERO
			d["shade"].size = Vector2(TILE, TILE)
			d["secs"].text = ""
			d["panel"].add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, Pal.CARD_LINE))
			continue
		if not on:
			d["shade"].visible = false
			d["secs"].text = ""
			d["panel"].add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, Pal.CARD_LINE))
			continue
		var s: Dictionary = sk[i]
		d["pic"].texture = skill_picture(s)
		var left: float = float(s.get("cd_left", 0.0))
		var cd: float = maxf(0.01, float(s.get("cd", 1.0)))
		var short: bool = energy < float(s.get("cost", 0.0))
		d["shade"].visible = left > 0.0
		var share := clampf(left / cd, 0.0, 1.0)
		d["shade"].position = Vector2(0, TILE * (1.0 - share))
		d["shade"].size = Vector2(TILE, TILE * share)
		d["secs"].text = ("%d" % int(ceil(left))) if left > 0.0 else ""
		var edge: Color = Pal.ACCENT if left <= 0.0 and not short else (Pal.BAD if short and left <= 0.0 else Pal.CARD_LINE)
		d["panel"].add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, edge))
		d["pic"].modulate = Color(1, 1, 1, 0.45) if short else Color.WHITE
	_note_sk.visible = not out_keys.is_empty()
	_note_sk.text = "Not in the slice: %s" % ", ".join(out_keys) if not out_keys.is_empty() else ""
	# the meds
	var meds: Array = st.get("meds", [])
	for i in range(_meds.size()):
		var d: Dictionary = _meds[i]
		var it = meds[i] if i < meds.size() else null
		var has: bool = it is Dictionary and int(it.get("count", 1)) > 0
		var tex: Texture2D = med_picture(it) if has else null
		d["pic"].texture = tex
		d["pic"].visible = has and tex != null
		d["plus"].visible = has and tex == null
		d["secs"].text = ""
		d["count"].text = ("×%d" % int(it.get("count", 1))) if has and int(it.get("count", 1)) > 1 else ""
		d["panel"].modulate = Color.WHITE if has else Color(1, 1, 1, 0.35)
		d["key"].modulate = Color.WHITE if has else Color(1, 1, 1, 0.35)
		d["panel"].add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, EXIT_TONE if has else Pal.CARD_LINE))
	# Last legs: the banner over the bar while it holds you up
	var ls: float = float(st.get("last_legs_s", 0.0))
	_banner.visible = ls > 0.0
	if ls > 0.0:
		_banner.text = UI.dots("%s · %s" % [Words.V66["last_stand"], Words.V66["ls_on"] % ("%d" % int(ceil(ls)))])


## (build 76, board D) The gun's line, long to short: its kind and its rate, "AR · 10 a second" - the bridge's words
## (SliceBridge.gun_line: a press gun's rate is its cap, a melee weapon "a swing"); then the kind alone.
static func gun_line(gun: Dictionary) -> Array:
	return [""] if gun.is_empty() else SliceBridge.gun_line(gun)


static func x_words(x: float) -> String:
	return ("×%d" % roundi(x)) if is_equal_approx(x, roundf(x)) else "×%s" % str(snappedf(x, 0.01))


## The waves' line (round 4): "3 on you · 4 waiting", the waiting part gone when none wait; "" before any are on you.
static func wave_words(st: Dictionary) -> Array:
	var on: int = int(st.get("on_you", 0))
	var wait: int = int(st.get("waiting", 0))
	if on <= 0 and wait <= 0:
		return [""]
	if wait <= 0:
		return ["%d on you" % on]
	return ["%d on you · %d waiting" % [on, wait], "%d on you · %d" % [on, wait]]


## The gang clock's line, long to short: "Gang 2 of 3 · next in 0:41" (board A).
static func clock_words(st: Dictionary) -> Array:
	var gangs: int = int(st.get("gangs", 3))
	var gang: int = int(st.get("gang", 0))
	var next_s: float = float(st.get("next_s", -1.0))
	if bool(st.get("cleared", false)):
		return ["Cleared · the way out's open", "Cleared"]
	if gang <= 0:
		return ["First gang in %s" % Fmt.mss(next_s), Fmt.mss(next_s)] if next_s >= 0.0 else ["Quiet for now"]
	if gang < gangs and next_s >= 0.0:
		return ["Gang %d of %d · next in %s" % [gang, gangs, Fmt.mss(next_s)], "Gang %d of %d · %s" % [gang, gangs, Fmt.mss(next_s)]]
	return ["Gang %d of %d · the last" % [gang, gangs], "Gang %d of %d" % [gang, gangs]]


## The gun's own picture (the item's art, or its icon path), else none.
static func gun_picture(gun: Dictionary) -> Texture2D:
	if gun.get("item") is Dictionary:
		var own: Texture2D = Items.art(gun["item"])
		if own != null:
			return own
	if gun.has("base"):
		var t: Texture2D = Items.art(gun)
		if t != null:
			return t
	var icon: String = str(gun.get("icon", ""))
	if icon != "" and ResourceLoader.exists(icon):
		return load(icon)
	if gun.has("name") and not gun.has("base"):
		var as_item := {"base": str(gun["name"]), "slot": "Primary"}
		return Items.art(as_item)
	return null


## The class's face: the bridge's path when it has one, else the class's portrait by name.
static func face_picture(path: String, cls_v: String) -> Texture2D:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		return load(path)
	return People.portrait(cls_v) if cls_v != "" else null


static func med_picture(m: Dictionary) -> Texture2D:
	var icon: String = str(m.get("icon", ""))
	if icon != "" and ResourceLoader.exists(icon):
		return load(icon)
	if m.has("base"):
		return Items.art({"base": str(m["base"]), "slot": "Medical"})
	return null


static func skill_picture(s: Dictionary) -> Texture2D:
	var icon: String = str(s.get("icon", ""))
	if icon != "" and ResourceLoader.exists(icon):
		return load(icon)
	return SkillBar.picture(str(s.get("id", "")))


# ------------------------------------------------------------------ the numbers over the men

## A damage number at a screen point; a headshot's is the board's "HEADSHOT 412" in its yellow.
func pop(at: Vector2, damage: int, headshot := false, killed := false) -> Label:
	var words: String = (Words.V66["headshot"] % Fmt.group(damage)) if headshot else Fmt.group(damage)
	var l := UI.label(_pop_root, Rect2(at.x - 150, at.y - 40, 300, 36), words, "Bold", 28 if headshot else (22 if killed else 18),
			HEAD_TONE if headshot else (MAN_TONE if killed else Pal.TEXT), HORIZONTAL_ALIGNMENT_CENTER)
	UI.shadow(l)
	pops.append({"label": l, "t": 0.0, "y": l.position.y})
	while pops.size() > POP_MAX:
		var old: Dictionary = pops.pop_front()
		old["label"].queue_free()
	return l


func _tick_pops(dt: float) -> void:
	for p in pops.duplicate():
		p["t"] = float(p["t"]) + dt
		var k: float = float(p["t"]) / POP_S
		var l: Label = p["label"]
		if k >= 1.0:
			pops.erase(p)
			l.queue_free()
			continue
		l.position.y = float(p["y"]) - POP_RISE * (1.0 - pow(1.0 - k, 2.0))
		l.modulate.a = 1.0 if k < 0.6 else 1.0 - (k - 0.6) / 0.4


## The bridge's events since the last frame, on the news line (the newest wins) - headshots are the pops' own.
func drain_events() -> void:
	for e in SliceBridge.pop_events(world.ctx):
		var w: Array = event_words(e)
		if not w.is_empty():
			news(w)


## A line on the news line, long to short, for NEWS_S seconds.
func news(options: Array) -> void:
	UI.fit(_news, options)
	_news.visible = true
	_news_left = NEWS_S


## An event's words, long to short; [] for one the news line doesn't carry.
static func event_words(e: Dictionary) -> Array:
	var L: Dictionary = Words.LOG66
	match str(e.get("kind", "")):
		"hard_man":
			var tw: Array = e.get("trait_words", []).map(func(x): return str(x).to_lower())
			return [L["hard_in"] % [str(e.get("name", "")), ", ".join(tw)], "%s, a hard man, is with this gang" % str(e.get("name", ""))]
		"hard_down":
			return [L["hard_down"] % str(e.get("name", "")), "%s is down" % str(e.get("name", ""))]
		"jam":
			return [L["jam"] % [str(e.get("gun", "")), str(snappedf(float(e.get("s", 0.0)), 0.1))], "Jammed"]
		"skill":
			return [str(e.get("name", ""))]
		"streak_end":
			return ["Hit: the streak of %d ends" % int(e.get("was", 0)), "The streak ends"]
		"med":
			return ["%s · +%d HP" % [str(e.get("name", "")), int(e.get("heal", 0))], str(e.get("name", ""))]
	return []


## The world's signals the HUD answers: a hit's number. Called by whoever opens the slice, once the world is up.
func bind(w) -> void:
	world = w
	if w.has_signal("hit_landed"):
		w.hit_landed.connect(_on_hit)
	if w.gang != null and w.gang.has_signal("gang_arrived"):
		w.gang.gang_arrived.connect(func(i: int, _n: int) -> void: _arrived = maxi(_arrived, i + 1))


func _on_hit(man: Node, result: Dictionary, point: Vector2) -> void:
	if man is CanvasItem and not man.visible:     # (round 5's review) a man the fog hides: no number to give him away
		return
	var at: Vector2 = world.world_to_screen(point) if world != null and world.has_method("world_to_screen") else point
	pop(at, int(result.get("damage", 0)), bool(result.get("headshot", false)), bool(result.get("killed", false)))


## Every label the HUD shows, for the fit checks (pops are short-lived and centred over a man: not laid out against
## anything).
func text_nodes() -> Array:
	var out: Array = [_site_kicker, _site_name, _site_clock, _waves, _me_name, _me_hp, _me_line, _me_energy, _gun_line, _gun_rounds, _gun_spare, _gun_state, _banner,
		_news, _note_gun, _note_sk, _reload_hint, _tests]
	for d in _skills + _meds:
		out.append(d["secs"])
		out.append(d["key"])
		out.append(d["plus"])
		out.append(d["count"])
	return out


## The panels, for the check that none overlaps another or runs off the screen.
func panels() -> Array:
	return [_site, _map, _me, _bar]


## The minimap: the park in its panel - cover, crates, the way out, the men, you. (build 76, W's line of sight) Only what
## the runner has seen: a man the fog hides isn't on it (his "last seen" mark is, faint), a crate or the way out once seen.
class MiniMap extends Control:
	var hud = null

	## What the map shows, in the park's px: {"crates": [[pos, opened]], "men": [[pos, hard]], "marks": [pos], "exit": bool}.
	static func shown(w) -> Dictionary:
		var out := {"crates": [], "men": [], "marks": [], "exit": true}
		var lv = w.get("level")
		if lv != null and lv.get("exit_seen") != null:
			out["exit"] = bool(lv.get("exit_seen"))
		if w.has_method("crates"):
			for c in w.crates():
				if c.get("seen") == false or not c.visible:
					continue
				out["crates"].append([c.global_position, bool(c.get("opened")) if c.get("opened") != null else false])
		if w.has_method("men"):
			for m in w.men():
				if not m.visible:
					continue
				out["men"].append([m.global_position, bool(m.get("hard")) if m.get("hard") != null else false])
		var sight = w.get("sight")
		if sight != null and sight.get("marks") is Array:
			for mk in sight.get("marks"):
				if mk is Dictionary and mk.get("pos") is Vector2:
					out["marks"].append(mk["pos"])
		return out

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.10, 0.9))
		draw_rect(Rect2(Vector2.ZERO, size), COVER_TONE, false, 2.0)
		var w = hud.world if hud != null else null
		if w == null or not is_instance_valid(w):
			return
		var park: Rect2 = w.park_rect
		var k: float = minf(size.x / park.size.x, size.y / park.size.y)
		var off: Vector2 = (size - park.size * k) / 2.0
		var to := func(p: Vector2) -> Vector2: return off + (p - park.position) * k
		if w.has_method("cover_rects"):
			for r in w.cover_rects():
				draw_rect(Rect2(to.call(r.position), r.size * k), COVER_TONE)
		var sh: Dictionary = shown(w)
		if bool(sh["exit"]):
			var ex: Rect2 = w.exit_rect
			draw_rect(Rect2(to.call(ex.position), (ex.size * k).max(Vector2(8, 8))), EXIT_TONE, false, 2.0)
		for c in sh["crates"]:
			draw_rect(Rect2(to.call(c[0]) - Vector2(3, 3), Vector2(7, 7)), Color(Pal.ACCENT, 0.35 if bool(c[1]) else 1.0))
		for p in sh["marks"]:
			draw_arc(to.call(p), 4.0, 0.0, TAU, 12, Color(MAN_TONE, 0.45), 1.5)     # where a man was last seen
		for m in sh["men"]:
			draw_circle(to.call(m[0]), 5.0 if bool(m[1]) else 4.0, MAN_TONE)
			if bool(m[1]):
				draw_arc(to.call(m[0]), 6.5, 0.0, TAU, 16, Pal.ACCENT, 1.5)
		if w.runner != null and is_instance_valid(w.runner):
			draw_circle(to.call(w.runner.global_position), 5.0, Pal.ACCENT)
