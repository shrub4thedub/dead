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
	# Check if Antichrist has been killed to determine destination
	var exit_door = $ExitDoor
	
	if exit_door:
		if GameState.antichrist_is_dead:
			# After killing Antichrist, train goes back to main scene 
			exit_door.next_scene_path = "res://Main.tscn"
			print("Exit door now goes back to Main scene (Antichrist is dead)")
		else:
			# Before killing Antichrist, train goes to Wyoming
			exit_door.next_scene_path = "res://NewLevel.tscn"
			print("Exit door now goes to Wyoming")
