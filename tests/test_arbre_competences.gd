extends RefCounted

func test_les_noeuds_ont_un_cout_croissant(v: Verif) -> void:
	v.vrai(ArbreCompetences.cout("puissance", 3) > ArbreCompetences.cout("puissance", 0),
		"les rangs suivants coutent davantage")

func test_un_noeud_avance_demande_son_tronc(v: Verif) -> void:
	v.vrai(not ArbreCompetences.prerequis_atteint("cadence", {}), "Cadence commence verrouillee")
	v.vrai(ArbreCompetences.prerequis_atteint("cadence", {"puissance": 5}),
		"terminer Puissance ouvre Cadence")

func test_les_bonus_se_cumulent(v: Verif) -> void:
	v.presque(ArbreCompetences.bonus_pv({"vitalite": 2, "rempart": 1}), 20.0,
		"les deux etages de survie se cumulent")
	v.presque(ArbreCompetences.multiplicateur_degats({"puissance": 2, "surcharge": 1}), 1.11,
		"les deux etages offensifs se cumulent")

func test_chaque_branche_est_une_chaine_de_quatre_noeuds(v: Verif) -> void:
	for branche in ArbreCompetences.BRANCHES:
		var ids: Array = ArbreCompetences.BRANCHES[branche]
		v.egal(ids.size(), 4, "%s contient quatre noeuds" % branche)
		for i in range(1, ids.size()):
			v.egal(ArbreCompetences.NOEUDS[ids[i]]["requis"], ids[i - 1],
				"chaque noeud de %s depend du precedent" % branche)

func test_le_niveau_global_renforce_les_stats_de_base(v: Verif) -> void:
	var stats := Stats.depuis_reglages({}, 10.0, 1.20, 1.10)
	v.presque(stats.pv_max, Reglages.HEROS_PV + 10.0, "le niveau global ajoute des PV")
	v.presque(stats.degats, Reglages.TIR_DEGATS * 1.20, "le niveau global ajoute des degats")
	v.presque(stats.vitesse, Reglages.HEROS_VITESSE * 1.10, "le niveau global ajoute de la vitesse")
