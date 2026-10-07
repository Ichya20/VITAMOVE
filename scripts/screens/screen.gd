class_name Screen
extends Control
## Dasar setiap layar. Main memanggil build() setelah layar masuk ke pohon node.

var main: Node
var params: Dictionary = {}
var content: MarginContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func build() -> void:
	pass


func on_back() -> bool:
	## true bila layar sudah menangani tombol kembali sendiri.
	return false


func default_focus() -> Control:
	return null


func on_leave() -> void:
	Game.stop_speech()


func make_content(extra: float = 28.0) -> MarginContainer:
	## Wadah isi yang menghormati safe area (poni/kamera) perangkat.
	var sa: Vector4 = main.safe_margins() if main else Vector4.ZERO
	content = UI.margin(extra + sa.x, extra * 0.7 + sa.y, extra + sa.z, extra * 0.7 + sa.w)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	return content


func top_bar(title: String, show_home: bool = true) -> HBoxContainer:
	var bar := UI.hbox(14)
	var back := UI.btn("Kembali", "Button", "back", 76, 30)
	back.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.back())
	bar.add_child(back)
	var t := UI.label(title, "H1")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bar.add_child(t)
	if show_home:
		var home := UI.btn("", "Button", "home", 76, 34)
		home.tooltip_text = "Beranda"
		home.set("accessibility_name", "Beranda")
		home.pressed.connect(func() -> void:
			Sfx.play("tap")
			main.home())
		bar.add_child(home)
	bar.set_meta("back", back)
	return bar


func soft_bg(kind: String = "", tod: String = "pagi", veil: float = 0.55) -> Landscape:
	var bg := Landscape.new()
	bg.time_of_day = tod
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if kind != "":
		bg.places = [{"kind": kind, "x": 0.0, "y": 0.0, "s": 0.0}]
		bg.set_meta("kind", kind)
		bg.resized.connect(func() -> void:
			bg.places = [{"kind": kind, "x": bg.size.x * 0.84, "y": bg.size.y * 0.86, "s": bg.size.y / 720.0 * 1.2}])
	add_child(bg)
	if veil > 0.0:
		var v := ColorRect.new()
		v.color = Color(Game.CREAM, veil)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(v)
	return bg
