extends Control
## The sky, shown (23 Oct, parked item 8; Matt: "we advertise night/day on the map and then rain but nothing in game
## signifies those states"). A layer over a scene - the Map's painting under its pins, the fight's scene under its
## figures: night's blue wash, fog's pale one, and the rain as Greenhorn's (watch_deck_fx.gd, atmosphere.gd): two
## layers of pixel streaks, a light drizzle always on and a heavy one that comes and goes in showers, both leaning
## with the gusts. Nothing here changes a number; the words on the cards are the sim's as before.

const NIGHT := Color(0.04, 0.07, 0.2, 0.52)
const FOG := Color(0.77, 0.79, 0.82, 0.34)
const FOG_BAND := Color(0.86, 0.88, 0.9, 0.22)        # heavier at the top and the foot
const RAIN_WASH := Color(0.08, 0.11, 0.16, 0.32)
const RAIN_COLOUR := Color(0.82, 0.88, 0.97, 0.7)
# Greenhorn's figures, for a 1920 x 1080 view: the count scales with the view's area, the streak with its height
const LIGHT := {"amount": 40, "floor": 40, "speed": 1350.0, "w": 6.0, "len": 21.0}
const HEAVY := {"amount": 150, "floor": 120, "speed": 1950.0, "w": 7.5, "len": 39.0}
const LEAN := 0.28                                     # the fall's slant, as Greenhorn's FALL_DIRECTION
const GUST := 0.22                                     # how far the gusts swing the slant
const SHOWER_S := 14.0                                 # a shower's round, seconds; the heavy layer comes and goes on it
const FALL_SPREAD := 6.0

var night := false
var weather := ""
var _night: ColorRect
var _fog: ColorRect
var _fog_top: ColorRect
var _fog_foot: ColorRect
var _wash: ColorRect
var _light: CPUParticles2D
var _heavy: CPUParticles2D
var _t := 0.0


func _init(sz: Vector2) -> void:
	size = sz
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_night = _rect(NIGHT)
	_wash = _rect(RAIN_WASH)
	_fog = _rect(FOG)
	_fog_top = _rect(FOG_BAND)
	_fog_top.size.y = sz.y * 0.22
	_fog_foot = _rect(FOG_BAND)
	_fog_foot.size.y = sz.y * 0.22
	_fog_foot.position.y = sz.y - _fog_foot.size.y
	_light = _rain(LIGHT)
	_heavy = _rain(HEAVY)
	add_child(_light)
	add_child(_heavy)
	set_sky(false, "")


func _rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.size = size
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.visible = false
	add_child(r)
	return r


## A rain layer, Greenhorn's _build_falling: a pixel streak, falling from a line above the top, leaning LEAN.
func _rain(cfg: Dictionary) -> CPUParticles2D:
	var node := CPUParticles2D.new()
	var w: float = maxf(2.0, round(float(cfg["w"]) * 0.4))              # Greenhorn's streak, thinner: ours draw at x2 in the fight
	var streak: float = maxf(8.0, round(float(cfg["len"]) * 0.8))
	var image := Image.create(int(w), int(streak), false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	node.texture = ImageTexture.create_from_image(image)
	node.color = RAIN_COLOUR
	node.emitting = false
	node.visible = false
	var speed: float = float(cfg["speed"]) * 0.8
	node.amount = maxi(int(cfg["floor"]), int(round(float(cfg["amount"]) * (size.x * size.y) / (1920.0 * 1080.0) * 1.6)))     # a small view keeps a floor, else a fight's window shows five drops
	node.lifetime = (size.y + 160.0) / speed * 1.2             # the slant at a gust's peak lengthens the fall (the review)
	node.position = Vector2(size.x / 2.0, -60.0)
	node.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	node.emission_rect_extents = Vector2(size.x / 2.0 + size.y * (LEAN + GUST + 0.1), 1.0)     # wide enough that a gust leaves no dry edge (the review)
	node.gravity = Vector2.ZERO
	node.direction = Vector2(LEAN, 1.0).normalized()
	node.spread = FALL_SPREAD
	node.initial_velocity_min = speed * 0.9
	node.initial_velocity_max = speed * 1.1
	node.scale_amount_min = 0.85
	node.scale_amount_max = 1.15
	node.angle_min = rad_to_deg(Vector2(LEAN, 1.0).angle()) - 90.0
	node.angle_max = node.angle_min
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return node


## The sky as the sim has it: night or day, "Rain", "Fog" or "" (the zone's). Night and weather stack.
func set_sky(is_night: bool, w: String) -> void:
	night = is_night
	weather = w
	_night.visible = night
	var raining: bool = w == "Rain"
	var foggy: bool = w == "Fog"
	_wash.visible = raining
	_fog.visible = foggy
	_fog_top.visible = foggy
	_fog_foot.visible = foggy
	_apply()


## The rain runs only while the layer shows (the review): a hidden Map or fight neither emits nor ticks. The walk up
## stops at the first Window: under the headless display the root reads as hidden (the smoke on Matt's machine).
func _shown() -> bool:
	var n: Node = self
	while n != null and n is CanvasItem:
		if not (n as CanvasItem).visible:
			return false
		n = n.get_parent()
	return true


func _apply() -> void:
	var on: bool = weather == "Rain" and _shown()
	for p in [_light, _heavy]:
		p.visible = on
		p.emitting = on
	set_process(on)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_apply()


## The showers and the gusts (Greenhorn: "a gust arrives as the sky fills with it"): the heavy layer's alpha rides a
## slow wave, both layers' slant swings with a faster one.
func _process(dt: float) -> void:
	_t += dt
	var shower: float = clampf(0.5 + 0.8 * sin(_t * TAU / SHOWER_S) + 0.3 * sin(_t * 1.7), 0.0, 1.0)
	_heavy.modulate.a = shower
	var lean: float = LEAN + GUST * sin(_t * 0.7) + 0.1 * sin(_t * 2.3)
	var dir := Vector2(lean, 1.0).normalized()
	for p in [_light, _heavy]:
		p.direction = dir
		p.angle_min = rad_to_deg(dir.angle()) - 90.0
		p.angle_max = p.angle_min


## For the smoke: what's showing.
func showing() -> Dictionary:
	return {"night": _night.visible, "rain": _light.emitting, "fog": _fog.visible, "shower": _heavy.modulate.a}
