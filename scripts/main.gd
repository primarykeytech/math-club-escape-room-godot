class_name Main
extends Control

## Main controller connecting UI view elements to the GameManager.

@onready var game_manager: GameManager = $GameManager

func _ready() -> void:
	print("Math Club Escape Room initialized.")
	if game_manager:
		print("Game loaded: ", game_manager.data.room_title)
