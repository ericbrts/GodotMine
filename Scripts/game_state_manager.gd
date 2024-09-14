extends Node

@export var ui: UI
@onready var mines_grid: MinesGrid = $"../TileMap"
@onready var settings_window: Window = $"../SettingsWindow"
@onready var timer: Timer = $Timer

var time_elapsed = 0

func _ready():
	mines_grid.game_lost.connect(on_game_lost)
	mines_grid.game_won.connect(on_game_won)
	mines_grid.flag_count_changed.connect(on_flag_count_changed)
	timer.timeout.connect(_on_timer_timeout)
	ui.set_mine_count(mines_grid.nbmines)
	timer.start()
	settings_window.hide()
	
func _on_timer_timeout():
	if time_elapsed < 999:
		time_elapsed += 1
	ui.set_timer_count(time_elapsed)
	
func on_game_lost():
	timer.stop()
	ui.game_lost()
	
func on_game_won():
	timer.stop()
	ui.game_won()
	
func on_flag_count_changed(flag_count):
	ui.set_mine_count(mines_grid.nbmines - flag_count)
	
