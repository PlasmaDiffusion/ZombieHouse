extends Control

# Connected rooms with junctions, side branches, and alternate routes.
const ROOM_PATTERNS = [
	["oxxx-", "xx-xx", "-xxxx", "--x-x"],
	["ox-xx", "-xxx-", "xx-xx", "-xxx-"],
	["oxxxx", "xx-x-", "-xxx-", "xx-xx"],
	["ox-xx", "xxxxx", "x-x-x", "--xxx"],
	["oxxx-", "x-xxx", "xxx-x", "-xxxx"],
	["oxx-x", "-xxxx", "xx-x-", "-xxxx"],
	["ox-xx", "xxxx-", "x-xxx", "xxx-x"],
	["oxxxx", "-xx-x", "xx-xx", "-xxx-"],
]
const CELL_SIZE = 5
const ROOM_COLOR = Color(0.0, 0.25, 1.0)
const CURRENT_COLOR = Color(0.4, 0.8, 1.0)
const WARP_DIRECTIONS = {
	"WarpL": Vector2i.LEFT,
	"WarpR": Vector2i.RIGHT,
	"WarpU": Vector2i.UP,
	"WarpD": Vector2i.DOWN,
}

# This run's map survives every room scene change.
static var room_layout: Array[String] = []
static var start_room := Vector2i.ZERO
static var current_room := Vector2i.ZERO
static var map_revision: int = 0
var drawn_room := Vector2i(-1, -1)
var drawn_revision: int = -1

static func ensure_map() -> void:
	if room_layout.is_empty():
		reset_map()

static func has_room(cell: Vector2i) -> bool:
	ensure_map()
	if cell.y < 0 or cell.y >= room_layout.size():
		return false
	var row: String = room_layout[cell.y]
	return cell.x >= 0 and cell.x < row.length() and row[cell.x] in ["x", "o", "!", "c"]

static func is_chest_room() -> bool:
	return has_room(current_room) and room_layout[current_room.y][current_room.x] == "c"

static func is_win_room() -> bool:
	if not has_room(current_room):
		return false
	return room_layout[current_room.y][current_room.x] == "!"

static func can_move(direction: Vector2i) -> bool:
	ensure_map()
	return has_room(current_room + direction)

static func reset_map(pattern_index: int = -1) -> void:
	var index := pattern_index if pattern_index >= 0 else randi_range(0, ROOM_PATTERNS.size() - 1)
	room_layout.assign(ROOM_PATTERNS[index])
	# Mirrors add variety while preserving each pattern's routes.
	if randf() < 0.5:
		for y in range(room_layout.size()):
			room_layout[y] = room_layout[y].reverse()
	if randf() < 0.5:
		room_layout.reverse()
	for y in range(room_layout.size()):
		var x := room_layout[y].find("o")
		if x >= 0:
			start_room = Vector2i(x, y)
			break
	current_room = start_room
	_place_win_room()
	_place_chest_rooms()
	map_revision += 1

static func _place_chest_rooms() -> void:
	var candidates: Array[Vector2i] = []
	for y in range(room_layout.size()):
		for x in range(room_layout[y].length()):
			if room_layout[y][x] == "x":
				candidates.append(Vector2i(x, y))
	candidates.shuffle()
	for index in range(randi_range(0, mini(4, candidates.size()))):
		var cell := candidates[index]
		var row := room_layout[cell.y]
		room_layout[cell.y] = row.substr(0, cell.x) + "c" + row.substr(cell.x + 1)

static func _place_win_room() -> void:
	# Breadth-first search gives shortest-path distances on an unweighted grid.
	var queue: Array[Vector2i] = [start_room]
	var distances := {start_room: 0}
	var farthest: Array[Vector2i] = [start_room]
	var max_distance: int = 0
	var head: int = 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for direction in WARP_DIRECTIONS.values():
			var neighbour: Vector2i = cell + direction
			if not has_room(neighbour) or distances.has(neighbour):
				continue
			var distance: int = distances[cell] + 1
			distances[neighbour] = distance
			queue.append(neighbour)
			if distance > max_distance:
				max_distance = distance
				farthest.clear()
			if distance == max_distance:
				farthest.append(neighbour)
	var win_room: Vector2i = farthest.pick_random()
	var row: String = room_layout[win_room.y]
	room_layout[win_room.y] = row.substr(0, win_room.x) + "!" + row.substr(win_room.x + 1)

func _ready() -> void:
	ensure_map()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if drawn_room != current_room or drawn_revision != map_revision:
		drawn_room = current_room
		drawn_revision = map_revision
		queue_redraw()

func _draw() -> void:
	for y in range(room_layout.size()):
		for x in range(room_layout[y].length()):
			var cell := Vector2i(x, y)
			if has_room(cell):
				var color := CURRENT_COLOR if cell == current_room else ROOM_COLOR
				draw_rect(Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE)), color)
