extends SceneTree
## Renders the Lock-up to a PNG, so a layout change can be looked at and not
## just measured: on the Legion `godot --path . --rendering-driver opengl3
## -s tests/shot.gd` (under xvfb-run on a headless Linux box). Writes
## lockup.png beside the project.
func _init() -> void:
	var main = load("res://scripts/ui/main.gd").new()
	main.intro = false
	root.add_child(main)
	main.new_game()
	var sim = main.sim
	# a few things in the stash to see the packing
	for pair in [["Primary", "Old .303"], ["Armour", "Riot suit"], ["Helmet", "Hard hat"], ["Medical", "First aid kit"], ["Ammo", "Shells"], ["Backpack", "Bergen"], ["Secondary", "Flare pistol"], ["Attachment", "Red dot"]]:
		sim.stash.append(sim._plain(pair[0], pair[1]))
	main.show_room(main.ARMOURY)
	main._menu.close()
	main._menu.close()
	main._armoury._pick_slot("Backpack")
	main.refresh()
	await process_frame
	main._menu.close()
	main.refresh()
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://../lockup.png"))
	quit()
