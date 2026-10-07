class_name PropArt
extends Control
## Ilustrasi benda rumah tangga untuk tantangan "Rapikan Rumah Mbah".

@export var kind := "kursi_kayu"
@export var fixed := false
const INK := Color("2a2420")


func _init(k: String = "kursi_kayu") -> void:
	kind = k
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(120, 92)


func _poly(pts: Array, c: Color) -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(_p(p))
	for o in Geometry2D.offset_polygon(arr, 2.6):
		draw_colored_polygon(o, INK)
	draw_colored_polygon(arr, c)


func _p(v: Vector2) -> Vector2:
	var s := minf(size.x / 120.0, size.y / 92.0)
	var o := (size - Vector2(120, 92) * s) / 2.0
	return o + v * s


func _k() -> float:
	return minf(size.x / 120.0, size.y / 92.0)


func _line(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	draw_line(_p(a), _p(b), INK, (w + 5.0) * _k(), true)
	draw_line(_p(a), _p(b), c, w * _k(), true)


func _circ(c: Vector2, r: float, col: Color) -> void:
	draw_circle(_p(c), (r + 2.6) * _k(), INK, true, -1.0, true)
	draw_circle(_p(c), r * _k(), col, true, -1.0, true)


func _draw() -> void:
	var wood := Color("b07c4a")
	match kind:
		"karpet":
			if fixed:
				_poly([Vector2(14, 60), Vector2(106, 60), Vector2(112, 78), Vector2(8, 78)], Color("c8553d"))
				for i in 4:
					_line(Vector2(24 + i * 22, 66), Vector2(24 + i * 22, 74), Color("f2b134"), 3)
			else:
				_poly([Vector2(10, 70), Vector2(70, 70), Vector2(78, 82), Vector2(4, 82)], Color("c8553d"))
				_poly([Vector2(70, 70), Vector2(104, 48), Vector2(116, 58), Vector2(78, 82)], Color("e0785f"))
				for i in 3:
					_line(Vector2(18 + i * 18, 74), Vector2(18 + i * 18, 80), Color("f2b134"), 3)
		"kursi_roda":
			_poly([Vector2(36, 16), Vector2(84, 16), Vector2(80, 46), Vector2(40, 46)], Color("4b5a66"))
			_poly([Vector2(30, 48), Vector2(90, 48), Vector2(86, 58), Vector2(34, 58)], Color("5f6f7c"))
			_line(Vector2(60, 58), Vector2(60, 72), Color("8a9aa6"), 5)
			_line(Vector2(36, 76), Vector2(84, 76), Color("8a9aa6"), 5)
			for x in [34, 60, 86]:
				_circ(Vector2(x, 82), 6, Color("2b2b2b"))
			if not fixed:
				for i in 3:
					_line(Vector2(96 + i * 4, 70 + i * 4), Vector2(108 + i * 4, 70 + i * 4), Color("f2b134"), 2)
		"lantai_basah":
			if fixed:
				_poly([Vector2(16, 74), Vector2(104, 74), Vector2(104, 80), Vector2(16, 80)], Color("e9dfcf"))
				_line(Vector2(84, 30), Vector2(84, 70), Color("b07c4a"), 4)
				_poly([Vector2(70, 22), Vector2(98, 22), Vector2(94, 34), Vector2(74, 34)], Color("dcebc9"))
			else:
				var pts := []
				for i in 16:
					var a := float(i) / 16.0 * TAU
					pts.append(Vector2(56, 70) + Vector2(cos(a) * (40 + sin(a * 3.0) * 6), sin(a) * 12))
				_poly(pts, Color("7cc3e0"))
				_poly([Vector2(88, 72), Vector2(100, 30), Vector2(112, 72)], Color("f2b134"))
				_line(Vector2(100, 44), Vector2(100, 58), Color("2a2420"), 2)
				_circ(Vector2(100, 64), 1.6, Color("2a2420"))
				_circ(Vector2(40, 36), 5, Color("7cc3e0"))
				_circ(Vector2(54, 26), 4, Color("7cc3e0"))
		"kabel":
			if fixed:
				_line(Vector2(10, 82), Vector2(110, 82), Color("3a3a3a"), 4)
				_poly([Vector2(100, 70), Vector2(112, 70), Vector2(112, 86), Vector2(100, 86)], Color("eeeeee"))
			else:
				var pts2 := PackedVector2Array()
				for i in 25:
					var t := float(i) / 24.0
					pts2.append(_p(Vector2(8 + t * 96, 60 + sin(t * TAU * 1.5) * 16)))
				draw_polyline(pts2, INK, 10 * _k(), true)
				draw_polyline(pts2, Color("3a3a3a"), 5 * _k(), true)
				_poly([Vector2(100, 50), Vector2(116, 50), Vector2(116, 66), Vector2(100, 66)], Color("eeeeee"))
				_line(Vector2(116, 54), Vector2(120, 54), Color("c9c9c9"), 2)
				_line(Vector2(116, 62), Vector2(120, 62), Color("c9c9c9"), 2)
		"sandal_licin":
			_poly([Vector2(20, 60), Vector2(58, 54), Vector2(64, 70), Vector2(24, 76)], Color("7aa7c7") if not fixed else Color("6f4a2a"))
			_poly([Vector2(62, 56), Vector2(100, 50), Vector2(106, 66), Vector2(66, 72)], Color("7aa7c7") if not fixed else Color("6f4a2a"))
			_line(Vector2(32, 62), Vector2(48, 58), Color("f2b134"), 4)
			_line(Vector2(74, 58), Vector2(90, 54), Color("f2b134"), 4)
			if not fixed:
				for i in 3:
					_line(Vector2(30 + i * 30, 30 + (i % 2) * 6), Vector2(36 + i * 30, 22 + (i % 2) * 6), Color("ffffff"), 3)
			else:
				for i in 6:
					_line(Vector2(26 + i * 13, 78), Vector2(30 + i * 13, 78), Color("2a2420"), 2)
		"gelas":
			_poly([Vector2(42, 20), Vector2(78, 20), Vector2(72, 82), Vector2(48, 82)], Color("e8f6fb"))
			_poly([Vector2(45, 40), Vector2(75, 40), Vector2(72, 80), Vector2(48, 80)], Color("7cc3e0"))
			_line(Vector2(52, 46), Vector2(54, 74), Color(1, 1, 1, 0.8), 3)
		"kursi_kayu":
			_line(Vector2(36, 14), Vector2(36, 84), wood.darkened(0.25), 6)
			_line(Vector2(84, 50), Vector2(84, 84), wood.darkened(0.25), 6)
			_poly([Vector2(32, 12), Vector2(74, 12), Vector2(74, 26), Vector2(32, 26)], wood)
			_poly([Vector2(30, 48), Vector2(92, 48), Vector2(96, 58), Vector2(30, 58)], wood.lightened(0.1))
			_line(Vector2(58, 58), Vector2(58, 84), wood.darkened(0.25), 6)
		"lampu":
			var glow := Color(1.0, 0.86, 0.45, 0.35)
			draw_circle(_p(Vector2(60, 40)), 34 * _k(), glow, true, -1.0, true)
			_poly([Vector2(40, 18), Vector2(80, 18), Vector2(90, 48), Vector2(30, 48)], Color("f2b134"))
			_line(Vector2(60, 48), Vector2(60, 76), Color("6f4a2a"), 5)
			_poly([Vector2(42, 76), Vector2(78, 76), Vector2(82, 84), Vector2(38, 84)], Color("6f4a2a"))
		_:
			_circ(Vector2(60, 46), 24, Color("dcebc9"))
