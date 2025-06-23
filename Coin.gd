extends Area2D

signal collected

@onready var sprite = $Sprite2D

# Floating animation variables
var float_timer = 0.0
var base_position = Vector2.ZERO
const FLOAT_AMPLITUDE = 8.0  # Subtle floating
const FLOAT_SPEED = 2.0      # Gentle floating speed

func _ready():
	body_entered.connect(_on_body_entered)
	# Store the base position for floating animation
	base_position = sprite.position

func _process(delta):
	# Update floating animation
	float_timer += delta
	var float_offset = sin(float_timer * FLOAT_SPEED) * FLOAT_AMPLITUDE
	sprite.position.y = base_position.y + float_offset

func _on_body_entered(body):
	if body.name == "Player":
		collected.emit()
		queue_free()