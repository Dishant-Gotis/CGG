extends Node
## Registers the game's Input Map actions at startup (spec §8).
## If an action already exists (e.g. defined by the owner in the editor),
## that definition is kept instead of being overwritten.

const LETTER_ACTIONS: Dictionary = {
	"move_up": [KEY_W],
	"move_down": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"attack": [KEY_Q],
	"cast_mana": [KEY_F, KEY_R],
	"interact": [KEY_E],
	"advance": [KEY_E],
}
const SPECIAL_ACTIONS: Dictionary = {
	"move_up": [KEY_UP],
	"move_down": [KEY_DOWN],
	"move_left": [KEY_LEFT],
	"move_right": [KEY_RIGHT],
	"interact": [KEY_SPACE],
	"advance": [KEY_SPACE, KEY_ENTER],
	"pause": [KEY_ESCAPE],
	"skip": [KEY_ENTER, KEY_ESCAPE],
	"sprint": [KEY_SHIFT],
}


func _ready() -> void:
	for action: String in LETTER_ACTIONS:
		_ensure_action(action)
		for code: Key in LETTER_ACTIONS[action]:
			_add_key(action, code, true)
	for action: String in SPECIAL_ACTIONS:
		_ensure_action(action)
		for code: Key in SPECIAL_ACTIONS[action]:
			_add_key(action, code, false)
	print("[CHECK] input actions ready: ", InputMap.get_actions().size())


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)


func _add_key(action: String, code: Key, physical: bool) -> void:
	var ev := InputEventKey.new()
	if physical:
		ev.physical_keycode = code
	else:
		ev.keycode = code
	# Skip duplicates (an action may list the same key twice across tables).
	for existing: InputEvent in InputMap.action_get_events(action):
		var k := existing as InputEventKey
		if k != null and k.physical_keycode == code and physical:
			return
		if k != null and k.keycode == code and not physical:
			return
	InputMap.action_add_event(action, ev)
