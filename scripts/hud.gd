extends Control

@onready var health_label: Label = $HealthLabel
@onready var death_label: Label = $DeathLabel
@onready var player = get_node("../../Player")

func _ready() -> void:
	player.health_changed.connect(_update_health)
	player.died.connect(_on_player_died)
	_update_health(player.health)
	death_label.hide()

func _update_health(current_health: float) -> void:
	health_label.text = "HP: %d" % int(ceil(current_health))

func _on_player_died() -> void:
	death_label.show()
