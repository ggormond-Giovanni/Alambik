extends Control

signal termine

const REGLAGES := preload("res://ui/reglages.tscn")

var _titre_detail: Label
var _description_detail: Label
var _stats_detail: Label
var _boutons_reactifs: Dictionary = {}
var _selection := ""
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	StyleInterface.animer_entree(self, 14.0)
	Capture.programmer(self)

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 72)
	marge.add_theme_constant_override("margin_right", 72)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 300)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 64)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 16)
	marge.add_child(colonne)

	var inventaire_titre := Label.new()
	inventaire_titre.text = "DEV — touchez pour ajouter un augment à tester" if ReglagesJoueur.mode_dev else "VOS AUGMENTS — touchez pour voir les bonus"
	inventaire_titre.add_theme_font_size_override("font_size", 24)
	inventaire_titre.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	colonne.add_child(inventaire_titre)

	var defilement := ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.custom_minimum_size = Vector2(0, 260)
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(defilement)
	var grille := GridContainer.new()
	grille.columns = 3
	grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 12)
	defilement.add_child(grille)
	if ReglagesJoueur.mode_dev:
		var ids: Array[String] = CatalogueReactifs.ids()
		for id in ids:
			_ajouter_bouton_reactif(grille, id, Jeu.copies(id))
	elif Jeu.inventaire.is_empty():
		var vide := Label.new()
		vide.text = "Aucun augment pour le moment."
		vide.add_theme_font_size_override("font_size", 28)
		vide.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
		grille.add_child(vide)
	else:
		for entree in Jeu.inventaire_groupe():
			_ajouter_bouton_reactif(grille, entree[0], int(entree[1]))

	var details := PanelContainer.new()
	details.custom_minimum_size = Vector2(0, 280)
	details.add_theme_stylebox_override("panel", StyleInterface.panneau(Color(0.055, 0.045, 0.085, 0.98), Color(Palette.ESSENCE, 0.38), 24, 8))
	colonne.add_child(details)
	var textes := VBoxContainer.new()
	textes.add_theme_constant_override("separation", 8)
	details.add_child(textes)
	_titre_detail = Label.new()
	_titre_detail.text = "Choisissez un augment"
	_titre_detail.add_theme_font_size_override("font_size", 32)
	_titre_detail.add_theme_color_override("font_color", Palette.TEXTE)
	textes.add_child(_titre_detail)
	_description_detail = Label.new()
	_description_detail.text = "Ses effets chiffrés apparaîtront ici."
	_description_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_detail.add_theme_font_size_override("font_size", 23)
	_description_detail.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	textes.add_child(_description_detail)
	_stats_detail = Label.new()
	_stats_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_detail.add_theme_font_size_override("font_size", 23)
	_stats_detail.add_theme_color_override("font_color", Palette.ESSENCE)
	textes.add_child(_stats_detail)

	var bouton_reglages := Button.new()
	bouton_reglages.text = "RÉGLAGES"
	bouton_reglages.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	bouton_reglages.add_theme_font_size_override("font_size", 29)
	StyleInterface.styliser_bouton(bouton_reglages, Palette.OR, true)
	bouton_reglages.pressed.connect(_ouvrir_reglages)
	colonne.add_child(bouton_reglages)

	var continuer := Button.new()
	continuer.text = "Continuer"
	continuer.custom_minimum_size = Vector2(0, 116)
	continuer.add_theme_font_size_override("font_size", 34)
	StyleInterface.styliser_bouton(continuer, Palette.ESSENCE)
	continuer.pressed.connect(func() -> void:
		StyleInterface.sortir_puis(self, func() -> void: termine.emit()))
	colonne.add_child(continuer)
	var quitter := Button.new()
	quitter.text = "Refermer le grimoire"
	quitter.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	quitter.add_theme_font_size_override("font_size", 29)
	StyleInterface.styliser_bouton(quitter, Palette.TEXTE_ATTENUE, true)
	quitter.pressed.connect(func() -> void:
		StyleInterface.sortir_puis(self, func() -> void:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/menu.tscn")))
	colonne.add_child(quitter)

func _ouvrir_reglages() -> void:
	Sons.jouer("choix", -12.0)
	var panneau := REGLAGES.instantiate()
	panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(panneau)
	panneau.ferme.connect(func() -> void: panneau.queue_free())

func _ajouter_bouton_reactif(grille: GridContainer, id: String, copies: int) -> void:
	var reactif := Jeu.reactif(id)
	if reactif == null:
		return
	var bouton := Button.new()
	bouton.text = "%s%s\n%s" % ["✦ " if reactif.est_transformation else "", reactif.nom, "x%d" % copies if copies > 1 else "Détails"]
	bouton.toggle_mode = true
	bouton.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bouton.add_theme_font_size_override("font_size", 21)
	StyleInterface.styliser_bouton(bouton, Palette.ESSENCE if reactif.est_transformation else reactif.teinte, true)
	bouton.pressed.connect(func() -> void: _afficher_details(id, copies))
	grille.add_child(bouton)
	_boutons_reactifs[id] = bouton

func _afficher_details(id: String, copies: int) -> void:
	var reactif := Jeu.reactif(id)
	if reactif == null:
		return
	if ReglagesJoueur.mode_dev:
		Jeu.ajouter_reactif(id)
		copies = Jeu.copies(id)
		var heros := get_tree().get_first_node_in_group("heros")
		if heros != null:
			heros.recalculer()
		var bouton_ajoute: Button = _boutons_reactifs.get(id)
		if bouton_ajoute != null:
			bouton_ajoute.text = "%s%s\nTEST x%d (+1)" % ["✦ " if reactif.est_transformation else "", reactif.nom, copies]
	_selection = id
	for bouton_id in _boutons_reactifs:
		(_boutons_reactifs[bouton_id] as Button).button_pressed = bouton_id == id
	_titre_detail.text = "%s%s" % [reactif.nom, "  ×%d" % copies if copies > 1 else ""]
	_titre_detail.add_theme_color_override("font_color", Palette.ESSENCE if reactif.est_transformation else reactif.teinte)
	_description_detail.text = reactif.description
	var lignes := DetailsReactif.lignes(reactif, copies)
	_stats_detail.text = "BONUS TOTAL\n• " + "\n• ".join(lignes) if not lignes.is_empty() else "Aucun bonus chiffré."
	StyleInterface.animer_rafraichissement(_titre_detail)
	StyleInterface.animer_rafraichissement(_description_detail)
	StyleInterface.animer_rafraichissement(_stats_detail)
	Sons.jouer("choix", -18.0)

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	StyleInterface.dessiner_fond(self, size, Palette.ESSENCE, _anim, 0.96)
	var police := ThemeDB.fallback_font
	var centre := Vector2(size.x * 0.5, Ecran.marge_haute() + 170.0)
	Dessin.halo(self, centre, 260.0, Color(Palette.ESSENCE, 0.22), 7)
	draw_string(police, Vector2(0, centre.y - 34.0), "PAUSE", HORIZONTAL_ALIGNMENT_CENTER, size.x, 66, Palette.TEXTE)
	draw_string(police, Vector2(0, centre.y + 30.0), "%s — salle %d / %d" % [Jeu.nom_run(), Jeu.salle_courante, Jeu.salles_du_chapitre()],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Palette.TEXTE_ATTENUE)
