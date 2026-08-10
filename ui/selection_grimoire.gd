extends Control

signal ferme

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	StyleInterface.animer_entree(self, 12.0)

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
	var aide := Label.new()
	aide.text = "Chaque grimoire contient 50 pages. Terminez le précédent pour ouvrir le suivant."
	aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aide.add_theme_font_size_override("font_size", 23)
	aide.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	colonne.add_child(aide)
	var defilement := ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(defilement)
	var grille := GridContainer.new()
	grille.columns = 2
	grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 12)
	defilement.add_child(grille)
	for index in Chapitres.nombre():
		var livre := Chapitres.par_index(index)
		var ouvert := ReglagesJoueur.chapitre_debloque(index)
		var page := ReglagesJoueur.meilleure_du_chapitre(index)
		var bouton := Button.new()
		bouton.custom_minimum_size = Vector2(0, 178)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bouton.add_theme_font_size_override("font_size", 21)
		bouton.text = "%s\n%s\n%s" % [livre["nom"], "page %d / 50" % page if ouvert else "VERROUILLÉ", livre["sous_titre"]]
		StyleInterface.styliser_bouton(bouton, livre["teinte"], not ouvert)
		bouton.disabled = not ouvert
		bouton.pressed.connect(func() -> void:
			ReglagesJoueur.choisir_chapitre(index)
			Sons.jouer("choix", -10.0)
			get_tree().change_scene_to_file("res://scenes/run.tscn"))
		grille.add_child(bouton)
	var retour := Button.new()
	retour.text = "RETOUR"
	retour.custom_minimum_size = Vector2(0, 96)
	retour.add_theme_font_size_override("font_size", 28)
	StyleInterface.styliser_bouton(retour, Palette.TEXTE_ATTENUE, true)
	retour.pressed.connect(func() -> void: ferme.emit())
	colonne.add_child(retour)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.010, 0.025, 0.99))
	var police := ThemeDB.fallback_font
	var haut := Ecran.marge_haute() + 105.0
	Dessin.halo(self, Vector2(size.x * 0.5, haut), 250.0, Color(Palette.OR, 0.24), 6)
	draw_string(police, Vector2(0, haut), "BIBLIOTHÈQUE DES GRIMOIRES", HORIZONTAL_ALIGNMENT_CENTER, size.x, 42, Palette.TEXTE)
