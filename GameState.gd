extends Node

signal antichrist_killed
signal train_station_visited_after_antichrist_death

var antichrist_is_dead: bool = false
var has_visited_train_station_after_antichrist: bool = false

func _ready():
	add_to_group("game_state")

func kill_antichrist():
	if not antichrist_is_dead:
		antichrist_is_dead = true
		antichrist_killed.emit()
		print("GameState: Antichrist has been killed")

func visit_train_station():
	if antichrist_is_dead and not has_visited_train_station_after_antichrist:
		has_visited_train_station_after_antichrist = true
		train_station_visited_after_antichrist_death.emit()
		print("GameState: Player visited train station after killing Antichrist")