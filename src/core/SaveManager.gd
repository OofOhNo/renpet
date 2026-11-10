extends Node

## SaveManager - Guardado y carga en JSON (Fase 1.5).
##  - Ranura 0 = autoguardado bimensual (se escribe al cerrar cada bimestre).
##  - Ranuras 1 a 3 = guardados manuales.
##  - Escritura segura: archivo temporal + copia de respaldo (.bak) antes de reemplazar.
##  - Versionado (SAVE_VERSION) y migración de las partidas del formato antiguo (v1).

signal saved(slot: int)
signal loaded(slot: int)

const SAVE_VERSION: int = 2
const SAVE_DIR: String = "user://saves"
const LEGACY_PREFIX: String = "user://renpet_save_slot_"
const AUTOSAVE_SLOT: int = 0
const MANUAL_SLOTS: Array[int] = [1, 2, 3]

## Ranura manual en uso (la que escribe el botón Guardar)
var current_slot: int = 1
## La pantalla de título deja aquí la ranura a cargar al entrar a la mansión (-1 = partida nueva)
var pending_load_slot: int = -1

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_migrate_legacy_files()

# ------------------------------------------------------------------------------
# RUTAS Y LISTADO
# ------------------------------------------------------------------------------
func get_save_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func has_any_save() -> bool:
	for s in [AUTOSAVE_SLOT] + MANUAL_SLOTS:
		if has_save(s):
			return true
	return false

## Metadatos de cada ranura para el menú: {slot, exists, label, age, turn, gold, saved_at, valid}
func list_slots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in [AUTOSAVE_SLOT] + MANUAL_SLOTS:
		var entry: Dictionary = {"slot": slot, "exists": false, "valid": false,
			"label": "Autoguardado" if slot == AUTOSAVE_SLOT else "Ranura %d" % slot}
		if has_save(slot):
			entry["exists"] = true
			var data: Dictionary = _read_json(get_save_path(slot))
			if not data.is_empty() and data.has("meta"):
				var meta: Dictionary = data["meta"]
				entry["valid"] = true
				entry["daughter_name"] = str(meta.get("daughter_name", "Renpet"))
				entry["age"] = int(meta.get("age", 12))
				entry["turn"] = int(meta.get("turn", 1))
				entry["bimester_name"] = str(meta.get("bimester_name", ""))
				entry["gold"] = int(meta.get("gold", 0))
				entry["saved_at"] = int(meta.get("saved_at", 0))
		out.append(entry)
	return out

# ------------------------------------------------------------------------------
# NUEVA PARTIDA
# ------------------------------------------------------------------------------
func new_game() -> void:
	GameState.reset_new_game()
	TimeManager.reset_new_game()
	Chronicle.reset_new_game()
	RelationshipManager.reset_new_game()
	RivalMirror.reset_new_game()
	CrucibleManager.reset_new_game()
	TurnExecutor.reset_new_game()
	current_slot = 1

# ------------------------------------------------------------------------------
# GUARDAR
# ------------------------------------------------------------------------------
func autosave() -> bool:
	return _write_slot(AUTOSAVE_SLOT)

func save_game(slot: int = -1) -> bool:
	if slot < 0:
		slot = current_slot
	if not MANUAL_SLOTS.has(slot):
		push_warning("SaveManager: ranura manual inválida %d" % slot)
		return false
	current_slot = slot
	return _write_slot(slot)

func build_payload() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"meta": {
			"daughter_name": GameState.daughter_name, "age": GameState.age,
			"turn": TimeManager.current_total_turn,
			"bimester_name": TimeManager.get_bimester_info()["name"],
			"gold": GameState.gold, "saved_at": int(Time.get_unix_time_from_system())
		},
		"game_state": GameState.serialize(),
		"time": TimeManager.serialize(),
		"chronicle": Chronicle.serialize(),
		"relationships": RelationshipManager.serialize(),
		"rivals": RivalMirror.serialize(),
		"crucible": CrucibleManager.serialize(),
		"plan": TurnExecutor.serialize()
	}

func _write_slot(slot: int) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path: String = get_save_path(slot)
	var tmp_path: String = path + ".tmp"
	var bak_path: String = path + ".bak"

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: no se pudo abrir %s (error %d)" % [tmp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(build_payload(), "\t"))
	file.close()

	# Verifica que lo escrito se pueda leer antes de reemplazar el guardado anterior
	if _read_json(tmp_path).is_empty():
		push_error("SaveManager: el archivo temporal quedó ilegible; se conserva el guardado anterior.")
		DirAccess.remove_absolute(tmp_path)
		return false

	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return false
	var base: String = path.get_file()
	if dir.file_exists(base):
		if dir.file_exists(bak_path.get_file()):
			dir.remove(bak_path.get_file())
		dir.rename(base, bak_path.get_file())
	var err: int = dir.rename(tmp_path.get_file(), base)
	if err != OK:
		push_error("SaveManager: no se pudo finalizar el guardado (error %d)" % err)
		return false
	saved.emit(slot)
	return true

# ------------------------------------------------------------------------------
# CARGAR
# ------------------------------------------------------------------------------
func load_game(slot: int = 1) -> Dictionary:
	if not has_save(slot):
		return {"ok": false, "msg": "No hay una partida en esta ranura."}
	var data: Dictionary = _read_json(get_save_path(slot))
	if data.is_empty():
		# Intenta con la copia de respaldo
		data = _read_json(get_save_path(slot) + ".bak")
		if data.is_empty():
			return {"ok": false, "msg": "El archivo de guardado está dañado."}
	var version: int = int(data.get("version", 1))
	if version > SAVE_VERSION:
		return {"ok": false, "msg": "Este guardado pertenece a una versión más reciente del juego."}
	if version < 2 or not data.has("game_state"):
		data = _migrate_v1(data)

	GameState.deserialize(data.get("game_state", {}))
	TimeManager.deserialize(data.get("time", {}))
	Chronicle.deserialize(data.get("chronicle", {}))
	RelationshipManager.deserialize(data.get("relationships", {}))
	RivalMirror.deserialize(data.get("rivals", {}))
	CrucibleManager.deserialize(data.get("crucible", {}))
	TurnExecutor.deserialize(data.get("plan", {}))
	if MANUAL_SLOTS.has(slot):
		current_slot = slot
	loaded.emit(slot)
	return {"ok": true}

func delete_slot(slot: int) -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var p: String = get_save_path(slot) + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

# ------------------------------------------------------------------------------
# UTILIDADES Y MIGRACIÓN
# ------------------------------------------------------------------------------
func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

## Convierte el formato antiguo (todo plano + "extra") al formato v2.
func _migrate_v1(old: Dictionary) -> Dictionary:
	var extra: Dictionary = old.get("extra", {}) if typeof(old.get("extra", {})) == TYPE_DICTIONARY else {}
	var state: Dictionary = {}
	var cands: Dictionary = extra.get("candidates", {}) if typeof(extra.get("candidates", {})) == TYPE_DICTIONARY else {}
	for npc_id in cands.keys():
		var c: Dictionary = cands[npc_id]
		state[npc_id] = {"affection": int(c.get("affection", 0)), "respect": int(c.get("respect", 0)),
			"spark": int(c.get("spark", 0)), "stage": int(c.get("stage", 1)), "events_seen": []}
	var scores: Dictionary = {}
	var mirror: Dictionary = extra.get("rivals_mirror", {}) if typeof(extra.get("rivals_mirror", {})) == TYPE_DICTIONARY else {}
	for rid in mirror.keys():
		scores[rid] = int(mirror[rid].get("score", 250)) if typeof(mirror[rid]) == TYPE_DICTIONARY else 250
	return {
		"version": SAVE_VERSION,
		"meta": {"daughter_name": str(old.get("daughter_name", "Renpet")), "age": int(old.get("age", 12)),
			"turn": int(old.get("current_total_turn", 1)), "bimester_name": "", "gold": int(old.get("gold", 0)),
			"saved_at": 0},
		"game_state": old,
		"time": {"current_total_turn": int(old.get("current_total_turn", 1))},
		"chronicle": {"events_ledger": old.get("events_ledger", []), "letters_archive": old.get("letters_archive", [])},
		"relationships": {"state": state},
		"rivals": {"scores": scores},
		"crucible": {}, "plan": {}
	}

## Convierte guardados antiguos de user://renpet_save_slot_N.json a la nueva carpeta (una sola vez).
func _migrate_legacy_files() -> void:
	for slot in MANUAL_SLOTS:
		var legacy: String = "%s%d.json" % [LEGACY_PREFIX, slot]
		if FileAccess.file_exists(legacy) and not has_save(slot):
			var data: Dictionary = _read_json(legacy)
			if data.is_empty():
				continue
			var migrated: Dictionary = _migrate_v1(data)
			var f := FileAccess.open(get_save_path(slot), FileAccess.WRITE)
			if f != null:
				f.store_string(JSON.stringify(migrated, "\t"))
				f.close()
				DirAccess.rename_absolute(legacy, legacy + ".migrated")
