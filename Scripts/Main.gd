extends Node2D

# Node refs
@onready var land = $Map/Land
@onready var spawned_pickups = $SpawnedPickups

var rng = RandomNumberGenerator.new()

func _ready():
	# Spawn between 5 and 10 pickups
	var spawn_pickup_amount = rng.randf_range(5, 10)
	spawn_pickups(spawn_pickup_amount)
	

# Valid pickup spawn location
func is_valid_spawn_location(layer, position):
	var cell_coords = Vector2i(position.x, position.y)
	
	## Check if there's a tile on the water, foliage, or exterior layers
	if $Map/Fences.get_cell_source_id(cell_coords) != -1 ||\
	$Map/Buildings.get_cell_source_id(cell_coords) != -1 ||\
	$Map/Foliage.get_cell_source_id(cell_coords) != -1 ||\
	$Map/Signs.get_cell_source_id(cell_coords) != -1 ||\
	$Map/Decorations.get_cell_source_id(cell_coords) != -1 ||\
	$Map/Trees1.get_cell_source_id(cell_coords) != -1 ||\
	$Map/Trees2.get_cell_source_id(cell_coords) != -1 ||\
	$Map/Trees3.get_cell_source_id(cell_coords) != -1 ||\
	$Map/Trees4.get_cell_source_id(cell_coords) != -1:
		return false
		
	# Check if there's a tile on the land layers
	if land.get_cell_source_id(cell_coords) != -1:
		return true
		
	return false
	
func spawn_pickups(amount):
	var spawned = 0
	var attempts = 0
	var max_attempts = 1000 # Arbitrary number, adjust as needed.
	
	while spawned < amount and attempts < max_attempts:
		attempts += 1
		# Randomly choose a location on the first or second layer
		var random_position = Vector2(randi() % land.get_used_rect().size.x, randi() % land.get_used_rect().size.y)
		# Spawn it underneath SpawnedPickups node
		if is_valid_spawn_location(land, random_position):
			var pickup_instance = Global.pickups_scene.instantiate()
			pickup_instance.item = Global.Pickups.values()[randi() % 3]
			pickup_instance.position = land.map_to_local(random_position)
			spawned_pickups.add_child(pickup_instance)
			spawned += 1
