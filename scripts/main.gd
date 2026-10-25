class_name Main
extends Control

## Main UI and interaction controller for Math Club Escape Room.

@onready var game_manager: GameManager = $GameManager
@onready var sound_manager: SoundManager = $SoundManager

# Layout Nodes
@onready var main_container: MarginContainer = $MainContainer
@onready var alert_overlay: ColorRect = $AlertOverlay

# HUD Nodes
@onready var title_label: Label = %TitleLabel
@onready var stage_badge: Label = %StageBadge
@onready var timer_label: Label = %TimerLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var fullscreen_btn: Button = %FullscreenButton
@onready var exit_btn: Button = %ExitButton

# Viewport Nodes
@onready var stage_image: TextureRect = %StageImage
@onready var image_caption: Label = %ImageCaption

# Narrative Nodes
@onready var speaker_tag: Label = %SpeakerTag
@onready var narrative_label: RichTextLabel = %NarrativeLabel
@onready var puzzle_panel: PanelContainer = %PuzzlePanel
@onready var puzzle_label: RichTextLabel = %PuzzleLabel
@onready var status_panel: PanelContainer = %StatusPanel
@onready var status_label: RichTextLabel = %StatusLabel

# Command Nodes
@onready var prompt_prefix: Label = %PromptPrefix
@onready var input_line: LineEdit = %InputLine
@onready var submit_btn: Button = %SubmitButton
@onready var hint_btn: Button = %HintButton
@onready var action_btn: Button = %ActionButton
@onready var restart_btn: Button = %RestartButton

# Image Cache
var image_cache: Dictionary = {}
var shake_tween: Tween
var flash_tween: Tween

func _ready() -> void:
	_preload_images()
	_connect_signals()

	# Start on main menu / intro screen
	if game_manager:
		game_manager.load_game_data(game_manager.data_path)
		title_label.text = game_manager.data.room_title
		_update_ui_state(GameManager.State.START)
		sound_manager.play_bgm()

	_update_fullscreen_button_text()
	input_line.grab_focus()

func _preload_images() -> void:
	var img_dir := "res://assets/images/"
	var dir := DirAccess.open(img_dir)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				var full_path := img_dir + file_name
				var tex := load(full_path) as Texture2D
				if tex:
					image_cache[file_name] = tex
			file_name = dir.get_next()

func _connect_signals() -> void:
	game_manager.state_changed.connect(_on_state_changed)
	game_manager.stage_changed.connect(_on_stage_changed)
	game_manager.prologue_changed.connect(_on_prologue_changed)
	game_manager.timer_ticked.connect(_on_timer_ticked)
	game_manager.hint_revealed.connect(_on_hint_revealed)
	game_manager.answer_result.connect(_on_answer_result)
	game_manager.game_completed.connect(_on_game_completed)
	game_manager.game_over.connect(_on_game_over)
	game_manager.screen_shake_requested.connect(_on_screen_shake)
	game_manager.alert_flash_requested.connect(_on_alert_flash)

	# Connect UI inputs
	input_line.text_submitted.connect(_on_input_submitted)
	input_line.text_changed.connect(func(_new_text): sound_manager.play_click())
	submit_btn.pressed.connect(_on_submit_pressed)
	hint_btn.pressed.connect(_on_hint_pressed)
	action_btn.pressed.connect(_on_action_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(_on_fullscreen_toggle_pressed)
	if exit_btn:
		exit_btn.pressed.connect(_on_exit_pressed)

func _set_viewport_image(filename: String, caption: String = "") -> void:
	if image_cache.has(filename):
		var target_tex = image_cache[filename]
		image_caption.text = caption
		if stage_image.texture == null:
			stage_image.texture = target_tex
			stage_image.modulate.a = 1.0
		elif stage_image.texture != target_tex:
			# Smooth crossfade
			var t := create_tween()
			t.tween_property(stage_image, "modulate:a", 0.3, 0.08)
			t.tween_callback(func(): stage_image.texture = target_tex)
			t.tween_property(stage_image, "modulate:a", 1.0, 0.12)
	else:
		image_caption.text = "[ IMAGE NOT FOUND ]"

func _on_state_changed(new_state: GameManager.State, _old_state: GameManager.State) -> void:
	_update_ui_state(new_state)

func _update_ui_state(state: GameManager.State) -> void:
	match state:
		GameManager.State.START:
			stage_badge.text = "MISSION BRIEFING"
			stage_badge.modulate = Color(0.7, 0.85, 1.0)
			progress_bar.value = 0
			timer_label.text = "TIME: %s" % game_manager.format_time(game_manager.time_limit)
			timer_label.modulate = Color(0.9, 0.9, 0.9)

			_set_viewport_image("professor_intro_gb.png", "THE VAULT OF NEWTON // ARCHIVES")
			speaker_tag.text = "MISSION BRIEFING // ARCHIVAL ARCHIVES"
			narrative_label.text = "[font_size=17]%s[/font_size]" % game_manager.data.intro_text

			puzzle_panel.visible = false
			status_panel.visible = true
			status_label.text = "[color=#79c0ff]Press [b]START[/b] or press Enter to begin your trial.[/color]"

			prompt_prefix.text = "> "
			input_line.placeholder_text = "Press Enter or click 'Start Escape'..."
			hint_btn.visible = false
			action_btn.visible = true
			action_btn.text = "Start Escape ->"
			submit_btn.visible = true
			submit_btn.text = "Begin"

		GameManager.State.PROLOGUE:
			puzzle_panel.visible = false
			hint_btn.visible = false
			action_btn.visible = true
			submit_btn.visible = true
			submit_btn.text = "Next"

		GameManager.State.PLAYING:
			puzzle_panel.visible = true
			status_panel.visible = true
			hint_btn.visible = true
			action_btn.visible = false
			submit_btn.visible = true
			submit_btn.text = "Submit"
			prompt_prefix.text = "ENTER CODE > "
			input_line.placeholder_text = "Type your answer or 'hint'..."
			input_line.grab_focus()

		GameManager.State.STAGE_SOLVED:
			puzzle_panel.visible = true
			hint_btn.visible = false
			action_btn.visible = true
			action_btn.text = "Next Challenge ->"
			submit_btn.visible = false
			input_line.placeholder_text = "Press Enter to proceed to the next stage..."
			sound_manager.play_success()

		GameManager.State.VICTORY:
			stage_badge.text = "VAULT CONQUERED"
			stage_badge.modulate = Color(0.4, 0.95, 0.5)
			progress_bar.value = 100
			hint_btn.visible = false
			action_btn.visible = true
			action_btn.text = "Play Again"
			submit_btn.visible = false
			puzzle_panel.visible = true
			status_panel.visible = true
			prompt_prefix.text = "> "
			input_line.placeholder_text = "Press Enter to restart..."
			sound_manager.play_victory()

		GameManager.State.GAME_OVER:
			stage_badge.text = "SYSTEM LOCKOUT"
			stage_badge.modulate = Color(1.0, 0.35, 0.35)
			hint_btn.visible = false
			action_btn.visible = true
			action_btn.text = "Try Again"
			submit_btn.visible = false
			puzzle_panel.visible = true
			status_panel.visible = true
			prompt_prefix.text = "> "
			input_line.placeholder_text = "Press Enter to retry..."
			sound_manager.play_error()
			sound_manager.play_bgm()

func _on_prologue_changed(p_data: Dictionary, idx: int, total: int) -> void:
	stage_badge.text = "BRIEFING %d / %d" % [idx + 1, total]
	stage_badge.modulate = Color(0.9, 0.75, 0.3)
	progress_bar.value = float(idx) / float(total) * 15.0

	var img_name: String = p_data.get("image", "professor_intro_gb.png")
	var speaker: String = p_data.get("speaker", "THE PROFESSOR")
	var title: String = p_data.get("title", "TRANSMISSION")

	_set_viewport_image(img_name, "%s // %s" % [speaker, title])
	speaker_tag.text = ">> %s // %s <<" % [speaker, title]
	var text: String = game_manager.format_narrative_text(p_data.get("text", ""))
	narrative_label.text = "[font_size=17]%s[/font_size]" % text

	var is_last := (idx + 1 >= total)
	action_btn.text = "Enter Vault ->" if is_last else "Next Briefing ->"
	status_label.text = "[color=#79c0ff]Briefing slide %d of %d. Read carefully before entering.[/color]" % [idx + 1, total]

func _on_stage_changed(s_data: Dictionary, idx: int, total: int) -> void:
	stage_badge.text = "STAGE %d / %d" % [idx + 1, total]
	stage_badge.modulate = Color(0.2, 0.7, 1.0)
	progress_bar.value = float(idx) / float(total) * 100.0

	var img_name: String = s_data.get("image", "")
	var title: String = s_data.get("title", "CHALLENGE")
	_set_viewport_image(img_name, "%s // STAGE %d" % [title, idx + 1])

	speaker_tag.text = "STAGE %d: %s" % [idx + 1, title]
	narrative_label.text = "[font_size=16]%s[/font_size]" % s_data.get("flavor_text", "")

	var puzzle_raw: String = s_data.get("puzzle_text", "")
	puzzle_label.text = "[b][color=#f0f6fc]%s[/color][/b]" % puzzle_raw

	status_label.text = "[color=#8b949e]Stage initiated. Enter your code or type [b]'hint'[/b] for assistance.[/color]"
	input_line.text = ""

func _on_timer_ticked(time_rem: float, formatted: String) -> void:
	timer_label.text = "TIME: " + formatted
	if time_rem < 60.0:
		timer_label.modulate = Color(1.0, 0.25, 0.25)
	elif time_rem < 300.0:
		timer_label.modulate = Color(1.0, 0.75, 0.2)
	else:
		timer_label.modulate = Color(0.9, 0.95, 1.0)

func _on_hint_revealed(hint_text: String, revealed: int, total: int) -> void:
	sound_manager.play_enter()
	status_label.text = "[color=#e6c35c]💡 [b]HINT %d/%d:[/b] %s[/color]" % [revealed, total, hint_text]

func _on_answer_result(correct: bool, message: String, _penalty: float) -> void:
	if correct:
		sound_manager.play_success()
		status_label.text = "[color=#3fb950]✔ [b]SUCCESS:[/b] %s[/color]" % message
	else:
		sound_manager.play_error()
		status_label.text = "[color=#f85149]✖ [b]ERROR:[/b] %s[/color]" % message

func _on_game_completed(elapsed: float, summary: Dictionary) -> void:
	var v_cfg: Dictionary = summary.get("victory_screen", {})
	var speaker: String = v_cfg.get("speaker", "THE PROFESSOR")
	var title: String = v_cfg.get("title", "ENRAGED RETRIBUTION")
	var img: String = v_cfg.get("image", "professor_angry_gb.png")

	_set_viewport_image(img, "%s // %s" % [speaker, title])
	speaker_tag.text = ">> %s // %s <<" % [speaker, title]
	narrative_label.text = "[font_size=16][color=#ff7b72]\"%s\"[/color][/font_size]" % v_cfg.get("dialogue", "")

	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	puzzle_label.text = "[b][color=#56d364]★ TRIAL COMPLETE // ALL %d STAGES CONQUERED ★[/color][/b]\nTotal Escape Time: [b]%02d:%02d[/b]\nTotal Penalty Incurred: [b]%d seconds[/b]" % [
		summary.get("total_stages", 6), mins, secs, int(summary.get("total_penalties", 0))
	]
	status_label.text = "[color=#7ee787]You outsmarted the Professor and unlocked the secrets of Newton![/color]"

func _on_game_over(stages_cleared: int, total_stages: int, summary: Dictionary) -> void:
	var g_cfg: Dictionary = summary.get("game_over_screen", {})
	var speaker: String = g_cfg.get("speaker", "THE PROFESSOR")
	var title: String = g_cfg.get("title", "GLOATING TRIUMPH")
	var img: String = g_cfg.get("image", "professor_gloating_gb.png")

	_set_viewport_image(img, "%s // %s" % [speaker, title])
	speaker_tag.text = ">> %s // %s <<" % [speaker, title]
	narrative_label.text = "[font_size=16][color=#f85149]\"%s\"[/color][/font_size]" % g_cfg.get("dialogue", "")

	puzzle_label.text = "[b][color=#f85149]✖ TIME EXPIRED // ARCHIVES PERMANENTLY SEALED ✖[/color][/b]\nStages Cleared: [b]%d / %d[/b]" % [
		stages_cleared, total_stages
	]
	status_label.text = "[color=#f85149]The countdown clock hit zero. The heavy iron bolts slam shut forever.[/color]"

func _on_input_submitted(text: String) -> void:
	var cmd := text.strip_edges()
	input_line.text = ""
	sound_manager.play_enter()
	game_manager.process_command(cmd)

func _on_submit_pressed() -> void:
	var cmd := input_line.text.strip_edges()
	input_line.text = ""
	sound_manager.play_enter()
	game_manager.process_command(cmd)

func _on_hint_pressed() -> void:
	sound_manager.play_enter()
	game_manager.request_hint()

func _on_action_pressed() -> void:
	sound_manager.play_enter()
	match game_manager.current_state:
		GameManager.State.START:
			game_manager.start_game()
		GameManager.State.PROLOGUE:
			game_manager.advance_prologue()
		GameManager.State.STAGE_SOLVED:
			game_manager.advance_stage()
		GameManager.State.VICTORY, GameManager.State.GAME_OVER:
			game_manager.restart_game()
		_:
			pass

func _on_restart_pressed() -> void:
	sound_manager.play_click()
	game_manager.restart_game()
	sound_manager.play_bgm()

func _on_exit_pressed() -> void:
	sound_manager.play_click()
	if OS.has_feature("web"):
		# Browsers restrict script window closure; return to briefing and stop
		game_manager.restart_game()
		sound_manager.play_bgm()
	else:
		get_tree().quit()

func _on_screen_shake(strength: float) -> void:
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	position = Vector2.ZERO
	shake_tween = create_tween()
	for i in range(4):
		var decay := (1.0 - float(i) * 0.25)
		var offset := Vector2(
			randf_range(-strength, strength) * decay,
			randf_range(-strength, strength) * decay
		)
		shake_tween.tween_property(self, "position", offset, 0.04)
	shake_tween.tween_property(self, "position", Vector2.ZERO, 0.04)

func _on_alert_flash() -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	alert_overlay.color = Color(0.8, 0.1, 0.1, 0.35)
	flash_tween = create_tween()
	flash_tween.tween_property(alert_overlay, "color:a", 0.0, 0.4)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()

func _on_fullscreen_toggle_pressed() -> void:
	sound_manager.play_click()
	_toggle_fullscreen()

func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_fullscreen_button_text()

func _update_fullscreen_button_text() -> void:
	if fullscreen_btn == null:
		return
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		fullscreen_btn.text = "🗗 Windowed"
	else:
		fullscreen_btn.text = "⛶ Fullscreen"
