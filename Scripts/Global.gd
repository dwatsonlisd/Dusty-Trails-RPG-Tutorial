# Global

extends Node

# Scene resources
@onready var pickups_scene = preload("res://Scenes/Pickup.tscn")
@onready var enemy_scene = preload("res://Scenes/Enemy.tscn")
@onready var bullet_scene = preload("res://Scenes/Bullet.tscn")
@onready var enemy_bullet_scene = preload("res://Scenes/EnemyBullet.tscn")

# Pickups
enum Pickups { AMMO, STAMINA, HEALTH }

# Current scene
var current_scene_name

# Notifies scene change
signal scene_changed()

# Set current scene on load
func _ready():
	current_scene_name = get_tree().get_current_scene().name

# Change scene
func change_scene(scene_path):
	# Get the current scene
	current_scene_name = scene_path.get_file().get_basename()
	var current_scene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
	# Free it for the new scene
	current_scene.queue_free()
	# Change the scene
	var new_scene = load(scene_path).instantiate()
	get_tree().get_root().call_deferred("add_child", new_scene)
	get_tree().call_deferred("set_current_scene", new_scene)
	call_deferred("post_scene_change_initialization")
	
func post_scene_change_initialization():
	scene_changed.emit()
