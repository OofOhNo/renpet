extends Node

## RelationshipManager.gd - Sistema de Relaciones 3D (Amor, Amistad, Odio/Némesis),
## Escenas Interactivas de Vínculo y Duelos de Rivales en Espejo (Fase 6).

signal relationship_updated(npc_id: String)
signal rival_ranks_updated()

var interacted_this_bimester: bool = false
var rival_challenged_this_bimester: bool = false

# Base de datos de los 6 Candidatos Principales con Matriz 3D:
# affection (-100 a +100), respect (-100 a +100), spark (0 a 100), stage (1 a 3)
var candidates: Dictionary = {
	"soren": {
		"id": "soren",
		"name": "Soren de Caelum",
		"title": "El Astrónomo de la Torre de Cristal",
		"location": "Observatorio de la Cumbre",
		"affection": 20,
		"respect": 25,
		"spark": 0,
		"stage": 1,
		"event_seen_stage": 0,
		"perk_desc": "Compañero en Expedición: +25% Daño Astral y revela puntos débiles (Guardia -15).",
		"bio": "Prodigio astronómico cuya madre fue desterrada por calcular que la estrella de Renpet era una prisión milenaria.",
		"dialogues": {
			"support": "\"¿Me trajiste café mientras reviso las tablas lunares? Gracias, Renpet... Contigo aquí, siento que la verdad del cielo no da tanto miedo.\"",
			"romance": "\"Mis manos tiemblan cuando ajustas mis lentes así... He medido mil constelaciones, pero ninguna brilla como tú cuando sonríes.\"",
			"gift": "\"¡Un cristal de cuarzo tallado! Es perfecto para la lente del telescopio de mi madre. Nunca olvidaré este gesto.\"",
			"provoke": "\"¿Te burlas del destierro de mi madre y rompes mis mapas? Escúchame bien, Renpet: demostraré ante el Senado que eres una anomalía peligrosa.\""
		},
		"bond_event": {
			"title": "El Mapa Prohibido de la Madre de Soren",
			"narrative": "A medianoche en la Torre de Cristal, Soren te muestra temblando el papiro sellado por el que desterraron a su madre: las ecuaciones demuestran que la estrella que cayó hace doce años no era un regalo divino, sino una celda.\n\n«Si el Archimago descubre que conservo este mapa me expulsarán, Renpet... pero tenía que mostrarte la verdad sobre tu corazón.»",
			"choices": [
				{
					"label": "♥ Tomar sus manos: «Descifraremos juntos el cielo, Soren. Mi vida está en tus manos.»",
					"affection": 22, "respect": 15, "spark": 28,
					"stat_effects": {"erudicion": 18, "seal_investigation": 10},
					"outcome": "Soren entrelaza sus dedos con los tuyos bajo la cúpula estrellada, jurando encontrar la forma de romper el sello sin que mueras."
				},
				{
					"label": "★ Prometer alianza: «Gracias por confiar en mí, amigo mío. Limpiaremos el nombre de tu madre.»",
					"affection": 24, "respect": 24, "spark": 0,
					"stat_effects": {"erudicion": 20, "human_anchor": 8},
					"outcome": "Soren sonríe con profundo alivio y sella contigo un pacto de hermandad académica inquebrantable."
				},
				{
					"label": "⚔ Confiscar el mapa con frialdad: «Mi naturaleza no es un acertijo para tu familia, Soren.»",
					"affection": -28, "respect": 16, "spark": 0,
					"stat_effects": {"gravedad": 20, "entropia": 8},
					"outcome": "Los ojos de Soren se endurecen tras sus lentes. Guarda silencio, pero jura superarte en el Gran Astrolabio."
				}
			]
		}
	},
	"vespera": {
		"id": "vespera",
		"name": "Dama Vespera de Val-Astra",
		"title": "La Lanza de Escarcha y el Deber",
		"location": "Patio Ducal de Armas",
		"affection": -5,
		"respect": 35,
		"spark": 0,
		"stage": 1,
		"event_seen_stage": 0,
		"perk_desc": "Compañera en Expedición: +25% Daño Físico y rompe +20 de Guardia enemiga por golpe.",
		"bio": "Heredera militar presionada por un padre tiránico para superar a la hija del Héroe; en secreto escribe poesía lírica.",
		"dialogues": {
			"support": "\"¿No le contaste a nadie que estos versos eran míos? Eres más noble de lo que mi padre dice, Renpet. Cruzar lanzas contigo es un honor.\"",
			"romance": "\"Baja el arma un segundo... Cuando me miras de ese modo, toda mi disciplina marcial se derrite como nieve al sol.\"",
			"gift": "\"¿Una cinta de seda y un tomo de poesía antigua? Yo... lo guardaré bajo mi armadura, cerca del corazón.\"",
			"provoke": "\"¡Jamás perdonaré esta humillación! Juro por la sangre de Val-Astra que en nuestro próximo duelo no usaré armas de práctica.\""
		},
		"bond_event": {
			"title": "Versos Bajo la Armadura de Escarcha",
			"narrative": "Tras el entrenamiento vespertino bajo la lluvia, encuentras a Dama Vespera curando sus nudillos ensangrentados junto a un cuaderno de poemas sobre un pájaro enjaulado.\n\n«Mi padre el Duque dice que si no derroto a la hija del Héroe, no merezco su apellido... Adelante, ríete de mis estúpidos versos.»",
			"choices": [
				{
					"label": "♥ Acariciar su mejilla herida: «Tus versos son más fuertes que la lanza de tu padre, Vespera.»",
					"affection": 25, "respect": 18, "spark": 30,
					"stat_effects": {"destreza": 16, "gracia": 16},
					"outcome": "Vespera contiene el aliento, sonrojándose por primera vez mientras apoya su frente contra tu hombro."
				},
				{
					"label": "★ Ofrecer tu mano de camarada: «Peleemos por nuestro propio honor, no por el de nuestros padres.»",
					"affection": 22, "respect": 26, "spark": 0,
					"stat_effects": {"temple": 22, "human_anchor": 8},
					"outcome": "Vespera choca su antebrazo con el tuyo al estilo de los antiguos caballeros solares."
				},
				{
					"label": "⚔ Desafiarla sin piedad: «Los poemas no detienen una estocada. Levántate y pelea en serio.»",
					"affection": -25, "respect": 22, "spark": 10,
					"stat_effects": {"temple": 25, "destreza": 15},
					"outcome": "El orgullo de Vespera arde como hielo azul. Empuña su lanza jurando derrotarte en el Festival de Otoño."
				}
			]
		}
	},
	"kaelen": {
		"id": "kaelen",
		"name": "Kaelen de los Canales",
		"title": "El Rey de los Huérfanos de Mercurio",
		"location": "Acueductos Subterráneos",
		"affection": 10,
		"respect": 15,
		"spark": 0,
		"stage": 1,
		"event_seen_stage": 0,
		"perk_desc": "Compañero en Expedición: +40% Oro obtenido en mazmorras y +20% Evasión.",
		"bio": "Líder rebelde de los bajos fondos que lucha por curar a los niños afectados por la Fiebre de Escoria que vierte la nobleza.",
		"dialogues": {
			"support": "\"¿Bajaste desde tu cómoda mansión con vendas y luz estelar para curar a los críos del canal? Tienes agallas, princesa de estrella.\"",
			"romance": "\"Sube al tejado conmigo, Renpet. Desde aquí arriba ni los dioses ni el Emperador pueden decirnos a quién amar.\"",
			"gift": "\"¿Medicinas puras y acero bien templado? Esto salvará media docena de vidas esta noche. Te debo una grande.\"",
			"provoke": "\"¿Así que miras por encima del hombro a los que vivimos en el barro? Cuida las cerraduras de tu mansión, hija del Héroe.\""
		},
		"bond_event": {
			"title": "Fiebre de Escoria en los Acueductos",
			"narrative": "La guardia ducal ha bloqueado el puente de medicinas hacia los canales inferiores. Kaelen está acorralado en el tejado con un cargamento de elixires robados para los huérfanos enfermos.\n\n«¡Apártate, princesa! Si te ven ayudándome, mancharás el ilustre nombre de tu padre.»",
			"choices": [
				{
					"label": "♥ Saltar junto a él y cubrir su huida: «Que hablen lo que quieran; esta noche vuelo contigo, Kaelen.»",
					"affection": 24, "respect": 20, "spark": 28,
					"stat_effects": {"destreza": 20, "luminiscencia": 15},
					"outcome": "Escapan juntos por las cornisas iluminadas por la luna. Kaelen te besa la mano entre risas de adrenalina."
				},
				{
					"label": "★ Usar tu prestigio para abrir el paso legalmente y curar a los niños.",
					"affection": 26, "respect": 25, "spark": 0,
					"stat_effects": {"moralidad": 15, "human_anchor": 10},
					"outcome": "Los huérfanos del canal te aclaman como su protectora y Kaelen te jura lealtad eterna."
				},
				{
					"label": "⚔ Entregar el cargamento a la guardia para mantener el orden imperial.",
					"affection": -35, "respect": -10, "spark": 0,
					"stat_effects": {"gravedad": 20, "gold": 120},
					"outcome": "Kaelen escapa entre las sombras con una mirada de puro rencor que jamás olvidará."
				}
			]
		}
	},
	"cassian": {
		"id": "cassian",
		"name": "Príncipe Cassian Aurelius",
		"title": "El Heredero del Sol Eclipsado",
		"location": "Jardines del Palacio de Alabastro",
		"affection": 15,
		"respect": 20,
		"spark": 5,
		"stage": 1,
		"event_seen_stage": 0,
		"perk_desc": "Compañero en Expedición: Autoridad Imperial (+20% a todos los daños y escudos).",
		"bio": "Príncipe heredero que descubre que su padre el Emperador planea usar a Renpet como sacrificio en el Solsticio de sus 20 años.",
		"dialogues": {
			"support": "\"En la corte todos me ven como una corona con patas. Solo cuando converso contigo en el jardín recuerdo quién soy en realidad.\"",
			"romance": "\"Si el trono de Aethelgard exige tu sacrificio para sostenerse, entonces prenderé fuego al trono con mis propias manos por ti.\"",
			"gift": "\"Un presente elegido con tanto gusto... Lo llevaré en la solapa durante la sesión del Senado Imperial.\"",
			"provoke": "\"Desprecias mi mano tendida y amenazas la paz del reino. Si eliges ser el enemigo de la Corona, la Corona responderá sin piedad.\""
		},
		"bond_event": {
			"title": "El Decreto Secreto del Solsticio",
			"narrative": "Durante un baile de gala en el Palacio de Alabastro, el Príncipe Cassian te conduce tras las columnas de loto. Tiene el rostro pálido.\n\n«Renpet, acabo de leer las actas secretas de mi padre y del Sumo Sacerdote... Creen que cuando cumplas veinte años, la Diosa regresará a reclamar tu estrella para alimentar el Reloj Imperial.»",
			"choices": [
				{
					"label": "♥ Abrazarlo en la penumbra: «Entonces cambiemos el destino del Imperio juntos, Cassian.»",
					"affection": 24, "respect": 18, "spark": 28,
					"stat_effects": {"magnetismo": 22, "seal_investigation": 10},
					"outcome": "Cassian te estrecha contra su pecho y promete usar todo el poder de la corona para proteger tu vida."
				},
				{
					"label": "★ Forjar un pacto político: «Seré tu aliada para reformar el Senado antes del Solsticio.»",
					"affection": 20, "respect": 28, "spark": 0,
					"stat_effects": {"gracia": 20, "erudicion": 15},
					"outcome": "El Príncipe inclina la cabeza ante tu temple de estadista y te entrega su sello personal."
				},
				{
					"label": "⚔ Rechazar a la familia real: «Dile al Emperador que si intenta tocarme, su palacio caerá.»",
					"affection": -26, "respect": 15, "spark": 0,
					"stat_effects": {"gravedad": 25, "abyssal_sync": 8},
					"outcome": "Cassian retrocede con tristeza solemne, comprendiendo que la corona y tú podrían terminar en guerra."
				}
			]
		}
	},
	"mirari": {
		"id": "mirari",
		"name": "Mirari del Anfiteatro",
		"title": "La Cantora que Escucha el Tiempo",
		"location": "Anfiteatro de Cristal",
		"affection": 30,
		"respect": 30,
		"spark": 0,
		"stage": 1,
		"event_seen_stage": 0,
		"perk_desc": "Compañera en Expedición: Regenera +15% de HP cada turno y protege la Integridad del Sello.",
		"bio": "Oráculo y arpista ciega que escucha dos latidos en el pecho de Renpet: el corazón humano y el astro encadenado.",
		"dialogues": {
			"support": "\"Acércate, Renpet. Puedo oír cómo la canción de tu padre envuelve las cadenas de tu pecho para que no te lastimen.\"",
			"romance": "\"Mis ojos no ven las estrellas del cielo, pero cuando toco tu rostro siento la luz más hermosa de la creación.\"",
			"gift": "\"Cuerdas de plata resonante para mi arpa... El sonido que producen calma hasta los ecos más tristes del tiempo.\"",
			"provoke": "\"Tu corazón suena quebrado y lleno de ceniza cruel, Renpet. Si devoras a los inocentes, mi canto tendrá que sellarte.\""
		},
		"bond_event": {
			"title": "La Canción de los Dos Latidos",
			"narrative": "En el Anfiteatro vacío al atardecer, Mirari apoya su oído sobre tu pecho mientras pulsa una acorde de plata en su arpa.\n\n«Escucho a la niña que ama a su padre... y escucho al espíritu de la estrella llorando tras los barrotes de oro. Si ambos siguen peleando, tu alma se romperá.»",
			"choices": [
				{
					"label": "♥ Cantar a dúo con ella tomando sus manos: «Enséñame a ser una sola melodía contigo, Mirari.»",
					"affection": 25, "respect": 18, "spark": 28,
					"stat_effects": {"luminiscencia": 20, "seal_integrity": 6},
					"outcome": "Sus voces resuenan en las columnas de cristal, restaurando la paz de tu núcleo y despertando un amor luminoso."
				},
				{
					"label": "★ Pedirle que armonice ambos latidos para proteger a tu familia.",
					"affection": 24, "respect": 24, "spark": 0,
					"stat_effects": {"human_anchor": 10, "seal_integrity": 8},
					"outcome": "Mirari te bendice con el Himno de la Palma Eterna, fortaleciendo tu Sello y tu corazón mortal."
				},
				{
					"label": "⚔ Hacer vibrar las cuerdas con poder abisal: «No necesito que nadie domestique mi tormenta.»",
					"affection": -25, "respect": 10, "spark": 0,
					"stat_effects": {"resonancia": 25, "abyssal_sync": 10},
					"outcome": "Una cuerda del arpa de Mirari se rompe con un chispazo púrpura. Ella reza en silencio por tu destino."
				}
			]
		}
	},
	"zephyr": {
		"id": "zephyr",
		"name": "Zephyr (Nyx-Aethel)",
		"title": "El Prisionero Detrás del Espejo",
		"location": "Espejo Astral del Sueño",
		"affection": 0,
		"respect": 25,
		"spark": 10,
		"stage": 1,
		"event_seen_stage": 0,
		"perk_desc": "Simbiosis Interior: Reduce a la mitad el coste del Sello al invocar el poder abisal en combate.",
		"bio": "El espíritu del Lucero Primordial del libre albedrío encerrado dentro de Renpet por la traición de la Diosa de la Eternidad.",
		"dialogues": {
			"support": "\"¿Compartes tus recuerdos del hogar conmigo en vez de rezar para callarme? Qué extraña carcelera me ha tocado... Cálida y terca.\"",
			"romance": "\"La Diosa nos encerró en el mismo cuerpo para que nos destruyéramos, Renpet... y en cambio has hecho que un astro muerto se enamore de ti.\"",
			"gift": "\"¿Ofreces una esquirla de luz al espejo para aliviar mis cadenas? Nadie había tenido piedad de mí en mil años.\"",
			"provoke": "\"¿Me tratas como a una bestia enjaulada? Sigue apretando los barrotes, niña; cuando tu sello se rompa, devoraré todo lo que amas.\""
		},
		"bond_event": {
			"title": "El Pacto Frente al Espejo del Sueño",
			"narrative": "En sueños, el espejo del observatorio se abre hacia un mar de nebulosas violetas. Zephyr aparece con cadenas de oro egipcio atadas a sus muñecas.\n\n«La Diosa Renpet-Neheh me encerró porque yo era el Cambio y ella quería una Eternidad inmóvil. Tú eres mi jaula, niña... ¿Qué harás conmigo cuando llegue el Equinoccio?»",
			"choices": [
				{
					"label": "♥ Tocar su rostro a través del cristal: «No soy tu carcelera, Zephyr. Seremos libres juntos.»",
					"affection": 26, "respect": 20, "spark": 30,
					"stat_effects": {"abyssal_sync": 14, "resonancia": 22},
					"outcome": "Las cadenas doradas dejan de quemar. Zephyr apoya su mano contra la tuya en una simbiosis perfecta."
				},
				{
					"label": "★ Proponer una tregua justa: «Préstame tu fuerza para proteger a mi padre y buscaré tu libertad.»",
					"affection": 22, "respect": 28, "spark": 0,
					"stat_effects": {"abyssal_sync": 10, "human_anchor": 8, "seal_investigation": 10},
					"outcome": "Zephyr sonríe con respeto genuino ante tu coraje mortal, sellando la alianza del Tercer Camino."
				},
				{
					"label": "⚔ Reforzar los barrotes dorados: «Este cuerpo y esta vida son míos. ¡Obedece mis órdenes!»",
					"affection": -30, "respect": 20, "spark": 0,
					"stat_effects": {"seal_integrity": 8, "gravedad": 25},
					"outcome": "Zephyr ruge entre relámpagos carmesíes, jurando que el día que flaquees tomará el control por la fuerza."
				}
			]
		}
	}
}

# Puntuación competitiva en espejo de los 4 Rivales de Aethelgard
var rivals_mirror: Dictionary = {
	"vespera": {"id": "vespera", "name": "Dama Vespera", "domain": "Marcial (Temple + Destreza)", "score": 260, "stat_a": "temple", "stat_b": "destreza"},
	"soren": {"id": "soren", "name": "Soren de Caelum", "domain": "Académico (Erudición + Resonancia)", "score": 255, "stat_a": "erudicion", "stat_b": "resonancia"},
	"lyra": {"id": "lyra", "name": "Lady Lyra de Meridia", "domain": "Corte y Gala (Gracia + Magnetismo)", "score": 245, "stat_a": "gracia", "stat_b": "magnetismo"},
	"caelum": {"id": "caelum", "name": "Caelum 'El Lobo Gris'", "domain": "Caza y Sombra (Destreza + Gravedad)", "score": 240, "stat_a": "destreza", "stat_b": "gravedad"}
}

func get_renpet_domain_score(rival_id: String) -> int:
	if not rivals_mirror.has(rival_id):
		return 0
	var r: Dictionary = rivals_mirror[rival_id]
	return int(GameState.get(r["stat_a"])) + int(GameState.get(r["stat_b"]))

func challenge_rival_duel(rival_id: String) -> Dictionary:
	if not rivals_mirror.has(rival_id):
		return {"ok": false, "msg": "Rival no encontrado."}
	if rival_challenged_this_bimester:
		return {"ok": false, "msg": "Ya disputaste un Duelo de Prestigio oficial en este bimestre."}
	rival_challenged_this_bimester = true
	var r: Dictionary = rivals_mirror[rival_id]
	var my_score: int = get_renpet_domain_score(rival_id)
	var riv_score: int = int(r["score"])
	
	if my_score >= riv_score:
		GameState.modify_gold(150)
		GameState.modify_stat(r["stat_a"], 14)
		GameState.modify_stat("magnetismo", 10)
		if candidates.has(rival_id):
			candidates[rival_id]["respect"] = clampi(int(candidates[rival_id]["respect"]) + 16, -100, 100)
		Chronicle.record_event("duel_win_" + rival_id, "Victoria de Prestigio contra %s" % r["name"], "Renpet superó a %s en %s (%d vs %d)." % [r["name"], r["domain"], my_score, riv_score], "rivalry", 4)
		return {
			"ok": true,
			"speaker": "Duelo de Prestigio — ¡VICTORIA!",
			"reply": "¡%s superó a %s en %s (%d vs %d) ante toda la Academia Real!" % [GameState.daughter_name, r["name"], r["domain"], my_score, riv_score],
			"effects": "+150 Oro, +14 %s, +10 Magnetismo, +16 Respeto" % str(r["stat_a"]).capitalize()
		}
	else:
		GameState.modify_stat(r["stat_a"], 10)
		GameState.modify_stat("stress", 8)
		r["score"] = int(r["score"]) + 10
		return {
			"ok": true,
			"speaker": "Duelo de Prestigio — Derrota Honorable",
			"reply": "%s se impuso por %d a %d en %s. %s aprendió de la derrota y prometió volver más fuerte." % [r["name"], riv_score, my_score, r["domain"], GameState.daughter_name],
			"effects": "+10 %s (Aprendizaje), +8 Estrés" % str(r["stat_a"]).capitalize()
		}

func get_relationship_status_title(npc_id: String) -> String:
	var c: Dictionary = candidates.get(npc_id, {})
	if c.is_empty():
		return "Desconocido"
	var aff: int = int(c["affection"])
	var res: int = int(c["respect"])
	var spk: int = int(c["spark"])
	
	if aff >= 65 and res >= 55 and spk >= 60:
		return "♥ AMOR VERDADERO (Amantes Destinados)"
	elif aff < 20 and res >= 50 and spk >= 45:
		return "♦ TENSIÓN ENEMIGOS-A-AMANTES"
	elif aff < 0 and spk >= 50:
		return "♠ OBSESIÓN TRÁGICA"
	elif aff >= 65 and res >= 60 and spk < 60:
		return "★ MEJOR AMIGO / HERMANO DE JURAMENTO"
	elif aff >= 35 and res >= 30:
		return "✦ Confidente y Aliado Leal"
	elif aff <= -45 and res >= 40:
		return "⚔ NÉMESIS HONORABLE (Duelo Jurado)"
	elif aff <= -45 and res < 40:
		return "☠ ODIO MORTAL (Saboteador / Enemigo)"
	elif aff < 0 and res >= 35:
		return "⚡ Rivalidad Feroz"
	return "• Conocido de Aethelgard"

func interact_with_candidate(npc_id: String, action_type: String) -> Dictionary:
	if not candidates.has(npc_id):
		return {"ok": false, "msg": "Personaje no encontrado."}
	if interacted_this_bimester:
		return {"ok": false, "msg": "Renpet ya realizó su salida social en la capital durante este bimestre. Espera al siguiente turno."}
		
	var c: Dictionary = candidates[npc_id]
	var reply: String = ""
	var effect_summary: String = ""
	
	match action_type:
		"support":
			interacted_this_bimester = true
			c["affection"] = clampi(int(c["affection"]) + 16, -100, 100)
			c["respect"] = clampi(int(c["respect"]) + 14, -100, 100)
			GameState.modify_stat("human_anchor", 5)
			if npc_id == "zephyr":
				GameState.modify_stat("abyssal_sync", 10)
			reply = c["dialogues"]["support"]
			effect_summary = "+16 Afecto, +14 Respeto, +5 Anclaje Humano"
		"romance":
			interacted_this_bimester = true
			c["spark"] = clampi(int(c["spark"]) + 20, 0, 100)
			c["affection"] = clampi(int(c["affection"]) + 12, -100, 100)
			GameState.modify_stat("stress", -10)
			GameState.modify_stat("human_anchor", 6)
			reply = c["dialogues"]["romance"]
			effect_summary = "+20 Chispa Romántica, +12 Afecto, -10 Estrés"
		"gift":
			if not GameState.modify_gold(-75):
				return {"ok": false, "msg": "Necesitas 75 G para comprar un regalo especial en el Bazar."}
			interacted_this_bimester = true
			c["affection"] = clampi(int(c["affection"]) + 22, -100, 100)
			c["respect"] = clampi(int(c["respect"]) + 10, -100, 100)
			reply = c["dialogues"]["gift"]
			effect_summary = "-75 Oro | +22 Afecto, +10 Respeto"
		"provoke":
			interacted_this_bimester = true
			c["affection"] = clampi(int(c["affection"]) - 30, -100, 100)
			if GameState.temple + GameState.erudicion >= 300:
				c["respect"] = clampi(int(c["respect"]) + 12, -100, 100)
				effect_summary = "-30 Afecto, +12 Respeto (Rivalidad/Némesis), +6 Entropía"
			else:
				c["respect"] = clampi(int(c["respect"]) - 18, -100, 100)
				effect_summary = "-30 Afecto, -18 Respeto (Odio/Desprecio), +6 Entropía"
			GameState.modify_stat("entropia", 6)
			reply = c["dialogues"]["provoke"]
			
	if abs(int(c["affection"])) >= 45 and int(c["stage"]) == 1:
		c["stage"] = 2
	elif abs(int(c["affection"])) >= 80 and int(c["stage"]) == 2:
		c["stage"] = 3
		
	var new_status: String = get_relationship_status_title(npc_id)
	Chronicle.record_event("bond_" + npc_id, "Vínculo con %s (%s)" % [c["name"], new_status], reply, "social", 3)
	relationship_updated.emit(npc_id)
	return {
		"ok": true,
		"speaker": "%s — %s" % [c["name"], new_status],
		"reply": reply,
		"effects": effect_summary
	}

func apply_bond_event_choice(npc_id: String, choice_idx: int) -> Dictionary:
	var c: Dictionary = candidates.get(npc_id, {})
	if c.is_empty():
		return {"ok": false}
	var ev: Dictionary = c["bond_event"]
	var ch: Dictionary = ev["choices"][choice_idx]
	c["affection"] = clampi(int(c["affection"]) + int(ch["affection"]), -100, 100)
	c["respect"] = clampi(int(c["respect"]) + int(ch["respect"]), -100, 100)
	c["spark"] = clampi(int(c["spark"]) + int(ch["spark"]), 0, 100)
	c["event_seen_stage"] = int(c["stage"])
	if int(c["stage"]) < 3:
		c["stage"] = int(c["stage"]) + 1
		
	var s_eff: Dictionary = ch.get("stat_effects", {})
	var eff_labels: Array[String] = [
		"Afecto %+d" % int(ch["affection"]),
		"Respeto %+d" % int(ch["respect"]),
		"Chispa %+d" % int(ch["spark"])
	]
	for k in s_eff.keys():
		if k == "gold":
			GameState.modify_gold(int(s_eff[k]))
			eff_labels.append("Oro %+dG" % int(s_eff[k]))
		else:
			GameState.modify_stat(k, int(s_eff[k]))
			eff_labels.append("%s %+d" % [str(k).capitalize(), int(s_eff[k])])
			
	var st_title: String = get_relationship_status_title(npc_id)
	Chronicle.record_event("scene_" + npc_id, "Escena con %s: %s" % [c["name"], ev["title"]], ch["outcome"], "romance", 5)
	relationship_updated.emit(npc_id)
	return {
		"ok": true,
		"speaker": "%s — %s" % [c["name"], st_title],
		"outcome": ch["outcome"],
		"effects": ", ".join(eff_labels)
	}

## Avanza el entrenamiento en espejo de los 4 rivales cada bimestre
func advance_rivals_mirror() -> void:
	var renpet_martial: int = GameState.temple + GameState.destreza
	var renpet_academic: int = GameState.erudicion + GameState.resonancia
	var renpet_court: int = GameState.gracia + GameState.magnetismo
	var renpet_hunt: int = GameState.destreza + GameState.gravedad
	
	rivals_mirror["vespera"]["score"] = maxi(int(rivals_mirror["vespera"]["score"]) + 28, int(renpet_martial * 0.92))
	rivals_mirror["soren"]["score"] = maxi(int(rivals_mirror["soren"]["score"]) + 26, int(renpet_academic * 0.90))
	rivals_mirror["lyra"]["score"] = maxi(int(rivals_mirror["lyra"]["score"]) + 25, int(renpet_court * 0.88))
	rivals_mirror["caelum"]["score"] = maxi(int(rivals_mirror["caelum"]["score"]) + 24, int(renpet_hunt * 0.88))
	rival_ranks_updated.emit()
