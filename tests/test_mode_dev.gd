extends RefCounted

func test_reset_rembourse_exactement_les_rangs(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.points_maitrise = 0
	r.rangs_competences = {"vitalite": 2, "puissance": 1}
	var attendu := ArbreCompetences.cout("vitalite", 0) + ArbreCompetences.cout("vitalite", 1) + ArbreCompetences.cout("puissance", 0)
	v.egal(r.reinitialiser_arbre(), attendu, "le reset calcule tous les points depenses")
	v.egal(r.points_maitrise, attendu, "les points sont rendus")
	v.vrai(r.rangs_competences.is_empty(), "tous les noeuds sont remis a zero")
	r.free()

func test_mode_dev_debloque_et_maximise_sans_modifier_la_sauvegarde(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.mode_dev = true
	r.rangs_competences = {}
	v.vrai(r.chapitre_debloque(2), "le mode dev ouvre tous les chapitres")
	v.egal(r.rang_competence("rempart"), ArbreCompetences.MAX_RANG, "tous les noeuds sont au maximum")
	v.egal(r.niveau_heros_effectif(), 100, "le niveau global de dev est maximal")
	v.egal(r.points_maitrise_affiches(), "∞", "les points sont infinis")
	v.vrai(r.rangs_competences.is_empty(), "les vrais rangs sauvegardes ne sont pas ecrases")
	r.free()
