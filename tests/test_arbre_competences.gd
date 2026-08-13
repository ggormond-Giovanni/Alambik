extends RefCounted

func test_chaque_maitrise_n_a_qu_un_niveau(v: Verif) -> void:
	v.egal(ArbreCompetences.MAX_RANG, 1, "une maitrise est acquise une seule fois")

func test_les_trois_branches_restent_independantes(v: Verif) -> void:
	v.egal(ArbreCompetences.BRANCHES.size(), 3, "offensif, defensif et utilitaire sont separes")
	for branche in ArbreCompetences.BRANCHES:
		var ids: Array = ArbreCompetences.BRANCHES[branche]
		v.vrai(ids.size() >= 2, "%s contient un chemin jouable" % branche)
		for index in range(1, ids.size()):
			v.egal(ArbreCompetences.NOEUDS[ids[index]]["requis"], ids[index - 1],
				"chaque avancee de %s demande le noeud precedent" % branche)

func test_l_arbre_accompagne_les_dix_mondes(v: Verif) -> void:
	v.egal(ArbreCompetences.NOEUDS.size(), 30, "trois branches de dix paliers sont disponibles")
	for branche in ArbreCompetences.BRANCHES:
		v.egal(ArbreCompetences.BRANCHES[branche].size(), 10, "%s accompagne les dix mondes" % branche)
	v.vrai(not ArbreCompetences.prerequis_atteint("cadence", {}), "Cadence commence verrouillee")
	v.vrai(ArbreCompetences.prerequis_atteint("cadence", {"force": 1}), "Force ouvre Cadence")

func test_la_puissance_va_du_petit_bonus_au_gros_scaling(v: Verif) -> void:
	v.presque(ArbreCompetences.multiplicateur_pv({"constitution": 1}), 1.15,
		"Constitution applique son premier bonus")
	v.presque(ArbreCompetences.multiplicateur_degats({"force": 1}), 1.12,
		"Force applique son premier bonus")
	v.vrai(ArbreCompetences.multiplicateur_degats({"force": 1, "puissance": 1,
		"catalyse": 1, "domination": 1, "grand_oeuvre": 1}) >= 5.0,
		"la fin de branche produit un gros scaling visible")
	v.presque(ArbreCompetences.reduction_degats({"armure": 1}), 0.04,
		"Armure applique sa reduction")

func test_maitrises_et_capacites_sont_separees(v: Verif) -> void:
	for catalogue in [Sorts.ACTIFS, Sorts.PASSIFS, Sorts.ULTIMES]:
		for id in catalogue:
			v.vrai(not catalogue[id].has("requis"), "%s n'a aucune Maitrise prerequise" % id)
			v.vrai(not catalogue[id].has("niveau"), "%s ne depend pas du niveau de compte" % id)

func test_les_capacites_changent_les_regles_du_build(v: Verif) -> void:
	v.vrai(Sorts.donne_bouclier({"rempart_initial": 1}), "un Passif donne un bouclier au depart")
	v.presque(Sorts.multiplicateur_degats_conditionnel({"audace": 1}, 0.4), 1.30,
		"Audace ne renforce que le heros blesse")
	v.presque(Sorts.multiplicateur_degats_conditionnel({"audace": 1}, 0.8), 1.0,
		"Audace ne donne rien quand le heros va bien")

func test_l_epreuve_active_un_sort(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.rangs_sorts = {"onde_alchimique": 0}
	v.vrai(r.sort_decouvert("onde_alchimique"), "le sort appartient au pool des Epreuves")
	v.vrai(not r.sort_debloque("onde_alchimique"), "au rang zero il reste inutilisable")
	v.vrai(r.debloquer_sort("onde_alchimique"), "le premier loot active le sort")
	v.egal(r.rang_sort("onde_alchimique"), 1, "le premier exemplaire donne le rang un")
	for i in Reglages.CAPACITE_RANG_MAX - 1:
		v.vrai(r.debloquer_sort("onde_alchimique"), "un doublon ameliore encore le sort")
	v.egal(r.rang_sort("onde_alchimique"), Reglages.CAPACITE_RANG_MAX, "le sort respecte le rang maximal provisoire")
	v.presque(r.efficacite_sort("onde_alchimique"),
		1.0 + float(Reglages.CAPACITE_RANG_MAX - 1) * Reglages.CAPACITE_BONUS_PAR_RANG,
		"les doublons ameliorent la capacite sans multiplier sa puissance par cinq")
	v.vrai(not r.debloquer_sort("onde_alchimique"), "un sixieme exemplaire ne sert pas")
	r.free()

func test_les_deblocages_utilitaires_changent_les_regles(v: Verif) -> void:
	v.egal(ArbreCompetences.nombre_rerolls({"distillation": 1}), 1,
		"la Maitrise donne un nouveau tirage")
	v.vrai(ArbreCompetences.donne_second_passif({"savoir": 1}),
		"la Maitrise ouvre le second slot Passif")
