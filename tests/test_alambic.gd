extends RefCounted

func test_aucune_paire_dans_un_inventaire_vide(v: Verif) -> void:
	v.egal(AlambicLogique.paires_possibles([]).size(), 0, "rien a fusionner sans reactif")

func test_paire_detectee(v: Verif) -> void:
	var paires := AlambicLogique.paires_possibles(["braise", "ricochet", "perforation"])
	v.egal(paires.size(), 3, "toutes les paires sont fusionnables")
	v.vrai(["braise", "ricochet", "trainee_etincelles"] in paires, "la recette majeure reste disponible")

func test_toute_paire_de_reactifs_est_acceptee(v: Verif) -> void:
	v.vrai(AlambicLogique.peut_fusionner(["braise", "perforation"], "braise", "perforation"),
		"une paire sans recette majeure produit un amalgame")

func test_reactif_absent_refuse(v: Verif) -> void:
	v.egal(AlambicLogique.peut_fusionner(["braise"], "braise", "ricochet"), false,
		"on ne fusionne pas un reactif qu'on ne possede pas")

func test_essence_non_refusionnable(v: Verif) -> void:
	var paires := AlambicLogique.paires_possibles(["trainee_etincelles", "givre", "sillage"])
	for paire in paires:
		v.vrai(not CatalogueEssences.TOUS.has(paire[0]), "une essence n'est jamais un composant")
		v.vrai(not CatalogueEssences.TOUS.has(paire[1]), "une essence n'est jamais un composant")

func test_pas_de_doublon_de_paire(v: Verif) -> void:
	var paires := AlambicLogique.paires_possibles(["braise", "ricochet", "givre", "sillage"])
	var cles: Array[String] = []
	for paire in paires:
		var c := Recettes.cle(paire[0], paire[1])
		v.vrai(not c in cles, "la paire %s ne doit apparaitre qu'une fois" % c)
		cles.append(c)

func test_partenaires_d_un_reactif(v: Verif) -> void:
	var inventaire: Array[String] = ["givre", "sillage", "encre_lourde", "perforation"]
	var partenaires := AlambicLogique.partenaires(inventaire, "givre")
	v.vrai("sillage" in partenaires, "Givre + Sillage donne la Piste de gel")
	v.vrai("encre_lourde" in partenaires, "Givre + Encre lourde donne le Marteau de glace")
	v.vrai("perforation" in partenaires, "Givre peut aussi fusionner avec Perforation")

func test_fiole_de_vie_se_combine_avec_tout(v: Verif) -> void:
	var inventaire := CatalogueReactifs.ids()
	v.egal(AlambicLogique.partenaires(inventaire, "fiole_de_vie").size(), inventaire.size() - 1,
		"Fiole de vie se combine avec chaque autre augment")
