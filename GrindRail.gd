extends Area2D

signal player_started_grinding(player)
signal player_stopped_grinding(player)

var grinding_player = null
var rail_points = []
var rail_line: Line2D
var is_player_on_rail = false

const RAIL_WIDTH = 10.0
const GRIND_ACCELERATION = 200.0  # Speed gained per second while grinding
const MIN_GRIND_SPEED = 10.0  # Minimum speed to stay on rail
const MAX_GRIND_SPEED = 2000.0  # Cap for grind speed
const RAIL_FRICTION = 0.98  # Slight friction when not accelerating
const GRIND_HEIGHT_TOLERANCE = 20.0  # How close player needs to be vertically

# Rail path properties
@export var rail_start: Vector2 = Vector2(-200, 0)
@export var rail_end: Vector2 = Vector2(200, 0)
@export var rail_curve: float = 0.0  # For curved rails (future feature)

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("grind_rails")
	
	setup_rail_visual()
	generate_rail_points()

func setup_rail_visual():
	rail_line = Line2D.new()
	add_child(rail_line)
	rail_line.width = RAIL_WIDTH
	rail_line.default_color = Color(0.8, 0.8, 0.8, 1.0)
	rail_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	# Add shine effect
	rail_line.add_point(rail_start)
	rail_line.add_point(rail_end)

func generate_rail_points():
	rail_points.clear()
	var rail_distance = rail_start.distance_to(rail_end)
	var segments = max(10, int(rail_distance / 20))  # One point every 20 units
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var point = rail_start.lerp(rail_end, t)
		
		# Add curve if specified
		if rail_curve != 0.0:
			var curve_offset = Vector2(0, rail_curve * sin(t * PI))
			point += curve_offset
		
		rail_points.append(point)

func _on_body_entered(body):
	if body.has_method("start_grinding") and not is_player_on_rail:
		# Only allow grinding if player is coming from above the rail
		var player_pos = body.global_position
		var rail_y = global_position.y
		
		# Check if player is above the rail and moving with sufficient speed
		if player_pos.y < rail_y and body.velocity.length() >= MIN_GRIND_SPEED:
			# Also check if player is moving downward (landing on rail)
			if body.velocity.y >= -50:  # Allow slight upward velocity for landing
				start_grinding(body)

func _on_body_exited(body):
	if body == grinding_player:
		stop_grinding()

func start_grinding(player):
	if grinding_player != null:
		return  # Already grinding
	
	grinding_player = player
	is_player_on_rail = true
	
	# Get player's position relative to rail
	var rail_position = get_closest_rail_point(player.global_position)
	var rail_direction = get_rail_direction_at_point(rail_position)
	
	# Preserve player's movement direction when starting to grind
	var current_speed = player.velocity.length()
	var rail_speed = max(current_speed, MIN_GRIND_SPEED)
	
	# Determine which direction along the rail to grind based on player velocity
	var player_direction = player.velocity.normalized()
	var rail_dir = get_rail_direction_at_point(rail_position)
	
	# Choose the rail direction that best matches player's current movement
	var forward_dot = player_direction.dot(rail_dir)
	var backward_dot = player_direction.dot(-rail_dir)
	
	if backward_dot > forward_dot:
		rail_dir = -rail_dir  # Grind in opposite direction
	
	player.velocity = rail_dir * rail_speed
	
	# Replenish air dash when touching the rail
	player.has_used_air_dash = false
	
	player.start_grinding(self)
	player_started_grinding.emit(player)
	
	# Visual feedback
	rail_line.default_color = Color(1.0, 0.9, 0.3, 1.0)  # Golden color when grinding

func stop_grinding():
	if grinding_player == null:
		return
	
	var player = grinding_player
	
	# Give player a small hop when exiting rail
	player.velocity.y = -250.0  # Longer upward boost
	
	grinding_player.stop_grinding()
	player_stopped_grinding.emit(player)
	
	grinding_player = null
	is_player_on_rail = false
	
	# Reset visual
	rail_line.default_color = Color(0.8, 0.8, 0.8, 1.0)

func update_grinding(player, delta):
	if player != grinding_player:
		return
	
	var player_pos = player.global_position
	var closest_rail_point = get_closest_rail_point(player_pos)
	var rail_world_pos = global_position + closest_rail_point
	
	# Check if player is still close enough to the rail (more lenient)
	var distance_to_rail = player_pos.distance_to(rail_world_pos)
	if distance_to_rail > GRIND_HEIGHT_TOLERANCE * 4:
		stop_grinding()
		return
	
	# Smoothly position player on top of the rail to prevent jitter
	var target_y = rail_world_pos.y - 25
	var current_y = player.global_position.y
	var distance_to_target = abs(current_y - target_y)
	
	# Only snap if player is significantly off the rail
	if distance_to_target > 5.0:
		player.global_position.y = lerp(current_y, target_y, 0.3)  # Smooth interpolation
	else:
		player.global_position.y = target_y  # Direct snap when close
	
	# Get rail direction at current position
	var rail_direction = get_rail_direction_at_point(closest_rail_point)
	
	# Preserve horizontal velocity direction but accelerate
	var current_speed = abs(player.velocity.x)
	var velocity_direction = sign(player.velocity.x) if player.velocity.x != 0 else 1
	var target_speed = min(current_speed + GRIND_ACCELERATION * delta, MAX_GRIND_SPEED)
	
	# Apply velocity in the same horizontal direction as player was moving
	player.velocity.x = velocity_direction * target_speed
	player.velocity.y = 0  # Keep on rail
	
	# Apply slight friction when not actively grinding
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("s"):
		player.velocity.x *= RAIL_FRICTION

func get_closest_rail_point(world_position: Vector2) -> Vector2:
	var local_pos = world_position - global_position
	var closest_point = rail_points[0]
	var min_distance = local_pos.distance_to(rail_points[0])
	
	for point in rail_points:
		var distance = local_pos.distance_to(point)
		if distance < min_distance:
			min_distance = distance
			closest_point = point
	
	return closest_point

func get_rail_direction_at_point(rail_point: Vector2) -> Vector2:
	# Find the rail point index
	var point_index = -1
	for i in range(rail_points.size()):
		if rail_points[i].distance_to(rail_point) < 5.0:  # Close enough
			point_index = i
			break
	
	if point_index == -1:
		return (rail_end - rail_start).normalized()
	
	# Calculate direction based on neighboring points
	var direction = Vector2.ZERO
	
	if point_index == 0:
		# First point - use direction to next point
		direction = rail_points[1] - rail_points[0]
	elif point_index == rail_points.size() - 1:
		# Last point - use direction from previous point
		direction = rail_points[point_index] - rail_points[point_index - 1]
	else:
		# Middle point - average of both directions
		var dir1 = rail_points[point_index] - rail_points[point_index - 1]
		var dir2 = rail_points[point_index + 1] - rail_points[point_index]
		direction = (dir1 + dir2) / 2.0
	
	return direction.normalized()

func is_point_on_rail(world_position: Vector2) -> bool:
	var rail_point = get_closest_rail_point(world_position)
	var rail_world_pos = global_position + rail_point
	return world_position.distance_to(rail_world_pos) <= GRIND_HEIGHT_TOLERANCE

func get_rail_length() -> float:
	return rail_start.distance_to(rail_end)