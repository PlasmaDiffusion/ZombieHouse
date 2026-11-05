class_name Enemy
extends CharacterBody2D

const HURT_SOUND = preload("res://assets/sounds/enemyHurt.wav")

@export var speed: float = 60.0
@export var direction: Vector2 = Vector2.RIGHT # Set to Vector2.RIGHT/LEFT or Vector2.UP/DOWN in the Inspector

@export var min_x: float = 0.0
@export var max_x: float = 250.0
@export var min_y: float = 0.0
@export var max_y: float = 250.0

@export var damage: float = 1.0
@export var health: float = 2.0
@export var canAutomaticallyMove: bool = true
@export var canKill: bool = true
# Invincibility duration in physics frames.
@export var max_iframes: float = 10.0
var iframes: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if (canKill):
		add_to_group("enemies")
	set_collision_mask_value(1, true)

func _process(_delta: float) -> void:
	# Blink every rendered frame while invincible.
	if iframes > 0.0:
		animated_sprite.visible = not animated_sprite.visible
	else:
		animated_sprite.visible = true

func _physics_process(delta: float) -> void:
	iframes = maxf(0.0, iframes - 1.0)

	if canAutomaticallyMove:
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
	_reverse_on_tile_collision()
	_check_player_contact()
	
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

func take_damage(weapon: Node) -> void:
	if iframes > 0.0 or is_queued_for_deletion() or !canKill:
		return
	if not is_instance_valid(weapon):
		return
	# Both sword and zombie arm weapons provide a numeric damage property.
	var weapon_damage: Variant = weapon.get("damage")
	if not (weapon_damage is float or weapon_damage is int):
		return
	var amount: float = float(weapon_damage)
	if amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	# Play on the player so the effect survives this enemy's death.
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("play_sound"):
		player.play_sound(HURT_SOUND)
	iframes = max_iframes
	animated_sprite.visible = iframes <= 0.0
	if health <= 0.0:
		queue_free()

func deal_damage(player: CharacterBody2D) -> void:
	if not is_queued_for_deletion() and player.has_method("take_damage"):
		player.take_damage(damage)

func _check_player_contact() -> void:
	if collision_shape.disabled or collision_shape.shape == null:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	# Include touching bodies, which move_and_slide keeps just outside the shape.
	query.margin = 0.1
	query.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 256):
		var body = hit.collider
		if body is CharacterBody2D and (body.is_in_group("player") or body.name == &"Player"):
			deal_damage(body)

func _reverse_on_tile_collision() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if not (collider is TileMapLayer or (collider != null and collider.is_class("TileMap"))):
			continue
		var body_layer := PhysicsServer2D.body_get_collision_layer(collision.get_collider_rid())
		if (body_layer & 1) != 0 and direction.dot(collision.get_normal()) < 0.0:
			direction = -direction
			velocity = direction * speed
			break
