extends CharacterBody2D

signal health_changed(current_health: float)
signal died
signal won
signal inventory_changed

var key_count: int = 0:
	set(value):
		key_count = value
		if is_node_ready():
			PlayerState.key_count = value
			inventory_changed.emit()
var zombie_arm_count: int = 0:
	set(value):
		zombie_arm_count = value
		if is_node_ready():
			PlayerState.zombie_arm_count = value
			inventory_changed.emit()

@export var health: float = 5.0:
	set(value):
		health = value
		if is_node_ready():
			PlayerState.health = value
@export var maxHealth: float = 5.0
# Invincibility duration in physics frames.
@export var max_iframes: float = 30.0
var iframes: float = 0.0

@export var speed: float = 100.0
@export var attack_duration: float = 0.25 # Adjust how long the attack lasts in seconds
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_area: Area2D = $SwordArea2D
@onready var sword_sprite: AnimatedSprite2D = $SwordArea2D/SwordAnimatedSprite2D

var is_dead: bool = false
var is_attacking: bool = false
var last_facing_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	if PlayerState.initialized:
		health = clampf(PlayerState.health, 0.0, maxHealth)
		key_count = PlayerState.key_count
		zombie_arm_count = PlayerState.zombie_arm_count
	# Seed from the first player's Inspector values; later scenes restore these.
	PlayerState.health = health
	PlayerState.key_count = key_count
	PlayerState.zombie_arm_count = zombie_arm_count
	PlayerState.initialized = true
	health_changed.emit(health)
	inventory_changed.emit()
	add_to_group("player")
	# Center the sword root on the sprite while preserving child alignment.
	var sword_origin := sword_sprite.position
	for child in sword_area.get_children():
		if child is Node2D:
			child.position -= sword_origin
	if sword_sprite:
		sword_sprite.visible = false
		sword_sprite.stop()

func _process(_delta: float) -> void:
	# Blink every rendered frame while invincible.
	if iframes > 0.0:
		animated_sprite.visible = not animated_sprite.visible
	else:
		animated_sprite.visible = true

func _physics_process(delta: float) -> void:
	iframes = maxf(0.0, iframes - 1.0)
	if is_attacking:
		velocity = Vector2.ZERO
		return

	if Input.is_action_just_pressed("attack"):
		start_attack()
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = input_vector * speed
	move_and_slide()
	
	if input_vector != Vector2.ZERO:
		if input_vector.x != 0:
			animated_sprite.play("walk_side")
			animated_sprite.flip_h = input_vector.x < 0
			last_facing_direction = Vector2(input_vector.x, 0)
		elif input_vector.y > 0:
			animated_sprite.play("walk_down")
			animated_sprite.flip_h = false
			last_facing_direction = Vector2.DOWN
		else:
			animated_sprite.play("walk_up")
			animated_sprite.flip_h = false
			last_facing_direction = Vector2.UP
	else:
		animated_sprite.stop()
		animated_sprite.frame = 0

func start_attack() -> void:
	if is_dead:
		return
	is_attacking = true
	
	if sword_sprite:
		sword_sprite.visible = true
		sword_sprite.play("stab")
	
	if abs(last_facing_direction.x) > abs(last_facing_direction.y):
		animated_sprite.play("attack_side")
		animated_sprite.flip_h = last_facing_direction.x > 0
		update_sword_transform(Vector2(last_facing_direction.x, 0))
	elif last_facing_direction.y > 0:
		animated_sprite.play("attack_down")
		animated_sprite.flip_h = false
		update_sword_transform(Vector2.DOWN)
	else:
		animated_sprite.play("attack_up")
		animated_sprite.flip_h = false
		update_sword_transform(Vector2.UP)
		
	# Wait for the attack duration to finish, then end the attack automatically
	await get_tree().create_timer(attack_duration).timeout
	end_attack()

func end_attack() -> void:
	is_attacking = false
	if sword_sprite:
		sword_sprite.visible = false
		sword_sprite.stop()

func update_sword_transform(dir: Vector2) -> void:
	if not sword_sprite:
		return
	
	sword_sprite.flip_h = false
	sword_sprite.flip_v = false
	sword_area.scale = Vector2.ONE
	sword_area.rotation = 0.0
	
	if dir.x > 0:
		sword_area.position = Vector2(10, 4)
		sword_area.rotation = 0.0
		sword_area.scale.x = -1.0
	elif dir.x < 0:
		sword_area.position = Vector2(-10, 4)
		sword_area.rotation = 0.0
		sword_sprite.flip_h = false
	elif dir.y < 0:
		sword_area.position = Vector2(0, -10)
		sword_area.rotation = deg_to_rad(90)
		sword_sprite.flip_v = false
	elif dir.y > 0:
		sword_area.position = Vector2(0, 10)
		sword_area.rotation = deg_to_rad(-90)
		sword_area.scale.y = -1.0

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = minf(maxHealth, health + amount)
	health_changed.emit(health)

func win() -> void:
	won.emit()

func take_damage(amount: float) -> void:
	if is_dead or iframes > 0.0 or is_queued_for_deletion() or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health)
	iframes = max_iframes
	animated_sprite.visible = iframes <= 0.0
	if health <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	end_attack()
	animated_sprite.stop()
	set_process(false)
	set_physics_process(false)
	sword_area.set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
	died.emit()

	await get_tree().create_timer(5.0).timeout
	PlayerState.reset()
	preload("res://scripts/map.gd").reset_map()
	get_tree().reload_current_scene()
