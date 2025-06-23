extends StaticBody2D

@export var slope_angle: float = 45.0  # Degrees
@export var slope_width: float = 64.0
@export var slope_height: float = 64.0
@export var slope_direction: int = 1  # 1 for right-up, -1 for left-up

func _ready():
	create_slope_collision()

func create_slope_collision():
	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = ConvexPolygonShape2D.new()
	
	# Create slope points based on parameters
	var points = PackedVector2Array()
	
	if slope_direction == 1:  # Right-up slope
		points = PackedVector2Array([
			Vector2(-slope_width/2, slope_height/2),  # Bottom-left
			Vector2(slope_width/2, slope_height/2),   # Bottom-right
			Vector2(slope_width/2, -slope_height/2),  # Top-right
			Vector2(-slope_width/2, slope_height/2)   # Back to bottom-left (closed)
		])
	else:  # Left-up slope
		points = PackedVector2Array([
			Vector2(-slope_width/2, slope_height/2),  # Bottom-left
			Vector2(slope_width/2, slope_height/2),   # Bottom-right
			Vector2(-slope_width/2, -slope_height/2), # Top-left
			Vector2(-slope_width/2, slope_height/2)   # Back to bottom-left (closed)
		])
	
	shape.points = points
	collision.shape = shape
	add_child(collision)
	
	# Optional: Add visual representation
	create_slope_visual()

func create_slope_visual():
	# Create a simple colored polygon for visualization
	var polygon = Polygon2D.new()
	var points = PackedVector2Array()
	
	if slope_direction == 1:
		points = PackedVector2Array([
			Vector2(-slope_width/2, slope_height/2),
			Vector2(slope_width/2, slope_height/2),
			Vector2(slope_width/2, -slope_height/2)
		])
	else:
		points = PackedVector2Array([
			Vector2(-slope_width/2, slope_height/2),
			Vector2(slope_width/2, slope_height/2),
			Vector2(-slope_width/2, -slope_height/2)
		])
	
	polygon.polygon = points
	polygon.color = Color(0.6, 0.4, 0.2, 0.8)  # Brown slope color
	add_child(polygon)