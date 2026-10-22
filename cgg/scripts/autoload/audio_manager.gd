extends Node
## Central audio manager for background music and sound effects.

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var step_player: AudioStreamPlayer

var bgm_stream: AudioStream
var sfx_select: AudioStream
var sfx_sword: AudioStream
var sfx_slime_die: AudioStream
var sfx_walk: AudioStream


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Safely load all sound streams
	if ResourceLoader.exists("res://sounds/main.mp3"):
		bgm_stream = load("res://sounds/main.mp3")
		if bgm_stream is AudioStreamMP3:
			(bgm_stream as AudioStreamMP3).loop = true
	if ResourceLoader.exists("res://sounds/option-selection.mp3"):
		sfx_select = load("res://sounds/option-selection.mp3")
		if sfx_select is AudioStreamMP3:
			(sfx_select as AudioStreamMP3).loop = false
	if ResourceLoader.exists("res://sounds/sword-sound.mp3"):
		sfx_sword = load("res://sounds/sword-sound.mp3")
		if sfx_sword is AudioStreamMP3:
			(sfx_sword as AudioStreamMP3).loop = false
	if ResourceLoader.exists("res://sounds/slime-dies.mp3"):
		sfx_slime_die = load("res://sounds/slime-dies.mp3")
		if sfx_slime_die is AudioStreamMP3:
			(sfx_slime_die as AudioStreamMP3).loop = false
	if ResourceLoader.exists("res://sounds/walk.mp3"):
		sfx_walk = load("res://sounds/walk.mp3")
		if sfx_walk is AudioStreamMP3:
			(sfx_walk as AudioStreamMP3).loop = false

	# BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	bgm_player.volume_db = -9.0
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player)
	bgm_player.finished.connect(_on_bgm_finished)

	# Dedicated step player to avoid footstep overlap
	step_player = AudioStreamPlayer.new()
	step_player.bus = "Master"
	step_player.volume_db = -8.0
	step_player.stream = sfx_walk
	add_child(step_player)

	# Multi-channel SFX pool for polyphony
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		sfx_players.append(p)

	print("[CHECK] AudioManager ready with 5 audio tracks")


func play_music() -> void:
	if bgm_stream == null or bgm_player == null:
		return
	if bgm_player.playing:
		return
	bgm_player.stream = bgm_stream
	bgm_player.play()


func stop_music() -> void:
	if bgm_player != null and bgm_player.playing:
		bgm_player.stop()


func _on_bgm_finished() -> void:
	if bgm_player != null and bgm_stream != null:
		bgm_player.stream = bgm_stream
		bgm_player.play()


func play_select() -> void:
	_play_sfx(sfx_select, -3.0, randf_range(0.98, 1.02))


func play_sword() -> void:
	_play_sfx(sfx_sword, -2.0, randf_range(0.93, 1.07))


func play_slime_death() -> void:
	_play_sfx(sfx_slime_die, -1.0, randf_range(0.96, 1.04))


func play_step() -> void:
	if step_player == null or sfx_walk == null:
		return
	step_player.pitch_scale = randf_range(0.92, 1.08)
	step_player.play()


func _play_sfx(stream: AudioStream, vol: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol
			p.pitch_scale = pitch
			p.play()
			return
	# Fallback if all players are busy
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = vol
	sfx_players[0].pitch_scale = pitch
	sfx_players[0].play()
