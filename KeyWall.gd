extends StaticBody2D

@onready var sprite = $ColorRect
@onready var collision_shape = $CollisionShape2D

var group_name = ""  # The group this wall belongs to
var required_keys = 3  # Number of key bulbs needed
var activated_keys = 0
var is_unlocked = false

func _ready():
	add_to_group("key_walls")
	
	# Set green color for key walls to match key orbs - use call_deferred to ensure it overrides scene settings
	call_deferred("set_green_color")
	
	# Connect to all key bulbs in the scene
	call_deferred("connect_to_key_bulbs")

func set_green_color():
	# Force green color to match key orbs
	if sprite:
		# Set bright green color directly on ColorRect
		sprite.color = Color(0.3, 1.0, 0.3)
		print("KeyWall: Set color to green - color: ", sprite.color)

func connect_to_key_bulbs():
	# Find all key bulbs and connect to their activation signal
	var key_bulbs = get_tree().get_nodes_in_group("key_bulbs")
	for bulb in key_bulbs:
		if bulb.has_signal("key_bulb_activated"):
			bulb.key_bulb_activated.connect(_on_key_bulb_activated)

func _on_key_bulb_activated(bulb_group):
	# Only accept keys from our specific group
	if bulb_group == group_name:
		activated_keys += 1
		print("Key wall ", group_name, " progress: ", activated_keys, "/", required_keys)
		
		if activated_keys >= required_keys:
			unlock_wall()

func unlock_wall():
	if is_unlocked:
		return
	
	is_unlocked = true
	print("Key wall unlocked!")
	
	# Visual feedback - fade out
	var tween = create_tween()
	tween.tween_property(sprite, "color:a", 0.0, 0.5)
	tween.tween_callback(remove_wall)

func remove_wall():
	# Disable collision
	collision_shape.disabled = true
	# Hide completely
	visible = false
	print("Key wall removed")

func reset():
	"""Reset the wall when player respawns"""
	activated_keys = 0
	is_unlocked = false
	collision_shape.disabled = false
	visible = true
	sprite.color = Color(0.3, 1.0, 0.3, 1.0)  # Reset to bright green with full alpha (matches key orbs)