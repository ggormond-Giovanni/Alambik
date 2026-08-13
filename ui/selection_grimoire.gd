extends Control

signal ferme

const TRANSITION := preload("res://ui/transition_grimoire.tscn")

var _lancement := false
var _choix_modes: VBoxContainer
var _catalogue: ScrollContainer
var _aide: Label
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	StyleInterface.animer_entree(self, 12.0)
	call_deferred("_animer_choix")
	Capture.programmer(self)

func _animer_choix() -> void:
	if is_instance_valid(_choix_modes):
		StyleInterface.animer_liste(_choix_modes, 0.045)

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 38)
	marge.add_theme_constant_override("margin_right", 38)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 190)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 32)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)
	_aide = Label.new()
	_aide.text = "Choisissez votre manière d'entrer dans l'Alambic"
	_aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aide.add_theme_font_size_override("font_size", 23)
	_aide.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	colonne.add_child(_aide)
	_choix_modes = VBoxContainer.new()
	_choix_modes.alignment = BoxContainer.ALIGNMENT_CENTER
	_choix_modes.add_theme_constant_override("separation", 18)
	_choix_modes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(_choix_modes)
	var grimoires := Button.new()
	grimoires.text = "PARCOURIR LA CAMPAGNE\n10 mondes • 3 chapitres • 20 salles"
	grimoires.custom_minimum_size = Vector2(0, 170)
	grimoires.add_theme_font_size_override("font_size", 29)
	StyleInterface.styliser_bouton(grimoires, Palette.OR)
	grimoires.pressed.connect(_ouvrir_grimoires)
	_choix_modes.add_child(grimoires)
	var mine := Button.new()
	mine.text = "MINE\nSurvie 5 min • XP • Boss • Pierres de forge"
	mine.custom_minimum_size = Vector2(0, 150)
	mine.add_theme_font_size_override("font_size", 28)
	StyleInterface.styliser_bouton(mine, Palette.MOUSSE_MAGIQUE)
	mine.pressed.connect(_lancer_mine)
	_choix_modes.add_child(mine)
	var epreuve := Button.new()
	epreuve.text = "ÉPREUVES RITUELLES\n5 miniboss • Sorts, Passifs et Ultimes"
	epreuve.custom_minimum_size = Vector2(0, 170)
	epreuve.add_theme_font_size_override("font_size", 29)
	StyleInterface.styliser_bouton(epreuve, Palette.ESSENCE)
	epreuve.pressed.connect(_lancer_epreuve_sorts)
	_choix_modes.add_child(epreuve)
	_catalogue = ScrollContainer.new()
	_catalogue.visible = false
	_catalogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_catalogue.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(_catalogue)
	var grille := GridContainer.new()
	grille.columns = 2
	grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 12)
	_catalogue.add_child(grille)
	for index in Chapitres.nombre():
		var livre := Chapitres.par_index(index)
		var ouvert := ReglagesJoueur.chapitre_debloque(index)
		var page := ReglagesJoueur.meilleure_du_chapitre(index)
		var bouton := Button.new()
		bouton.custom_minimum_size = Vector2(0, 178)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bouton.add_theme_font_size_override("font_size", 21)
		bouton.text = "%s\n%s\n%s" % [livre["nom"], "salle %d / 20" % page if ouvert else "VERROUILLÉ", livre["sous_titre"]]
		StyleInterface.styliser_bouton(bouton, livre["teinte"], not ouvert)
		bouton.disabled = not ouvert
		bouton.pressed.connect(func() -> void: _lancer_grimoire(index, livre))
		grille.add_child(bouton)
	var retour := Button.new()
	retour.text = "RETOUR"
	retour.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	retour.add_theme_font_size_override("font_size", 28)
	StyleInterface.styliser_bouton(retour, Palette.TEXTE_ATTENUE, true)
	retour.pressed.connect(_sur_retour)
	colonne.add_child(retour)

func _ouvrir_grimoires() -> void:
	_aide.text = "20 salles • 6 Augments • Alambics avant 5/10/15"
	StyleInterface.basculer_contenu(_choix_modes, _catalogue, 1.0)
	StyleInterface.animer_rafraichissement(_aide)

func _sur_retour() -> void:
	if _catalogue.visible:
		_aide.text = "Choisissez votre manière d'entrer dans l'Alambic"
		StyleInterface.basculer_contenu(_catalogue, _choix_modes, -1.0)
		StyleInterface.animer_rafraichissement(_aide)
	else:
		StyleInterface.sortir_puis(self, func() -> void: ferme.emit())

func _lancer_grimoire(index: int, livre: Dictionary) -> void:
	if _lancement:
		return
	_lancement = true
	ReglagesJoueur.choisir_mode_run("grimoire")
	ReglagesJoueur.choisir_chapitre(index)
	Sons.jouer("choix", -10.0)
	Sons.demarrer_musique_combat()
	var transition := TRANSITION.instantiate()
	transition.configurer(livre)
	add_child(transition)
	transition.terminee.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/run.tscn"))

func _lancer_epreuve_sorts() -> void:
	if _lancement:
		return
	_lancement = true
	ReglagesJoueur.choisir_mode_run("epreuve_sorts")
	Sons.jouer("choix", -10.0)
	Sons.demarrer_musique_combat()
	var transition := TRANSITION.instantiate()
	transition.configurer({"nom": "Défi alchimique"})
	add_child(transition)
	transition.terminee.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/run.tscn"))

func _lancer_mine() -> void:
	if _lancement:
		return
	_lancement = true
	ReglagesJoueur.choisir_mode_run("mine")
	Sons.jouer("choix", -10.0)
	Sons.demarrer_musique_combat()
	var transition := TRANSITION.instantiate()
	transition.configurer({"nom": "Mine"})
	add_child(transition)
	transition.terminee.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/run.tscn"))

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	StyleInterface.dessiner_fond(self, size, Palette.OR, _anim)
	var haut := Ecran.marge_haute() + 105.0
	StyleInterface.dessiner_entete(self, size, "DESTINATION", "Choisissez votre descente",
		"Campagne, survie ou épreuves rituelles", Palette.OR, haut)
