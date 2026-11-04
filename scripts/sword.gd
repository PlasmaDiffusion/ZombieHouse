extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player = get_parent()

func _physics_process(_delta: float) -> void:
	if not player.is_attacking or collision_shape.disabled or collision_shape.shape == null:
		return

	# Query the current transform so a new attack uses its new facing direction
	# immediately, without waiting for Area2D's cached overlaps to update.
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]

	var hits := get_world_2d().direct_space_state.intersect_shape(query, 256)
	for hit in hits:
		var body = hit.collider
		if body is CharacterBody2D and (body.is_in_group("enemies") or body.name == &"Enemy"):
			if not body.is_queued_for_deletion():
				body.queue_free()
