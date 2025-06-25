extends CanvasLayer
class_name GameUI

# UI elements
@onready var combo_counter: Label
@onready var combo_level_label: Label
@onready var speed_indicator: Label
@onready var speed_multiplier_label: Label
@onready var last_move_label: Label
@onready var trajectory_line: Line2D
@onready var screen_overlay: ColorRect
@onready var status_container: VBoxContainer
@onready var status_messages: Array

# Ground time indicator removed

# Combo system
var combo_scale_tween: Tween
var combo_fade_tween: Tween
var combo_shake_tween: Tween
var combo_level_base_position: Vector2

# Screen effects
var screen_flash_tween: Tween

# Status text
var status_text_tweens: Array
const MAX_STATUS_MESSAGES = 5

func _ready():
	setup_ui_elements()
	
	# Connect to effects manager
	var effects_manager = get_tree().get_first_node_in_group("effects_manager")
	if effects_manager:
		effects_manager.combo_updated.connect(_on_combo_updated)
		effects_manager.combo_move_updated.connect(_on_combo_move_updated)

func setup_ui_elements():
	# Load Georgia font
	var georgia_font = load("res://Assets/georgia-2/georgia.ttf") as FontFile
	
	# Reverse dash UI removed
	
	# Combo counter - moved up
	combo_counter = Label.new()
	add_child(combo_counter)
	combo_counter.text = "0"
	combo_counter.position = Vector2(20, 20)
	combo_counter.add_theme_font_override("font", georgia_font)
	combo_counter.add_theme_font_size_override("font_size", 32)
	combo_counter.add_theme_color_override("font_color", Color.WHITE)
	combo_counter.modulate.a = 0.0
	combo_counter.visible = true
	
	# Combo level label - moved up
	combo_level_label = Label.new()
	add_child(combo_level_label)
	combo_level_label.text = ""
	combo_level_label.position = Vector2(20, 60)
	combo_level_base_position = combo_level_label.position  # Store base position for shaking
	combo_level_label.add_theme_font_override("font", georgia_font)
	combo_level_label.add_theme_font_size_override("font_size", 24)
	combo_level_label.add_theme_color_override("font_color", Color.YELLOW)
	combo_level_label.modulate.a = 0.0
	combo_level_label.visible = true
	
	# Speed indicator - moved up
	speed_indicator = Label.new()
	add_child(speed_indicator)
	speed_indicator.text = "0"
	speed_indicator.position = Vector2(20, 100)
	speed_indicator.add_theme_font_override("font", georgia_font)
	speed_indicator.add_theme_font_size_override("font_size", 20)
	speed_indicator.add_theme_color_override("font_color", Color.GREEN)
	speed_indicator.visible = true
	
	# Speed multiplier indicator - moved up
	speed_multiplier_label = Label.new()
	add_child(speed_multiplier_label)
	speed_multiplier_label.text = "1.0x"
	speed_multiplier_label.position = Vector2(20, 125)
	speed_multiplier_label.add_theme_font_override("font", georgia_font)
	speed_multiplier_label.add_theme_font_size_override("font_size", 18)
	speed_multiplier_label.add_theme_color_override("font_color", Color.CYAN)
	speed_multiplier_label.visible = true
	
	# Last combo move indicator - moved up
	last_move_label = Label.new()
	add_child(last_move_label)
	last_move_label.text = ""
	last_move_label.position = Vector2(20, 150)
	last_move_label.add_theme_font_override("font", georgia_font)
	last_move_label.add_theme_font_size_override("font_size", 16)
	last_move_label.add_theme_color_override("font_color", Color.YELLOW)
	last_move_label.visible = true
	
	# Trajectory line
	trajectory_line = Line2D.new()
	add_child(trajectory_line)
	trajectory_line.default_color = Color(1, 1, 1, 0.5)
	trajectory_line.width = 3.0
	trajectory_line.z_index = 10
	
	# Screen overlay for flash effects
	screen_overlay = ColorRect.new()
	add_child(screen_overlay)
	screen_overlay.color = Color.WHITE
	screen_overlay.modulate.a = 0.0
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Status text container - top right corner
	status_container = VBoxContainer.new()
	add_child(status_container)
	status_container.alignment = BoxContainer.ALIGNMENT_END  # Align to bottom of container
	status_messages = []
	status_text_tweens = []
	
	# Use anchors for proper fullscreen handling
	status_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status_container.anchor_left = 1.0
	status_container.anchor_right = 1.0
	status_container.anchor_top = 0.0
	status_container.anchor_bottom = 0.0
	status_container.offset_left = -300  # 300px from right edge
	status_container.offset_top = 5      # 5px from top (even higher)
	status_container.offset_right = -20  # 20px margin from right edge
	status_container.offset_bottom = 160 # 150px height
	
	# Connect to viewport size changes for fullscreen handling
	get_viewport().size_changed.connect(position_status_container)

# Reverse dash UI removed

func update_speed(speed: float):
	speed_indicator.text = str(int(speed))
	
	# Update speed multiplier display
	var multiplier = 1.0
	if speed >= 2000.0:
		multiplier = 2.0
		speed_multiplier_label.add_theme_color_override("font_color", Color.RED)
	elif speed >= 1200.0:
		multiplier = 1.5
		speed_multiplier_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		multiplier = 1.0
		speed_multiplier_label.add_theme_color_override("font_color", Color.CYAN)
	
	speed_multiplier_label.text = str(multiplier) + "x"
	
	# Change color based on speed
	if speed > 600:
		speed_indicator.add_theme_color_override("font_color", Color.RED)
	elif speed > 400:
		speed_indicator.add_theme_color_override("font_color", Color.ORANGE)
	elif speed > 200:
		speed_indicator.add_theme_color_override("font_color", Color.YELLOW)
	else:
		speed_indicator.add_theme_color_override("font_color", Color.GREEN)


func _on_combo_updated(combo_count: int, combo_level: String):
	# Update combo counter
	combo_counter.text = str(combo_count)
	
	# Show/hide combo elements
	if combo_count > 0:
		combo_counter.modulate.a = 1.0
		combo_level_label.modulate.a = 1.0
		
		# Animate combo counter
		if combo_scale_tween:
			combo_scale_tween.kill()
		combo_scale_tween = create_tween()
		combo_scale_tween.tween_property(combo_counter, "scale", Vector2(1.2, 1.2), 0.1)
		combo_scale_tween.tween_property(combo_counter, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		# Fade out combo elements
		if combo_fade_tween:
			combo_fade_tween.kill()
		combo_fade_tween = create_tween()
		combo_fade_tween.tween_property(combo_counter, "modulate:a", 0.0, 0.5)
		combo_fade_tween.tween_property(combo_level_label, "modulate:a", 0.0, 0.5)
	
	# Update combo level
	if combo_level != "none":
		combo_level_label.text = combo_level.to_upper()
		
		# Set color based on level (grey, white, green, yellow, blue, purple, orange)
		match combo_level:
			"dead":          # 0-9 points
				combo_level_label.add_theme_color_override("font_color", Color.GRAY)
				stop_morbid_shake()
			"asleep":        # 10-19 points  
				combo_level_label.add_theme_color_override("font_color", Color.WHITE)
				stop_morbid_shake()
			"boring":        # 20-29 points
				combo_level_label.add_theme_color_override("font_color", Color.GREEN)
				stop_morbid_shake()
			"average":       # 30-39 points
				combo_level_label.add_theme_color_override("font_color", Color.YELLOW)
				stop_morbid_shake()
			"criminal":      # 40-49 points
				combo_level_label.add_theme_color_override("font_color", Color.BLUE)
				stop_morbid_shake()
			"sickening":     # 50-59 points
				combo_level_label.add_theme_color_override("font_color", Color.MAGENTA)  # Purple
				stop_morbid_shake()
			"disgusting":    # 60-69 points
				combo_level_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))  # Orange
				stop_morbid_shake()
			"morbid":        # 70+ points - Ultimate level
				combo_level_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.0))  # Bright Orange/Red
				start_morbid_shake()
			_:
				stop_morbid_shake()
	else:
		combo_level_label.text = ""
		stop_morbid_shake()

func _on_combo_move_updated(move_name: String, speed_multiplier: float):
	# Convert move names to readable text
	var display_name = ""
	match move_name:
		"roll":
			display_name = "ROLL"
		"roll_leap":
			display_name = "ROLL LEAP"
		"reverse_dash":
			display_name = "REVERSE DASH"
		"turn_boost":
			display_name = "TURN BOOST"
		"air_dash":
			display_name = "AIR DASH"
		"wall_kick":
			display_name = "WALL KICK"
		"dash_replenish":
			display_name = "DASH REPLENISH"
		"smash":
			display_name = "SMASH"
		"speedbreak":
			display_name = "SPEEDBREAK"
		"cashgrab":
			display_name = "CASHGRAB"
		_:
			display_name = move_name.to_upper()
	
	last_move_label.text = display_name
	
	# Color based on multiplier
	if speed_multiplier >= 2.0:
		last_move_label.add_theme_color_override("font_color", Color.RED)
	elif speed_multiplier >= 1.5:
		last_move_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		last_move_label.add_theme_color_override("font_color", Color.YELLOW)

func show_trajectory(start_pos: Vector2, end_pos: Vector2, arc_height: float = 0.0):
	# Disabled - no more white trajectory lines
	pass

func hide_trajectory():
	# Disabled - no more white trajectory lines  
	pass

func screen_flash(color: Color, duration: float):
	screen_overlay.color = color
	
	if screen_flash_tween:
		screen_flash_tween.kill()
	
	screen_flash_tween = create_tween()
	screen_flash_tween.tween_property(screen_overlay, "modulate:a", 0.6, 0.05)
	screen_flash_tween.tween_property(screen_overlay, "modulate:a", 0.0, duration - 0.05)

func highlight_surface(surface_position: Vector2, surface_size: Vector2, color: Color = Color.GREEN):
	var highlight = ColorRect.new()
	add_child(highlight)
	highlight.color = color
	highlight.modulate.a = 0.3
	highlight.position = surface_position
	highlight.size = surface_size
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Auto-fade after 1 second
	var fade_tween = create_tween()
	fade_tween.tween_property(highlight, "modulate:a", 0.0, 1.0)
	fade_tween.tween_callback(highlight.queue_free)

func start_morbid_shake():
	# Stop any existing shake
	if combo_shake_tween:
		combo_shake_tween.kill()
	
	# Create continuous wave shaking effect
	combo_shake_tween = create_tween()
	combo_shake_tween.set_loops()
	
	# Create a wave pattern with varying intensity
	var shake_duration = 0.08
	var shake_intensity = 3.0
	
	# Wave shake: left, up, right, down, with slight randomness
	combo_shake_tween.tween_method(apply_wave_shake, 0.0, 2.0 * PI, shake_duration * 8)

func apply_wave_shake(wave_progress: float):
	# Create a wave-based shake pattern
	var shake_x = sin(wave_progress * 3) * 3.0 + randf_range(-1, 1)
	var shake_y = cos(wave_progress * 4) * 2.5 + randf_range(-1, 1)
	combo_level_label.position = combo_level_base_position + Vector2(shake_x, shake_y)

func stop_morbid_shake():
	if combo_shake_tween:
		combo_shake_tween.kill()
		combo_shake_tween = null
	# Reset position to base
	combo_level_label.position = combo_level_base_position


func position_status_container():
	# Refresh anchors for fullscreen changes - anchors should handle positioning automatically
	# This function is called when viewport size changes
	pass

func show_status_text(text: String, color: Color = Color.WHITE):
	# Load Georgia font
	var georgia_font = load("res://Assets/georgia-2/georgia.ttf") as FontFile
	
	# Create new status message label
	var status_label = Label.new()
	status_label.text = text
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_override("font", georgia_font)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", color)
	status_label.modulate.a = 0.0
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Add to container and arrays
	status_container.add_child(status_label)
	status_messages.append(status_label)
	
	# Remove oldest message if we exceed max
	if status_messages.size() > MAX_STATUS_MESSAGES:
		var oldest_label = status_messages[0]
		status_messages.remove_at(0)
		# Clean up corresponding tween if it exists
		if status_text_tweens.size() > 0:
			var oldest_tween = status_text_tweens[0]
			if oldest_tween:
				oldest_tween.kill()
			status_text_tweens.remove_at(0)
		oldest_label.queue_free()
	
	# Create fade in/out sequence for new message
	var message_tween = create_tween()
	status_text_tweens.append(message_tween)
	message_tween.tween_property(status_label, "modulate:a", 1.0, 0.5)  # Fade in over 0.5s
	message_tween.tween_property(status_label, "modulate:a", 1.0, 19.0)  # Stay visible for 19s
	message_tween.tween_property(status_label, "modulate:a", 0.0, 0.5)  # Fade out over 0.5s
	
	# Clean up when tween finishes
	message_tween.finished.connect(_on_status_message_finished.bind(status_label, message_tween))

func _on_status_message_finished(status_label: Label, message_tween: Tween):
	if status_label and is_instance_valid(status_label):
		status_messages.erase(status_label)
		status_label.queue_free()
	status_text_tweens.erase(message_tween)