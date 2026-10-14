extends Control
## The opening (14 Oct, docs/design/intro.md): a new camp fades up from black into six scenes, 2028 to now - one picture
## each, full screen and drifting, the year and the scene's name at the top left, its lines fading in one at a time at
## the foot. A click, Space or Enter brings the next line (or the next scene once they're all up); Esc skips the lot.
## Left alone it plays itself in about a minute. A scene without its picture yet stands on a dark ground. Then `done`.
## Frees itself. Nothing here changes the sim.

signal done

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Words := preload("res://scripts/sim/words.gd")

const ART := "res://art/intro/%s.png"
const VOICE := "res://art/intro/voice/%s.mp3"     # Matt's reading of each scene (14 Oct); the lines come up on its cues
const VOICE_DB := -1.0
const VOICE_HOLD_S := 1.4              # the scene held after its reading ends
const LINE_S := 2.8                    # a line's turn, left alone
const HOLD_S := 2.6                    # the scene held once its lines are up
const FADE_S := 0.7                    # black between scenes
const LINE_FADE_S := 0.6
const DRIFT := 0.07                    # how far the picture pushes in over a scene
const LINE_GAP := 58

var scenes: Array = Words.OPENING_SCENES
var scene := -1                        # which scene's up
var shown := 0                         # how many of its lines are up
var _t := 0.0                          # time in this scene
var _line_t := 0.0                     # time since the last line came up
var _finished := false
var _bg: ColorRect
var _pic: TextureRect
var _shade: TextureRect
var _year: Label
var _title: Label
var _lines: Array = []
var _pips: Array = []
var _hint: Label
var _black: ColorRect                  # the fade between scenes, over everything
var _fading := 0.0                     # >0 fading out to the next scene, <0 fading up into it
var _voice: AudioStreamPlayer
var _vlen := 0.0                       # this scene's reading's length; 0 with none (the lines then go on the clock)
var _vt := 0.0                         # how far into the reading
var voice_on := true                   # the pause menu's Sound: off, the lines still keep the reading's time, unheard


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = ColorRect.new()
	_bg.color = Color.BLACK
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_pic = TextureRect.new()
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pic)
	_shade = TextureRect.new()
	_shade.texture = _shade_tex()
	_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shade.stretch_mode = TextureRect.STRETCH_SCALE
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_year = UI.label(self, Rect2(80, 64, 600, 56), "", "SemiBold", 44, Color(0.88, 0.88, 0.86), HORIZONTAL_ALIGNMENT_LEFT, false)
	_title = UI.label(self, Rect2(82, 120, 600, 36), "", "Regular", 26, Color(0.65, 0.65, 0.63), HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(5):
		var l := UI.label(self, Rect2(0, 0, 1600, 48), "", "Medium", 36, Color(0.92, 0.92, 0.9), HORIZONTAL_ALIGNMENT_CENTER, false)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		_lines.append(l)
	for k in range(scenes.size()):
		var p := Panel.new()
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_theme_stylebox_override("panel", UI.box(Color(0.3, 0.3, 0.3), 5))
		p.size = Vector2(10, 10)
		add_child(p)
		_pips.append(p)
	_hint = UI.label(self, Rect2(0, 0, 500, 30), "Click for more  ·  Esc to skip", "Regular", 22, Color(0.45, 0.45, 0.44), HORIZONTAL_ALIGNMENT_RIGHT, false)
	_voice = AudioStreamPlayer.new()
	_voice.volume_db = VOICE_DB
	add_child(_voice)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	_go(0)


## Dark at the foot for the lines and in the top-left corner for the year; the middle left as the picture is.
static func _shade_tex() -> Texture2D:
	var img := Image.create(96, 54, false, Image.FORMAT_RGBA8)
	for y in range(54):
		for x in range(96):
			var foot: float = pow(clampf((y / 53.0 - 0.5) / 0.5, 0.0, 1.0), 1.3) * 0.92
			var corner: float = clampf(1.0 - Vector2(x / 35.0, y / 16.0).length(), 0.0, 1.0) * 0.7
			img.set_pixel(x, y, Color(0, 0, 0, maxf(foot, corner)))
	return ImageTexture.create_from_image(img)


func _ready() -> void:
	if _vlen > 0.0 and voice_on and not _voice.playing:
		_voice.play(_vt)                   # the first scene's: _go(0) ran before it was in the tree (the review)
	_place(get_viewport_rect().size)
	get_viewport().size_changed.connect(func(): _place(get_viewport_rect().size))


## Sized by hand from the viewport (the studio card's lesson).
func _place(s: Vector2) -> void:
	size = s
	for n in [_bg, _shade, _black]:
		n.size = s
	_lay_lines()
	for k in range(_pips.size()):
		_pips[k].position = Vector2(s.x / 2.0 - _pips.size() * 15 + k * 30, s.y - 48)
	_hint.position = Vector2(s.x - 80 - _hint.size.x, s.y - 58)


func _lay_lines() -> void:
	var s: Vector2 = size
	var n: int = _lines.filter(func(l): return l.text != "").size()
	var y0: float = s.y - 120 - LINE_GAP * maxi(0, n - 1)
	for k in range(_lines.size()):
		var l: Label = _lines[k]
		l.size.x = minf(1700.0, s.x - 120)
		l.position = Vector2((s.x - l.size.x) / 2.0, y0 + LINE_GAP * k)


## Scene i: its picture (or the dark ground), its year and name, its lines waiting.
func _go(i: int) -> void:
	scene = i
	shown = 0
	_t = 0.0
	_line_t = LINE_S                        # the first line comes straight away
	var sc: Dictionary = scenes[i]
	var path: String = ART % sc["art"]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		tex = ImageTexture.create_from_image(img) if img != null else null
	_pic.texture = _trimmed(tex)
	_pic.visible = tex != null
	_year.text = str(sc["year"])
	_title.text = str(sc["title"])
	var all: Array = lines_of(i)
	for k in range(_lines.size()):
		var l: Label = _lines[k]
		l.text = all[k] if k < all.size() else ""
		l.modulate.a = 0.0
		var radio: bool = sc.has("radio") and k == all.size() - 1
		l.add_theme_color_override("font_color", Color(0.55, 0.55, 0.53) if radio else Color(0.92, 0.92, 0.9))
		l.add_theme_font_size_override("font_size", 30 if radio else 36)
	_lay_lines()
	for k in range(_pips.size()):
		_pips[k].add_theme_stylebox_override("panel", UI.box(Color(0.86, 0.86, 0.84) if k == i else Color(0.28, 0.28, 0.28), 5))
	# the reading: from the top as the scene comes up
	_voice.stop()
	_vt = 0.0
	_vlen = 0.0
	var vs: AudioStream = _voice_of(sc)
	if vs != null:
		_voice.stream = vs
		_vlen = vs.get_length()
		if _voice.is_inside_tree() and voice_on:
			_voice.play()
	_fading = -FADE_S                       # up from black


## The picture without the white bands the generator sometimes leaves top and bottom (14 Oct: three of the six came
## with 3 to 32 rows of near-white): the rows that are mostly near-white at either edge are cut off.
static func _trimmed(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return tex
	var w := img.get_width()
	var h := img.get_height()
	var white_row := func(y: int) -> bool:
		var n := 0
		for x in range(0, w, 4):
			var c := img.get_pixel(x, y)
			if minf(c.r, minf(c.g, c.b)) > 0.94:
				n += 1
		return n > (w / 4) * 0.6
	var top := 0
	while top < h / 4 and white_row.call(top):
		top += 1
	var bot := h - 1
	while bot > h * 3 / 4 and white_row.call(bot):
		bot -= 1
	if top == 0 and bot == h - 1:
		return tex
	var inset := 2 if (top > 0 or bot < h - 1) else 0
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(0, top + inset, w, bot - top + 1 - inset * 2)
	return at


## A scene's reading, imported or straight off the disk; null with none (or before the art's made).
static func _voice_of(sc: Dictionary) -> AudioStream:
	if not sc.has("voice"):
		return null
	var path: String = VOICE % sc["voice"]
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		var mp := AudioStreamMP3.new()
		mp.data = FileAccess.get_file_as_bytes(path)
		return mp if mp.get_length() > 0.0 else null
	return null


## Whether this scene's lines are going on its reading's cues.
func voiced() -> bool:
	return _vlen > 0.0 and scenes[scene].has("cues") and scenes[scene]["cues"].size() >= lines_of(scene).size()


## A scene's lines, its radio line last.
func lines_of(i: int) -> Array:
	var sc: Dictionary = scenes[i]
	var out: Array = sc["lines"].duplicate()
	if sc.has("radio"):
		out.append(sc["radio"])
	return out


func _process(dt: float) -> void:
	if _finished:
		return
	# the fade: down to black and on to the next, or up out of it
	if _fading > 0.0:
		_fading = maxf(0.0, _fading - dt)
		_black.color.a = 1.0 - _fading / FADE_S
		if _fading <= 0.0:
			if scene + 1 >= scenes.size():
				finish()
				return
			_go(scene + 1)
		return
	if _fading < 0.0:
		_fading = minf(0.0, _fading + dt)
		_black.color.a = -_fading / FADE_S
	_t += dt
	_line_t += dt
	# the picture pushes in slowly across the scene
	var s: Vector2 = size
	var k: float = 1.0 + DRIFT * clampf(_t / 14.0, 0.0, 1.0)
	_pic.size = s * k
	_pic.position = -(_pic.size - s) * Vector2(0.35 + 0.3 * clampf(_t / 14.0, 0.0, 1.0), 0.5)
	# the lines, one at a time; the scene held once they're all up, then on
	var total: int = lines_of(scene).size()
	if voiced():
		_vt += dt
		var cues: Array = scenes[scene]["cues"]
		while shown < total and _vt >= float(cues[shown]) - 0.1:
			next_line()
		if shown >= total and _vt >= _vlen + VOICE_HOLD_S:
			_fading = FADE_S
	elif shown < total and _line_t >= LINE_S:
		next_line()
	for i in range(_lines.size()):
		var l: Label = _lines[i]
		if i < shown:
			l.modulate.a = minf(1.0, l.modulate.a + dt / LINE_FADE_S)
	if not voiced() and shown >= total and _line_t >= HOLD_S + LINE_FADE_S:
		_fading = FADE_S


func next_line() -> void:
	shown = mini(shown + 1, lines_of(scene).size())
	_line_t = 0.0


## A press: the next line now, or with them all up, the next scene.
func advance() -> void:
	if _fading != 0.0:
		return
	if shown < lines_of(scene).size():
		if voiced():
			_vt = float(scenes[scene]["cues"][shown])     # the reading jumps to the line asked for
			if _voice.playing:
				_voice.seek(_vt)
		next_line()
		for i in range(shown):
			_lines[i].modulate.a = maxf(_lines[i].modulate.a, 0.35)
	else:
		_voice.stop()
		_fading = FADE_S


func _input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("ui_cancel") and not (event is InputEventKey):
		finish()                                # a pad's back (the review: the Deck)
		return
	if event.is_action_pressed("ui_accept") and not (event is InputEventKey):
		advance()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			finish()
		elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_RIGHT]:
			advance()
		if is_inside_tree():
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


func finish() -> void:
	if _finished:
		return
	_finished = true
	_voice.stop()
	done.emit()
	if get_parent() != null:
		get_parent().remove_child(self)     # gone at once, not at the frame's end
	queue_free()
