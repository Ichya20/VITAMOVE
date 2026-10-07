class_name UI
extends RefCounted
## Pembuat elemen UI yang konsisten dan ramah lansia.

const FG := {
	"Button": Color("1f6f6a"),
	"PrimaryButton": Color.WHITE,
	"TealButton": Color.WHITE,
	"SunButton": Color("23302e"),
	"DangerButton": Color("b3261e"),
	"ChoiceButton": Color("23302e"),
}


static func label(text: String, variation: String = "Body", wrap: bool = false, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func btn(text: String, variation: String = "Button", icon_kind: String = "", min_h: float = 84.0, icon_size: float = 38.0) -> Button:
	var b := Button.new()
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(min_h, min_h)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if icon_kind == "":
		b.text = text
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		return b
	b.tooltip_text = text
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	var fit := func() -> void:
		var m := row.get_combined_minimum_size()
		var w := m.x + (40.0 if text != "" else 22.0)
		b.custom_minimum_size = Vector2(maxf(min_h, w), maxf(min_h, m.y + 20.0))
	row.minimum_size_changed.connect(fit)
	fit.call()
	return b


static func set_btn_text(b: Button, text: String) -> void:
	if b.has_meta("label"):
		(b.get_meta("label") as Label).text = text
	else:
		b.text = text


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
	return s


static func leaves_row(n: int, total: int = 3, sz: float = 34.0) -> HBoxContainer:
	var h := hbox(4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in total:
		var ic := Icon.new("leaf", Game.LEAF if i < n else Color(Game.INK_SOFT, 0.25), sz)
		h.add_child(ic)
	return h
