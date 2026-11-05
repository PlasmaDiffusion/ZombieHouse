extends Control

@onready var health_bar = $HealthBar
@onready var death_label: Label = $DeathLabel
@onready var win_label: Label = $WinLabel
@onready var player = get_node("../../Player")
@onready var key_count_label: Label = $Inventory/KeyCount
@onready var zombie_arm_count_label: Label = $Inventory/ZombieArmCount

func _ready() -> void:
	player.health_changed.connect(_update_health)
	player.died.connect(_on_player_died)
	player.won.connect(win)
	player.inventory_changed.connect(_update_inventory)
	_update_inventory()
	_update_health(player.health)
	death_label.hide()
	win_label.hide()

func _update_health(current_health: float) -> void:
	health_bar.set_health(current_health, player.maxHealth)

func _update_inventory() -> void:
	key_count_label.text = str(player.key_count)
	zombie_arm_count_label.text = str(player.zombie_arm_count)

func _on_player_died() -> void:
	death_label.show()

func win() -> void:
	win_label.text = "A Winner Is You!"
	win_label.show()
