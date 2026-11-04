extends CharacterBody2D

@export var speed: float = 100.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Get movement vector from arrow keys or WASD (-1, 0, or 1)
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Apply velocity and move
	velocity = input_vector * speed
	move_and_slide()
	
	# Handle animations and facing direction
	if input_vector != Vector2.ZERO:
		# Choose animation based on direction
		if abs(input_vector.x) > abs(input_vector.y):
			animated_sprite.play("walk_right")
			# Flip sprite horizontally if walking left
			animated_sprite.flip_h = input_vector.x < 0
		elif input_vector.y > 0:
			animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_up")
	else:
		# Stop or switch to idle frame when not moving
		animated_sprite.stop()
		animated_sprite.frame = 0
