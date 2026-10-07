class_name Icon
extends Control
## Ikon vektor sederhana yang digambar langsung (tajam di semua resolusi).

@export var kind := "leaf"
@export var color := Color.WHITE
@export var line := 0.0  # 0 = otomatis


func _init(k: String = "leaf", c: Color = Color.WHITE, s: float = 40.0) -> void:
	kind = k
	color = c
	custom_minimum_size = Vector2(s, s)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_kind(k: String) -> void:
	kind = k
	queue_redraw()


func _p(x: float, y: float) -> Vector2:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) / 2.0
	return o + Vector2(x, y) * s


func _w() -> float:
	return line if line > 0.0 else maxf(2.5, minf(size.x, size.y) * 0.11)


func _l(a: Vector2, b: Vector2, w: float = -1.0) -> void:
	var ww := _w() if w < 0 else w
	draw_line(a, b, color, ww, true)
	draw_circle(a, ww / 2.0, color, true, -1.0, true)
	draw_circle(b, ww / 2.0, color, true, -1.0, true)


func _poly(pts: Array) -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(_p(p.x, p.y))
	draw_colored_polygon(arr, color)


func _ring(c: Vector2, r: float, w: float = -1.0) -> void:
	var s := minf(size.x, size.y)
	draw_arc(_p(c.x, c.y), r * s, 0, TAU, 40, color, _w() if w < 0 else w, true)


func _dot(c: Vector2, r: float) -> void:
	var s := minf(size.x, size.y)
	draw_circle(_p(c.x, c.y), r * s, color, true, -1.0, true)


func _draw() -> void:
	var s := minf(size.x, size.y)
	match kind:
		"back", "prev":
			_l(_p(0.62, 0.2), _p(0.32, 0.5))
			_l(_p(0.32, 0.5), _p(0.62, 0.8))
		"next":
			_l(_p(0.38, 0.2), _p(0.68, 0.5))
			_l(_p(0.68, 0.5), _p(0.38, 0.8))
		"home":
			_l(_p(0.15, 0.5), _p(0.5, 0.18))
			_l(_p(0.5, 0.18), _p(0.85, 0.5))
			_l(_p(0.27, 0.45), _p(0.27, 0.82))
			_l(_p(0.73, 0.45), _p(0.73, 0.82))
			_l(_p(0.27, 0.82), _p(0.73, 0.82))
			_l(_p(0.44, 0.82), _p(0.44, 0.62))
			_l(_p(0.56, 0.62), _p(0.56, 0.82))
			_l(_p(0.44, 0.62), _p(0.56, 0.62))
		"play":
			_poly([Vector2(0.3, 0.16), Vector2(0.84, 0.5), Vector2(0.3, 0.84)])
		"pause":
			_l(_p(0.36, 0.2), _p(0.36, 0.8), s * 0.17)
			_l(_p(0.64, 0.2), _p(0.64, 0.8), s * 0.17)
		"replay":
			draw_arc(_p(0.5, 0.52), s * 0.3, -PI * 0.15, PI * 1.45, 32, color, _w(), true)
			_poly([Vector2(0.62, 0.06), Vector2(0.86, 0.3), Vector2(0.56, 0.36)])
		"skip":
			_poly([Vector2(0.18, 0.18), Vector2(0.6, 0.5), Vector2(0.18, 0.82)])
			_l(_p(0.76, 0.2), _p(0.76, 0.8), s * 0.15)
		"speaker":
			_poly([Vector2(0.12, 0.38), Vector2(0.3, 0.38), Vector2(0.52, 0.18), Vector2(0.52, 0.82), Vector2(0.3, 0.62), Vector2(0.12, 0.62)])
			draw_arc(_p(0.52, 0.5), s * 0.18, -0.9, 0.9, 16, color, _w() * 0.8, true)
			draw_arc(_p(0.52, 0.5), s * 0.33, -0.9, 0.9, 16, color, _w() * 0.8, true)
		"mute":
			_poly([Vector2(0.12, 0.38), Vector2(0.3, 0.38), Vector2(0.52, 0.18), Vector2(0.52, 0.82), Vector2(0.3, 0.62), Vector2(0.12, 0.62)])
			_l(_p(0.66, 0.36), _p(0.88, 0.64))
			_l(_p(0.88, 0.36), _p(0.66, 0.64))
		"gear":
			for i in 8:
				var a := i * TAU / 8.0
				_l(_p(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.22, _p(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.38, s * 0.14)
			_ring(Vector2(0.5, 0.5), 0.19, s * 0.13)
		"info":
			_ring(Vector2(0.5, 0.5), 0.38)
			_dot(Vector2(0.5, 0.31), 0.065)
			_l(_p(0.5, 0.46), _p(0.5, 0.72))
		"book":
			_l(_p(0.5, 0.26), _p(0.5, 0.82))
			_l(_p(0.12, 0.2), _p(0.5, 0.26))
			_l(_p(0.5, 0.26), _p(0.88, 0.2))
			_l(_p(0.12, 0.2), _p(0.12, 0.76))
			_l(_p(0.88, 0.2), _p(0.88, 0.76))
			_l(_p(0.12, 0.76), _p(0.5, 0.82))
			_l(_p(0.5, 0.82), _p(0.88, 0.76))
		"people":
			_dot(Vector2(0.34, 0.32), 0.12)
			_dot(Vector2(0.68, 0.36), 0.1)
			_poly([Vector2(0.12, 0.84), Vector2(0.16, 0.58), Vector2(0.34, 0.5), Vector2(0.52, 0.58), Vector2(0.56, 0.84)])
			_poly([Vector2(0.6, 0.84), Vector2(0.6, 0.6), Vector2(0.68, 0.53), Vector2(0.84, 0.6), Vector2(0.88, 0.84)])
		"user":
			_dot(Vector2(0.5, 0.32), 0.17)
			_poly([Vector2(0.18, 0.88), Vector2(0.24, 0.62), Vector2(0.5, 0.54), Vector2(0.76, 0.62), Vector2(0.82, 0.88)])
		"check":
			_l(_p(0.18, 0.52), _p(0.42, 0.76), s * 0.15)
			_l(_p(0.42, 0.76), _p(0.84, 0.26), s * 0.15)
		"close":
			_l(_p(0.24, 0.24), _p(0.76, 0.76), s * 0.14)
			_l(_p(0.76, 0.24), _p(0.24, 0.76), s * 0.14)
		"plus":
			_l(_p(0.5, 0.2), _p(0.5, 0.8), s * 0.15)
			_l(_p(0.2, 0.5), _p(0.8, 0.5), s * 0.15)
		"minus":
			_l(_p(0.2, 0.5), _p(0.8, 0.5), s * 0.15)
		"leaf":
			var pts := PackedVector2Array()
			for i in 25:
				var t := float(i) / 24.0
				pts.append(_p(0.15 + 0.7 * t, 0.85 - 0.7 * t) + Vector2(-1, -1).normalized() * sin(t * PI) * s * 0.26)
			for i in range(24, -1, -1):
				var t := float(i) / 24.0
				pts.append(_p(0.15 + 0.7 * t, 0.85 - 0.7 * t) + Vector2(1, 1).normalized() * sin(t * PI) * s * 0.26)
			draw_colored_polygon(pts, color)
			var vein := color.darkened(0.35)
			draw_line(_p(0.12, 0.88), _p(0.78, 0.22), vein, maxf(2.0, s * 0.05), true)
		"heart":
			var hp := PackedVector2Array()
			for i in 48:
				var t := float(i) / 48.0 * TAU
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				hp.append(_p(0.5 + x / 38.0, 0.47 + y / 38.0))
			draw_colored_polygon(hp, color)
		"chair":
			_l(_p(0.3, 0.12), _p(0.3, 0.88))
			_l(_p(0.3, 0.52), _p(0.74, 0.52))
			_l(_p(0.74, 0.52), _p(0.74, 0.88))
			_l(_p(0.3, 0.14), _p(0.5, 0.14))
		"eye":
			var ep := PackedVector2Array()
			for i in 33:
				var t := float(i) / 32.0
				ep.append(_p(0.08 + 0.84 * t, 0.5 - sin(t * PI) * 0.3))
			for i in range(32, -1, -1):
				var t := float(i) / 32.0
				ep.append(_p(0.08 + 0.84 * t, 0.5 + sin(t * PI) * 0.3))
			draw_polyline(ep, color, _w() * 0.8, true)
			_dot(Vector2(0.5, 0.5), 0.13)
		"run":
			_dot(Vector2(0.6, 0.15), 0.1)
			_l(_p(0.55, 0.3), _p(0.45, 0.58))
			_l(_p(0.45, 0.58), _p(0.62, 0.72))
			_l(_p(0.62, 0.72), _p(0.6, 0.9))
			_l(_p(0.45, 0.58), _p(0.3, 0.74))
			_l(_p(0.3, 0.74), _p(0.16, 0.74))
			_l(_p(0.53, 0.36), _p(0.74, 0.46))
			_l(_p(0.53, 0.36), _p(0.32, 0.4))
		"quiz":
			draw_arc(_p(0.5, 0.34), s * 0.2, PI * 1.0, PI * 2.25, 20, color, _w(), true)
			_l(_p(0.56, 0.52), _p(0.5, 0.62))
			_dot(Vector2(0.5, 0.82), 0.075)
		"lock":
			draw_arc(_p(0.5, 0.42), s * 0.19, PI, TAU, 20, color, _w(), true)
			_l(_p(0.31, 0.42), _p(0.31, 0.5))
			_l(_p(0.69, 0.42), _p(0.69, 0.5))
			_poly([Vector2(0.2, 0.48), Vector2(0.8, 0.48), Vector2(0.8, 0.88), Vector2(0.2, 0.88)])
		"calendar":
			_poly([Vector2(0.14, 0.2), Vector2(0.86, 0.2), Vector2(0.86, 0.36), Vector2(0.14, 0.36)])
			_l(_p(0.14, 0.3), _p(0.14, 0.86))
			_l(_p(0.86, 0.3), _p(0.86, 0.86))
			_l(_p(0.14, 0.86), _p(0.86, 0.86))
			_l(_p(0.32, 0.1), _p(0.32, 0.26))
			_l(_p(0.68, 0.1), _p(0.68, 0.26))
			for yy in [0.52, 0.7]:
				for xx in [0.32, 0.5, 0.68]:
					_dot(Vector2(xx, yy), 0.045)
		"shield":
			_poly([Vector2(0.5, 0.08), Vector2(0.86, 0.22), Vector2(0.8, 0.6), Vector2(0.5, 0.92), Vector2(0.2, 0.6), Vector2(0.14, 0.22)])
			var c2 := color.darkened(0.55)
			draw_line(_p(0.34, 0.5), _p(0.46, 0.64), c2, s * 0.1, true)
			draw_line(_p(0.46, 0.64), _p(0.68, 0.36), c2, s * 0.1, true)
		"sun":
			_dot(Vector2(0.5, 0.5), 0.2)
			for i in 8:
				var a := i * TAU / 8.0
				_l(_p(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.3, _p(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.42, s * 0.08)
		"trophy":
			_poly([Vector2(0.26, 0.14), Vector2(0.74, 0.14), Vector2(0.68, 0.46), Vector2(0.5, 0.58), Vector2(0.32, 0.46)])
			draw_arc(_p(0.26, 0.28), s * 0.12, PI * 0.5, PI * 1.5, 12, color, _w() * 0.7, true)
			draw_arc(_p(0.74, 0.28), s * 0.12, -PI * 0.5, PI * 0.5, 12, color, _w() * 0.7, true)
			_l(_p(0.5, 0.56), _p(0.5, 0.76))
			_poly([Vector2(0.3, 0.76), Vector2(0.7, 0.76), Vector2(0.74, 0.88), Vector2(0.26, 0.88)])
		"water":
			var wp := PackedVector2Array()
			for i in 33:
				var t := float(i) / 32.0 * TAU
				wp.append(_p(0.5, 0.6) + Vector2(sin(t), -cos(t)) * s * 0.26)
			draw_colored_polygon(wp, color)
			_poly([Vector2(0.5, 0.1), Vector2(0.73, 0.48), Vector2(0.27, 0.48)])
		"stop":
			var sp := PackedVector2Array()
			for i in 8:
				var a := PI / 8.0 + i * TAU / 8.0
				sp.append(_p(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.42)
			draw_colored_polygon(sp, color)
			draw_line(_p(0.3, 0.5), _p(0.7, 0.5), Color.WHITE, s * 0.12, true)
		"wave":
			for k in 3:
				var wpts := PackedVector2Array()
				for i in 21:
					var t := float(i) / 20.0
					wpts.append(_p(0.1 + 0.8 * t, 0.3 + k * 0.2 + sin(t * TAU) * 0.06))
				draw_polyline(wpts, color, _w() * 0.8, true)
		"flex":
			_dot(Vector2(0.5, 0.14), 0.1)
			_l(_p(0.5, 0.28), _p(0.5, 0.6))
			_l(_p(0.5, 0.32), _p(0.24, 0.08))
			_l(_p(0.5, 0.32), _p(0.76, 0.08))
			_l(_p(0.5, 0.6), _p(0.34, 0.9))
			_l(_p(0.5, 0.6), _p(0.66, 0.9))
		"balance":
			_dot(Vector2(0.5, 0.14), 0.1)
			_l(_p(0.5, 0.28), _p(0.5, 0.6))
			_l(_p(0.12, 0.36), _p(0.88, 0.36))
			_l(_p(0.5, 0.6), _p(0.5, 0.9))
			_l(_p(0.5, 0.6), _p(0.7, 0.66))
			_l(_p(0.7, 0.66), _p(0.66, 0.78))
		"strength":
			_l(_p(0.18, 0.5), _p(0.82, 0.5), s * 0.1)
			_poly([Vector2(0.1, 0.3), Vector2(0.26, 0.3), Vector2(0.26, 0.7), Vector2(0.1, 0.7)])
			_poly([Vector2(0.74, 0.3), Vector2(0.9, 0.3), Vector2(0.9, 0.7), Vector2(0.74, 0.7)])
		"basket":
			_poly([Vector2(0.12, 0.44), Vector2(0.88, 0.44), Vector2(0.76, 0.86), Vector2(0.24, 0.86)])
			draw_arc(_p(0.5, 0.44), s * 0.27, PI, TAU, 20, color, _w(), true)
		"moon":
			var mp := PackedVector2Array()
			for i in 25:
				var a := PI * 0.35 + float(i) / 24.0 * PI * 1.3
				mp.append(_p(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.36)
			for i in range(24, -1, -1):
				var a := PI * 0.35 + float(i) / 24.0 * PI * 1.3
				mp.append(_p(0.62, 0.42) + Vector2(cos(a), sin(a)) * s * 0.26)
			draw_colored_polygon(mp, color)
		"face_happy", "face_ok", "face_tired":
			_dot(Vector2(0.5, 0.5), 0.44)
			var fc := Color("23302e")
			var eye_y := 0.42
			if kind == "face_tired":
				draw_line(_p(0.3, 0.42), _p(0.42, 0.44), fc, s * 0.06, true)
				draw_line(_p(0.58, 0.44), _p(0.7, 0.42), fc, s * 0.06, true)
			else:
				draw_circle(_p(0.36, eye_y), s * 0.05, fc, true, -1.0, true)
				draw_circle(_p(0.64, eye_y), s * 0.05, fc, true, -1.0, true)
			match kind:
				"face_happy":
					draw_arc(_p(0.5, 0.56), s * 0.18, 0.2, PI - 0.2, 16, fc, s * 0.06, true)
				"face_ok":
					draw_line(_p(0.36, 0.66), _p(0.64, 0.66), fc, s * 0.06, true)
				_:
					draw_arc(_p(0.5, 0.76), s * 0.14, PI + 0.4, TAU - 0.4, 16, fc, s * 0.06, true)
		_:
			_dot(Vector2(0.5, 0.5), 0.3)
