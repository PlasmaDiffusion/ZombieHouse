extends CharacterBody2D

@export var speed: float = 60.0
@export var direction: Vector2 = Vector2.RIGHT # Set to Vector2.RIGHT/LEFT or Vector2.UP/DOWN in the Inspector

@export var min_x: float = 0.0
@export var max_x: float = 200.0
@export var min_y: float = 0.0
@export var max_y: float = 200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Check boundaries and automatically reverse direction
	if global_position.x >= max_x:
		direction = Vector2.LEFT
	elif global_position.x <= min_x:
		direction = Vector2.RIGHT
		
	if global_position.y >= max_y:
		direction = Vector2.UP
	elif global_position.y <= min_y:
		direction = Vector2.DOWN

	# Apply velocity and move automatically
	velocity = direction * speed
	move_and_slide()
	
	# Handle animations and facing direction based on current movement
	if abs(direction.x) > abs(direction.y):
		animated_sprite.play("walk_right") # Swap to "walk_side" if that's what your animation is named
		animated_sprite.flip_h = direction.x < 0
	elif direction.y > 0:
		animated_sprite.play("walk_down")
		animated_sprite.flip_h = false
	elif direction.y < 0:
		animated_sprite.play("walk_up")
		animated_sprite.flip_h = false
