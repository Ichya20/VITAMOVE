extends Node
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	print("A screen awal = ", main.current.get_script().resource_path.get_file())
	# tunggu splash selesai sendiri (mode animasi penuh)
	await get_tree().create_timer(4.6).timeout
	print("B setelah splash = ", main.current.get_script().resource_path.get_file(), " stack=", main.stack.size())
	# Beranda tidak boleh kembali ke splash
	main.go("info")
	await get_tree().create_timer(1.2).timeout
	main.home()
	await get_tree().create_timer(1.2).timeout
	print("C setelah home = ", main.current.get_script().resource_path.get_file())
	# mode animasi dikurangi: splash harus singkat
	Game.set_setting("reduce_motion", true)
	Game.splash_shown = false
	main.stack.clear()
	main.go("splash")
	await get_tree().create_timer(0.4).timeout
	print("D reduce-motion, splash aktif = ", main.current.get_script().resource_path.get_file())
	await get_tree().create_timer(1.6).timeout
	print("E reduce-motion selesai = ", main.current.get_script().resource_path.get_file())
	# tombol lewati
	Game.set_setting("reduce_motion", false)
	main.stack.clear()
	main.go("splash")
	await get_tree().create_timer(0.8).timeout
	main.current._skip()
	await get_tree().create_timer(1.0).timeout
	print("F setelah Lewati = ", main.current.get_script().resource_path.get_file())
	print("SPLASH_CHECK_DONE")
	get_tree().quit()
