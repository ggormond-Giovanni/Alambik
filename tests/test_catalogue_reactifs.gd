extends RefCounted

func test_pool_d_augments_sans_elements(v: Verif) -> void:
	v.egal(CatalogueReactifs.ids().size(), 16, "le pool actuel compte exactement seize Augments")
	for element_legacy in ["braise", "givre", "foudre", "acide"]:
		v.vrai(element_legacy not in CatalogueReactifs.ids(), "%s ne tombe jamais au draft" % element_legacy)

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

func test_aucun_augment_n_est_une_transformation(v: Verif) -> void:
	for id in CatalogueReactifs.ids():
		v.vrai(not CatalogueReactifs.par_id(id).est_transformation, "%s est un Augment de base" % id)

func test_tir_multiple_ajoute_un_projectile(v: Verif) -> void:
	var r := CatalogueReactifs.par_id("tir_multiple")
	var t := Mods.appliquer(Tir.de_base(Stats.depuis_reglages()), [r.mods])
	v.egal(t.nb_projectiles, 2, "Tir multiple porte le tir a deux projectiles")
	v.vrai(t.ecart_lateral > 0.0, "deux projectiles partent sur deux lignes lisibles")

func test_salve_tire_exactement_deux_fois(v: Verif) -> void:
	v.vrai("rafale" in CatalogueReactifs.par_id("salve").mods["drapeaux"],
		"Salve active le comportement de rafale")
	v.egal(Reglages.RAFALE_NOMBRE, 2, "Salve produit exactement deux tirs")

func test_repartition_exacte_des_familles(v: Verif) -> void:
	v.egal(CatalogueReactifs.ids_de_famille(CatalogueReactifs.PROJECTILE).size(), 6,
		"six Augments modifient les projectiles")
	v.egal(CatalogueReactifs.ids_de_famille(CatalogueReactifs.HEROS).size(), 5,
		"cinq Augments transforment le Heros")
	v.egal(CatalogueReactifs.ids_de_famille(CatalogueReactifs.PHENOMENE).size(), 5,
		"cinq Augments creent des phenomenes")
