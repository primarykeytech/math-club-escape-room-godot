class_name EscapeRoomData
extends RefCounted

## Data container and parser for math escape room configuration and stages.

var room_title: String = "THE VAULT OF NEWTON"
var subtitle: String = "MATH CLUB RETRO ESCAPE ROOM"
var intro_text: String = ""
var time_limit_seconds: float = 1800.0
var default_penalty_seconds: float = 30.0
var prologue_screens: Array = []
var stages: Array = []
var victory_screen: Dictionary = {}
var game_over_screen: Dictionary = {}

static func load_from_file(path: String = "res://data/escape_room.json") -> EscapeRoomData:
	var data := EscapeRoomData.new()
	if not FileAccess.file_exists(path):
		push_error("EscapeRoomData: File not found at " + path)
		return data

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("EscapeRoomData: Could not open file at " + path + " (Error: " + str(FileAccess.get_open_error()) + ")")
		return data

	var json_str := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if not (parsed is Dictionary):
		push_error("EscapeRoomData: Invalid JSON dictionary parsed from " + path)
		return data

	data.room_title = parsed.get("room_title", "THE VAULT OF NEWTON")
	data.subtitle = parsed.get("subtitle", "MATH CLUB ESCAPE ROOM")
	data.intro_text = parsed.get("intro_text", "")
	data.time_limit_seconds = float(parsed.get("time_limit_seconds", 1800.0))
	data.default_penalty_seconds = float(parsed.get("penalty_seconds", 30.0))
	data.prologue_screens = parsed.get("prologue_screens", [])
	data.stages = parsed.get("stages", [])
	data.victory_screen = parsed.get("victory_screen", {})
	data.game_over_screen = parsed.get("game_over_screen", {})

	return data

func get_stage(idx: int) -> Dictionary:
	if idx >= 0 and idx < stages.size():
		return stages[idx]
	return {}

func get_prologue(idx: int) -> Dictionary:
	if idx >= 0 and idx < prologue_screens.size():
		return prologue_screens[idx]
	return {}

func get_total_stages() -> int:
	return stages.size()

func get_total_prologues() -> int:
	return prologue_screens.size()
