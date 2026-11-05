extends Enemy

func _init() -> void:
	canAutomaticallyMove = false
	canKill = false

func _ready() -> void:
	super._ready()
	var lifetime_timer := Timer.new()
	lifetime_timer.wait_time = 25.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	add_child(lifetime_timer)
	lifetime_timer.start()

func _reverse_on_tile_collision() -> void:
	# Apply impact damage before queue_free makes deal_damage skip this shot.
	for index in range(get_slide_collision_count()):
		var body := get_slide_collision(index).get_collider()
		if body is CharacterBody2D and (body.is_in_group("player") or body.name == &"Player"):
			deal_damage(body)
			return
	if get_slide_collision_count() > 0:
		queue_free()

func deal_damage(player: CharacterBody2D) -> void:
	super.deal_damage(player)
	queue_free()
