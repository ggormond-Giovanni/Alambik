extends Control

# Voile commun aux entrees et changements de salle. Le sceau tourne pendant le
# fondu : il relie visuellement l'ouverture du grimoire a l'arene suivante.

var _anim := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	var centre := size * 0.5
	StyleInterface.dessiner_fond(self, size, Palette.ESSENCE, _anim)
	# Des bandes de pages donnent un sens vertical au passage sans faire croire
	# que le joueur a change d'application.
	for index in 7:
		var hauteur := size.y / 7.0 + 2.0
		var glissement := sin(_anim * 1.4 + float(index) * 0.72) * 18.0
		var couleur := Color(Palette.ESSENCE if index % 2 == 0 else Palette.OR,
			0.025 + float(index % 3) * 0.008)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-30.0 + glissement, float(index) * hauteur),
			Vector2(size.x + 30.0 + glissement, float(index) * hauteur),
			Vector2(size.x + 30.0 - glissement, float(index + 1) * hauteur),
			Vector2(-30.0 - glissement, float(index + 1) * hauteur)]), couleur)
	Dessin.halo(self, centre, 250.0, Color(Palette.ESSENCE, 0.34), 7)
	Dessin.halo(self, centre, 150.0, Color(Palette.OR, 0.20), 5)
	for index in 3:
		var rayon := 102.0 + float(index) * 42.0
		var vitesse := (0.42 + float(index) * 0.17) * (-1.0 if index % 2 else 1.0)
		var debut := _anim * vitesse + float(index) * 0.7
		draw_arc(centre, rayon, debut, debut + PI * (0.78 + float(index) * 0.12), 42,
			Color(Palette.OR.lerp(Palette.ESSENCE, float(index) / 2.0), 0.66), 3.0, true)
	Dessin.contour(self, Dessin.polygone_regulier(centre, 78.0, 6, PI / 6.0 + _anim * 0.14),
		Color(Palette.ESSENCE, 0.32), 2.5)
	draw_circle(centre, 9.0 + sin(_anim * 3.2) * 2.0, Palette.OR)
