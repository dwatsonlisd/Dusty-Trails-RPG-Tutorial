# Enemy spawner

extends Node2D

# Node refs
@onready var spawned_enemies = $SpawnedEnemies
@onready var land = $"../Map/Land"
@onready var buildings = $"../Map/Buildings"
@onready var fences = $"../Map/Fences"
@onready var foliage = $"../Map/Foliage"
@onready var signs = $"../Map/Signs"
@onready var decorations = $"../Map/Decorations"
@onready var trees1 = $"../Map/Trees1"
@onready var trees2 = $"../Map/Trees2"
@onready var trees3 = $"../Map/Trees3"
@onready var trees4 = $"../Map/Trees4"

# Enemy stats
@export var max_enemies = 20
var enemy_count = 0
var rng = RandomNumberGenerator.new()

# --------- Spawning -----------
func spawn_enemy():
	var attempts = 0
	var max_attempts = 100 # Maximum number of attempts to find a valid location
	var spawned = false
	
	while not spawned and attempts < max_attempts:
		# Randomly select a position on the map
		var random_position = Vector2(randi() % land.get_used_rect().size.x, randi() % land.get_used_rect().size.y)
		# Check if the position is a valid spawn location
		if is_valid_spawn_location(land, random_position):
			var enemy = Global.enemy_scene.instantiate()
			enemy.position = land.map_to_local(random_position) + Vector2(16,16) / 2
			spawned_enemies.add_child(enemy)
			spawned = true
		else:
			attempts += 1
	if attempts == max_attempts:
		print("Warning: Could not find a valid spawn location after", max_attempts, "attempts.")
	
	

# Valid pickup spawn location
func is_valid_spawn_location(layer, position):
	var cell_coords = Vector2i(position.x, position.y)
	
	## Check if there's a tile on the water, foliage, or exterior layers
	if fences.get_cell_source_id(cell_coords) != -1 ||\
	buildings.get_cell_source_id(cell_coords) != -1 ||\
	foliage.get_cell_source_id(cell_coords) != -1 ||\
	signs.get_cell_source_id(cell_coords) != -1 ||\
	decorations.get_cell_source_id(cell_coords) != -1 ||\
	trees1.get_cell_source_id(cell_coords) != -1 ||\
	trees2.get_cell_source_id(cell_coords) != -1 ||\
	trees3.get_cell_source_id(cell_coords) != -1 ||\
	trees4.get_cell_source_id(cell_coords) != -1:
		return false
		
	# Check if there's a tile on the land layers
	if land.get_cell_source_id(cell_coords) != -1:
		return true
		
	return false


func _on_timer_timeout():
	if enemy_count < max_enemies:
		spawn_enemy()
		enemy_count = enemy_count + 1
