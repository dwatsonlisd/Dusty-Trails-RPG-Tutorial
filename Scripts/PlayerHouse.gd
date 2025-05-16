# Player house

extends Node2D

# Node refs
@onready var exterior = $Exterior
@onready var interior = $Interior
@onready var furnishings = $Furnishings

func _on_trigger_area_body_entered(body):
	if body.is_in_group("player"):
		interior.show()
		furnishings.show()
		exterior.hide()
	# Prevent enemies from entering
	if body.is_in_group("enemy"):
		body.direction = -body.direction
		body.timer = 16

func _on_trigger_area_body_exited(body):
	if body.is_in_group("player"):
		interior.hide()
		furnishings.hide()
		exterior.show()
