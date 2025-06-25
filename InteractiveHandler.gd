extends Area2D

var player_nearby = false
var dialogue_system = null
@onready var prompt_label = $PromptLabel
@onready var sprite = $Sprite2D

# Handler sits still - no animations

var conversation_sets = [
	[
		"Alright, let's see here...",
	],
	[
		"Trial mission for you... yep... on it...",
	],
	[
		"Got it. You have to kill Jeffery.",
	],
	[
		"Huh? Oh, Jeffery is this annoying little prick who was rebelling against death for years.",
	],
	[
		"They sent Grim after him, Yes, Grim Reaper, this department's claim to fame.",
	],
	[
		"Even Grim couldn't kill him. Incredible really.",
	],
	[
		"Jeffery got so pissed off he came down to the Underworld to fight us here. No one's sure how he got here.",
	],
	[
		"Then Grim turned him into a fucking fish! That was the problem with Grim, fame got to his head, thought he could do what he liked.",
	],
	[
		"We had to let Grim go eventually, when tried to reap JFK. bullet went straight through JFK, hit grim right in the skull. ",
	],
	[
		"Anyway, back to your mission. Yeah, he's a fish now, been floating there for a few millenia.",
	],
	[
		"Manager says we have to get rid of him now. Should be easy.",
	],
	[
		"Now that I think about it, you probably saw him on your way up here.",
	],
	[
		"Aye, it's your first job, dont screw it up.",
	],
	[
		"Go on, get moving.",
	]
]

var current_conversation_index = 0
var has_spoken_to_manager = false
var mission_completed = false

var post_mission_dialogue = [
	[
		"Huh, that was quick. You dealt with him?",
	],
	[
		"Good job. Geez, we've been sending guys after that nuisance for years.",
	],
	[
		"Huh? Oh, the Manager's gone to attend to more important business.",
	],
	[
		"Alright, you're next mission... What have we got here...",
	],
	[
		"Right. Those absolute boneheads at the Department of Life have dreampt up something called the 'Antichrist'",
	],
	[
		"Some kind of evil baby, or some shit like that. I dunno, I never understood Christian eschatology.",
	],
	[
		"Anyway, it was born on Earth, somewhere called Wyoming. Go catch the next interdimensional train and kill it.",
	],
	[
		"Get moving, we got a deadline to meet, or this kid might trigger the apocalypse or something.",
	],
	[
		"The train station is now unlocked for you. Go catch that train to Wyoming.",
	]
]

var post_antichrist_dialogue = [
	[
		"Oh, you're back. How did it go?",
	],
	[
		"The Antichrist is dead? Well I'll be damned. Good work.",
	],
	[
		"That was probably the most important job we've had in centuries.",
	],
	[
		"Alright, here's your next assignment. There's a new realm that's opened up.",
	],
	[
		"Go to the train station, take the train, and investigate this new realm.",
	],
	[
		"The door should appear near me when you return from the train station.",
	]
]

var post_mission_index = 0
var post_antichrist_index = 0
var antichrist_mission_complete = false
var door_spawned = false

func _ready():
	add_to_group("handler")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Set Georgia font for prompt label
	var georgia_font = load("res://Assets/georgia-2/georgia.ttf") as FontFile
	prompt_label.add_theme_font_override("font", georgia_font)
	# Find dialogue system after scene is ready
	call_deferred("find_dialogue_system")
	# Connect to game state signals
	call_deferred("connect_game_state_signals")

func _process(delta):
	# Handler sits completely still - no floating or shaking
	pass

func find_dialogue_system():
	dialogue_system = get_tree().get_first_node_in_group("dialogue_system")

func connect_game_state_signals():
	GameState.antichrist_killed.connect(_on_antichrist_killed)
	GameState.train_station_visited_after_antichrist_death.connect(_on_train_station_visited_after_antichrist)

func _on_antichrist_killed():
	antichrist_mission_complete = true
	print("Handler: Antichrist mission complete")

func _on_train_station_visited_after_antichrist():
	if not door_spawned:
		spawn_door_near_handler()
		door_spawned = true

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
		talk_to_handler()

func talk_to_handler():
	if not dialogue_system:
		find_dialogue_system()
	
	if dialogue_system:
		# Hide the Press F prompt during dialogue
		if prompt_label:
			prompt_label.visible = false
		
		if antichrist_mission_complete:
			# Use post-antichrist dialogue
			var current_conversation = post_antichrist_dialogue[post_antichrist_index]
			dialogue_system.start_conversation("Handler", current_conversation)
			
			post_antichrist_index = (post_antichrist_index + 1) % post_antichrist_dialogue.size()
		elif mission_completed:
			# Use post-mission dialogue
			var current_conversation = post_mission_dialogue[post_mission_index]
			dialogue_system.start_conversation("Handler", current_conversation)
			
			# Show mission status text for second mission (conversation 6: Wyoming antichrist mission)
			if post_mission_index == 6:
				show_mission_status("Mission: Kill the Antichrist in Wyoming", Color.WHITE)
			
			post_mission_index = (post_mission_index + 1) % post_mission_dialogue.size()
			
			# Check if we just finished the final dialogue that unlocks train station
			if post_mission_index == 0 and post_mission_dialogue.size() > 0:
				# We've completed all post-mission dialogue, unlock train station
				var main_scene = get_tree().get_first_node_in_group("main_scene")
				if main_scene and main_scene.has_method("unlock_train_station"):
					main_scene.unlock_train_station()
		else:
			# Check if player has spoken to manager first
			check_manager_interaction()
			
			if not has_spoken_to_manager:
				# Show redirect message if haven't spoken to manager
				var redirect_dialogue = ["You here for the job? Go speak to the manager."]
				dialogue_system.start_conversation("Handler", redirect_dialogue)
			else:
				# Get current conversation set
				var current_conversation = conversation_sets[current_conversation_index]
				dialogue_system.start_conversation("Handler", current_conversation)
				
				# Show mission status text when giving the initial mission (conversation 2: "Got it. You have to kill Jeffery.")
				if current_conversation_index == 2:
					show_mission_status("Mission: Kill Jeffery the Fish", Color.WHITE)
				
				# Move to next conversation for next time
				current_conversation_index = (current_conversation_index + 1) % conversation_sets.size()

func _on_dialogue_ended():
	# Show the Press F prompt again when dialogue ends (if player is still nearby)
	if player_nearby and prompt_label:
		prompt_label.visible = true

func start_speaking(text: String):
	# Handler doesn't animate when speaking - stays completely still
	pass

func _on_mission_completed():
	# Handler switches to post-mission dialogue
	mission_completed = true

func check_manager_interaction():
	# Check if the manager has progressed beyond first conversation
	var manager = get_tree().get_first_node_in_group("manager")
	if manager and manager.has_method("get_conversation_index"):
		has_spoken_to_manager = manager.get_conversation_index() > 0
	elif manager and "current_conversation_index" in manager:
		has_spoken_to_manager = manager.current_conversation_index > 0

func show_mission_status(text: String, color: Color = Color.WHITE):
	# Find the GameUI and show status text
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if not game_ui:
		# Try to find it through the main scene
		var main_scene = get_tree().get_first_node_in_group("main_scene")
		if main_scene:
			for child in main_scene.get_children():
				if child is GameUI:
					game_ui = child
					break
	
	if game_ui and game_ui.has_method("show_status_text"):
		game_ui.show_status_text(text, color)

func spawn_door_near_handler():
	# Create a new door instance near the handler
	var door_scene = preload("res://Door.tscn")
	var door_instance = door_scene.instantiate()
	
	# Position the door near the handler (100 pixels to the right)
	door_instance.position = position + Vector2(100, 0)
	
	# Add the door to the same parent as the handler
	get_parent().add_child(door_instance)
	
	print("Handler: Door spawned near handler")
