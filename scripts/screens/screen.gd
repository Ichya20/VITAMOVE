class_name Screen
extends Control
## Dasar setiap layar: latar desa, kop (header) rapi, dan wadah isi yang menghormati safe area.

var main: Node
var params: Dictionary = {}
var content: MarginContainer
var back_button: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func build() -> void:
	pass


func on_back() -> bool:
	return false


func default_focus() -> Control:
	return null


func on_leave() -> void:
	Game.stop_speech()


func make_content(extra: float = 28.0) -> MarginContainer:
	var sa: Vector4 = main.safe_margins() if main else Vector4.ZERO
	content = UI.margin(extra + sa.x, extra * 0.62 + sa.y, extra + sa.z, extra * 0.62 + sa.w)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	return content


func header(title: String, eyebrow: String = "", show_home: bool = true) -> HBoxContainer:
	## Kop layar: tombol Kembali, judul dua tingkat, ruang tambahan, dan tombol Beranda.
	var bar := UI.hbox(18)
	bar.custom_minimum_size.y = 84
	back_button = UI.btn("Kembali", "Button", "back", 76, 28)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(func() -> void:
		Sfx.play("tap")
		if not on_back():
			main.back())
	bar.add_child(back_button)
	var tb := UI.vbox(0)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.alignment = BoxContainer.ALIGNMENT_CENTER
	if eyebrow != "":
		tb.add_child(UI.label(eyebrow, "Caption"))
	var t := UI.label(title, "H1")
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.add_theme_constant_override("line_spacing", 0)
	tb.add_child(t)
	bar.add_child(tb)
	bar.set_meta("title", t)
	bar.set_meta("slot", tb)
	if show_home:
		var home := UI.icon_btn("home", "Beranda", "Button", 76)
		home.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		home.pressed.connect(func() -> void:
			Sfx.play("tap")
			main.home())
		bar.add_child(home)
		bar.set_meta("home", home)
	return bar


func header_add(bar: HBoxContainer, c: Control) -> void:
	## Sisipkan kontrol sebelum tombol Beranda.
	bar.add_child(c)
	if bar.has_meta("home"):
		bar.move_child(c, (bar.get_meta("home") as Control).get_index())


func scene_bg(kind: String = "", tod: String = "pagi", veil: float = 0.35) -> Landscape:
	var bg := Landscape.new()
	bg.time_of_day = tod
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if kind != "":
		bg.resized.connect(func() -> void:
			bg.places = [{"kind": kind, "x": bg.size.x * 0.82, "y": bg.size.y * 0.86, "s": bg.size.y / 720.0 * 1.15}])
	add_child(bg)
	var birds := Decor.new("birds")
	birds.anchor_right = 1.0
	birds.anchor_bottom = 0.35
	add_child(birds)
	if veil > 0.0:
		var v := Control.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.full(v)
		v.draw.connect(func() -> void:
			var w := v.size.x
			var h := v.size.y
			v.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
				PackedColorArray([Color(Game.CREAM, veil * 0.6), Color(Game.CREAM, veil * 0.6), Color(Game.CREAM, veil * 1.3), Color(Game.CREAM, veil * 1.3)])))
		add_child(v)
	UI.paper_grain(self, 0.35)
	return bg


func reveal(nodes: Array, delay: float = 0.05) -> void:
	UI.pop_in(nodes, delay, 0.07)
