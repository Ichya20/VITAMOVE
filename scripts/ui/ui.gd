class_name UI
extends RefCounted
## Pembuat elemen UI yang konsisten, ramah lansia, dan "juicy".

const FG := {
	"Button": Color("0f4c4a"),
	"PrimaryButton": Color.WHITE,
	"TealButton": Color.WHITE,
	"LeafButton": Color.WHITE,
	"SunButton": Color("23302e"),
	"DangerButton": Color("b3261e"),
	"ChoiceButton": Color("23302e"),
	"GhostButton": Color("0f4c4a"),
}


static func label(text: String, variation: String = "Body", wrap: bool = false, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = align
	if variation == "Caption":
		l.uppercase = true
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func btn(text: String, variation: String = "Button", icon_kind: String = "", min_h: float = 80.0, icon_size: float = 34.0) -> Button:
	var b := Button.new()
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(min_h, min_h)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.set("accessibility_name", text)
	juice(b)
	if icon_kind == "":
		b.text = text
		return b
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_bottom = -4
	var col: Color = FG.get(variation, FG["Button"])
	var ic := Icon.new(icon_kind, col, icon_size)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	if text != "":
		var l := Label.new()
		l.text = text
		l.add_theme_font_override("font", Game.font_bold)
		l.add_theme_font_size_override("font_size", Game.fs(26))
		l.add_theme_color_override("font_color", col)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(l)
		b.set_meta("label", l)
	b.add_child(row)
	b.set_meta("icon", ic)
	b.set_meta("row", row)
	var fit := func() -> void:
		var m := row.get_combined_minimum_size()
		var w := m.x + (48.0 if text != "" else 26.0)
		b.custom_minimum_size = Vector2(maxf(min_h, w), maxf(min_h, m.y + 26.0))
	row.minimum_size_changed.connect(fit)
	fit.call()
	# ikut turun saat tombol ditekan
	b.button_down.connect(func() -> void: row.offset_top = 5)
	b.button_up.connect(func() -> void: row.offset_top = 0)
	return b


static func icon_btn(icon_kind: String, label_text: String, variation: String = "Button", s: float = 76.0) -> Button:
	var b := btn("", variation, icon_kind, s, s * 0.44)
	b.tooltip_text = label_text
	b.set("accessibility_name", label_text)
	return b


static func set_btn_text(b: Button, text: String) -> void:
	if b.has_meta("label"):
		(b.get_meta("label") as Label).text = text
	else:
		b.text = text
	b.set("accessibility_name", text)


static func set_btn_icon(b: Button, kind: String) -> void:
	if b.has_meta("icon"):
		(b.get_meta("icon") as Icon).set_kind(kind)


static func juice(c: Control) -> void:
	if c is BaseButton:
		var b := c as BaseButton
		b.button_down.connect(func() -> void: press_anim(b, true))
		b.button_up.connect(func() -> void: press_anim(b, false))


static func press_anim(c: Control, down: bool) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree():
		return
	c.pivot_offset = c.size / 2.0
	if c.has_meta("press_tw"):
		var old: Tween = c.get_meta("press_tw")
		if old and old.is_valid():
			old.kill()
	var tw := c.create_tween()
	if down:
		tw.tween_property(c, "scale", Vector2(0.95, 0.95), 0.07)
	else:
		tw.tween_property(c, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	c.set_meta("press_tw", tw)


static func pop_in(nodes: Array, delay: float = 0.0, step: float = 0.06) -> void:
	## Kemunculan bertahap: memudar dan sedikit membesar (tidak mengganggu tata letak).
	var i := 0
	for n in nodes:
		if not (n is Control) or not is_instance_valid(n):
			continue
		var c := n as Control
		if not Game.motion():
			continue
		c.modulate.a = 0.0
		var d := delay + i * step
		var tw := c.create_tween().set_parallel(true)
		var prep := func() -> void:
			c.pivot_offset = c.size / 2.0
			c.scale = Vector2(0.94, 0.94)
		tw.tween_callback(prep).set_delay(d)
		tw.tween_property(c, "modulate:a", 1.0, 0.3).set_delay(d)
		tw.tween_property(c, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(d + 0.01)
		i += 1


static func float_anim(c: Control, amp: float = 6.0, period: float = 2.6) -> void:
	if not Game.motion():
		return
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "position:y", c.position.y - amp, period / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(c, "position:y", c.position.y, period / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func vbox(sep: int = -1) -> VBoxContainer:
	var v := VBoxContainer.new()
	if sep >= 0:
		v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = -1) -> HBoxContainer:
	var h := HBoxContainer.new()
	if sep >= 0:
		h.add_theme_constant_override("separation", sep)
	return h


static func panel(variation: String = "Card") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	return p


static func margin(l: float, t: float, r: float, b: float) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", int(l))
	m.add_theme_constant_override("margin_top", int(t))
	m.add_theme_constant_override("margin_right", int(r))
	m.add_theme_constant_override("margin_bottom", int(b))
	return m


static func xmargin(l: float, t: float, r: float, b: float) -> MarginContainer:
	## Margin yang melebar penuh (untuk isi ScrollContainer).
	var m := margin(l, t, r, b)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return m


static func spacer(expand_h: bool = true, expand_v: bool = false) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand_h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand_v:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(h, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func scroll_v() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.follow_focus = true
	return s


static func chip(text: String, variation: String = "Chip", icon_kind: String = "", col: Color = Color("0f4c4a")) -> PanelContainer:
	var p := panel(variation)
	var h := hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	if icon_kind != "":
		var ic := Icon.new(icon_kind, col, 24)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
	var l := label(text, "H3")
	l.add_theme_font_size_override("font_size", Game.fs(20))
	l.add_theme_color_override("font_color", col)
	h.add_child(l)
	p.set_meta("label", l)
	return p


static func badge(icon_kind: String, bg: Color, s: float = 64.0, fg: Color = Color.WHITE) -> Control:
	## Lencana ikon bundar dengan kontur.
	var c := Control.new()
	c.custom_minimum_size = Vector2(s, s)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.draw.connect(func() -> void:
		var cc := c.size / 2.0
		var r := minf(c.size.x, c.size.y) / 2.0
		c.draw_circle(cc + Vector2(0, 3), r, bg.darkened(0.3), true, -1.0, true)
		c.draw_circle(cc, r - 1.0, bg, true, -1.0, true)
		c.draw_circle(cc + Vector2(-r * 0.3, -r * 0.32), r * 0.28, Color(1, 1, 1, 0.18), true, -1.0, true))
	var ic := Icon.new(icon_kind, fg, s * 0.55)
	ic.position = Vector2(s * 0.225, s * 0.225)
	ic.size = Vector2(s * 0.55, s * 0.55)
	c.add_child(ic)
	c.set_meta("icon", ic)
	return c


static func leaves_row(n: int, total: int = 3, sz: float = 32.0) -> HBoxContainer:
	var h := hbox(2)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in total:
		var ic := Icon.new("leaf", Game.LEAF if i < n else Color(Game.INK_SOFT, 0.22), sz)
		h.add_child(ic)
	return h


static func progress(value: float, max_v: float = 1.0, h: float = 18.0, fill: Color = Color("4f8a3c")) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.max_value = max_v
	pb.value = value
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, h)
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var f := Game.sb(fill, int(h / 2.0), 0, 0)
	pb.add_theme_stylebox_override("fill", f)
	pb.add_theme_stylebox_override("background", Game.sb(Color(Game.TEAL, 0.1), int(h / 2.0), 0, 0))
	return pb


static func paper_grain(parent: Control, alpha: float = 0.5) -> TextureRect:
	var t := TextureRect.new()
	t.texture = preload("res://assets/fx/paper_grain.png")
	t.stretch_mode = TextureRect.STRETCH_TILE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.modulate = Color(1, 1, 1, alpha)
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(t)
	return t
