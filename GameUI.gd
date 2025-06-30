extends CanvasLayer
class_name GameUI

# UI elements
@onready var speed_indicator: Label
@onready var trajectory_line: Line2D
@onready var screen_overlay: ColorRect
@onready var status_container: VBoxContainer
@onready var status_messages: Array
@onready var metacube_animation: MetaCubeAnimation

# New combo system - dynamic positioning
var current_combo_label: Label
var combo_labels_pool: Array[Label] = []
var move_name_labels_pool: Array[Label] = []

# Track visible labels to limit to 2 max for combo numbers
var visible_combo_labels: Array[Label] = []
var visible_move_labels: Array[Label] = []
const MAX_VISIBLE_LABELS = 3
const MAX_VISIBLE_COMBO_LABELS = 2  # Only 2 combo numbers max

# Track previous combo count and multiplier for flash-scroll effect
var last_combo_count = 0
var last_multiplier = 1.0

# Track speed for dynamic indicator
var last_speed_tier = 0  # Track which 500-unit tier we're in
var current_speed_label: Label = null  # Currently active speed label

# Ground time indicator removed

# Combo system
var combo_tweens: Array[Tween] = []

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
	
	# Initialize combo label pools
	setup_combo_label_pools(georgia_font)
	
	# Speed indicator removed - now dynamic on MetaCube
	
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
	
	# Create MetaCube animation behind combo UI
	metacube_animation = MetaCubeAnimation.new()
	add_child(metacube_animation)
	# Position it behind the combo UI area with proper z-index
	metacube_animation.z_index = -10  # Ensure it's behind all UI elements
	
	# Adjust animation based on combo activity
	metacube_animation.set_animation_speed(0.12)  # Slower default speed

func setup_combo_label_pools(georgia_font: FontFile):
	# Create a pool of labels for combo numbers and move names
	for i in range(10):  # Pool of 10 labels should be enough
		# Combo counter labels
		var combo_label = Label.new()
		add_child(combo_label)
		combo_label.add_theme_font_override("font", georgia_font)
		combo_label.add_theme_font_size_override("font_size", 48)
		combo_label.add_theme_color_override("font_color", Color.WHITE)
		combo_label.visible = false
		combo_label.z_index = 5  # Above MetaCube but below other UI
		combo_label.scale = Vector2(1.0, 1.7)  # Vertical stretch effect
		combo_labels_pool.append(combo_label)
		
		# Move name labels
		var move_label = Label.new()
		add_child(move_label)
		move_label.add_theme_font_override("font", georgia_font)
		move_label.add_theme_font_size_override("font_size", 18)
		move_label.add_theme_color_override("font_color", Color.WHITE)
		move_label.visible = false
		move_label.z_index = 5  # Above MetaCube but below other UI
		move_label.scale = Vector2(1.0, 1.7)  # Vertical stretch effect
		move_name_labels_pool.append(move_label)

func get_random_metacube_position() -> Vector2:
	# Get a random position within the MetaCube area, positioned higher so text can scroll down
	# MetaCube is at (168, 168) with scale 1.5, so 336x336 pixels
	# Generate random position within that area, but start higher to allow for scrolling
	var metacube_center = Vector2(168, 168)
	var metacube_size = 336  # 224 * 1.5
	var half_size = metacube_size / 2
	
	var random_x = randf_range(metacube_center.x - half_size + 50, metacube_center.x + half_size - 50)
	# Sweet spot - start slightly higher so text can scroll down and sometimes off the cube
	var random_y = randf_range(metacube_center.y - half_size + 20, metacube_center.y + half_size - 80)
	
	return Vector2(random_x, random_y)

func show_combo_number(combo_count: int, previous_count: int = -1, multiplier: float = 1.0):
	# Check for milestone messages (in order of importance - highest first)
	if combo_count >= 200 and previous_count < 200:
		show_fucking_insane_message()
		return  # Don't show regular combo number for this milestone
	elif combo_count >= 100 and previous_count < 100:
		show_holy_shit_message()
		return  # Don't show regular combo number for this milestone
	elif combo_count >= 80 and previous_count < 80:
		show_disgusting_message()
		return  # Don't show regular combo number for this milestone
	elif combo_count >= 50 and previous_count < 50:
		show_sickening_message()
		return  # Don't show regular combo number for this milestone
	elif combo_count >= 20 and previous_count < 20:
		show_criminal_message()
		return  # Don't show regular combo number for this milestone
	
	# Enforce max 2 visible combo labels
	if visible_combo_labels.size() >= MAX_VISIBLE_COMBO_LABELS:
		# Hide the oldest combo label
		var oldest_label = visible_combo_labels[0]
		oldest_label.visible = false
		visible_combo_labels.remove_at(0)
	
	# Find an available combo label
	var combo_label: Label = null
	for label in combo_labels_pool:
		if not label.visible:
			combo_label = label
			break
	
	if not combo_label:
		return  # No available labels
	
	# Set up new combo label
	current_combo_label = combo_label
	combo_label.scale = Vector2(1.0, 1.7)  # Keep vertical stretch
	combo_label.visible = true
	combo_label.modulate.a = 1.0
	
	# Add to visible tracking
	visible_combo_labels.append(combo_label)
	
	var base_position = get_random_metacube_position()
	var tween = create_tween()
	combo_tweens.append(tween)
	
	# Check if we need flash-scroll effect for multiplier
	if multiplier > 1.0 and previous_count >= 0:
		var points_gained = combo_count - previous_count
		var scroll_distance = 82  # Full text height with stretch (48px font × 1.7 stretch)
		
		# Set initial position and text
		combo_label.position = base_position
		combo_label.text = str(previous_count + 1)
		
		# Flash through each number gained - all numbers stay visible
		for i in range(points_gained):
			var current_number = previous_count + i + 1
			var current_position = base_position + Vector2(0, scroll_distance * i)
			
			# Move to position and set text immediately
			tween.tween_property(combo_label, "position", current_position, 0.0)
			tween.tween_callback(func(num = current_number): combo_label.text = str(num))
			tween.tween_property(combo_label, "modulate:a", 1.0, 0.0)
			tween.tween_property(combo_label, "modulate:a", 1.0, 0.1)
			
			# Add 0.05s blank between each number (except for the last one)
			if i < points_gained - 1:
				tween.tween_property(combo_label, "modulate:a", 0.0, 0.0)
				tween.tween_property(combo_label, "modulate:a", 0.0, 0.05)
		
		# Final number stays visible for much longer
		tween.tween_property(combo_label, "modulate:a", 1.0, 3.0)  # Stay visible for 3 seconds
		tween.tween_property(combo_label, "modulate:a", 0.0, 0.2)  # Fade out
	else:
		# Normal single number display
		combo_label.text = str(combo_count)
		combo_label.position = base_position
		
		# Stay visible for longer duration
		tween.tween_property(combo_label, "modulate:a", 1.0, 3.0)  # Stay visible for 3 seconds
		tween.tween_property(combo_label, "modulate:a", 0.0, 0.2)  # Fade out
	
	tween.tween_callback(func(): 
		combo_label.visible = false
		visible_combo_labels.erase(combo_label)
	)

func show_move_name(move_name: String, is_staled: bool = false):
	# Enforce max 3 visible move labels
	if visible_move_labels.size() >= MAX_VISIBLE_LABELS:
		# Hide the oldest move label
		var oldest_label = visible_move_labels[0]
		oldest_label.visible = false
		visible_move_labels.remove_at(0)
	
	# Find an available move label
	var move_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			move_label = label
			break
	
	if not move_label:
		return  # No available labels
	
	# Convert move names to readable text
	var display_name = ""
	match move_name:
		"roll":
			display_name = "ROLL"
		"roll_leap":
			display_name = "LEAP"
		"reverse_dash":
			display_name = "REVERSE"
		"turn_boost":
			display_name = "REVERSE"
		"air_dash":
			display_name = "DASH"
		"wall_kick":
			display_name = "KICK"
		"wall_bounce":
			display_name = "RICOCHET"
		"bounce_tile":
			display_name = "BOUNCE"
		"bub_destroy":
			display_name = "KILL"
		"dash_replenish":
			display_name = "ORB"
		"smash":
			display_name = "ORB"
		"speedbreak":
			display_name = "SPEEDBREAK"
		"cashgrab":
			display_name = "CASHGRAB"
		_:
			display_name = move_name.to_upper()
	
	# Override with STALED if move is staled
	if is_staled:
		display_name = "STALED"
		move_label.add_theme_color_override("font_color", Color.RED)
	else:
		move_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Set up move label
	move_label.text = display_name
	var base_position = get_random_metacube_position()
	move_label.position = base_position
	move_label.visible = true
	move_label.modulate.a = 1.0
	
	# Add to visible tracking
	visible_move_labels.append(move_label)
	
	# Create flicker animation - 5 flashes over 1 second
	var tween = create_tween()
	combo_tweens.append(tween)
	
	# Flash 3 times - 0.1s visible, 0.05s blank between each
	var scroll_distance = 31  # Text height equivalent
	
	for i in range(3):
		var current_position = base_position + Vector2(0, scroll_distance * i)
		
		# Show at current position for 0.1s
		tween.tween_property(move_label, "position", current_position, 0.0)
		tween.tween_property(move_label, "modulate:a", 1.0, 0.0)
		tween.tween_property(move_label, "modulate:a", 1.0, 0.1)
		
		# Add 0.05s blank (invisible) between each flash
		if i < 2:  # Don't add blank after the last flash
			tween.tween_property(move_label, "modulate:a", 0.0, 0.0)
			tween.tween_property(move_label, "modulate:a", 0.0, 0.05)
	
	# Final cleanup
	tween.tween_callback(func(): 
		move_label.visible = false
		visible_move_labels.erase(move_label)
	)

func show_combo_dead():
	# Find an available move label for combo dead message
	var dead_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			dead_label = label
			break
	
	if not dead_label:
		return  # No available labels
	
	# Set up combo dead message
	dead_label.text = "COMBO DEAD"
	dead_label.add_theme_color_override("font_color", Color.RED)
	dead_label.position = get_random_metacube_position()
	dead_label.visible = true
	dead_label.modulate.a = 1.0
	
	# Animate the combo dead message - stay visible longer
	var tween = create_tween()
	combo_tweens.append(tween)
	
	tween.tween_property(dead_label, "modulate:a", 1.0, 0.0)  # Stay visible
	tween.tween_property(dead_label, "modulate:a", 0.0, 0.4).set_delay(1.0)  # Fade out after 1s
	tween.tween_callback(func(): dead_label.visible = false)

func show_multiplier_change(multiplier: float):
	# Store the new multiplier for combo number flash-scroll calculations
	last_multiplier = multiplier
	
	# Enforce max 3 visible move labels (multiplier uses move label pool)
	if visible_move_labels.size() >= MAX_VISIBLE_LABELS:
		# Hide the oldest move label
		var oldest_label = visible_move_labels[0]
		oldest_label.visible = false
		visible_move_labels.remove_at(0)
	
	# Find an available move label
	var multiplier_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			multiplier_label = label
			break
	
	if not multiplier_label:
		return  # No available labels
	
	# Set up multiplier label with color based on multiplier value
	multiplier_label.text = str(multiplier) + "x"
	if multiplier >= 3.0:
		multiplier_label.add_theme_color_override("font_color", Color.MAGENTA)
	elif multiplier >= 2.0:
		multiplier_label.add_theme_color_override("font_color", Color.RED)
	else:
		multiplier_label.add_theme_color_override("font_color", Color.CYAN)
	
	# Set up animation
	var base_position = get_random_metacube_position()
	multiplier_label.position = base_position
	multiplier_label.visible = true
	multiplier_label.modulate.a = 1.0
	
	# Add to visible tracking
	visible_move_labels.append(multiplier_label)
	
	# Create the same flash-scroll animation as move names
	var tween = create_tween()
	combo_tweens.append(tween)
	
	# Flash 3 times - 0.1s visible, 0.05s blank between each
	var scroll_distance = 31  # Text height equivalent
	
	for i in range(3):
		var current_position = base_position + Vector2(0, scroll_distance * i)
		
		# Show at current position for 0.1s
		tween.tween_property(multiplier_label, "position", current_position, 0.0)
		tween.tween_property(multiplier_label, "modulate:a", 1.0, 0.0)
		tween.tween_property(multiplier_label, "modulate:a", 1.0, 0.1)
		
		# Add 0.05s blank (invisible) between each flash
		if i < 2:  # Don't add blank after the last flash
			tween.tween_property(multiplier_label, "modulate:a", 0.0, 0.0)
			tween.tween_property(multiplier_label, "modulate:a", 0.0, 0.05)
	
	# Final cleanup
	tween.tween_callback(func(): 
		multiplier_label.visible = false
		visible_move_labels.erase(multiplier_label)
	)

func show_holy_shit_message():
	# Find an available move label for the holy shit message
	var holy_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			holy_label = label
			break
	
	if not holy_label:
		return  # No available labels
	
	# Set up holy shit message with large red text
	holy_label.text = "HOLY SHIT!!!"
	holy_label.add_theme_color_override("font_color", Color.RED)
	holy_label.add_theme_font_size_override("font_size", 72)  # Much larger font
	holy_label.scale = Vector2(1.0, 1.7)  # Keep vertical stretch
	holy_label.visible = true
	holy_label.modulate.a = 1.0
	
	# Start from top of MetaCube area
	var metacube_center = Vector2(168, 168)
	var start_position = Vector2(metacube_center.x, metacube_center.y - 200)  # Start above MetaCube
	holy_label.position = start_position
	
	# Create dramatic flash-scroll animation across the entire MetaCube
	var tween = create_tween()
	combo_tweens.append(tween)
	
	# Flash 5 times scrolling down across the MetaCube
	var scroll_distance = 100  # Large distance for dramatic effect
	
	for i in range(5):
		var current_position = start_position + Vector2(0, scroll_distance * i)
		
		# Show at current position for 0.15s (slightly longer for impact)
		tween.tween_property(holy_label, "position", current_position, 0.0)
		tween.tween_property(holy_label, "modulate:a", 1.0, 0.0)
		tween.tween_property(holy_label, "modulate:a", 1.0, 0.15)
		
		# Add 0.05s blank between each flash
		if i < 4:  # Don't add blank after the last flash
			tween.tween_property(holy_label, "modulate:a", 0.0, 0.0)
			tween.tween_property(holy_label, "modulate:a", 0.0, 0.05)
	
	# Final cleanup and reset font size
	tween.tween_callback(func(): 
		holy_label.visible = false
		holy_label.add_theme_font_size_override("font_size", 18)  # Reset to normal size
	)

func show_criminal_message():
	# Find an available move label for the criminal message
	var criminal_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			criminal_label = label
			break
	
	if not criminal_label:
		return  # No available labels
	
	# Set up criminal message with medium yellow text
	criminal_label.text = "CRIMINAL!"
	criminal_label.add_theme_color_override("font_color", Color.YELLOW)
	criminal_label.add_theme_font_size_override("font_size", 36)  # Medium size
	criminal_label.scale = Vector2(1.0, 1.7)  # Keep vertical stretch
	criminal_label.visible = true
	criminal_label.modulate.a = 1.0
	
	# Position at center of MetaCube
	var metacube_center = Vector2(168, 168)
	criminal_label.position = metacube_center
	
	# Create flash animation
	var tween = create_tween()
	combo_tweens.append(tween)
	
	# Flash 3 times
	for i in range(3):
		tween.tween_property(criminal_label, "modulate:a", 1.0, 0.0)
		tween.tween_property(criminal_label, "modulate:a", 1.0, 0.15)
		
		if i < 2:  # Don't add blank after the last flash
			tween.tween_property(criminal_label, "modulate:a", 0.0, 0.0)
			tween.tween_property(criminal_label, "modulate:a", 0.0, 0.1)
	
	# Final cleanup and reset font size
	tween.tween_callback(func(): 
		criminal_label.visible = false
		criminal_label.add_theme_font_size_override("font_size", 18)  # Reset to normal size
	)

func show_sickening_message():
	# Find an available move label for the sickening message
	var sickening_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			sickening_label = label
			break
	
	if not sickening_label:
		return  # No available labels
	
	# Set up sickening message with large orange text
	sickening_label.text = "SICKENING!!"
	sickening_label.add_theme_color_override("font_color", Color.ORANGE)
	sickening_label.add_theme_font_size_override("font_size", 48)  # Larger size
	sickening_label.scale = Vector2(1.0, 1.7)  # Keep vertical stretch
	sickening_label.visible = true
	sickening_label.modulate.a = 1.0
	
	# Start from top of MetaCube area
	var metacube_center = Vector2(168, 168)
	var start_position = Vector2(metacube_center.x, metacube_center.y - 100)
	sickening_label.position = start_position
	
	# Create flash-scroll animation
	var tween = create_tween()
	combo_tweens.append(tween)
	
	# Flash 4 times scrolling down
	var scroll_distance = 60
	
	for i in range(4):
		var current_position = start_position + Vector2(0, scroll_distance * i)
		
		tween.tween_property(sickening_label, "position", current_position, 0.0)
		tween.tween_property(sickening_label, "modulate:a", 1.0, 0.0)
		tween.tween_property(sickening_label, "modulate:a", 1.0, 0.12)
		
		if i < 3:  # Don't add blank after the last flash
			tween.tween_property(sickening_label, "modulate:a", 0.0, 0.0)
			tween.tween_property(sickening_label, "modulate:a", 0.0, 0.05)
	
	# Final cleanup and reset font size
	tween.tween_callback(func(): 
		sickening_label.visible = false
		sickening_label.add_theme_font_size_override("font_size", 18)  # Reset to normal size
	)

func show_disgusting_message():
	# Find an available move label for the disgusting message
	var disgusting_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			disgusting_label = label
			break
	
	if not disgusting_label:
		return  # No available labels
	
	# Set up disgusting message with large red text
	disgusting_label.text = "DISGUSTING!!!"
	disgusting_label.add_theme_color_override("font_color", Color.RED)
	disgusting_label.add_theme_font_size_override("font_size", 60)  # Large size
	disgusting_label.scale = Vector2(1.0, 1.7)  # Keep vertical stretch
	disgusting_label.visible = true
	disgusting_label.modulate.a = 1.0
	
	# Start from top of MetaCube area
	var metacube_center = Vector2(168, 168)
	var start_position = Vector2(metacube_center.x, metacube_center.y - 150)
	disgusting_label.position = start_position
	
	# Create dramatic flash-scroll animation
	var tween = create_tween()
	combo_tweens.append(tween)
	
	# Flash 5 times scrolling down across more of the MetaCube
	var scroll_distance = 80
	
	for i in range(5):
		var current_position = start_position + Vector2(0, scroll_distance * i)
		
		tween.tween_property(disgusting_label, "position", current_position, 0.0)
		tween.tween_property(disgusting_label, "modulate:a", 1.0, 0.0)
		tween.tween_property(disgusting_label, "modulate:a", 1.0, 0.13)
		
		if i < 4:  # Don't add blank after the last flash
			tween.tween_property(disgusting_label, "modulate:a", 0.0, 0.0)
			tween.tween_property(disgusting_label, "modulate:a", 0.0, 0.05)
	
	# Final cleanup and reset font size
	tween.tween_callback(func(): 
		disgusting_label.visible = false
		disgusting_label.add_theme_font_size_override("font_size", 18)  # Reset to normal size
	)

func show_fucking_insane_message():
	# Find an available move label from the pool
	var insane_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			insane_label = label
			break
	
	if not insane_label:
		return  # No available labels
	
	# Set up the FUCKING INSANE message
	insane_label.text = "FUCKING INSANE!!!!!"
	insane_label.modulate = Color(0.4, 0.1, 0.8, 1.0)  # Dark purple color
	insane_label.add_theme_font_size_override("font_size", 84)  # Massive size
	insane_label.visible = true
	
	# MetaCube center and bounds for flashing around different positions
	var metacube_center = Vector2(168, 168)
	var radius = 120  # Distance from center to create flash positions
	
	# Array of positions around the MetaCube to flash to
	var flash_positions = [
		Vector2(metacube_center.x - radius, metacube_center.y - radius),      # Top-left
		Vector2(metacube_center.x + radius, metacube_center.y - radius),      # Top-right
		Vector2(metacube_center.x - radius, metacube_center.y + radius),      # Bottom-left
		Vector2(metacube_center.x + radius, metacube_center.y + radius),      # Bottom-right
		Vector2(metacube_center.x, metacube_center.y - radius),               # Top-center
		Vector2(metacube_center.x, metacube_center.y + radius),               # Bottom-center
		Vector2(metacube_center.x - radius, metacube_center.y),               # Left-center
		Vector2(metacube_center.x + radius, metacube_center.y)                # Right-center
	]
	
	# Create dramatic flashing animation that moves to different positions
	var insane_tween = create_tween()
	insane_tween.set_parallel(true)
	
	var flash_duration = 0.15
	var blank_duration = 0.08
	
	for i in range(8):  # 8 flashes at different positions
		var delay = i * (flash_duration + blank_duration)
		var position = flash_positions[i % flash_positions.size()]
		
		# Move to position and flash
		insane_tween.tween_callback(func():
			insane_label.position = position
			insane_label.visible = true
		).set_delay(delay)
		
		# Hide for blank period
		insane_tween.tween_callback(func():
			insane_label.visible = false
		).set_delay(delay + flash_duration)
	
	# Final cleanup
	var total_duration = 8 * (flash_duration + blank_duration)
	insane_tween.tween_callback(func():
		insane_label.visible = false
		insane_label.add_theme_font_size_override("font_size", 18)  # Reset to normal size
	).set_delay(total_duration)

func show_speed_indicator(speed: int):
	# Hide the current speed label if it exists
	if current_speed_label:
		current_speed_label.visible = false
		current_speed_label.add_theme_font_size_override("font_size", 18)  # Reset to normal size
	
	# Find an available move label for the new speed indicator
	var speed_label: Label = null
	for label in move_name_labels_pool:
		if not label.visible:
			speed_label = label
			break
	
	if not speed_label:
		return  # No available labels
	
	# Set up speed label with larger font size and color based on speed value
	speed_label.text = str(speed)
	speed_label.add_theme_font_size_override("font_size", 24)  # Medium font size for speed
	if speed > 2000:
		speed_label.add_theme_color_override("font_color", Color.MAGENTA)
	elif speed > 1500:
		speed_label.add_theme_color_override("font_color", Color.RED)
	elif speed > 1000:
		speed_label.add_theme_color_override("font_color", Color.ORANGE)
	elif speed > 500:
		speed_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		speed_label.add_theme_color_override("font_color", Color.GREEN)
	
	# Position at new random location on MetaCube
	speed_label.position = get_random_metacube_position()
	speed_label.visible = true
	speed_label.modulate.a = 1.0
	
	# Store as current speed label (stays visible until next tier change)
	current_speed_label = speed_label

# Reverse dash UI removed

func update_speed(speed: float):
	# Check if speed crossed a 500-unit threshold
	var current_speed_tier = int(speed / 500)
	
	if current_speed_tier != last_speed_tier:
		# Speed tier changed, show new speed indicator on MetaCube
		show_speed_indicator(int(speed))
		last_speed_tier = current_speed_tier
	elif current_speed_label:
		# Update the text of the existing speed label without changing position
		current_speed_label.text = str(int(speed))
		current_speed_label.add_theme_font_size_override("font_size", 24)  # Ensure medium font size
		
		# Update color based on current speed
		if speed > 2000:
			current_speed_label.add_theme_color_override("font_color", Color.MAGENTA)
		elif speed > 1500:
			current_speed_label.add_theme_color_override("font_color", Color.RED)
		elif speed > 1000:
			current_speed_label.add_theme_color_override("font_color", Color.ORANGE)
		elif speed > 500:
			current_speed_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			current_speed_label.add_theme_color_override("font_color", Color.GREEN)


func _on_combo_updated(combo_count: int, combo_level: String):
	# Update MetaCube animation based on combo count
	if metacube_animation:
		if combo_count > 0:
			# Speed up animation dynamically - each combo point makes it slightly faster
			# More aggressive speed reduction for noticeable changes per combo
			var base_speed = 0.18
			var speed_reduction = 0.004  # Reduces by 0.004s per combo point (more noticeable)
			var min_speed = 0.02  # Very fast minimum speed cap
			
			var animation_speed = max(base_speed - (combo_count * speed_reduction), min_speed)
			metacube_animation.set_animation_speed(animation_speed)
			
			# Show combo number in random position on MetaCube
			show_combo_number(combo_count, last_combo_count, last_multiplier)
			last_combo_count = combo_count
		else:
			# Reset to slowest speed when no combo
			metacube_animation.set_animation_speed(0.25)  # Slow when idle
			
			# Hide all visible combo numbers when combo resets
			for label in visible_combo_labels:
				label.visible = false
			visible_combo_labels.clear()
			last_combo_count = 0
			
			# Show combo dead message
			show_combo_dead()

func _on_combo_move_updated(move_name: String, speed_multiplier: float, is_staled: bool = false):
	# Show move name in random position on MetaCube for 1 second
	show_move_name(move_name, is_staled)

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
