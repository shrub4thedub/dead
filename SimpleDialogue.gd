extends Control

@onready var dialogue_text = $DialogueText

var is_showing = false
var current_dialogue_lines = []
var current_line_index = 0
var fish_position = Vector2.ZERO
var dialogue_timer = 0.0
var timeout_duration = 8.0
var current_speaker_name = ""
var interaction_distance = 150.0  # Distance to maintain camera zoom

# Simple camera zoom variables
var player_camera = null
var original_zoom = Vector2.ONE
var original_camera_position = Vector2.ZERO
var dialogue_zoom = Vector2(1.4, 1.4)
var camera_tween: Tween
var camera_positioned = false  # Flag to prevent double positioning

func _ready():
	add_to_group("dialogue_system")
	hide_dialogue()
	# Set LiberationSans Bold Italic font for dialogue text
	var liberation_font = load("res://Assets/LiberationSans-BoldItalic.ttf") as FontFile
	dialogue_text.add_theme_font_override("font", liberation_font)
	dialogue_text.scale = Vector2(1.0, 1.2)  # 1.2x vertical stretch
	# Find player camera
	call_deferred("find_player_camera")

func find_player_camera():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_nodes_in_group("player")
		if player.size() > 0:
			player = player[0]
	
	if player:
		for child in player.get_children():
			if child is Camera2D:
				player_camera = child
				original_zoom = player_camera.zoom
				original_camera_position = player_camera.position
				break

func _process(delta):
	if is_showing:
		dialogue_timer += delta
		if dialogue_timer >= timeout_duration:
			hide_dialogue()
		
		# Check distance to speaker - end dialogue if too far
		check_speaker_distance()

func start_conversation(name: String, lines: Array):
	# Find the speaker to get their position
	var speaker = null
	if name == "Fish":
		speaker = get_tree().get_first_node_in_group("fish")
	elif name == "Manager":
		speaker = get_tree().get_first_node_in_group("manager")
	elif name == "Handler":
		speaker = get_tree().get_first_node_in_group("handler")
	
	if speaker:
		fish_position = speaker.global_position
	
	current_dialogue_lines = lines
	current_line_index = 0
	current_speaker_name = name
	show_current_line(name)

func show_current_line(speaker_name: String = ""):
	if current_line_index < current_dialogue_lines.size():
		var current_text = current_dialogue_lines[current_line_index]
		dialogue_text.text = current_text
		
		# Position text above the speaker
		if fish_position != Vector2.ZERO:
			dialogue_text.position.x = fish_position.x - 200
			# Position based on speaker type and height
			if current_speaker_name == "Manager":
				dialogue_text.position.y = fish_position.y - 350  # Manager text moved up
			elif current_speaker_name == "Handler":
				dialogue_text.position.y = fish_position.y - 150  # Handler is smaller now
			else:
				dialogue_text.position.y = fish_position.y - 100  # Fish is shortest
		
		dialogue_text.visible = true
		is_showing = true
		dialogue_timer = 0.0  # Reset timer when showing new line
		
		# Camera zoom (only on first line, not for Manager)
		if current_line_index == 0 and not camera_positioned:
			if speaker_name != "Manager":
				zoom_only()
			camera_positioned = true
		
		# Notify the speaker to start speaking animation
		var speaker = null
		if fish_position != Vector2.ZERO:
			# Find which character is speaking based on the current speaker
			if current_speaker_name == "Fish":
				speaker = get_tree().get_first_node_in_group("fish")
			elif current_speaker_name == "Manager":
				speaker = get_tree().get_first_node_in_group("manager")
			elif current_speaker_name == "Handler":
				speaker = get_tree().get_first_node_in_group("handler")
		
		if speaker and speaker.has_method("start_speaking"):
			speaker.start_speaking(current_text)
	else:
		hide_dialogue()

func advance_dialogue():
	current_line_index += 1
	if current_line_index < current_dialogue_lines.size():
		show_current_line(current_speaker_name)
	else:
		hide_dialogue()

func hide_dialogue():
	dialogue_text.visible = false
	is_showing = false
	current_dialogue_lines.clear()
	current_line_index = 0
	dialogue_timer = 0.0
	camera_positioned = false  # Reset flag when dialogue ends
	
	# Camera zoom out (only if not Manager)
	if current_speaker_name != "Manager":
		zoom_out_only()
	
	# Notify the speaker that dialogue ended
	var speaker = null
	if fish_position != Vector2.ZERO:
		# Find which character was speaking
		if current_speaker_name == "Fish":
			speaker = get_tree().get_first_node_in_group("fish")
		elif current_speaker_name == "Manager":
			speaker = get_tree().get_first_node_in_group("manager")
		elif current_speaker_name == "Handler":
			speaker = get_tree().get_first_node_in_group("handler")
	
	if speaker and speaker.has_method("_on_dialogue_ended"):
		speaker._on_dialogue_ended()

func check_speaker_distance():
	if not is_showing:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var speaker = null
	if current_speaker_name == "Fish":
		speaker = get_tree().get_first_node_in_group("fish")
	elif current_speaker_name == "Manager":
		speaker = get_tree().get_first_node_in_group("manager")
	elif current_speaker_name == "Handler":
		speaker = get_tree().get_first_node_in_group("handler")
	
	if speaker:
		var distance = player.global_position.distance_to(speaker.global_position)
		if distance > interaction_distance:
			hide_dialogue()

func _input(event):
	if is_showing and event.is_action_pressed("interact"):
		advance_dialogue()

func zoom_only():
	if not player_camera:
		find_player_camera()
	
	if player_camera:
		# Kill any existing tween
		if camera_tween:
			camera_tween.kill()
		
		# ONLY zoom in, no position changes
		camera_tween = create_tween()
		camera_tween.tween_property(player_camera, "zoom", dialogue_zoom, 0.4)

func zoom_out_only():
	if not player_camera:
		return
	
	# Kill any existing tween
	if camera_tween:
		camera_tween.kill()
	
	# ONLY zoom out, no position changes
	camera_tween = create_tween()
	camera_tween.tween_property(player_camera, "zoom", original_zoom, 0.5)

func zoom_and_position_for_manager():
	if not player_camera:
		find_player_camera()
	
	if player_camera:
		# Kill any existing tween
		if camera_tween:
			camera_tween.kill()
		
		# Get current camera position (don't rely on stored original_camera_position)
		var current_camera_position = player_camera.position
		
		# Zoom in and move up for Manager
		camera_tween = create_tween()
		camera_tween.set_parallel(true)
		camera_tween.tween_property(player_camera, "zoom", dialogue_zoom, 0.4)
		
		var target_position = current_camera_position + Vector2(0, -50)
		camera_tween.tween_property(player_camera, "position", target_position, 0.4)

func zoom_out_and_reset_position():
	if not player_camera:
		return
	
	# Kill any existing tween
	if camera_tween:
		camera_tween.kill()
	
	# Get current position and move back down 50 pixels (reverse of the up movement)
	var current_camera_position = player_camera.position
	var reset_position = current_camera_position + Vector2(0, 50)
	
	# Zoom out and reset position
	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.tween_property(player_camera, "zoom", original_zoom, 0.5)
	camera_tween.tween_property(player_camera, "position", reset_position, 0.5)
