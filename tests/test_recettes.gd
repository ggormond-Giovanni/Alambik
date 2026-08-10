extends RefCounted

func test_paire_non_ordonnee(v: Verif) -> void:
	v.egal(Recettes.essence_pour("braise", "ricochet"), Recettes.essence_pour("ricochet", "braise"),
		"l'ordre des deux reactifs ne compte pas")

func test_onze_recettes_majeures(v: Verif) -> void:
	v.egal(Recettes.TABLE.size(), 11, "onze fusions ont une identité entièrement dédiée")

func test_paire_sans_recette_majeure_donne_un_amalgame(v: Verif) -> void:
	var id := Recettes.essence_pour("fiole_de_vie", "perforation")
	v.vrai(id.begins_with(Recettes.PREFIXE_AMALGAME), "la paire produit un amalgame")
	var amalgame := CatalogueEssences.par_id(id)
	v.vrai(amalgame != null and amalgame.est_essence, "l'amalgame est une essence utilisable")
	v.vrai("fiole_de_vie" in amalgame.mods["drapeaux"], "il conserve le bonus de vie")
	v.vrai(int(amalgame.mods["perforations_add"]) == 1, "il conserve la perforation")
	var signatures := (amalgame.mods.get("drapeaux", []) as Array).filter(
		func(drapeau: String) -> bool: return drapeau.begins_with("fusion_"))
	v.egal(signatures.size(), 1, "meme un amalgame generique change la mecanique du tir")

func test_perforation_ricochet_devient_un_paradoxe(v: Verif) -> void:
	var id := Recettes.essence_pour("perforation", "ricochet")
	v.egal(id, "paradoxe_balistique", "la paire a sa propre essence")
	var essence := CatalogueEssences.par_id(id)
	v.vrai("perfore_tout" in essence.mods["drapeaux"], "elle traverse tous les ennemis")
	v.vrai("rebond_murs_infini" in essence.mods["drapeaux"], "elle rebondit sans stock de charges")

func test_toutes_les_paires_de_base_existent(v: Verif) -> void:
	var ids := CatalogueReactifs.ids()
	var nombre := 0
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			nombre += 1
			v.vrai(Recettes.essence_pour(ids[i], ids[j]) != "", "%s et %s se combinent" % [ids[i], ids[j]])
	v.egal(nombre, 105, "quinze augments forment 105 paires")

func test_composants_existants(v: Verif) -> void:
	for cle in Recettes.TABLE:
		for id in cle.split("+"):
			v.vrai(CatalogueReactifs.TOUS.has(id), "le composant %s doit etre un reactif du catalogue" % id)

func test_essences_existantes(v: Verif) -> void:
	for cle in Recettes.TABLE:
		v.vrai(CatalogueEssences.TOUS.has(Recettes.TABLE[cle]), "l'essence %s doit exister" % Recettes.TABLE[cle])

func test_aucune_essence_n_est_composant(v: Verif) -> void:
	# Regle de la spec : une essence ne se refusionne pas.
	for cle in Recettes.TABLE:
		for id in cle.split("+"):
			v.vrai(not CatalogueEssences.TOUS.has(id), "%s est une essence, elle ne peut pas etre un composant" % id)

func test_cles_normalisees(v: Verif) -> void:
	for cle in Recettes.TABLE:
		var morceaux: PackedStringArray = (cle as String).split("+")
		v.vrai(morceaux[0] < morceaux[1], "la cle %s doit etre triee, sinon deux ecritures coexistent" % cle)

func test_pas_deux_fois_la_meme_paire(v: Verif) -> void:
	var vues: Array[String] = []
	for cle in Recettes.TABLE:
		var morceaux: PackedStringArray = (cle as String).split("+")
		var normale := Recettes.cle(morceaux[0], morceaux[1])
		v.vrai(not normale in vues, "la paire %s apparait deux fois" % normale)
		vues.append(normale)

func test_essences_marquees(v: Verif) -> void:
	for id in CatalogueEssences.TOUS:
		v.vrai(CatalogueEssences.par_id(id).est_essence, "%s doit etre marquee comme essence" % id)

func test_chaque_essence_est_atteignable(v: Verif) -> void:
	var atteintes: Array = Recettes.TABLE.values()
	for id in CatalogueEssences.TOUS:
		v.vrai(id in atteintes, "l'essence %s doit avoir au moins une recette" % id)

func test_composants_retrouves(v: Verif) -> void:
	for cle in Recettes.TABLE:
		var essence: String = Recettes.TABLE[cle]
		var composants := Recettes.composants_de(essence)
		v.egal(Recettes.cle(composants[0], composants[1]), cle, "on retrouve la paire depuis l'essence")
