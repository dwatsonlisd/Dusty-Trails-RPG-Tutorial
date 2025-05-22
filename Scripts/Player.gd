# Player

extends CharacterBody2D

# Node references
@onready var animation_sprite = $AnimatedSprite2D
@onready var health_bar = $UI/HealthBar
@onready var stamina_bar = $UI/StaminaBar
@onready var ammo_amount = $UI/AmmoAmount
@onready var stamina_amount = $UI/StaminaAmount
@onready var health_amount = $UI/HealthAmount
@onready var xp_amount = $UI/XP
@onready var level_amount = $UI/Level
@onready var animation_player = $AnimationPlayer
@onready var level_popup = $UI/LevelUpPopup
@onready var ray_cast = $RayCast2D

# Player states
# Player movement speed
@export var speed = 50
var is_attacking = false
# Direction & Animation Variables
var new_direction = Vector2(0,1)
var animation

var chestFull = true

# UI variables
@export var health = 100
@export var max_health = 100
@export var regen_health = 1
@export var stamina = 100
@export var max_stamina = 100
@export var regen_stamina = 5


# Custom signals
signal health_updated
signal stamina_updated
signal ammo_pickups_updated
signal health_pickups_updated
signal stamina_pickups_updated
signal xp_updated
signal level_updated
signal xp_requirements_updated

# Pickups

var ammo_pickup = 5
var health_pickup = 0
var stamina_pickup = 0

# Bullet and attack variables
var bullet_damage = 30
var bullet_reload_time = 1000
var bullet_fired_time = 0.5

# XP and levelling
var xp = 0
var level = 1
var xp_requirements = 100

# Paused state
var paused

# UI nodes
@onready var pause_screen = $UI/PauseScreen

func _ready():
	# Connect the signals to the UI components' functions
	health_updated.connect(health_bar.update_health_ui)
	stamina_updated.connect(stamina_bar.update_stamina_ui)
	ammo_pickups_updated.connect(ammo_amount.update_ammo_pickup_ui)
	health_pickups_updated.connect(health_amount.update_health_pickup_ui)
	stamina_pickups_updated.connect(stamina_amount.update_stamina_pickup_ui)
	xp_updated.connect(xp_amount.update_xp_ui)
	xp_requirements_updated.connect(xp_amount.update_xp_requirements_ui)
	level_updated.connect(level_amount.update_level_ui)
	
	
	# Reset color
	animation_sprite.modulate = Color(1,1,1,1)
	
	# Hide mouse on load
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


# Movement and Animations
func _physics_process(delta):
	# Get player input (left, right, up/down)
	var direction: Vector2
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# If input is digital, normalize it for diagonal movement
	if abs(direction.x) == 1 and abs(direction.y) == 1:
		direction = direction.normalized()
	
	# Sprinting
	if Input.is_action_pressed("ui_sprint"):
		if stamina >= 25:
			speed = 100
			stamina = stamina - 5
			stamina_updated.emit(stamina, max_stamina)
	elif Input.is_action_just_released("ui_sprint"):
		speed = 50
	
	# Apply movement if the player is not attacking
	var movement = speed * direction * delta
	
	if is_attacking == false:
		# Moves our player around, whilst enforcing collisions so that thay come to a stop when colliding with another object.
		move_and_collide(movement)
	
		# play animations
		player_animations(direction)
	
	if !Input.is_anything_pressed():
		if is_attacking == false:
			animation = "idle_" + returned_direction(new_direction)
	if direction != Vector2.ZERO:
		ray_cast.target_position = direction.normalized() * 50


func _input(event):
	# Input event for attacking
	if event.is_action_pressed("ui_attack"):
		# checks the current time as the amount of time passed in milliseconds since the engine started
		var now = Time.get_ticks_msec()
		# attacking/shooting animation
		if now >= bullet_fired_time and ammo_pickup > 0:
			# shooting animation
			is_attacking = true
			animation = "attack_" + returned_direction(new_direction)
			animation_sprite.play(animation)
			# bullet fired time to current time
			bullet_fired_time = now + bullet_reload_time
			# reduce and signal ammo change
			ammo_pickup = ammo_pickup - 1
			ammo_pickups_updated.emit(ammo_pickup)
			
	#using health consumables
	elif event.is_action_pressed("ui_consume_health"):
		if health > 0 && health_pickup > 0:
			health_pickup = health_pickup - 1
			health = min(health + 50, max_health)
			health_updated.emit(health, max_health)
			health_pickups_updated.emit(health_pickup)
	elif event.is_action_pressed("ui_consume_stamina"):
		if stamina > 0 && stamina_pickup > 0:
			stamina_pickup = stamina_pickup - 1
			stamina = min(stamina +50, max_stamina)
			stamina_updated.emit(stamina, max_stamina)
			stamina_pickups_updated.emit(stamina_pickup)
	# Interact with world
	elif event.is_action_pressed("ui_interact"):
		var target = ray_cast.get_collider()
		if target != null:
			if target.is_in_group("NPC"):
				# Talk to NPC
				target.dialog()
				return
			# Go to sleep
			if target.name == "Bed":
				# Play sleep screen
				animation_player.play("sleeping")
				health = max_health
				stamina = max_stamina
				health_updated.emit(health, max_health)
				stamina_updated.emit(stamina, max_stamina)
				return
			if target.name == "Chest":
				if chestFull == true:
					ammo_pickup = ammo_pickup + 10
					ammo_pickups_updated.emit(ammo_pickup)
					print("ammo val:" + str(ammo_pickup))
					chestFull = false
				else:
					return
				return
	# Show pause menu
	if !pause_screen.visible:
		if event.is_action_pressed("ui_pause"):
			# Pause game
			get_tree().paused = true
			# Show pause screen popup
			pause_screen.visible = true
			# Stops movement processing
			set_physics_process(false)
			# Set pauses state to be true
			paused = true
			
			# If the player is dead, go back to the main menu screen
			if health <= 0:
				get_node("/root/%s" % Global.current_scene_name).queue_free()
				Global.change_scene("res://Scenes/MainScene.tscn")
				get_tree().paused = false
				return
	
# Animations
func player_animations(direction : Vector2):
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


func _on_animated_sprite_2d_animation_finished():
	is_attacking = false
	
	# Instantiate Bullet
	if animation_sprite.animation.begins_with("attack_"):
		var bullet = Global.bullet_scene.instantiate()
		bullet.damage = bullet_damage
		bullet.direction = new_direction.normalized()
		# place it 4-5 pixels away in front of the player to simulate it coming from the gun's barrel
		bullet.position = position + new_direction.normalized() * 20
		get_tree().root.get_node("%s" % Global.current_scene_name).add_child(bullet)

# UI
func _process(delta):
	# Calculate health
	var updated_health = min(health + regen_health * delta, max_health)
	# Regenerate health
	if updated_health != health:
		health = updated_health
		health_updated.emit(health, max_health)
	# Calculate stamina
	var updated_stamina = min(stamina + regen_stamina * delta, max_stamina)
	# Regenerate stamina
	if updated_stamina != stamina:
		stamina = updated_stamina
		stamina_updated.emit(stamina, max_stamina)

# ------ Consumalbes ------
func add_pickup(item):
	if item == Global.Pickups.AMMO:
		ammo_pickup = ammo_pickup + 3 # + 3 bullets
		ammo_pickups_updated.emit(ammo_pickup)
		print("ammo val:" + str(ammo_pickup))
	if item == Global.Pickups.HEALTH:
		health_pickup = health_pickup + 1 # + 1 health drink
		health_pickups_updated.emit(health_pickup)
		print("health val:" + str(health_pickup))
	if item == Global.Pickups.STAMINA:
		stamina_pickup = stamina_pickup + 1 # + 1 stamina drink
		stamina_pickups_updated.emit(stamina_pickup)
		print("stamina val:" + str(stamina_pickup))
	update_xp(5)
		
# -------- Damage & Death ----------
# Does damage to our player
func hit(damage):
	health -= damage
	health_updated.emit(health, max_health)
	if health > 0:
		# Damage
		animation_player.play("damage")
		health_updated.emit(health)
	else:
		# Death
		set_process(false)
		get_tree().paused = true
		paused = true
		animation_player.play("game_over")


func _on_animation_player_animation_finished(anim_name):
	# Reset color
	animation_sprite.modulate = Color(1,1,1,1)

# --------- Level & XP -----------
# Updates player XP
func update_xp(value):
	xp += value
	# Check if player leveled up after reaching xp requirements
	if xp >= xp_requirements:
		# Allows input
		set_process_input(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# Pause the game
		get_tree().paused = true
		# Make popup visible
		level_popup.visible = true
		# Reset XP to 0
		xp = 0
		# Increase the level and xp requirements
		level += 1
		xp_requirements *= 2
		
		# Update max health and stamina
		max_health += 10
		max_stamina += 10
		
		# Ammo and pickups
		ammo_pickup += 10
		health_pickup += 5
		stamina_pickup += 3
		
		# Update signals for label values
		health_updated.emit(health, max_health)
		stamina_updated.emit(stamina, max_stamina)
		ammo_pickups_updated.emit(ammo_pickup)
		health_pickups_updated.emit(health_pickup)
		stamina_pickups_updated.emit(stamina_pickup)
		xp_updated.emit(xp)
		level_updated.emit(level)
		
		# Reflect changees in label
		$UI/LevelUpPopup/Message/Rewards/LevelGained.text = "LVL: " + str(level)
		$UI/LevelUpPopup/Message/Rewards/HealthIncreaseGained.text = "+ MAX HP: " + str(max_health)
		$UI/LevelUpPopup/Message/Rewards/StaminaIncreaseGained.text = "+ MAX SP: " + str(max_stamina)
		$UI/LevelUpPopup/Message/Rewards/HealthPickupsGained.text = "+ HEALTH: 5"
		$UI/LevelUpPopup/Message/Rewards/StaminaPickupsGained.text = "+ STAMINA: 3"
		$UI/LevelUpPopup/Message/Rewards/AmmoPickupsGained.text = "+ AMMO: 10"
		
	# Emit signals
	xp_requirements_updated.emit(xp_requirements)
	xp_updated.emit(xp)
	level_updated.emit(level)

# Close popup
func _on_confirm_pressed():
	level_popup.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_resume_pressed():
	# Hide pause menu
	pause_screen.visible = false
	# Set paused state to be false
	get_tree().paused = false
	paused = false
	# Accept movement and input
	set_process_input(true)
	set_physics_process(true)


func _on_quit_pressed():
	Global.change_scene("res://Scenes/MainScene.tscn")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
