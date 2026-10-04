extends SceneTree
## Renders the studio card (held) and the title to PNGs beside the project.
func _init() -> void:
	var main = load("res://scripts/ui/main.gd").new()
	root.add_child(main)
	await process_frame
	await create_timer(0.9).timeout
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../studio.png"))
	await create_timer(1.6).timeout
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../title.png"))
	quit()
