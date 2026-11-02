extends SceneTree
## The boot scene as the game starts it (BUILD45 review45u 1, 7, 8, 9), in a tree that runs its frames: the smoke's own
## runs in _init, outside one, so it starts this (`-s res://tests/boot_check.gd`) and reads the line it prints.
## Checked: black under the card and still there once the card's gone; the window fitted before the card draws; main
## takes over (the current scene, `booted`, the card not again, Sim.asks on) and boot frees itself; then a main.gd that
## won't load is said (`failed`) and nothing comes up. The smoke starts it on Linux only (the cloud, xvfb), with the
## dummy audio and its own XDG data home; `-- out <file>` is where it writes what it found.

const Sim := preload("res://scripts/sim/sim.gd")
const Intro := preload("res://scripts/ui/intro.gd")
const MAIN := "res://scripts/ui/main.gd"

var out := {}
var boot = null
var bad = null
var new_main = null
var frames := 0
var phase := -1
var screen := Vector2i.ZERO
var card_ref = null
var black_ref = null


func _card_of(n: Node):
	for ch in n.get_children():
		if ch.get_script() == Intro:
			return ch
	return null


func _initialize() -> void:
	Sim.asks = false
	screen = DisplayServer.screen_get_size(root.current_screen)
	root.mode = Window.MODE_WINDOWED


## The window made small first (a frame for it to take), then boot: its own _ready must fit it.
func _start_boot() -> void:
	out["shrunk"] = root.size == Vector2i(800, 600)
	boot = load("res://scenes/boot.tscn").instantiate()
	boot.ready.connect(_boot_ready)               # read as its _ready ends: before any frame, before main's own fit
	root.add_child(boot)


func _boot_ready() -> void:
	out["fitted"] = out["shrunk"] and root.size == screen       # Linux only: the smoke runs this in the cloud alone
	out["size"] = str(root.size)
	out["screen"] = str(screen)
	var black = boot.get("black")
	var card = _card_of(boot)
	out["card"] = card != null
	card_ref = card
	black_ref = black
	# boot's own, not the card's (the card frees itself with its black): up till boot goes, at the hand-over
	out["black_held"] = black is ColorRect and black.get_parent() == boot and black.size.x >= 800.0
	out["black_under"] = black is ColorRect and black.get_parent() == boot and (black as ColorRect).color == Color.BLACK and card != null and black.get_index() < card.get_index()
	if card != null:
		card._finish()                        # skipped, as a key does


func _process(_dt: float) -> bool:
	frames += 1
	if phase == -1:
		if frames == 1:
			root.size = Vector2i(800, 600)
		elif frames == 4:
			_start_boot()
			phase = 0
			frames = 0
		return false
	if phase == 0:
		if not out.has("black_seen") and card_ref != null and not is_instance_valid(card_ref) and is_instance_valid(boot):
			out["black_seen"] = true
			# the first frame the card's gone: the black still up under whatever comes next
			out["black_held"] = is_instance_valid(boot) and black_ref is ColorRect and is_instance_valid(black_ref) and black_ref.is_visible_in_tree() and black_ref.size.x >= 800.0
		for ch in root.get_children():
			if ch != boot and ch.get_script() != null and ch.get_script().resource_path == MAIN:
				new_main = ch
		if new_main != null:
			phase = 1
			frames = 0
		elif frames > 3000:
			out["handed"] = false
			return _done()
	elif phase == 1:
		if frames < 3:
			return false
		out["handed"] = true
		out["current"] = current_scene == new_main
		out["booted"] = bool(new_main.booted) and bool(new_main.card_shown)
		out["card_again"] = _card_of(new_main) != null
		out["asks"] = Sim.asks
		out["boot_freed"] = not is_instance_valid(boot)
		bad = load("res://scenes/boot.tscn").instantiate()
		bad.set("main_path", "res://scripts/ui/no_such_main.gd")
		bad.set("quit_on_fail", false)
		root.add_child(bad)
		var c = _card_of(bad)
		if c != null:
			c._finish()
		phase = 2
		frames = 0
	elif phase == 2:
		if frames < 5:
			return false
		out["failed_said"] = bool(bad.get("failed"))
		var extra := 0
		for ch in root.get_children():
			if ch != new_main and ch.get_script() != null and ch.get_script().resource_path == MAIN:
				extra += 1
		out["failed_blank"] = extra == 0
		return _done()
	return false


func _done() -> bool:
	print("BOOT_CHECK " + JSON.stringify(out))
	var args := OS.get_cmdline_user_args()
	var oi := args.find("out")
	if oi >= 0 and oi + 1 < args.size():
		var f := FileAccess.open(args[oi + 1], FileAccess.WRITE)     # the smoke reads it (a child's stdout isn't caught off Linux)
		if f != null:
			f.store_string(JSON.stringify(out))
			f.close()
	quit()
	return true
