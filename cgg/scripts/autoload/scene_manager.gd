extends Node
## The one door between scenes (spec §7.2): fades out, swaps scene, fades in.
## Persistent state lives in GameState and is never reset by a transition.

var _changing: bool = false


func change_scene(path: String, spawn: String = "") -> void:
	if _changing:
		return
	_changing = true
	GameState.pending_spawn = spawn
	GameState.pending_player_position = null
	if not ResourceLoader.exists(path):
		push_error("[SceneManager] scene not found: " + path)
		_changing = false
		return
	await UI.fade_out()
	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[SceneManager] change failed (%d): %s" % [err, path])
	# Let the new scene instantiate and run _ready() before revealing it.
	await get_tree().process_frame
	await get_tree().process_frame
	await UI.fade_in()
	_changing = false
	print("[CHECK] scene ready: ", path, " spawn=", spawn)


func restart_current_scene() -> void:
	if _changing:
		return
	_changing = true
	await UI.fade_out()
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await get_tree().process_frame
	await UI.fade_in()
	_changing = false


func quit_game() -> void:
	get_tree().quit()
