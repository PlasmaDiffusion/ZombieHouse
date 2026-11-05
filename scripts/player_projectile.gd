extends Area2D

@export var damage: float = 3.0
@export var speed: float = 150.0
@export var rotation_speed_degrees: float = 90.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var lifetime_timer := Timer.new()
	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(queue_free)
	add_child(lifetime_timer)
	lifetime_timer.start()

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	rotation_degrees += 90 #Don't do rotation_speed_degrees * delta to make it look snappy like a retro game

func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion() or body.is_queued_for_deletion():
		return
	if body is Enemy:
		body.take_damage(self)
		queue_free()
