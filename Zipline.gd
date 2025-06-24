extends StaticBody2D

@export var end_position: Vector2 = Vector2(200, 0)  # Relative to start position
@onready var line_renderer: Line2D
@onready var collision_area: Area2D
@onready var collision_shape: CollisionShape2D

var start_position: Vector2
var is_player_riding = false
var player_reference = null
var zipline_progress = 0.0  # 0.0 to 1.0 along the zipline
var zipline_speed = 0.0

func _ready():
	start_position = global_position
	setup_zipline_visual()
	setup_collision_detection()
	add_to_group("ziplines")

func setup_zipline_visual():
	# Create line renderer for zipline cable
	line_renderer = Line2D.new()
	line_renderer.width = 3.0
	line_renderer.default_color = Color(0.4, 0.3, 0.2, 1.0)  # Brown cable color
	line_renderer.add_point(Vector2.ZERO)  # Start point
	line_renderer.add_point(end_position)  # End point
	add_child(line_renderer)

func setup_collision_detection():
	# Create area for scythe detection
	collision_area = Area2D.new()
	collision_area.name = "ZiplineArea"
	add_child(collision_area)
	
	# Create collision shape along the zipline - using larger rectangle for easier detection
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	var zipline_length = end_position.length()
	rect_shape.size = Vector2(zipline_length, 30.0)  # 30 pixel wide collision area
	collision_shape.shape = rect_shape
	
	# Rotate and position the collision shape to match the zipline
	var angle = end_position.angle()
	collision_shape.rotation = angle
	collision_shape.position = end_position * 0.5  # Center the collision
	
	collision_area.add_child(collision_shape)
	collision_area.body_entered.connect(_on_scythe_hit)
	
	print("Zipline collision area created at position: ", global_position)

func _on_scythe_hit(body):
	print("Something hit zipline: ", body.name)
	# Check if it's the player and they're slashing
	if body.name == "Player" and not is_player_riding:
		var player = body
		print("Player detected, checking slash state...")
		# Check if player is slashing via their scythe
		var scythe = player.get_node_or_null("Scythe")
		print("Scythe found: ", scythe != null)
		if scythe:
			print("Scythe is_slashing: ", scythe.is_slashing)
		
		# Require scythe slashing to use zipline
		if scythe and scythe.is_slashing:
			print("Zipline hit! Starting ride...")
			start_zipline_ride(player)
		else:
			print("Player hit zipline but not slashing with scythe")
	else:
		print("Not player or already riding")

func start_zipline_ride(player):
	if is_player_riding:
		return
		
	is_player_riding = true
	player_reference = player
	zipline_progress = 0.0
	
	# Calculate initial speed based on player's current velocity
	var player_velocity = player.velocity.length()
	zipline_speed = max(300.0, player_velocity * 0.8)  # Minimum speed of 300
	
	# Disable player's normal movement
	if player.has_method("set_zipline_mode"):
		player.set_zipline_mode(true)
	
	print("Started zipline ride with speed: ", zipline_speed)

func _physics_process(delta):
	if is_player_riding and player_reference:
		update_zipline_ride(delta)

func update_zipline_ride(delta):
	if not player_reference:
		end_zipline_ride()
		return
	
	# Calculate zipline direction and slope
	var zipline_vector = end_position
	var zipline_length = zipline_vector.length()
	var zipline_direction = zipline_vector.normalized()
	
	# Calculate slope effect (positive = downward, negative = upward)
	var slope = zipline_direction.y
	
	# Apply momentum changes based on slope
	if slope > 0.1:  # Downward zipline - gain speed
		zipline_speed += slope * 400.0 * delta  # Gravity acceleration
	elif slope < -0.1:  # Upward zipline - lose speed
		zipline_speed += slope * 200.0 * delta  # Resistance
	# Horizontal ziplines maintain speed (no change)
	
	# Clamp speed to reasonable limits
	zipline_speed = clamp(zipline_speed, 100.0, 1200.0)
	
	# Update progress along zipline
	var distance_delta = zipline_speed * delta
	zipline_progress += distance_delta / zipline_length
	
	# Check if reached the end
	if zipline_progress >= 1.0:
		zipline_progress = 1.0
		end_zipline_ride()
		return
	
	# Calculate positions for scythe blade on zipline and player hanging below
	var current_zipline_position = start_position + (zipline_vector * zipline_progress)
	
	# Position scythe so its BLADE is on the zipline rope
	var scythe = player_reference.get_node_or_null("Scythe")
	if scythe:
		# Scythe blade contacts the zipline directly
		scythe.global_position = current_zipline_position
		# Scythe hangs straight down from its blade contact point
		scythe.rotation = 0.0
	
	# Position player hanging BELOW the scythe handle
	var scythe_length = 40.0  # Full scythe length from blade to handle end
	var player_hang_distance = 25.0  # How far below scythe handle the player hangs
	var total_distance = scythe_length + player_hang_distance
	player_reference.global_position = current_zipline_position + Vector2(0, total_distance)
	
	# Rotate player sprite to hang naturally
	var player_sprite = player_reference.get_node_or_null("AnimatedSprite2D")
	if player_sprite:
		# Player hangs vertically regardless of zipline angle
		player_sprite.rotation = 0.0
	
	# Update player velocity for smooth transition when leaving zipline
	var velocity_direction = zipline_direction
	player_reference.velocity = velocity_direction * zipline_speed

func end_zipline_ride():
	if not player_reference:
		return
		
	print("Ended zipline ride with final speed: ", zipline_speed)
	
	# Restore scythe rotation and position to normal
	var scythe = player_reference.get_node_or_null("Scythe")
	if scythe:
		scythe.rotation = 0.0  # Reset scythe rotation
	
	# Restore player sprite rotation to normal
	var player_sprite = player_reference.get_node_or_null("AnimatedSprite2D")
	if player_sprite:
		player_sprite.rotation = 0.0  # Reset player rotation
	
	# Re-enable player's normal movement
	if player_reference.has_method("set_zipline_mode"):
		player_reference.set_zipline_mode(false)
	
	# Add combo point for zipline use
	var effects_manager = get_tree().get_first_node_in_group("effects_manager")
	if effects_manager:
		effects_manager.add_combo("zipline")
	
	is_player_riding = false
	player_reference = null
	zipline_progress = 0.0

func get_zipline_angle():
	return end_position.angle()

func get_zipline_length():
	return end_position.length()