extends Node2D

@onready var animated_sprite = $AnimatedSprite2D
var player_node: CharacterBody2D
var is_slashing = false
var is_reverse_slashing = false

const FLOAT_DISTANCE = 40  # Distance behind player (increased)
const FLOAT_HEIGHT_OFFSET = -10  # Height offset (negative = above player)
const FLOAT_AMPLITUDE = 2.0
const FLOAT_SPEED = 1.2
var float_timer = 0.0

# Velocity-based lag system
const MAX_LAG_DISTANCE = 35  # Maximum additional lag distance
const VELOCITY_LAG_FACTOR = 0.05  # How much velocity affects lag
var previous_player_position = Vector2.ZERO

func _ready():
	player_node = get_parent()

func _process(delta):
	if not player_node:
		return
	
	# Update float timer
	float_timer += delta
	
	# Don't update position/orientation during normal slash animation
	# BUT allow position updates during reverse slashing
	if is_slashing and not is_reverse_slashing:
		return
	
	# Calculate player velocity for lag effect
	var player_velocity = Vector2.ZERO
	if previous_player_position != Vector2.ZERO:
		player_velocity = (player_node.global_position - previous_player_position) / delta
	previous_player_position = player_node.global_position
	
	# Calculate velocity-based lag
	var speed = player_velocity.length()
	var lag_amount = min(speed * VELOCITY_LAG_FACTOR, MAX_LAG_DISTANCE)
	var lag_direction = -player_velocity.normalized() if speed > 0 else Vector2.ZERO
	
	# Determine which side is "behind" the player based on their facing direction
	var player_sprite = player_node.get_node("AnimatedSprite2D")
	var behind_x_offset = FLOAT_DISTANCE if player_sprite.flip_h else -FLOAT_DISTANCE
	
	# For reverse slashing, position in front instead of behind
	if is_reverse_slashing:
		behind_x_offset = -behind_x_offset  # Flip to front
		print("Scythe: Positioning in front - behind_x_offset = ", behind_x_offset)
		print("Scythe: Player position = ", player_node.global_position)
		print("Scythe: Scythe position before = ", global_position)
	
	# Flip scythe sprite to match player direction
	# BUT for reverse slashing, flip the sprite to face the slash direction
	if is_reverse_slashing:
		animated_sprite.flip_h = not player_sprite.flip_h  # Flip opposite to player
		print("Scythe: Flipping sprite for reverse slash - flip_h = ", animated_sprite.flip_h)
	else:
		animated_sprite.flip_h = player_sprite.flip_h
	
	# Calculate floating position behind player with velocity lag
	var float_y_offset = sin(float_timer * FLOAT_SPEED) * FLOAT_AMPLITUDE
	var float_offset = Vector2(behind_x_offset, FLOAT_HEIGHT_OFFSET)
	var lag_offset = lag_direction * lag_amount
	var target_position = player_node.global_position + float_offset + Vector2(0, float_y_offset) + lag_offset
	
	# Smooth following - slower when moving fast for more natural lag
	var lerp_speed = max(0.05, 0.25 - (speed * 0.0002))  # Slower following at high speeds
	global_position = global_position.lerp(target_position, lerp_speed)
	
	if is_reverse_slashing:
		print("Scythe: Scythe position after = ", global_position)
		print("Scythe: Target position = ", target_position)
	
func perform_slash(slash_direction: Vector2 = Vector2.ZERO):
	if is_slashing:
		return
		
	# Check if this is a diagonal downward slash
	var is_diagonal_down = false
	if slash_direction != Vector2.ZERO:
		# Check if slash is diagonally downward (southeast or southwest)
		# Y > 0 means downward, and we want some horizontal component too
		is_diagonal_down = slash_direction.y > 0 and abs(slash_direction.x) > 0.3 and abs(slash_direction.y) > 0.3
		print("Scythe: slash_direction = ", slash_direction)
		print("Scythe: is_diagonal_down = ", is_diagonal_down)
	
	# Check if this is a reverse slash (opposite to player facing direction)
	var is_reverse_slash = false
	if slash_direction != Vector2.ZERO and player_node:
		var player_sprite = player_node.get_node("AnimatedSprite2D")
		var player_facing_right = not player_sprite.flip_h
		
		# Consider both horizontal and diagonal slashes for reversal
		# Check if the slash has a significant horizontal component
		var has_horizontal_component = abs(slash_direction.x) > 0.3
		
		if has_horizontal_component:
			var slash_going_right = slash_direction.x > 0
			
			print("Scythe: player_facing_right = ", player_facing_right)
			print("Scythe: slash_going_right = ", slash_going_right)
			print("Scythe: has_horizontal_component = ", has_horizontal_component)
			
			# If player faces right but slash goes left, or player faces left but slash goes right
			is_reverse_slash = (player_facing_right and not slash_going_right) or (not player_facing_right and slash_going_right)
			
			print("Scythe: is_reverse_slash = ", is_reverse_slash)
		else:
			print("Scythe: Pure vertical slash detected, not reversing")
	
	if is_reverse_slash:
		print("Scythe: Performing reverse slash!")
		await perform_reverse_slash(is_diagonal_down)
	else:
		print("Scythe: Performing normal slash")
		await perform_normal_slash(is_diagonal_down)

func perform_normal_slash(use_diagonal_down: bool = false):
	is_slashing = true
	
	# Choose animation based on slash direction
	if use_diagonal_down:
		print("Scythe: Playing diagonal down slash animation")
		animated_sprite.play("slash_diag_down")
	else:
		print("Scythe: Playing normal slash animation")
		animated_sprite.play("slash")
	
	# Wait for animation to complete
	await animated_sprite.animation_finished
	is_slashing = false
	animated_sprite.play("idle")

func perform_reverse_slash(use_diagonal_down: bool = false):
	is_slashing = true
	is_reverse_slashing = true
	print("Scythe: Starting reverse slash - flag set to true")
	
	# Quick delay to let positioning update
	await get_tree().create_timer(0.1).timeout
	
	# Perform slash animation
	if use_diagonal_down:
		print("Scythe: Playing reverse diagonal down slash animation")
		animated_sprite.play("slash_diag_down")
	else:
		print("Scythe: Playing reverse slash animation")
		animated_sprite.play("slash")
	await animated_sprite.animation_finished
	
	# Quick delay before returning to normal position
	await get_tree().create_timer(0.1).timeout
	
	is_reverse_slashing = false
	is_slashing = false
	animated_sprite.play("idle")
	print("Scythe: Reverse slash complete - flags reset")