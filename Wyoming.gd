extends Node2D

var effects_manager
var game_ui

func _ready():
	# Add to Wyoming scene group
	add_to_group("wyoming_scene")
	setup_effects_system()
	setup_key_door_system()

func setup_effects_system():
	# Create effects manager
	effects_manager = preload("res://EffectsManager.gd").new()
	add_child(effects_manager)
	effects_manager.add_to_group("effects_manager")
	
	# Create game UI
	game_ui = preload("res://GameUI.gd").new()
	add_child(game_ui)
	game_ui.add_to_group("game_ui")
	
	# Ensure player can move (fix for teleportation movement freeze)
	var player_node = get_node_or_null("Player")
	if player_node and "can_move" in player_node:
		player_node.can_move = true
		print("Wyoming: Player movement enabled")
	
	print("Wyoming: Effects system setup complete")

func setup_key_door_system():
	# Configure original KeyWall to require only 2 keys instead of 3
	var keywall = get_node_or_null("KeyWall")
	if keywall:
		keywall.required_keys = 2
		keywall.group_name = "keywall1"
		print("Wyoming: KeyWall configured to require 2 keys out of 3")
	
	# Configure KeyWall2 (requires KeyBulb4)
	var keywall2 = get_node_or_null("KeyWall2")
	if keywall2:
		keywall2.required_keys = 1
		keywall2.group_name = "keywall2"
		print("Wyoming: KeyWall2 configured to require 1 key")
	
	# Configure KeyWall3 (requires KeyBulb5)
	var keywall3 = get_node_or_null("KeyWall3")
	if keywall3:
		keywall3.required_keys = 1
		keywall3.group_name = "keywall3"
		print("Wyoming: KeyWall3 configured to require 1 key")
	
	print("Wyoming: Key-wall system setup complete")

func _input(event):
	# Q key teleport back to main scene (debug builds only)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		teleport_to_main()

func teleport_to_main():
	print("Wyoming: Debug teleport to Main using TeleportManager")
	TeleportManager.teleport_to_main()