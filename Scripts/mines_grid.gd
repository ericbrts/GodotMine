extends TileMap

class_name MinesGrid

signal game_lost
signal game_won
signal flag_count_changed(fc)

@onready var camera_2d: Camera2D = $Camera2D
@onready var settings_window: SettingsWindow = $"../SettingsWindow"

const CELL = {
	"1": Vector2i(0, 0),
	"2": Vector2i(1, 0),
	"3": Vector2i(2, 0),
	"4": Vector2i(3, 0),
	"5": Vector2i(4, 0),
	"6": Vector2i(0, 1),
	"7": Vector2i(1, 1),
	"8": Vector2i(2, 1),
	"empty": Vector2i(3, 1),
	"boom": Vector2i(4, 1),
	"flag": Vector2i(0, 2),
	"mine": Vector2i(1, 2),
	"unsure": Vector2i(2, 2),
	"unrevealed": Vector2i(3, 2)
}

@export var cols = 15
@export var rows = 15
@export var nbmines = 20

const TILE_SET_ID = 0
const DEFAULT_LAYER = 0

var mines_position = []
var _cells_checked = []
var _is_game_finished = false
var _currently_revealed = 0
var _revealed_to_win
var _flag_count = 0
var _first_reveal = true
var _cam_offset_modifier = Vector2i(0, 0)

func _ready() -> void:
	clear_layer(DEFAULT_LAYER)
	_load_settings()
	for r in rows:
		for c in cols:
			var cell_coord = Vector2i(r - int(rows / 2), c - int(cols / 2))
			set_tile_cell(cell_coord, "unrevealed")
	_revealed_to_win = rows*cols - nbmines
	if int(rows) % 2 == 1:
		_cam_offset_modifier.x = 8
	if int(cols) % 2 == 1:
		_cam_offset_modifier.y = 8
	_set_cam_offset()
	_set_window_size()
	
func _load_settings():
	var settings_filename = settings_window.settings_filename
	if FileAccess.file_exists(settings_filename):
		var file = FileAccess.open(settings_filename, FileAccess.READ)
		var settings = JSON.parse_string(file.get_as_text())
		cols = settings.cols
		rows = settings.rows
		nbmines = settings.mines
	
func _set_window_size():
	var sz = Vector2(rows*16*camera_2d.zoom.x, cols*16*camera_2d.zoom.y+40)
	var win = get_window()
	win.size.x = max(sz.x, 240)
	win.size.y = sz.y

func _input(event: InputEvent):
	if _is_game_finished:
		return
	
	if event is not InputEventMouseButton || !event.is_pressed():
		return
		
	var clicked_cell_coords = local_to_map(get_local_mouse_position())
	if event.button_index == MOUSE_BUTTON_MASK_LEFT:
		on_cell_clicked(clicked_cell_coords)
	elif event.button_index == MOUSE_BUTTON_MASK_RIGHT:
		on_cell_flagged(clicked_cell_coords)
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_in()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_out()
		
func zoom_in():
	if camera_2d.zoom.x < 4:
		camera_2d.zoom.x += 0.25
		camera_2d.zoom.y += 0.25
		_set_cam_offset()
		_set_window_size()
		
func zoom_out():
	if camera_2d.zoom.x > 1:
		camera_2d.zoom.x -= 0.25
		camera_2d.zoom.y -= 0.25
		_set_cam_offset()
		_set_window_size()
		
func _set_cam_offset():
	camera_2d.offset.y = -40 / camera_2d.zoom.y / 2 + _cam_offset_modifier.y
	camera_2d.offset.x = _cam_offset_modifier.x
			
func on_cell_flagged(coords: Vector2i):
	var status = get_cell_atlas_coords(DEFAULT_LAYER, coords)
	if status == CELL.unrevealed:
		set_tile_cell(coords, "flag")
		_flag_count += 1
		flag_count_changed.emit(_flag_count)
	elif status == CELL.flag:
		set_tile_cell(coords, "unsure")
	elif status == CELL.unsure:
		set_tile_cell(coords, "unrevealed")
		_flag_count -= 1
		flag_count_changed.emit(_flag_count)
		
	
func place_mines(avoid_coords):
	for i in nbmines:
		var rdm_coord = Vector2i(randi_range(- rows/2, rows/2 - 1), randi_range(- cols/2, cols/2 - 1))
		while mines_position.has(rdm_coord) or avoid_coords == rdm_coord:
			rdm_coord = Vector2i(randi_range(- rows/2, rows/2 - 1), randi_range(- cols/2, cols/2 - 1))
		mines_position.append(rdm_coord)
		
	print(mines_position.size())
		
	for coords in mines_position:
		erase_cell(DEFAULT_LAYER, coords)
		set_cell(DEFAULT_LAYER, coords, TILE_SET_ID, CELL.unrevealed, 1)
			
func set_tile_cell(cell_coord: Vector2, cell_type: String):
	set_cell(DEFAULT_LAYER, cell_coord, TILE_SET_ID, CELL[cell_type])

func on_cell_clicked(cell_coord: Vector2i):
	print(cell_coord)
	
	if _first_reveal:
		_first_reveal = false
		place_mines(cell_coord)
	
	var status = get_cell_atlas_coords(DEFAULT_LAYER, cell_coord)
	if status == CELL.flag || status == CELL.unsure:
		return
		
	if mines_position.any(func (cell): return cell.x == cell_coord.x && cell.y == cell_coord.y):
		lose(cell_coord)
		return
	
	_cells_checked.append(cell_coord)
	_reveal_cells(cell_coord)
	_cells_checked.clear()
	if _currently_revealed == _revealed_to_win:
		_is_game_finished = true
		game_won.emit()
	
func _reveal_cells(cell_coord: Vector2i):
	var tile_data = get_cell_tile_data(DEFAULT_LAYER, cell_coord)
	if tile_data == null:  # if outside of the grid
		return
		
	var status = get_cell_atlas_coords(DEFAULT_LAYER, cell_coord)
	if status != CELL.unrevealed:
		return
		
	var has_mine = tile_data.get_custom_data("has_mine")
	if has_mine:
		return
	_currently_revealed += 1
	var mine_count = get_surrounding_cells_mine_count(cell_coord)
	if mine_count == 0:
		set_tile_cell(cell_coord, "empty")
		var neighbors = get_surrounding_cells_with_diagonals(cell_coord)
		for cell in neighbors:
			if not _cells_checked.has(cell):
				_cells_checked.append(cell)
				_reveal_cells(cell)
	else:
		set_tile_cell(cell_coord, "%d" % mine_count)
	
func get_surrounding_cells_mine_count(cell_coord: Vector2i):
	var mine_count = 0
	var neighbors = get_surrounding_cells_with_diagonals(cell_coord)
	for cell in neighbors:
		if mines_position.has(cell):
			mine_count += 1
	return mine_count
	
func get_surrounding_cells_with_diagonals(cell_coord: Vector2i):
	var target
	var neighbors = []
	
	for x in 3:
		for y in 3:
			if x == 1 and y == 1:
				continue
			target = cell_coord + Vector2i(x-1, y-1)
			neighbors.append(target)
	return neighbors
	
func lose(coord: Vector2i):
	game_lost.emit()
	_is_game_finished = true
	
	# Reveal all mine positions
	for cell in mines_position:
		set_tile_cell(cell, "mine")
	set_tile_cell(coord, "boom")
