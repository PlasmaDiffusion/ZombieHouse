extends Area2D

enum PickupType { HERB, HEART, KEY, KNIFE, ZOMBIE_ARM }

@export var herb_heal_amount: float = 5.0

# Keep textures in the same order as PickupType.
@export var pickup_sprites: Array[Texture2D] = [
	preload("res://assets/images/herb.png"),
	preload("res://assets/images/Heart.png"),
	preload("res://assets/images/Key.png"),
	preload("res://assets/images/Knife.png"),
	preload("res://assets/images/ZombieArm.png"),
]

@export var pickup_type: PickupType = PickupType.HERB:
	set(value):
		pickup_type = value
		if is_node_ready():
			_update_sprite()

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_update_sprite()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion() or not body.is_in_group("player"):
		return
	if body.get("is_dead") == true:
		return
	match pickup_type:
		PickupType.HERB:
			body.heal(herb_heal_amount)
		PickupType.HEART:
			body.win()
		PickupType.KEY:
			body.key_count += 1
		PickupType.ZOMBIE_ARM:
			body.zombie_arm_count += 1
		PickupType.KNIFE:
			pass
	queue_free()

func _update_sprite() -> void:
	if pickup_type >= pickup_sprites.size():
		sprite.texture = null
		push_warning("No sprite configured for pickup type %s." % pickup_type)
		return
	sprite.texture = pickup_sprites[pickup_type]
