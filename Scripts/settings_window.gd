extends Window

class_name SettingsWindow

@onready var row_setter_edit: LineEdit = %RowSetterEdit
@onready var col_setter_edit: LineEdit = %ColSetterEdit
@onready var mine_setter_edit: LineEdit = %MineSetterEdit

var settings_filename: String = "user://settings.json"
var color_invalid = Color(1, 0, 0, 1)
var color_valid = Color(1, 1, 1, 1)

func _on_close_requested() -> void:
	hide()

func _on_focus_exited() -> void:
	hide()

func _fill_settings():
	if FileAccess.file_exists(settings_filename):
		var file = FileAccess.open(settings_filename, FileAccess.READ)
		var settings = JSON.parse_string(file.get_as_text())
		row_setter_edit.text = String.num_int64(settings.rows)
		col_setter_edit.text = String.num_int64(settings.cols)
		mine_setter_edit.text = String.num_int64(settings.mines)
	else:
		row_setter_edit.text = "15"
		col_setter_edit.text = "15"
		mine_setter_edit.text = "20"
		
func _reset_input_color():
	row_setter_edit.set("theme_override_colors/font_color", color_valid)
	col_setter_edit.set("theme_override_colors/font_color", color_valid)
	mine_setter_edit.set("theme_override_colors/font_color", color_valid)

func _validate_inputs():
	_reset_input_color()
	var int_row = int(row_setter_edit.text)
	var int_col = int(col_setter_edit.text)
	var int_mine = int(mine_setter_edit.text)
	var all_valid = true
	if int_row < 1 or int_row > 40:
		row_setter_edit.set("theme_override_colors/font_color", color_invalid)
		#row_setter_edit.modulate = color_invalid
		all_valid = false
	if int_col < 1 or int_col > 60:
		col_setter_edit.set("theme_override_colors/font_color", color_invalid)
		all_valid = false
	if int_mine < 1 or int_mine > int_row*int_col*0.2:
		mine_setter_edit.set("theme_override_colors/font_color", color_invalid)
		all_valid = false
		
	if all_valid:
		return {"rows": int_row, "cols": int_col, "mines": int_mine}
	return false

func _save_settings_to_file():
	var validated_inputs = _validate_inputs()
	if validated_inputs:
		var file = FileAccess.open(settings_filename, FileAccess.WRITE)
		file.store_string(JSON.stringify(validated_inputs))
		return true
	return false

func _on_about_to_popup() -> void:
	_fill_settings()
	_validate_inputs()

func _on_ok_button_pressed() -> void:
	if _save_settings_to_file():
		hide()
		get_tree().reload_current_scene()

func _on_cancel_button_pressed() -> void:
	hide()
