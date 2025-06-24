extends Node2D

var effects_manager
var game_ui

func _ready():
	# Create and setup effects manager (same as Main.gd)
	effects_manager = preload("res://EffectsManager.gd").new()
	add_child(effects_manager)
	effects_manager.add_to_group("effects_manager")
	
	# Create and setup game UI (same as Main.gd)
	game_ui = preload("res://GameUI.gd").new()
	add_child(game_ui)
	game_ui.add_to_group("game_ui")
	
	# Set up the camera for effects manager (deferred so effects manager _ready runs first)
	call_deferred("setup_camera")
	
	# Configure the train station door to go back to train station
	call_deferred("setup_train_station_door")
	
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
		print("Wyoming background music setup complete")

func setup_camera():
	# Find the player's camera instead of using a fixed scene camera
	var player = $Player
	if player and effects_manager:
		var player_camera = player.get_node("Camera2D")
		if player_camera:
			effects_manager.camera = player_camera
			effects_manager.original_camera_position = player_camera.position
			print("Wyoming camera set up for effects manager using player camera")

func setup_train_station_door():
	# Configure the door to go back to the train station
	var door = $TrainStationDoor
	if door:
		door.next_scene_path = "res://InterDimensionalTrainStation.tscn"
		print("Train station door configured to go back to train station")