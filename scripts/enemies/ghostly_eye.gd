extends Enemy

@export var projectile_scene: PackedScene = preload("res://scenes/objects/enemies/projectile.tscn")
@export var projectile_speed: float = 100.0

func _ready() -> void:
	super._ready()
	var shoot_timer := Timer.new()
	shoot_timer.wait_time = 3.0
	shoot_timer.timeout.connect(_shoot_projectiles)
	add_child(shoot_timer)
	shoot_timer.start()

func _shoot_projectiles() -> void:
	var volley: Array[Enemy] = []
	for shot_direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var projectile := projectile_scene.instantiate() as Enemy
		projectile.direction = shot_direction
		projectile.speed = projectile_speed
		projectile.velocity = shot_direction * projectile_speed
		projectile.add_collision_exception_with(self)
		# All four shots share an origin, so they must ignore each other.
		for other_projectile in volley:
			projectile.add_collision_exception_with(other_projectile)
			other_projectile.add_collision_exception_with(projectile)
		volley.append(projectile)
		projectile.position = position
		get_parent().add_child(projectile)
