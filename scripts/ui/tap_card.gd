class_name TapCard
extends PanelContainer
## Kartu yang dapat diketuk (seperti tombol) namun berisi tata letak bebas.
## Aman di dalam ScrollContainer: geser untuk menggulir tidak memicu ketukan.

signal pressed

@export var toggle := false
var selected := false: set = set_selected
var disabled := false: set = set_disabled
var base_style := "Tile"
var state_style := ""
var access_name := ""

var _down := false
var _press_pos := Vector2.ZERO
var _focus_sb: StyleBoxFlat


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	theme_type_variation = "Tile"
	_focus_sb = StyleBoxFlat.new()
	_focus_sb.draw_center = false
	_focus_sb.set_border_width_all(4)
	_focus_sb.border_color = Color("23302e")
	_focus_sb.set_corner_radius_all(32)
	_focus_sb.set_expand_margin_all(6)
	_focus_sb.anti_aliasing = true
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func set_selected(v: bool) -> void:
	selected = v
	_refresh()


func set_disabled(v: bool) -> void:
	disabled = v
	focus_mode = Control.FOCUS_NONE if v else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_ARROW if v else Control.CURSOR_POINTING_HAND
	_refresh()


func set_state(style: String) -> void:
	state_style = style
	_refresh()


func _refresh() -> void:
	if disabled and state_style == "":
		theme_type_variation = "TileDisabled"
	elif state_style != "":
		theme_type_variation = state_style
	elif _down:
		theme_type_variation = "TilePressed"
	elif selected:
		theme_type_variation = "TileSelected"
	else:
		theme_type_variation = base_style


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_down = true
			_press_pos = mb.global_position
			_refresh()
			UI.press_anim(self, true)
		elif _down:
			_down = false
			_refresh()
			UI.press_anim(self, false)
			if get_global_rect().has_point(mb.global_position) and mb.global_position.distance_to(_press_pos) < 26.0:
				_fire()
	elif event is InputEventMouseMotion and _down:
		if (event as InputEventMouseMotion).global_position.distance_to(_press_pos) > 26.0:
			_down = false
			_refresh()
			UI.press_anim(self, false)
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		UI.press_anim(self, true)
		get_tree().create_timer(0.08).timeout.connect(func() -> void: UI.press_anim(self, false))
		_fire()


func _fire() -> void:
	if toggle:
		selected = not selected
	pressed.emit()


func _draw() -> void:
	if has_focus():
		draw_style_box(_focus_sb, Rect2(Vector2.ZERO, size))
