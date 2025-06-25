extends CharacterBody2D

# Effects and UI references
var effects_manager
var game_ui
var debug_ui

# Movement variables (adjustable via debug UI)
var can_move = true  # Controls whether player can respond to movement input
var max_speed = 2500.0  # High speed cap for advanced play
var acceleration = 600.0
var friction = 600.0  # Reduced friction for easier speed maintenance
var air_friction = 150.0  # Reduced air friction
var brake_force = 2000.0
var turn_threshold = 200.0
var base_turn_boost = 30.0  # Very small base turn boost
var jump_velocity = -400.0

# Air dash and roll variables (adjustable via debug UI)
var dash_cooldown_time = 0.6
var dash_speed = 850.0
var dash_duration = 0.22
var min_air_time_for_dash = 0.25
var min_speed_for_dash = 100.0
var roll_min_speed = 180.0
var roll_max_time = 0.5

# Constants that don't need adjustment
const BASE_TURN_DELAY = 0.1  # Reduced turn delay for faster chaining
const MAX_TURN_DELAY = 0.3  # Reduced max turn delay
const MAX_GROUND_TIME_BONUS = 5.0

@onready var sprite = $AnimatedSprite2D
@onready var dash_icon = $DashIcon
@onready var wall_icon = $WallIcon
@onready var slash_effect = $SlashEffect
@onready var slash_area = $SlashArea
@onready var camera = $Camera2D
@onready var scythe = $Scythe

# Dash direction indicator
var dash_direction_indicator: Line2D

# Animation variables
var base_scale = Vector2(1, 1)
var target_scale = Vector2(1, 1)
var sprite_lean = 0.0
var target_lean = 0.0
var animation_tween: Tween

# Visual effect variables
var last_velocity = Vector2.ZERO
var impact_threshold = 300.0
var high_speed_threshold = 400.0

# Floating animation variables
var float_timer = 0.0
var base_position = Vector2.ZERO
const FLOAT_AMPLITUDE = 3.0  # Subtle floating
const FLOAT_SPEED = 1.5      # Slow floating

# Landing animation variables
var landing_offset = 0.0
var is_landing = false
var landing_tween: Tween
const LANDING_DIP_AMOUNT = 4.0  # How far down the sprite dips
const LANDING_DIP_DURATION = 0.16  # How long the dip lasts
const LANDING_RECOVERY_DURATION = 0.3  # How long to recover to normal

# Input buffer system
var buffered_dash = false
var buffered_slash = false
var buffered_jump = false
var dash_buffer_timer = 0.0
var slash_buffer_timer = 0.0
var jump_buffer_timer = 0.0
const INPUT_BUFFER_TIME = 0.15

# Coyote time system
var coyote_timer = 0.0
var was_on_floor_last_frame = false
const COYOTE_TIME = 0.06

# Momentum preservation system
var momentum_preservation_timer = 0.0
var preserved_velocity = Vector2.ZERO
var is_momentum_preserved = false
const MOMENTUM_PRESERVATION_TIME = 0.5
const HIGH_SPEED_LANDING_THRESHOLD = 600.0

# Combo system integration
var current_combo_points = 0
var combo_cooldown_reduction = 1.0
var combo_charge_multiplier = 1.0

# Reverse dash staling system
var reverse_dash_staling_level = 0
var last_reverse_dash_time = 0.0
var staling_recovery_timer = 0.0
const STALING_DECAY_RATE = 0.5  # Each use reduces effectiveness by 50%
const STALING_RECOVERY_TIME = 10.0  # Time to fully recover
const MAX_STALING_LEVEL = 4  # Max staling level (6.25% effectiveness at max)

# Speed-based upward dash scaling
const UPWARD_dash_speed_THRESHOLD = 400.0  # Speed where scaling starts
const UPWARD_DASH_MIN_SCALE = 0.3  # Minimum scaling factor (30% at high speeds)
const UPWARD_DASH_max_speed = 1500.0  # Speed where minimum scaling is reached

# Physics-based grappling system - completely rewritten
var is_grappling = false
var grapple_anchor = Vector2.ZERO
var rope_natural_length = 0.0
var rope_current_length = 0.0
var rope_line: Line2D
var preview_line: Line2D
var nearby_grapple_points = []

# Easy swinging rope physics constants
const GRAPPLE_RANGE = 800.0  # Large range for very easy grappling
const ROPE_MAX_STRETCH = 0.04  # Slightly more stretch for easier swinging
const ROPE_SPRING_FORCE = 1800.0  # Gentler spring force for smoother swinging
const ROPE_DAMPING = 0.9  # Less damping for more dynamic swinging
const SWING_DAMPING = 0.9998  # Even less damping for longer swings
const MIN_GRAPPLE_DISTANCE = 60.0  # Can grapple closer for easier targeting

# Grinding system
var is_grinding = false
var current_grind_rail = null
var grind_time = 0.0
var pre_grind_velocity = Vector2.ZERO


# Predictive dash targeting
const DASH_MAGNETISM_RANGE = 150.0
const DASH_MAGNETISM_ANGLE = 45.0  # degrees


# Dash streak effect
var dash_streak: Sprite2D
var dash_streak_tween: Tween
var dash_streak_visible = false
var dash_start_position: Vector2
var dash_total_distance: float
var spawn_position: Vector2
var is_turning = false
var turn_timer = 0.0
var stored_speed = 0.0
var turn_direction = 0
var ground_time = 0.0
var preserved_ground_time = 0.0
var was_grounded = false
var air_time = 0.0
var slash_cooldown = 0.0
var dash_cooldown = 0.0
var is_dashing = false
var is_charging_dash = false
var dash_timer = 0.0
var charge_timer = 0.0
var stored_velocity = Vector2.ZERO
var dash_direction = Vector2.ZERO
var has_used_air_dash = false
var is_dashing_backward = false  # Track if current dash is backward
var is_wall_sliding = false
var wall_contact_timer = 0.0
var wall_direction = 0
var is_wall_climbing = false
var wall_climb_timer = 0.0
var wall_climb_direction = 0  # Store the wall direction when climb starts
var has_wall_kicked = false
var can_wall_kick = false
var slash_effect_timer = 0.0
var bulb_delay_timer = 0.0
const GROUND_TIME_REQUIRED = 0.8  # Reduced time required for reverse boost
const MIN_SPEED_FOR_BOOST = 250.0  # Reduced minimum speed for boost
const SLASH_COOLDOWN_TIME = 0.3  # Reduced slash cooldown for faster chaining
const BASE_CHARGE_TIME = 0.08  # Reduced charge time
const MAX_CHARGE_TIME = 0.2  # Reduced max charge time
const DASH_MOMENTUM_BONUS = 120.0  # Reasonable reverse dash bonus
const DASH_MOMENTUM_PENALTY = 80.0  # Reduced forward dash penalty
const WALL_SLIDE_SPEED = 100.0
const WALL_KICK_AVAILABILITY_TIME = 0.25
const WALL_APPROACH_DETECTION_DISTANCE = 50.0
const WALL_CLIMB_SPEED = 800.0
const WALL_CLIMB_DURATION = 0.15
const WALL_KICK_VELOCITY_X = 650.0  # Balanced wall kick speed
const WALL_KICK_VELOCITY_Y = -450.0  # Balanced wall kick height
const SLASH_EFFECT_DURATION = 0.4

# Roll mechanics
var is_rolling = false
var is_air_rolling = false
var roll_distance_remaining = 0.0
var roll_start_speed = 0.0
var roll_target_speed = 0.0  # Target speed for gradual change
var roll_direction = 1
var roll_distance_traveled = 0.0  # Track how far we've rolled
var can_roll = false
var pre_ground_timer = 0.0
var post_ground_timer = 0.0
var roll_time_elapsed = 0.0
var is_roll_leaping = false

# Zipline system
var is_on_zipline = false
var roll_leap_timer = 0.0
var air_roll_pending_brake = false  # Track if air roll should brake on landing

# Roll brake system
var roll_key_held = false
var roll_key_held_duration = 0.0
var should_brake_on_roll_end = false
var is_movement_impaired = false
var movement_impairment_timer = 0.0
var movement_impairment_first_frame = false
var blocked_direction = 0  # Direction that's blocked (1 for right, -1 for left, 0 for none)
var direction_block_timer = 0.0
const MOVEMENT_IMPAIRMENT_DURATION = 0.2
const DIRECTION_BLOCK_DURATION = 0.1
const MOVEMENT_IMPAIRMENT_FACTOR = 0.1  # Movement reduced to 10% effectiveness

# Roll animation system
var roll_animation_timer = 0.0
var roll_current_frame = 0
var roll_animation_completed = false
var roll_frame_textures = []
var roll_sprite: Sprite2D

# Roll entry/exit animation variables
var roll_entry_textures = []
var is_roll_exiting = false
var roll_entry_frame = 0
const ROLL_ANIMATION_FRAMES = 10
const ROLL_ANIMATION_FPS = 20.0
const ROLL_FRAME_DURATION = 1.0 / ROLL_ANIMATION_FPS  # 0.05 seconds per frame
const QUICK_ROLL_DISTANCE = 500.0  # Distance for quick roll (speed regulation)
const BRAKE_ROLL_DISTANCE = 400.0  # Distance for brake roll (stopping)
const AIR_roll_min_speed = 180.0  # Minimum speed for air rolls
const PRE_GROUND_WINDOW = 0.4  # Window before landing to start roll
const POST_GROUND_WINDOW = 0.3  # Window after landing to start roll
const ROLL_MIN_DISTANCE = 100.0  # Minimum distance from ground to allow roll
const ROLL_LEAP_DURATION = 0.12  # Time to stay in roll state during leap
const AIR_ROLL_FALL_MULTIPLIER = 2.0  # How much faster you fall when air rolling
const AIR_ROLL_CONTROL_MULTIPLIER = 1.8  # Moderate air control increase when air rolling
const ROLL_BRAKE_MIN_DISTANCE = 150.0  # Minimum distance required for ledge brake

# Centralized sprite color state management
enum ColorState {
	DEFAULT,
	CHARGING_DASH,
	DASHING,
	SLASHING,
	WALL_CLIMBING,
	TURNING,
	GRINDING,
	ROLLING
}

var current_color_state = ColorState.DEFAULT
var color_state_priority = 0
var color_state_timer = 0.0
var color_state_priorities = {
	ColorState.DEFAULT: 0,
	ColorState.GRINDING: 1,
	ColorState.TURNING: 2,
	ColorState.ROLLING: 3,
	ColorState.WALL_CLIMBING: 4,
	ColorState.SLASHING: 5,
	ColorState.CHARGING_DASH: 6,
	ColorState.DASHING: 7
}

var color_state_colors = {
	ColorState.DEFAULT: Color.WHITE,
	ColorState.CHARGING_DASH: Color.RED,
	ColorState.DASHING: Color.CYAN,
	ColorState.SLASHING: Color.YELLOW,
	ColorState.WALL_CLIMBING: Color.GREEN,
	ColorState.TURNING: Color.RED,
	ColorState.GRINDING: Color(1.0, 0.8, 0.2, 1.0),  # Orange
	ColorState.ROLLING: Color(0.8, 0.4, 0.0, 1.0)  # Brown
}

func _ready():
	# Set up player group
	add_to_group("player")
	
	# Store spawn position
	spawn_position = global_position
	
	# Disable player camera in train station since we have a fixed station camera
	var scene_name = get_tree().current_scene.name
	if scene_name == "InterDimensionalTrainStation":
		if camera:
			camera.enabled = false
	
	# Find effects manager and UI
	call_deferred("setup_references")
	
	# Store base scale and position
	base_scale = sprite.scale
	target_scale = base_scale
	base_position = sprite.position
	
	# Setup dash streak effect
	setup_dash_streak()
	
	# Setup new grappling system
	setup_grappling_visuals()
	
	# Setup dash direction indicator
	setup_dash_indicator()
	
	# Load roll frame textures
	load_roll_frames()

func load_roll_frames():
	# Create roll sprite (separate from main animated sprite)
	roll_sprite = Sprite2D.new()
	add_child(roll_sprite)
	roll_sprite.visible = false
	roll_sprite.z_index = 1  # Above main sprite
	
	# Scale roll sprite to match player size
	var roll_scale_factor = 0.125  # Adjust this value to make roll frames smaller/larger
	roll_sprite.scale = Vector2(roll_scale_factor, roll_scale_factor)
	
	# Load all 10 roll frame textures
	roll_frame_textures.clear()
	for i in range(1, ROLL_ANIMATION_FRAMES + 1):
		var texture_path = "res://Assets/Roll_" + str(i) + ".png"
		var texture = load(texture_path)
		if texture:
			roll_frame_textures.append(texture)
		else:
			print("Warning: Could not load roll frame: ", texture_path)
	
	# Load roll entry textures
	roll_entry_textures.clear()
	for i in range(1, 3):  # Roll_Entry_1.png and Roll_Entry_2.png
		var texture_path = "res://Assets/Roll_Entry_" + str(i) + ".png"
		var texture = load(texture_path)
		if texture:
			roll_entry_textures.append(texture)
		else:
			print("Warning: Could not load roll entry frame: ", texture_path)
	
	print("Loaded ", roll_frame_textures.size(), " roll frames and ", roll_entry_textures.size(), " roll entry frames")

func setup_references():
	effects_manager = get_tree().get_first_node_in_group("effects_manager")
	game_ui = get_tree().get_first_node_in_group("game_ui")
	
	# Connect slash area signal if it exists
	if slash_area:
		slash_area.area_entered.connect(_on_slash_area_entered)
	
	# Connect to effects manager for combo updates
	if effects_manager:
		effects_manager.combo_updated.connect(_on_combo_updated)

func _on_combo_updated(combo_points: int, combo_rating: String):
	current_combo_points = combo_points
	
	# Calculate combo benefits based on points
	if combo_points >= 10:
		combo_cooldown_reduction = 0.9  # 10% faster cooldowns
		combo_charge_multiplier = 0.95  # 5% faster charge times
	if combo_points >= 30:
		combo_cooldown_reduction = 0.7  # 30% faster cooldowns
		combo_charge_multiplier = 0.85  # 15% faster charge times
	if combo_points >= 50:
		combo_cooldown_reduction = 0.5  # 50% faster cooldowns
		combo_charge_multiplier = 0.7   # 30% faster charge times
	if combo_points < 10:
		combo_cooldown_reduction = 1.0
		combo_charge_multiplier = 1.0

func _input(event):
	# Handle right click for roll
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				# Right click pressed
				if is_rolling or is_roll_leaping:
					# Cancel roll if already rolling
					end_roll()
				elif is_air_rolling:
					# Cancel air roll if already air rolling
					end_air_roll()
				else:
					# Start roll if not rolling
					if check_roll_input():
						roll_key_held = true
						roll_key_held_duration = 0.0
			else:
				# Right click released
				roll_key_held = false

# Centralized sprite color state management functions
func set_sprite_color_state(new_state: ColorState, duration: float = 0.0):
	# Check if new state has higher priority than current state
	var new_priority = color_state_priorities.get(new_state, 0)
	
	# Only change if new state has higher or equal priority
	if new_priority >= color_state_priority:
		current_color_state = new_state
		color_state_priority = new_priority
		color_state_timer = duration
		# sprite.modulate = color_state_colors[new_state]  # Disabled to maintain original sprite color

func clear_sprite_color_state(state_to_clear: ColorState):
	# Only clear if we're currently in the specified state
	if current_color_state == state_to_clear:
		reset_sprite_color_to_default()

func reset_sprite_color_to_default():
	current_color_state = ColorState.DEFAULT
	color_state_priority = 0
	color_state_timer = 0.0
	# sprite.modulate = color_state_colors[ColorState.DEFAULT]  # Disabled to maintain original sprite color

func set_zipline_mode(zipline_active: bool):
	is_on_zipline = zipline_active
	if zipline_active:
		# Disable physics and input when entering zipline mode
		can_move = false
		# Stop any current movement states
		is_dashing = false
		is_charging_dash = false
		is_rolling = false
		is_air_rolling = false
		is_wall_sliding = false
		is_wall_climbing = false
		# Release grapple if active
		if is_grappling:
			release_grapple()
	else:
		# Re-enable physics and input when exiting zipline mode
		can_move = true

func is_slashing() -> bool:
	# Check if the scythe is currently performing a slash animation
	if scythe and "is_slashing" in scythe:
		return scythe.is_slashing
	return false

func update_sprite_color_state(delta: float):
	# Handle timed color states
	if color_state_timer > 0:
		color_state_timer -= delta
		if color_state_timer <= 0:
			reset_sprite_color_to_default()

func _on_slash_area_entered(area):
	print("SlashArea detected: ", area.name)
	# Check if we hit a dash bulb
	if area.has_method("_on_slash_hit"):
		print("Calling _on_slash_hit on: ", area.name)
		area._on_slash_hit(self)
	else:
		print("Area ", area.name, " doesn't have _on_slash_hit method")

func setup_dash_streak():
	# Create dash streak sprite
	dash_streak = Sprite2D.new()
	add_child(dash_streak)
	
	# Load the Dash_Trail asset
	var texture = load("res://Assets/Dash_Trail.PNG")
	dash_streak.texture = texture
	
	# Set initial properties
	dash_streak.modulate = Color(1.0, 1.0, 1.0, 0.8)  # White with high alpha
	dash_streak.z_index = -1  # Behind player
	dash_streak.visible = false
	# Scale the trail to appropriate size - much smaller for subtle trail effect
	var trail_scale = 0.1  # 10% of original size for subtle trail effect
	dash_streak.scale = Vector2(trail_scale, trail_scale)  # Scale both dimensions equally

func animate_slash_effect(slash_direction: Vector2):
	if not slash_effect:
		return
	
	# Hide effect initially
	slash_effect.modulate.a = 0.0
	
	# Position effect at 80 pixels to match hitbox
	slash_effect.position = slash_direction * 80
	slash_effect.rotation = atan2(slash_direction.y, slash_direction.x) + PI/2  # Rotate 90 degrees to match hitbox
	slash_effect.scale = Vector2(1.0, 1.0)
	
	# Create tween for the visual effect
	var slash_tween = create_tween()
	slash_tween.set_parallel(true)
	
	# Wait for the delay (0.15s) then show the effect
	slash_tween.tween_property(slash_effect, "modulate:a", 1.0, 0.05).set_delay(0.15)
	slash_tween.tween_property(slash_effect, "scale", Vector2(1.5, 2.0), 0.05).set_delay(0.15)
	slash_tween.tween_property(slash_effect, "modulate", Color.WHITE, 0.05).set_delay(0.15)
	
	# Keep effect visible for active duration (0.2s)
	slash_tween.tween_property(slash_effect, "modulate", Color.CYAN, 0.2).set_delay(0.2)
	
	# Fade out after active duration
	slash_tween.tween_property(slash_effect, "modulate:a", 0.0, 0.1).set_delay(0.4)
	slash_tween.tween_property(slash_effect, "scale", Vector2(1.0, 1.5), 0.1).set_delay(0.4)

func activate_slash_collision(slash_direction: Vector2):
	if not slash_area:
		print("SlashArea not found!")
		return
	
	# Check if scythe is already slashing
	if scythe and scythe.is_slashing:
		print("Cannot slash - scythe is still slashing")
		return
	
	# Trigger scythe animation
	if scythe:
		scythe.perform_slash(slash_direction)
	
	# Position slash area at 80 pixels from player
	slash_area.position = slash_direction * 80  # 80 pixel range
	slash_area.rotation = atan2(slash_direction.y, slash_direction.x) + PI/2  # Rotate 90 degrees
	
	# Also rotate the collision shape directly
	var collision_shape = slash_area.get_node("CollisionShape2D")
	if collision_shape:
		collision_shape.rotation = PI/2
	
	print("SlashArea positioned at: ", slash_area.global_position)
	
	# Delay hitbox activation as requested
	var activation_delay = 0.15  # Reduced delay as requested
	var activation_timer = get_tree().create_timer(activation_delay)
	activation_timer.timeout.connect(func():
		if slash_area:
			print("Activating SlashArea monitoring")
			slash_area.set_deferred("monitoring", true)
			
			# Keep hitbox active for 0.4 seconds for better hit detection
			print("Scythe: Setting up 0.4s hitbox timer")
			var slash_timer = get_tree().create_timer(0.4)  # 0.4 second duration
			slash_timer.timeout.connect(func(): 
				if slash_area:
					print("Deactivating SlashArea monitoring after 0.4 seconds")
					slash_area.monitoring = false
			)
	)

func animate_player_slash(slash_direction: Vector2):
	# Player recoil and slash pose animation
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	# Quick recoil in opposite direction
	var recoil_direction = -slash_direction * 0.1
	var original_lean = sprite_lean
	
	# Phase 1: Stretch toward slash direction and lean (0.05s)
	# animation_tween.tween_property(sprite, "scale", Vector2(1.2, 0.9), 0.05)  # Disabled for ghost sprite
	animation_tween.tween_method(
		func(lean): sprite_lean = lean,
		original_lean,
		original_lean + recoil_direction.x * 0.5,
		0.05
	)
	
	# Phase 2: Compress and lean back (0.1s)
	# animation_tween.tween_property(sprite, "scale", Vector2(0.9, 1.1), 0.1).set_delay(0.05)  # Disabled for ghost sprite
	animation_tween.tween_method(
		func(lean): sprite_lean = lean,
		original_lean + recoil_direction.x * 0.5,
		original_lean - recoil_direction.x * 0.3,
		0.1
	).set_delay(0.05)
	
	# Phase 3: Return to normal (0.05s)
	# animation_tween.tween_property(sprite, "scale", base_scale, 0.05).set_delay(0.15)  # Disabled for ghost sprite
	animation_tween.tween_method(
		func(lean): sprite_lean = lean,
		original_lean - recoil_direction.x * 0.3,
		original_lean,
		0.05
	).set_delay(0.15)

func start_dash_streak(dash_direction: Vector2):
	if not dash_streak:
		return
	
	# Set up streak for this dash
	dash_start_position = global_position
	dash_total_distance = dash_speed * dash_duration
	
	# Position streak relative to player, anchored at back
	dash_streak.position = Vector2.ZERO  # Relative to player
	dash_streak.rotation = atan2(dash_direction.y, dash_direction.x)
	var trail_scale = 0.1
	dash_streak.scale = Vector2(0.0, trail_scale)  # Start with no length
	dash_streak.modulate.a = 0.8  # Ensure it's visible
	
	# Don't make visible yet - wait for actual dash to start
	dash_streak.visible = false
	dash_streak_visible = false

func end_dash_streak():
	if not dash_streak or not dash_streak_visible:
		return
	
	dash_streak_visible = false
	
	if dash_streak_tween:
		dash_streak_tween.kill()
	
	dash_streak_tween = create_tween()
	dash_streak_tween.set_parallel(true)
	
	# Store current trail state for fading - keep original dash direction
	var fade_direction = Vector2(cos(dash_streak.rotation), sin(dash_streak.rotation))  # Current dash direction
	var fade_position = dash_streak.position
	var fade_scale = dash_streak.scale
	
	# Fade out the streak over 0.3 seconds while keeping original direction
	dash_streak_tween.tween_property(dash_streak, "modulate:a", 0.0, 0.3)
	dash_streak_tween.tween_method(func(alpha): 
		# Keep trail in original direction, attached to back of player
		dash_streak.rotation = atan2(fade_direction.y, fade_direction.x)
		# Position trail so its front edge touches the back of player in original direction
		var trail_length = fade_scale.x * dash_streak.texture.get_width()
		var trail_offset = -fade_direction * (trail_length * 0.5 + 16)  # 16 is approx player radius
		dash_streak.position = trail_offset
	, 1.0, 0.0, 0.3)
	
	dash_streak_tween.tween_callback(func(): 
		dash_streak.visible = false
		dash_streak.modulate.a = 0.8  # Reset for next dash
		dash_streak.scale = Vector2(0.1, 0.1)  # Reset scale for next dash with proper trail size
		dash_streak.position = Vector2.ZERO  # Reset position
	).set_delay(0.3)

func respawn():
	# Reset player position
	global_position = spawn_position
	
	# Reset physics state
	velocity = Vector2.ZERO
	
	# Reset player state
	is_turning = false
	is_dashing = false
	is_charging_dash = false
	is_wall_sliding = false
	is_wall_climbing = false
	has_used_air_dash = false
	has_wall_kicked = false
	can_wall_kick = false
	is_rolling = false
	is_roll_leaping = false
	
	# Reset staling system
	reverse_dash_staling_level = 0
	staling_recovery_timer = 0.0
	
	# Reset grappling state
	if is_grappling:
		release_grapple()
	nearby_grapple_points.clear()
	
	# Reset timers
	ground_time = 0.0
	preserved_ground_time = 0.0
	air_time = 0.0
	dash_cooldown = 0.0
	slash_cooldown = 0.0
	turn_timer = 0.0
	charge_timer = 0.0
	dash_timer = 0.0
	wall_contact_timer = 0.0
	wall_climb_timer = 0.0
	slash_effect_timer = 0.0
	bulb_delay_timer = 0.0
	
	# Reset roll animation
	roll_animation_timer = 0.0
	roll_current_frame = 0
	roll_animation_completed = false
	
	# Reset visual state
	reset_sprite_color_to_default()
	sprite.scale = base_scale
	sprite_lean = 0.0
	target_lean = 0.0
	target_scale = base_scale
	
	# Restore normal sprite system
	restore_normal_sprite()
	
	# Hide effects
	if slash_effect:
		slash_effect.visible = false
	end_dash_streak()
	
	
	# Reset camera position if needed (but not in train station)
	if camera:
		var scene_name = get_tree().current_scene.name
		if scene_name != "InterDimensionalTrainStation":
			camera.position = Vector2(0, 2)
	
	# Reset key bulb and wall system
	reset_key_system()

func reset_key_system():
	# Reset all key bulbs
	var key_bulbs = get_tree().get_nodes_in_group("key_bulbs")
	for bulb in key_bulbs:
		if bulb.has_method("reset"):
			bulb.reset()
	
	# Reset all key walls
	var key_walls = get_tree().get_nodes_in_group("key_walls")
	for wall in key_walls:
		if wall.has_method("reset"):
			wall.reset()
	
	print("Key system reset")

func update_visual_effects(delta):
	if not effects_manager:
		return
	
	var speed = velocity.length()
	
	# Much more subtle speed lines
	var speed_intensity = clamp(speed / max_speed, 0.0, 0.3)  # Reduced max intensity
	effects_manager.set_speed_lines(speed_intensity)
	
	# Only emit trail at very high speeds and less frequently
	if speed > high_speed_threshold * 1.5:
		if randf() < 0.1:  # Only 10% chance per frame
			effects_manager.emit_trail(global_position, velocity)
	
	# Handle dash streak gradual reveal during dash
	if dash_streak and dash_streak_visible and is_dashing:
		# Calculate how much of the dash has been completed
		var distance_traveled = global_position.distance_to(dash_start_position)
		var dash_progress = clamp(distance_traveled / dash_total_distance, 0.0, 1.0)
		
		# Scale trail length based on dash progress, keeping it attached to back of player
		var trail_scale_y = 0.1  # Height stays constant
		var trail_scale_x = 0.1 * dash_progress  # Length grows with progress
		dash_streak.scale = Vector2(trail_scale_x, trail_scale_y)
		
		# Position trail behind player in dash direction
		var current_dash_dir = velocity.normalized() if velocity.length() > 0.1 else Vector2.RIGHT
		dash_streak.rotation = atan2(current_dash_dir.y, current_dash_dir.x)
		# Position trail so its front edge touches the back of player
		# Need to account for half the trail length plus player radius
		var trail_length = trail_scale_x * dash_streak.texture.get_width()
		var trail_offset = -current_dash_dir * (trail_length * 0.5 + 16)  # 16 is approx player radius
		dash_streak.position = trail_offset
	
	# Enhanced dynamic camera movement
	var camera_responsiveness = 0.03
	
	# Check if we're in the train station - if so, keep camera fixed
	var scene_name = get_tree().current_scene.name
	if scene_name == "InterDimensionalTrainStation":
		# Keep camera fixed at the center of the train station
		if camera:
			# Disable camera following by setting position independently
			camera.global_position = Vector2(0, -150)
			# Prevent effects manager from moving the camera
			return
	
	# Make camera more responsive during high-speed movement
	if speed > 600:
		camera_responsiveness = 0.05
	elif speed > 400:
		camera_responsiveness = 0.04
	
	effects_manager.camera_lag(global_position, camera_responsiveness)

func update_animations(delta):
	# Squash and stretch based on acceleration
	var acceleration = (velocity - last_velocity) / delta if delta > 0 else Vector2.ZERO
	var accel_magnitude = acceleration.length()
	
	# Squash/stretch effects disabled for ghost sprite
	# if accel_magnitude > 1000:
	# 	# Squash/stretch effect
	# 	if acceleration.x > 500:
	# 		target_scale = Vector2(1.2, 0.8)  # Stretch horizontally
	# 	elif acceleration.x < -500:
	# 		target_scale = Vector2(0.8, 1.2)  # Compress horizontally
	# 	elif acceleration.y > 500:
	# 		target_scale = Vector2(0.9, 1.1)  # Stretch vertically
	# 	elif acceleration.y < -500:
	# 		target_scale = Vector2(1.1, 0.9)  # Compress vertically
	# else:
	target_scale = base_scale
	
	# Lean based on horizontal velocity and turning
	if abs(velocity.x) > 100:
		target_lean = clamp(velocity.x * 0.02, -0.3, 0.3)
	else:
		target_lean = 0.0
	
	# Smooth interpolation
	# sprite.scale = sprite.scale.lerp(target_scale, delta * 8.0)  # Disabled for ghost sprite
	sprite_lean = lerp(sprite_lean, target_lean, delta * 6.0)
	sprite.rotation = sprite_lean
	
	# Speed-based animation selection
	update_sprite_animation()

func update_sprite_animation():
	var speed = velocity.length()
	var current_animation = sprite.animation
	var target_animation = "idle"
	
	# Check for rolling first - use custom roll sprite system
	if is_rolling or is_roll_leaping:
		# Custom roll animation is handled by update_roll_animation and roll_sprite
		# Don't interfere with main sprite during rolling
		return
	# In air: only use dash sprite during air dash, otherwise use idle
	elif not is_on_floor():
		if is_dashing:
			target_animation = "dashback" if is_dashing_backward else "dash"
		else:
			target_animation = "idle"
	else:
		# On ground: use speed-based animations
		if is_dashing:
			target_animation = "dashback" if is_dashing_backward else "dash"
		elif speed >= 1600:
			target_animation = "dash"
		elif speed >= 600:
			target_animation = "run"
		else:
			target_animation = "idle"
	
	# Only change animation if it's different to avoid restarting
	if current_animation != target_animation:
		sprite.play(target_animation)

func update_floating(delta):
	if is_on_floor():
		# Float whenever on ground
		float_timer += delta
		var float_offset = sin(float_timer * FLOAT_SPEED) * FLOAT_AMPLITUDE
		sprite.position.y = base_position.y + float_offset + landing_offset
		sprite.position.x = base_position.x  # Keep x position stable
	else:
		# Reset to base position when in air (but keep landing offset if still landing)
		sprite.position.y = base_position.y + landing_offset
		sprite.position.x = base_position.x
		float_timer = 0.0

func update_ui_feedback():
	if not game_ui:
		return
	
	# Reverse dash UI removed
	
	# Update speed indicator
	game_ui.update_speed(velocity.length())
	

func check_for_impacts(pre_move_velocity: Vector2, delta):
	if not effects_manager:
		return
	
	var speed_change = (velocity - pre_move_velocity).length()
	
	# Landing impact - much more subtle
	if not was_grounded and is_on_floor():
		var impact_force = abs(pre_move_velocity.y)
		
		# Landing dip animation - always trigger for any landing
		trigger_landing_animation()
		
		if impact_force > impact_threshold:
			effects_manager.screen_shake(clamp(impact_force * 0.003, 0.0, 1.0), 0.05)
			effects_manager.emit_dust(global_position + Vector2(0, 24), clamp(impact_force / 800.0, 0.0, 0.5))
			
			# Subtle squash effect on landing
			if animation_tween:
				animation_tween.kill()
			animation_tween = create_tween()
			# animation_tween.tween_property(sprite, "scale", Vector2(1.1, 0.9), 0.05)  # Disabled for ghost sprite
			# animation_tween.tween_property(sprite, "scale", base_scale, 0.1)  # Disabled for ghost sprite
	
	# Wall impact - much more subtle
	if speed_change > impact_threshold and is_on_wall():
		effects_manager.screen_shake(clamp(speed_change * 0.002, 0.0, 0.5), 0.05)
		effects_manager.emit_impact(global_position, get_wall_normal(), clamp(speed_change / 600.0, 0.0, 0.3))

func get_8_direction_from_mouse():
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	var direction = (mouse_pos - player_pos).normalized()
	
	var angle = atan2(direction.y, direction.x)
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360
	
	var index = int((degrees + 22.5) / 45.0) % 8
	var directions = [
		Vector2(1, 0),    # Right
		Vector2(1, 1),    # Down-Right
		Vector2(0, 1),    # Down
		Vector2(-1, 1),   # Down-Left
		Vector2(-1, 0),   # Left
		Vector2(-1, -1),  # Up-Left
		Vector2(0, -1),   # Up
		Vector2(1, -1)    # Up-Right
	]
	return directions[index].normalized()

func get_precise_dash_direction():
	# Get raw direction from mouse position
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	var raw_direction = (mouse_pos - player_pos).normalized()
	
	# Use mouse direction (no snapping to 8 directions)
	return raw_direction

func find_nearby_dash_bulb(intended_direction: Vector2) -> Vector2:
	# Look for bulbs (dash and smash) in the general direction of the intended dash
	var best_direction = intended_direction
	var closest_distance = DASH_MAGNETISM_RANGE
	
	# Get all bulbs in the scene (both dash and smash bulbs)
	var dash_bulbs = get_tree().get_nodes_in_group("dash_bulbs")
	var smash_bulbs = get_tree().get_nodes_in_group("smash_bulbs")
	var all_bulbs = dash_bulbs + smash_bulbs
	
	for bulb in all_bulbs:
		if bulb.is_respawning:
			continue
			
		var bulb_direction = (bulb.global_position - global_position).normalized()
		var distance = global_position.distance_to(bulb.global_position)
		
		# Check if bulb is within magnetism range and angle
		var angle_diff = rad_to_deg(intended_direction.angle_to(bulb_direction))
		
		if distance < closest_distance and abs(angle_diff) < DASH_MAGNETISM_ANGLE:
			closest_distance = distance
			# Blend the intended direction with bulb direction for subtle magnetism
			best_direction = intended_direction.lerp(bulb_direction, 0.3)
	
	return best_direction.normalized()





func update_momentum_preservation(delta):
	# Update momentum preservation timer
	momentum_preservation_timer -= delta
	if momentum_preservation_timer <= 0:
		is_momentum_preserved = false
	
	# Check for high-speed landing
	if not was_grounded and is_on_floor():
		var landing_speed = abs(last_velocity.y)
		if landing_speed > HIGH_SPEED_LANDING_THRESHOLD:
			# Preserve momentum for smooth chaining
			preserved_velocity = last_velocity
			is_momentum_preserved = true
			momentum_preservation_timer = MOMENTUM_PRESERVATION_TIME
			
			if effects_manager:
				effects_manager.emit_impact(global_position + Vector2(0, 24), Vector2.UP, 0.8)

func update_input_buffers(delta):
	# Update buffer timers
	dash_buffer_timer -= delta
	slash_buffer_timer -= delta
	jump_buffer_timer -= delta
	
	# Clear expired buffers
	if dash_buffer_timer <= 0:
		buffered_dash = false
	if slash_buffer_timer <= 0:
		buffered_slash = false
	if jump_buffer_timer <= 0:
		buffered_jump = false
	
	# Capture new inputs
	if Input.is_action_just_pressed("dash"):
		buffered_dash = true
		dash_buffer_timer = INPUT_BUFFER_TIME
	
	if Input.is_action_just_pressed("click"):
		# Check if mouse is over debug UI
		if debug_ui and debug_ui.is_mouse_over_panel():
			print("Player: Ignoring click - mouse over debug UI")
		else:
			buffered_slash = true
			slash_buffer_timer = INPUT_BUFFER_TIME
	
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		buffered_jump = true
		jump_buffer_timer = INPUT_BUFFER_TIME
	
	# Roll input handled in _input function for mouse events

func update_staling_system(delta):
	# Update staling recovery timer
	staling_recovery_timer += delta
	
	# Gradually reduce staling level over time
	if staling_recovery_timer >= STALING_RECOVERY_TIME and reverse_dash_staling_level > 0:
		reverse_dash_staling_level = max(0, reverse_dash_staling_level - 1)
		staling_recovery_timer = 0.0

func apply_reverse_dash_staling(old_velocity_direction: float, new_velocity_direction: float, speed_gain: float) -> float:
	# Detect if this was a reverse dash (opposite direction with significant speed gain)
	var is_reverse_dash = false
	
	# Check if velocity direction changed significantly (opposite directions)
	if sign(old_velocity_direction) != sign(new_velocity_direction) and abs(old_velocity_direction) > turn_threshold and speed_gain > 100:
		is_reverse_dash = true
	
	if is_reverse_dash:
		var current_time = Time.get_ticks_msec() / 1000.0
		
		# Increase staling level if this happened recently after the last reverse dash
		if current_time - last_reverse_dash_time < 5.0:  # Within 5 seconds
			reverse_dash_staling_level = min(MAX_STALING_LEVEL, reverse_dash_staling_level + 1)
			staling_recovery_timer = 0.0  # Reset recovery timer
		
		last_reverse_dash_time = current_time
		
		# Calculate effectiveness multiplier based on staling level
		var effectiveness = pow(STALING_DECAY_RATE, reverse_dash_staling_level)
		
		# Visual feedback for staling
		if reverse_dash_staling_level > 0 and effects_manager:
			var staling_color = Color.ORANGE.lerp(Color.DARK_RED, reverse_dash_staling_level / float(MAX_STALING_LEVEL))
			effects_manager.emit_energy(global_position, staling_color)
		
		return effectiveness
	
	return 1.0  # No staling for non-reverse dashes

# ==================== ROLL SYSTEM ====================

func check_roll_input() -> bool:
	var current_speed = abs(velocity.x)
	
	# Can always roll when on ground and moving fast enough
	if is_on_floor() and not is_rolling and current_speed >= roll_min_speed and velocity.x != 0:
		start_roll()
		return true
	
	# Can start air roll when in air and moving
	if not is_on_floor() and not is_rolling and not is_air_rolling and current_speed >= AIR_roll_min_speed and velocity.x != 0:
		start_air_roll()
		return true
	
	# Check if we can start rolling (falling and close to ground) - legacy system
	if not is_on_floor() and not is_rolling and not is_air_rolling and velocity.y > 0:  # Falling
		# Check distance to ground with a longer ray
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + Vector2(0, 100)  # Increased distance for better detection
		)
		var result = space_state.intersect_ray(query)
		
		if result:
			var distance_to_ground = global_position.distance_to(result.position)
			if distance_to_ground <= ROLL_MIN_DISTANCE:
				can_roll = true
				pre_ground_timer = PRE_GROUND_WINDOW
				return true
	
	return false

func start_air_roll():
	if is_air_rolling or is_rolling:
		return
	
	is_air_rolling = true
	roll_direction = sign(velocity.x) if velocity.x != 0 else 1
	roll_time_elapsed = 0.0
	
	# Track if this should become a brake on landing
	air_roll_pending_brake = roll_key_held
	
	# Set visual state for air rolling
	set_sprite_color_state(ColorState.ROLLING)
	
	# Start roll animation
	roll_animation_timer = 0.0
	roll_current_frame = 0
	roll_animation_completed = false
	
	# Use custom roll frames if available
	if roll_frame_textures.size() >= 1 and roll_sprite:
		sprite.visible = false
		roll_sprite.visible = true
		roll_sprite.texture = roll_frame_textures[0]
	
	# Visual effects
	if effects_manager:
		effects_manager.add_combo("air_roll")

func _transition_to_ground_roll():
	# Transition from air roll to ground roll without resetting animation
	print("Transitioning from air roll to ground roll at speed: ", abs(velocity.x))
	is_rolling = true
	
	# Determine if this is a brake roll or quick roll based on pending brake status
	var is_brake_roll = should_brake_on_roll_end
	
	if is_brake_roll:
		# Brake roll: shorter distance, no immediate speed change
		roll_distance_remaining = BRAKE_ROLL_DISTANCE
		roll_start_speed = abs(velocity.x)
	else:
		# Quick roll: longer distance, apply gradual speed regulation
		roll_distance_remaining = QUICK_ROLL_DISTANCE
		var current_speed = abs(velocity.x)
		
		# Determine speed adjustment based on current velocity
		if current_speed >= 2000.0:
			roll_target_speed = current_speed + 250.0
			print("Quick roll gradual speed boost: ", current_speed, " → ", roll_target_speed)
		elif current_speed <= 800.0:
			roll_target_speed = max(0, current_speed - 250.0)
			print("Quick roll gradual speed reduction: ", current_speed, " → ", roll_target_speed)
		
		roll_start_speed = current_speed
		# No immediate speed change - will be applied gradually during roll
	
	roll_direction = sign(velocity.x) if velocity.x != 0 else 1
	roll_time_elapsed = 0.0
	roll_distance_traveled = 0.0  # Reset distance traveled
	is_roll_leaping = false
	roll_leap_timer = 0.0
	can_roll = false
	
	# DON'T reset animation timer - preserve air roll animation state
	# roll_animation_timer = 0.0  # <-- This line is intentionally omitted
	# roll_current_frame = 0      # <-- This line is intentionally omitted
	# roll_animation_completed = false  # <-- This line is intentionally omitted
	
	set_sprite_color_state(ColorState.ROLLING)
	
	# Sprite is already set up from air roll, don't change it
	
	# Visual effects and combo points
	if effects_manager:
		effects_manager.add_combo("roll")

func start_roll():
	if is_rolling:
		return
	
	print("Starting ground roll at speed: ", abs(velocity.x))
	is_rolling = true
	
	# Determine if this is a brake roll or quick roll based on pending brake status
	var is_brake_roll = should_brake_on_roll_end
	
	if is_brake_roll:
		# Brake roll: shorter distance, no immediate speed change
		roll_distance_remaining = BRAKE_ROLL_DISTANCE
		roll_start_speed = abs(velocity.x)
	else:
		# Quick roll: longer distance, apply gradual speed regulation
		roll_distance_remaining = QUICK_ROLL_DISTANCE
		var current_speed = abs(velocity.x)
		
		if current_speed < 1000.0:
			# Under 1000 speed: gradually gain 250 speed
			roll_target_speed = current_speed + 250.0
			print("Quick roll gradual speed boost: ", current_speed, " → ", roll_target_speed)
		else:
			# Over 1000 speed: gradually lose 250 speed
			roll_target_speed = max(0, current_speed - 250.0)
			print("Quick roll gradual speed reduction: ", current_speed, " → ", roll_target_speed)
		
		roll_start_speed = current_speed
		# No immediate speed change - will be applied gradually during roll
	
	roll_direction = sign(velocity.x) if velocity.x != 0 else 1
	roll_time_elapsed = 0.0
	roll_distance_traveled = 0.0  # Reset distance traveled
	is_roll_leaping = false
	roll_leap_timer = 0.0
	can_roll = false
	post_ground_timer = 0.0  # Clear post-ground timer
	
	# Initialize roll animation
	roll_animation_timer = 0.0
	roll_current_frame = 0
	roll_animation_completed = false
	
	# Set visual state and start animation
	set_sprite_color_state(ColorState.ROLLING)
	
	# Use custom roll frames if available
	if roll_frame_textures.size() >= 1 and roll_sprite:
		sprite.visible = false  # Hide main animated sprite
		roll_sprite.visible = true  # Show roll sprite
		roll_sprite.texture = roll_frame_textures[0]  # Set first frame
	else:
		# Fallback to animation system if frames not loaded
		sprite.animation = "roll"
		sprite.frame = 0
	
	# Visual effects and combo points
	if effects_manager:
		effects_manager.add_combo("roll")

func update_roll_animation(delta):
	if not is_rolling and not is_roll_leaping and not is_air_rolling:
		return
	
	# Check if we have loaded roll frames
	if roll_frame_textures.size() != ROLL_ANIMATION_FRAMES:
		return
	
	# Update animation timer
	roll_animation_timer += delta
	
	# Calculate current frame including entry frames
	# Total frames = 2 entry frames + 10 roll frames = 12 frames
	var total_frames = 2 + ROLL_ANIMATION_FRAMES
	var target_frame = int(roll_animation_timer / ROLL_FRAME_DURATION)
	
	var texture_to_use = null
	
	if is_roll_leaping:
		# During roll leap, loop the animation if all frames have been used
		if roll_animation_completed:
			# Loop only the roll frames (skip entry frames during loop)
			var loop_frame = (target_frame - 2) % ROLL_ANIMATION_FRAMES
			if loop_frame >= 0 and loop_frame < roll_frame_textures.size():
				texture_to_use = roll_frame_textures[loop_frame]
		else:
			# Play through the full sequence once (entry + roll)
			if target_frame < 2 and roll_entry_textures.size() >= 2:
				# Show entry frames
				texture_to_use = roll_entry_textures[target_frame]
			elif target_frame >= 2:
				# Show roll frames
				var roll_frame_index = target_frame - 2
				if roll_frame_index < roll_frame_textures.size():
					texture_to_use = roll_frame_textures[roll_frame_index]
				else:
					roll_animation_completed = true
					roll_animation_timer = 0.0  # Reset timer for looping
	elif is_air_rolling:
		# During air roll, start with entry frames then loop roll frames
		if target_frame < 2 and roll_entry_textures.size() >= 2:
			# Show entry frames
			texture_to_use = roll_entry_textures[target_frame]
		else:
			# Loop roll frames continuously 
			var roll_frame_index = (target_frame - 2) % ROLL_ANIMATION_FRAMES
			if roll_frame_index >= 0 and roll_frame_index < roll_frame_textures.size():
				texture_to_use = roll_frame_textures[roll_frame_index]
	else:
		# During ground roll, play entry frames then loop roll frames until roll ends
		if target_frame < 2 and roll_entry_textures.size() >= 2:
			# Show entry frames
			texture_to_use = roll_entry_textures[target_frame]
		elif target_frame >= 2:
			# Loop roll frames continuously until roll ends
			var roll_frame_index = (target_frame - 2) % ROLL_ANIMATION_FRAMES
			if roll_frame_index >= 0 and roll_frame_index < roll_frame_textures.size():
				texture_to_use = roll_frame_textures[roll_frame_index]
	
	# Update roll sprite texture and flipping
	if texture_to_use and roll_sprite:
		roll_sprite.texture = texture_to_use
		
		# Flip sprite based on roll direction
		# Positive roll_direction = moving right (normal), negative = moving left (flipped)
		if roll_direction < 0:
			roll_sprite.scale.x = -abs(roll_sprite.scale.x)  # Flip horizontally
		else:
			roll_sprite.scale.x = abs(roll_sprite.scale.x)   # Normal orientation

func update_air_roll(delta):
	if not is_air_rolling:
		return
	
	# Update air roll animation
	update_roll_animation(delta)
	
	# Track how long the roll key has been held during air roll
	if roll_key_held:
		roll_key_held_duration += delta
	
	# Check if we've landed - transition to ground roll
	if is_on_floor():
		is_air_rolling = false
		
		# Only transition to ground roll if speed is high enough
		var current_speed = abs(velocity.x)
		if current_speed >= roll_min_speed:
			# Check if we should start with a brake setup
			if air_roll_pending_brake and roll_key_held:
				# Transition to ground roll but mark it for immediate brake
				_transition_to_ground_roll()
				# Transfer the key hold duration and set up for brake
				should_brake_on_roll_end = true
			else:
				# Transition to normal ground roll
				_transition_to_ground_roll()
		else:
			# Too slow for ground roll - just end air roll
			clear_sprite_color_state(ColorState.ROLLING)
			restore_normal_sprite()
			print("Air roll ended - too slow for ground roll (", current_speed, " < ", roll_min_speed, ")")

func update_roll(delta):
	if not is_rolling and not is_roll_leaping:
		# Reset roll key tracking when not rolling (but not during air roll)
		if not is_air_rolling:
			roll_key_held = false
			roll_key_held_duration = 0.0
			should_brake_on_roll_end = false
		return
	
	# Track how long the roll key has been held
	if roll_key_held:
		roll_key_held_duration += delta
	
	# Update roll animation
	update_roll_animation(delta)
	
	# Handle roll leap state
	if is_roll_leaping:
		roll_leap_timer += delta
		
		# End roll leap when timer expires OR when player lands
		if roll_leap_timer >= ROLL_LEAP_DURATION or is_on_floor():
			is_roll_leaping = false
			# Call proper roll end with exit animation
			end_roll()
		return
	
	# Update roll time
	roll_time_elapsed += delta
	
	# Check if roll has exceeded maximum time
	if roll_time_elapsed >= roll_max_time:
		# Check if key was held for the full duration (time-based completion)
		print("Roll time limit reached. Key held: ", roll_key_held, " Duration: ", roll_key_held_duration, " Roll time: ", roll_time_elapsed)
		if roll_key_held and roll_key_held_duration >= roll_time_elapsed:
			should_brake_on_roll_end = true
			print("Setting should_brake_on_roll_end = true (time-based)")
		end_roll()
		return
	
	# Check if player went airborne during roll (rolled off a ledge)
	if not is_on_floor():
		# Check if player is holding for a full brake AND has rolled far enough - if so, brake instead of leap
		if roll_key_held and roll_key_held_duration >= roll_time_elapsed and roll_distance_traveled >= ROLL_BRAKE_MIN_DISTANCE:
			print("Ledge brake triggered! Key held for: ", roll_key_held_duration, " Roll time: ", roll_time_elapsed, " Distance: ", roll_distance_traveled)
			should_brake_on_roll_end = true
			# Force immediate stop of all movement to prevent falling
			velocity.x = 0.0
			velocity.y = 0.0
			# Nudge player back based on speed to ensure they're on solid ground
			var base_nudge = 10.0
			var speed_based_nudge = abs(velocity.x) * 0.02  # 2% of speed as additional nudge
			var nudge_distance = base_nudge + speed_based_nudge
			nudge_distance = min(nudge_distance, 50.0)  # Cap at 50 pixels max
			global_position.x -= roll_direction * nudge_distance
			# Block the roll direction for 0.1 seconds to prevent falling off
			blocked_direction = roll_direction
			direction_block_timer = DIRECTION_BLOCK_DURATION
			print("Ledge brake: stopped, nudged back ", nudge_distance, " pixels, blocking direction: ", blocked_direction)
			# Reset combo on ledge brake
			if effects_manager:
				effects_manager.reset_combo()
			end_roll()
			return
		
		# Otherwise, start rolling leap
		is_roll_leaping = true
		roll_leap_timer = 0.0
		# Add upward boost for the rolling leap
		velocity.y = min(velocity.y, -350.0)  # Strong upward boost
		# Give a significant forward boost - more than just maintaining speed
		var roll_leap_boost = max(roll_start_speed * 1.3, 800.0)  # At least 30% more speed or 800 units minimum
		velocity.x = roll_leap_boost * roll_direction
		
		# Add combo points for rolling leap
		if effects_manager:
			effects_manager.add_combo("roll_leap")
		return
	
	# Calculate target speed based on roll type
	var target_speed = roll_start_speed
	
	if should_brake_on_roll_end:
		# Brake roll: apply gradual speed reduction
		var total_distance = BRAKE_ROLL_DISTANCE
		var distance_progress = 1.0 - (roll_distance_remaining / total_distance)  # Goes from 0.0 to 1.0
		var speed_reduction_amount = 1000.0 if roll_start_speed > 2000.0 else 600.0
		var speed_reduction = speed_reduction_amount * distance_progress
		target_speed = max(0, roll_start_speed - speed_reduction)
	elif roll_target_speed != 0.0:
		# Quick roll: apply gradual speed regulation
		var total_distance = QUICK_ROLL_DISTANCE
		var distance_progress = 1.0 - (roll_distance_remaining / total_distance)  # Goes from 0.0 to 1.0
		# Interpolate between start speed and target speed based on progress
		target_speed = lerp(roll_start_speed, roll_target_speed, distance_progress)
	
	# Apply roll movement (no reversing)
	velocity.x = target_speed * roll_direction
	
	# Track distance traveled this frame
	var distance_this_frame = abs(velocity.x) * delta
	roll_distance_remaining -= distance_this_frame
	roll_distance_traveled += distance_this_frame
	
	# End roll when distance is covered
	if roll_distance_remaining <= 0:
		# Check if key was held for the full duration (distance-based completion)
		print("Roll distance completed. Key held: ", roll_key_held, " Duration: ", roll_key_held_duration, " Roll time: ", roll_time_elapsed)
		if roll_key_held and roll_key_held_duration >= roll_time_elapsed:
			should_brake_on_roll_end = true
			print("Setting should_brake_on_roll_end = true (distance-based)")
		end_roll()

func restore_normal_sprite():
	# Hide roll sprite and show main sprite
	if roll_sprite:
		roll_sprite.visible = false
	sprite.visible = true
	
	# Restore normal sprite animation system
	sprite.animation = "idle"
	sprite.play("idle")

func end_air_roll():
	is_air_rolling = false
	air_roll_pending_brake = false
	
	# Reset roll animation
	roll_animation_timer = 0.0
	roll_current_frame = 0
	roll_animation_completed = false
	
	clear_sprite_color_state(ColorState.ROLLING)
	
	# Restore normal sprite system
	restore_normal_sprite()
	

func end_roll():
	# Play quick exit animation (roll_entry_2 then roll_entry_1)
	if roll_entry_textures.size() >= 2 and roll_sprite:
		# Show exit frames quickly
		roll_sprite.texture = roll_entry_textures[1]  # Roll_Entry_2
		
		# Apply direction flipping for exit animation
		if roll_direction < 0:
			roll_sprite.scale.x = -abs(roll_sprite.scale.x)  # Flip horizontally
		else:
			roll_sprite.scale.x = abs(roll_sprite.scale.x)   # Normal orientation
		
		# Set timer to show first entry frame then complete
		var timer1 = get_tree().create_timer(0.05)  # 50ms for second frame
		timer1.timeout.connect(_show_exit_frame_1)
		return
	
	# If no exit animation, end immediately
	_end_roll_complete()

func _show_exit_frame_1():
	if roll_sprite and roll_entry_textures.size() >= 1:
		roll_sprite.texture = roll_entry_textures[0]  # Roll_Entry_1
		
		# Apply direction flipping for exit animation
		if roll_direction < 0:
			roll_sprite.scale.x = -abs(roll_sprite.scale.x)  # Flip horizontally
		else:
			roll_sprite.scale.x = abs(roll_sprite.scale.x)   # Normal orientation
	
	# Complete the roll after showing first frame
	var timer2 = get_tree().create_timer(0.05)  # 50ms for first frame
	timer2.timeout.connect(_end_roll_complete)

func _end_roll_complete():
	is_rolling = false
	is_roll_leaping = false
	is_roll_exiting = false
	roll_distance_remaining = 0.0
	roll_time_elapsed = 0.0
	roll_leap_timer = 0.0
	roll_target_speed = 0.0  # Reset target speed
	roll_distance_traveled = 0.0  # Reset distance traveled
	
	# Apply roll brake if key was held for full duration
	if should_brake_on_roll_end:
		velocity.x = 0.0  # Full stop
		should_brake_on_roll_end = false
		# Start movement impairment
		is_movement_impaired = true
		movement_impairment_timer = MOVEMENT_IMPAIRMENT_DURATION
		movement_impairment_first_frame = true
		print("Roll brake applied! Speed was: ", abs(velocity.x), " - Now impaired for ", MOVEMENT_IMPAIRMENT_DURATION, "s")
		# Reset combo on full brake
		if effects_manager:
			effects_manager.reset_combo()
	
	# Reset roll animation
	roll_animation_timer = 0.0
	roll_current_frame = 0
	roll_animation_completed = false
	
	# Reset roll key tracking
	roll_key_held = false
	roll_key_held_duration = 0.0
	
	clear_sprite_color_state(ColorState.ROLLING)
	
	# Hide roll sprite and show main sprite
	if roll_sprite:
		roll_sprite.visible = false
	sprite.visible = true
	
	# Restore normal sprite animation system
	sprite.animation = "idle"
	sprite.play("idle")
	
	# Restore normal sprite system
	restore_normal_sprite()
	
	# Return to appropriate animation
	update_animation_state()

func update_animation_state():
	if is_rolling or is_roll_leaping:
		sprite.animation = "roll"
	elif is_dashing:
		sprite.animation = "dash"
	elif abs(velocity.x) > 50:
		sprite.animation = "run"
	else:
		sprite.animation = "idle"

# ==================== NEW PHYSICS-BASED GRAPPLING SYSTEM ====================

func setup_grappling_visuals():
	# Create rope visualization
	rope_line = Line2D.new()
	add_child(rope_line)
	rope_line.default_color = Color(0.7, 0.5, 0.3, 1.0)  # Brown rope
	rope_line.width = 4.0
	rope_line.z_index = -1
	rope_line.visible = false
	rope_line.joint_mode = Line2D.LINE_JOINT_ROUND
	rope_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	rope_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	# Create preview line for targeting
	preview_line = Line2D.new()
	add_child(preview_line)
	preview_line.default_color = Color(0.8, 0.8, 1.0, 0.5)  # Translucent blue
	preview_line.width = 2.0
	preview_line.z_index = -1
	preview_line.visible = false

func _on_grapple_point_entered(grapple_point_node):
	if grapple_point_node not in nearby_grapple_points:
		nearby_grapple_points.append(grapple_point_node)

func _on_grapple_point_exited(grapple_point_node):
	if grapple_point_node in nearby_grapple_points:
		nearby_grapple_points.erase(grapple_point_node)

func find_best_grapple_target() -> Node:
	var best_target = null
	var best_score = -1.0
	
	for grapple_point in nearby_grapple_points:
		var distance = global_position.distance_to(grapple_point.global_position)
		
		# Skip if too far or too close
		if distance > GRAPPLE_RANGE or distance < MIN_GRAPPLE_DISTANCE:
			continue
		
		# Calculate score based on multiple factors
		var distance_score = 1.0 - (distance / GRAPPLE_RANGE)  # Closer is better
		var angle_to_target = (grapple_point.global_position - global_position).normalized()
		
		# Prefer targets that are roughly in the direction of movement
		var movement_score = 0.0
		if velocity.length() > 50:
			var velocity_dir = velocity.normalized()
			movement_score = max(0, angle_to_target.dot(velocity_dir)) * 0.3
		
		# Slight preference for targets above the player (for upward swings)
		var height_score = 0.0
		if grapple_point.global_position.y < global_position.y:
			height_score = 0.2
		
		var total_score = distance_score + movement_score + height_score
		
		if total_score > best_score:
			best_score = total_score
			best_target = grapple_point
	
	return best_target

func try_grapple():
	if is_grappling:
		return
		
	var target = find_best_grapple_target()
	if target:
		attach_grapple(target.global_position)

func attach_grapple(target_pos: Vector2):
	is_grappling = true
	grapple_anchor = target_pos
	rope_natural_length = global_position.distance_to(grapple_anchor)
	rope_current_length = rope_natural_length  # Start at natural length
	
	# Preserve and enhance existing momentum for better swing initiation
	var current_speed = velocity.length()
	if current_speed > 50:
		# Convert movement toward anchor into swing momentum
		var to_anchor = (grapple_anchor - global_position).normalized()
		var rope_tangent = Vector2(-to_anchor.y, to_anchor.x)
		
		# Get existing tangential component
		var existing_tangential = velocity.dot(rope_tangent)
		
		# Add some of the forward momentum to swing if moving horizontally
		if abs(velocity.x) > 100:
			var momentum_bonus = abs(velocity.x) * 0.3  # 30% of horizontal momentum
			existing_tangential += momentum_bonus * sign(velocity.x)
			
			# Rebuild velocity with enhanced tangential component
			var radial_component = velocity.dot(to_anchor)
			velocity = to_anchor * radial_component + rope_tangent * existing_tangential
	
	# Visual feedback
	if effects_manager:
		effects_manager.emit_energy(grapple_anchor, Color.CYAN)
		effects_manager.screen_shake(0.8, 0.06)

func release_grapple():
	if not is_grappling:
		return
	
	is_grappling = false
	
	# Natural swing release - preserve momentum without artificial boosts
	# Calculate swing direction (tangent to rope for natural pendulum motion)
	var to_anchor = grapple_anchor - global_position
	var rope_direction = to_anchor.normalized()
	var swing_tangent = Vector2(-rope_direction.y, rope_direction.x)
	
	# Get the tangential (swing) component of velocity
	var tangential_velocity = velocity.dot(swing_tangent)
	var radial_velocity = velocity.dot(rope_direction)
	
	# Preserve swing momentum, slightly reduce inward pull
	if radial_velocity < 0:  # Moving toward anchor
		velocity -= rope_direction * radial_velocity * 0.3  # Reduce inward velocity by 30%
	
	# Very small momentum conservation boost (realistic for rope release)
	var current_speed = velocity.length()
	if current_speed > 150:
		velocity *= 1.02  # Tiny 2% boost to account for rope energy release
	
	# Visual feedback
	if effects_manager:
		var feedback_color = Color.YELLOW if current_speed > 300 else Color.ORANGE
		effects_manager.emit_energy(global_position, feedback_color)

func update_grapple_physics(delta):
	if not is_grappling:
		return
	
	# Apply gravity normally
	velocity.y += get_gravity().y * delta
	
	# Calculate distance and direction to anchor
	var to_anchor = grapple_anchor - global_position
	var current_distance = to_anchor.length()
	var rope_direction = to_anchor.normalized()
	
	# Calculate tangent direction (perpendicular to rope for swinging)
	var rope_tangent = Vector2(-rope_direction.y, rope_direction.x)
	
	# Decompose velocity into radial and tangential components
	var radial_velocity = velocity.dot(rope_direction)
	var tangential_velocity = velocity.dot(rope_tangent)
	
	# Only constrain when rope is stretched beyond natural length
	var max_allowed_distance = rope_natural_length * (1.0 + ROPE_MAX_STRETCH)
	
	if current_distance > rope_natural_length:
		# Apply constraint force proportional to stretch
		var stretch_ratio = min((current_distance - rope_natural_length) / (rope_natural_length * ROPE_MAX_STRETCH), 1.0)
		
		# Convert radial energy to tangential for momentum conservation
		if radial_velocity > 0:  # Moving away from anchor
			# Transfer some outward momentum to swinging momentum
			var energy_transfer = radial_velocity * 0.4  # Convert 40% of radial to tangential
			tangential_velocity += energy_transfer * (1.0 if velocity.x > 0 else -1.0)  # Maintain swing direction
			
			# Reduce outward velocity gradually
			radial_velocity *= (1.0 - stretch_ratio * 0.6)  # Less aggressive damping
		
		# Apply gentle position constraint only at max stretch
		if current_distance > max_allowed_distance:
			var excess = current_distance - max_allowed_distance
			global_position += rope_direction * excess * 0.2  # Very gentle correction
	
	# Rebuild velocity from components - this preserves swing momentum
	velocity = rope_direction * radial_velocity + rope_tangent * tangential_velocity
	
	# Add momentum boost during downward swing (like a real pendulum)
	var height_from_anchor = (global_position.y - grapple_anchor.y) / rope_natural_length
	if height_from_anchor > -0.8:  # When swinging down from sides
		var momentum_boost = abs(height_from_anchor) * 200.0 * delta  # Gravity assists swing
		velocity += rope_tangent * momentum_boost * sign(tangential_velocity)
	
	# Update visual rope length smoothly
	rope_current_length = lerp(rope_current_length, current_distance, 15.0 * delta)
	
	# Minimal damping to preserve momentum
	velocity *= SWING_DAMPING

func update_grapple_visuals():
	# Update preview line
	var target = find_best_grapple_target()
	if target and not is_grappling:
		preview_line.visible = true
		preview_line.clear_points()
		preview_line.add_point(Vector2.ZERO)
		var relative_pos = target.global_position - global_position
		preview_line.add_point(relative_pos)
	else:
		preview_line.visible = false
	
	# Update rope line - keep it simple
	if is_grappling:
		rope_line.visible = true
		rope_line.clear_points()
		
		# Simple straight rope line
		rope_line.add_point(Vector2.ZERO)
		var relative_anchor = grapple_anchor - global_position
		rope_line.add_point(relative_anchor)
		
		# Optional: slight color change when at max stretch
		var actual_distance = global_position.distance_to(grapple_anchor)
		var max_distance = rope_natural_length * (1.0 + ROPE_MAX_STRETCH)
		if actual_distance >= max_distance:
			rope_line.default_color = Color(0.9, 0.6, 0.3, 1.0)  # Slightly more orange when taut
		else:
			rope_line.default_color = Color(0.7, 0.5, 0.3, 1.0)  # Normal brown
	else:
		rope_line.visible = false

func calculate_upward_velocity_cap(dash_direction: Vector2, current_speed: float) -> float:
	# Check if this is primarily an upward dash (within 45 degrees of straight up)
	var upward_angle = dash_direction.angle_to(Vector2.UP)
	var is_upward_dash = abs(upward_angle) <= PI / 4  # 45 degrees
	
	if is_upward_dash and current_speed > UPWARD_dash_speed_THRESHOLD:
		# Calculate velocity cap based on current speed
		var speed_excess = current_speed - UPWARD_dash_speed_THRESHOLD
		var speed_range = UPWARD_DASH_max_speed - UPWARD_dash_speed_THRESHOLD
		var cap_reduction = (speed_excess / speed_range) * (1.0 - UPWARD_DASH_MIN_SCALE)
		cap_reduction = clamp(cap_reduction, 0.0, 1.0 - UPWARD_DASH_MIN_SCALE)
		
		# Calculate maximum allowed upward velocity
		var base_upward_velocity = dash_speed  # Normal dash speed
		var max_upward_velocity = base_upward_velocity * (1.0 - cap_reduction)
		
		# Visual feedback for velocity capping
		if cap_reduction > 0.2 and effects_manager:
			var scaling_color = Color.YELLOW.lerp(Color.RED, cap_reduction)
			effects_manager.emit_energy(global_position, scaling_color)
		
		return max_upward_velocity
	
	return -1.0  # No cap for non-upward dashes

func update_movement_impairment(delta):
	if is_movement_impaired:
		movement_impairment_timer -= delta
		movement_impairment_first_frame = false  # Clear first frame flag after first update
		if movement_impairment_timer <= 0:
			is_movement_impaired = false
			movement_impairment_timer = 0.0
			movement_impairment_first_frame = false
	
	# Update direction blocking timer
	if direction_block_timer > 0:
		direction_block_timer -= delta
		if direction_block_timer <= 0:
			blocked_direction = 0

func update_coyote_time(delta):
	# Update coyote timer
	if is_on_floor():
		coyote_timer = COYOTE_TIME  # Reset timer when on ground
		was_on_floor_last_frame = true
	else:
		# Only start counting down if we just left the ground
		if was_on_floor_last_frame:
			coyote_timer = COYOTE_TIME
		else:
			coyote_timer -= delta
		was_on_floor_last_frame = false
	
	# Clamp to prevent negative values
	coyote_timer = max(0.0, coyote_timer)

func _physics_process(delta):
	# Skip all physics processing if on zipline
	if is_on_zipline:
		return
	
	update_sprite_color_state(delta)
	update_input_buffers(delta)
	update_momentum_preservation(delta)
	update_staling_system(delta)
	update_movement_impairment(delta)
	update_coyote_time(delta)
	
	# Update new grappling system
	update_grapple_visuals()
	
	# Handle grappling input
	if Input.is_action_just_pressed("click"):
		try_grapple()
	elif Input.is_action_just_released("click") and is_grappling:
		release_grapple()
	
	# Apply grappling physics if active
	if is_grappling:
		update_grapple_physics(delta)
	
	update_visual_effects(delta)
	update_animations(delta)
	update_floating(delta)
	update_ui_feedback()
	
	# Update roll systems
	update_air_roll(delta)
	update_roll(delta)
	
	# Update pre-ground timer for roll
	if pre_ground_timer > 0:
		pre_ground_timer -= delta
		if pre_ground_timer <= 0:
			can_roll = false
	
	# Update post-ground timer for roll
	if post_ground_timer > 0:
		post_ground_timer -= delta
	
	# Update combo system
	if effects_manager:
		effects_manager.update_combo_state(delta, velocity, is_on_floor())
	
	var direction = 0
	# Prevent movement input while rolling, but allow during movement impairment and air rolling
	if can_move and (not is_rolling or is_movement_impaired or is_air_rolling):
		if Input.is_key_pressed(KEY_A) and blocked_direction != -1:
			direction -= 1
		if Input.is_key_pressed(KEY_D) and blocked_direction != 1:
			direction += 1

	if not is_on_floor() and not is_charging_dash and not is_dashing and not is_wall_climbing:
		if bulb_delay_timer <= 0:
			var gravity_multiplier = AIR_ROLL_FALL_MULTIPLIER if is_air_rolling else 1.0
			velocity += get_gravity() * delta * gravity_multiplier
		if was_grounded:
			preserved_ground_time = ground_time
			was_grounded = false
		air_time += delta
		
		# Check for wall contact or approaching wall
		var near_wall = false
		if is_on_wall_only():
			var wall_normal = get_wall_normal()
			wall_direction = -sign(wall_normal.x)
			near_wall = true
			
			if direction == wall_direction:
				# Cancel air roll if starting wall slide
				if is_air_rolling:
					end_air_roll()
				is_wall_sliding = true
				velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
			else:
				is_wall_sliding = false
		else:
			# Check if approaching wall
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(
				global_position,
				global_position + Vector2(WALL_APPROACH_DETECTION_DISTANCE * sign(velocity.x), 0)
			)
			var result = space_state.intersect_ray(query)
			if result and velocity.x != 0:
				wall_direction = -sign(velocity.x)
				near_wall = true
				is_wall_sliding = false
			else:
				is_wall_sliding = false
		
		# Update wall contact timer
		if near_wall:
			if wall_contact_timer <= 0:
				# Just made contact or approached wall
				can_wall_kick = true
			wall_contact_timer = WALL_KICK_AVAILABILITY_TIME
		else:
			wall_contact_timer -= delta
			if wall_contact_timer <= 0:
				can_wall_kick = false
			
	elif is_on_floor():
		# Only increase ground time when moving
		var is_moving = abs(velocity.x) > 50  # Only count as moving if speed > 50
		
		if not was_grounded:
			# Check if we should start rolling on landing
			if can_roll:
				start_roll()
			else:
				# Start post-ground timer for late roll input
				post_ground_timer = POST_GROUND_WINDOW
			
			if preserved_ground_time > 0.0:
				ground_time = preserved_ground_time + air_time + (delta if is_moving else 0)
			else:
				ground_time += delta if is_moving else 0
		else:
			ground_time += delta if is_moving else 0
		was_grounded = true
		air_time = 0.0
		has_used_air_dash = false
		is_wall_sliding = false
		wall_contact_timer = 0.0
		can_wall_kick = false
		has_wall_kicked = false
	elif is_charging_dash or is_dashing:
		air_time += delta
	elif is_wall_climbing:
		wall_climb_timer -= delta
		velocity.y = -WALL_CLIMB_SPEED
		
		# Check if still touching wall during climb (hybrid approach)
		var still_touching_wall = false
		
		# Method 1: Check Godot's built-in wall detection (works when touching)
		if is_on_wall_only():
			var current_wall_normal = get_wall_normal()
			var current_wall_direction = -sign(current_wall_normal.x)
			if current_wall_direction == wall_climb_direction:
				still_touching_wall = true
		
		# Method 2: Raycast check for when not holding direction but still touching wall
		if not still_touching_wall:
			var space_state = get_world_2d().direct_space_state
			
			# Cast from player edge in the climb direction
			var player_half_width = 24.0  # Player collision box is 48px wide
			var ray_start = global_position + Vector2(wall_climb_direction * player_half_width * 0.8, 0)  # Start from near player edge
			var ray_end = global_position + Vector2(wall_climb_direction * (player_half_width + 8.0), 0)  # Short cast beyond edge
			var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
			query.exclude = [self]  # Don't hit the player
			var result = space_state.intersect_ray(query)
			
			# If we hit something close to the player edge, we're still touching
			if result:
				still_touching_wall = true
		
		if not still_touching_wall:
			# No longer touching wall - cancel wall climb without kicking
			is_wall_climbing = false
			clear_sprite_color_state(ColorState.WALL_CLIMBING)
			is_wall_sliding = false
			wall_contact_timer = 0.0
			can_wall_kick = false
			# Reduce upward velocity to prevent excessive launch
			if velocity.y < 0:
				velocity.y *= 0.65  # Keep good upward momentum but not full climb speed
			print("Wall climb cancelled - no longer touching wall")
		elif wall_climb_timer <= 0:
			# Still touching wall and timer expired - perform wall kick
			var approach_speed = abs(velocity.x)
			var speed_multiplier = 1.0 + min(approach_speed / 800.0, 0.5)  # Up to 50% boost
			velocity.x = -wall_climb_direction * WALL_KICK_VELOCITY_X * speed_multiplier
			velocity.y = WALL_KICK_VELOCITY_Y * speed_multiplier
			is_wall_climbing = false
			clear_sprite_color_state(ColorState.WALL_CLIMBING)
			is_wall_sliding = false
			wall_contact_timer = 0.0
			can_wall_kick = false
			if not has_wall_kicked:
				has_used_air_dash = false
			has_wall_kicked = true
			print("Wall kick executed - still touching wall")

	slash_cooldown -= delta * (1.0 / combo_cooldown_reduction)
	dash_cooldown -= delta * (1.0 / combo_cooldown_reduction)
	slash_effect_timer -= delta
	bulb_delay_timer -= delta
	
	if slash_effect_timer <= 0 and slash_effect:
		slash_effect.visible = false
	
	var can_dash = not is_on_floor() and dash_cooldown <= 0 and air_time >= min_air_time_for_dash and velocity.length() >= min_speed_for_dash and not has_used_air_dash and not is_wall_sliding
	dash_icon.visible = can_dash
	
	# Enhanced wall icon feedback
	wall_icon.visible = can_wall_kick
	if can_wall_kick and wall_icon:
		# Pulse effect for wall kick availability
		var pulse_alpha = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.008)
		wall_icon.modulate.a = pulse_alpha

	# Respawn on R key press
	if Input.is_key_pressed(KEY_R):
		respawn()
		return

	# Jump with coyote time - can jump if on floor OR within coyote time window
	var can_jump = (is_on_floor() or coyote_timer > 0.0) and not is_turning
	if buffered_jump and can_jump:
		velocity.y = jump_velocity
		buffered_jump = false  # Consume the buffered input
		coyote_timer = 0.0  # Reset coyote time after jumping
		# Jump no longer gives combo points
		if effects_manager:
			effects_manager.emit_dust(global_position + Vector2(0, 24), 0.8)

	if is_charging_dash:
		charge_timer -= delta
		if charge_timer <= 0:
			# Speed-based scaling: dash speed increases with stored velocity
			var speed_bonus = min(stored_velocity.length() * 0.1, 200.0)  # Up to 200 bonus speed
			var scaled_dash_speed = dash_speed + speed_bonus
			
			# Check if this is a backward dash (opposite to facing direction)
			var player_facing_left = sprite.flip_h
			var dash_going_left = dash_direction.x < 0
			is_dashing_backward = (player_facing_left and not dash_going_left) or (not player_facing_left and dash_going_left)
			
			velocity = dash_direction * scaled_dash_speed
			is_charging_dash = false
			is_dashing = true
			dash_timer = dash_duration
			clear_sprite_color_state(ColorState.CHARGING_DASH)
			set_sprite_color_state(ColorState.DASHING)
			
			# Now show the trail when actual dash starts
			if dash_streak:
				dash_streak.visible = true
				dash_streak_visible = true
	elif is_dashing:
		# Debug: Check if we're in dash state
		if buffered_slash:
			print("In dash, buffered_slash=", buffered_slash, " slash_cooldown=", slash_cooldown)
		
		# Allow slashing during dash
		if buffered_slash and slash_cooldown <= 0:
			print("Dash slash triggered!")
			# Cancel air roll if slashing
			if is_air_rolling:
				end_air_roll()
			
			# During dash, can slash in any direction
			var slash_dir = get_8_direction_from_mouse()
			
			set_sprite_color_state(ColorState.SLASHING, SLASH_EFFECT_DURATION)
			slash_cooldown = SLASH_COOLDOWN_TIME
			buffered_slash = false  # Consume the buffered input
			
			if effects_manager:
				effects_manager.emit_energy(global_position, Color.YELLOW)
				effects_manager.screen_shake(1.5, 0.1)
			
			# Reset slash effect to initial state before animation
			if slash_effect:
				slash_effect.visible = true
				slash_effect.position = Vector2.ZERO
				slash_effect.scale = Vector2(1.0, 1.0)
				slash_effect.modulate = Color.WHITE
				slash_effect.modulate.a = 1.0
				print("Reset slash effect - direction: ", slash_dir)
			
			# Add player recoil animation during slash
			animate_slash_effect(slash_dir)
			animate_player_slash(slash_dir)
			
			# Activate slash collision detection
			activate_slash_collision(slash_dir)
		
		dash_timer -= delta
		if dash_timer <= 0:
			var old_speed = stored_velocity.length()
			var old_direction = stored_velocity.normalized() if old_speed > 0 else Vector2.ZERO
			var direction_dot = old_direction.dot(dash_direction)
			
			var speed_modifier = 0.0
			if direction_dot < -0.5:
				# Reverse dash - gain momentum
				speed_modifier = DASH_MOMENTUM_BONUS
				pass  # Reverse dash bonus applied
			elif direction_dot > 0.5:
				# Forward dash - lose momentum
				speed_modifier = -DASH_MOMENTUM_PENALTY
			
			# Use the original stored velocity as base, not the dash speed
			var final_speed = max(old_speed + speed_modifier, 0.0)  # Don't go negative
			velocity = dash_direction * final_speed
			
			# Apply upward velocity cap if this was an upward dash at high speed
			var upward_velocity_cap = calculate_upward_velocity_cap(dash_direction, old_speed)
			if upward_velocity_cap > 0 and velocity.y < 0:  # Negative y is upward
				# Cap the upward velocity component while preserving horizontal
				velocity.y = max(velocity.y, -upward_velocity_cap)
			
			is_dashing = false
			is_dashing_backward = false  # Reset backward dash flag
			clear_sprite_color_state(ColorState.DASHING)
			if effects_manager:
				effects_manager.screen_shake(2.5, 0.12)  # Impact on dash completion
				effects_manager.emit_impact(global_position, dash_direction, 1.0)
			
			# End dash streak effect
			end_dash_streak()
	elif not is_on_floor():
		if buffered_slash and slash_cooldown <= 0:
			# Cancel air roll if slashing
			if is_air_rolling:
				end_air_roll()
			
			var slash_dir: Vector2
			
			# If dashing, can only slash in dash direction
			if is_dashing:
				slash_dir = dash_direction
			else:
				slash_dir = get_8_direction_from_mouse()
			
			set_sprite_color_state(ColorState.SLASHING, SLASH_EFFECT_DURATION)
			slash_cooldown = SLASH_COOLDOWN_TIME
			buffered_slash = false  # Consume the buffered input
			
			if effects_manager:
				# Slash no longer gives combo points
				effects_manager.emit_impact(global_position, slash_dir, 0.3)
			
			if slash_effect:
				# Enhanced slash animation
				slash_effect.rotation = atan2(slash_dir.y, slash_dir.x) + PI/2
				slash_effect.position = slash_dir * 20  # Start closer
				slash_effect.visible = true
				slash_effect.modulate = Color.WHITE
				slash_effect.scale = Vector2(0.5, 0.5)  # Start smaller
				slash_effect_timer = SLASH_EFFECT_DURATION
				
				# Animate the slash effect
				animate_slash_effect(slash_dir)
				
				# Add player recoil animation during slash
				animate_player_slash(slash_dir)
				
				# Activate slash collision detection
				activate_slash_collision(slash_dir)
		
		if can_wall_kick and buffered_dash:
			# Cancel air roll if wall kicking
			if is_air_rolling:
				end_air_roll()
			is_wall_climbing = true
			wall_climb_timer = WALL_CLIMB_DURATION
			wall_climb_direction = wall_direction  # Store the wall direction at start
			set_sprite_color_state(ColorState.WALL_CLIMBING, WALL_CLIMB_DURATION)
			buffered_dash = false  # Consume the buffered input
			if effects_manager:
				effects_manager.add_combo("wall_kick")
				effects_manager.screen_shake(1.0, 0.08)
				effects_manager.emit_impact(global_position, Vector2(-wall_direction, 0), 0.4)
		elif buffered_dash and dash_cooldown <= 0 and air_time >= min_air_time_for_dash and velocity.length() >= min_speed_for_dash and not has_used_air_dash and not is_wall_sliding:
			dash_direction = get_precise_dash_direction()
			stored_velocity = velocity
			var speed_factor = min(stored_velocity.length() / max_speed, 1.0)
			var base_charge = BASE_CHARGE_TIME * combo_charge_multiplier
			var max_charge = MAX_CHARGE_TIME * combo_charge_multiplier
			charge_timer = base_charge + (speed_factor * (max_charge - base_charge))
			velocity = Vector2.ZERO
			# Cancel air roll if dashing
			if is_air_rolling:
				end_air_roll()
			is_charging_dash = true
			set_sprite_color_state(ColorState.CHARGING_DASH)
			dash_cooldown = dash_cooldown_time
			has_used_air_dash = true
			buffered_dash = false  # Consume the buffered input
			
			if effects_manager:
				effects_manager.add_combo("air_dash")
				effects_manager.emit_energy(global_position, Color.RED)
				effects_manager.screen_shake(2.0, 0.15)  # More prominent dash shake
				effects_manager.emit_impact(global_position, dash_direction, 0.8)  # Add impact particles
			
			# Start dash streak effect
			start_dash_streak(dash_direction)
	else:
		# Ground slashing
		if buffered_slash and slash_cooldown <= 0:
			# Cancel air roll if slashing
			if is_air_rolling:
				end_air_roll()
			
			var slash_dir = get_8_direction_from_mouse()
			
			set_sprite_color_state(ColorState.SLASHING, SLASH_EFFECT_DURATION)
			slash_cooldown = SLASH_COOLDOWN_TIME
			buffered_slash = false  # Consume the buffered input
			
			if effects_manager:
				effects_manager.emit_impact(global_position, slash_dir, 0.3)
			
			if slash_effect:
				# Enhanced slash animation
				slash_effect.rotation = atan2(slash_dir.y, slash_dir.x) + PI/2
				slash_effect.position = slash_dir * 20  # Start closer
				slash_effect.visible = true
				slash_effect.modulate = Color.WHITE
				slash_effect.scale = Vector2(0.5, 0.5)  # Start smaller
				slash_effect_timer = SLASH_EFFECT_DURATION
				
				# Animate the slash effect
				animate_slash_effect(slash_dir)
				
				# Add player recoil animation during slash
				animate_player_slash(slash_dir)
				
				# Activate slash collision detection
				activate_slash_collision(slash_dir)

	if is_turning:
		turn_timer -= delta
		if turn_timer <= 0:
			var ground_time_multiplier = min(ground_time / MAX_GROUND_TIME_BONUS, 1.0)
			var speed_multiplier = min(stored_speed / max_speed, 1.0)
			# Speed-based scaling: turn boost delay decreases at high speeds
			var speed_based_multiplier = 1.0 + (stored_speed / max_speed) * 0.3  # Up to 30% boost
			var final_boost = base_turn_boost + (stored_speed * 0.08) + (ground_time_multiplier * 50)
			final_boost *= speed_based_multiplier
			var final_speed = stored_speed + final_boost
			
			# Apply reverse dash staling before applying velocity
			var old_velocity_direction = -turn_direction * stored_speed  # Previous velocity direction
			var new_velocity_direction = turn_direction * final_speed   # New velocity direction
			var speed_gain = final_speed - stored_speed
			var staling_multiplier = apply_reverse_dash_staling(old_velocity_direction, new_velocity_direction, speed_gain)
			
			# Apply staling to the speed boost (not the base speed)
			var staled_boost = final_boost * staling_multiplier
			final_speed = stored_speed + staled_boost
			
			velocity.x = turn_direction * final_speed
			is_turning = false
			clear_sprite_color_state(ColorState.TURNING)
			ground_time = 0.0
			if effects_manager:
				effects_manager.add_combo("turn_boost")
				effects_manager.screen_shake(1.5, 0.1)
				effects_manager.emit_dust(global_position + Vector2(0, 24), 0.6)
		else:
			velocity.x = 0
		sprite.flip_h = turn_direction < 0
	else:
		if direction != 0:
			var should_turn = (direction > 0 and velocity.x < -turn_threshold) or (direction < 0 and velocity.x > turn_threshold)
			
			if should_turn and is_on_floor():
				if ground_time >= GROUND_TIME_REQUIRED and abs(velocity.x) >= MIN_SPEED_FOR_BOOST:
					is_turning = true
					var ground_time_multiplier = min(ground_time / MAX_GROUND_TIME_BONUS, 1.0)
					var speed_multiplier = min(abs(velocity.x) / max_speed, 1.0)
					turn_timer = BASE_TURN_DELAY + (ground_time_multiplier * 0.2) + (speed_multiplier * 0.15)
					turn_timer = min(turn_timer, MAX_TURN_DELAY)
					stored_speed = abs(velocity.x)
					turn_direction = direction
					set_sprite_color_state(ColorState.TURNING)
					velocity.x = move_toward(velocity.x, 0, brake_force * delta)
				else:
					velocity.x = move_toward(velocity.x, 0, brake_force * delta)
			else:
				# Don't allow any acceleration on the first frame of movement impairment
				if movement_impairment_first_frame:
					velocity.x = 0.0  # Force stop on first frame
					print("Movement impairment first frame - velocity forced to 0")
				else:
					var acceleration_multiplier = 1.0
					
					if is_movement_impaired:
						acceleration_multiplier = MOVEMENT_IMPAIRMENT_FACTOR
					elif is_air_rolling and not is_on_floor():
						# Only apply enhanced control when changing direction or at lower speeds
						var current_speed = abs(velocity.x)
						var is_changing_direction = (direction > 0 and velocity.x < 0) or (direction < 0 and velocity.x > 0)
						var is_moving_same_direction = (direction > 0 and velocity.x > 0) or (direction < 0 and velocity.x < 0)
						
						if is_changing_direction:
							# Changing direction - enhanced control
							acceleration_multiplier = AIR_ROLL_CONTROL_MULTIPLIER * 1.4
						elif current_speed < max_speed * 0.7:
							# Below 70% max speed - moderate enhanced control
							acceleration_multiplier = AIR_ROLL_CONTROL_MULTIPLIER
						elif is_moving_same_direction and current_speed >= max_speed * 0.9:
							# Already moving fast in same direction - no speed boost
							acceleration_multiplier = 0.3
					
					velocity.x += direction * acceleration * delta * acceleration_multiplier
					velocity.x = clamp(velocity.x, -max_speed, max_speed)
			
			sprite.flip_h = direction < 0
		else:
			var friction_force = friction if is_on_floor() else air_friction
			# Reduce friction dramatically during momentum preservation
			if is_momentum_preserved:
				friction_force *= 0.2  # 80% reduction in friction
			# Increase friction during movement impairment
			elif is_movement_impaired:
				friction_force *= 3.0  # Increased friction during impairment
			# Reduce air friction when air rolling to allow better control
			elif is_air_rolling and not is_on_floor():
				friction_force *= 0.3  # Much lower air resistance when air rolling
			velocity.x = move_toward(velocity.x, 0, friction_force * delta)

	# Update grinding
	if is_grinding and current_grind_rail:
		# Check for jump input while grinding
		if buffered_jump and jump_buffer_timer > 0:
			# Jump off the rail
			current_grind_rail.stop_grinding()
			velocity.y = jump_velocity * 0.8  # Slightly reduced jump from rail
			buffered_jump = false
			jump_buffer_timer = 0.0
		else:
			current_grind_rail.update_grinding(self, delta)
			grind_time += delta
	
	# Store velocity before move_and_slide for impact detection
	var pre_move_velocity = velocity
	move_and_slide()
	
	# Enforce movement impairment after move_and_slide
	if movement_impairment_first_frame:
		velocity.x = 0.0  # Ensure brake persists even after move_and_slide
		print("Post-move_and_slide brake enforcement - velocity: ", velocity.x)
	
	# Check for impacts and landings
	check_for_impacts(pre_move_velocity, delta)
	
	# Update last velocity for next frame
	last_velocity = velocity
	
	# Update dash direction indicator
	update_dash_indicator()
	
	# Update sprite color state
	update_sprite_color_state(delta)

func start_grinding(rail):
	if is_grinding:
		return  # Already grinding
	
	is_grinding = true
	current_grind_rail = rail
	grind_time = 0.0
	pre_grind_velocity = velocity
	
	# Visual feedback
	set_sprite_color_state(ColorState.GRINDING)
	
	if effects_manager:
		# Grind start no longer gives combo points
		effects_manager.emit_dust(global_position + Vector2(0, 24), 0.4)

func stop_grinding():
	if not is_grinding:
		return
	
	is_grinding = false
	current_grind_rail = null
	
	# Reset visual
	clear_sprite_color_state(ColorState.GRINDING)
	
	# Add exit speed boost based on grind time
	var grind_bonus = min(grind_time * 50.0, 200.0)  # Up to 200 extra speed
	if velocity.length() > 0:
		velocity = velocity.normalized() * (velocity.length() + grind_bonus)
	
	grind_time = 0.0
	
	if effects_manager:
		# Grind end no longer gives combo points
		effects_manager.emit_energy(global_position, Color(1.0, 0.8, 0.2, 1.0))

func setup_dash_indicator():
	dash_direction_indicator = Line2D.new()
	add_child(dash_direction_indicator)
	dash_direction_indicator.default_color = Color(1.0, 0.8, 0.2, 0.9)  # Orange/yellow
	dash_direction_indicator.width = 5.0
	dash_direction_indicator.z_index = 1
	dash_direction_indicator.visible = false
	dash_direction_indicator.round_precision = 8

func update_dash_indicator():
	# Only show indicator when in air and dash is available
	var should_show = not is_on_floor() and dash_cooldown <= 0 and air_time >= min_air_time_for_dash and velocity.length() >= min_speed_for_dash and not has_used_air_dash and not is_wall_sliding
	
	if should_show:
		dash_direction_indicator.visible = true
		var dash_dir = get_precise_dash_direction()
		var indicator_length = 40.0
		
		# Add pulsing effect
		var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.006)
		dash_direction_indicator.modulate.a = pulse
		
		# Clear and redraw the indicator line
		dash_direction_indicator.clear_points()
		dash_direction_indicator.add_point(Vector2.ZERO)  # Start at player center
		dash_direction_indicator.add_point(dash_dir * indicator_length)  # Point in dash direction
		
		# Add arrowhead
		var arrow_size = 10.0
		var arrow_angle = 0.4  # radians
		var arrow_tip = dash_dir * indicator_length
		var arrow_left = arrow_tip + Vector2(cos(dash_dir.angle() + PI + arrow_angle), sin(dash_dir.angle() + PI + arrow_angle)) * arrow_size
		var arrow_right = arrow_tip + Vector2(cos(dash_dir.angle() + PI - arrow_angle), sin(dash_dir.angle() + PI - arrow_angle)) * arrow_size
		
		dash_direction_indicator.add_point(arrow_left)
		dash_direction_indicator.add_point(arrow_tip)
		dash_direction_indicator.add_point(arrow_right)
	else:
		dash_direction_indicator.visible = false

func trigger_landing_animation():
	# Stop any existing landing animation
	if landing_tween:
		landing_tween.kill()
	
	# Start the landing dip animation
	is_landing = true
	landing_tween = create_tween()
	
	# Dip down with gentle ease
	landing_tween.set_ease(Tween.EASE_OUT)
	landing_tween.set_trans(Tween.TRANS_SINE)
	landing_tween.tween_property(self, "landing_offset", LANDING_DIP_AMOUNT, LANDING_DIP_DURATION)
	
	# Recovery with very smooth, floaty transition
	landing_tween.set_ease(Tween.EASE_OUT)
	landing_tween.set_trans(Tween.TRANS_CUBIC)
	landing_tween.tween_property(self, "landing_offset", 0.0, LANDING_RECOVERY_DURATION)
	landing_tween.tween_callback(func(): is_landing = false)
