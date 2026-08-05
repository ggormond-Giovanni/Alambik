extends Control

# Titre, bouton, meilleur resultat. Aucun sprite : le grimoire est dessine.

var _anim := 0.0
var _particules: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	print("Alambic pret")
	var alea := RandomNumberGenerator.new()
	alea.seed = 20260801
	for i in 34:
		_particules.append({
			"position": Vector2(alea.randf_range(0.0, 1080.0), alea.randf_range(0.0, 1920.0)),
			"vitesse": Vector2(alea.randf_range(-12.0, 12.0), alea.randf_range(-26.0, -8.0)),
			"rayon": alea.randf_range(2.0, 6.0),
			"phase": alea.randf() * TAU,
		})
	_construire()
	Capture.programmer(self)

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 90)
	marge.add_theme_constant_override("margin_right", 90)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 110)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_END
	colonne.add_theme_constant_override("separation", 24)
	marge.add_child(colonne)

	var descendre := Button.new()
	descendre.text = "Descendre"
	descendre.custom_minimum_size = Vector2(0, 140)
	descendre.add_theme_font_size_override("font_size", 44)
	descendre.add_theme_color_override("font_color", Palette.OR)
	descendre.pressed.connect(func() -> void:
		Sons.jouer("choix", -10.0)
		get_tree().change_scene_to_file("res://scenes/run.tscn"))
	colonne.add_child(descendre)

func _process(delta: float) -> void:
	_anim += delta
	var hauteur := get_viewport_rect().size.y
	for p in _particules:
		p["position"] += p["vitesse"] * delta
		if p["position"].y < -20.0:
			p["position"].y = hauteur + 20.0
	queue_redraw()

func _draw() -> void:
	var police := ThemeDB.fallback_font
	var taille := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, taille), Palette.FOND)

	# Poussiere d'encre en suspension : le menu respire sans coûter une image.
	for p in _particules:
		var scintille: float = 0.25 + 0.25 * sin(_anim * 2.0 + p["phase"])
		draw_circle(p["position"], p["rayon"], Color(Palette.PARCHEMIN_VEINE, scintille))

	var centre := Vector2(taille.x / 2.0, taille.y * 0.27)
	Dessin.halo(self, centre, 300.0, Color(Palette.ESSENCE, 0.35), 6)

	# Le grimoire ouvert, vu de face : deux pages et une reliure.
	var largeur := 380.0
	var hauteur := 260.0
	var page_g := PackedVector2Array([
		centre + Vector2(-largeur, -hauteur * 0.75),
		centre + Vector2(-14.0, -hauteur * 0.55),
		centre + Vector2(-14.0, hauteur * 0.75),
		centre + Vector2(-largeur, hauteur * 0.55)])
	var page_d := PackedVector2Array([
		centre + Vector2(largeur, -hauteur * 0.75),
		centre + Vector2(14.0, -hauteur * 0.55),
		centre + Vector2(14.0, hauteur * 0.75),
		centre + Vector2(largeur, hauteur * 0.55)])
	for page in [page_g, page_d]:
		draw_colored_polygon(page, Palette.PARCHEMIN_SOMBRE)
		Dessin.contour(self, page, Palette.BORD_PAGE, 3.0)
	draw_rect(Rect2(centre.x - 16.0, centre.y - hauteur * 0.62, 32.0, hauteur * 1.32), Color(0.14, 0.11, 0.19))

	# Lignes d'ecriture suggerees, et une goutte qui tombe sur la page droite.
	for cote: float in [-1.0, 1.0]:
		for i in 7:
			var t := float(i) / 6.0
			var y := centre.y + lerpf(-hauteur * 0.42, hauteur * 0.5, t)
			var x1 := centre.x + cote * 40.0
			var x2 := centre.x + cote * (largeur - 50.0)
			draw_line(Vector2(x1, y), Vector2(x2, y), Color(Palette.PARCHEMIN_VEINE, 0.55), 3.0)
	var chute := fmod(_anim * 0.5, 1.0)
	var goutte := centre + Vector2(largeur * 0.45, lerpf(-hauteur, hauteur * 0.3, chute))
	draw_colored_polygon(Dessin.goutte(goutte, 12.0, PI / 2.0, 1.4), Color(Palette.ESSENCE, 1.0 - chute * 0.3))
	Dessin.halo(self, goutte, 40.0, Color(Palette.ESSENCE, 0.6), 3)

	var titre_y := taille.y * 0.56
	draw_string(police, Vector2(0, titre_y), "ALAMBIC", HORIZONTAL_ALIGNMENT_CENTER, taille.x, 96, Palette.TEXTE)
	draw_string(police, Vector2(0, titre_y + 54.0), "descente dans un grimoire vivant",
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 30, Palette.TEXTE_ATTENUE)
	var filet := PackedVector2Array()
	for i in 61:
		var t := float(i) / 60.0
		filet.append(Vector2(lerpf(140.0, taille.x - 140.0, t), titre_y + 86.0 + sin(t * 6.0 + _anim) * 4.0))
	draw_polyline(filet, Color(Palette.OR, 0.4), 2.0, true)

	if ReglagesJoueur.meilleure_salle > 0:
		draw_string(police, Vector2(0, titre_y + 148.0),
			"Meilleure descente : page %d / %d" % [ReglagesJoueur.meilleure_salle, Reglages.SALLES_PAR_RUN],
			HORIZONTAL_ALIGNMENT_CENTER, taille.x, 30, Color(Palette.OR, 0.85))

	# Trois lignes de regles : sur telephone, personne ne lit un didacticiel,
	# mais tout le monde lit trois lignes avant d'appuyer.
	var regles := [
		"Le pouce se pose n'importe où en bas de l'écran.",
		"On tire tout seul, dès qu'on s'arrête.",
		"Pages 5 et 9 : deux réactifs fusionnent en une essence.",
	]
	for i in regles.size():
		draw_string(police, Vector2(0, titre_y + 212.0 + float(i) * 42.0), regles[i],
			HORIZONTAL_ALIGNMENT_CENTER, taille.x, 26, Color(Palette.TEXTE_ATTENUE, 0.95))
