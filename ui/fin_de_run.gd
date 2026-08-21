extends Control

# Le bilan est entièrement composé en Controls. Le fond, le contenu et la
# récompense sont indépendants : aucun texte n'est gravé dans une image.
signal termine

var _victoire := false
var _salle := 0
var _anim := 0.0
var _duree := 0.0
var _coffre_gouttes := 0
var _objet_obtenu := ""
var _xp_gagnee := 0
var _coffre: Dictionary = {}
var _salles_vaincues := 0
var _pierres_gagnees := 0
var _interface_construite := false
var _retour_lance := false

const COFFRE_DUREE_ECRAN := 4.8

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	StyleInterface.animer_entree(self)
	Capture.programmer(self)

func afficher(victoire: bool, salle_atteinte: int) -> void:
	_victoire = victoire
	_salle = salle_atteinte
	_duree = Jeu.duree_run()
	_salles_vaincues = salle_atteinte if victoire else maxi(0, salle_atteinte - 1)
	_coffre = Recompenses.coffre_pour(_salles_vaincues)
	if Jeu.mode_run == "grimoire" and int(_coffre["palier"]) > 0:
		_coffre_gouttes = roundi(float(Recompenses.tirer_gouttes_coffre(_coffre, Jeu.chapitre, Jeu.rng)) \
			* ArbreCompetences.multiplicateur_coffre(ReglagesJoueur.rangs_competences_effectifs()) \
			* (Reglages.AVIDITE_GOUTTES_MULT if "avidite" in Jeu.inventaire else 1.0))
		ReglagesJoueur.ajouter_gouttes(_coffre_gouttes)
		var manquants := CatalogueObjets.manquants(Jeu.chapitre, ReglagesJoueur.objets)
		if not manquants.is_empty() and Recompenses.donne_objet(_coffre,
				ReglagesJoueur.grands_coffres_rates(Jeu.chapitre), Jeu.rng):
			_objet_obtenu = CatalogueObjets.tirer_manquant(Jeu.chapitre, ReglagesJoueur.objets, Jeu.rng)
			ReglagesJoueur.ajouter_objet(_objet_obtenu)
		if int(_coffre["palier"]) >= Reglages.SALLES_PAR_RUN:
			ReglagesJoueur.enregistrer_grand_coffre(Jeu.chapitre, not _objet_obtenu.is_empty())
	elif Jeu.mode_run == "mine" and victoire:
		_pierres_gagnees = ReglagesJoueur.ajouter_pierres_forge(ReglagesJoueur.pierres_mine())
	_xp_gagnee = 0 if Jeu.est_retro() else \
		_salle * (2 if Jeu.mode_run == "grimoire" else 1) + (20 if victoire and Jeu.mode_run == "grimoire" else 0)
	if _xp_gagnee > 0:
		ReglagesJoueur.ajouter_experience_compte(_xp_gagnee)
	if Jeu.mode_run == "grimoire":
		ReglagesJoueur.enregistrer_resultat(salle_atteinte, victoire, Jeu.chapitre)
	elif not Jeu.est_retro():
		ReglagesJoueur.enregistrer_resultat_annexe(victoire)
	_construire_bilan()
	_retour_automatique()

func _construire_bilan() -> void:
	if _interface_construite:
		return
	_interface_construite = true
	var teinte := Palette.OR if _victoire else Palette.DANGER
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	InterfaceMobile.appliquer_marges(marge, 0.0, true)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)

	var entete := PanelContainer.new()
	entete.add_theme_stylebox_override("panel", InterfaceMobile.panneau(teinte, true))
	colonne.add_child(entete)
	var titres := VBoxContainer.new()
	entete.add_child(titres)
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 19, teinte, true)
	surtitre.text = "RÉSUMÉ DE LA DESCENTE"
	titres.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 38, Palette.TEXTE, true)
	titre.text = _titre_resultat().to_upper()
	titres.add_child(titre)

	var bilan := PanelContainer.new()
	bilan.add_theme_stylebox_override("panel", InterfaceMobile.panneau_leger(Palette.ESSENCE))
	colonne.add_child(bilan)
	var bilan_colonne := VBoxContainer.new()
	bilan_colonne.add_theme_constant_override("separation", 8)
	bilan.add_child(bilan_colonne)
	_ajouter_ligne(bilan_colonne, Jeu.nom_run().to_upper(), "SALLE %d / %d" % [_salle, Jeu.salles_du_chapitre()], Palette.TEXTE)
	_ajouter_ligne(bilan_colonne, "CRÉATURES EFFACÉES", str(Jeu.ennemis_abattus), Palette.ESSENCE)
	_ajouter_ligne(bilan_colonne, "DURÉE", "%d MIN %02d S" % [int(_duree / 60.0), int(_duree) % 60], Palette.TEXTE)
	_ajouter_ligne(bilan_colonne, "XP DE COMPTE", "—" if Jeu.est_retro() else "+%d" % _xp_gagnee, Palette.OR)
	if Jeu.mode_run == "grimoire":
		_ajouter_ligne(bilan_colonne, "MEILLEURE DESCENTE",
			"SALLE %d" % ReglagesJoueur.meilleure_du_chapitre(Jeu.chapitre), Palette.TEXTE)

	var recompense := PanelContainer.new()
	recompense.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR if _a_un_coffre() else Palette.ESSENCE, true))
	colonne.add_child(recompense)
	var recompense_colonne := VBoxContainer.new()
	recompense_colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	recompense_colonne.add_theme_constant_override("separation", 8)
	recompense.add_child(recompense_colonne)
	var symbole := InterfaceMobile.styliser_label(Label.new(), 56, Palette.OR, true)
	symbole.text = "✦"
	recompense_colonne.add_child(symbole)
	var recompense_titre := InterfaceMobile.styliser_label(Label.new(), 28, Palette.OR, true)
	recompense_titre.text = _texte_recompense_principal()
	recompense_titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recompense_colonne.add_child(recompense_titre)
	var recompense_detail := InterfaceMobile.styliser_label(Label.new(), 21, Palette.TEXTE_ATTENUE, true)
	recompense_detail.text = _texte_recompense_detail()
	recompense_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recompense_detail.custom_minimum_size.y = 48.0
	recompense_colonne.add_child(recompense_detail)

	var inventaire := Jeu.inventaire_groupe()
	if not inventaire.is_empty():
		var build := PanelContainer.new()
		build.add_theme_stylebox_override("panel", InterfaceMobile.panneau_leger(Retro16.VIOLET))
		colonne.add_child(build)
		var build_label := InterfaceMobile.styliser_label(Label.new(), 20, Palette.TEXTE_ATTENUE, true)
		build_label.text = _resume_build(inventaire)
		build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		build_label.custom_minimum_size.y = 70.0
		build.add_child(build_label)

	var retour := Button.new()
	retour.text = "RETOUR AU MENU"
	retour.custom_minimum_size.y = 102.0
	InterfaceMobile.styliser_bouton(retour, teinte, true)
	retour.pressed.connect(_retour_menu)
	colonne.add_child(retour)

func _ajouter_ligne(parent: VBoxContainer, nom: String, valeur: String, couleur: Color) -> void:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	parent.add_child(ligne)
	var gauche := InterfaceMobile.styliser_label(Label.new(), 21, Palette.TEXTE_ATTENUE)
	gauche.text = nom
	gauche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(gauche)
	var droite := InterfaceMobile.styliser_label(Label.new(), 22, couleur)
	droite.text = valeur
	droite.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ligne.add_child(droite)

func _titre_resultat() -> String:
	if not _victoire:
		return "L'encre a gagné"
	match Jeu.mode_run:
		"retro": return "Prototype terminé"
		"epreuve_sorts": return "Épreuves relevées"
		"mine": return "Mine nettoyée"
	return "Grimoire refermé"

func _a_un_coffre() -> bool:
	return Jeu.mode_run == "grimoire" and int(_coffre.get("palier", 0)) > 0

func _texte_recompense_principal() -> String:
	if Jeu.mode_run == "mine" and _victoire:
		return "+%d PIERRES DE FORGE" % _pierres_gagnees
	if _a_un_coffre():
		return "%s  ·  +%d GOUTTES" % [str(_coffre.get("nom", "COFFRE")).to_upper(), _coffre_gouttes]
	if _xp_gagnee > 0:
		return "+%d XP" % _xp_gagnee
	return "DESCENTE ENREGISTRÉE"

func _texte_recompense_detail() -> String:
	if not _objet_obtenu.is_empty() and CatalogueObjets.OBJETS.has(_objet_obtenu):
		return "NOUVEL OBJET : %s" % str(CatalogueObjets.OBJETS[_objet_obtenu]["nom"]).to_upper()
	if _a_un_coffre():
		return "La récompense du coffre a été ajoutée à votre progression."
	return "Vos résultats ont été sauvegardés."

func _resume_build(inventaire: Array) -> String:
	var morceaux: Array[String] = []
	for entree in inventaire:
		var reactif := Jeu.reactif(str(entree[0]))
		if reactif == null:
			continue
		var quantite := int(entree[1])
		morceaux.append("%s%s" % [reactif.nom, " ×%d" % quantite if quantite > 1 else ""])
		if morceaux.size() >= 7:
			break
	return "BUILD DE FIN :  " + "  ·  ".join(morceaux)

func _retour_automatique() -> void:
	var attente := COFFRE_DUREE_ECRAN if _a_un_coffre() else 3.4
	await get_tree().create_timer(attente, true).timeout
	_retour_menu()

func _retour_menu() -> void:
	if _retour_lance:
		return
	_retour_lance = true
	get_tree().paused = false
	if Jeu.mode_auto:
		get_tree().quit()
	else:
		StyleInterface.sortir_puis(self, func() -> void:
			get_tree().change_scene_to_file("res://scenes/menu.tscn"))

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	InterfaceMobile.dessiner_fond(self, size, false,
		Palette.OR if _victoire else Palette.DANGER, _anim)
