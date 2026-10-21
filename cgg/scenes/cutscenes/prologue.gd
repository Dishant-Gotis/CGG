extends Control

@onready var bg: TextureRect = $StageRoot/Background
@onready var tint: ColorRect = $StageRoot/Tint
@onready var stage_root: Control = $StageRoot
@onready var arjun_sprite: AnimatedSprite2D = $StageRoot/ArjunSprite
@onready var title_label: Label = $TitleLabel
@onready var runner: CutsceneRunner = $CutsceneRunner


func _ready() -> void:
	# Inherit SpriteFrames from player.tscn for 100% visual consistency
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	if player_scene != null:
		var p_inst: Node = player_scene.instantiate()
		var p_anim := p_inst.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if p_anim != null and p_anim.sprite_frames != null:
			arjun_sprite.sprite_frames = p_anim.sprite_frames
			arjun_sprite.scale = Vector2(3.0, 3.0)
		p_inst.queue_free()

	runner.setup(bg, tint, stage_root, arjun_sprite, title_label)
	
	var data: Variant = Assets.load_json(Assets.PROLOGUE_JSON)
	if data is Dictionary and (data as Dictionary).has("prologue"):
		var steps: Array = (data as Dictionary)["prologue"]
		await runner.play(steps)
	
	GameState.set_flag("prologue_complete", true)
	SceneManager.change_scene("res://scenes/world.tscn")
