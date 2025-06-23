extends Node2D

signal combo_updated(combo_count: int, combo_level: String)
signal combo_move_updated(move_name: String, speed_multiplier: float)

# Screen shake variables - smooth shake system
var shake_intensity = 0.0
var shake_timer = 0.0
var shake_frequency = 15.0
var shake_phase = 0.0
var original_camera_position = Vector2.ZERO
var camera: Camera2D
var smooth_shake_offset = Vector2.ZERO

# Time effects
var time_scale = 1.0
var freeze_frame_timer = 0.0
var slow_mo_timer = 0.0
var slow_mo_scale = 0.3

# New combo system
var combo_points = 0.0  # Changed to float to support fractional points
var combo_moves = []  # Array to track last 20 moves
var ground_grace_timer = 0.0
var was_grounded_last_frame = false
var last_speed = 0.0
var low_speed_timer = 0.0  # Timer for tracking consecutive low speed
var inactivity_timer = 0.0  # Timer for tracking time since last combo action
var last_combo_move = ""  # Track the last combo-worthy move
var current_speed = 0.0  # Current player speed for multiplier calculation
var speedbreak_cooldown = 0.0  # Cooldown timer for speedbreak
var has_crossed_2000_speed = false  # Track if we've crossed the threshold this time
const MAX_COMBO_MOVES = 20
const RECENT_MOVES_CHECK = 10  # Check last 10 moves for repetition
const MAX_SAME_MOVES = 5  # Max 5 of same move in recent moves
const GROUND_GRACE_TIME = 1.5  # Reduced to 1.5 seconds
const MIN_SPEED_FOR_COMBO = 50.0  # Speed threshold for low speed timer
const LOW_SPEED_TIMEOUT = 5.0  # 5 seconds of low speed before reset
const INACTIVITY_TIMEOUT = 5.0  # 5 seconds of no combo actions before reset
const SPEEDBREAK_COOLDOWN = 4.0  # 4 seconds between speedbreak triggers
const SPEEDBREAK_THRESHOLD = 2000.0  # Speed threshold for speedbreak
const COMBO_RATINGS = [
	"dead",      # 0-9 points
	"asleep",    # 10-19 points
	"boring",    # 20-29 points
	"average",   # 30-39 points
	"criminal",  # 40-49 points
	"sickening", # 50-59 points
	"disgusting",# 60-69 points
	"morbid"     # 70+ points
]

# Particle systems
@onready var trail_particles: GPUParticles2D
@onready var dust_particles: GPUParticles2D
@onready var impact_particles: GPUParticles2D
@onready var energy_particles: GPUParticles2D

# Audio system
var audio_players = []
const MAX_AUDIO_PLAYERS = 16

# Environment effects
var environment_effects

# Speed lines
@onready var speed_lines: Node2D
var speed_line_opacity = 0.0


func _ready():
	setup_particle_systems()
	setup_audio_system()
	setup_speed_lines()
	setup_environment_effects()
	
	# Find camera
	var player = get_tree().get_first_node_in_group("player")
	if player:
		camera = player.get_node("Camera2D")
		if camera:
			original_camera_position = camera.position

func setup_environment_effects():
	environment_effects = preload("res://EnvironmentEffects.gd").new()
	add_child(environment_effects)

func setup_particle_systems():
	# Particle systems disabled
	pass

func setup_audio_system():
	for i in MAX_AUDIO_PLAYERS:
		var player = AudioStreamPlayer2D.new()
		add_child(player)
		audio_players.append(player)

func setup_speed_lines():
	speed_lines = Node2D.new()
	add_child(speed_lines)
	speed_lines.z_index = -1

func _process(delta):
	# Always ensure time scale is normal - disable all time effects for now
	Engine.time_scale = 1.0
	time_scale = 1.0
	freeze_frame_timer = 0.0
	slow_mo_timer = 0.0
	
	# Update smooth screen shake
	# Don't shake camera in train station
	var scene_name = get_tree().current_scene.name
	if scene_name == "InterDimensionalTrainStation":
		if camera:
			camera.position = Vector2(0, -150)
		return
	
	if shake_timer > 0 and camera:
		shake_timer -= delta
		shake_phase += delta * shake_frequency
		
		# Smooth sine-wave based shake with decay
		var decay_factor = shake_timer / (shake_timer + 0.1)  # Smooth decay
		var current_intensity = shake_intensity * decay_factor
		
		# Use sine waves for smooth, non-jerky movement
		smooth_shake_offset = Vector2(
			sin(shake_phase) * current_intensity,
			sin(shake_phase * 1.3 + 1.0) * current_intensity * 0.8  # Different frequency for Y
		)
		
		if shake_timer <= 0:
			shake_intensity = 0.0
			smooth_shake_offset = Vector2.ZERO
	
	# Combo system is now handled in Player.gd via update_combo_state()

func screen_shake(intensity: float, duration: float):
	if not camera:
		return
	
	# Clamp intensity to reasonable values
	intensity = clamp(intensity, 0.0, 4.0)  # Max 4 pixels for smooth shake
	duration = clamp(duration, 0.0, 0.5)   # Max 0.5 seconds
	
	# Add to existing shake instead of replacing (for layered effects)
	shake_intensity = max(shake_intensity, intensity)
	shake_timer = max(shake_timer, duration)
	
	# Randomize shake frequency slightly for variation
	shake_frequency = randf_range(12.0, 18.0)

func freeze_frame(duration: float):
	# Disabled for now
	pass

func emit_trail(position: Vector2, velocity: Vector2):
	# Particles disabled
	pass

func emit_dust(position: Vector2, intensity: float = 1.0):
	# Particles disabled
	pass

func emit_impact(position: Vector2, direction: Vector2, intensity: float = 1.0):
	# Particles disabled
	pass

func emit_energy(position: Vector2, color: Color = Color.CYAN):
	# Particles disabled
	pass

func set_speed_lines(intensity: float):
	# Disabled
	pass

func add_combo(action_type: String = ""):
	var base_points = get_points_for_action(action_type)
	if base_points == 0.0:
		return
	
	# Calculate speed multiplier
	var speed_multiplier = get_speed_multiplier(current_speed)
	var points = base_points * speed_multiplier
	
	# Check for repetition in recent moves (last 8 moves)
	var recent_moves = combo_moves.slice(-RECENT_MOVES_CHECK)
	var same_move_count = 0
	for move in recent_moves:
		if move == action_type:
			same_move_count += 1
	
	# If already at max repetitions, ignore this move (don't add points)
	if same_move_count >= MAX_SAME_MOVES:
		# Still add to move list for tracking, but no points
		combo_moves.append(action_type)
		if combo_moves.size() > MAX_COMBO_MOVES:
			combo_moves.pop_front()
		return
	
	# Add move to recent moves list
	combo_moves.append(action_type)
	if combo_moves.size() > MAX_COMBO_MOVES:
		combo_moves.pop_front()
	
	# Update last combo move and emit signal for UI
	last_combo_move = action_type
	combo_move_updated.emit(action_type, speed_multiplier)
	
	# Add points
	combo_points += points
	ground_grace_timer = 0.0  # Reset grace timer on successful action
	low_speed_timer = 0.0  # Reset low speed timer on successful action
	inactivity_timer = 0.0  # Reset inactivity timer on successful action
	
	var combo_rating = get_combo_rating()
	combo_updated.emit(int(combo_points), combo_rating)  # Display as integer
	
	# Visual feedback based on rating
	var color = get_rating_color(combo_rating)
	emit_energy(get_player_position(), color)
	
	# Screen shake intensity based on points
	if combo_points >= 50:
		screen_shake(1.0, 0.1)
	elif combo_points >= 30:
		screen_shake(0.8, 0.08)
	elif combo_points >= 10:
		screen_shake(0.5, 0.05)

func get_speed_multiplier(speed: float) -> float:
	if speed >= 2000.0:
		return 2.0
	elif speed >= 1200.0:
		return 1.5
	else:
		return 1.0

func get_points_for_action(action_type: String) -> float:
	match action_type:
		"reverse_dash", "turn_boost":
			return 1.0
		"dash", "air_dash":
			return 1.0
		"roll", "roll_leap":
			return 1.0
		"speedbreak":
			return 1.0
		"wall_kick":
			return 2.0
		"dash_replenish", "smash":
			return 5.0
		"cashgrab":
			return 0.5
		_:
			return 0.0

func reset_combo():
	combo_points = 0.0
	combo_moves.clear()
	ground_grace_timer = 0.0
	low_speed_timer = 0.0
	inactivity_timer = 0.0
	combo_updated.emit(int(combo_points), get_combo_rating())

func get_combo_rating() -> String:
	var rating_index = combo_points / 10
	rating_index = min(rating_index, COMBO_RATINGS.size() - 1)
	return COMBO_RATINGS[rating_index]

func get_rating_color(rating: String) -> Color:
	match rating:
		"dead":
			return Color.GRAY
		"asleep":
			return Color.BLUE
		"boring":
			return Color.CYAN
		"average":
			return Color.GREEN
		"criminal":
			return Color.YELLOW
		"sickening":
			return Color.ORANGE
		"disgusting":
			return Color.RED
		"morbid":
			return Color.MAGENTA
		_:
			return Color.WHITE

func update_combo_state(delta: float, player_velocity: Vector2, is_grounded: bool):
	var previous_speed = current_speed
	current_speed = player_velocity.length()
	
	# Update speedbreak cooldown
	speedbreak_cooldown -= delta
	
	# Check for speedbreak (crossing 2000 speed threshold)
	if previous_speed < SPEEDBREAK_THRESHOLD and current_speed >= SPEEDBREAK_THRESHOLD:
		if speedbreak_cooldown <= 0.0:
			add_combo("speedbreak")
			speedbreak_cooldown = SPEEDBREAK_COOLDOWN
			has_crossed_2000_speed = true
	elif current_speed < SPEEDBREAK_THRESHOLD:
		has_crossed_2000_speed = false
	
	# Check for prolonged low speed (5 seconds of 0-50 speed)
	if current_speed <= MIN_SPEED_FOR_COMBO:
		low_speed_timer += delta
		if low_speed_timer >= LOW_SPEED_TIMEOUT and combo_points > 0:
			reset_combo()
	else:
		low_speed_timer = 0.0  # Reset timer when moving fast enough
	
	# Check for inactivity (5 seconds since last combo action)
	inactivity_timer += delta
	if inactivity_timer >= INACTIVITY_TIMEOUT and combo_points > 0:
		reset_combo()
	
	# Handle ground touch grace period
	if was_grounded_last_frame and not is_grounded:
		# Just left ground, reset grace timer
		ground_grace_timer = 0.0
	elif not was_grounded_last_frame and is_grounded:
		# Just touched ground, start grace timer
		ground_grace_timer = GROUND_GRACE_TIME
	
	# Update grace timer - only reset if staying on ground too long
	if is_grounded and ground_grace_timer > 0.0:
		ground_grace_timer -= delta
		if ground_grace_timer <= 0.0 and combo_points > 0:
			# Been on ground too long without new combo points
			reset_combo()
	
	was_grounded_last_frame = is_grounded
	last_speed = current_speed

func get_player_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	return player.global_position if player else Vector2.ZERO

func camera_lag(target_position: Vector2, responsiveness: float = 0.03):
	if not camera:
		return
	
	# Don't move camera in train station - keep it fixed
	var scene_name = get_tree().current_scene.name
	if scene_name == "InterDimensionalTrainStation":
		camera.global_position = Vector2(0, -150)
		return
	
	# Always update camera - shake will be additive
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var velocity = player.velocity
		var speed = velocity.length()
		
		# Enhanced dynamic camera that leads movement more naturally
		var velocity_offset = Vector2.ZERO
		if speed > 50:  # Start offset at lower speeds
			# More pronounced offset for better anticipation
			velocity_offset = velocity.normalized() * clamp(speed * 0.15, 10, 80)
		
		# Add slight vertical offset based on vertical velocity
		var vertical_offset = clamp(velocity.y * 0.08, -30, 30)
		velocity_offset.y += vertical_offset
		
		# Add subtle banking effect during turns
		var turn_banking = clamp(velocity.x * 0.02, -8, 8)
		velocity_offset.y += turn_banking
		
		# Much smoother camera movement with dynamic responsiveness
		var target_position_calc = original_camera_position + velocity_offset
		var smooth_camera_position = camera.position.lerp(target_position_calc, responsiveness)
		
		# Apply smooth shake offset additively
		camera.position = smooth_camera_position + smooth_shake_offset
