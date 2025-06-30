extends Area2D

var is_alive: bool = true

func _ready():
	$Sprite2D.texture = preload("res://Assets/Antichrist_alive.png")

func _on_slash_hit(player):
	print("Antichrist: _on_slash_hit() called, is_alive=", is_alive)
	if is_alive:
		die()

func die():
	print("Antichrist: die() called, is_alive=", is_alive)
	if not is_alive:
		return
	
	is_alive = false
	$Sprite2D.texture = preload("res://Assets/Antichrist_dead.png")
	print("Antichrist: Texture changed to dead")
	
	GameState.kill_antichrist()
	print("Antichrist: GameState.kill_antichrist() called")
	
	# Show TARGET ELIMINATED message and teleport
	show_target_eliminated()

func show_target_eliminated():
	print("Antichrist: show_target_eliminated() called")
	
	# Create a CanvasLayer for the overlay to ensure it appears on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to appear on top
	get_tree().root.add_child(canvas_layer)
	
	# Create a control that fills the screen
	var control = Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(control)
	
	# Create the TARGET ELIMINATED label
	var label = Label.new()
	label.text = "TARGET ELIMINATED"
	label.modulate = Color(1.0, 0.0, 0.0, 0.0)  # Start with transparent red
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Use Georgia font with much larger size and 1.7x vertical stretch
	var georgia_font = load("res://Assets/georgia-2/georgia.ttf") as FontFile
	if georgia_font:
		label.add_theme_font_override("font", georgia_font)
		label.add_theme_font_size_override("font_size", 120)  # Much larger font
		print("Antichrist: Font applied successfully")
	else:
		print("Antichrist: Failed to load Georgia font")
	
	# Apply vertical stretch with center pivot
	var viewport_size = get_viewport().get_visible_rect().size
	label.pivot_offset = viewport_size / 2  # Set pivot to center of screen
	label.scale = Vector2(1.0, 1.7)  # 1.7x vertical stretch
	
	control.add_child(label)
	print("Antichrist: Label added to control")
	
	# Animate the text fade-in and fade-out
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5)  # Fade in
	tween.tween_interval(2.0)  # Stay visible for 2 seconds
	tween.tween_property(label, "modulate:a", 0.0, 0.5)  # Fade out
	tween.tween_callback(teleport_to_main)
	tween.tween_callback(canvas_layer.queue_free)  # Clean up canvas layer
	print("Antichrist: Tween animation started")

func teleport_to_main():
	print("Antichrist: Teleporting to Main using TeleportManager")
	TeleportManager.teleport_to_main()
