extends CharacterBody2D

# Node refs
@onready var player = get_tree().root.get_node("Main/Player")
@onready var animation_sprite = $AnimatedSprite2D

# Enemy stats
@export var speed = 50
var direction : Vector2 # Current direction
var new_direction = Vector2(0,1) # Next direction
var animation
var is_attacking = false

# Direction timer
var rng = RandomNumberGenerator.new()
var timer = 0

func _ready():
	rng.randomize()
	
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
	
# Animation Direction
func returned_direction(direction : Vector2):
	# Normalizes the direction vector
	var normalized_direction = direction.normalized()
	var default_return = "side"
	
	if normalized_direction.y > 0:
		return "down"
	elif normalized_direction.y < 0:
		return "up"
	elif normalized_direction.x > 0:
		# (right)
		$AnimatedSprite2D.flip_h = false
		return "side"
	elif normalized_direction.x < 0:
		# flipt the animation for reusability (left)
		$AnimatedSprite2D.flip_h = true
		return "side"
	
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
		
