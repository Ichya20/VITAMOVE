class_name FX
extends RefCounted
## Efek perayaan: semburan daun dan konfeti dengan CPUParticles2D (cocok untuk mode Compatibility).

const LEAF := preload("res://assets/fx/leaf.png")
const CONFETTI := preload("res://assets/fx/confetti.png")
const SPARKLE := preload("res://assets/fx/sparkle.png")


static func _ramp(colors: Array) -> Gradient:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in colors.size():
		offs.append(float(i) / colors.size())
		cols.append(colors[i])
	g.offsets = offs
	g.colors = cols
	return g


static func _fade() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.75, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	return g


static func burst(parent: Node, at: Vector2, amount: int = 26, kind: String = "leaf") -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.texture = LEAF if kind == "leaf" else SPARKLE
	p.amount = amount if Game.motion() else maxi(4, amount / 4)
	p.one_shot = true
	p.explosiveness = 0.92
	p.lifetime = 1.5
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 280.0
	p.initial_velocity_max = 560.0
	p.gravity = Vector2(0, 760)
	p.damping_min = 30.0
	p.damping_max = 70.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -320.0
	p.angular_velocity_max = 320.0
	p.scale_amount_min = 0.38 if kind == "leaf" else 0.3
	p.scale_amount_max = 0.8 if kind == "leaf" else 0.6
	p.color_initial_ramp = _ramp([Color("4f8a3c"), Color("8cc063"), Color("f2b134"), Color("6aa84f")] if kind == "leaf" else [Color("f2b134"), Color("ffffff"), Color("fde7b0")])
	p.color_ramp = _fade()
	p.position = at
	p.z_index = 20
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(2.2).timeout.connect(p.queue_free)


static func confetti(parent: Control, amount: int = 70) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.texture = CONFETTI
	p.amount = amount if Game.motion() else 10
	p.one_shot = true
	p.explosiveness = 0.25
	p.lifetime = 3.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(parent.size.x * 0.5, 8)
	p.position = Vector2(parent.size.x * 0.5, -20)
	p.direction = Vector2(0, 1)
	p.spread = 25.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 240.0
	p.gravity = Vector2(0, 260)
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	p.color_initial_ramp = _ramp([Color("c8553d"), Color("f2b134"), Color("4f8a3c"), Color("1e6b66"), Color("e8a0b4"), Color("ffffff")])
	p.color_ramp = _fade()
	p.z_index = 20
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(4.0).timeout.connect(p.queue_free)


static func leaf_fall(parent: Control, delay: float = 0.0) -> CPUParticles2D:
	## Daun kertas berjatuhan pelan dari atas layar (dipakai pada splash).
	var p := CPUParticles2D.new()
	p.texture = LEAF
	p.amount = 26 if Game.motion() else 6
	p.lifetime = 5.0
	p.preprocess = 1.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2(0, 1)
	p.spread = 18.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 95.0
	p.gravity = Vector2(6, 34)
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -55.0
	p.angular_velocity_max = 55.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.62
	p.color_initial_ramp = _ramp([Color("4f8a3c"), Color("8cc063"), Color("f2b134"), Color("6aa84f")])
	p.modulate = Color(1, 1, 1, 0.75)
	parent.add_child(p)
	var fit := func() -> void:
		p.emission_rect_extents = Vector2(parent.size.x * 0.52, 10)
		p.position = Vector2(parent.size.x * 0.5, -30)
	parent.resized.connect(fit)
	fit.call()
	if delay > 0.0:
		p.emitting = false
		parent.get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_instance_valid(p):
				p.emitting = true)
	else:
		p.emitting = true
	return p


static func float_text(parent: Control, at: Vector2, text: String, col: Color = Color("4f8a3c")) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Game.font_display)
	l.add_theme_font_size_override("font_size", 48)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 21
	parent.add_child(l)
	l.reset_size()
	l.position = at - l.size / 2.0
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(0.5, 0.5)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - 70.0, 1.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.8)
	tw.chain().tween_callback(l.queue_free)
