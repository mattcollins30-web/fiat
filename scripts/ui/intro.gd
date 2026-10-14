extends Control
## The studio card: the first thing on screen. Greenhorn's splash, the same
## mark: black, "MUNDANE STUDIOS" in Inter at 60 with 15 px of letter
## spacing, white, fading in over half a second, held a second, out over
## half (scripts/ui/splash.gd there). An art/studio.png takes the words'
## place if one ever exists. Any key or click skips it; then `done`.
## Frees itself.

signal done

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const ART := "res://art/studio.png"
const FADE_IN_S := 0.5
const HOLD_S := 1.0
const FADE_OUT_S := 0.5
const FONT_SIZE := 60
const LETTER_SPACING := 15
const MARK_W := 1200               # the mark's box; the picture keeps its aspect inside it

var _bg: ColorRect
var _mark: Control
var _finished := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = ColorRect.new()
	_bg.color = Color.BLACK
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	if ResourceLoader.exists(ART) or FileAccess.file_exists(ART):
		var t := TextureRect.new()
		t.texture = load(ART) if ResourceLoader.exists(ART) else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(ART)))
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		@warning_ignore("integer_division")
		t.size = Vector2(MARK_W, MARK_W / 2)
		_mark = t
	else:
		var l := UI.label(self, Rect2(0, 0, MARK_W, 100), "MUNDANE STUDIOS", "Regular", FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, false)
		var fv := FontVariation.new()
		fv.base_font = load("res://fonts/Inter-Regular.ttf")
		fv.set_spacing(TextServer.SPACING_GLYPH, LETTER_SPACING)
		l.add_theme_font_override("font", fv)
		_mark = l
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.modulate.a = 0.0
	if _mark.get_parent() == null:
		add_child(_mark)


func _ready() -> void:
	_place(get_viewport_rect().size)
	get_viewport().size_changed.connect(func(): _place(get_viewport_rect().size))
	var tw := create_tween()
	tw.tween_property(_mark, "modulate:a", 1.0, FADE_IN_S)
	tw.tween_interval(HOLD_S)
	tw.tween_property(_mark, "modulate:a", 0.0, FADE_OUT_S)
	tw.tween_callback(_finish)


## Sized by hand from the viewport, not anchored: a preset applied before
## the node is in the tree leaves it at nothing (Greenhorn's own lesson).
func _place(s: Vector2) -> void:
	size = s
	_bg.size = s
	_mark.position = ((s - _mark.size) / 2.0).floor()


func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	done.emit()
	queue_free()
