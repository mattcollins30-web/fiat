extends Control
## The game's first scene (BUILD45, 2 Nov, perf44 10: 3.4-3.8 s compiling the game's scripts before the first frame,
## then the studio card's 2 s on top): the studio card goes up at once while main.gd and everything it preloads are
## loaded on the loader's thread behind it; the camp's shell comes in when both are done (the card skipped by any key
## or click, as ever). main.gd is the game as before: the tests and tools that make it straight are unchanged.

const Intro := preload("res://scripts/ui/intro.gd")
const MAIN := "res://scripts/ui/main.gd"

var _card_done := false
var _asked := false
var main_path := MAIN                      # the tests point it at a file that isn't there (the failed load's path)
var quit_on_fail := true                   # the tests stay up to read `failed`
var failed := false
var black: ColorRect                       # under the card until the hand-over (review45u 1: the default grey between them)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	black = ColorRect.new()
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.set_anchors_preset(Control.PRESET_FULL_RECT)     # its anchors fill the boot screen: no size set (BUILD53: "Nodes with non-equal opposite anchors will have their size overridden")
	add_child(black)
	fit_window(get_window())                # the Deck's window fitted before the card draws, not after the load (review45u 8)
	if DisplayServer.get_name() != "headless":
		Engine.max_fps = 60                    # the card's frames leave the loader the CPU (main sets its own cap after)
	_asked = ResourceLoader.load_threaded_request(main_path, "", false) == OK
	var card := Intro.new()
	card.done.connect(func(): _card_done = true)
	add_child(card)


func _process(_dt: float) -> void:
	if not _card_done:
		return
	if _asked and ResourceLoader.load_threaded_get_status(main_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	set_process(false)
	var script: GDScript = (ResourceLoader.load_threaded_get(main_path) if _asked else null) as GDScript
	if script == null and ResourceLoader.exists(main_path):
		script = load(main_path) as GDScript      # the thread failed: the plain load, as before
	if script == null:
		failed = true                          # neither load: said, and the game shuts, not a blank window (review45u 9)
		push_error("the game's script didn't load: %s" % main_path)
		if quit_on_fail:
			get_tree().quit(1)
		return
	var main: Control = script.new()
	main.name = "Main"
	main.card_shown = true                 # the studio card's been up: straight to the title
	main.booted = true
	var tree := get_tree()
	tree.root.add_child(main)
	tree.current_scene = main
	queue_free()


## The window fitted to the screen on Linux (the Steam Deck's game mode: windowed at the panel's own size, 8 Oct); main
## calls it too, as before. Windows and headless untouched.
static func fit_window(win: Window) -> void:
	if DisplayServer.get_name() == "headless" or OS.get_name() != "Linux":
		return
	if win == null or win.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
		return
	var screen: Vector2i = DisplayServer.screen_get_size(win.current_screen)
	if screen.x <= 0 or screen.y <= 0:
		return
	# the project opens the window maximized on Windows only (window/size/mode.windows=2, 8 Oct): on
	# the Deck a maximized 1920 x 1080 window had gamescope set its own screen to 1920 x 1080 (the
	# foot read "1920×1080 → 1920×1080" in game mode), so there was no smaller screen to size to;
	# windowed, as Greenhorn's is, the screen stays the panel's 1280 x 800. Windowed here too, in case.
	win.mode = Window.MODE_WINDOWED
	win.size = screen                      # through the Window, so the canvas follows at once
	win.position = DisplayServer.screen_get_position(win.current_screen)
