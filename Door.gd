extends Area2D

@onready var prompt_label = $PromptLabel
var player_nearby = false
var next_scene_path = "res://InterDimensionalTrainStation.tscn"

func _ready():
	add_to_group("door")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		if prompt_label:
			prompt_label.visible = false

func _input(event):
	if player_nearby and event.is_action_pressed("interact"):
		enter_door()

func enter_door():
	# Change to the train station scene
	get_tree().change_scene_to_file(next_scene_path)