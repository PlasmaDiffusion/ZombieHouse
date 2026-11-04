extends Node2D

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

	for cell in room_border.get_used_cells():
		if room_border.get_cell_atlas_coords(cell) == Vector2i(1, 2):
			room_border.set_cell(
				cell,
				room_border.get_cell_source_id(cell),
				Vector2i(0, 2),
				room_border.get_cell_alternative_tile(cell)
			)
	room_cleared = true
	set_process(false)
