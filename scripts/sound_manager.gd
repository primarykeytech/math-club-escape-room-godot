class_name SoundManager
extends Node

## Handles background music looping and audio sound effect playback.

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var sfx_click: AudioStreamPlayer = $SFXClick
@onready var sfx_enter: AudioStreamPlayer = $SFXEnter
@onready var sfx_error: AudioStreamPlayer = $SFXError
@onready var sfx_success: AudioStreamPlayer = $SFXSuccess
@onready var sfx_victory: AudioStreamPlayer = $SFXVictory

var current_bgm_tween: Tween

func play_bgm() -> void:
	if bgm_player == null or bgm_player.stream == null:
		return
	if not bgm_player.playing:
		if current_bgm_tween and current_bgm_tween.is_valid():
			current_bgm_tween.kill()
		bgm_player.volume_db = -6.0
		bgm_player.play()

func fadeout_bgm(duration: float = 1.2) -> void:
	if bgm_player == null or not bgm_player.playing:
		return
	if current_bgm_tween and current_bgm_tween.is_valid():
		current_bgm_tween.kill()
	current_bgm_tween = create_tween()
	current_bgm_tween.tween_property(bgm_player, "volume_db", -40.0, duration)
	current_bgm_tween.tween_callback(Callable(bgm_player, "stop"))

func stop_bgm() -> void:
	if current_bgm_tween and current_bgm_tween.is_valid():
		current_bgm_tween.kill()
	if bgm_player:
		bgm_player.stop()

func play_click() -> void:
	if sfx_click:
		sfx_click.play()

func play_enter() -> void:
	if sfx_enter:
		sfx_enter.play()

func play_error() -> void:
	if sfx_error:
		sfx_error.play()

func play_success() -> void:
	if sfx_success:
		sfx_success.play()

func play_victory() -> void:
	if sfx_victory:
		sfx_victory.play()
