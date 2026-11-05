extends Control

@onready var health_bar = $HealthBar
@onready var death_label: Label = $DeathLabel
@onready var win_label: Label = $WinLabel
@onready var player = get_node("../../Player")

func _ready() -> void:
	player.health_changed.connect(_update_health)
	player.died.connect(_on_player_died)
	player.won.connect(win)
	_update_health(player.health)
	death_label.hide()
	win_label.hide()

func _update_health(current_health: float) -> void:
	health_bar.set_health(current_health, player.maxHealth)

func _on_player_died() -> void:
	death_label.show()

func win() -> void:
	win_label.text = "A Winner Is You!"
	win_label.show()
