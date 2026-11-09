extends Node

## Singleton SaveManager - Sistema de guardado, carga y autoguardado bimensual en JSON.

const SAVE_PREFIX: String = "user://renpet_save_slot_"

func get_save_path(slot: int) -> String:
	return "%s%d.json" % [SAVE_PREFIX, slot]

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func save_game(slot: int = 1, extra_data: Dictionary = {}) -> bool:
	var data: Dictionary = {
		"daughter_name": GameState.daughter_name,
		"age": GameState.age,
		"father_name": GameState.father_name,
		"father_archetype": int(GameState.father_archetype),
		"temple": GameState.temple,
		"destreza": GameState.destreza,
		"erudicion": GameState.erudicion,
		"gracia": GameState.gracia,
		"magnetismo": GameState.magnetismo,
		"luminiscencia": GameState.luminiscencia,
		"gravedad": GameState.gravedad,
		"resonancia": GameState.resonancia,
		"entropia": GameState.entropia,
		"moralidad": GameState.moralidad,
		"devocion": GameState.devocion,
		"human_anchor": GameState.human_anchor,
		"seal_integrity": GameState.seal_integrity,
		"abyssal_sync": GameState.abyssal_sync,
		"stress": GameState.stress,
		"current_stamina": GameState.current_stamina,
		"affection": GameState.affection,
		"gold": GameState.gold,
		"current_diet": int(GameState.current_diet),
		"father_energy": GameState.father_energy,
		"father_reputation": GameState.father_reputation,
		"seal_investigation_progress": GameState.seal_investigation_progress,
		"astral_saturation": GameState.astral_saturation,
		"active_mutations": GameState.active_mutations,
		"unlocked_synergies": GameState.unlocked_synergies,
		"materials_inventory": GameState.materials_inventory,
		"estate_levels": GameState.estate_levels,
		"current_total_turn": TimeManager.current_total_turn,
		"current_year": TimeManager.current_year,
		"current_bimester": TimeManager.current_bimester,
		"events_ledger": Chronicle.events_ledger,
		"letters_archive": Chronicle.letters_archive,
		"extra": extra_data
	}
	
	var file := FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_game(slot: int = 1) -> Dictionary:
	if not has_save(slot):
		return {"ok": false}
	var file := FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		return {"ok": false}
	var text: String = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false}
		
	var data: Dictionary = parsed
	GameState.daughter_name = str(data.get("daughter_name", "Renpet"))
	GameState.age = int(data.get("age", 12))
	GameState.father_name = str(data.get("father_name", "Aurelius"))
	GameState.father_archetype = int(data.get("father_archetype", 0)) as GameState.HeroArchetype
	GameState.temple = int(data.get("temple", 130))
	GameState.destreza = int(data.get("destreza", 120))
	GameState.erudicion = int(data.get("erudicion", 135))
	GameState.gracia = int(data.get("gracia", 105))
	GameState.magnetismo = int(data.get("magnetismo", 100))
	GameState.luminiscencia = int(data.get("luminiscencia", 110))
	GameState.gravedad = int(data.get("gravedad", 90))
	GameState.resonancia = int(data.get("resonancia", 100))
	GameState.entropia = int(data.get("entropia", 5))
	GameState.moralidad = int(data.get("moralidad", 60))
	GameState.devocion = int(data.get("devocion", 50))
	GameState.human_anchor = int(data.get("human_anchor", 70))
	GameState.seal_integrity = int(data.get("seal_integrity", 92))
	GameState.abyssal_sync = int(data.get("abyssal_sync", 10))
	GameState.stress = int(data.get("stress", 15))
	GameState.current_stamina = int(data.get("current_stamina", 330))
	GameState.affection = int(data.get("affection", 75))
	GameState.gold = int(data.get("gold", 850))
	GameState.current_diet = int(data.get("current_diet", 1)) as GameState.DietPlan
	GameState.father_energy = int(data.get("father_energy", 100))
	GameState.father_reputation = int(data.get("father_reputation", 60))
	GameState.seal_investigation_progress = int(data.get("seal_investigation_progress", 0))
	GameState.astral_saturation = int(data.get("astral_saturation", 0))
	
	GameState.active_mutations.clear()
	for m in data.get("active_mutations", []):
		GameState.active_mutations.append(str(m))
		
	GameState.unlocked_synergies.clear()
	for s in data.get("unlocked_synergies", []):
		GameState.unlocked_synergies.append(str(s))
		
	if data.has("materials_inventory") and typeof(data["materials_inventory"]) == TYPE_DICTIONARY:
		for k in data["materials_inventory"].keys():
			GameState.materials_inventory[str(k)] = int(data["materials_inventory"][k])
			
	if data.has("estate_levels") and typeof(data["estate_levels"]) == TYPE_DICTIONARY:
		for k in data["estate_levels"].keys():
			GameState.estate_levels[str(k)] = int(data["estate_levels"][k])
			
	if data.has("events_ledger") and typeof(data["events_ledger"]) == TYPE_ARRAY:
		Chronicle.events_ledger.clear()
		for ev in data["events_ledger"]:
			if typeof(ev) == TYPE_DICTIONARY:
				Chronicle.events_ledger.append(ev)
				
	if data.has("letters_archive") and typeof(data["letters_archive"]) == TYPE_ARRAY:
		Chronicle.letters_archive.clear()
		for lt in data["letters_archive"]:
			if typeof(lt) == TYPE_DICTIONARY:
				Chronicle.letters_archive.append(lt)
				
	TimeManager.current_total_turn = int(data.get("current_total_turn", 1))
	TimeManager.current_year = int(data.get("current_year", 12))
	TimeManager.current_bimester = int(data.get("current_bimester", 1))
	TimeManager.update_era()
	
	GameState.recalculate_derived_stats()
	GameState.evaluate_psychological_traits()
	return {"ok": true, "extra": data.get("extra", {})}
