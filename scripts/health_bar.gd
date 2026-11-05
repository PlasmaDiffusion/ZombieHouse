extends Control

const UNIT_SIZE = 5.0
var health: float = 0.0
var max_health: float = 0.0

func set_health(current_health: float, maximum_health: float) -> void:
	max_health = maxf(0.0, maximum_health)
	health = clampf(current_health, 0.0, max_health)
	size = Vector2(max_health * UNIT_SIZE, UNIT_SIZE)
	queue_redraw()

func _draw() -> void:
	# Every health unit occupies 5 by 5 pixels; missing health stays red.
	draw_rect(Rect2(Vector2.ZERO, Vector2(max_health * UNIT_SIZE, UNIT_SIZE)), Color.RED)
	draw_rect(Rect2(Vector2.ZERO, Vector2(health * UNIT_SIZE, UNIT_SIZE)), Color.GREEN)
