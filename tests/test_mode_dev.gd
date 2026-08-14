extends RefCounted

func test_reset_rembourse_exactement_les_rangs(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.gouttes = 0
	r.rangs_competences = {"constitution": 1, "force": 1}
	var attendu := ArbreCompetences.cout("constitution") + ArbreCompetences.cout("force")
	v.egal(r.reinitialiser_arbre(), attendu, "le reset calcule tous les points depenses")
	v.egal(r.gouttes, attendu, "les gouttes sont rendues")
	v.vrai(r.rangs_competences.is_empty(), "tous les noeuds sont remis a zero")
	r.free()

func test_mode_dev_donne_acces_sans_modifier_le_build(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.mode_dev = true
	r.rangs_competences = {}
	v.vrai(r.chapitre_debloque(2), "le mode dev ouvre tous les chapitres")
	v.egal(r.rang_competence("force"), ArbreCompetences.rangs("force"),
		"le mode dev ouvre toutes les Maitrises a leur rang maximal")
	v.egal(r.niveau_compte_effectif(), 1, "le mode dev ne change pas le niveau global")
	v.egal(r.gouttes_affichees(), "∞", "les gouttes sont infinies")
	v.vrai(r.rangs_competences.is_empty(), "les vrais rangs sauvegardes ne sont pas ecrases")
	v.egal(r.sort_actif_effectif(), "", "aucun sort n'est equipe implicitement")
	v.egal(r.ultime_effectif(), "", "aucun ultime n'est equipe implicitement")
	v.vrai(r.sort_debloque("onde_alchimique"), "tous les Sorts sont disponibles")
	v.egal(r.objets_disponibles().size(), CatalogueObjets.OBJETS.size(),
		"tous les equipements sont disponibles")
	r.free()

func test_quitter_le_mode_dev_ne_conserve_pas_un_objet_de_test(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.objets.clear()
	r.mode_dev = true
	var id := CatalogueObjets.objet_du_chapitre(0)
	v.vrai(r.equiper_objet("anneau_gauche", id), "un objet dev peut etre equipe")
	v.egal(r.equipements["anneau_gauche"], id, "l'objet sert pendant le test")
	r.definir_mode_dev(false)
	v.egal(r.equipements["anneau_gauche"], "", "l'objet non obtenu disparait en quittant le mode dev")
	v.vrai(r.objets.is_empty(), "le vrai inventaire reste intact")
	r.free()

func test_reset_efface_la_progression_et_garde_les_options(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.victoires = 4
	r.runs = 9
	r.meilleures_par_chapitre = {"0": 20}
	r.chapitre_choisi = 3
	r.gouttes = 700
	r.rangs_competences = {"force": 1}
	r.niveau_compte = 8
	r.experience_compte = 50
	r.rangs_sorts = {"onde_alchimique": 2}
	r.objets.clear()
	r.objets.append(CatalogueObjets.objet_du_chapitre(0))
	r.pierres_forge = 30
	r.volume_musique = 0.35
	r.piste_musique = "dynamic_arcade"
	r.secousses_ecran = false
	r.mode_dev = true
	r.reinitialiser_progression()
	v.egal(r.runs, 0, "les tentatives sont effacees")
	v.vrai(r.meilleures_par_chapitre.is_empty(), "la campagne repart du debut")
	v.egal(r.niveau_compte, 1, "le compte repart au niveau un")
	v.egal(r.gouttes, 0, "les Gouttes sont effacees")
	v.vrai(r.rangs_competences.is_empty(), "les Maitrises sont effacees")
	v.vrai(r.rangs_sorts.is_empty(), "l'Arsenal est efface")
	v.vrai(r.objets.is_empty(), "l'equipement obtenu est efface")
	v.egal(r.pierres_forge, 0, "les Pierres sont effacees")
	v.presque(r.volume_musique, 0.35, "le volume reste un reglage")
	v.egal(r.piste_musique, "dynamic_arcade", "la piste musicale reste un reglage")
	v.vrai(not r.secousses_ecran, "l'accessibilite est conservee")
	v.vrai(r.mode_dev, "le Mode dev reste un reglage distinct de la progression")
	r.free()
