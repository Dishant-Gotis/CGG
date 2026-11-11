extends Control
## Video-based Prologue Cutscene
## Plays 1112_1_.ogv, automatically pausing at specific story timestamps
## and resuming when the player presses [E] or [Space].
## Transitions to the main playing mode (world.tscn) upon completion.

const VIDEO_PATH := "res://Tiny Swords (Update 010)/everything/1112_1_.ogv"

# Timecodes from video editing (seconds:frames, where 30 frames = 1 second)
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

var current_pause_idx: int = 0
var is_paused_at_point: bool = false
var is_finished: bool = false
var playback_timer: float = 0.0


func _ready() -> void:
	prompt_panel.visible = false
	
	# Configure VideoStream
	_setup_video_stream()
	
	# Connect finished signal
	video_player.finished.connect(_on_video_finished)
	
	# Start playback
	video_player.play()
	print("[PROLOGUE] Video playback started: %s" % VIDEO_PATH)


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


func _process(delta: float) -> void:
	if is_finished:
		return
	
	if is_paused_at_point:
		# Subtle pulsing breathing effect on the prompt to guide the player
		var pulse: float = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.006)
		prompt_panel.modulate.a = pulse
		return
	
	# Track stream playback position
	var pos: float = video_player.get_stream_position()
	if pos > 0.0:
		playback_timer = pos
	else:
		playback_timer += delta
	
	var current_time: float = maxf(pos, playback_timer)
	
	# Check if we reached the next designated pause timestamp
	if current_pause_idx < PAUSE_POINTS.size():
		var target: float = float(PAUSE_POINTS[current_pause_idx]["time"])
		if current_time >= target:
			_pause_at_point(current_time)


func _pause_at_point(current_time: float) -> void:
	is_paused_at_point = true
	video_player.paused = true
	prompt_panel.visible = true
	
	var pt: Dictionary = PAUSE_POINTS[current_pause_idx]
	print("[PROLOGUE] Paused at [%s] (target: %.3fs, actual: %.3fs) (%d/%d)" % [
		pt["code"], pt["time"], current_time, current_pause_idx + 1, PAUSE_POINTS.size()
	])


func _resume_playback() -> void:
	is_paused_at_point = false
	prompt_panel.visible = false
	current_pause_idx += 1
	video_player.paused = false
	print("[PROLOGUE] Resumed playback, next pause index: %d" % current_pause_idx)


func _unhandled_input(event: InputEvent) -> void:
	if is_finished:
		return
	
	# Skip Prologue Cutscene (Escape or Skip action)
	if event.is_action_pressed("skip") or event.is_action_pressed("pause") or _is_key_pressed(event, KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		print("[PROLOGUE] Cutscene skipped by player.")
		_finish_prologue()
		return
	
	# When paused at a story point, press [E] or [Space] to proceed
	if is_paused_at_point:
		if event.is_action_pressed("interact") or event.is_action_pressed("advance") or _is_key_pressed(event, KEY_E) or _is_key_pressed(event, KEY_SPACE):
			get_viewport().set_input_as_handled()
			_resume_playback()
			return


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
	
	# Mark prologue complete in GameState
	GameState.set_flag("prologue_complete", true)
	print("[PROLOGUE] Transitioning to main gameplay: res://scenes/world.tscn")
	
	# Transition to main world gameplay
	SceneManager.change_scene("res://scenes/world.tscn")
