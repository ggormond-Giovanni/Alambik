extends RefCounted

func test_chaque_maitrise_n_a_qu_un_niveau(v: Verif) -> void:
	v.egal(ArbreCompetences.MAX_RANG, 1, "une maitrise est acquise une seule fois")

func test_un_noeud_avance_demande_son_tronc(v: Verif) -> void:
	v.vrai(not ArbreCompetences.prerequis_atteint("cadence", {}), "Cadence commence verrouillee")
	v.vrai(ArbreCompetences.prerequis_atteint("cadence", {"force": 1}),
		"acquerir Force ouvre Cadence")

func test_les_bonus_se_cumulent(v: Verif) -> void:
	v.presque(ArbreCompetences.bonus_pv({"constitution": 1}), 32.0, "Constitution ajoute ses PV renforces")
	v.presque(ArbreCompetences.multiplicateur_degats({"force": 1}), 1.12,
		"Force applique son bonus offensif")
	v.egal(ArbreCompetences.cout("force"), 48, "les maitrises puissantes demandent davantage de farm")

func test_chaque_categorie_est_un_chemin_clair(v: Verif) -> void:
	for branche in ArbreCompetences.BRANCHES:
		var ids: Array = ArbreCompetences.BRANCHES[branche]
		v.vrai(ids.size() >= 3, "%s contient un vrai chemin" % branche)
		for i in range(1, ids.size()):
			v.egal(ArbreCompetences.NOEUDS[ids[i]]["requis"], ids[i - 1],
				"chaque noeud de %s depend du precedent" % branche)

func test_maitrises_et_sorts_sont_separes(v: Verif) -> void:
	v.egal(ArbreCompetences.BRANCHES.size(), 3, "offensif, defensif et passif sont trois chemins separes")
	for branche in ["Offensif", "Défensif", "Passif"]:
		v.egal(ArbreCompetences.BRANCHES[branche].size(), 20, "%s contient vingt maitrises" % branche)
	v.egal(ArbreCompetences.NOEUDS.size(), 60, "l'arbre contient soixante maitrises")
	v.egal(Sorts.PASSIFS.size(), 10, "dix passifs sont des choix de build separes")
	v.egal(Sorts.ACTIFS.size(), 5, "cinq sorts actifs sont proposes")
	v.egal(Sorts.ULTIMES.size(), 3, "trois ultimes sont proposes")
	for catalogue in [Sorts.ACTIFS, Sorts.PASSIFS, Sorts.ULTIMES]:
		for id in catalogue:
			v.vrai(not catalogue[id].has("requis"), "%s n'a aucun sort prerequis" % id)

func test_chaque_maitrise_a_un_effet_reel(v: Verif) -> void:
	var effets := ["degats", "cadence", "projectile", "pv", "reduction", "soin", "soin_page",
		"bouclier", "vitesse", "experience", "collecte", "coffre"]
	for id in ArbreCompetences.NOEUDS:
		var noeud: Dictionary = ArbreCompetences.NOEUDS[id]
		var trouve := false
		for effet in effets:
			trouve = trouve or noeud.has(effet)
		v.vrai(trouve, "%s applique un effet de jeu" % id)

func test_les_nouvelles_maitrises_se_cumulent(v: Verif) -> void:
	v.presque(ArbreCompetences.multiplicateur_degats({"force": 1, "grand_arcane": 1}), 1.36,
		"les bonus offensifs du debut et de fin se cumulent")
	v.presque(ArbreCompetences.bonus_pv({"constitution": 1, "immortel": 1}), 132.0,
		"les bonus defensifs du debut et de fin se cumulent")

func test_les_passifs_changent_les_regles_du_build(v: Verif) -> void:
	v.vrai(Sorts.donne_bouclier({"rempart_initial": 1}), "un passif donne un bouclier au depart")
	v.presque(Sorts.multiplicateur_degats_conditionnel({"audace": 1}, 0.4), 1.30,
		"Audace ne renforce que le heros blesse")
	v.presque(Sorts.multiplicateur_degats_conditionnel({"audace": 1}, 0.8), 1.0,
		"Audace ne donne rien quand le heros va bien")

func test_le_niveau_revele_un_sort_mais_le_defi_l_active(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.sorts_debloques.clear()
	r.rangs_sorts = {"onde_alchimique": 0}
	v.vrai(r.sort_decouvert("onde_alchimique"), "le niveau revele le sort")
	v.vrai(not r.sort_debloque("onde_alchimique"), "au rang zero il reste inutilisable")
	v.vrai(r.debloquer_sort("onde_alchimique"), "le premier loot active le sort")
	v.egal(r.rang_sort("onde_alchimique"), 1, "le premier exemplaire donne le rang un")
	v.presque(r.efficacite_sort("onde_alchimique"), 1.0, "le rang un vaut cent pour cent")
	for i in 4:
		v.vrai(r.debloquer_sort("onde_alchimique"), "un doublon ameliore encore le sort")
	v.egal(r.rang_sort("onde_alchimique"), 5, "le sort plafonne au rang cinq")
	v.presque(r.efficacite_sort("onde_alchimique"), 5.0, "le rang cinq vaut cinq cents pour cent")
	v.vrai(not r.debloquer_sort("onde_alchimique"), "un sixieme exemplaire ne sert pas")
	r.free()

func test_le_niveau_global_renforce_les_stats_de_base(v: Verif) -> void:
	var stats := Stats.depuis_reglages({}, 10.0, 1.20, 1.10)
	v.presque(stats.pv_max, Reglages.HEROS_PV + 10.0, "le niveau global ajoute des PV")
	v.presque(stats.degats, Reglages.TIR_DEGATS * 1.20, "le niveau global ajoute des degats")
	v.presque(stats.vitesse, Reglages.HEROS_VITESSE * 1.10, "le niveau global ajoute de la vitesse")
