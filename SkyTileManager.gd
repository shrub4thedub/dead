extends Node2D

# Sky tile management
var sky_texture: Texture2D
var tile_size: Vector2 = Vector2(500, 500)  # Matches the actual Seamless_Sky.PNG size
var active_tiles: Dictionary = {}
var camera: Camera2D
var last_camera_pos: Vector2

func _ready():
	# Load the seamless sky texture
	sky_texture = load("res://Assets/Seamless_Sky.PNG")
	
	# Find the camera (it's attached to the player)
	call_deferred("find_camera")

func find_camera():
	var player = get_node("../Player")
	if player:
		camera = player.get_node("Camera2D2")
		if camera:
			print("SkyTileManager: Found camera")
		else:
			print("SkyTileManager: Camera not found")
	else:
		print("SkyTileManager: Player not found")

func _process(_delta):
	if camera:
		var camera_pos = camera.global_position
		
		# Only update if camera moved significantly
		if camera_pos.distance_to(last_camera_pos) > 100:
			update_sky_tiles(camera_pos)
			last_camera_pos = camera_pos

func update_sky_tiles(camera_pos: Vector2):
	# Calculate which tiles should be visible
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera.zoom if camera else Vector2(1, 1)
	var effective_viewport = viewport_size / zoom
	
	# Add some padding to ensure smooth transitions
	var padding = tile_size * 2
	var start_x = int((camera_pos.x - effective_viewport.x/2 - padding.x) / tile_size.x) * tile_size.x
	var end_x = int((camera_pos.x + effective_viewport.x/2 + padding.x) / tile_size.x) * tile_size.x
	var start_y = int((camera_pos.y - effective_viewport.y/2 - padding.y) / tile_size.y) * tile_size.y
	var end_y = int((camera_pos.y + effective_viewport.y/2 + padding.y) / tile_size.y) * tile_size.y
	
	var needed_tiles: Dictionary = {}
	
	# Generate tiles in a grid around the camera
	for x in range(start_x, end_x + tile_size.x, tile_size.x):
		for y in range(start_y, end_y + tile_size.y, tile_size.y):
			var tile_key = Vector2(x, y)
			needed_tiles[tile_key] = true
			
			# Create tile if it doesn't exist
			if not active_tiles.has(tile_key):
				create_sky_tile(tile_key)
	
	# Remove tiles that are no longer needed
	var tiles_to_remove = []
	for tile_key in active_tiles.keys():
		if not needed_tiles.has(tile_key):
			tiles_to_remove.append(tile_key)
	
	for tile_key in tiles_to_remove:
		remove_sky_tile(tile_key)

func create_sky_tile(tile_pos: Vector2):
	var sprite = Sprite2D.new()
	sprite.texture = sky_texture
	sprite.position = tile_pos + tile_size / 2  # Center the sprite on the tile
	add_child(sprite)
	active_tiles[tile_pos] = sprite

func remove_sky_tile(tile_pos: Vector2):
	if active_tiles.has(tile_pos):
		var sprite = active_tiles[tile_pos]
		sprite.queue_free()
		active_tiles.erase(tile_pos)