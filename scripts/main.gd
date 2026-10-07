extends Control
## Pengatur layar, transisi kertas, dialog, notifikasi singkat, dan tombol kembali Android.

const SCREENS := {
	"splash": preload("res://scripts/screens/splash_screen.gd"),
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
var _toast_layer: Control
var _wipe: PaperWipe
var _busy := false
var _dialogs: Array = []
var _toast: PanelContainer


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
	_toast_layer = Control.new()
	UI.full(_toast_layer)
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_layer)
	_wipe = PaperWipe.new()
	UI.full(_wipe)
	add_child(_wipe)
	# Splash beranimasi hanya saat aplikasi pertama dibuka, bukan tiap ke Beranda.
	if Game.splash_shown:
		go("title")
	else:
		Game.splash_shown = true
		go("splash")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tour=") and ResourceLoader.exists("res://scripts/dev/tour.gd"):
			var t: Node = load("res://scripts/dev/tour.gd").new()
			t.set("main", self)
			add_child(t)
		elif a.begins_with("--splash-shot=") and ResourceLoader.exists("res://scripts/dev/splash_shot.gd"):
			var ss: Node = load("res://scripts/dev/splash_shot.gd").new()
			ss.set("main", self)
			add_child(ss)
		elif a == "--splash-check" and ResourceLoader.exists("res://scripts/dev/splash_check.gd"):
			var sc: Node = load("res://scripts/dev/splash_check.gd").new()
			sc.set("main", self)
			add_child(sc)


func safe_margins() -> Vector4:
	## Safe area perangkat (poni/kamera) dalam satuan kanvas.
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


func go(screen_name: String, params: Dictionary = {}, replace: bool = false) -> void:
	if _busy:
		return
	if replace and not stack.is_empty():
		stack.pop_back()
	stack.append({"name": screen_name, "params": params})
	_show(screen_name, params, 1.0)


func back() -> void:
	if _busy:
		return
	if stack.size() <= 1:
		confirm_exit()
		return
	stack.pop_back()
	var top: Dictionary = stack.back()
	_show(top["name"], top["params"], -1.0)


func home() -> void:
	if _busy:
		return
	stack = [{"name": "title", "params": {}}]
	_show("title", {}, -1.0)


func replace_with(screen_name: String, params: Dictionary = {}) -> void:
	go(screen_name, params, true)


func refresh() -> void:
	if stack.is_empty():
		return
	var top: Dictionary = stack.back()
	_show(top["name"], top["params"], 0.0)


func _show(screen_name: String, params: Dictionary, dir: float) -> void:
	_busy = true
	if current and dir != 0.0:
		Sfx.play("whoosh")
		if Game.motion():
			_wipe.play(dir)
			await _wipe.covered
		else:
			var f := ColorRect.new()
			f.color = Color(Game.TEAL, 0.0)
			UI.full(f)
			add_child(f)
			var tw := create_tween()
			tw.tween_property(f, "color:a", 0.6, 0.12)
			await tw.finished
			_swap(screen_name, params)
			var tw2 := create_tween()
			tw2.tween_property(f, "color:a", 0.0, 0.18)
			tw2.tween_callback(f.queue_free)
			_busy = false
			return
	_swap(screen_name, params)
	_busy = false


func _swap(screen_name: String, params: Dictionary) -> void:
	close_all_dialogs()
	if is_instance_valid(_toast):
		_toast.queue_free()
	if current:
		current.on_leave()
		current.queue_free()
	var scr: Screen = SCREENS[screen_name].new()
	scr.main = self
	scr.params = params
	_layer.add_child(scr)
	scr.build()
	current = scr


# ------------------------------------------------------------------ dialog

func show_dialog(title: String, text: String, buttons: Array, icon: String = "info", tone: String = "teal") -> Control:
	## buttons: [{ "text": "...", "style": "PrimaryButton", "cb": Callable, "icon": "", "is_cancel": bool }]
	var overlay := ColorRect.new()
	overlay.color = Color(0.03, 0.1, 0.09, 0.0)
	UI.full(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialog_layer.add_child(overlay)
	var center := CenterContainer.new()
	UI.full(center)
	overlay.add_child(center)
	var col := UI.vbox(0)
	center.add_child(col)
	var tone_col: Color = {"teal": Game.TEAL_MID, "terra": Game.TERRA, "sun": Game.SAFFRON_DARK, "leaf": Game.LEAF, "danger": Game.DANGER}.get(tone, Game.TEAL_MID)
	var badge := UI.badge(icon, tone_col, 96)
	badge.z_index = 2
	col.add_child(badge)
	var panel := UI.panel("Cream")
	panel.custom_minimum_size = Vector2(minf(760.0, get_viewport_rect().size.x - 120.0), 0)
	col.add_child(panel)
	col.add_theme_constant_override("separation", -40)
	var box := UI.vbox(16)
	var inner := UI.margin(12, 36, 12, 6)
	inner.add_child(box)
	panel.add_child(inner)
	box.add_child(UI.label(title, "H1", true, HORIZONTAL_ALIGNMENT_CENTER))
	if text != "":
		var tl := UI.label(text, "Lead", true, HORIZONTAL_ALIGNMENT_CENTER)
		box.add_child(tl)
	var row := UI.hbox(18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(UI.gap(4))
	box.add_child(row)
	var first: Button = null
	var cancel_cb := Callable()
	var has_cancel := false
	for b in buttons:
		var bt := UI.btn(str(b.get("text", "OK")), str(b.get("style", "Button")), str(b.get("icon", "")), 84, 32)
		bt.custom_minimum_size.x = maxf(bt.custom_minimum_size.x, 220)
		var cb: Callable = b.get("cb", Callable())
		bt.pressed.connect(func() -> void:
			Sfx.play("tap")
			close_dialog(overlay)
			if cb.is_valid():
				cb.call())
		row.add_child(bt)
		if bool(b.get("is_cancel", false)):
			cancel_cb = cb
			has_cancel = true
		if first == null or str(b.get("style", "")) == "PrimaryButton":
			first = bt
	overlay.set_meta("cancel", cancel_cb)
	overlay.set_meta("has_cancel", has_cancel)
	overlay.set_meta("prev_focus", get_viewport().gui_get_focus_owner())
	_dialogs.append(overlay)
	if current:
		current.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	var tw := create_tween().set_parallel(true)
	tw.tween_property(overlay, "color:a", 0.6, 0.18)
	if Game.motion():
		col.modulate.a = 0.0
		tw.tween_property(col, "modulate:a", 1.0, 0.18)
		tw.tween_callback(func() -> void:
			col.pivot_offset = col.size / 2.0
			col.scale = Vector2(0.9, 0.9))
		tw.tween_property(col, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.01)
	if first:
		first.call_deferred("grab_focus")
	Sfx.play("pop")
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
	if current and is_instance_valid(current):
		current.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED


func has_dialog() -> bool:
	return not _dialogs.is_empty()


func confirm_exit() -> void:
	show_dialog("Keluar dari VITAMOVE?", "Catatan latihan Mbah sudah tersimpan.", [
		{"text": "Tetap di sini", "style": "Button", "is_cancel": true},
		{"text": "Keluar", "style": "PrimaryButton", "cb": Callable(get_tree(), "quit")},
	], "home", "terra")


func toast(text: String, icon: String = "info") -> void:
	## Pesan singkat yang tidak menghalangi (muncul dari atas, hilang sendiri).
	if is_instance_valid(_toast):
		_toast.queue_free()
	var p := UI.panel("Dark")
	var h := UI.hbox(12)
	p.add_child(h)
	h.add_child(Icon.new(icon, Game.SAFFRON, 34))
	var l := UI.label(text, "OnDark", true)
	l.custom_minimum_size.x = 520
	h.add_child(l)
	_toast_layer.add_child(p)
	_toast = p
	p.reset_size()
	var w := get_viewport_rect().size.x
	p.position = Vector2(w / 2.0 - p.size.x / 2.0, -p.size.y - 10)
	var tw := p.create_tween()
	tw.tween_property(p, "position:y", 24.0 + safe_margins().y, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)
	Game.speak(text)


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
		if not bool(d.get_meta("has_cancel", false)):
			return
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
	if get_viewport().gui_get_focus_owner() == null and current:
		for a in ["ui_focus_next", "ui_down", "ui_up", "ui_left", "ui_right"]:
			if event.is_action_pressed(a):
				var f: Control = current.default_focus()
				if f == null:
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
