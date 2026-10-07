extends Node
## Autoload "Sfx": musik latar gamelan dan efek suara.

const SOUNDS := {
	"tap": preload("res://assets/audio/tap.wav"),
	"tick": preload("res://assets/audio/tick.wav"),
	"tick_accent": preload("res://assets/audio/tick_accent.wav"),
	"success": preload("res://assets/audio/success.wav"),
	"leaf": preload("res://assets/audio/leaf.wav"),
	"soft_no": preload("res://assets/audio/soft_no.wav"),
	"breath_in": preload("res://assets/audio/breath_in.wav"),
	"breath_out": preload("res://assets/audio/breath_out.wav"),
	"unlock": preload("res://assets/audio/unlock.wav"),
}

var _music: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _duck := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	var bgm: AudioStreamWAV = load("res://assets/audio/bgm_desa.wav")
	bgm.loop_mode = AudioStreamWAV.LOOP_FORWARD
	bgm.loop_begin = 0
	bgm.loop_end = int(bgm.get_length() * bgm.mix_rate)
	_music.stream = bgm
	add_child(_music)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	apply_volume()
	Game.settings_changed.connect(apply_volume)
	_music.play()


func _lin(v: float) -> float:
	return linear_to_db(maxf(v, 0.0001))


func apply_volume() -> void:
	var mv := float(Game.settings["music"]) * _duck
	_music.volume_db = _lin(mv)
	_music.stream_paused = mv <= 0.001
	for p in _pool:
		p.volume_db = _lin(float(Game.settings["sfx"]))


func duck(on: bool) -> void:
	## Kecilkan musik saat latihan agar hitungan dan suara pemandu jelas.
	_duck = 0.35 if on else 1.0
	apply_volume()


func play(sound: String) -> void:
	if float(Game.settings["sfx"]) <= 0.001 or not SOUNDS.has(sound):
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = SOUNDS[sound]
	p.play()
