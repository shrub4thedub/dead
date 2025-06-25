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

func _ready():
	add_to_group("fish")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	base_position = sprite.position
	# Set Georgia font for prompt label
	var georgia_font = load("res://Assets/georgia-2/georgia.ttf") as FontFile
	prompt_label.add_theme_font_override("font", georgia_font)
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
	if handler_mission_briefed:
		# Emit signal to notify Manager and Handler that mission is complete
		mission_completed.emit()
		# Update global game state
		GameState.complete_jeffery_mission()
		# Connect to Manager and Handler to update their state
		var manager = get_tree().get_first_node_in_group("manager")
		var handler = get_tree().get_first_node_in_group("handler")
		if manager and manager.has_method("_on_mission_completed"):
			manager._on_mission_completed()
		if handler and handler.has_method("_on_mission_completed"):
			handler._on_mission_completed()
	
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
