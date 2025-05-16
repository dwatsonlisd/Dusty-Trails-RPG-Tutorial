extends ColorRect

# Node refs
@onready var value = $Value
@onready var player = $"../.."

# Return level
func update_level_ui(level):
	# Return something like 0
	value.text = str(level)
