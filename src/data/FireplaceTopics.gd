extends RefCounted
class_name FireplaceTopics

## Tópicos de la Charla en la Chimenea (Fase 3.4).
## Cada tópico ofrece las 4 actitudes paternas de la Biblia: Cálido, Estricto, Curioso y Protector.
## "when" define cuándo aparece (los tópicos se desbloquean por eventos recientes):
##   min_age, stress_min, gold_max, away_min, mutations_min, sync_min, bimester, recent: [prefijo_evento, turnos]

const ATTITUDES: Dictionary = {
	"warm": "Cálido y Afectuoso",
	"strict": "Estricto y Firme",
	"curious": "Curioso y Analítico",
	"protective": "Protector y Cauto"
}

const TOPICS: Array[Dictionary] = [
	{
		"id": "dream_of_chains", "when": {},
		"title": "Sus extraños sueños sobre cadenas de luz y un espejo oscuro",
		"prompt": "\"Padre... anoche soñé de nuevo con un cielo sin luna. Había una voz detrás de un cristal preguntándome por qué los humanos tememos tanto al cambio.\"",
		"stances": {
			"warm": {"father": "\"Mientras estés bajo este techo, ningún sueño podrá hacerte daño. Toma mi mano; yo estoy aquí contigo.\"",
				"reply": "\"Gracias, Padre. Cuando escucho tu voz, el zumbido en mi pecho se vuelve cálido y silencioso.\"",
				"effects": {"affection": 8, "human_anchor": 7, "stress": -10}},
			"strict": {"father": "\"Cierra tu mente a esos murmullos. El control espiritual es la primera muralla de un guerrero.\"",
				"reply": "\"Entendido, Padre. Meditaré antes de dormir para que ninguna grieta perturbe mi concentración.\"",
				"effects": {"temple": 10, "seal_integrity": 4, "stress": 5}},
			"curious": {"father": "\"Cuéntame cada detalle de esa voz, Renpet. Quizá la estrella de la que naciste guarda recuerdos antiguos.\"",
				"reply": "\"¿Tú también crees que no es una pesadilla común? La voz se llama a sí misma Zephyr... dice que lleva siglos esperando.\"",
				"effects": {"erudicion": 12, "abyssal_sync": 8, "seal_investigation": 6}},
			"protective": {"father": "\"No se lo menciones a nadie de la Corte ni del Santuario. Hay oídos en la capital que no comprenderían tu don.\"",
				"reply": "\"Lo guardaré como nuestro secreto familiar. Confío más en ti que en todos los sacerdotes del templo.\"",
				"effects": {"affection": 5, "human_anchor": 5, "resonancia": 10}}
		}
	},
	{
		"id": "academy_and_rivals", "when": {},
		"title": "Sus lecciones en la capital y la competencia con sus pares",
		"prompt": "\"En la ciudad todos murmuran cuando paso diciendo que soy 'la hija del Héroe que salvó a la Diosa'. A veces siento que Dama Vespera y Soren esperan que tropiece.\"",
		"stances": {
			"warm": {"father": "\"No tienes que cargar con mi leyenda, Renpet. Cualquier camino que elijas por ti misma me llenará de orgullo.\"",
				"reply": "\"¡Eso me quita un peso enorme de encima! Pero aun así... quiero esforzarme para estar a tu altura.\"",
				"effects": {"affection": 7, "stress": -12, "human_anchor": 6}},
			"strict": {"father": "\"Que murmuren cuanto quieran. Demuéstrales en el próximo Festival de Otoño de qué está hecha tu voluntad.\"",
				"reply": "\"¡Tienes razón! Entrenaré el doble mañana. Nadie dirá que la casa del Héroe se ha ablandado.\"",
				"effects": {"destreza": 15, "magnetismo": 12, "stress": 6}},
			"curious": {"father": "\"Observa a tus rivales con empatía. Vespera y Soren también cargan con expectativas familiares muy pesadas.\"",
				"reply": "\"Nunca lo había pensado así... La próxima vez que vea a Soren en la biblioteca, intentaré hablar con él sin competir.\"",
				"effects": {"gracia": 14, "moralidad": 6, "erudicion": 8}},
			"protective": {"father": "\"Si alguien te falta al respeto en esas aulas, dímelo a mí antes que a nadie. Tú no pelees sola.\"",
				"reply": "\"Gracias, Padre. Saber que me respaldas hace que la gente me parezca menos intimidante.\"",
				"effects": {"affection": 5, "human_anchor": 6, "stress": -6}}
		}
	},
	{
		"id": "hearth_and_future", "when": {},
		"title": "El paso del tiempo en la mansión y sus deseos para el futuro",
		"prompt": "\"Miraba las muescas que tallamos en la columna de madera del jardín por cada año que cumplo. El tiempo pasa tan rápido cuando estamos juntos, Padre...\"",
		"stances": {
			"warm": {"father": "\"Por muchos años que marquemos en esa madera, esta casa siempre será tu refugio contra el mundo entero.\"",
				"reply": "\"Prométeme que cuando cumpla veinte años seguiremos cenando juntos frente a esta misma chimenea.\"",
				"effects": {"affection": 10, "human_anchor": 10, "stress": -8}},
			"strict": {"father": "\"El tiempo no espera a nadie. Cada año es una oportunidad que se aprovecha o se pierde.\"",
				"reply": "\"Lo sé, Padre. Por eso no quiero desperdiciar ni una lección.\"",
				"effects": {"temple": 8, "destreza": 8, "stress": 5}},
			"curious": {"father": "\"Por eso te llamé Renpet: porque cada año no es algo que se pierde, sino una rama nueva que florece en ti.\"",
				"reply": "\"Me gusta mi nombre, Padre. Siento que cuando lo pronuncias tu voz me ata a la tierra firme.\"",
				"effects": {"resonancia": 15, "seal_integrity": 3, "human_anchor": 5}},
			"protective": {"father": "\"Cuando el mundo cambie, y va a cambiar, prométeme que me dirás cuándo tienes miedo. Sin vergüenza.\"",
				"reply": "\"Te lo prometo. Y tú prométeme lo mismo, porque a veces noto que también lo tienes.\"",
				"effects": {"affection": 6, "human_anchor": 6, "seal_investigation": 3}}
		}
	},
	{
		"id": "father_absence", "when": {"away_min": 2},
		"title": "Las noches en que el salón estuvo vacío",
		"prompt": "\"Este año has salido mucho a trabajar, Padre. Entiendo por qué, de verdad. Pero a veces el salón se siente tan grande...\"",
		"stances": {
			"warm": {"father": "\"Tienes razón, y lo siento. Ningún contrato vale más que una cena contigo. Voy a compensártelo.\"",
				"reply": "\"No tienes que disculparte, pero... gracias por decirlo. Lo necesitaba.\"",
				"effects": {"affection": 10, "human_anchor": 6, "stress": -10}},
			"strict": {"father": "\"El oro sostiene esta casa y esa responsabilidad no se negocia. Tú también aprenderás a cargar con la tuya.\"",
				"reply": "\"Sí, Padre. Lo entiendo... aunque me habría gustado que lo dijeras de otra manera.\"",
				"effects": {"temple": 6, "affection": -3, "stress": 4}},
			"curious": {"father": "\"¿Qué hacías en las noches que no estaba? Cuéntame todo, quiero conocer lo que viviste sola.\"",
				"reply": "\"Estudié las constelaciones desde el balcón. Me dio por contar cuántas estrellas hay en tu constelación favorita.\"",
				"effects": {"erudicion": 8, "affection": 5, "resonancia": 5}},
			"protective": {"father": "\"No voy a dejar que te sientas sola en esta casa. Si me necesitas, dime y vuelvo, aunque sea a medianoche.\"",
				"reply": "\"Eso ya me hace sentir mejor. Aunque no me hagas volver a verte cansado por mí.\"",
				"effects": {"affection": 7, "human_anchor": 8, "stress": -6}}
		}
	},
	{
		"id": "exhaustion", "when": {"stress_min": 60},
		"title": "El cansancio que no se va con el sueño",
		"prompt": "\"Padre, estoy bien... creo. Solo que cuando cierro los ojos todavía oigo el reloj de la clase. No logro apagarlo.\"",
		"stances": {
			"warm": {"father": "\"Ven aquí. Hoy no hay clases, ni notas, ni expectativas. Solo té caliente y esta manta.\"",
				"reply": "\"...Gracias. Creo que estaba esperando que alguien me dijera eso.\"",
				"effects": {"stress": -18, "affection": 8, "human_anchor": 6}},
			"strict": {"father": "\"El descanso también forma parte del entrenamiento. Esta noche te acuestas temprano y no se discute.\"",
				"reply": "\"Entendido. Es raro que me ordenes descansar, pero lo voy a obedecer.\"",
				"effects": {"stress": -10, "temple": 5}},
			"curious": {"father": "\"Descríbeme ese ruido con exactitud. ¿Es el reloj de verdad o viene de dentro del Sello?\"",
				"reply": "\"...Creo que viene de dentro. Cada tic suena como una cadena apretándose.\"",
				"effects": {"stress": -8, "abyssal_sync": 6, "seal_investigation": 5}},
			"protective": {"father": "\"Mañana avisaré en el Santuario de que faltarás unos días. Nadie te va a exigir nada.\"",
				"reply": "\"Me alivia tanto que lo digas... gracias, Padre.\"",
				"effects": {"stress": -14, "human_anchor": 6, "affection": 4}}
		}
	},
	{
		"id": "money_worries", "when": {"gold_max": 200},
		"title": "Las cuentas de la casa",
		"prompt": "\"Vi el libro de cuentas sobre tu escritorio, Padre. No quise curiosear, pero... ¿estamos bien?\"",
		"stances": {
			"warm": {"father": "\"Estamos bien, y lo estaremos aún mejor. Nada de esto es tu culpa ni tu carga.\"",
				"reply": "\"Entonces no me preocuparé. Pero si puedo ayudar en algo, dímelo.\"",
				"effects": {"affection": 6, "stress": -8, "human_anchor": 4}},
			"strict": {"father": "\"Aprenderás a llevar las cuentas. Un hogar que no controla su oro está a un paso de la ruina.\"",
				"reply": "\"Sí, Padre. Empezaré por revisar los gastos de la despensa.\"",
				"effects": {"erudicion": 10, "magnetismo": 5, "stress": 4}},
			"curious": {"father": "\"Ven, te enseñaré qué entra y qué sale. ¿Dónde crees que podemos recortar sin perder lo importante?\"",
				"reply": "\"Podríamos pasar un bimestre sin las Termas... pero entonces el estrés me ganaría. Mejor la dieta.\"",
				"effects": {"erudicion": 12, "moralidad": 4}},
			"protective": {"father": "\"No quiero que cargues con esto. Sigue con tus lecciones; yo me encargo del resto.\"",
				"reply": "\"Está bien, Padre. Pero cuando pueda, yo también contribuiré.\"",
				"effects": {"affection": 5, "human_anchor": 5, "stress": -4}}
		}
	},
	{
		"id": "golden_eyes", "when": {"mutations_min": 1},
		"title": "El brillo dorado en sus pupilas",
		"prompt": "\"Padre, ¿te diste cuenta de que mis ojos brillan un poco más cuando uso el Horno? Marcas de constelaciones me suben por la muñeca... ¿me estoy volviendo otra cosa?\"",
		"stances": {
			"warm": {"father": "\"Sigues siendo mi hija. Las marcas son solo parte de ti, como tu sonrisa o tu forma de reír.\"",
				"reply": "\"Gracias... A veces necesito que me lo recuerdes en voz alta.\"",
				"effects": {"human_anchor": 10, "affection": 6, "stress": -8}},
			"strict": {"father": "\"El poder se domina o te domina. Si vas a usar el Horno, que sea con disciplina y no por impulso.\"",
				"reply": "\"Lo entiendo. Lo haré con más cuidado y con un propósito claro.\"",
				"effects": {"luminiscencia": 8, "temple": 6, "stress": 4}},
			"curious": {"father": "\"Enséñame las marcas. Quiero saber qué señalan: cada mutación parece una pieza de un mismo mapa.\"",
				"reply": "\"Mira: cuando me concentro, las líneas se acomodan como una constelación que aún no tiene nombre.\"",
				"effects": {"resonancia": 12, "seal_investigation": 6, "abyssal_sync": 4}},
			"protective": {"father": "\"Ocúltalas bajo mangas largas cuando salgas a la capital. No todos entenderían lo que son.\"",
				"reply": "\"Lo haré. Prefiero que solo tú las veas, Padre.\"",
				"effects": {"affection": 6, "human_anchor": 6, "seal_integrity": 2}}
		}
	},
	{
		"id": "rival_defeat", "when": {"recent": ["lose_", 2]},
		"title": "Una derrota que todavía le pesa",
		"prompt": "\"Perdí, Padre. Y lo peor es que lo vieron todos. Siento que me dolió más el orgullo que cualquier golpe.\"",
		"stances": {
			"warm": {"father": "\"Perder también es aprender, hija mía. Tu valor no se mide en un marcador.\"",
				"reply": "\"Me gustaría creerte del todo... aunque ya me siento mejor solo por contártelo.\"",
				"effects": {"stress": -12, "affection": 6, "human_anchor": 5}},
			"strict": {"father": "\"Analiza qué falló, corrígelo y vuelve más fuerte. Quejarse no gana revanchas.\"",
				"reply": "\"Tienes razón. Mañana empiezo a entrenar lo que fallé.\"",
				"effects": {"destreza": 8, "erudicion": 6, "stress": 5}},
			"curious": {"father": "\"Repasemos juntos el momento exacto en que se torció. Casi siempre hay una decisión pequeña detrás.\"",
				"reply": "\"Creo que dudé medio segundo antes de actuar. Y medio segundo bastó.\"",
				"effects": {"erudicion": 10, "resonancia": 6}},
			"protective": {"father": "\"Quien te vio perder también vio que te levantaste. Eso importa más de lo que crees.\"",
				"reply": "\"Gracias, Padre. Intentaré recordarlo la próxima vez.\"",
				"effects": {"stress": -8, "affection": 5, "magnetismo": 5}}
		}
	},
	{
		"id": "friend_made", "when": {"recent": ["bond_friend_", 3]},
		"title": "Alguien en quien empieza a confiar",
		"prompt": "\"Padre, hoy conocí a alguien que de verdad me escuchó. No sé cómo explicarlo... es raro tener a alguien en la ciudad que no me trate como una leyenda.\"",
		"stances": {
			"warm": {"father": "\"Me alegra tanto oírte decir eso. Los buenos amigos se cuidan como un jardín: con tiempo y cariño.\"",
				"reply": "\"Lo voy a cuidar, Padre. Y lo traeré un día a casa, si no te molesta.\"",
				"effects": {"affection": 6, "human_anchor": 8, "stress": -8}},
			"strict": {"father": "\"Una amistad se demuestra en los malos momentos. Sé leal y exige lealtad, pero no te dejes manipular.\"",
				"reply": "\"Lo tendré presente. Quiero ser alguien en quien se pueda confiar.\"",
				"effects": {"moralidad": 6, "magnetismo": 8, "stress": 3}},
			"curious": {"father": "\"¿Qué fue lo que más te llamó la atención de esa persona? A veces uno aprende mucho de sí mismo al describir a un amigo.\"",
				"reply": "\"Que no me pidió nada. Solo se quedó conmigo y conversamos hasta que oscureció.\"",
				"effects": {"erudicion": 6, "gracia": 8, "human_anchor": 4}},
			"protective": {"father": "\"Conserva siempre tus propios límites, incluso con los amigos. Y si algo no te gusta, dímelo.\"",
				"reply": "\"Lo haré. Pero creo que este amigo es de los buenos.\"",
				"effects": {"affection": 5, "human_anchor": 7, "magnetismo": 4}}
		}
	},
	{
		"id": "mirror_dreams", "when": {"min_age": 15, "sync_min": 20},
		"title": "El muchacho del espejo de agua",
		"prompt": "\"Zephyr volvió anoche. Ya no intenta asustarme; hoy me preguntó cómo sabe el pan caliente. No supe qué responderle, Padre.\"",
		"stances": {
			"warm": {"father": "\"Dile que está caliente, suave, y que huele a casa. Y que algún día lo comerá de verdad.\"",
				"reply": "\"...Creo que lo conmoviste, Padre. Se quedó muy callado después.\"",
				"effects": {"abyssal_sync": 8, "human_anchor": 8, "affection": 6}},
			"strict": {"father": "\"No olvides que sigue siendo un prisionero. Escúchalo, pero no te dejes arrastrar por su voz.\"",
				"reply": "\"Lo sé. Pero tampoco quiero tratarlo como a un monstruo.\"",
				"effects": {"seal_integrity": 5, "temple": 5, "stress": 4}},
			"curious": {"father": "\"Pregúntale qué recuerda del día en que lo encerraron. Cada detalle puede servirnos.\"",
				"reply": "\"Dice que lo traicionaron cuando más confiaba. Se me heló el pecho al oírlo.\"",
				"effects": {"seal_investigation": 8, "abyssal_sync": 8, "erudicion": 8}},
			"protective": {"father": "\"Esa conversación es tuya y mía. Si alguna vez te sientes arrastrada, avísame al instante.\"",
				"reply": "\"Lo haré. Confío en ti más que en nadie.\"",
				"effects": {"human_anchor": 8, "affection": 7, "seal_integrity": 3}}
		}
	},
	{
		"id": "solstice_eve", "when": {"bimester": 6},
		"title": "La noche antes de su cumpleaños",
		"prompt": "\"Mañana cumplo otro año, Padre. Cada vez que el Solsticio llega, siento que el cielo nos mira un poco más de cerca.\"",
		"stances": {
			"warm": {"father": "\"Mañana habrá torta de miel y dátiles, y no importa qué diga el cielo: esta noche es nuestra.\"",
				"reply": "\"Gracias, Padre. Pase lo que pase, este es el mejor cumpleaños que podría pedir.\"",
				"effects": {"affection": 10, "human_anchor": 8, "stress": -10}},
			"strict": {"father": "\"Un año más significa un año más de responsabilidades. Quiero verte crecer con la frente en alto.\"",
				"reply": "\"Lo haré. Quiero que estés orgulloso de quien soy.\"",
				"effects": {"magnetismo": 8, "temple": 6, "stress": 4}},
			"curious": {"father": "\"Dime qué has aprendido de ti misma este año. Escríbelo en tu carta; la guardaré con las demás.\"",
				"reply": "\"Que soy más terca de lo que creía... y más curiosa, también.\"",
				"effects": {"erudicion": 8, "resonancia": 8, "seal_investigation": 3}},
			"protective": {"father": "\"Sea lo que sea que se acerque, no vas a enfrentarlo sola. Eso te lo prometo hoy y todos los años.\"",
				"reply": "\"Y yo prometo no ocultarte nada importante, Padre.\"",
				"effects": {"affection": 7, "human_anchor": 8, "seal_integrity": 3}}
		}
	}
]

## Devuelve los tópicos disponibles hoy como lista de diccionarios con las 4 actitudes ya ordenadas.
static func get_available() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t in TOPICS:
		if _is_available(t["when"]):
			result.append(t)
	return result

static func get_topic(topic_id: String) -> Dictionary:
	for t in TOPICS:
		if t["id"] == topic_id:
			return t
	return {}

static func _is_available(cond: Dictionary) -> bool:
	if cond.has("min_age") and GameState.age < int(cond["min_age"]):
		return false
	if cond.has("stress_min") and GameState.stress < int(cond["stress_min"]):
		return false
	if cond.has("gold_max") and GameState.gold > int(cond["gold_max"]):
		return false
	if cond.has("away_min") and TimeManager.father_times_worked_away_this_year < int(cond["away_min"]):
		return false
	if cond.has("mutations_min") and GameState.active_mutations.size() < int(cond["mutations_min"]):
		return false
	if cond.has("sync_min") and GameState.abyssal_sync < int(cond["sync_min"]):
		return false
	if cond.has("bimester") and TimeManager.current_bimester != int(cond["bimester"]):
		return false
	if cond.has("recent"):
		if not Chronicle.has_recent_event(str(cond["recent"][0]), int(cond["recent"][1])):
			return false
	return true
