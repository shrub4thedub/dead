extends Area2D

@onready var prompt_label = $PromptLabel
var player_nearby = false
var next_scene_path = "res://InterDimensionalTrainStation.tscn"
var is_locked = false
var original_position: Vector2

func _ready():
	add_to_group("door")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	original_position = position
	
	# Set Georgia font for prompt label
	var georgia_font = load("res://Assets/georgia-2/georgia.ttf") as FontFile
	if prompt_label and georgia_font:
		prompt_label.add_theme_font_override("font", georgia_font)
		prompt_label.add_theme_font_size_override("font_size", 16)
		# Position label above the door and center it
		prompt_label.position = Vector2(-100, -50)  # Centered above door
		prompt_label.size = Vector2(200, 30)
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if prompt_label:
			if is_locked:
				prompt_label.text = "No trains running"
			else:
				prompt_label.text = "Press F to enter"
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
	if is_locked:
		print("Door is locked! Complete Handler dialogue first.")
		# Shake the door
		shake_door()
		return
	
	# Notify game state about train station visit
	GameState.visit_train_station()
	
	# Use smooth scene transition instead of direct scene change
	var scene_transition = get_tree().get_first_node_in_group("scene_transition")
	if scene_transition and scene_transition.has_method("start_scene_transition"):
		scene_transition.start_scene_transition(next_scene_path)
	else:
		# Fallback to direct scene change
		get_tree().change_scene_to_file(next_scene_path)

func shake_door():
	var tween = create_tween()
	var shake_intensity = 5.0
	var shake_duration = 0.5
	
	# Quick shake animation
	tween.tween_property(self, "position", original_position + Vector2(shake_intensity, 0), 0.05)
	tween.tween_property(self, "position", original_position + Vector2(-shake_intensity, 0), 0.05)
	tween.tween_property(self, "position", original_position + Vector2(shake_intensity, 0), 0.05)
	tween.tween_property(self, "position", original_position + Vector2(-shake_intensity, 0), 0.05)
	tween.tween_property(self, "position", original_position, 0.05)