extends RefCounted

func test_pool_d_augments_sans_elements(v: Verif) -> void:
	v.egal(CatalogueReactifs.ids().size(), 30, "le pool actuel compte exactement trente Améliorations")
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
		v.vrai(not CatalogueReactifs.par_id(id).est_transformation, "%s est un Amélioration de base" % id)

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
	v.egal(CatalogueReactifs.ids_de_famille(CatalogueReactifs.PROJECTILE).size(), 10,
		"dix Améliorations modifient les projectiles")
	v.egal(CatalogueReactifs.ids_de_famille(CatalogueReactifs.HEROS).size(), 8,
		"huit Améliorations transforment le Heros")
	v.egal(CatalogueReactifs.ids_de_famille(CatalogueReactifs.PHENOMENE).size(), 7,
		"sept Améliorations creent des phenomenes")
	v.egal(CatalogueReactifs.ids_de_famille(CatalogueReactifs.SCEAU).size(), 5,
		"cinq Sceaux gravent une regle permanente")
	# La famille decide de ce que l'Element produit a la fusion : une famille
	# vide de contenu rendrait une part des Elements sans effet.
	var total := 0
	for famille in [CatalogueReactifs.PROJECTILE, CatalogueReactifs.HEROS,
			CatalogueReactifs.PHENOMENE, CatalogueReactifs.SCEAU]:
		var compte := CatalogueReactifs.ids_de_famille(famille).size()
		v.vrai(compte >= 5, "la famille %s reste assez fournie pour porter les Elements" % famille)
		total += compte
	v.egal(total, CatalogueReactifs.ids().size(), "aucune Amélioration n'est hors famille")

# La famille decide de ce qu'un Element produit a la fusion. Les Sceaux sont le
# quatrieme axe : leur Element controle au lieu de frapper.
func test_les_sceaux_ont_leur_propre_interaction_elementaire(v: Verif) -> void:
	for id in CatalogueReactifs.ids_de_famille(CatalogueReactifs.SCEAU):
		for element in CatalogueElements.ids():
			var fusion := CatalogueElements.creer_fusion(element, id)
			v.vrai(fusion != null, "%s doit fusionner avec %s" % [id, element])
			var drapeaux: Array = fusion.mods.get("drapeaux", [])
			v.vrai("sceau_element_%s" % element in drapeaux,
				"la fusion %s · %s scelle son Element dans la salle" % [id, element])
			v.vrai(fusion.description.length() > 20,
				"la fusion %s · %s explique ce qu'elle change" % [id, element])

# Chaque Amélioration doit pouvoir fusionner avec les six Elements : une fusion
# qui ne produit rien serait un Alambic perdu.
func test_chaque_amelioration_fusionne_avec_les_six_elements(v: Verif) -> void:
	for id in CatalogueReactifs.ids():
		for element in CatalogueElements.ids():
			var fusion := CatalogueElements.creer_fusion(element, id)
			v.vrai(fusion != null, "%s doit pouvoir fusionner avec %s" % [id, element])
			v.vrai(fusion.description != "", "la fusion %s · %s doit s'expliquer" % [id, element])

# Les multiplicateurs s'additionnent d'une carte a l'autre. Une main de six
# Améliorations qui payent toutes en degats produit un tir incapable de tuer :
# la sonde a mesure x0,28 avec le pool complet. Chaque carte qui coute des
# degats doit donc rendre des impacts, et aucune ne doit couter trop seule.
func test_une_amelioration_qui_coute_des_degats_les_rend_en_impacts(v: Verif) -> void:
	for id in CatalogueReactifs.ids():
		var mods: Dictionary = CatalogueReactifs.par_id(id).mods
		if float(mods.get("degats_mult", 1.0)) >= 1.0:
			continue
		var drapeaux: Array = mods.get("drapeaux", [])
		var rend_des_impacts: bool = mods.has("nb_projectiles_add") or mods.has("fragments_add") \
			or mods.has("perforations_add") or mods.has("rebonds_add") \
			or "rafale" in drapeaux or "perfore_tout" in drapeaux
		v.vrai(rend_des_impacts, "%s paie des degats sans multiplier les impacts" % id)
		v.vrai(float(mods["degats_mult"]) >= 0.70,
			"%s ne doit pas couter plus de 30 pour cent de degats a lui seul" % id)

func test_les_nouvelles_ameliorations_ont_un_vrai_arbitrage(v: Verif) -> void:
	# Une Amélioration qui ne fait que gagner n'est pas un choix. Les trois
	# nouvelles Améliorations de projectile echangent explicitement une
	# statistique contre une autre.
	for id in ["frappe_lourde", "cadence_febrile", "trait_transpercant"]:
		var mods: Dictionary = CatalogueReactifs.par_id(id).mods
		var gagne := false
		var perd := false
		for cle in ["degats_mult", "cadence_mult", "vitesse_mult", "portee_mult"]:
			if mods.has(cle):
				gagne = gagne or float(mods[cle]) > 1.0
				perd = perd or float(mods[cle]) < 1.0
		v.vrai(perd, "%s paie son gain par une statistique en baisse" % id)
		v.vrai(gagne or mods.has("drapeaux"), "%s apporte bien quelque chose" % id)
