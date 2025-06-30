extends Node

signal antichrist_killed
signal train_station_visited_after_antichrist_death

var antichrist_is_dead: bool = false
var has_visited_train_station_after_antichrist: bool = false
var jeffery_mission_completed: bool = false
var return_position: Vector2 = Vector2(0, 0)  # Position to spawn player when returning to Main scene

func _ready():
	add_to_group("game_state")

func kill_antichrist():
	if not antichrist_is_dead:
		antichrist_is_dead = true
		antichrist_killed.emit()
		print("GameState: Antichrist has been killed")

func complete_jeffery_mission():
	if not jeffery_mission_completed:
		jeffery_mission_completed = true
		print("GameState: Jeffery mission completed")

func visit_train_station():
	print("GameState: visit_train_station called. antichrist_is_dead=", antichrist_is_dead, " has_visited=", has_visited_train_station_after_antichrist)
	if antichrist_is_dead and not has_visited_train_station_after_antichrist:
		has_visited_train_station_after_antichrist = true
		train_station_visited_after_antichrist_death.emit()
		print("GameState: Player visited train station after killing Antichrist")