extends CharacterBody2D

const PLAYER_PROJECTILE_SCENE = preload("res://scenes/objects/playerProjectile.tscn")
const STAB_SOUND = preload("res://assets/sounds/stab.wav")
const THROW_SOUND = preload("res://assets/sounds/throw.wav")
const PICKUP_SOUND = preload("res://assets/sounds/pickup.wav")
const WIN_PICKUP_SOUND = preload("res://assets/sounds/winPickup.wav")
const HURT_SOUND = preload("res://assets/sounds/playerHurt.wav")
const DEATH_SOUND = preload("res://assets/sounds/death.wav")
const UNLOCK_SOUND = preload("res://assets/sounds/unlock.wav")

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
var zombie_arm_count: int = 10:
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
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var is_dead: bool = false
var has_won: bool = false
var is_attacking: bool = false
var last_facing_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	audio_player.play()
	if PlayerState.initialized:
		health = clampf(PlayerState.health, 0.0, maxHealth)
		key_count = PlayerState.key_count
		zombie_arm_count = PlayerState.zombie_arm_count
	elif preload("res://scripts/map.gd").debug_all_chest_rooms:
		key_count = 10
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
	if Input.is_action_just_pressed("ranged_attack") && zombie_arm_count > 0:
		shoot_projectile()
	if is_attacking:
		velocity = Vector2.ZERO
		return

	if Input.is_action_just_pressed("attack"):
		start_attack()
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = input_vector * speed
	move_and_slide()
	_check_locked_tiles()
	
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

func shoot_projectile() -> void:
	if is_dead or zombie_arm_count <= 0:
		return
	var projectile := PLAYER_PROJECTILE_SCENE.instantiate() as Area2D
	projectile.direction = last_facing_direction
	projectile.position = get_parent().to_local(global_position + last_facing_direction * 12.0)
	get_parent().add_child(projectile)
	zombie_arm_count -= 1
	play_sound(THROW_SOUND)

func _check_locked_tiles() -> void:
	if key_count <= 0:
		return
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var layer := collision.get_collider() as TileMapLayer
		if layer == null:
			continue
		# A physics body can contain multiple tiles, so its RID is not a cell ID.
		# Move slightly inside the surface to resolve the tile at the contact point.
		var contact_point := collision.get_position() - collision.get_normal() * 0.5
		var cell := layer.local_to_map(layer.to_local(contact_point))
		if layer.get_cell_atlas_coords(cell) != Vector2i(2, 2):
			continue
		key_count -= 1
		play_sound(UNLOCK_SOUND)
		for locked_cell in layer.get_used_cells():
			if layer.get_cell_atlas_coords(locked_cell) in [Vector2i(2, 2), Vector2i(3, 2)]:
				layer.set_cell(locked_cell, layer.get_cell_source_id(locked_cell), Vector2i(2, 0))
		return

func start_attack() -> void:
	if is_dead:
		return
	is_attacking = true
	play_sound(STAB_SOUND)
	
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
	await get_tree().create_timer(attack_duration, false).timeout
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

func play_sound(sound: AudioStream) -> void:
	# One non-positional player mixes overlapping effects without cutting them off.
	var playback := audio_player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if playback != null:
		playback.play_stream(sound)

func play_pickup_sound() -> void:
	play_sound(PICKUP_SOUND)

func win() -> void:
	if is_dead or has_won:
		return
	has_won = true
	play_sound(WIN_PICKUP_SOUND)
	won.emit()
	await get_tree().create_timer(10.0, false).timeout
	PlayerState.reset()
	preload("res://scripts/map.gd").reset_map()
	get_tree().reload_current_scene()

func take_damage(amount: float) -> void:
	if is_dead or has_won or iframes > 0.0 or is_queued_for_deletion() or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	play_sound(HURT_SOUND)
	health_changed.emit(health)
	iframes = max_iframes
	animated_sprite.visible = iframes <= 0.0
	if health <= 0.0:
		die()

func die() -> void:
	if is_dead or has_won:
		return
	is_dead = true
	play_sound(DEATH_SOUND)
	velocity = Vector2.ZERO
	end_attack()
	animated_sprite.stop()
	set_process(false)
	set_physics_process(false)
	sword_area.set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
	died.emit()

	await get_tree().create_timer(5.0, false).timeout
	PlayerState.reset()
	preload("res://scripts/map.gd").reset_map()
	get_tree().reload_current_scene()
