class_name SpeechBubble
extends PanelContainer
## Gelembung bicara dengan ekor yang menunjuk ke pembicara (Jali atau kader).

@export var tail := "left"   # left | right | bottom | top | none
@export var tail_at := 0.5
var bg := Color("fffdf8")
var label: Label


func _init(text: String = "", tail_side: String = "left", variation: String = "H3") -> void:
	tail = tail_side
	var s := Game.sb(bg, 26, 22, 14)
	s.border_width_bottom = 5
	s.border_color = Color("d5e3df")
	Game.soft_shadow(s, 0.16, 14, 6)
	add_theme_stylebox_override("panel", s)
	label = UI.label(text, variation, true)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(label)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_text(t: String) -> void:
	label.text = t


func pop() -> void:
	if not Game.motion():
		return
	pivot_offset = Vector2(0, size.y / 2.0) if tail == "left" else size / 2.0
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var pts: PackedVector2Array
	match tail:
		"left":
			var y := clampf(h * tail_at, 22.0, h - 22.0)
			pts = PackedVector2Array([Vector2(3, y - 14), Vector2(-20, y + 4), Vector2(3, y + 12)])
		"right":
			var y2 := clampf(h * tail_at, 22.0, h - 22.0)
			pts = PackedVector2Array([Vector2(w - 3, y2 - 14), Vector2(w + 20, y2 + 4), Vector2(w - 3, y2 + 12)])
		"bottom":
			var x := clampf(w * tail_at, 30.0, w - 30.0)
			pts = PackedVector2Array([Vector2(x - 16, h - 6), Vector2(x - 2, h + 20), Vector2(x + 14, h - 6)])
		"top":
			var x2 := clampf(w * tail_at, 30.0, w - 30.0)
			pts = PackedVector2Array([Vector2(x2 - 14, 3), Vector2(x2 + 2, -20), Vector2(x2 + 14, 3)])
		_:
			return
	draw_colored_polygon(pts, bg)
