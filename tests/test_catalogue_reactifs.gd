extends RefCounted

func test_quinze_reactifs(v: Verif) -> void:
	v.egal(CatalogueReactifs.ids().size(), 15, "la V1 compte quinze reactifs")

func test_chaque_reactif_a_un_effet(v: Verif) -> void:
	for id in CatalogueReactifs.ids():
		var r := CatalogueReactifs.par_id(id)
		v.vrai(not r.mods.is_empty(), "le reactif %s doit modifier quelque chose" % id)
		v.vrai(r.nom != "", "le reactif %s doit avoir un nom affichable" % id)
		v.vrai(r.description != "", "le reactif %s doit avoir une description" % id)

func test_ids_uniques(v: Verif) -> void:
	var vus: Array[String] = []
	for id in CatalogueReactifs.ids():
		v.vrai(not id in vus, "l'id %s ne doit apparaitre qu'une fois" % id)
		vus.append(id)

func test_id_coherent_avec_la_cle(v: Verif) -> void:
	for id in CatalogueReactifs.ids():
		v.egal(CatalogueReactifs.par_id(id).id, id, "la cle du catalogue est l'id du reactif")

func test_aucun_reactif_n_est_une_essence(v: Verif) -> void:
	for id in CatalogueReactifs.ids():
		v.vrai(not CatalogueReactifs.par_id(id).est_essence, "%s est un reactif, pas une essence" % id)

func test_fleche_double_ajoute_un_projectile(v: Verif) -> void:
	var r := CatalogueReactifs.par_id("fleche_double")
	var t := Mods.appliquer(Tir.de_base(Stats.depuis_reglages()), [r.mods])
	v.egal(t.nb_projectiles, 2, "Fleche double porte le tir a deux projectiles")
	v.vrai(t.angle_eventail > 0.0, "deux projectiles s'ecartent")
