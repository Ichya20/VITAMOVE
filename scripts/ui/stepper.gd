class_name Stepper
extends Control
## Penunjuk langkah (1 Lihat - 2 Ikuti - 3 Coba) dengan garis penghubung.

var steps: Array = ["Lihat", "Ikuti", "Coba"]
var current := 0
var _t := 0.0


func _init(names: Array = ["Lihat", "Ikuti", "Coba"]) -> void:
	steps = names
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(110 * names.size(), 74)


func set_current(i: int) -> void:
	current = i
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var n := steps.size()
	var w := size.x
	var cw := w / n
	var cy := 24.0
	var r := 20.0
	var ink := Game.INK
	var f := Game.font_bold
	var fsz := Game.fs_cap(20, 1.1)
	for i in n - 1:
		var x0 := cw * (i + 0.5) + r + 4
		var x1 := cw * (i + 1.5) - r - 4
		var col := Game.LEAF if i < current else Color(Game.TEAL, 0.2)
		draw_line(Vector2(x0, cy), Vector2(x1, cy), col, 5.0, true)
	for i in n:
		var c := Vector2(cw * (i + 0.5), cy)
		if i == current:
			var pulse := 0.5 + 0.5 * sin(_t * 3.0)
			draw_circle(c, r + 6 + pulse * 3, Color(Game.SAFFRON, 0.35), true, -1.0, true)
		draw_circle(c + Vector2(0, 3), r + 2, Color(ink, 0.9), true, -1.0, true)
		draw_circle(c, r + 2, ink, true, -1.0, true)
		var fill := Game.LEAF if i < current else (Game.SAFFRON if i == current else Game.PAPER)
		draw_circle(c, r - 1, fill, true, -1.0, true)
		if i < current:
			draw_line(c + Vector2(-9, 0), c + Vector2(-2, 7), Color.WHITE, 4.5, true)
			draw_line(c + Vector2(-2, 7), c + Vector2(10, -7), Color.WHITE, 4.5, true)
		else:
			var num := str(i + 1)
			var df := Game.font_display
			var tw := df.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			draw_string(df, c + Vector2(-tw / 2.0, 9), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ink if i == current else Game.INK_SOFT)
		var lab := str(steps[i])
		var lw := f.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		draw_string(f, Vector2(c.x - lw / 2.0, cy + r + 8 + fsz), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, ink if i <= current else Game.INK_SOFT)
