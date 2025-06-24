extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var group_name = ""  # The group this wall belongs to
var required_keys = 3  # Number of key bulbs needed
var activated_keys = 0
var is_unlocked = false

func _ready():
	add_to_group("key_walls")
	
	# Set green color for key walls
	sprite.modulate = Color(0.2, 0.8, 0.2)  # Green tint
	
	# Connect to all key bulbs in the scene
	call_deferred("connect_to_key_bulbs")

func connect_to_key_bulbs():
	# Find all key bulbs and connect to their activation signal
	var key_bulbs = get_tree().get_nodes_in_group("key_bulbs")
	for bulb in key_bulbs:
		if bulb.has_signal("key_bulb_activated"):
			bulb.key_bulb_activated.connect(_on_key_bulb_activated)

func _on_key_bulb_activated(bulb_group):
	if bulb_group == group_name:
		activated_keys += 1
		print("Key wall ", group_name, " progress: ", activated_keys, "/", required_keys)
		
		if activated_keys >= required_keys:
			unlock_wall()

func unlock_wall():
	if is_unlocked:
		return
	
	is_unlocked = true
	print("Key wall ", group_name, " unlocked!")
	
	# Visual feedback - fade out
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(remove_wall)

func remove_wall():
	# Disable collision
	collision_shape.disabled = true
	# Hide completely
	visible = false
	print("Key wall ", group_name, " removed")

func reset():
	"""Reset the wall when player respawns"""
	activated_keys = 0
	is_unlocked = false
	collision_shape.disabled = false
	visible = true
	sprite.modulate = Color(0.2, 0.8, 0.2, 1.0)  # Reset to green with full alpha