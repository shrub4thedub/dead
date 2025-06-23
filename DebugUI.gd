extends CanvasLayer

var player_node: CharacterBody2D

@onready var max_speed_slider = $Control/Panel/VBoxContainer/MaxSpeedContainer/MaxSpeedSlider
@onready var acceleration_slider = $Control/Panel/VBoxContainer/AccelerationContainer/AccelerationSlider
@onready var friction_slider = $Control/Panel/VBoxContainer/FrictionContainer/FrictionSlider
@onready var air_friction_slider = $Control/Panel/VBoxContainer/AirFrictionContainer/AirFrictionSlider
@onready var brake_force_slider = $Control/Panel/VBoxContainer/BrakeForceContainer/BrakeForceSlider
@onready var turn_threshold_slider = $Control/Panel/VBoxContainer/TurnThresholdContainer/TurnThresholdSlider
@onready var base_turn_boost_slider = $Control/Panel/VBoxContainer/BaseTurnBoostContainer/BaseTurnBoostSlider
@onready var jump_velocity_slider = $Control/Panel/VBoxContainer/JumpVelocityContainer/JumpVelocitySlider
@onready var dash_cooldown_slider = $Control/Panel/VBoxContainer/DashCooldownContainer/DashCooldownSlider
@onready var dash_speed_slider = $Control/Panel/VBoxContainer/DashSpeedContainer/DashSpeedSlider
@onready var dash_duration_slider = $Control/Panel/VBoxContainer/DashDurationContainer/DashDurationSlider
@onready var min_air_time_slider = $Control/Panel/VBoxContainer/MinAirTimeContainer/MinAirTimeSlider
@onready var min_speed_dash_slider = $Control/Panel/VBoxContainer/MinSpeedDashContainer/MinSpeedDashSlider
@onready var roll_min_speed_slider = $Control/Panel/VBoxContainer/RollMinSpeedContainer/RollMinSpeedSlider
@onready var roll_max_time_slider = $Control/Panel/VBoxContainer/RollMaxTimeContainer/RollMaxTimeSlider

@onready var max_speed_label = $Control/Panel/VBoxContainer/MaxSpeedContainer/MaxSpeedLabel
@onready var acceleration_label = $Control/Panel/VBoxContainer/AccelerationContainer/AccelerationLabel
@onready var friction_label = $Control/Panel/VBoxContainer/FrictionContainer/FrictionLabel
@onready var air_friction_label = $Control/Panel/VBoxContainer/AirFrictionContainer/AirFrictionLabel
@onready var brake_force_label = $Control/Panel/VBoxContainer/BrakeForceContainer/BrakeForceLabel
@onready var turn_threshold_label = $Control/Panel/VBoxContainer/TurnThresholdContainer/TurnThresholdLabel
@onready var base_turn_boost_label = $Control/Panel/VBoxContainer/BaseTurnBoostContainer/BaseTurnBoostLabel
@onready var jump_velocity_label = $Control/Panel/VBoxContainer/JumpVelocityContainer/JumpVelocityLabel
@onready var dash_cooldown_label = $Control/Panel/VBoxContainer/DashCooldownContainer/DashCooldownLabel
@onready var dash_speed_label = $Control/Panel/VBoxContainer/DashSpeedContainer/DashSpeedLabel
@onready var dash_duration_label = $Control/Panel/VBoxContainer/DashDurationContainer/DashDurationLabel
@onready var min_air_time_label = $Control/Panel/VBoxContainer/MinAirTimeContainer/MinAirTimeLabel
@onready var min_speed_dash_label = $Control/Panel/VBoxContainer/MinSpeedDashContainer/MinSpeedDashLabel
@onready var roll_min_speed_label = $Control/Panel/VBoxContainer/RollMinSpeedContainer/RollMinSpeedLabel
@onready var roll_max_time_label = $Control/Panel/VBoxContainer/RollMaxTimeContainer/RollMaxTimeLabel

func _ready():
	# Find player node
	player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		# Try to find it by searching the scene
		player_node = find_player_recursive(get_tree().root)
	
	print("Debug UI: Player node found: ", player_node)
	
	if player_node:
		setup_sliders()
		print("Debug UI: Sliders setup complete")
	else:
		print("Debug UI: No player node found!")
	
	# Hide initially
	visible = false
	print("Debug UI: Ready, visible = ", visible)
	
	# Debug the UI structure
	print("Debug UI: Control node = ", $Control)
	print("Debug UI: Panel node = ", $Control/Panel)
	print("Debug UI: VBoxContainer node = ", $Control/Panel/VBoxContainer)
	print("Debug UI: Title node = ", $Control/Panel/VBoxContainer/Title)
	print("Debug UI: MaxSpeedContainer = ", $Control/Panel/VBoxContainer/MaxSpeedContainer)
	print("Debug UI: MaxSpeedSlider = ", $Control/Panel/VBoxContainer/MaxSpeedContainer/MaxSpeedSlider)
	print("Debug UI: MaxSpeedLabel = ", $Control/Panel/VBoxContainer/MaxSpeedContainer/MaxSpeedLabel)

func find_player_recursive(node):
	if node.get_script() and node.get_script().get_path().ends_with("Player.gd"):
		return node
	for child in node.get_children():
		var result = find_player_recursive(child)
		if result:
			return result
	return null

func setup_sliders():
	print("Setting up sliders...")
	print("max_speed_slider: ", max_speed_slider)
	print("acceleration_slider: ", acceleration_slider)
	
	if not max_speed_slider:
		print("ERROR: max_speed_slider is null!")
		return
	
	# Set slider ranges and initial values
	max_speed_slider.min_value = 500
	max_speed_slider.max_value = 5000
	max_speed_slider.value = player_node.max_speed
	max_speed_slider.value_changed.connect(_on_max_speed_changed)
	print("Max speed slider connected, value: ", max_speed_slider.value)
	
	acceleration_slider.min_value = 100
	acceleration_slider.max_value = 1500
	acceleration_slider.value = player_node.acceleration
	acceleration_slider.value_changed.connect(_on_acceleration_changed)
	
	friction_slider.min_value = 100
	friction_slider.max_value = 1500
	friction_slider.value = player_node.friction
	friction_slider.value_changed.connect(_on_friction_changed)
	
	air_friction_slider.min_value = 50
	air_friction_slider.max_value = 500
	air_friction_slider.value = player_node.air_friction
	air_friction_slider.value_changed.connect(_on_air_friction_changed)
	
	brake_force_slider.min_value = 500
	brake_force_slider.max_value = 4000
	brake_force_slider.value = player_node.brake_force
	brake_force_slider.value_changed.connect(_on_brake_force_changed)
	
	turn_threshold_slider.min_value = 50
	turn_threshold_slider.max_value = 500
	turn_threshold_slider.value = player_node.turn_threshold
	turn_threshold_slider.value_changed.connect(_on_turn_threshold_changed)
	
	base_turn_boost_slider.min_value = 10
	base_turn_boost_slider.max_value = 100
	base_turn_boost_slider.value = player_node.base_turn_boost
	base_turn_boost_slider.value_changed.connect(_on_base_turn_boost_changed)
	
	jump_velocity_slider.min_value = -800
	jump_velocity_slider.max_value = -200
	jump_velocity_slider.value = player_node.jump_velocity
	jump_velocity_slider.value_changed.connect(_on_jump_velocity_changed)
	
	dash_cooldown_slider.min_value = 0.1
	dash_cooldown_slider.max_value = 2.0
	dash_cooldown_slider.value = player_node.dash_cooldown_time
	dash_cooldown_slider.value_changed.connect(_on_dash_cooldown_changed)
	
	dash_speed_slider.min_value = 300
	dash_speed_slider.max_value = 1500
	dash_speed_slider.value = player_node.dash_speed
	dash_speed_slider.value_changed.connect(_on_dash_speed_changed)
	
	dash_duration_slider.min_value = 0.01
	dash_duration_slider.max_value = 1.0
	dash_duration_slider.step = 0.01
	dash_duration_slider.value = player_node.dash_duration
	dash_duration_slider.value_changed.connect(_on_dash_duration_changed)
	
	min_air_time_slider.min_value = 0.0
	min_air_time_slider.max_value = 1.0
	min_air_time_slider.value = player_node.min_air_time_for_dash
	min_air_time_slider.value_changed.connect(_on_min_air_time_changed)
	
	min_speed_dash_slider.min_value = 0
	min_speed_dash_slider.max_value = 500
	min_speed_dash_slider.value = player_node.min_speed_for_dash
	min_speed_dash_slider.value_changed.connect(_on_min_speed_dash_changed)
	
	roll_min_speed_slider.min_value = 50
	roll_min_speed_slider.max_value = 500
	roll_min_speed_slider.value = player_node.roll_min_speed
	roll_min_speed_slider.value_changed.connect(_on_roll_min_speed_changed)
	
	roll_max_time_slider.min_value = 0.1
	roll_max_time_slider.max_value = 2.0
	roll_max_time_slider.value = player_node.roll_max_time
	roll_max_time_slider.value_changed.connect(_on_roll_max_time_changed)
	
	update_labels()

func update_labels():
	if not player_node:
		return
		
	max_speed_label.text = "Max Speed: " + str(player_node.max_speed)
	acceleration_label.text = "Acceleration: " + str(player_node.acceleration)
	friction_label.text = "Friction: " + str(player_node.friction)
	air_friction_label.text = "Air Friction: " + str(player_node.air_friction)
	brake_force_label.text = "Brake Force: " + str(player_node.brake_force)
	turn_threshold_label.text = "Turn Threshold: " + str(player_node.turn_threshold)
	base_turn_boost_label.text = "Base Turn Boost: " + str(player_node.base_turn_boost)
	jump_velocity_label.text = "Jump Velocity: " + str(player_node.jump_velocity)
	dash_cooldown_label.text = "Dash Cooldown: " + str(player_node.dash_cooldown_time)
	dash_speed_label.text = "Dash Speed: " + str(player_node.dash_speed)
	dash_duration_label.text = "Dash Duration: " + str(player_node.dash_duration)
	min_air_time_label.text = "Min Air Time: " + str(player_node.min_air_time_for_dash)
	min_speed_dash_label.text = "Min Speed Dash: " + str(player_node.min_speed_for_dash)
	roll_min_speed_label.text = "Roll Min Speed: " + str(player_node.roll_min_speed)
	roll_max_time_label.text = "Roll Max Time: " + str(player_node.roll_max_time)

func _unhandled_input(event):
	# Handle P key toggle
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		visible = !visible
		print("Debug UI: P pressed, visible = ", visible)
		var control_node = $Control
		if control_node:
			control_node.visible = visible
			print("Debug UI: Control visible = ", control_node.visible)
		get_viewport().set_input_as_handled()
	
	# Test slider with O key
	elif event is InputEventKey and event.pressed and event.keycode == KEY_O:
		if max_speed_slider:
			print("Testing slider - setting value to 3000")
			max_speed_slider.value = 3000
		else:
			print("Max speed slider is null!")
		get_viewport().set_input_as_handled()

func is_mouse_over_panel() -> bool:
	if not visible:
		return false
	
	var panel_node = $Control/Panel
	if not panel_node:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	var panel_rect = Rect2(panel_node.global_position, panel_node.size)
	return panel_rect.has_point(mouse_pos)

func _on_max_speed_changed(value):
	print("Max speed slider changed to: ", value)
	if player_node:
		player_node.max_speed = value
		update_labels()
	else:
		print("ERROR: Player node is null!")

func _on_acceleration_changed(value):
	player_node.acceleration = value
	update_labels()

func _on_friction_changed(value):
	player_node.friction = value
	update_labels()

func _on_air_friction_changed(value):
	player_node.air_friction = value
	update_labels()

func _on_brake_force_changed(value):
	player_node.brake_force = value
	update_labels()

func _on_turn_threshold_changed(value):
	player_node.turn_threshold = value
	update_labels()

func _on_base_turn_boost_changed(value):
	player_node.base_turn_boost = value
	update_labels()

func _on_jump_velocity_changed(value):
	player_node.jump_velocity = value
	update_labels()

func _on_dash_cooldown_changed(value):
	player_node.dash_cooldown_time = value
	update_labels()

func _on_dash_speed_changed(value):
	player_node.dash_speed = value
	update_labels()

func _on_dash_duration_changed(value):
	player_node.dash_duration = value
	update_labels()

func _on_min_air_time_changed(value):
	player_node.min_air_time_for_dash = value
	update_labels()

func _on_min_speed_dash_changed(value):
	player_node.min_speed_for_dash = value
	update_labels()

func _on_roll_min_speed_changed(value):
	player_node.roll_min_speed = value
	update_labels()

func _on_roll_max_time_changed(value):
	player_node.roll_max_time = value
	update_labels()
