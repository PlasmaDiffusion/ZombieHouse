extends Area2D

const GameMap = preload("res://scripts/map.gd")

@export_file("*.tscn") var destination_scene: String = "res://scenes/levels/level1.tscn"
@export var spawn_offset: float = 32.0

const ARRIVALS = {
	"WarpL": ["WarpR", Vector2.LEFT],
	"WarpR": ["WarpL", Vector2.RIGHT],
	"WarpU": ["WarpD", Vector2.UP],
	"WarpD": ["WarpU", Vector2.DOWN],
}

# Shared by every warp, including those in the newly loaded scene.
static var transition_pending: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if transition_pending or not body is CharacterBody2D:
		return
	if not (body.is_in_group("player") or String(body.name).to_lower() == "player"):
		return
	if body.get("is_dead") == true or not ARRIVALS.has(String(name)):
		return
	var direction: Vector2i = GameMap.WARP_DIRECTIONS[String(name)]
	if not GameMap.can_move(direction):
		return
	transition_pending = true
	# Scene changes must happen after physics finishes processing collisions.
	_change_scene.call_deferred()

func _change_scene() -> void:
	var tree := get_tree()
	var previous_room: Vector2i = GameMap.current_room
	GameMap.current_room += GameMap.WARP_DIRECTIONS[String(name)]
	var arrival: Array = ARRIVALS[String(name)]
	var on_loaded := _place_player.bind(tree, arrival[0], arrival[1] * spawn_offset)
	tree.scene_changed.connect(on_loaded, CONNECT_ONE_SHOT)
	var error := tree.change_scene_to_file(destination_scene)
	if error != OK:
		GameMap.current_room = previous_room
		tree.scene_changed.disconnect(on_loaded)
		transition_pending = false
		push_error("Could not load warp destination: %s" % destination_scene)

static func _place_player(tree: SceneTree, arrival_name: String, offset: Vector2) -> void:
	var scene := tree.current_scene
	var arrival := scene.find_child(arrival_name, true, false) as Node2D
	var player: CharacterBody2D = null
	for candidate in scene.find_children("*", "CharacterBody2D", true, false):
		if candidate.is_in_group("player") or String(candidate.name).to_lower() == "player":
			player = candidate
			break
	if arrival != null and player != null:
		player.global_position = arrival.global_position + offset
		player.velocity = Vector2.ZERO
	else:
		push_error("Warp destination needs a Player and a %s node." % arrival_name)
	transition_pending = false
