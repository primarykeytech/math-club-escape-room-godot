class_name GameManager
extends Node

## Core state machine and gameplay coordinator for Math Club Escape Room.

enum State {
	START,
	PROLOGUE,
	PLAYING,
	STAGE_SOLVED,
	VICTORY,
	GAME_OVER
}

signal state_changed(new_state: State, old_state: State)
signal stage_changed(stage_data: Dictionary, stage_index: int, total_stages: int)
signal prologue_changed(prologue_data: Dictionary, prologue_index: int, total_prologues: int)
signal timer_ticked(time_remaining: float, formatted_time: String)
signal hint_revealed(hint_text: String, hints_revealed: int, total_hints: int)
signal answer_result(correct: bool, message: String, penalty_applied: float)
signal game_completed(elapsed_seconds: float, summary_data: Dictionary)
signal game_over(stages_completed: int, total_stages: int, summary_data: Dictionary)
signal screen_shake_requested(strength: float)
signal alert_flash_requested()

@export var data_path: String = "res://data/escape_room.json"

var data: EscapeRoomData
var current_state: State = State.START
var current_stage_idx: int = 0
var current_prologue_idx: int = 0

var time_limit: float = 1800.0
var time_remaining: float = 1800.0
var timer_active: bool = false
var total_penalties_applied: float = 0.0

var hints_revealed: int = 0
var active_stage_variants: Dictionary = {}

func _ready() -> void:
	load_game_data(data_path)

func load_game_data(path: String) -> void:
	data = EscapeRoomData.load_from_file(path)
	time_limit = data.time_limit_seconds
	time_remaining = time_limit
	current_stage_idx = 0
	current_prologue_idx = 0
	hints_revealed = 0
	select_random_questions()
	set_state(State.START)

## Selects a random question from each stage's question pool for replayability.
func select_random_questions() -> void:
	active_stage_variants.clear()
	for i in range(data.get_total_stages()):
		var base_stage := data.get_stage(i)
		var pool: Array = base_stage.get("question_pool", [])
		if not pool.is_empty():
			var chosen: Dictionary = pool.pick_random()
			var merged: Dictionary = base_stage.duplicate(true)
			for k in chosen.keys():
				merged[k] = chosen[k]
			active_stage_variants[i] = merged
		else:
			active_stage_variants[i] = base_stage

## Allows manually locking in a specific variant index for testing or seeds.
func set_stage_variant_index(stage_idx: int, variant_idx: int) -> void:
	var base_stage := data.get_stage(stage_idx)
	var pool: Array = base_stage.get("question_pool", [])
	if not pool.is_empty() and variant_idx >= 0 and variant_idx < pool.size():
		var chosen: Dictionary = pool[variant_idx]
		var merged: Dictionary = base_stage.duplicate(true)
		for k in chosen.keys():
			merged[k] = chosen[k]
		active_stage_variants[stage_idx] = merged

func get_active_stage(idx: int = -1) -> Dictionary:
	if idx < 0:
		idx = current_stage_idx
	if active_stage_variants.has(idx):
		return active_stage_variants[idx]
	return data.get_stage(idx)

func _process(delta: float) -> void:
	if timer_active:
		time_remaining = max(0.0, time_remaining - delta)
		timer_ticked.emit(time_remaining, format_time(time_remaining))
		if time_remaining <= 0.0:
			trigger_game_over()

func set_state(new_state: State) -> void:
	if current_state == new_state and new_state != State.START:
		return
	var old_state := current_state
	current_state = new_state
	state_changed.emit(new_state, old_state)

func start_game() -> void:
	select_random_questions()
	if data.get_total_prologues() > 0:
		current_prologue_idx = 0
		set_state(State.PROLOGUE)
		prologue_changed.emit(
			data.get_prologue(current_prologue_idx),
			current_prologue_idx,
			data.get_total_prologues()
		)
	else:
		start_escape()

func advance_prologue() -> void:
	if current_prologue_idx + 1 < data.get_total_prologues():
		current_prologue_idx += 1
		prologue_changed.emit(
			data.get_prologue(current_prologue_idx),
			current_prologue_idx,
			data.get_total_prologues()
		)
	else:
		start_escape()

func previous_prologue() -> void:
	if current_prologue_idx > 0:
		current_prologue_idx -= 1
		prologue_changed.emit(
			data.get_prologue(current_prologue_idx),
			current_prologue_idx,
			data.get_total_prologues()
		)
	else:
		set_state(State.START)

func start_escape() -> void:
	current_stage_idx = 0
	hints_revealed = 0
	timer_active = true
	set_state(State.PLAYING)
	_emit_current_stage()

func submit_answer(raw_input: String) -> void:
	var cmd := raw_input.strip_edges()
	if cmd.is_empty():
		return

	if cmd.to_lower() == "hint":
		request_hint()
		return

	if cmd.to_lower() in ["quit", "exit"]:
		timer_active = false
		set_state(State.START)
		return

	var stage := get_active_stage(current_stage_idx)
	var accepted: Array = stage.get("accepted_answers", [])

	if AnswerValidator.matches_answer(cmd, accepted):
		# Correct answer
		set_state(State.STAGE_SOLVED)
		var solved_text: String = stage.get("solved_text", "LOCK OPENED!")
		answer_result.emit(true, solved_text, 0.0)
	else:
		# Incorrect answer with penalty
		var penalty: float = float(stage.get("penalty_seconds", data.default_penalty_seconds))
		time_remaining = max(0.0, time_remaining - penalty)
		total_penalties_applied += penalty
		screen_shake_requested.emit(12.0)
		alert_flash_requested.emit()
		var msg := "INCORRECT CODE! [-%d SECONDS PENALTY]" % int(penalty)
		answer_result.emit(false, msg, penalty)
		timer_ticked.emit(time_remaining, format_time(time_remaining))
		if time_remaining <= 0.0:
			trigger_game_over()

func request_hint() -> void:
	var stage := get_active_stage(current_stage_idx)
	var hints: Array = stage.get("hints", [])
	if hints_revealed < hints.size():
		var hint_str: String = hints[hints_revealed]
		hints_revealed += 1
		hint_revealed.emit(hint_str, hints_revealed, hints.size())
	else:
		hint_revealed.emit("NO MORE HINTS AVAILABLE FOR THIS STAGE.", hints_revealed, hints.size())

func advance_stage() -> void:
	if current_stage_idx + 1 < data.get_total_stages():
		current_stage_idx += 1
		hints_revealed = 0
		set_state(State.PLAYING)
		_emit_current_stage()
	else:
		trigger_victory()

func trigger_victory() -> void:
	timer_active = false
	set_state(State.VICTORY)
	var elapsed := time_limit - time_remaining
	var summary := {
		"elapsed_seconds": elapsed,
		"formatted_time": format_time(elapsed),
		"stages_cleared": data.get_total_stages(),
		"total_stages": data.get_total_stages(),
		"total_penalties": total_penalties_applied,
		"victory_screen": data.victory_screen
	}
	game_completed.emit(elapsed, summary)

func trigger_game_over() -> void:
	time_remaining = 0.0
	timer_active = false
	set_state(State.GAME_OVER)
	screen_shake_requested.emit(18.0)
	alert_flash_requested.emit()
	var summary := {
		"stages_cleared": current_stage_idx,
		"total_stages": data.get_total_stages(),
		"game_over_screen": data.game_over_screen
	}
	game_over.emit(current_stage_idx, data.get_total_stages(), summary)

func restart_game() -> void:
	time_remaining = time_limit
	timer_active = false
	current_stage_idx = 0
	current_prologue_idx = 0
	hints_revealed = 0
	total_penalties_applied = 0.0
	select_random_questions()
	set_state(State.START)

func process_command(cmd_text: String) -> void:
	var cmd := cmd_text.strip_edges()
	match current_state:
		State.START:
			if cmd.to_lower() in ["quit", "exit"]:
				get_tree().quit()
				return
			start_game()

		State.PROLOGUE:
			if cmd.to_lower() in ["skip", "jump", "start"]:
				start_escape()
			elif cmd.to_lower() in ["back", "prev"]:
				previous_prologue()
			elif cmd.to_lower() in ["quit", "exit"]:
				set_state(State.START)
			else:
				advance_prologue()

		State.PLAYING:
			submit_answer(cmd)

		State.STAGE_SOLVED:
			if cmd.to_lower() in ["next", "continue", "open", "go", "proceed", ""] or true:
				advance_stage()

		State.VICTORY, State.GAME_OVER:
			restart_game()

func _emit_current_stage() -> void:
	stage_changed.emit(
		get_active_stage(current_stage_idx),
		current_stage_idx,
		data.get_total_stages()
	)

func format_time(total_seconds: float) -> String:
	var sec := int(floor(max(0.0, total_seconds)))
	var mins := sec / 60
	var rem_sec := sec % 60
	return "%02d:%02d" % [mins, rem_sec]

func format_narrative_text(raw_text: String) -> String:
	if raw_text.is_empty():
		return ""
	var mins := int(time_limit / 60.0)
	var formatted := raw_text.replace("{time_limit_minutes}", str(mins))
	formatted = formatted.replace("60 minutes", str(mins) + " minutes")
	formatted = formatted.replace("{penalty_seconds}", str(int(data.default_penalty_seconds)))
	return formatted
