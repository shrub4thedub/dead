extends Area2D

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var is_activated = false
var floating_timer = 0.0
var base_position: Vector2
var key_wall_group = ""  # Which group of key bulbs this belongs to

const FLOAT_AMPLITUDE = 3.0
const FLOAT_SPEED = 2.0

signal key_bulb_activated(group_name)

func _ready():
	add_to_group("key_bulbs")
	body_entered.connect(_on_body_entered)
	base_position = position
	
	# Set green color for key bulbs
	sprite.modulate = Color(0.3, 1.0, 0.3)  # Bright green tint

func _physics_process(delta):
	if not is_activated:
		# Floating animation
		floating_timer += delta * FLOAT_SPEED
		var float_offset = sin(floating_timer) * FLOAT_AMPLITUDE
		position = base_position + Vector2(0, float_offset)

func _on_body_entered(body):
	if body.name == "Player" and not is_activated and body.is_slashing():
		_activate_bulb(body)

func activate():
	if is_activated:
		return
	
	is_activated = true
	
	# Notify the key wall system
	key_bulb_activated.emit(key_wall_group)
	
	print("Key bulb activated in group: ", key_wall_group)

func _activate_bulb(body):
	# Same functionality as dash bulbs
	# Replenish dash
	body.has_used_air_dash = false
	# Trigger delay effect
	body.bulb_delay_timer = 0.08
	# Give upward momentum
	body.velocity.y = -400.0  # Same as dash bulbs
	
	# Visual effects
	if body.effects_manager:
		body.effects_manager.add_combo("key_collect")
		body.effects_manager.screen_shake(3.0, 0.1)
	
	# Activate the key system
	activate()
	
	# Fade out until respawn
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	
	# Disable collision
	collision_shape.disabled = true

func reset():
	"""Reset the key bulb to its initial state"""
	is_activated = false
	sprite.modulate = Color(0.3, 1.0, 0.3, 1.0)  # Bright green with full alpha
	collision_shape.disabled = false
	floating_timer = 0.0
	position = base_position