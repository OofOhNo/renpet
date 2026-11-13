extends Node

## AstralAudio - Motor de sonido procedural cristalino (sin archivos externos).
## Sintetiza arpas celestes, campanas de astrolabio y efectos táctiles de combate e interfaz.

signal mute_changed(is_muted: bool)

const SAMPLE_RATE: float = 44100.0
const BUFFER_LEN: float = 0.08
const MAX_VOICES: int = 12

var muted: bool = false
var _enabled: bool = false
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _voices: Array[Dictionary] = []

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = BUFFER_LEN
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.volume_db = -6.0
	add_child(_player)
	_player.play()
	var pb := _player.get_stream_playback()
	if pb is AudioStreamGeneratorPlayback:
		_playback = pb as AudioStreamGeneratorPlayback
		_enabled = true

func toggle_mute() -> bool:
	muted = not muted
	if muted:
		_voices.clear()
	mute_changed.emit(muted)
	if not muted:
		play_ui()
	return muted

func set_muted(v: bool) -> void:
	if muted == v:
		return
	muted = v
	if muted:
		_voices.clear()
	mute_changed.emit(muted)

func _add_voice(freq: float, dur: float, amp: float = 0.11, delay: float = 0.0, freq_end: float = -1.0, harmonic: float = 0.35) -> void:
	if not _enabled or muted:
		return
	if _voices.size() >= MAX_VOICES:
		_voices.remove_at(0)
	_voices.append({
		"f0": freq,
		"f1": freq_end if freq_end > 0.0 else freq,
		"dur": maxf(0.03, dur),
		"t": -delay,
		"phase": 0.0,
		"amp": clampf(amp, 0.01, 0.22),
		"harm": clampf(harmonic, 0.0, 0.8)
	})

func play_ui() -> void:
	_add_voice(880.0, 0.09, 0.06, 0.0, 1046.5, 0.20)

func play_confirm() -> void:
	_add_voice(523.25, 0.16, 0.08, 0.0, -1.0, 0.30)
	_add_voice(659.25, 0.24, 0.08, 0.05, -1.0, 0.30)

func play_warn() -> void:
	_add_voice(261.63, 0.18, 0.09, 0.0, 220.0, 0.45)

func play_turn_end() -> void:
	var notes: Array[float] = [293.66, 349.23, 440.0, 587.33]
	for i in range(notes.size()):
		_add_voice(notes[i], 0.38, 0.08, float(i) * 0.065, -1.0, 0.38)

func play_triumph() -> void:
	var chord: Array[float] = [293.66, 440.0, 523.25, 698.46, 880.0]
	for i in range(chord.size()):
		_add_voice(chord[i], 0.65, 0.085, float(i) * 0.055, -1.0, 0.40)

func play_twist() -> void:
	_add_voice(146.83, 1.05, 0.13, 0.0, 130.81, 0.55)
	_add_voice(220.00, 0.85, 0.09, 0.08, 207.65, 0.50)
	_add_voice(587.33, 0.70, 0.07, 0.18, 554.37, 0.30)

func play_combat(kind: String) -> void:
	match kind:
		"slash":
			_add_voice(392.0, 0.14, 0.11, 0.0, 185.0, 0.60)
		"shield":
			_add_voice(349.23, 0.24, 0.09, 0.0, 440.0, 0.25)
			_add_voice(523.25, 0.24, 0.07, 0.04, 587.33, 0.20)
		"magic":
			_add_voice(587.33, 0.22, 0.09, 0.0, 880.0, 0.45)
			_add_voice(698.46, 0.26, 0.07, 0.06, 1046.5, 0.35)
		"hit":
			_add_voice(155.56, 0.18, 0.13, 0.0, 82.41, 0.65)
		"stagger":
			_add_voice(440.0, 0.28, 0.10, 0.0, -1.0, 0.45)
			_add_voice(659.25, 0.32, 0.10, 0.05, -1.0, 0.45)
			_add_voice(880.0, 0.38, 0.09, 0.10, -1.0, 0.35)
		"unseal":
			play_twist()
		"victory":
			play_triumph()
		_:
			play_ui()

func _process(_delta: float) -> void:
	if not _enabled or _playback == null:
		return
	var avail: int = _playback.get_frames_available()
	if avail <= 0:
		return
	if _voices.is_empty():
		var silent: PackedVector2Array = PackedVector2Array()
		silent.resize(mini(avail, 512))
		_playback.push_buffer(silent)
		return

	var count: int = mini(avail, 1024)
	var dt: float = 1.0 / SAMPLE_RATE
	var buf := PackedVector2Array()
	buf.resize(count)

	for i in range(count):
		var mix: float = 0.0
		var v_idx: int = _voices.size() - 1
		while v_idx >= 0:
			var v: Dictionary = _voices[v_idx]
			var t: float = float(v["t"]) + dt
			v["t"] = t
			if t < 0.0:
				v_idx -= 1
				continue
			var dur: float = float(v["dur"])
			if t >= dur:
				_voices.remove_at(v_idx)
				v_idx -= 1
				continue
			var p: float = t / dur
			var freq: float = lerpf(float(v["f0"]), float(v["f1"]), p)
			var ph: float = fmod(float(v["phase"]) + freq * dt, 1.0)
			v["phase"] = ph
			var env: float = minf(1.0, t / 0.012) * exp(-p * 4.2)
			var sig: float = sin(ph * TAU) + float(v["harm"]) * 0.45 * sin(ph * TAU * 2.0) + float(v["harm"]) * 0.2 * sin(ph * TAU * 3.0)
			mix += sig * env * float(v["amp"])
			v_idx -= 1
		var out_v: float = tanh(mix)
		buf[i] = Vector2(out_v, out_v)
	_playback.push_buffer(buf)
