extends Node2D

var effects_manager
var game_ui
var train
var player
var is_train_sequence_active = false
var train_tween: Tween
var player_original_position: Vector2
var has_taken_train = false

func _ready():
	# Get references to nodes
	train = $Train
	player = $Player
	# Store player's original position
	player_original_position = player.position
	# Create and setup effects manager (same as Main.gd)
	effects_manager = preload("res://EffectsManager.gd").new()
	add_child(effects_manager)
	effects_manager.add_to_group("effects_manager")
	
	# Create and setup game UI (same as Main.gd)
	game_ui = preload("res://GameUI.gd").new()
	add_child(game_ui)
	game_ui.add_to_group("game_ui")
	
	# Set up the station camera for effects manager (deferred so effects manager _ready runs first)
	call_deferred("setup_station_camera")
	
	# Configure the exit door to go back to Main scene
	call_deferred("setup_exit_door")
	
	# Update exit door destination based on current state
	call_deferred("update_exit_door_destination")
	
	# Setup background music
	call_deferred("setup_background_music")

func setup_background_music():
	var bgm_player = get_node_or_null("BGM")
	if bgm_player:
		bgm_player.autoplay = true
		bgm_player.volume_db = -10.0
		# Make sure it loops
		if bgm_player.stream:
			bgm_player.stream.loop = true
		print("Train station background music setup complete")

func _input(event):
	# Q key teleport to Wyoming (debug builds only)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		print("Q key pressed - teleporting to Wyoming")
		teleport_to_wyoming()
		return
	
	# Also handle 1 key as backup (debug builds only)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_1:
		print("1 key pressed - teleporting to Wyoming")
		teleport_to_wyoming()
		return
	
	if event.is_action_pressed("interact") and not is_train_sequence_active:
		# Check if player is near the train (within interaction range)
		var distance_to_train = player.global_position.distance_to(train.global_position)
		if distance_to_train < 100:
			start_train_sequence()

func start_train_sequence():
	is_train_sequence_active = true
	player.can_move = false  # Disable player movement
	
	# Create tween for animations
	train_tween = create_tween()
	
	# Step 1: Player fades out (getting in train)
	train_tween.tween_property(player, "modulate:a", 0.0, 0.3)
	
	# Step 2: Move train off screen to the right
	train_tween.tween_property(train, "position:x", 1200, 1.2).set_delay(0.4).set_ease(Tween.EASE_IN)
	
	# Step 3: After train exits, move it to the left side off screen
	train_tween.tween_callback(move_train_to_left_side).set_delay(1.6)
	
	# Step 4: Bring train back from left side
	train_tween.tween_property(train, "position:x", train.position.x, 1.2).set_delay(1.8).set_ease(Tween.EASE_OUT)
	
	# Step 5: Player fades back in and immediately restore movement
	train_tween.tween_property(player, "modulate:a", 1.0, 0.3).set_delay(3.2)
	train_tween.tween_callback(end_train_sequence).set_delay(3.2)

func move_train_to_left_side():
	train.position.x = -1200  # Move train to left side off screen

func end_train_sequence():
	is_train_sequence_active = false
	has_taken_train = true  # Mark that player has taken the train
	player.can_move = true  # Re-enable player movement
	# Update the exit door to go to the new level
	update_exit_door_destination()

func setup_station_camera():
	# Override the effects manager's camera with our fixed station camera
	var station_camera = $StationCamera
	if station_camera and effects_manager:
		effects_manager.camera = station_camera
		effects_manager.original_camera_position = station_camera.position
		print("Station camera set up for effects manager")

func setup_exit_door():
	# Configure the exit door to go back to the main scene initially
	var exit_door = $ExitDoor
	if exit_door:
		exit_door.next_scene_path = "res://Main.tscn"
		print("Exit door configured to go to Main scene")

func update_exit_door_destination():
	# Determine where the exit door should go based on mission progress
	var exit_door = $ExitDoor
	
	if exit_door:
		if has_taken_train and not GameState.antichrist_is_dead:
			# After taking train but before killing Antichrist, go to Wyoming
			exit_door.next_scene_path = "res://NewLevel.tscn"
			print("Exit door goes to Wyoming (train taken, Antichrist alive)")
		elif has_taken_train and GameState.antichrist_is_dead:
			# After taking train and killing Antichrist, go back to Main
			exit_door.next_scene_path = "res://Main.tscn"
			print("Exit door goes back to Main (train taken, Antichrist dead)")
		else:
			# Before taking train, stay at Main scene
			exit_door.next_scene_path = "res://Main.tscn"
			print("Exit door goes to Main (train not taken)")

func teleport_to_wyoming():
	print("Teleporting to Wyoming (stopping all tweens first)")
	
	# Stop any active tweens that might be blocking scene change
	if train_tween:
		train_tween.kill()
	
	# Stop any other tweens in the scene
	var all_tweens = get_tree().get_nodes_in_group("tween")
	for tween in all_tweens:
		if tween and tween.has_method("kill"):
			tween.kill()
	
	# Re-enable player movement in case it was disabled
	if player:
		player.can_move = true
	
	# Use call_deferred to ensure scene change happens after current frame
	call_deferred("_do_scene_change")

func _do_scene_change():
	print("Actually changing scene now")
	var error = get_tree().change_scene_to_file("res://Wyoming.tscn")
	if error != OK:
		print("ERROR: Failed to change scene: ", error)
		print("Error code ", error, " - trying fallback")
		# Try with call_deferred again as last resort
		get_tree().call_deferred("change_scene_to_file", "res://Wyoming.tscn")
	else:
		print("Scene change initiated successfully")
