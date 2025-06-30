extends Area2D

signal mission_completed

var player_nearby = false
var dialogue_system = null
@onready var prompt_label = $PromptLabel
@onready var sprite = $Sprite2D

# Floating animation variables
var float_time = 0.0
var base_position: Vector2
var is_speaking = false
var speak_timer = 0.0
var speak_duration = 0.0

var conversation_sets = [
	[
		"Huh? You asked where the job is? It's up there. A bit of a hike.",
	],
	[
		"A depressed fuck like you looks the type. You'll probably have no problem getting accepted.",
	],
	[
		"No, I'm not going to teach you how to play the game. Who the fuck do you think I am?",
	],
	[
		"Fine, since you asked nicely. Shift key to do an air dash. Click to use your scythe.",
	],
	[
		"Don't ask how I know that. I've dealt with slimy little ghouls like yourself before.",
	],
	[
		"Anyway....",
	],
	[
		"Those morbid little shits up there have been trying to whack me ever since I can remember.",
	],
	[
		"I came to this shithole to try get back at them, And now I'm a floating fish. You win some, you lose some.",
	],
	[
		"They're understaffed, so it's been alright recently. If you get the job, don't kill me, alright?
		I helped you out, didn't I?",
	],
	[
		"I'm glad we're on the same page.",
	],
	[
		"Alright, you can fuck off now.",
	],
	[
		"I wasn't joking, kid. Move it.",
	]
	
]

var current_conversation_index = 0
var handler_mission_briefed = false
var ever_spoken_to_fish = false

var post_briefing_conversation_sets = [
	[
		"Back so soon? Did you flunk the interview or something?",
	],
	[
		"Oh, you did get the job. Good for you, I guess.",
	],
	[
		"What do you mean you have to kill me?",
	],
	[
		"Fat chance, kid. We made a fucking deal. No takesies-backsies.",
	],
	[
		"I knew those pricks would try rub me out permanently now or later.",
	],
	[
		"Go back up there and tell those good-for-nothing clods that you sliced me up real good, and leave me the fuck alone.",
	],
	[
		"I'll even give you this pack of cigarettes. Never too young to start a nice little nicotine habit.",
	],
	[
		"I got no use for them now, being a fish n' all.",
	],
	[
		"Here. Take em. Now back away slowly.",
	],
	[
		"I said shove it, kid!",
	]
]

var post_briefing_index = 0

var first_time_post_briefing_dialogue = [
	[
		"Who the fuck are you? New kid on the block?",
	],
	[
		"Department of Death, special kill warrant? Yeah, fat fucking chance, Kid.",
	],
	[
		"Those morons have been trying to wipe me off the map for thousands of years, and you sure as sugar won't be the idiot to finish the job.",
	],
	[
		"Do yourself a favour and tell those braindead beurocrats you sliced me up realllll good.",
	],
	[
		"Good riddance.",
	]
]

var first_time_index = 0
var is_jumping_away = false
var mission_completed_already = false

func _ready():
	add_to_group("fish")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	base_position = sprite.position
	# Set LiberationSans Bold Italic font for prompt label
	var liberation_font = load("res://Assets/LiberationSans-BoldItalic.ttf") as FontFile
	prompt_label.add_theme_font_override("font", liberation_font)
	prompt_label.scale = Vector2(1.0, 1.2)  # 1.2x vertical stretch
	# Find dialogue system after scene is ready
	call_deferred("find_dialogue_system")

func _process(delta):
	float_time += delta
	
	# Floating animation
	var float_offset = sin(float_time * 2.0) * 3.0
	
	if is_speaking:
		# Shaking while speaking
		speak_timer += delta
		var shake_intensity = 2.0
		var shake_x = randf_range(-shake_intensity, shake_intensity)
		var shake_y = randf_range(-shake_intensity, shake_intensity)
		sprite.position = base_position + Vector2(shake_x, shake_y + float_offset)
		
		# Stop shaking when speak duration is over
		if speak_timer >= speak_duration:
			is_speaking = false
			speak_timer = 0.0
	else:
		# Just floating
		sprite.position = base_position + Vector2(0, float_offset)

func find_dialogue_system():
	dialogue_system = get_tree().get_first_node_in_group("dialogue_system")

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		if prompt_label:
			prompt_label.visible = false

func _input(event):
	if player_nearby and event.is_action_pressed("interact"):
		talk_to_fish()

func talk_to_fish():
	if not dialogue_system:
		find_dialogue_system()
	
	if dialogue_system:
		# Hide the Press F prompt during dialogue
		if prompt_label:
			prompt_label.visible = false
		
		# Check if handler has given mission briefing
		check_handler_briefing_status()
		
		if handler_mission_briefed and not ever_spoken_to_fish:
			# Special case: first time talking to fish after handler briefing
			var current_conversation = first_time_post_briefing_dialogue[first_time_index]
			dialogue_system.start_conversation("Fish", current_conversation)
			first_time_index += 1
			# Check if this is the last dialogue line
			if first_time_index >= first_time_post_briefing_dialogue.size():
				is_jumping_away = true
		elif handler_mission_briefed and ever_spoken_to_fish:
			# Normal post-briefing dialogue (fish already met player before)
			var current_conversation = post_briefing_conversation_sets[post_briefing_index]
			dialogue_system.start_conversation("Fish", current_conversation)
			
			# Show status text when Jeffery gives cigarettes (conversation 6: "Here. Take em. Now back away slowly.")
			if post_briefing_index == 6:
				show_cigarette_status("Received: Pack of Cigarettes from Jeffery", Color.WHITE)
			
			post_briefing_index = (post_briefing_index + 1) % post_briefing_conversation_sets.size()
		else:
			# Normal dialogue (before handler briefing)
			var current_conversation = conversation_sets[current_conversation_index]
			dialogue_system.start_conversation("Fish", current_conversation)
			current_conversation_index = (current_conversation_index + 1) % conversation_sets.size()
			ever_spoken_to_fish = true

func _on_dialogue_ended():
	# Check if this was a post-briefing conversation (mission completion)
	if handler_mission_briefed and not mission_completed_already:
		# Check if this is the completion of the mission (final dialogue)
		var mission_just_completed = false
		
		# For first-time post-briefing dialogue, mission completes when fish jumps away
		if first_time_index >= first_time_post_briefing_dialogue.size():
			mission_just_completed = true
		
		# For normal post-briefing dialogue, mission completes after cigarettes are given (index 6)
		elif ever_spoken_to_fish and post_briefing_index == 0 and post_briefing_conversation_sets.size() > 0:
			# We've wrapped around, meaning we completed all dialogue
			mission_just_completed = true
		
		if mission_just_completed:
			mission_completed_already = true  # Prevent multiple completions
			print("Fish: Mission completed! Jeffery mission finished.")
			# Show TARGET NOT ELIMINATED message
			show_target_not_eliminated()
			# Emit signal to notify Manager and Handler that mission is complete
			mission_completed.emit()
			# Update global game state
			GameState.complete_jeffery_mission()
			print("Fish: GameState.complete_jeffery_mission() called, jeffery_mission_completed=", GameState.jeffery_mission_completed)
			# Connect to Manager and Handler to update their state
			var manager = get_tree().get_first_node_in_group("manager")
			var handler = get_tree().get_first_node_in_group("handler")
			if manager and manager.has_method("_on_mission_completed"):
				print("Fish: Calling manager._on_mission_completed()")
				manager._on_mission_completed()
			if handler and handler.has_method("_on_mission_completed"):
				print("Fish: Calling handler._on_mission_completed()")
				handler._on_mission_completed()
			else:
				print("Fish: Handler not found or doesn't have _on_mission_completed method")
	
	# Check if fish should jump away
	if is_jumping_away:
		jump_off_stage()
	else:
		# Show the Press F prompt again when dialogue ends (if player is still nearby)
		if player_nearby and prompt_label:
			prompt_label.visible = true
	# Stop speaking animation
	is_speaking = false
	speak_timer = 0.0

func start_speaking(text: String):
	# Calculate speaking duration based on text length (roughly reading speed)
	var words = text.split(" ").size()
	speak_duration = max(1.0, words * 0.15)  # Minimum 1 second, ~0.15 seconds per word
	is_speaking = true
	speak_timer = 0.0

func check_handler_briefing_status():
	# Check if handler has completed his actual mission briefing dialogue
	var handler = get_tree().get_first_node_in_group("handler")
	if handler and "current_conversation_index" in handler and "has_spoken_to_manager" in handler:
		# Handler has given briefing if he's spoken to manager and has progressed through conversations
		handler_mission_briefed = handler.has_spoken_to_manager and handler.current_conversation_index > 0

func jump_off_stage():
	# Disable interaction
	prompt_label.visible = false
	player_nearby = false
	
	# Create a tween to make the fish jump away
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Jump trajectory - move right and up, then down much further
	var jump_target = global_position + Vector2(600, -300)
	var fall_target = global_position + Vector2(1200, 800)  # Much further down to go off-screen
	
	# First jump up and right with easing
	tween.tween_property(self, "global_position", jump_target, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "rotation", deg_to_rad(180), 0.4).set_ease(Tween.EASE_OUT)
	
	# Then fall down with easing
	tween.chain().tween_property(self, "global_position", fall_target, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_property(self, "rotation", deg_to_rad(540), 0.5).set_ease(Tween.EASE_IN)
	
	# Finally, remove the fish from the scene
	tween.chain().tween_callback(func(): queue_free())

func show_cigarette_status(text: String, color: Color = Color.WHITE):
	# Find the GameUI and show status text
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if not game_ui:
		# Try to find it through the main scene
		var main_scene = get_tree().get_first_node_in_group("main_scene")
		if main_scene:
			for child in main_scene.get_children():
				if child.has_method("show_status_text"):
					game_ui = child
					break
	
	if game_ui and game_ui.has_method("show_status_text"):
		game_ui.show_status_text(text, color)

func show_target_not_eliminated():
	print("Fish: show_target_not_eliminated() called")
	
	# Create the overlay using a static function to avoid any node dependencies
	_create_target_not_eliminated_overlay()

# Static function that creates the overlay independently
static func _create_target_not_eliminated_overlay():
	# Get the scene tree from the main tree singleton
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		print("Fish: Could not get scene tree")
		return
	
	# Create a CanvasLayer for the overlay to ensure it appears on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to appear on top
	scene_tree.root.add_child(canvas_layer)
	
	# Create a control that fills the screen
	var control = Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(control)
	
	# Create the TARGET NOT ELIMINATED label
	var label = Label.new()
	label.text = "TARGET NOT ELIMINATED"
	label.modulate = Color(1.0, 0.0, 0.0, 0.0)  # Start with transparent red
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Use Georgia font with large size and 1.7x vertical stretch
	var georgia_font = load("res://Assets/georgia-2/georgia.ttf") as FontFile
	if georgia_font:
		label.add_theme_font_override("font", georgia_font)
		label.add_theme_font_size_override("font_size", 120)  # Large font
		print("Fish: Font applied successfully")
	else:
		print("Fish: Failed to load Georgia font")
	
	# Apply vertical stretch with center pivot
	var viewport_size = scene_tree.root.get_viewport().get_visible_rect().size
	label.pivot_offset = viewport_size / 2  # Set pivot to center of screen
	label.scale = Vector2(1.0, 1.7)  # 1.7x vertical stretch
	
	control.add_child(label)
	print("Fish: Label added to control")
	
	# Create an independent tween using the scene tree
	var tween = scene_tree.create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.8)  # Fade in
	tween.tween_interval(3.5)  # Stay visible for 3.5 seconds
	tween.tween_property(label, "modulate:a", 0.0, 1.2)  # Fade out slower
	
	# Use tween callback to clean up
	tween.tween_callback(func():
		print("Fish: Tween completed, cleaning up canvas layer")
		if is_instance_valid(canvas_layer):
			canvas_layer.queue_free()
	)
	
	# Multiple safety cleanup mechanisms - adjust timer for longer duration
	scene_tree.create_timer(6.0).timeout.connect(func(): 
		print("Fish: Safety timer triggered")
		if is_instance_valid(canvas_layer):
			print("Fish: Canvas layer still exists, force cleanup")
			canvas_layer.queue_free()
		else:
			print("Fish: Canvas layer already cleaned up")
	)
	
	# Additional cleanup on scene change
	scene_tree.tree_changed.connect(func():
		if is_instance_valid(canvas_layer):
			print("Fish: Scene changed, force cleanup")
			canvas_layer.queue_free()
	, CONNECT_ONE_SHOT)
	
	print("Fish: Tween animation started")
