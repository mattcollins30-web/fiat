extends Control
## Storeys' cards can carry an in-engine drawing; Clade's don't yet. This keeps
## card.gd unchanged: a sketch that draws nothing and takes no room.

const Pal := preload("res://scripts/ui/palette.gd")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_sketch(d: Dictionary) -> void:
	visible = not d.is_empty()


## For tests/ui_check.gd, when Clade has one.
func text_nodes() -> Array:
	return []
