extends RefCounted
## Portraits: res://art/people/<slug>.png, 128 x 128, Greenhorn's faces -
## one a class (poacher, doorman, paramedic, scrapper, drifter), the Fence,
## the medic. Looked for once; a screen that has one draws it at 1x or 2x
## (never between), and shows nothing where there is none.

const Items := preload("res://scripts/sim/items.gd")

static var _cache := {}


static func portrait(name: String) -> Texture2D:
	var s := Items.slug(name)
	if not _cache.has(s):
		var path := "res://art/people/%s.png" % s
		_cache[s] = null
		if ResourceLoader.exists(path):
			_cache[s] = load(path)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null:
				_cache[s] = ImageTexture.create_from_image(img)
	return _cache[s]


## A TextureRect for a portrait at an integer scale (or a clean half, for a
## wall of small faces), hidden until shown.
static func rect(parent: Node, at: Vector2, scale: float) -> TextureRect:
	var t := TextureRect.new()
	t.position = at
	t.size = Vector2(128 * scale, 128 * scale)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.visible = false
	parent.add_child(t)
	return t


## Point the rect at a person, or hide it. Returns whether it shows.
static func show(t: TextureRect, name: String) -> bool:
	var tex := portrait(name) if name != "" else null
	t.texture = tex
	t.visible = tex != null
	return t.visible
