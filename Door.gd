extends Area2D

@onready var prompt_label = $PromptLabel
var player_nearby = false
var next_scene_path = "res://InterDimensionalTrainStation.tscn"
var is_locked = false
var original_position: Vector2

# Key system properties
var required_keys = 0  # 0 means no key requirement (original door behavior)
var activated_keys = 0
var key_group = ""  # Which key bulbs this door accepts

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
	
	# Connect to key bulb system if this door requires keys
	if required_keys > 0:
		call_deferred("connect_to_key_bulbs")
		is_locked = true  # Start locked if keys are required

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if prompt_label:
			if is_locked:
				if required_keys > 0:
					prompt_label.text = "Collect " + str(required_keys - activated_keys) + " key(s)"
				else:
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
		print("Door: Using scene transition system")
		scene_transition.start_scene_transition(next_scene_path)
	else:
		print("Door: Using fallback direct scene change")
		# Fallback to direct scene change with error handling
		var error = get_tree().change_scene_to_file(next_scene_path)
		if error != OK:
			print("Door: ERROR - Failed to change scene: ", error)
		else:
			print("Door: Direct scene change successful")

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

func connect_to_key_bulbs():
	# Find all key bulbs and connect to their activation signal
	var key_bulbs = get_tree().get_nodes_in_group("key_bulbs")
	for bulb in key_bulbs:
		if bulb.has_signal("key_bulb_activated"):
			bulb.key_bulb_activated.connect(_on_key_bulb_activated)

func _on_key_bulb_activated(bulb_group):
	# Only accept keys from our specific group (or if key_group is empty, accept any)
	if key_group == "" or bulb_group == key_group:
		activated_keys += 1
		print("Door progress: ", activated_keys, "/", required_keys)
		
		if activated_keys >= required_keys:
			unlock_door()
		
		# Update prompt text if player is nearby
		if player_nearby and prompt_label:
			if is_locked:
				prompt_label.text = "Collect " + str(required_keys - activated_keys) + " key(s)"

func unlock_door():
	if not is_locked:
		return
	
	is_locked = false
	print("Door unlocked!")
	
	# Update prompt text if player is nearby
	if player_nearby and prompt_label:
		prompt_label.text = "Press F to enter"