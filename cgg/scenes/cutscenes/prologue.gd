extends Control
## Video-based Prologue Cutscene
## Plays 1112_1_.ogv (muted), plays starlight-arpeggio.mp3 as background music.
## (Pause timestamps are currently commented out per request to play through without stopping).
## Transitions to the main playing mode (world.tscn) upon completion.

const VIDEO_PATH := "res://Tiny Swords (Update 010)/everything/1112_1_.ogv"
const BGM_PATH := "res://Tiny Swords (Update 010)/everything/starlight-arpeggio.mp3"
const TRANSITION_PATH := "res://Tiny Swords (Update 010)/everything/transition.mp3"

# Timecodes from video editing (seconds:frames, where 30 frames = 1 second)
# PRESERVED FOR FUTURE USE:
const PAUSE_POINTS: Array[Dictionary] = [
	{"time": 1.0 + 8.0 / 30.0, "code": "1:08"},     # ~1.267s
	{"time": 4.0, "code": "4"},                     # 4.000s
	{"time": 5.0, "code": "5"},                     # 5.000s
	{"time": 7.0 + 23.0 / 30.0, "code": "7:23"},    # ~7.767s
	{"time": 9.0 + 16.0 / 30.0, "code": "9:16"},    # ~9.533s
	{"time": 12.0 + 2.0 / 30.0, "code": "12:02"},   # ~12.067s
	{"time": 15.0 + 27.0 / 30.0, "code": "15:27"},  # 15.900s
	{"time": 23.0 + 25.0 / 30.0, "code": "23:25"},  # ~23.833s
	{"time": 27.0 + 29.0 / 30.0, "code": "27:29"},  # ~27.967s
	{"time": 31.0 + 27.0 / 30.0, "code": "31:27"},  # 31.900s
	{"time": 35.0 + 27.0 / 30.0, "code": "35:27"},  # 35.900s
	{"time": 39.0 + 19.0 / 30.0, "code": "39:19"},  # ~39.633s
	{"time": 43.0 + 23.0 / 30.0, "code": "43:23"},  # ~43.767s
	{"time": 47.0 + 27.0 / 30.0, "code": "47:27"},  # 47.900s
	{"time": 51.0 + 15.0 / 30.0, "code": "51:15"},  # 51.500s
]

@onready var video_player: VideoStreamPlayer = $AspectRatioContainer/VideoStreamPlayer
@onready var prompt_panel: PanelContainer = $Overlay/PromptPanel
@onready var prompt_label: Label = $Overlay/PromptPanel/PromptLabel
@onready var skip_label: Label = $Overlay/SkipLabel
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var sfx_transition: AudioStreamPlayer = $TransitionSFXPlayer

var current_pause_idx: int = 0
var is_paused_at_point: bool = false
var is_finished: bool = false
var playback_timer: float = 0.0


func _ready() -> void:
	# Hide all gameplay HUD and Hotbars during cutscene
	UI.set_hud_visible(false)
	prompt_panel.visible = false
	
	# Configure VideoStream & mute video's native audio
	_setup_video_stream()
	video_player.volume_db = -80.0
	video_player.volume = 0.0
	
	# Setup and start background music (starlight-arpeggio.mp3)
	_setup_audio()
	
	# Connect finished signal
	video_player.finished.connect(_on_video_finished)
	
	# Start video playback (continuous, no pauses)
	video_player.play()
	print("[PROLOGUE] Video playing continuously from start to finish: %s" % VIDEO_PATH)


func _setup_video_stream() -> void:
	if video_player.stream == null:
		if ResourceLoader.exists(VIDEO_PATH):
			var res := load(VIDEO_PATH)
			if res is VideoStream:
				video_player.stream = res
		
		# Fallback if load() returns generic resource
		if video_player.stream == null:
			var vs := VideoStreamTheora.new()
			vs.file = VIDEO_PATH
			video_player.stream = vs


func _setup_audio() -> void:
	# Background music: starlight-arpeggio.mp3
	if ResourceLoader.exists(BGM_PATH):
		var bgm: AudioStream = load(BGM_PATH)
		if bgm is AudioStreamMP3:
			(bgm as AudioStreamMP3).loop = true
		bgm_player.stream = bgm
		bgm_player.volume_db = -4.0
		bgm_player.play()
		print("[PROLOGUE] Background music started: %s" % BGM_PATH)
	else:
		push_warning("[PROLOGUE] BGM file not found: %s" % BGM_PATH)

	# Transition SFX: transition.mp3
	if ResourceLoader.exists(TRANSITION_PATH):
		var sfx: AudioStream = load(TRANSITION_PATH)
		if sfx is AudioStreamMP3:
			(sfx as AudioStreamMP3).loop = false
		sfx_transition.stream = sfx
		sfx_transition.volume_db = 0.0
		print("[PROLOGUE] Transition SFX ready: %s" % TRANSITION_PATH)
	else:
		push_warning("[PROLOGUE] Transition SFX not found: %s" % TRANSITION_PATH)


func _play_transition_sfx() -> void:
	if sfx_transition != null and sfx_transition.stream != null:
		sfx_transition.play()


func _process(delta: float) -> void:
	if is_finished:
		return
	
	# =========================================================================
	# PAUSE CHECK CODE (COMMENTED OUT TEMPORARILY AS REQUESTED)
	# =========================================================================
	# if is_paused_at_point:
	# 	var pulse: float = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.006)
	# 	prompt_panel.modulate.a = pulse
	# 	return
	#
	# var pos: float = video_player.get_stream_position()
	# if pos > 0.0:
	# 	playback_timer = pos
	# else:
	# 	playback_timer += delta
	#
	# var current_time: float = maxf(pos, playback_timer)
	# if current_pause_idx < PAUSE_POINTS.size():
	# 	var target: float = float(PAUSE_POINTS[current_pause_idx]["time"])
	# 	if current_time >= target:
	# 		_pause_at_point(current_time)
	# =========================================================================

	# Fallback check to ensure scene finishes when video completes
	playback_timer += delta
	if not video_player.is_playing() and playback_timer > 5.0:
		_finish_prologue()


# =============================================================================
# PAUSE FUNCTIONS (COMMENTED OUT TEMPORARILY AS REQUESTED)
# =============================================================================
# func _pause_at_point(current_time: float) -> void:
# 	is_paused_at_point = true
# 	video_player.paused = true
# 	prompt_panel.visible = true
# 	var pt: Dictionary = PAUSE_POINTS[current_pause_idx]
# 	print("[PROLOGUE] Paused at [%s] (target: %.3fs, actual: %.3fs) (%d/%d)" % [
# 		pt["code"], pt["time"], current_time, current_pause_idx + 1, PAUSE_POINTS.size()
# 	])
#
# func _resume_playback() -> void:
# 	is_paused_at_point = false
# 	prompt_panel.visible = false
# 	current_pause_idx += 1
# 	video_player.paused = false
# 	print("[PROLOGUE] Resumed playback, next pause index: %d" % current_pause_idx)
# =============================================================================


func _unhandled_input(event: InputEvent) -> void:
	if is_finished:
		return
	
	# Skip Prologue Cutscene (Escape or Skip action)
	if event.is_action_pressed("skip") or event.is_action_pressed("pause") or _is_key_pressed(event, KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		print("[PROLOGUE] Cutscene skipped by player.")
		_finish_prologue()
		return
	
	# Optional: pressing E triggers the transition sound effect
	if _is_key_pressed(event, KEY_E):
		_play_transition_sfx()


func _is_key_pressed(event: InputEvent, key: Key) -> bool:
	if event is InputEventKey:
		var k := event as InputEventKey
		return k.pressed and not k.echo and (k.keycode == key or k.physical_keycode == key)
	return false


func _on_video_finished() -> void:
	print("[PROLOGUE] Video stream finished.")
	_finish_prologue()


func _finish_prologue() -> void:
	if is_finished:
		return
	is_finished = true
	
	if video_player != null:
		video_player.stop()
	
	# Fade out prologue BGM
	if bgm_player != null and bgm_player.playing:
		var tw := create_tween()
		tw.tween_property(bgm_player, "volume_db", -80.0, 0.4)
		tw.tween_callback(bgm_player.stop)
	
	# Mark prologue complete in GameState
	GameState.set_flag("prologue_complete", true)
	print("[PROLOGUE] Transitioning to main gameplay: res://scenes/world.tscn")
	
	# Transition to main world gameplay
	SceneManager.change_scene("res://scenes/world.tscn")
