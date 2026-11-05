extends Node

# Autoload state survives scene changes for the current run.
var initialized: bool = false
var health: float = 5.0
var key_count: int = 0
var zombie_arm_count: int = 0

func reset() -> void:
	initialized = false
	health = 5.0
	key_count = 0
	zombie_arm_count = 0
