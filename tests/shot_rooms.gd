extends SceneTree
## Renders the Yard, the Caravan, the Fence and the Clinic to PNGs beside the project.
func _init() -> void:
	var main = load("res://scripts/ui/main.gd").new()
	main.intro = false
	root.add_child(main)
	main.new_game()
	main.sim.set_class("Scrapper")
	await process_frame
	main._menu.close()
	for pair in [["OVERVIEW", "yard"], ["MISSIONS", "runs"], ["BARRACKS", "caravan"], ["MARKET", "fence"], ["MEDIC", "clinic"]]:
		main.show_room(main.get(pair[0]))
		main.refresh()
		await process_frame
		await process_frame
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../room_%s.png" % pair[1]))
	quit()
