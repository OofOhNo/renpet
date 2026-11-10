# Auditoría y mejoras de las Fases 1 a 6

Revisión completa de `documentacion/` (Biblia, Hoja de Ruta) frente al código de las Fases 1 a 6, con correcciones,
piezas faltantes, rediseño de la interfaz y pruebas automáticas. Todo está verificado con Godot 4.6.1 en modo headless
y con capturas reales de pantalla (renderizado por software).

## 1. Decisiones que debes conocer

**Romance solo desde los 18 años.** La documentación y el código permitían la "Chispa Romántica", citas y elecciones
con corazón (♥) desde los 12–15 años. Renpet es una niña en esas edades, así que:

- La Chispa Romántica, las citas y las elecciones románticas de las escenas **solo existen cuando Renpet tiene 18 o más**
  y el personaje también es adulto (cada candidato tiene una edad base: Soren 14, Vespera 14, Kaelen 15, Cassian 16,
  Mirari 14 al inicio; crecen con ella. Zephyr es un ser ancestral).
- Antes de los 18, cada personaje sigue teniendo dos rutas: **Amistad** y **Rivalidad/Némesis** (más las tres escenas de historia).
- La "custodia honorífica" de Cassian reemplaza al compromiso político en las escenas de menores.
- Está cubierto por pruebas (`tools/simulate_campaign.gd`, `test_age_gate`) y la constante vive en `GameState.ROMANCE_MIN_AGE`.
- Los textos románticos que existen (para 18+) son sobrios: gestos y confesiones.

**No pude abrir el tablero de Pinterest** (el sitio bloquea el acceso automático). La estética se mantuvo fiel al arte que ya
tiene el proyecto (lapislázuli, oro, marfil, turquesa y amatista; Egipto + astronomía fantástica). Toda la paleta está en
`src/ui/AstralTheme.gd`: si me pasas capturas del tablero o 5–6 palabras clave, se ajusta en un solo archivo.

**Balance:** se añadió `CatalogDB.BIG_STAT_GAIN_SCALE = 0.55` (ver §5).

## 2. Errores corregidos

### Lógica y arquitectura
| Problema original | Corrección |
|---|---|
| La resolución del turno (cobros, ganancias, rivales, mantenimiento) vivía dentro de `ManorHub.gd` (UI de ~1800 líneas). | Nuevo autoload `TurnExecutor`; la UI solo planifica y muestra el informe. |
| `RelationshipManager` se instanciaba dentro de la escena y no se guardaba. | Autoload registrado; estado completo en el guardado. |
| El guardado omitía vínculos, rivales, contadores del Padre, charla del bimestre, salida social, fragmentos, etc. | Cada módulo implementa `serialize()/deserialize()`; guardado versionado (v2) con migración del formato antiguo. |
| El autoguardado pisaba la ranura 1 manual en cada turno. | Ranura 0 de autoguardado + 3 ranuras manuales; escritura segura (temporal + `.bak`). |
| El prólogo reaparecía al cargar en el turno 1 sin progreso. | Bandera `prologue_completed`. |
| Turno 48: terminaba sin mantenimiento y **sin la última carta**; el informe del turno 6 de cada año se perdía; las cartas decían "mis 12 años" al cumplir 13. | Corregido: el turno 48 aplica mantenimiento y entrega la carta de los 20; el informe siempre se muestra; la carta se escribe con la edad nueva. |
| Los bonos de bimestre (+10% Erudición, +15% Afecto/Anclaje, +25% cósmicos, +20% ingresos urbanos) eran solo texto. | Se aplican de verdad (`TimeManager.get_gain_bonus / get_income_bonus`). |
| El bono de nivel de mansión se sumaba a **todos** los atributos (incluidos Anclaje, Entropía, Moralidad). | Solo a las ganancias principales (≥15). La supervisión ya no multiplica valores negativos. |
| Dietas: comentarios y código no coincidían (Austera sin −2 Temple, Banquete −14 vs −15, Purificación +2 vs +3%). | Una sola fuente en `CatalogDB.DIETS`; si falta oro la casa cae a Dieta Austera con aviso. |
| Bond events repetibles sin límite (farmeo de Afecto) y cada repetición subía la etapa. | Una escena por etapa (3 por personaje), desbloqueada por Acto y vínculo, que consume la salida del bimestre. |
| Zephyr disponible desde el turno 1. | Aparece a los 15 años (Acto II) o al asimilar la *Voz del Prisionero*. |
| Rasgos con umbrales distintos a la Biblia y sin tope de 4. | Umbrales de la Biblia §1.3; máximo 4 por prioridad. |
| Materiales y mutaciones con valores/nombres distintos a la Biblia ("Voz del Eclipse", Mercurio −4, Sarcófago…). | Alineados (ver §4 para el caso de Anclaje). |
| Azar con `randi()` (no reproducible). | Tiradas deterministas (`GameState.det_rng`: semilla de partida + turno + bloque). |
| Tópicos de chimenea regenerados al azar y solo algunos con las 4 actitudes. | 11 tópicos reactivos a eventos recientes, todos con Cálido/Estricto/Curioso/Protector. |
| Rival "Lobo Gris" (la Biblia dice "Perro Gris"); choques de aula sin estados; Vespera no entrenaba el doble. | `RivalMirror`: estados *Inspirada* / *Picada en su Orgullo*, entrenamiento doble de Vespera, freno y suelo espejo. |
| `get_activity_by_id` devolvía la primera actividad en silencio si el id no existía. | Devuelve vacío y avisa en consola. |
| La UI se reconstruía por completo en **cada** cambio de atributo (decenas de veces por turno). | Actualización agrupada (`begin_batch/end_batch` + refresco diferido). |

### Interfaz y presentación
- La barra superior **se cortaba** (el botón *Cargar* quedaba fuera de pantalla) y la caja de diálogo iniciaba vacía.
- Los glifos `𓇳` y varios emojis se veían como cuadrados vacíos: ahora se incluyen fuentes con licencia OFL
  (Cinzel, Alegreya Sans) y subconjuntos de Noto Symbols (normalizados para no inflar el interlineado).
- Diseño con posiciones absolutas → ahora contenedores y anclas: probado en 16:9, 21:9 y 4:3.
- Las listas de actividades se truncaban; ahora cada decano muestra descripción, mentor, rival y efectos reales calculados.

### Higiene del repositorio
- Eliminado el archivo de bloqueo de Word `documentacion/~$npet_…docx` y el `.docx` duplicado de la raíz (idéntico byte a byte).
- `Volcano_Maiden_GDD_Master.docx` (proyecto anterior) movido a `documentacion/legacy/`.
- `.gitignore` (bloqueos de Office, build) y `.gitattributes` (binarios) completados; icono propio en lugar del de Godot.

## 3. Piezas añadidas (dentro de las Fases 1–6)

| Fase | Novedad |
|---|---|
| 1 | Guardado por ranuras, autoguardado, migración v1→v2; Crónica con consultas por evento reciente; cartas con más variables. |
| 2 | 5ª tarea del Padre (**Diplomacia**), `father_reputation` con efecto real (descuentos y objetos exclusivos); Relojería pasa a oficio (Biblia §4). |
| 3 | Pantalla de título, prólogo narrado en 3 páginas, creación del héroe con validación, mejoras de mansión hasta nivel 5. |
| 4 | Agenda del Padre con 100 de Energía y exclusiones (el Padre no puede estar en dos sitios), vista previa, 12 micro-eventos deterministas que premian los rasgos, **fatiga** (≥80 Estrés: −25%) y **colapso** (100: la Doctora Helena la atiende). |
| 5 | Vista previa de fusión, Sobrecarga Astral con confirmación, saturación con umbrales, bazar de Zahir solo en bimestres pares, destilación (1 por bimestre), purificación. |
| 6 | 18 escenas de historia (3 por candidato, ramas Amistad/Rival/18+), duelos y choques de aula, marcador de rivalidad. |
| UI | Tema propio, atajos 1–5 / Esc / F11, tooltips, animaciones, estrellas, foco de teclado y mando. |

Correspondencia con la Hoja de Ruta (que pedía escenas separadas): `HeroCreation`→`PrologueOverlay`,
`SchedulePlanner`, `TurnExecution`→`TurnReportOverlay`, `FireplaceModal/EstateModal`→`HearthWindow`,
`AstralCrucible`, `TownMap`; scripts `CrucibleManager.gd`, `RivalMirror.gd` creados tal cual.

## 4. Errata de la documentación (para corregir en los .docx)

1. **Lágrima de la Diosa: "+50 Anclaje Humano"** — el Anclaje va de 0 a 100; +50 es medio medidor. Se implementó +25. Decide si lo quieres distinto.
2. **"Caelum"** designa a la vez al rival (*El Perro Gris*) y a la República de Soren. Conviene renombrar una.
3. La Biblia sitúa el romance desde los 15 años y un matrimonio político con Cassian: ver §1.
4. El Acto III dice "18 a 20 años" pero solo hay 12 turnos jugables (18 y 19) más la noche de los 20.
5. La Hoja de Ruta lista escenas `.tscn` que nunca existieron; la UI se construye por código (ver §3).
6. `ExplorationCombat.gd` (Fase 7/8) no está conectado a nada; solo se ajustó para usar mutaciones por id. Además comprobaba el Festival en el bimestre 5 mientras `TimeManager.FESTIVAL_BIMESTER` y la Biblia dicen 4: ya usa la constante.

## 5. Observaciones de balance (simulación de 6 estrategias × 48 turnos)

- Con los valores originales un especialista llegaba al tope de 1200 hacia los 16 años: se aplicó el factor 0.55 a las ganancias de atributos grandes; ahora un jugador equilibrado roza el tope al final.
- Estrategias que solo trabajan acumulan mucho oro (>20 000): faltan sumideros (mejoras de mansión ya ayudan; pensar en gastos de Fase 8).
- Anclaje y Sello llegan a 100 en juego seguro: la tensión del twist depende de eventos de la trama (Fases 7–9) y del Horno. Se sugiere que esos eventos puedan erosionarlos.
- Con 48 salidas sociales los 6 vínculos pueden alcanzar la etapa 3; si quieres que haya que elegir, limita las salidas o añade coste.

## 6. Cómo probar

```
godot --headless --path . res://tools/Simulator.tscn      # núcleo: 6 estrategias, guardado, regla de edad, catálogos
godot --headless --path . res://tools/UISmoke.tscn        # interfaz: flujo completo de 48 turnos
godot --path . --script tools/screenshot.gd -- res://src/scenes/ManorHub.tscn out.png prologue_off,open:status
```

Mapa de módulos: `src/core` (GameState, TimeManager, Chronicle, TurnExecutor, CrucibleManager, RelationshipManager,
RivalMirror, SaveManager) · `src/data` (CatalogDB, BondEvents, FireplaceTopics) · `src/ui` (AstralTheme, StatBar, StarField,
BaseWindow, `windows/`, `overlays/`) · `src/scenes` (TitleScreen, ManorHub).
