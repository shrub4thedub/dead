extends Node2D

var effects_manager
var game_ui
var title_screen
var title_logo
var title_text
var is_title_active = true
var is_returning_from_train = false

func _ready():
	# Add to main scene group
	add_to_group("main_scene")
	setup_game_state()
	setup_effects_system()
	
	# Check if we're returning from train station after Antichrist death
	is_returning_from_train = GameState.antichrist_is_dead and GameState.has_visited_train_station_after_antichrist
	var has_return_position = GameState.return_position != Vector2(0, 0)
	print("Main: is_returning_from_train=", is_returning_from_train, " antichrist_dead=", GameState.antichrist_is_dead, " visited_train=", GameState.has_visited_train_station_after_antichrist, " return_pos=", GameState.return_position)
	
	# Only show title screen on first load (not when returning from train or with return position)
	if not is_returning_from_train and not has_return_position:
		setup_title_screen()
	else:
		is_title_active = false
		# Position player based on return conditions
		if has_return_position:
			call_deferred("position_player_at_return_position")
		else:
			call_deferred("position_player_near_handler")
	
	connect_coin_signals()

func setup_effects_system():
	# Create effects manager
	effects_manager = preload("res://EffectsManager.gd").new()
	add_child(effects_manager)
	effects_manager.add_to_group("effects_manager")
	
	# Create game UI
	game_ui = preload("res://GameUI.gd").new()
	add_child(game_ui)
	game_ui.add_to_group("game_ui")
	
	# Set up debug UI reference for player
	var debug_ui_node = get_node("DebugUI")
	var player_node = get_node("Player")
	if debug_ui_node and player_node:
		player_node.debug_ui = debug_ui_node
		print("Main: Connected debug UI to player")
		
		# Ensure player can move (fix for teleportation movement freeze)
		if "can_move" in player_node:
			player_node.can_move = true
			print("Main: Player movement enabled")
	
	# Setup background music
	setup_background_music()

func setup_background_music():
	var bgm_player = get_node_or_null("BGM")
	if bgm_player:
		bgm_player.autoplay = true
		bgm_player.volume_db = -10.0
		# Make sure it loops
		if bgm_player.stream:
			bgm_player.stream.loop = true
		print("Background music setup complete")

func setup_title_screen():
	# Create title screen overlay
	title_screen = CanvasLayer.new()
	title_screen.layer = 100  # High layer to appear on top
	add_child(title_screen)
	
	# Create main container that fills the screen
	var container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(container)
	
	# Create background (semi-transparent to see game underneath)
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.3)  # Semi-transparent black
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(background)
	
	# Create logo container centered in screen
	var logo_container = Control.new()
	logo_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	logo_container.position.y -= 100  # Offset upward
	container.add_child(logo_container)
	
	# Create logo sprite
	title_logo = Sprite2D.new()
	title_logo.texture = load("res://Assets/Logo.PNG")
	title_logo.position = Vector2.ZERO  # Centered in container
	title_logo.scale = Vector2(0.3, 0.3)  # Smaller size
	logo_container.add_child(title_logo)
	
	# Create text container centered in screen
	var text_container = Control.new()
	text_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	text_container.position.y += 100  # Offset downward
	container.add_child(text_container)
	
	# Create "Click to Start" text
	title_text = Label.new()
	title_text.text = "Click to Start"
	var liberation_font = load("res://Assets/LiberationSans-BoldItalic.ttf") as FontFile
	title_text.add_theme_font_override("font", liberation_font)
	title_text.add_theme_font_size_override("font_size", 32)
	title_text.add_theme_color_override("font_color", Color.WHITE)
	title_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_text.scale = Vector2(1.0, 1.2)  # 1.2x vertical stretch
	title_text.position = Vector2(-100, -16)  # Center text relative to container
	text_container.add_child(title_text)
	
	# Add pulsing animation to text only
	var text_tween = create_tween()
	text_tween.set_loops()
	text_tween.tween_property(title_text, "modulate:a", 0.5, 1.0)
	text_tween.tween_property(title_text, "modulate:a", 1.0, 1.0)

func _input(event):
	if is_title_active and event is InputEventMouseButton and event.pressed:
		hide_title_screen()
	
	# Debug: Press Q to go to Wyoming level (debug builds only)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		teleport_to_wyoming()

func hide_title_screen():
	if title_screen and is_title_active:
		is_title_active = false
		
		# Simple sequential animation
		var tween = create_tween()
		
		# Logo grows quickly
		tween.tween_property(title_logo, "scale", Vector2(0.4, 0.4), 0.08)
		# Logo shrinks
		tween.tween_property(title_logo, "scale", Vector2(0.0, 0.0), 0.15)
		# Screen fades out
		tween.tween_property(title_screen, "modulate:a", 0.0, 0.2)
		# Clean up
		tween.tween_callback(func(): title_screen.queue_free())

func connect_coin_signals():
	# Find all coin nodes and connect their collected signals
	var coins = get_tree().get_nodes_in_group("coins")
	if coins.is_empty():
		# If no group, find coins by node name pattern
		coins = find_coins_in_scene(self)
	
	for coin in coins:
		if coin.has_signal("collected"):
			coin.collected.connect(_on_coin_collected)
			print("Main: Connected coin collection signal for ", coin.name)

func find_coins_in_scene(node: Node) -> Array:
	var coins = []
	for child in node.get_children():
		if child.name.begins_with("Coin"):
			coins.append(child)
		coins.append_array(find_coins_in_scene(child))
	return coins

func _on_coin_collected():
	print("Main: Coin collected!")
	if effects_manager:
		effects_manager.add_combo("cashgrab")

func setup_game_state():
	# GameState is now an autoload singleton, so no need to create it here
	pass

func position_player_near_handler():
	# Find the Handler and position player nearby
	var handler = get_tree().get_first_node_in_group("handler")
	var player = get_node_or_null("Player")
	
	if handler and player:
		# Position player to the left of the Handler
		player.global_position = handler.global_position + Vector2(-150, 0)
		print("Player positioned near Handler after train return")

func position_player_at_return_position():
	var player = get_node_or_null("Player")
	if player:
		player.global_position = GameState.return_position
		print("Player positioned at return position: ", GameState.return_position)
		# Clear the return position after using it
		GameState.return_position = Vector2(0, 0)

func teleport_to_wyoming():
	print("Main: Debug teleport to Wyoming using TeleportManager")
	TeleportManager.teleport_to_wyoming()
