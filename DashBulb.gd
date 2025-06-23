extends Area2D

signal dash_replenished

var float_timer = 0.0
var base_y = 0.0
var is_respawning = false
var respawn_timer = 0.0
const FLOAT_AMPLITUDE = 10.0
const FLOAT_SPEED = 2.0
const UPWARD_MOMENTUM = -400.0
const RESPAWN_TIME = 2.0

func _ready():
	base_y = global_position.y
	body_entered.connect(_on_body_entered)
	add_to_group("dash_bulbs")

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
		if body.slash_cooldown > 0 or body.slash_effect_timer > 0:
			_activate_bulb(body)

func _on_slash_hit(player_body):
	if not is_respawning:
		_activate_bulb(player_body)

func _activate_bulb(body):
	# Replenish dash
	body.has_used_air_dash = false
	# Trigger delay effect
	body.bulb_delay_timer = 0.08
	# Give upward momentum
	body.velocity.y = UPWARD_MOMENTUM
	
	# Visual effects - keep combo but remove particles
	if body.effects_manager:
		body.effects_manager.add_combo("dash_replenish")
		body.effects_manager.screen_shake(3.0, 0.1)  # Keep screen shake only
	
	# Removed screen flash - too overwhelming
	# if body.game_ui:
	#	body.game_ui.screen_flash(Color.CYAN, 0.2)
	
	# Start respawn timer
	visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	is_respawning = true
	respawn_timer = RESPAWN_TIME
	dash_replenished.emit()