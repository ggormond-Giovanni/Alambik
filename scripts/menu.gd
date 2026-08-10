extends Control

const CHEMIN_SPRITES_HEROS := "res://assets/characters/sheets/hero_alchemist_sheet.png"
const ARBRE := preload("res://ui/arbre_competences.tscn")
const MENU_SORTS := preload("res://ui/sorts.tscn")
const SELECTION_GRIMOIRE := preload("res://ui/selection_grimoire.tscn")
const REGLAGES := preload("res://ui/reglages.tscn")

# Titre, bouton, meilleur resultat. Aucun sprite : le grimoire est dessine.

var _anim := 0.0
var _particules: Array[Dictionary] = []
var _texture_heros: Texture2D
var _bouton_arbre: Button
var _bouton_dev: Button
var _bouton_grimoire: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sons.musique_menu()
	if ResourceLoader.exists(CHEMIN_SPRITES_HEROS):
		_texture_heros = load(CHEMIN_SPRITES_HEROS)
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
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 90)
	marge.add_theme_constant_override("margin_right", 90)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 70)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_END
	colonne.add_theme_constant_override("separation", 16)
	marge.add_child(colonne)

	var outils := HBoxContainer.new()
	outils.add_theme_constant_override("separation", 10)
	colonne.add_child(outils)
	_bouton_arbre = Button.new()
	_bouton_arbre.custom_minimum_size = Vector2(0, 106)
	_bouton_arbre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bouton_arbre.add_theme_font_size_override("font_size", 30)
	StyleInterface.styliser_bouton(_bouton_arbre, Palette.ESSENCE)
	_bouton_arbre.pressed.connect(_ouvrir_arbre)
	outils.add_child(_bouton_arbre)
	var bouton_sorts := Button.new()
	bouton_sorts.text = "SORTS\n1 • 2 • 1"
	bouton_sorts.custom_minimum_size = Vector2(210, 106)
	bouton_sorts.add_theme_font_size_override("font_size", 23)
	StyleInterface.styliser_bouton(bouton_sorts, Palette.OR)
	bouton_sorts.pressed.connect(_ouvrir_sorts)
	outils.add_child(bouton_sorts)
	_bouton_dev = Button.new()
	_bouton_dev.custom_minimum_size = Vector2(180, 106)
	_bouton_dev.add_theme_font_size_override("font_size", 23)
	_bouton_dev.pressed.connect(_basculer_dev)
	outils.add_child(_bouton_dev)
	var bouton_reglages := Button.new()
	bouton_reglages.text = "RÉGLAGES"
	bouton_reglages.custom_minimum_size = Vector2(190, 106)
	bouton_reglages.add_theme_font_size_override("font_size", 23)
	StyleInterface.styliser_bouton(bouton_reglages, Palette.TEXTE_ATTENUE, true)
	bouton_reglages.pressed.connect(_ouvrir_reglages)
	outils.add_child(bouton_reglages)
	_rafraichir_bouton_arbre()

	_bouton_grimoire = Button.new()
	_bouton_grimoire.text = "CHOISIR UN GRIMOIRE\n10 livres • 50 pages chacun"
	_bouton_grimoire.custom_minimum_size = Vector2(0, 136)
	_bouton_grimoire.add_theme_font_size_override("font_size", 32)
	StyleInterface.styliser_bouton(_bouton_grimoire, Palette.OR)
	_bouton_grimoire.pressed.connect(_ouvrir_bibliotheque)
	colonne.add_child(_bouton_grimoire)

func _rafraichir_bouton_arbre() -> void:
	_bouton_arbre.text = "HÉROS NIVEAU %d\nARBRE ✦ %s" % [ReglagesJoueur.niveau_heros_effectif(), ReglagesJoueur.points_maitrise_affiches()]
	_bouton_dev.text = "DEV\n%s" % ("ON" if ReglagesJoueur.mode_dev else "OFF")
	StyleInterface.styliser_bouton(_bouton_dev, Palette.DANGER if ReglagesJoueur.mode_dev else Palette.TEXTE_ATTENUE, true)

func _basculer_dev() -> void:
	ReglagesJoueur.definir_mode_dev(not ReglagesJoueur.mode_dev)
	Sons.jouer("choix", -12.0)
	get_tree().reload_current_scene()

func _ouvrir_arbre() -> void:
	Sons.jouer("choix", -12.0)
	var arbre := ARBRE.instantiate()
	add_child(arbre)
	arbre.ferme.connect(func() -> void:
		arbre.queue_free()
		_rafraichir_bouton_arbre())

func _ouvrir_sorts() -> void:
	Sons.jouer("choix", -12.0)
	var sorts := MENU_SORTS.instantiate()
	add_child(sorts)
	sorts.ferme.connect(func() -> void: sorts.queue_free())

func _ouvrir_bibliotheque() -> void:
	Sons.jouer("choix", -12.0)
	var bibliotheque := SELECTION_GRIMOIRE.instantiate()
	add_child(bibliotheque)
	bibliotheque.ferme.connect(func() -> void: bibliotheque.queue_free())

func _ouvrir_reglages() -> void:
	Sons.jouer("choix", -12.0)
	var panneau := REGLAGES.instantiate()
	add_child(panneau)
	panneau.ferme.connect(func() -> void: panneau.queue_free())

func _chapitres_ouverts() -> int:
	var total := 0
	for index in Chapitres.nombre():
		if ReglagesJoueur.chapitre_debloque(index):
			total += 1
	return total

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
	# Le personnage est la promesse visuelle du jeu des le premier ecran.
	var taille_heros := 360.0 + sin(_anim * 2.0) * 5.0
	if _texture_heros != null:
		var cellule := Vector2(_texture_heros.get_width() / 4.0, _texture_heros.get_height() / 2.0)
		var source := Rect2(Vector2(0.0, cellule.y), cellule)
		draw_texture_rect_region(_texture_heros,
			Rect2(centre + Vector2(-taille_heros * 0.45, -taille_heros * 0.92), Vector2(taille_heros * 0.9, taille_heros * 1.8)), source)
	var chute := fmod(_anim * 0.5, 1.0)
	var goutte := centre + Vector2(largeur * 0.45, lerpf(-hauteur, hauteur * 0.3, chute))
	draw_colored_polygon(Dessin.goutte(goutte, 12.0, PI / 2.0, 1.4), Color(Palette.ESSENCE, 1.0 - chute * 0.3))
	Dessin.halo(self, goutte, 40.0, Color(Palette.ESSENCE, 0.6), 3)

	var titre_y := taille.y * 0.57
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
			"%d chapitre(s) ouvert(s) sur %d" % [_chapitres_ouverts(), Chapitres.nombre()],
			HORIZONTAL_ALIGNMENT_CENTER, taille.x, 30, Color(Palette.OR, 0.85))

	# Trois lignes de regles : sur telephone, personne ne lit un didacticiel,
	# mais tout le monde lit trois lignes avant d'appuyer.
	var regles := [
		"Le pouce se pose n'importe où en bas de l'écran.",
		"On tire tout seul, dès qu'on s'arrête.",
		"Aux alambics, deux réactifs se perdent pour une essence plus forte.",
	]
	for i in regles.size():
		draw_string(police, Vector2(0, titre_y + 212.0 + float(i) * 42.0), regles[i],
			HORIZONTAL_ALIGNMENT_CENTER, taille.x, 26, Color(Palette.TEXTE_ATTENUE, 0.95))
