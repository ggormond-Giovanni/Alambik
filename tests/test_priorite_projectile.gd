extends RefCounted

func test_le_ricochet_passe_avant_la_perforation(v: Verif) -> void:
	v.egal(PrioriteProjectile.apres_impact(1, 1), "rebond",
		"le premier ennemi redirige un tir qui peut ricocher et perforer")

func test_la_perforation_prend_ensuite_le_relais(v: Verif) -> void:
	v.egal(PrioriteProjectile.apres_impact(0, 1), "perforation",
		"apres le ricochet, le prochain ennemi est traverse")

func test_le_projectile_se_termine_sans_charge(v: Verif) -> void:
	v.egal(PrioriteProjectile.apres_impact(0, 0), "fin",
		"sans ricochet ni perforation le projectile prend fin")
