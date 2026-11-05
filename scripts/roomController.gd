extends Node2D

const GameMap = preload("res://scripts/map.gd")

# Assign in the Inspector, or name a descendant TileMapLayer RoomBorder.
@export var room_border: TileMapLayer

var room_cleared: bool = false

func _process(_delta: float) -> void:
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
