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
