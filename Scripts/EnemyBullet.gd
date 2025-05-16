# Enemy bullet

extends Area2D

# Node refs
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
@onready var animated_sprite = $AnimatedSprite2D

var speed = 80
var direction : Vector2
var damage

# ---------- Bullet ---------
# Position
func _process(delta):
	position = position + speed * delta * direction


func _on_body_entered(body):
	# Ignore collision with the enemy
	if body.is_in_group("enemy"):
		return
	# Ignore collision with land (?)
	if body.name == "Map":
		if land:
			return
		if buildings or decorations or signs or foliage or fences or trees1 or trees2 or trees3 or trees4:
			animated_sprite.play("impact")
			
	if body.is_in_group("player"):
		body.hit(damage)

	# Stop the movement and explode
	direction = Vector2.ZERO
	animated_sprite.play("impact")

# Removes the bullet
func _on_animated_sprite_2d_animation_finished():
	if animated_sprite.animation == "impact":
		get_tree().queue_delete(self)

# Self destruct
func _on_timer_timeout():
	animated_sprite.play("impact")
