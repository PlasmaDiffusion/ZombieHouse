extends Node2D

const GameMap = preload("res://scripts/map.gd")
const ENEMY_SCENE = preload("res://scenes/objects/enemy.tscn")

# Assign in the Inspector, or name a descendant TileMapLayer RoomBorder.
@export var room_border: TileMapLayer

@export var enemy_spawn_safe_distance: float = 48.0

var placing_enemies: bool = true
var room_cleared: bool = false

func _ready() -> void:
	# Allow tile collision bodies and the warp arrival position to update first.
	await get_tree().physics_frame
	await get_tree().process_frame
	randomly_place_enemies()

func _process(_delta: float) -> void:
	if placing_enemies:
		return
	if room_cleared:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is CharacterBody2D and is_ancestor_of(enemy):
			return
	_open_room_border()

func _open_room_border() -> void:
	if not is_instance_valid(room_border):
		room_border = find_child("RoomBorder", true, false) as TileMapLayer
	if room_border == null:
		return

	var bounds := room_border.get_used_rect()
	for cell in room_border.get_used_cells():
		if room_border.get_cell_atlas_coords(cell) == Vector2i(1, 2):
			if not GameMap.can_move(_border_direction(cell, bounds)):
				continue
			room_border.set_cell(
				cell,
				room_border.get_cell_source_id(cell),
				Vector2i(0, 2),
				room_border.get_cell_alternative_tile(cell)
			)
	room_cleared = true
	set_process(false)

func _border_direction(cell: Vector2i, bounds: Rect2i) -> Vector2i:
	# Door tiles belong to the closest outside edge of the room.
	var distances := [
		cell.x - bounds.position.x,
		bounds.end.x - 1 - cell.x,
		cell.y - bounds.position.y,
		bounds.end.y - 1 - cell.y,
	]
	var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var closest := 0
	for index in range(1, distances.size()):
		if distances[index] < distances[closest]:
			closest = index
	return directions[closest]

func randomly_place_enemies() -> void:
	if not is_instance_valid(room_border):
		room_border = find_child("RoomBorder", true, false) as TileMapLayer
	if room_border == null or room_border.tile_set == null:
		placing_enemies = false
		push_warning("Cannot place enemies without RoomBorder and its TileSet.")
		return

	var cells := room_border.get_used_rect()
	var tile_size := Vector2(room_border.tile_set.tile_size)
	var start := room_border.map_to_local(cells.position) - tile_size * 0.5
	var area := Rect2(start, Vector2(cells.size) * tile_size)
	var safe_points: Array[Vector2] = []
	for body in find_children("*", "CharacterBody2D", true, false):
		if body.is_in_group("player"):
			safe_points.append(body.global_position)
	for warp_name in GameMap.WARP_DIRECTIONS:
		var warp := find_child(warp_name, true, false) as Area2D
		if warp != null:
			var inward := -Vector2(GameMap.WARP_DIRECTIONS[warp_name])
			safe_points.append(warp.global_position + inward * float(warp.get("spawn_offset")))

	var placed_positions: Array[Vector2] = []
	var space := get_world_2d().direct_space_state
	for index in range(randi_range(1, 4)):
		var enemy := ENEMY_SCENE.instantiate() as CharacterBody2D
		var shape := enemy.get_node("CollisionShape2D") as CollisionShape2D
		var placed := false
		for attempt in range(256):
			var point := room_border.to_global(Vector2(
				randf_range(area.position.x, area.end.x),
				randf_range(area.position.y, area.end.y)
			))
			if not _spawn_point_is_safe(point, safe_points, enemy_spawn_safe_distance):
				continue
			if not _spawn_point_is_safe(point, placed_positions, 24.0):
				continue
			var body_transform := global_transform * Transform2D(0.0, to_local(point))
			var shape_transform := body_transform * shape.transform
			# Keep the entire collision shape within the room's outer bounds.
			var fits := true
			var shape_rect := shape.shape.get_rect()
			for corner in [shape_rect.position, Vector2(shape_rect.end.x, shape_rect.position.y), shape_rect.end, Vector2(shape_rect.position.x, shape_rect.end.y)]:
				if not area.has_point(room_border.to_local(shape_transform * corner)):
					fits = false
					break
			if not fits:
				continue
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = shape.shape
			query.transform = shape_transform
			query.collision_mask = enemy.collision_mask
			query.collide_with_areas = false
			query.margin = 1.0
			if not space.intersect_shape(query, 1).is_empty():
				continue
			enemy.position = to_local(point)
			enemy.direction = Vector2([Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN].pick_random())
			add_child(enemy)
			placed_positions.append(point)
			placed = true
			break
		if not placed:
			enemy.free()
			push_warning("No safe spawn position found for an enemy after 256 attempts.")
	placing_enemies = false

func _spawn_point_is_safe(point: Vector2, avoid: Array[Vector2], distance: float) -> bool:
	for other in avoid:
		if point.distance_to(other) < distance:
			return false
	return true
