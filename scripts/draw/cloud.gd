class_name Cloud
extends Control
## Awan kertas yang melayang pelan.

var speed := 12.0
var span := 1280.0


func _init(w: float = 180.0, spd: float = 12.0) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(w, w * 0.45)
	speed = spd


func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x > span + 40:
		position.x = -size.x - 40


func _draw() -> void:
	var w := size.x
	var h := size.y
	var col := Color(1, 1, 1, 0.92)
	var sh := Color(0.04, 0.16, 0.15, 0.12)
	var blobs := [Vector3(0.25, 0.65, 0.22), Vector3(0.45, 0.45, 0.3), Vector3(0.68, 0.58, 0.24), Vector3(0.85, 0.72, 0.15)]
	for b in blobs:
		draw_circle(Vector2(b.x * w + 6, b.y * h + 6), b.z * w, sh, true, -1.0, true)
	for b in blobs:
		draw_circle(Vector2(b.x * w, b.y * h), b.z * w, col, true, -1.0, true)
	draw_rect(Rect2(0.2 * w, 0.62 * h, 0.68 * w, 0.3 * h), col, true)
