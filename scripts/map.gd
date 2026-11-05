extends Control

const ROOM_LAYOUT = [
	"xxxx-",
	"x--xx",
	"xox-!",
	"--x--",
]
const START_ROOM = Vector2i(1, 2)
const CELL_SIZE = 5
const ROOM_COLOR = Color(0.0, 0.25, 1.0)
const CURRENT_COLOR = Color(0.4, 0.8, 1.0)
const WARP_DIRECTIONS = {
	"WarpL": Vector2i.LEFT,
	"WarpR": Vector2i.RIGHT,
	"WarpU": Vector2i.UP,
	"WarpD": Vector2i.DOWN,
}

# Static state survives room scene changes without an autoload.
static var current_room: Vector2i = START_ROOM
var drawn_room := Vector2i(-1, -1)

static func has_room(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= ROOM_LAYOUT.size():
		return false
	var row: String = ROOM_LAYOUT[cell.y]
	return cell.x >= 0 and cell.x < row.length() and row[cell.x] in ["x", "o", "!"]

static func is_win_room() -> bool:
	if not has_room(current_room):
		return false
	return ROOM_LAYOUT[current_room.y][current_room.x] == "!"

static func can_move(direction: Vector2i) -> bool:
	return has_room(current_room + direction)

static func reset_map() -> void:
	current_room = START_ROOM

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if drawn_room != current_room:
		drawn_room = current_room
		queue_redraw()

func _draw() -> void:
	for y in range(ROOM_LAYOUT.size()):
		for x in range(ROOM_LAYOUT[y].length()):
			var cell := Vector2i(x, y)
			if has_room(cell):
				var color := CURRENT_COLOR if cell == current_room else ROOM_COLOR
				draw_rect(Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE)), color)
