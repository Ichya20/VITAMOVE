extends Control
## Pengatur layar, transisi, dialog, dan tombol kembali Android.

const SCREENS := {
	"title": preload("res://scripts/screens/title_screen.gd"),
	"profiles": preload("res://scripts/screens/profile_screen.gd"),
	"map": preload("res://scripts/screens/map_screen.gd"),
	"station": preload("res://scripts/screens/station_screen.gd"),
	"journal": preload("res://scripts/screens/journal_screen.gd"),
	"test": preload("res://scripts/screens/test_screen.gd"),
	"session": preload("res://scripts/screens/session_screen.gd"),
	"settings": preload("res://scripts/screens/settings_screen.gd"),
	"info": preload("res://scripts/screens/info_screen.gd"),
}

var stack: Array = []
var current: Screen
var _layer: Control
var _dialog_layer: Control
var _fade: ColorRect
var _busy := false
var _dialogs: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Game.CREAM
	UI.full(bg)
	add_child(bg)
	_layer = Control.new()
	UI.full(_layer)
	add_child(_layer)
	_dialog_layer = Control.new()
	UI.full(_dialog_layer)
	_dialog_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dialog_layer)
	_fade = ColorRect.new()
	_fade.color = Color(Game.TEAL, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(_fade)
	add_child(_fade)
	get_tree().root.size_changed.connect(_on_resize)
	go("title")
	# Tur tangkapan layar khusus pengembang (tidak aktif pada pemakaian normal).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tour=") and ResourceLoader.exists("res://scripts/dev/tour.gd"):
			var t: Node = load("res://scripts/dev/tour.gd").new()
			t.set("main", self)
			add_child(t)


func safe_margins() -> Vector4:
	## Mengubah safe area layar (piksel perangkat) menjadi satuan kanvas.
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0 or safe.size.x <= 0:
		return Vector4.ZERO
	var k := get_viewport_rect().size.x / float(win.x)
	var l := maxf(0.0, safe.position.x) * k
	var t := maxf(0.0, safe.position.y) * k
	var r := maxf(0.0, win.x - safe.end.x) * k
	var b := maxf(0.0, win.y - safe.end.y) * k
	return Vector4(minf(l, 90), minf(t, 60), minf(r, 90), minf(b, 60))


func _on_resize() -> void:
	pass


func go(screen_name: String, params: Dictionary = {}, replace: bool = false) -> void:
	if replace and not stack.is_empty():
		stack.pop_back()
	stack.append({"name": screen_name, "params": params})
	_show(screen_name, params)


func back() -> void:
	if _busy:
		return
	if stack.size() <= 1:
		confirm_exit()
		return
	stack.pop_back()
	var top: Dictionary = stack.back()
	_show(top["name"], top["params"])


func home() -> void:
	stack = [{"name": "title", "params": {}}]
	_show("title", {})


func replace_with(screen_name: String, params: Dictionary = {}) -> void:
	go(screen_name, params, true)


func refresh() -> void:
	## Bangun ulang layar aktif (mis. setelah ukuran teks berubah).
	if stack.is_empty():
		return
	var top: Dictionary = stack.back()
	_show(top["name"], top["params"], false)


func _show(screen_name: String, params: Dictionary, animate: bool = true) -> void:
	_busy = true
	if animate and current:
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 0.55, 0.14)
		await tw.finished
	close_all_dialogs()
	if current:
		current.on_leave()
		current.queue_free()
	var scr: Screen = SCREENS[screen_name].new()
	scr.main = self
	scr.params = params
	_layer.add_child(scr)
	scr.build()
	current = scr
	if animate:
		var tw2 := create_tween()
		tw2.tween_property(_fade, "color:a", 0.0, 0.2)
	_busy = false


# ------------------------------------------------------------------ dialog

func show_dialog(title: String, text: String, buttons: Array, icon: String = "info") -> Control:
	## buttons: [{ "text": "...", "style": "PrimaryButton", "cb": Callable, "icon": "" }]
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.12, 0.11, 0.62)
	UI.full(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialog_layer.add_child(overlay)
	var center := CenterContainer.new()
	UI.full(center)
	overlay.add_child(center)
	var panel := UI.panel("Cream")
	panel.custom_minimum_size = Vector2(minf(820.0, get_viewport_rect().size.x - 120.0), 0)
	center.add_child(panel)
	var box := UI.vbox(18)
	panel.add_child(UI.margin(18, 14, 18, 14))
	panel.get_child(0).add_child(box)
	var head := UI.hbox(16)
	var ic := Icon.new(icon, Game.TERRA, 56)
	head.add_child(ic)
	var tl := UI.label(title, "H2", true)
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(tl)
	box.add_child(head)
	if text != "":
		box.add_child(UI.label(text, "Body", true))
	var row := UI.hbox(18)
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)
	var first: Button = null
	for b in buttons:
		var bt := UI.btn(str(b.get("text", "OK")), str(b.get("style", "Button")), str(b.get("icon", "")), 84, 32)
		var cb: Callable = b.get("cb", Callable())
		bt.pressed.connect(func() -> void:
			Sfx.play("tap")
			close_dialog(overlay)
			if cb.is_valid():
				cb.call())
		row.add_child(bt)
		if first == null:
			first = bt
	overlay.set_meta("cancel", buttons[0].get("cb", Callable()) if buttons.size() > 0 and bool(buttons[0].get("is_cancel", false)) else Callable())
	overlay.set_meta("prev_focus", get_viewport().gui_get_focus_owner())
	_dialogs.append(overlay)
	if current:
		current.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	panel.scale = Vector2(0.94, 0.94)
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if first:
		first.call_deferred("grab_focus")
	Game.speak(title + ". " + text)
	return overlay


func close_dialog(overlay: Control) -> void:
	_dialogs.erase(overlay)
	if _dialogs.is_empty() and current and is_instance_valid(current):
		current.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	if is_instance_valid(overlay):
		var prev = overlay.get_meta("prev_focus", null)
		if prev is Control and is_instance_valid(prev) and (prev as Control).is_visible_in_tree():
			(prev as Control).call_deferred("grab_focus")
		overlay.queue_free()


func close_all_dialogs() -> void:
	for d in _dialogs:
		if is_instance_valid(d):
			d.queue_free()
	_dialogs.clear()


func has_dialog() -> bool:
	return not _dialogs.is_empty()


func confirm_exit() -> void:
	show_dialog("Keluar dari VITAMOVE?", "Catatan latihan Mbah sudah tersimpan.", [
		{"text": "Tetap di sini", "style": "Button", "is_cancel": true},
		{"text": "Keluar", "style": "PrimaryButton", "cb": Callable(get_tree(), "quit")},
	], "home")


# ------------------------------------------------------------------ input

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		Game.stop_speech()


func _handle_back() -> void:
	if _busy:
		return
	if has_dialog():
		var d: Control = _dialogs.back()
		var cb: Callable = d.get_meta("cancel", Callable())
		close_dialog(d)
		if cb.is_valid():
			cb.call()
		return
	if current and current.on_back():
		return
	back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_handle_back()
		return
	if get_viewport().gui_get_focus_owner() == null:
		for a in ["ui_focus_next", "ui_down", "ui_up", "ui_left", "ui_right"]:
			if event.is_action_pressed(a):
				var f: Control = current.default_focus() if current else null
				if f == null and current:
					f = _first_focusable(current)
				if f:
					f.grab_focus()
					get_viewport().set_input_as_handled()
				return


func _first_focusable(n: Node) -> Control:
	for c in n.get_children():
		if c is Control and (c as Control).focus_mode == Control.FOCUS_ALL and (c as Control).is_visible_in_tree():
			return c
		var r := _first_focusable(c)
		if r:
			return r
	return null
