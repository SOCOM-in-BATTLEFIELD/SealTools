@tool
extends EditorPlugin

var panel
const SEAL_MAPPER_PANEL = preload("res://addons/SealMapper/SealMapper_panel.tscn")

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	panel = SEAL_MAPPER_PANEL.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, panel)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_docks(panel)
	panel.free()
