# Enemy

extends CharacterBody2D

# Node refs
@onready var player = get_tree().root.get_node("%s/Player" % Global.current_scene_name)
@onready var animation_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var timer_node = $Timer
@onready var ray_cast = $RayCast2D

# Enemy stats
@export var speed = 50
var direction : Vector2 # Current direction
var new_direction = Vector2(0,1) # Next direction
var animation
var is_attacking = false
var health = 100
var max_health = 100
var health_regen = 1

# Bullet & attack variables
var bullet_damage = 30
var bullet_reload_time = 1000
var bullet_fired_time = 0.5

# Direction timer
var rng = RandomNumberGenerator.new()
var timer = 0

# Custom signals
signal death

func _ready():
	rng.randomize()
	# Reset color
	animation_sprite.modulate = Color(1,1,1,1)

# ----------- Damage & Health ----------

func _process(delta):
	# Regenerates our enemy's health
	health = min(health + health_regen * delta, max_health)
	# Get the collider of the racast ray
	var target = ray_cast.get_collider()
	if target != null:
		# If we are colliding with the player and the player isn't dead
		if target.is_in_group("player"):
			# Shooting animation
			is_attacking = true
			animation = "attack_" + returned_direction(new_direction)
			animation_sprite.play(animation)

# Will damage the enemy when hit
func hit(damage):
	health -= damage
	if health > 0:
		# Damage
		animation_player.play("damage")
		direction = Vector2.ZERO
	else:
		# Death
		# Stop movement
		timer_node.stop()
		direction = Vector2.ZERO
		# Stop health regeneration
		set_process(false)
		# Trigger animation finished signal
		is_attacking = true
		# Finally, we play the death animation and emit the signal
		animation_sprite.play("death")
		player.update_xp(70)
		death.emit()
		
		# Drop loot randomly at a 90% chance
		if rng.randf() < 0.9:
			var pickup = Global.pickups_scene.instantiate()
			pickup.item = rng.randi() % 3 # we have 3 pickups in our enum
		
			get_tree().root.get_node("%s/PickupSpawner/SpawnedPickups" % Global.current_scene_name).call_deferred("add_child", pickup)
			pickup.position = position
	
# Bullet & Removal
func _on_animated_sprite_2d_animation_finished():
	if animation_sprite.animation == "death":
		get_tree().queue_delete(self)
	is_attacking = false
	# Instantiate Bullet
	if animation_sprite.animation.begins_with("attack_"):
		var bullet = Global.enemy_bullet_scene.instantiate()
		bullet.damage = bullet_damage
		bullet.direction = new_direction.normalized()
		
		# Place it 8 pixels away in front of the enemy to simulate it coming from the gun's barrel
		bullet.position = position + new_direction.normalized() * 8
		get_tree().root.get_node("%s" % Global.current_scene_name).add_child(bullet)
	
# ------- Movement & Direction -------
# Apply movement to the enemy
func _physics_process(delta):
	var movement = speed * direction * delta
	var collision = move_and_collide(movement)
	
	# If the enemy collides with other objects, turn around and re-randomize the timer countdown
	if collision != null and collision.get_collider().name != "Player":
		# Direction rotation
		direction = direction.rotated(rng.randf_range(PI/4, PI/2))
		# Random timer countdown range
		timer = rng.randf_range(2, 5)
	# If they collide with the player, trigger timer's timeout and chase/move towwards player
	else:
		timer = 0
	# Play animations only if the enemy is not attacking
	if !is_attacking:
		enemy_animations(direction)
	# Turn RayCast2D toward movement direction
	if direction != Vector2.ZERO:
		ray_cast.target_position = direction.normalized() * 50

func _on_timer_timeout():
	# Calculate the distance of the player's position relative to the enemy's position
	var player_distance = player.position - position
	# Turn towards player so it can attack if within radius
	if player_distance.length() <= 20:
		new_direction = player_distance.normalized()
	# Chase/move towards player to attack them
	elif player_distance.length() <= 100 and timer == 0:
		direction = player_distance.normalized()
	elif timer == 0:
		# Generate a random direction value
		var random_direction = rng.randf()
		# Obtain direction by rotating Vector2.DOWN by a random angle.
		if random_direction < 0.05:
			# Enemy stops
			direction = Vector2.ZERO
		elif random_direction < 0.1:
			# Enemy moves
			direction = Vector2.DOWN.rotated(rng.randf() * 2 * PI)
		sync_new_direction()
	
# Animation Direction
func returned_direction(direction : Vector2):
	# Normalizes the direction vector
	var normalized_direction = direction.normalized()
	var default_return = "side"
	if abs(normalized_direction.x) > abs(normalized_direction.y):
		if normalized_direction.x > 0:
			# (right)
			$AnimatedSprite2D.flip_h = false
			return "side"
		else:
			# flip the animation for reusability (left)
			$AnimatedSprite2D.flip_h = true
			return "side"
	elif normalized_direction.y > 0:
		return "down"
	elif normalized_direction.y < 0:
		return "up"
	
	#default value is empty
	return default_return

# Animations
func enemy_animations(direction : Vector2):
	# Vector.ZERO is the shorthand for writing Vector2(0,0).
	if direction != Vector2.ZERO:
		# update our direction with the new direction
		new_direction = direction
		# play walk animation because we are moving
		animation = "walk_" + returned_direction(new_direction)
		animation_sprite.play(animation)
	else:
		# play idle animation because we are still
		animation = "idle_" + returned_direction(new_direction)
		animation_sprite.play(animation)
		
# Sync new_direction with actual movement direction; called when enemy moves or rotates
func sync_new_direction():
	if direction != Vector2.ZERO:
		new_direction = direction.normalized()


func _on_animation_player_animation_finished(anim_name):
	animation_sprite.modulate = Color(1,1,1,1)
