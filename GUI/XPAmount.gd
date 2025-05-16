# XP amount

extends ColorRect

# Node refs
@onready var value = $Value
@onready var value2 = $Value2
@onready var player = $"../.."

# Return XP
func update_xp_ui(xp):
	# Return something like 0
	value.text = str(xp)
	
# Retrun xp_requirements
func update_xp_requirements_ui(xp_requirements):
	# Return something like / 100
	value2.text = "/" + str(xp_requirements)
	
