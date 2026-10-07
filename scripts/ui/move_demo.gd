class_name MoveDemo
extends Control
## Memutar demonstrasi gerakan: hitung mundur, hitungan berirama, isyarat, ekspresi, dan ulangan.

signal beat(count: int, cue: String)
signal rep_changed(rep: int, reps: int)
signal segment_changed(cue: String)
signal finished

var figure: ElderFigure
var move_id := ""
var variant: Dictionary = {}
var reps := 1
var playing := false
var done := false

var _seq: Array = []
var _seg := 0
var _seg_t := 0.0
var _from: Dictionary = {}
var _to: Dictionary = {}
var _beat_t := 0.0
var _count := 0
var _rep := 0
var _countdown := 0
var _base: Dictionary = {}
var _start_pose: Dictionary = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	figure = ElderFigure.new()
	figure.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(figure)


func setup(id: String, capacity: int, avatar: String, reps_override: int = -1, outfit: int = 0) -> void:
	move_id = id
	var m: Dictionary = Data.MOVES[id]
	variant = Data.move_variant(id, capacity)
	reps = reps_override if reps_override > 0 else int(m["reps"])
	figure.set_avatar(avatar, outfit)
	figure.chair = int(variant["chair"])
	figure.support_hand = bool(variant["support"])
	_base = {"sit": float(variant["sit_base"])}
	_seq.clear()
	var keys: Array = variant["keys"]
	var beats: Array = m.get("beats", [])
	var cues: Array = variant["cues"]
	var sounds: Array = m.get("sounds", [])
	for i in keys.size():
		var p := _base.duplicate()
		for kk in keys[i].keys():
			p[kk] = keys[i][kk]
		var snd: String = str(sounds[i]) if i < sounds.size() else ""
		var bt: int = int(beats[i]) if i < beats.size() else 1
		var fc := "smile"
		if snd == "breath_in":
			fc = "o"
		elif snd == "breath_out":
			fc = "blow"
		elif bt >= 2:
			fc = "focus"
		_seq.append({
			"pose": p, "beats": bt, "face": fc,
			"cue": str(cues[i]) if i < cues.size() else "",
			"sound": snd,
		})
	_start_pose = _seq.back()["pose"] if not _seq.is_empty() else _base
	reset()


func reset() -> void:
	playing = false
	done = false
	_seg = 0
	_seg_t = 0.0
	_beat_t = 0.0
	_count = 0
	_rep = 0
	_countdown = 0
	_from = _merged(_start_pose)
	_to = _from
	figure.face = "smile"
	figure.set_pose(_from)


func _merged(p: Dictionary) -> Dictionary:
	var out := ElderFigure.NEUTRAL.duplicate()
	for k in p.keys():
		out[k] = p[k]
	return out


func start(with_countdown: bool = true) -> void:
	if _seq.is_empty():
		return
	if done:
		reset()
	playing = true
	if _count == 0 and _countdown == 0:
		if with_countdown:
			_countdown = 3
			_beat_t = 0.0
			beat.emit(-3, "Siap...")
			Sfx.play("tick")
		else:
			rep_changed.emit(1, reps)
			_begin_segment(0)


func pause() -> void:
	playing = false


func restart() -> void:
	reset()
	start(true)


func total_beats() -> int:
	var n := 0
	for s in _seq:
		n += int(s["beats"])
	return n * reps


func progress() -> float:
	var tb := total_beats()
	return 0.0 if tb == 0 else clampf(float(_count) / tb, 0.0, 1.0)


func current_rep() -> int:
	return _rep


func _begin_segment(i: int) -> void:
	_seg = i
	_seg_t = 0.0
	_from = figure.pose.duplicate()
	_to = _merged(_seq[i]["pose"])
	figure.face = str(_seq[i]["face"])
	var cue: String = _seq[i]["cue"]
	segment_changed.emit(cue)
	var snd: String = _seq[i]["sound"]
	if snd != "":
		Sfx.play(snd)
	var seg_len := float(_seq[i]["beats"]) * Game.beat_seconds()
	if cue != "" and seg_len >= 1.5:
		Game.speak(cue)
	_beat_t = 0.0
	_tick()


func _tick() -> void:
	_count += 1
	var c := ((_count - 1) % 8) + 1
	Sfx.play("tick_accent" if c == 1 else "tick")
	beat.emit(c, _seq[_seg]["cue"])


func _process(delta: float) -> void:
	if not playing:
		return
	var bs := Game.beat_seconds()
	if _countdown > 0:
		_beat_t += delta
		if _beat_t >= bs * 0.8:
			_beat_t = 0.0
			_countdown -= 1
			if _countdown > 0:
				beat.emit(-_countdown, "Siap...")
				Sfx.play("tick")
			else:
				rep_changed.emit(1, reps)
				_begin_segment(0)
		return

	_seg_t += delta
	_beat_t += delta
	var seg: Dictionary = _seq[_seg]
	var beats_n := int(seg["beats"])
	var dur := beats_n * bs
	# bergerak pada ketukan pertama, lalu menahan
	var move_time := minf(dur, bs) * 0.85
	var t := clampf(_seg_t / move_time, 0.0, 1.0)
	var e := t * t * (3.0 - 2.0 * t)
	var p := {}
	for k in _to.keys():
		p[k] = lerpf(float(_from.get(k, 0.0)), float(_to[k]), e)
	if beats_n >= 2 and t >= 1.0:
		p["breath"] = float(p.get("breath", 0.0)) + sin(_seg_t * 2.0) * 0.08
	figure.set_pose(p)

	if _beat_t >= bs and _seg_t < dur - 0.01:
		_beat_t -= bs
		_tick()
	if _seg_t >= dur:
		var next := _seg + 1
		if next >= _seq.size():
			_rep += 1
			if _rep >= reps:
				playing = false
				done = true
				figure.face = "happy"
				figure.set_pose(_merged(_start_pose))
				finished.emit()
				return
			rep_changed.emit(_rep + 1, reps)
			next = 0
		_begin_segment(next)
