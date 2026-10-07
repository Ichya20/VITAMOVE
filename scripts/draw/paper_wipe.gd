class_name PaperWipe
extends Control
## Transisi layar: lembar kertas bermotif kawung menyapu layar dengan tepi bergelombang.

signal covered
signal finished

var progress := 0.0   # 0..1 menutup, 1..2 membuka
var direction := 1.0
var _emitted := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func play(dir: float = 1.0) -> void:
	direction = dir
	progress = 0.0
	_emitted = false
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_method(_set_p, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: covered.emit())
	tw.tween_interval(0.06)
	tw.tween_method(_set_p, 1.0, 2.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		finished.emit())


func _set_p(v: float) -> void:
	progress = v
	queue_redraw()


func _edge(x: float, h: float, phase: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 18
	for i in n + 1:
		var y := h * float(i) / n
		pts.append(Vector2(x + sin(y * 0.012 + phase) * 28.0 + sin(y * 0.031) * 10.0, y))
	return pts


func _draw() -> void:
	var w := size.x
	var h := size.y
	var pad := 90.0
	var lead: float
	var trail: float
	if progress <= 1.0:
		lead = lerpf(-pad, w + pad, progress)
		trail = -pad * 4.0
	else:
		lead = w + pad * 4.0
		trail = lerpf(-pad, w + pad, progress - 1.0)
	var lead_edge := _edge(lead, h, 0.0)
	var trail_edge := _edge(trail, h, 2.0)
	var poly := PackedVector2Array()
	for p in trail_edge:
		poly.append(_flip(p, w))
	for i in range(lead_edge.size() - 1, -1, -1):
		poly.append(_flip(lead_edge[i], w))
	# bayangan tepi
	var sh := PackedVector2Array()
	for p in poly:
		sh.append(p + Vector2(direction * 14.0, 0))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.18))
	draw_colored_polygon(poly, Game.TEAL)
	# motif kawung tipis
	var mot := Color(1, 1, 1, 0.07)
	var lo := minf(trail, lead)
	var hi := maxf(trail, lead)
	var yy := 30.0
	while yy < h:
		var xx := fmod(yy, 120.0) * 0.5
		while xx < w:
			var fx := _flip(Vector2(xx, yy), w).x
			var raw_x := xx
			if raw_x > lo + 20 and raw_x < hi - 20:
				for q in 4:
					var a := q * PI / 2.0 + PI / 4.0
					draw_circle(Vector2(fx, yy) + Vector2(cos(a), sin(a)) * 12.0, 9.0, mot, true, -1.0, true)
			xx += 72.0
		yy += 72.0
	# pinggir kertas krem
	var rim := PackedVector2Array()
	for p in lead_edge:
		rim.append(_flip(p, w))
	draw_polyline(rim, Game.SAFFRON, 8.0, true)
	var rim2 := PackedVector2Array()
	for p in trail_edge:
		rim2.append(_flip(p, w))
	draw_polyline(rim2, Game.SAFFRON, 8.0, true)
	# daun di tengah saat tertutup penuh
	if progress > 0.75 and progress < 1.35:
		var a2 := clampf(1.0 - absf(progress - 1.0) / 0.35, 0.0, 1.0)
		var c := size / 2.0
		var r := 46.0 * a2
		draw_circle(c, r + 10, Color(Game.CREAM, 0.95 * a2), true, -1.0, true)
		var leaf := PackedVector2Array()
		for i in 21:
			var t := float(i) / 20.0
			leaf.append(c + Vector2(lerpf(-r * 0.7, r * 0.7, t), -sin(t * PI) * r * 0.42).rotated(-0.6))
		for i in range(20, -1, -1):
			var t2 := float(i) / 20.0
			leaf.append(c + Vector2(lerpf(-r * 0.7, r * 0.7, t2), sin(t2 * PI) * r * 0.42).rotated(-0.6))
		if r > 4.0:
			draw_colored_polygon(leaf, Color(Game.LEAF, a2))


func _flip(p: Vector2, w: float) -> Vector2:
	return p if direction > 0 else Vector2(w - p.x, p.y)
