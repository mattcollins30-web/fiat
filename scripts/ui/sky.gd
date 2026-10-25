extends Control
## The sky, shown (23 Oct, parked item 8; Matt: "we advertise night/day on the map and then rain but nothing in game
## signifies those states"). A layer over a scene - the Map's painting under its pins, the fight's scene under its
## figures: night's blue wash, fog's pale one, and the rain as Greenhorn's (watch_deck_fx.gd, atmosphere.gd): two
## layers of pixel streaks, a light drizzle always on and a heavy one that comes and goes in showers, both leaning
## with the gusts. Nothing here changes a number; the words on the cards are the sim's as before.

const NIGHT := Color(0.04, 0.07, 0.2, 0.52)
# the fog (23 Oct, Matt: "the fog needs some work on the map, it's drawing weirdly" - a flat sheet and two hard bands):
# banks of it, two layers of one seamless noise drifting at their own speeds, thick in places and clear in others,
# over a faint tint, so the painting keeps its contrast. A shader on TIME: nothing ticks on the CPU, and hidden it
# isn't drawn. The Map's: MAP_FOG; the fight's thinner and a little quicker (FIGHT_FOG), under the figures.
const FOG_TINT := Color(0.84, 0.863, 0.894)
const MAP_FOG := {"tile_a": 870.0, "tile_b": 512.0, "drift_a": Vector2(9.0, 2.0), "drift_b": Vector2(15.0, -1.5), "max_a": 0.46, "max_b": 0.3, "base": 0.035}
const FIGHT_FOG := {"tile_a": 666.0, "tile_b": 410.0, "drift_a": Vector2(16.0, 1.5), "drift_b": Vector2(26.0, -1.0), "max_a": 0.36, "max_b": 0.24, "base": 0.035}
const FOG_SHADER := """
shader_type canvas_item;
uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec2 px_size = vec2(1018.0, 844.0);
uniform vec3 tint = vec3(0.84, 0.863, 0.894);
uniform float tile_a = 870.0;
uniform float tile_b = 512.0;
uniform vec2 drift_a = vec2(9.0, 2.0);
uniform vec2 drift_b = vec2(15.0, -1.5);
uniform float max_a = 0.46;
uniform float max_b = 0.3;
uniform float base = 0.035;
// a bank where the noise is high: nothing under 0.46, the whole bank by 0.76, eased
float bank(float n) {
	float a = clamp((n - 0.46) / 0.3, 0.0, 1.0);
	return a * a * (3.0 - 2.0 * a);
}
void fragment() {
	vec2 p = UV * px_size;
	float a = bank(texture(noise, (p - TIME * drift_a) / tile_a).r) * max_a;
	float b = bank(texture(noise, (p - TIME * drift_b) / tile_b + vec2(0.37, 0.61)).r) * max_b;
	COLOR = vec4(tint, 1.0 - (1.0 - base) * (1.0 - a) * (1.0 - b));     // the tint, then the two banks over it
}
"""
static var _fog_noise: NoiseTexture2D
const RAIN_WASH := Color(0.08, 0.11, 0.16, 0.32)
const RAIN_COLOUR := Color(0.82, 0.88, 0.97, 0.7)
# Greenhorn's figures, for a 1920 x 1080 view: the count scales with the view's area, the streak with its height. Half
# the drops at half the speed (25 Oct, Matt: "too fast and too much ... dialling back by about 50%")
const LIGHT := {"amount": 20, "floor": 20, "speed": 675.0, "w": 6.0, "len": 21.0}
const HEAVY := {"amount": 75, "floor": 60, "speed": 975.0, "w": 7.5, "len": 39.0}
const LEAN := 0.28                                     # the fall's slant, as Greenhorn's FALL_DIRECTION
const GUST := 0.22                                     # how far the gusts swing the slant
const SHOWER_S := 14.0                                 # a shower's round, seconds; the heavy layer comes and goes on it
const FALL_SPREAD := 6.0

var night := false
var weather := ""
var _night: ColorRect
var _fog: ColorRect
var _wash: ColorRect
var _light: CPUParticles2D
var _heavy: CPUParticles2D
var _t := 0.0


func _init(sz: Vector2, thin := false) -> void:
	size = sz
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_night = _rect(NIGHT)
	_wash = _rect(RAIN_WASH)
	_fog = _rect(Color.WHITE)
	_fog.material = _fog_material(FIGHT_FOG if thin else MAP_FOG)
	_light = _rain(LIGHT)
	_heavy = _rain(HEAVY)
	add_child(_light)
	add_child(_heavy)
	set_sky(false, "")


## Godot turns _process on at ready for a script that has one (23 Oct, the fans: the Map's and the fight's layers
## ticked every frame dry); off again unless it's raining.
func _ready() -> void:
	_apply()


func _rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.size = size
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.visible = false
	add_child(r)
	return r


## The seamless noise the fog's banks and the Map's cloud edge are drawn from (23 Oct), made once.
static func noise() -> NoiseTexture2D:
	if _fog_noise == null:
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_PERLIN
		fn.frequency = 4.0 / 256.0
		fn.fractal_octaves = 3
		_fog_noise = NoiseTexture2D.new()
		_fog_noise.width = 256
		_fog_noise.height = 256
		_fog_noise.seamless = true
		_fog_noise.noise = fn
	return _fog_noise


## The fog's shader, its noise made once for both layers (seamless, so the drift never shows an edge).
func _fog_material(cfg: Dictionary) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = FOG_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("noise", noise())
	mat.set_shader_parameter("px_size", size)
	mat.set_shader_parameter("tint", Vector3(FOG_TINT.r, FOG_TINT.g, FOG_TINT.b))
	for k in cfg:
		mat.set_shader_parameter(k, cfg[k])
	return mat


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
