extends CanvasLayer

class_name UI

@onready var mine_count_label: Label = %MineCountLabel
@onready var game_status_button: TextureButton = %GameStatusButton
@onready var timer_label: Label = %TimerLabel
@onready var settings_window: Window = $"../SettingsWindow"

var game_lost_button_texture = preload("res://Assets/button_dead.png")
var game_won_button_texture = preload("res://Assets/button_cleared.png")

func set_mine_count(mine_count: int):
	mine_count_label.text = "%03d" % mine_count
	
func set_timer_count(timer_count: int):
	if timer_count < 0:
		print("timer_count negative")
		return
	timer_label.text = "%03d" % timer_count

func _on_game_status_button_pressed() -> void:
	get_tree().reload_current_scene()
	
func _on_settings_button_pressed():
	settings_window.show()

func game_lost():
	game_status_button.texture_normal = game_lost_button_texture
	
func game_won():
	game_status_button.texture_normal = game_won_button_texture
