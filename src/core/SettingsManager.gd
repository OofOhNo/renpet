extends Node

## SettingsManager - Ajustes persistentes en user://settings.cfg
## Pantalla completa, 10 resoluciones más usadas, velocidad de texto, animación corta de turno,
## informe unificado, volúmenes separados de Música y Efectos y guía de primer turno.

signal settings_changed()

const SETTINGS_PATH: String = "user://settings.cfg"

const RESOLUTIONS: Array[Dictionary] = [
	{"w": 1280, "h": 720, "tag": "HD · 16:9"},
	{"w": 1366, "h": 768, "tag": "Portátil · ~16:9"},
	{"w": 1440, "h": 900, "tag": "WXGA+ · 16:10"},
	{"w": 1600, "h": 900, "tag": "HD+ · 16:9"},
	{"w": 1680, "h": 1050, "tag": "WSXGA+ · 16:10"},
	{"w": 1920, "h": 1080, "tag": "Full HD · 16:9"},
	{"w": 1920, "h": 1200, "tag": "WUXGA · 16:10"},
	{"w": 2560, "h": 1440, "tag": "QHD 2K · 16:9"},
	{"w": 3440, "h": 1440, "tag": "UltraWide · 21:9"},
	{"w": 3840, "h": 2160, "tag": "4K UHD · 16:9"}
]
const DEFAULT_RESOLUTION_INDEX: int = 3   # 1600 x 900

var fullscreen: bool = false
var resolution_index: int = DEFAULT_RESOLUTION_INDEX
var text_speed: int = 1          # 0 = Normal, 1 = Rápida, 2 = Instantánea
var short_turn_anim: bool = false
var unified_turn_end: bool = true
var bgm_volume: float = 0.65
var sfx_volume: float = 0.85
var muted: bool = false
var onboarding_dismissed: bool = false
var tutorial_completed: bool = false

func _ready() -> void:
	load_settings()
	call_deferred("_sync_audio_and_display")

func _sync_audio_and_display() -> void:
	if AstralAudio != null:
		AstralAudio.bgm_volume = bgm_volume
		AstralAudio.sfx_volume = sfx_volume
		AstralAudio.set_muted(muted)
	apply_display()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	fullscreen = bool(cfg.get_value("display", "fullscreen", false))
	resolution_index = clampi(int(cfg.get_value("display", "resolution_index", DEFAULT_RESOLUTION_INDEX)), 0, RESOLUTIONS.size() - 1)
	text_speed = clampi(int(cfg.get_value("ux", "text_speed", 1)), 0, 2)
	short_turn_anim = bool(cfg.get_value("ux", "short_turn_anim", false))
	unified_turn_end = bool(cfg.get_value("ux", "unified_turn_end", true))
	onboarding_dismissed = bool(cfg.get_value("ux", "onboarding_dismissed", false))
	bgm_volume = clampf(float(cfg.get_value("audio", "bgm_volume", 0.65)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", 0.85)), 0.0, 1.0)
	muted = bool(cfg.get_value("audio", "muted", false))
	tutorial_completed = bool(cfg.get_value("ux", "tutorial_completed", false))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	var res_vec: Vector2i = get_resolution_vector()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "resolution_index", resolution_index)
	cfg.set_value("display", "resolution_w", res_vec.x)
	cfg.set_value("display", "resolution_h", res_vec.y)
	cfg.set_value("ux", "text_speed", text_speed)
	cfg.set_value("ux", "short_turn_anim", short_turn_anim)
	cfg.set_value("ux", "unified_turn_end", unified_turn_end)
	cfg.set_value("ux", "onboarding_dismissed", onboarding_dismissed)
	cfg.set_value("ux", "tutorial_completed", tutorial_completed)
	cfg.set_value("audio", "bgm_volume", bgm_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "muted", muted)
	cfg.save(SETTINGS_PATH)
	settings_changed.emit()

func apply_display() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("web"):
		return
	var target: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target:
		DisplayServer.window_set_mode(target)
	if not fullscreen:
		var win_sz: Vector2i = get_resolution_vector()
		var scr: int = DisplayServer.window_get_current_screen()
		var usable: Rect2i = DisplayServer.screen_get_usable_rect(scr)
		DisplayServer.window_set_size(win_sz)
		var pos: Vector2i = usable.position + Vector2i((usable.size.x - win_sz.x) / 2, (usable.size.y - win_sz.y) / 2)
		pos.x = maxi(usable.position.x, pos.x)
		pos.y = maxi(usable.position.y, pos.y)
		DisplayServer.window_set_position(pos)

func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	apply_display()
	save_settings()

func get_resolution_vector(idx: int = -1) -> Vector2i:
	var use_i: int = clampi(resolution_index if idx < 0 else idx, 0, RESOLUTIONS.size() - 1)
	var d: Dictionary = RESOLUTIONS[use_i]
	return Vector2i(int(d["w"]), int(d["h"]))

func get_resolution_label(idx: int = -1) -> String:
	var use_i: int = clampi(resolution_index if idx < 0 else idx, 0, RESOLUTIONS.size() - 1)
	var d: Dictionary = RESOLUTIONS[use_i]
	return "%d × %d  (%s)" % [int(d["w"]), int(d["h"]), str(d["tag"])]

func set_resolution_index(idx: int, exit_fullscreen: bool = true) -> void:
	resolution_index = clampi(idx, 0, RESOLUTIONS.size() - 1)
	if exit_fullscreen and fullscreen:
		fullscreen = false
	apply_display()
	save_settings()

func set_text_speed(v: int) -> void:
	text_speed = clampi(v, 0, 2)
	save_settings()

func set_short_turn_anim(v: bool) -> void:
	short_turn_anim = v
	save_settings()

func set_unified_turn_end(v: bool) -> void:
	unified_turn_end = v
	save_settings()

func set_bgm_volume(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	if AstralAudio != null:
		AstralAudio.set_bgm_volume(bgm_volume)
	save_settings()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	if AstralAudio != null:
		AstralAudio.set_sfx_volume(sfx_volume)
	save_settings()

func set_muted(v: bool) -> void:
	muted = v
	if AstralAudio != null:
		AstralAudio.set_muted(muted)
	save_settings()

func dismiss_onboarding() -> void:
	if not onboarding_dismissed:
		onboarding_dismissed = true
		save_settings()

func mark_tutorial_completed() -> void:
	if not tutorial_completed:
		tutorial_completed = true
		onboarding_dismissed = true
		save_settings()

func reset_tutorial() -> void:
	tutorial_completed = false
	save_settings()

func get_text_speed_label() -> String:
	match text_speed:
		0: return "Normal"
		1: return "Rápida"
		_: return "Instantánea"

func get_typewriter_duration(char_count: int) -> float:
	if text_speed == 2:
		return 0.0
	var scale: float = 1.0 if text_speed == 0 else 0.45
	return clampf(float(char_count) * 0.018 * scale, 0.45 * scale, 4.5 * scale)
