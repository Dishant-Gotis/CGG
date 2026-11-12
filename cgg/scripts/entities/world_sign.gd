extends Area2D
class_name WorldSign

@export var prompt_text: String = "E - Read Sign"
@export var speaker: String = "Signpost"
@export var lines: Array[String] = []
@export var is_cave_sign: bool = false

func interact(_player: Node) -> void:
	if is_cave_sign:
		if GameState.has_item("cave_torch"):
			UI.start_dialogue([
				"Mystic Cavern Signpost:",
				"Warning: Treacherous crystal precipices ahead.",
				"Your burning Cave Torch illuminates safe passage into the cavern.",
				"Step up to the cave opening to descend!"
			], "Cave Sign")
		else:
			UI.start_dialogue([
				"Mystic Cavern Signpost:",
				"Warning: Deep subterranean crystal chasms.",
				"The descent is pitch black and fatal without a continuous source of light.",
				"A Cave Torch is required to enter. Seek Elder Oakhaven in Mossveil Village!"
			], "Cave Sign")
	else:
		UI.start_dialogue(lines, speaker)
