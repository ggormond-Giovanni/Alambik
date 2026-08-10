extends Control

# Ecran de fin. La mort renvoie au menu sans rien conserver, hors meilleur
# resultat local : c'est la regle de la V1, pas un oubli de meta-progression.

signal termine

var _victoire := false
var _salle := 0
var _anim := 0.0
var _duree := 0.0
var _coffre_gouttes := 0
var _objet_obtenu := ""
var _xp_gagnee := 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	StyleInterface.animer_entree(self)

func afficher(victoire: bool, salle_atteinte: int) -> void:
	_victoire = victoire
	_salle = salle_atteinte
	_duree = Jeu.duree_run()
	if victoire and Jeu.mode_run == "grimoire":
		_objet_obtenu = CatalogueObjets.tirer_manquant(Jeu.chapitre, ReglagesJoueur.objets, Jeu.rng)
		if _objet_obtenu.is_empty():
			_coffre_gouttes = roundi(float(Jeu.rng.randi_range(Recompenses.GOUTTES_COFFRE_COMPLET_MIN,
				Recompenses.GOUTTES_COFFRE_COMPLET_MAX)) * ArbreCompetences.multiplicateur_coffre(ReglagesJoueur.rangs_competences_effectifs()))
			ReglagesJoueur.ajouter_gouttes(_coffre_gouttes)
		else:
			ReglagesJoueur.ajouter_objet(_objet_obtenu)
	_xp_gagnee = _salle * (2 if Jeu.mode_run == "grimoire" else 1) + (20 if victoire and Jeu.mode_run == "grimoire" else 0)
	ReglagesJoueur.ajouter_experience_heros(_xp_gagnee)
	ReglagesJoueur.enregistrer_resultat(salle_atteinte, victoire, Jeu.chapitre)

	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 70)
	marge.add_theme_constant_override("margin_right", 70)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 90)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_END
	colonne.add_theme_constant_override("separation", 20)
	marge.add_child(colonne)

	var rejouer := Button.new()
	rejouer.text = "Redescendre"
	rejouer.custom_minimum_size = Vector2(0, 120)
	rejouer.add_theme_font_size_override("font_size", 34)
	StyleInterface.styliser_bouton(rejouer, Palette.OR)
	rejouer.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/run.tscn"))
	colonne.add_child(rejouer)

	var menu := Button.new()
	menu.text = "Refermer le grimoire"
	menu.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	menu.add_theme_font_size_override("font_size", 30)
	StyleInterface.styliser_bouton(menu, Palette.TEXTE_ATTENUE, true)
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	colonne.add_child(menu)

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	var police := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.012, 0.030, 0.96))
	var haut := size.y * 0.22
	var titre := ("Défi relevé" if Jeu.mode_run == "epreuve_sorts" else "Grimoire refermé") if _victoire else "L'encre a gagné"
	var teinte := Palette.OR if _victoire else Palette.DANGER
	Dessin.halo(self, Vector2(size.x / 2.0, haut - 20.0), 220.0, Color(teinte, 0.5), 5)
	draw_string(police, Vector2(0, haut - 58.0), "RÉSUMÉ DE LA DESCENTE", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(teinte, 0.8))
	draw_string(police, Vector2(0, haut), titre, HORIZONTAL_ALIGNMENT_CENTER, size.x, 62, teinte)
	draw_string(police, Vector2(0, haut + 70.0), "%s — page %d / %d" % [Jeu.nom_run(), _salle, Jeu.salles_du_chapitre()],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Palette.TEXTE)
	draw_string(police, Vector2(0, haut + 118.0), "Créatures d'encre effacées : %d" % Jeu.ennemis_abattus,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Palette.TEXTE_ATTENUE)
	draw_string(police, Vector2(0, haut + 158.0), "Durée : %d min %02d s" % [int(_duree / 60.0), int(_duree) % 60],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Palette.TEXTE_ATTENUE)
	draw_string(police, Vector2(0, haut + 194.0), "+%d XP HÉROS" % _xp_gagnee,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 25, Palette.OR)
	draw_string(police, Vector2(0, haut + 230.0), "Meilleure descente ici : page %d" % ReglagesJoueur.meilleure_du_chapitre(Jeu.chapitre),
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color(Palette.OR, 0.8))
	if _victoire and Jeu.mode_run == "grimoire":
		var coffre := Rect2(size.x * 0.5 - 220.0, haut + 270.0, 440.0, 78.0)
		draw_rect(coffre, Color(Palette.OR, 0.12))
		draw_rect(coffre, Color(Palette.OR, 0.75), false, 3.0)
		if _objet_obtenu.is_empty():
			draw_string(police, Vector2(coffre.position.x, coffre.position.y + 51.0),
				"TRIO COMPLET  •  +%d GOUTTES" % _coffre_gouttes, HORIZONTAL_ALIGNMENT_CENTER, coffre.size.x, 27, Palette.ESSENCE)
		else:
			draw_string(police, Vector2(coffre.position.x, coffre.position.y + 51.0),
				"COFFRE DU GRIMOIRE" , HORIZONTAL_ALIGNMENT_CENTER, coffre.size.x, 27, Palette.OR)
			var objet: Dictionary = CatalogueObjets.OBJETS[_objet_obtenu]
			draw_string(police, Vector2(coffre.position.x - 110.0, coffre.position.y + 112.0),
				"%s  •  %s" % [objet["rarete"].to_upper(), objet["nom"]], HORIZONTAL_ALIGNMENT_CENTER,
				coffre.size.x + 220.0, 29, objet["teinte"])
			draw_string(police, Vector2(coffre.position.x - 110.0, coffre.position.y + 148.0),
				"%s  —  ajouté au stuff" % objet["bonus"], HORIZONTAL_ALIGNMENT_CENTER,
				coffre.size.x + 220.0, 22, Palette.TEXTE_ATTENUE)

	# Ce que la run a construit : la seule trace qui compte.
	var groupe := Jeu.inventaire_groupe()
	var x := size.x / 2.0 - float(groupe.size() - 1) * 34.0
	for entree in groupe:
		var id: String = entree[0]
		var r := Jeu.reactif(id)
		if r == null:
			continue
		var centre := Vector2(x, haut + (475.0 if _victoire else 280.0))
		if r.est_essence:
			Dessin.halo(self, centre, 40.0, Palette.ESSENCE, 3)
		draw_circle(centre, 26.0, Color(0.10, 0.09, 0.14))
		draw_arc(centre, 26.0, 0.0, TAU, 22, Color(r.teinte, 0.8), 2.0, true)
		Dessin.glyphe(self, r.glyphe, centre, 14.0, r.teinte)
		if int(entree[1]) > 1:
			draw_string(police, centre + Vector2(14.0, 24.0), "x%d" % int(entree[1]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.TEXTE)
		x += 68.0
