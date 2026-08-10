extends RefCounted

func test_valeurs_de_depart(v: Verif) -> void:
	var s := Stats.depuis_reglages()
	v.presque(s.pv, Reglages.HEROS_PV, "le heros commence a ses PV max")
	v.presque(s.pv_max, Reglages.HEROS_PV, "PV max lus dans les reglages")

func test_blesser_retire_des_pv(v: Verif) -> void:
	var s := Stats.depuis_reglages()
	s.blesser(10.0)
	v.presque(s.pv, Reglages.HEROS_PV - 10.0, "la blessure retire des PV")

func test_pv_ne_descendent_pas_sous_zero(v: Verif) -> void:
	var s := Stats.depuis_reglages()
	s.blesser(Reglages.HEROS_PV * 10.0)
	v.presque(s.pv, 0.0, "les PV plafonnent a zero")
	v.vrai(s.est_mort(), "a zero PV le heros est mort")

func test_soigner_ne_depasse_pas_le_max(v: Verif) -> void:
	var s := Stats.depuis_reglages()
	s.blesser(5.0)
	s.soigner(50.0)
	v.presque(s.pv, s.pv_max, "le soin plafonne aux PV max")

func test_le_stuff_est_un_vrai_facteur_de_progression(v: Verif) -> void:
	var bonus := CatalogueObjets.bonus_effectifs(["plume_encres", "robe_enluminee", "sceau_scribe"])
	v.presque(float(bonus["degats"]), 0.12, "l'arme du premier grimoire donne douze pour cent de degats")
	v.presque(float(bonus["pv"]), 32.0, "la robe du premier grimoire donne trente-deux PV")
	v.presque(float(bonus["collecte"]), 0.20, "le talisman accelere le farm des maitrises")
	var s := Stats.depuis_reglages({}, 0.0, 1.0, 1.0, {}, bonus)
	v.presque(s.degats, Reglages.TIR_DEGATS * 1.12, "le bonus d'arme est applique en combat")
	v.presque(s.pv_max, Reglages.HEROS_PV + 32.0, "la robe est appliquee en combat")
