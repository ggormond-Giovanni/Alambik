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
	v.egal(r.rang_competence("transmutation_totale"), 0, "le mode dev ne debloque rien automatiquement")
	v.egal(r.niveau_heros_effectif(), 1, "le mode dev ne change pas le niveau global")
	v.egal(r.gouttes_affichees(), "∞", "les gouttes sont infinies")
	v.vrai(r.rangs_competences.is_empty(), "les vrais rangs sauvegardes ne sont pas ecrases")
	v.egal(r.sort_actif_effectif(), "", "aucun sort n'est equipe implicitement")
	v.egal(r.ultime_effectif(), "", "aucun ultime n'est equipe implicitement")
	r.free()
