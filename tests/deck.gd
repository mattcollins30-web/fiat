extends SceneTree
## The Steam Deck's screen (8 Oct): a 1280 x 800 screen handed the project's 1920 x 1080 window.
## Under gamescope "maximized" means nothing, the picture is scaled to fit but the pointer stops
## at the screen's edge, so the rail from the Fence down could not be clicked. main fits the
## window to the screen at start; the canvas follows (canvas_items, expand) and every rail row
## ends inside the window. Needs a display: run under a 1280 x 800 X screen -
##   xvfb-run -s "-screen 0 1280x800x24" godot --path . -s tests/deck.gd
## (headless has no window to size). Exit 1 on a row past the window.
func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))         # as the Deck gets it
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)     # and as the project asks (window/size/mode=2)
	await process_frame
	await process_frame
	var main = load("res://scripts/ui/main.gd").new()
	main.intro = false
	root.add_child(main)
	main.new_game()
	for i in range(30):
		await process_frame
	var win := DisplayServer.window_get_size()
	var screen := DisplayServer.screen_get_usable_rect().size
	var xf: Transform2D = root.get_final_transform()
	var bad := 0
	if win.x > screen.x or win.y > screen.y:
		push_error("the window is %s on a %s screen" % [win, screen])
		bad += 1
	for name in main.ROOMS:
		var bottom: Vector2 = xf * main._rail_buttons[name].get_global_rect().end
		if bottom.y > win.y + 0.5:
			push_error("%s ends at window y %.0f, past the window's %d" % [name, bottom.y, win.y])
			bad += 1
	print("deck: window %s, canvas %s, %s" % [win, root.get_visible_rect().size, "every rail row inside the window" if bad == 0 else "%d rows past it" % bad])
	quit(1 if bad > 0 else 0)
