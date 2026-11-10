extends ModalOverlay
class_name EndingOverlay

## Cierre de la campaña de 48 turnos: las Fases 1 a 6 terminan aquí (el Torneo, la Expedición y los
## Finales llegan en las Fases 7 a 9). Se muestra un resumen honesto y se vuelve al título.

signal title_requested()

func show_ending() -> void:
	set_panel_width(900)
	rebuild(func() -> void:
		content.add_child(AstralTheme.label("%s  EL SOLSTICIO DE LOS VEINTE AÑOS  %s" % [AstralTheme.G_STAR, AstralTheme.G_STAR], "HeadingLabel", AstralTheme.GOLD, true))
		content.add_child(AstralTheme.separator())
		content.add_child(AstralTheme.rich("[font_size=21]Ocho años han pasado desde la noche en que la estrella cayó en tus brazos. %s ya no es una niña: es una mujer de veinte años con un secreto latiendo en el pecho, y la Diosa llega esta noche.[/font_size]" % GameState.daughter_name))
		content.add_child(AstralTheme.rich("[b]Estado final[/b]\n%s\nSello %d%%  ·  Anclaje Humano %d  ·  Sincronía %d\nRasgos: %s\nMutaciones: %d  ·  Sinergias de prestigio: %d  ·  Cartas escritas: %d" % [
			AstralTheme.colored(GameState.get_metaphysical_state_title(), AstralTheme.TURQ), GameState.seal_integrity, GameState.human_anchor, GameState.abyssal_sync,
			", ".join(GameState.active_traits), GameState.active_mutations.size(), GameState.unlocked_synergies.size(), Chronicle.letters_archive.size()]))
		var note := AstralTheme.panel("SunkenPanel")
		note.add_child(AstralTheme.label("Esta versión del juego llega hasta la Fase 6. Las pruebas finales (Torneo, Expedición y los Finales) todavía no están implementadas.", "CaptionLabel", AstralTheme.MUTED, true))
		content.add_child(note)
		var b := AstralTheme.button("Volver al título", "PrimaryButton")
		b.custom_minimum_size.y = 56
		b.pressed.connect(func() -> void:
			hide_overlay()
			title_requested.emit())
		content.add_child(b))
	show_overlay()
