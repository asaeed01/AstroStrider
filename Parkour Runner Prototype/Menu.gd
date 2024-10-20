extends Control

func _on_play_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://world.tscn")

func _on_help_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://Help.tscn")

func _on_quit_pressed() -> void:
	pass # Replace with function body.
	get_tree().quit()
