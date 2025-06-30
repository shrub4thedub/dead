extends Area2D

signal bub_destroyed

var float_timer = 0.0
var base_y = 0.0
var is_destroyed = false
const FLOAT_AMPLITUDE = 15.0  # Slightly larger float than dash bulb
const FLOAT_SPEED = 1.5  # Slightly slower float
const UPWARD_MOMENTUM = -400.0

func _ready():
	base_y = global_position.y
	body_entered.connect(_on_body_entered)
	add_to_group("bubs")
	# Connect to player respawn events
	call_deferred("connect_to_player_respawn")

func _process(delta):
	if not is_destroyed:
		float_timer += delta
		global_position.y = base_y + sin(float_timer * FLOAT_SPEED) * FLOAT_AMPLITUDE

func _on_body_entered(body):
	if body.name == "Player" and not is_destroyed:
		# Check if player is slashing
		if body.slash_cooldown > 0:
			_destroy_bub(body)
		else:
			# Player touched bub without slashing - kill them
			_kill_player(body)

func _on_slash_hit(player_body):
	if not is_destroyed:
		_destroy_bub(player_body)

func _destroy_bub(body):
	# Give upward momentum
	body.velocity.y = UPWARD_MOMENTUM
	
	# Visual effects and combo
	if body.effects_manager:
		body.effects_manager.add_combo("bub_destroy")
		body.effects_manager.screen_shake(2.0, 0.1)
	
	# Permanently destroy the bub - no respawning
	visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	is_destroyed = true
	bub_destroyed.emit()

func _kill_player(body):
	# Kill the player - trigger respawn
	print("BUB KILLED PLAYER! Respawning...")
	body.respawn()

func connect_to_player_respawn():
	# Find the player and connect to their respawn signal
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Try to find player by name if group doesn't work
		player = get_tree().get_nodes_in_group("player")
		if player.size() > 0:
			player = player[0]
	
	if player and player.has_signal("player_respawned"):
		player.player_respawned.connect(_on_player_respawned)
		print("Bub connected to player respawn signal")

func _on_player_respawned():
	# Respawn the bub when player respawns (from any cause)
	if is_destroyed:
		print("Bub respawning due to player death")
		respawn_bub()

func respawn_bub():
	# Reset bub state to original
	is_destroyed = false
	visible = true
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	float_timer = 0.0  # Reset animation timer