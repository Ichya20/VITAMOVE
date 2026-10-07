extends Node
var main: Node
var dir := "/tmp/sp"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--splash-shot="):
			dir = a.substr(14)
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(3.2).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/splash_%dx%d.png" % [dir, img.get_width(), img.get_height()])
	print("SPLASH_SHOT ", img.get_size())
	get_tree().quit()
