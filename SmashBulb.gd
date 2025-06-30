extends Area2D

signal player_smashed

var float_timer = 0.0
var base_y = 0.0
var is_respawning = false
var respawn_timer = 0.0
const FLOAT_AMPLITUDE = 8.0
const FLOAT_SPEED = 1.5
const DOWNWARD_MOMENTUM = 800.0  # Strong downward force
const RESPAWN_TIME = 3.0  # Longer respawn time than dash bulb

func _ready():
	base_y = global_position.y
	body_entered.connect(_on_body_entered)
	add_to_group("smash_bulbs")

func _process(delta):
	if is_respawning:
		respawn_timer -= delta
		if respawn_timer <= 0:
			visible = true
			set_collision_layer_value(1, true)
			set_collision_mask_value(1, true)
			is_respawning = false
	else:
		float_timer += delta
		global_position.y = base_y + sin(float_timer * FLOAT_SPEED) * FLOAT_AMPLITUDE

func _on_body_entered(body):
	if body.name == "Player" and not is_respawning:
		# Check if player is slashing
		if body.slash_cooldown > 0:
			_activate_bulb(body)

func _on_slash_hit(player_body):
	if not is_respawning:
		_activate_bulb(player_body)

func _activate_bulb(body):
	# Kill all momentum and send player downward
	body.velocity.x = 0.0  # Stop horizontal movement completely
	body.velocity.y = DOWNWARD_MOMENTUM  # Strong downward force
	
	# Stop any ongoing dashes or charges
	body.is_dashing = false
	body.is_charging_dash = false
	body.is_turning = false
	body.is_wall_climbing = false
	
	# Reset visual state
	body.reset_sprite_color_to_default()
	
	# Visual effects - keep combo but remove particles
	if body.effects_manager:
		body.effects_manager.add_combo("smash")
		body.effects_manager.screen_shake(4.0, 0.15)  # Keep screen shake only
	
	# Start respawn timer
	visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	is_respawning = true
	respawn_timer = RESPAWN_TIME
	player_smashed.emit()