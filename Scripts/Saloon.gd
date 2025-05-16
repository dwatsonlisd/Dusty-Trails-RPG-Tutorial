# Saloon

extends Node2D



func _on_trigger_area_body_entered(body):
	if body.is_in_group("player"):
		Global.change_scene("res://Scenes/Main.tscn")
		Global.scene_changed.connect(_on_scene_changed)
		
# Only after scene has been changed do we free our resource
func _on_scene_changed():
	queue_free()
