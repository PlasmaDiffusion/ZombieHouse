extends CharacterBody2D

@export var speed: float = 100.0
@export var attack_duration: float = 0.25 # Adjust how long the attack lasts in seconds
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_sprite: AnimatedSprite2D = $SwordAnimatedSprite2D

var is_attacking: bool = false
var last_facing_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
    if sword_sprite:
        sword_sprite.visible = false
        sword_sprite.stop()

func _physics_process(delta: float) -> void:
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
    sword_sprite.rotation = 0.0
    
    if dir.x > 0:
        sword_sprite.position = Vector2(10, 4)
        sword_sprite.rotation = 0.0
        sword_sprite.flip_h = true
    elif dir.x < 0:
        sword_sprite.position = Vector2(-10, 4)
        sword_sprite.rotation = 0.0
        sword_sprite.flip_h = false
    elif dir.y < 0:
        sword_sprite.position = Vector2(0, -10)
        sword_sprite.rotation = deg_to_rad(90)
        sword_sprite.flip_v = false
    elif dir.y > 0:
        sword_sprite.position = Vector2(0, 10)
        sword_sprite.rotation = deg_to_rad(-90)
        sword_sprite.flip_v = true