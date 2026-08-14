extends RefCounted

func test_six_elements_hors_du_pool(v: Verif) -> void:
	v.egal(CatalogueElements.ids().size(), 6, "l'Alambic genere les six Elements decides")
	for id in CatalogueElements.ids():
		v.vrai(id not in CatalogueReactifs.ids(), "%s n'est pas un Amélioration de draft" % id)

func test_fusion_conserve_l_augment(v: Verif) -> void:
	Jeu.demarrer_run(7)
	Jeu.ajouter_reactif("tir_multiple")
	v.vrai(Jeu.ajouter_fusion_elementaire("feu", "tir_multiple"), "la fusion est creee")
	v.vrai("tir_multiple" in Jeu.inventaire, "l'Amélioration original n'est pas consomme")
	v.vrai(CatalogueElements.id_fusion("feu", "tir_multiple") in Jeu.inventaire,
		"la transformation est ajoutee separement")
	v.vrai(Jeu.augment_deja_fusionne("tir_multiple"),
		"l'Amélioration est marque comme deja combine")
	v.vrai(not Jeu.ajouter_fusion_elementaire("eau", "tir_multiple"),
		"un Amélioration combine ne peut pas recevoir un second Element")
	v.vrai(CatalogueElements.id_fusion("eau", "tir_multiple") not in Jeu.inventaire,
		"la seconde Fusion refusee n'entre pas dans l'inventaire")

func test_les_alambics_tirent_des_elements_differents(v: Verif) -> void:
	Jeu.demarrer_run(91)
	var tires: Array[String] = []
	for palier in 3:
		var element := Jeu.tirer_element_alambic()
		v.vrai(element in CatalogueElements.ids(), "l'Alambic tire un Element valide")
		v.vrai(element not in tires, "un Element ne revient pas dans la meme run")
		tires.append(element)
	v.egal(Jeu.elements_alambic_tires.size(), 3,
		"les trois Alambics memorisent leurs trois Elements distincts")

func test_fusion_applique_original_et_element(v: Verif) -> void:
	var inventaire: Array[String] = ["tir_multiple", CatalogueElements.id_fusion("feu", "tir_multiple")]
	var tir := Mods.appliquer(Tir.de_base(Stats.depuis_reglages()), Mods.depuis_l_inventaire(inventaire))
	v.egal(tir.nb_projectiles, 2, "Tir multiple reste actif")
	v.vrai("feu" in tir.effets, "le Feu ajoute sa brulure")

func test_toutes_les_combinaisons_sont_valides(v: Verif) -> void:
	for element in CatalogueElements.ids():
		for augment in CatalogueReactifs.ids():
			var fusion := CatalogueElements.creer_fusion(element, augment)
			v.vrai(fusion != null and fusion.est_transformation, "%s transforme %s" % [element, augment])

func test_un_element_depend_de_la_famille(v: Verif) -> void:
	var projectile := CatalogueElements.creer_fusion("feu", "ricochet")
	var heros := CatalogueElements.creer_fusion("feu", "egide")
	var phenomene := CatalogueElements.creer_fusion("feu", "meteores")
	v.vrai("feu" in projectile.mods.get("effets", []), "le projectile applique une brulure")
	v.vrai("transformation_heros_feu" in heros.mods.get("drapeaux", []),
		"l'Amélioration du Heros devient une transformation")
	v.vrai(phenomene.famille == CatalogueReactifs.PHENOMENE \
		and phenomene.mods.get("effets", []).is_empty(),
		"le Phenomene porte l'Element sans devenir un projectile")

func test_une_carte_est_un_vrai_bouton_tactile(v: Verif) -> void:
	var carte := CarteReactif.new()
	v.vrai(carte is Button, "le choix ne depend d'aucun bouton secondaire de souris")
	carte.free()
