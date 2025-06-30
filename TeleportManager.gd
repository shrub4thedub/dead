extends Node

# Preload all scenes to avoid runtime loading issues in builds
var main_scene = preload("res://Main.tscn")
var wyoming_scene = preload("res://Wyoming.tscn")

signal teleport_started
signal teleport_completed

func _ready():
	add_to_group("teleport_manager")
	print("TeleportManager: Ready")
	print("TeleportManager: main_scene valid: ", main_scene != null)
	print("TeleportManager: wyoming_scene valid: ", wyoming_scene != null)
	if main_scene:
		print("TeleportManager: main_scene type: ", typeof(main_scene))
	if wyoming_scene:
		print("TeleportManager: wyoming_scene type: ", typeof(wyoming_scene))

func teleport_to_wyoming():
	print("TeleportManager: Starting immediate teleport to Wyoming")
	emit_signal("teleport_started")
	
	# Direct scene change without fade for testing
	print("TeleportManager: Attempting change_scene_to_packed")
	var error = get_tree().change_scene_to_packed(wyoming_scene)
	if error != OK:
		print("TeleportManager: change_scene_to_packed failed with error: ", error)
		print("TeleportManager: Trying fallback change_scene_to_file")
		var error2 = get_tree().change_scene_to_file("res://Wyoming.tscn")
		if error2 != OK:
			print("TeleportManager: Fallback also failed with error: ", error2)
		else:
			print("TeleportManager: Fallback successful")
	else:
		print("TeleportManager: change_scene_to_packed successful")
	
	emit_signal("teleport_completed")

func teleport_to_main():
	print("TeleportManager: Starting immediate teleport to Main")
	emit_signal("teleport_started")
	
	# Set return position before teleporting
	GameState.return_position = Vector2(1600, -2371)
	
	# Direct scene change without fade for testing
	print("TeleportManager: Attempting change_scene_to_packed")
	var error = get_tree().change_scene_to_packed(main_scene)
	if error != OK:
		print("TeleportManager: change_scene_to_packed failed with error: ", error)
		print("TeleportManager: Trying fallback change_scene_to_file")
		var error2 = get_tree().change_scene_to_file("res://Main.tscn")
		if error2 != OK:
			print("TeleportManager: Fallback also failed with error: ", error2)
		else:
			print("TeleportManager: Fallback successful")
	else:
		print("TeleportManager: change_scene_to_packed successful")
	
	emit_signal("teleport_completed")

func create_fade_overlay():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 1000  # Very high layer
	get_tree().root.add_child(canvas_layer)
	
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)
	
	# Store reference for cleanup
	overlay.set_meta("canvas_layer", canvas_layer)
	
	print("TeleportManager: Fade overlay created")
	return overlay