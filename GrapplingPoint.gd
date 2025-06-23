extends Area2D

signal grapple_attached(grapple_point: Vector2)
signal grapple_detached

var is_in_range = false
var connected_player = null
const GRAPPLE_RANGE = 500.0  # Increased for easier grappling
const VISUAL_RANGE = 450.0  # Larger visual range to match

# Visual feedback
var range_indicator: Node2D
var glow_tween: Tween

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("grapple_points")
	
	# Setup visual range indicator
	setup_range_indicator()

func setup_range_indicator():
	range_indicator = Node2D.new()
	add_child(range_indicator)
	
	# Create a subtle range circle
	var circle_points = []
	var segments = 32
	for i in segments + 1:
		var angle = (i * 2 * PI) / segments
		var point = Vector2(cos(angle), sin(angle)) * VISUAL_RANGE
		circle_points.append(point)
	
	# We'll draw this in _draw() function instead

func _draw():
	if is_in_range and connected_player:
		# Draw range indicator
		var circle_color = Color(0.8, 0.8, 1.0, 0.2)
		draw_arc(Vector2.ZERO, VISUAL_RANGE, 0, 2 * PI, 64, circle_color, 2.0)
		
		# Draw glow effect around the grapple point
		var glow_color = Color(0.6, 0.9, 1.0, 0.6)
		draw_circle(Vector2.ZERO, 15.0, glow_color)

func _on_body_entered(body):
	if body.has_method("_on_grapple_point_entered"):
		is_in_range = true
		connected_player = body
		body._on_grapple_point_entered(self)
		queue_redraw()
		
		# Animate glow effect
		if glow_tween:
			glow_tween.kill()
		glow_tween = create_tween()
		glow_tween.set_loops()
		glow_tween.tween_property(self, "modulate:a", 0.7, 0.5)
		glow_tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_body_exited(body):
	if body == connected_player:
		is_in_range = false
		connected_player = null
		if body.has_method("_on_grapple_point_exited"):
			body._on_grapple_point_exited(self)
		queue_redraw()
		
		# Stop glow animation
		if glow_tween:
			glow_tween.kill()
		modulate.a = 1.0

func get_grapple_position() -> Vector2:
	return global_position

func is_player_in_range(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= GRAPPLE_RANGE

func activate_grapple(player):
	if is_in_range and connected_player == player:
		grapple_attached.emit(global_position)
		return true
	return false

func deactivate_grapple():
	grapple_detached.emit()
