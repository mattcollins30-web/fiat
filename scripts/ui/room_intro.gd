extends Control
## A room's first visit (14 Oct, docs/design/room_intros.md; mockup docs/design/mockups/room_intro_mockup.png): a card
## over the dimmed room - its place art across the top, who runs it (a portrait, or the narrator with none), two or
## three lines in their voice, three tiles naming the screen's parts. The lines come up on the take's cues when there's a
## take (art/intro/rooms/<voice>.mp3) and on the clock when not; a press brings the next line, then closes; Esc closes.
## The game is held while it's up (main._process).

signal done

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Words := preload("res://scripts/sim/words.gd")
const People := preload("res://scripts/ui/people.gd")

const VOICE := "res://art/intro/rooms/%s.mp3"
const VOICE_DB := -1.0
const W := 1280
const LINES := 4                       # the most lines a card has (the Clinic, 14 Oct)
const H := 752
const BAND_H := 300
const FACE := 256
const PAD := 48
const LINE_Y := 330
const LINE_GAP := 46
const TILE_Y := 524                    # under four lines
const TILE_H := 92
const TILE_GAP := 16
const LINE_S := 2.2                    # a line's turn with no take
const LINE_FADE_S := 0.4

var key := ""
var shown := 0
var _line_t := 0.0
var _finished := false
var _dim: ColorRect
var _card: Panel
var _art: TextureRect
var _face: TextureRect
var _kicker: Label
var _title: Label
var _sub: Label
var _lines: Array = []
var _tiles: Array = []                 # [panel, head, body]
var _hint: Label
var _go_on: Button
var _voice: AudioStreamPlayer
var _vlen := 0.0
var _vt := 0.0
var voice_on := true                   # the pause menu's Sound: off, the lines keep the take's time, unheard
var met_count := 0                     # for the hint: how many of the rooms have been met


func _init(room_key: String) -> void:
	key = room_key
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Pal.DIM
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_card = UI.panel(self, Rect2(0, 0, W, H), UI.box(Pal.PANEL, 12, 2, Pal.CARD_LINE))
	_card.clip_contents = true
	_art = TextureRect.new()
	_art.position = Vector2(2, 2)
	_art.size = Vector2(W - 4, BAND_H)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_art)
	var g := Gradient.new()                 # shaded from the left, as the room bands are, so the words read
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(Pal.PANEL, 0.95), Color(Pal.PANEL, 0.55), Color(Pal.PANEL, 0.1)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(1, 0)
	gt.width = 64
	gt.height = 4
	var shade := TextureRect.new()
	shade.texture = gt
	shade.position = _art.position
	shade.size = _art.size
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(shade)
	_face = People.rect(_card, Vector2(40, 22), FACE / 128.0)
	_kicker = UI.label(_card, Rect2(0, 64, 700, 30), "", "SemiBold", 22, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_title = UI.label(_card, Rect2(0, 94, 760, 66), "", "Bold", 52, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(_card, Rect2(0, 166, 760, 34), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(LINES):
		var l := UI.label(_card, Rect2(PAD, LINE_Y + LINE_GAP * k, W - 2 * PAD, 42), "", "Medium", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		_lines.append(l)
	var tw: float = (W - 2 * PAD - 2 * TILE_GAP) / 3.0
	for k in range(3):
		var x: float = PAD + k * (tw + TILE_GAP)
		var p := UI.panel(_card, Rect2(x, TILE_Y, tw, TILE_H), UI.box(Pal.BG, 6))
		var h := UI.label(p, Rect2(18, 12, tw - 36, 28), "", "SemiBold", 20, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		var b := UI.label(p, Rect2(18, 44, tw - 36, 34), "", "Medium", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		_tiles.append([p, h, b])
	_hint = UI.label(_card, Rect2(PAD, H - PAD - 40, 640, 40), "", "Regular", 22, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_go_on = UI.button(_card, Rect2(W - PAD - 220, H - PAD - 64, 220, 64), true)
	_go_on.text = "Go on"
	_go_on.focus_mode = Control.FOCUS_NONE
	_go_on.mouse_filter = Control.MOUSE_FILTER_IGNORE     # a click anywhere moves it on (_input); the button shows where
	_voice = AudioStreamPlayer.new()
	_voice.volume_db = VOICE_DB
	add_child(_voice)
	_fill()


func _ready() -> void:
	_hint.text = "Click or Space · %d of %d rooms met" % [mini(met_count, Words.ROOM_INTROS.size()), Words.ROOM_INTROS.size()]
	if _vlen > 0.0 and voice_on:
		_voice.play()
	_place(get_viewport_rect().size)
	get_viewport().size_changed.connect(func(): _place(get_viewport_rect().size))


func _place(s: Vector2) -> void:
	size = s
	_dim.size = s
	_card.position = ((s - Vector2(W, H)) / 2.0).floor()


## The room's words, art and take; the first line up at once.
func _fill() -> void:
	var d: Dictionary = Words.ROOM_INTROS[key]
	_art.texture = UI.place_texture(_place_of(key))
	var faced := People.show(_face, str(d["face"])) if str(d["face"]) != "" else People.show(_face, "")
	var tx: float = 40 + FACE + 24 if faced else PAD
	for l in [_kicker, _title, _sub]:
		l.position.x = tx
		l.size.x = W - tx - PAD
	_kicker.text = str(d["room"]).to_upper()
	_title.text = str(d["title"])
	_sub.text = sub_of(key)
	var all: Array = d["lines"]
	for k in range(_lines.size()):
		_lines[k].text = all[k] if k < all.size() else ""
		_lines[k].modulate.a = 0.0
	for k in range(_tiles.size()):
		_tiles[k][1].text = str(d["tiles"][k][0]).to_upper()
		_tiles[k][2].text = str(d["tiles"][k][1])
	var vs: AudioStream = _voice_of(d)
	if vs != null:
		_voice.stream = vs
		_vlen = vs.get_length()
	shown = 0
	_vt = 0.0
	_line_t = LINE_S                       # the first line straight away


## The place art each room's band already uses (art/places/).
static func _place_of(k: String) -> String:
	return {"map": "The map", "kit": "The kit room", "stats": "The Stats", "training": "The caravan", "clinic": "The Clinic",
			"fence": "The Fence", "workshop": "The workshop", "yard": "The yard", "radio": "The radio"}.get(k, "")


## The line under the name: what opened a gated room, nothing for the rest.
static func sub_of(k: String) -> String:
	var shut: Dictionary = Words.GATES["shut"]
	return ("Opened with " + str(shut[k])) if shut.has(k) else ""


static func _voice_of(d: Dictionary) -> AudioStream:
	var path: String = VOICE % str(d.get("voice", ""))
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		var mp := AudioStreamMP3.new()
		mp.data = FileAccess.get_file_as_bytes(path)
		return mp if mp.get_length() > 0.0 else null
	return null


func total() -> int:
	return Words.ROOM_INTROS[key]["lines"].size()


## On the take's cues: a take, and a cue a line.
func voiced() -> bool:
	var d: Dictionary = Words.ROOM_INTROS[key]
	return _vlen > 0.0 and d.has("cues") and d["cues"].size() >= total()


func _process(dt: float) -> void:
	if _finished:
		return
	_line_t += dt
	if voiced():
		_vt += dt
		var cues: Array = Words.ROOM_INTROS[key]["cues"]
		while shown < total() and _vt >= float(cues[shown]) - 0.1:
			_next_line()
	elif shown < total() and _line_t >= LINE_S:
		_next_line()
	for i in range(shown):
		_lines[i].modulate.a = minf(1.0, _lines[i].modulate.a + dt / LINE_FADE_S)


func _next_line() -> void:
	shown = mini(shown + 1, total())
	_line_t = 0.0


## A press: the next line now, or with them all up, close.
func advance() -> void:
	if shown < total():
		if voiced():
			_vt = float(Words.ROOM_INTROS[key]["cues"][shown])
			if _voice.playing:
				_voice.seek(_vt)
		_next_line()
		for i in range(shown):
			_lines[i].modulate.a = maxf(_lines[i].modulate.a, 0.35)
	else:
		finish()


func _input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("ui_cancel") and not (event is InputEventKey):
		finish()
	elif event.is_action_pressed("ui_accept") and not (event is InputEventKey):
		advance()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			finish()
		elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_RIGHT]:
			advance()
		# any other key stops here too: nothing behind the card moves (the review)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
	else:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func finish() -> void:
	if _finished:
		return
	_finished = true
	_voice.stop()
	done.emit()
	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()


## Every label, for the tests' fit sweep.
func text_nodes() -> Array:
	var out: Array = [_kicker, _title, _sub, _hint]
	out.append_array(_lines)
	for t in _tiles:
		out.append_array([t[1], t[2]])
	return out
