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
	
	# Setup key bulb system
	call_deferred("setup_key_system")

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

func setup_key_system():
	# Set up the key bulb group
	var group_name = "group1"
	
	# Configure key bulbs
	var key_bulb1 = get_node_or_null("KeyBulb1")
	var key_bulb2 = get_node_or_null("KeyBulb2")
	var key_bulb3 = get_node_or_null("KeyBulb3")
	
	if key_bulb1:
		key_bulb1.key_wall_group = group_name
	if key_bulb2:
		key_bulb2.key_wall_group = group_name
	if key_bulb3:
		key_bulb3.key_wall_group = group_name
	
	# Configure key wall
	var key_wall = get_node_or_null("KeyWall1")
	if key_wall:
		key_wall.group_name = group_name
		print("Key system configured - Group: ", group_name)