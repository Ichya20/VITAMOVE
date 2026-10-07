class_name CountRing
extends Control
## Angka hitungan besar di dalam cincin kemajuan, ditambah titik ulangan.

var text := ""
var progress := 0.0
var reps := 0
var rep_now := 0
var hint := ""
var _pulse := 0.0
var _shown_p := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(170, 210)


func set_count(t: String, h: String = "") -> void:
	text = t
	hint = h
	_pulse = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	var changed := false
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta * 3.0)
		changed = true
	if absf(_shown_p - progress) > 0.001:
		_shown_p = lerpf(_shown_p, progress, minf(1.0, delta * 8.0))
		changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var r := minf(w * 0.5 - 8.0, (size.y - 46.0) * 0.5)
	var c := Vector2(w / 2.0, r + 8.0)
	for i in 3:
		draw_circle(c + Vector2(0, 8), r + 6.0 - i * 4.0, Color(0.05, 0.25, 0.22, 0.05), true, -1.0, true)
	draw_circle(c, r, Game.PAPER, true, -1.0, true)
	draw_arc(c, r - 9.0, 0, TAU, 48, Color(Game.TEAL, 0.1), 12.0, true)
	if _shown_p > 0.002:
		draw_arc(c, r - 9.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(_shown_p, 0.0, 1.0), 48, Game.TERRA, 12.0, true)
	var f := Game.font_display
	var fsz := int(r * (1.05 + 0.18 * _pulse))
	if text.length() > 2:
		fsz = int(r * 0.55)
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
	draw_string(f, c + Vector2(-tw / 2.0, fsz * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Game.TERRA)
	if hint != "":
		var hf := Game.font_bold
		var hs := 18
		var hw := hf.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x
		draw_string(hf, c + Vector2(-hw / 2.0, r * 0.62), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hs, Game.INK_SOFT)
	if reps > 0:
		var gapx := minf(26.0, (w - 20.0) / reps)
		var x0 := w / 2.0 - gapx * (reps - 1) / 2.0
		var y := c.y + r + 22.0
		for i in reps:
			var p := Vector2(x0 + i * gapx, y)
			if i < rep_now:
				draw_circle(p, 8.0, Game.LEAF, true, -1.0, true)
			elif i == rep_now:
				draw_circle(p, 8.0, Game.SAFFRON, true, -1.0, true)
			else:
				draw_arc(p, 7.0, 0, TAU, 16, Color(Game.TEAL, 0.35), 2.5, true)
