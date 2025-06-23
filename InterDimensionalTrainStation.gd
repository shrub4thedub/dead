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
	
	# Set up the station camera for effects manager (deferred so effects manager _ready runs first)
	call_deferred("setup_station_camera")
	
	# Configure the exit door to go back to Main scene
	call_deferred("setup_exit_door")

func setup_station_camera():
	# Override the effects manager's camera with our fixed station camera
	var station_camera = $StationCamera
	if station_camera and effects_manager:
		effects_manager.camera = station_camera
		effects_manager.original_camera_position = station_camera.position
		print("Station camera set up for effects manager")

func setup_exit_door():
	# Configure the exit door to go back to the main scene
	var exit_door = $ExitDoor
	if exit_door:
		exit_door.next_scene_path = "res://Main.tscn"
		print("Exit door configured to go to Main scene")
