extends Node

## AstralAudio - Motor de sonido y música ambiental procedural cristalino (sin archivos externos).
## Sintetiza música adaptativa (Observatorio, Título, Tensión/Inquisición, Combate, Festival, Epílogo)
## junto a efectos táctiles con controles independientes de Música y Efectos.

signal mute_changed(is_muted: bool)
signal volume_changed()

const SAMPLE_RATE: float = 44100.0
const BUFFER_LEN: float = 0.09
const MAX_VOICES: int = 16

const MOOD_SCALES: Dictionary = {
	"manor": {
		"notes": [261.63, 329.63, 392.00, 493.88, 523.25, 392.00, 329.63, 293.66],
		"bass": [130.81, 130.81, 110.00, 110.00, 146.83, 146.83, 98.00, 130.81],
		"step_s": 0.92, "pad_amp": 0.030, "arp_amp": 0.028
	},
	"title": {
		"notes": [293.66, 349.23, 440.00, 523.25, 587.33, 440.00, 349.23, 329.63],
		"bass": [146.83, 146.83, 116.54, 116.54, 130.81, 130.81, 110.00, 146.83],
		"step_s": 1.05, "pad_amp": 0.032, "arp_amp": 0.030
	},
	"tension": {
		"notes": [220.00, 261.63, 329.63, 415.30, 329.63, 246.94, 220.00, 196.00],
		"bass": [110.00, 110.00, 103.83, 103.83, 98.00, 98.00, 103.83, 110.00],
		"step_s": 0.72, "pad_amp": 0.034, "arp_amp": 0.026
	},
	"combat": {
		"notes": [293.66, 440.00, 349.23, 523.25, 440.00, 587.33, 523.25, 440.00],
		"bass": [146.83, 146.83, 146.83, 164.81, 174.61, 174.61, 130.81, 146.83],
		"step_s": 0.42, "pad_amp": 0.026, "arp_amp": 0.034
	},
	"festival": {
		"notes": [349.23, 440.00, 523.25, 659.25, 587.33, 523.25, 440.00, 392.00],
		"bass": [174.61, 174.61, 130.81, 130.81, 146.83, 146.83, 130.81, 174.61],
		"step_s": 0.48, "pad_amp": 0.028, "arp_amp": 0.034
	},
	"ending": {
		"notes": [261.63, 392.00, 493.88, 523.25, 659.25, 587.33, 493.88, 392.00],
		"bass": [130.81, 130.81, 164.81, 164.81, 174.61, 174.61, 196.00, 130.81],
		"step_s": 0.96, "pad_amp": 0.036, "arp_amp": 0.032
	}
}

var muted: bool = false
var bgm_volume: float = 0.65
var sfx_volume: float = 0.85
var music_mood: String = "title"

var _enabled: bool = false
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _voices: Array[Dictionary] = []

var _bgm_step_timer: float = 0.0
var _bgm_step_idx: int = 0
var _bgm_pad_phase: float = 0.0
var _bgm_pad_phase2: float = 0.0
var _bgm_pad_freq: float = 130.81

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = BUFFER_LEN
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.volume_db = -4.0
	add_child(_player)
	_player.play()
	var pb := _player.get_stream_playback()
	if pb is AudioStreamGeneratorPlayback:
		_playback = pb as AudioStreamGeneratorPlayback
		_enabled = true

func toggle_mute() -> bool:
	set_muted(not muted)
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
	if SettingsManager != null and SettingsManager.muted != v:
		SettingsManager.muted = v
		SettingsManager.save_settings()

func set_bgm_volume(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	volume_changed.emit()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	volume_changed.emit()

func set_music_mood(mood: String) -> void:
	if MOOD_SCALES.has(mood) and music_mood != mood:
		music_mood = mood
		_bgm_step_idx = 0
		_bgm_step_timer = 0.0

func _add_voice(freq: float, dur: float, amp: float = 0.11, delay: float = 0.0, freq_end: float = -1.0, harmonic: float = 0.35, is_bgm: bool = false) -> void:
	if not _enabled or muted:
		return
	if _voices.size() >= MAX_VOICES:
		for k in range(_voices.size()):
			if bool(_voices[k].get("bgm", false)):
				_voices.remove_at(k)
				break
		if _voices.size() >= MAX_VOICES:
			_voices.remove_at(0)
	_voices.append({
		"f0": freq,
		"f1": freq_end if freq_end > 0.0 else freq,
		"dur": maxf(0.03, dur),
		"t": -delay,
		"phase": 0.0,
		"amp": clampf(amp, 0.005, 0.24),
		"harm": clampf(harmonic, 0.0, 0.8),
		"bgm": is_bgm
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

func _process(delta: float) -> void:
	if not _enabled or _playback == null:
		return

	var scale_data: Dictionary = MOOD_SCALES.get(music_mood, MOOD_SCALES["manor"])
	var step_s: float = float(scale_data["step_s"])
	if not muted and bgm_volume > 0.01:
		_bgm_step_timer -= delta
		if _bgm_step_timer <= 0.0:
			_bgm_step_timer = step_s
			var notes: Array = scale_data["notes"]
			var bass: Array = scale_data["bass"]
			var n_f: float = float(notes[_bgm_step_idx % notes.size()])
			_bgm_pad_freq = float(bass[_bgm_step_idx % bass.size()])
			_add_voice(n_f, step_s * 1.45, float(scale_data["arp_amp"]), 0.0, -1.0, 0.18, true)
			if _bgm_step_idx % 2 == 0:
				_add_voice(n_f * 1.5, step_s * 1.20, float(scale_data["arp_amp"]) * 0.55, 0.08, -1.0, 0.10, true)
			_bgm_step_idx += 1

	var avail: int = _playback.get_frames_available()
	if avail <= 0:
		return
	if muted or (_voices.is_empty() and bgm_volume <= 0.01):
		var silent := PackedVector2Array()
		silent.resize(mini(avail, 512))
		_playback.push_buffer(silent)
		return

	var count: int = mini(avail, 1024)
	var dt: float = 1.0 / SAMPLE_RATE
	var buf := PackedVector2Array()
	buf.resize(count)
	var pad_amp: float = float(scale_data["pad_amp"]) * bgm_volume if not muted else 0.0

	for i in range(count):
		var mix: float = 0.0
		if pad_amp > 0.0005:
			_bgm_pad_phase = fmod(_bgm_pad_phase + _bgm_pad_freq * dt, 1.0)
			_bgm_pad_phase2 = fmod(_bgm_pad_phase2 + (_bgm_pad_freq * 1.498) * dt, 1.0)
			mix += (sin(_bgm_pad_phase * TAU) * 0.65 + sin(_bgm_pad_phase2 * TAU) * 0.35) * pad_amp

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
			var env: float = minf(1.0, t / (0.04 if bool(v.get("bgm", false)) else 0.012)) * exp(-p * (2.8 if bool(v.get("bgm", false)) else 4.2))
			var sig: float = sin(ph * TAU) + float(v["harm"]) * 0.45 * sin(ph * TAU * 2.0) + float(v["harm"]) * 0.2 * sin(ph * TAU * 3.0)
			var gain: float = bgm_volume if bool(v.get("bgm", false)) else sfx_volume
			mix += sig * env * float(v["amp"]) * gain
			v_idx -= 1
		var out_v: float = tanh(mix)
		buf[i] = Vector2(out_v, out_v)
	_playback.push_buffer(buf)
