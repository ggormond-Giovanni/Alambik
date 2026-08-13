extends RefCounted

# Vingt salles par chapitre : on verifie les proprietes sur chacune.
# on verifie les proprietes qui doivent tenir sur toutes.

func test_chaque_page_de_combat_a_des_vagues(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in range(1, Chapitres.salles(chapitre) + 1):
			var vagues := Vagues.pour_salle(numero, chapitre, 1)
			v.vrai(vagues.size() >= 1, "la page %d du chapitre %d doit avoir une vague" % [numero, chapitre])
			for vague in vagues:
				v.vrai(not vague.is_empty(), "aucune vague vide page %d" % numero)

func test_les_ennemis_cites_existent(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in range(1, Chapitres.salles(chapitre) + 1):
			for vague in Vagues.pour_salle(numero, chapitre, 3):
				for id in vague:
					v.vrai(CatalogueEnnemis.TOUS.has(id),
						"l'ennemi %s de la page %d n'existe pas" % [id, numero])

func test_les_paliers_d_alambic_restent_des_combats(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in Chapitres.par_index(chapitre)["alambics"]:
			v.vrai(not Vagues.pour_salle(numero, chapitre, 1).is_empty(),
				"la page %d est nettoyee avant le soin et la fusion" % numero)

func test_quatre_combats_de_boss_par_chapitre(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in [5, 10, 15, 20]:
			var vagues := Vagues.pour_salle(numero, chapitre, 1)
			v.egal(vagues.size(), 1, "le boss page %d arrive en une vague" % numero)
			v.egal(vagues[0].size(), 1, "le combat contient une cible majeure")
			v.egal(CatalogueEnnemis.par_id(vagues[0][0])["cerveau"], "boss", "la cible utilise un pattern de boss")
			if numero == 20:
				v.egal(vagues[0][0], Chapitres.par_index(chapitre)["boss"], "seule la salle 20 utilise le boss final")
			else:
				v.vrai(vagues[0][0] != Chapitres.par_index(chapitre)["boss"], "la salle %d utilise un miniboss" % numero)
				v.egal(CatalogueEnnemis.par_id(vagues[0][0])["rang_boss"], "miniboss", "un palier ne vole pas un boss signature")

func test_le_premier_miniboss_n_est_plus_un_mur_de_pv(v: Verif) -> void:
	var pv_max := 0.0
	for graine in 40:
		var id: String = Vagues.pour_salle(5, 0, graine + 1)[0][0]
		pv_max = maxf(pv_max, float(CatalogueEnnemis.par_id(id)["pv"])
			* Chapitres.facteur_pv(0, 5))
	v.vrai(pv_max < 1000.0,
		"le premier miniboss reste sous mille PV avant le premier vrai build")

func test_les_miniboss_tournent_dans_un_chapitre(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for graine in 6:
			var rencontres: Array[String] = []
			for salle in [5, 10, 15]:
				rencontres.append(Vagues.pour_salle(salle, chapitre, graine + 1)[0][0])
			v.vrai(rencontres[0] != rencontres[1] and rencontres[1] != rencontres[2],
				"deux paliers consecutifs n'utilisent pas le meme miniboss")
			v.vrai(rencontres[0] in CatalogueEnnemis.TOUS and rencontres[1] in CatalogueEnnemis.TOUS,
				"la rotation ne contient que des miniboss catalogues")

func test_l_epreuve_montre_cinq_miniboss_sans_doublon(v: Verif) -> void:
	var rencontres: Array[String] = []
	for salle in range(1, 6):
		rencontres.append(Vagues.pour_salle(salle, 0, 77, "epreuve_sorts")[0][0])
		if salle > 1:
			v.vrai(rencontres[salle - 1] != rencontres[salle - 2],
				"deux rituels consecutifs ont des patterns differents")
	var uniques := {}
	for id in rencontres:
		uniques[id] = true
	v.egal(uniques.size(), 5, "les cinq rituels montrent cinq miniboss differents")
	for salle in range(6, 11):
		uniques[Vagues.pour_salle(salle, 0, 77, "epreuve_sorts")[0][0]] = true
	v.egal(uniques.size(), 10, "la rotation complete couvre les dix miniboss")

func test_le_prototype_retro_est_un_niveau_complet(v: Verif) -> void:
	var vagues := Vagues.pour_salle(1, 0, 42, "retro")
	v.egal(vagues.size(), 3, "le prototype a une introduction, une vague variee et une finale")
	v.egal(vagues[2], ["la_rature"], "la salle se conclut par une silhouette majeure")
	for vague in vagues:
		for id in vague:
			v.vrai(CatalogueEnnemis.TOUS.has(id), "%s existe dans le catalogue" % id)

func test_difficulte_croissante(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		var debut := _ennemis(1, chapitre)
		var fin := _ennemis(Chapitres.salles(chapitre) - 1, chapitre)
		v.vrai(fin > debut, "le chapitre %d envoie plus d'ennemis a la fin qu'au debut" % chapitre)

func test_le_mid_et_la_fin_ne_repopent_pas_sans_fin(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in [12, 15, 18, 19]:
			var vagues := Vagues.pour_salle(numero, chapitre, 9)
			v.vrai(vagues.size() <= 2, "la page %d reste limitee a deux vagues" % numero)
			v.vrai(_ennemis(numero, chapitre) <= 11, "la page %d garde une densite mobile lisible" % numero)

func test_les_creatures_grossissent(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		var derniere := Chapitres.salles(chapitre)
		v.vrai(Chapitres.facteur_pv(chapitre, derniere) > Chapitres.facteur_pv(chapitre, 1),
			"une creature de la fin du chapitre %d a plus de PV" % chapitre)
	v.vrai(Chapitres.facteur_pv(1, 1) > Chapitres.facteur_pv(0, 1),
		"le second chapitre commence plus dur que le premier")

func test_tirage_reproductible(v: Verif) -> void:
	# La sonde doit pouvoir rejouer un blocage : meme graine, meme page.
	v.egal(Vagues.pour_salle(7, 0, 42), Vagues.pour_salle(7, 0, 42), "meme graine, meme vague")
	v.vrai(str(Vagues.pour_salle(7, 0, 42)) != str(Vagues.pour_salle(7, 0, 43)),
		"une autre graine donne une autre page")

func test_chaque_ennemi_a_les_champs_requis(v: Verif) -> void:
	for id in CatalogueEnnemis.TOUS:
		var e: Dictionary = CatalogueEnnemis.TOUS[id]
		for champ in ["pv", "vitesse", "degats", "portee", "cerveau", "couleur", "rayon"]:
			v.vrai(e.has(champ), "l'ennemi %s doit definir %s" % [id, champ])
		v.vrai(e["pv"] > 0.0, "l'ennemi %s doit avoir des PV positifs" % id)

func test_onze_creatures_communes_et_toutes_jouees(v: Verif) -> void:
	var communs := {}
	for id in CatalogueEnnemis.TOUS:
		if not CatalogueEnnemis.TOUS[id].has("rang_boss"):
			communs[id] = true
	v.egal(communs.size(), 11, "onze silhouettes communes composent les salles")
	var presentes := {}
	for rencontre in Vagues.RENCONTRES:
		for vague in rencontre:
			for id in vague:
				presentes[id] = true
	for id in communs:
		v.vrai(presentes.has(id), "%s apparait dans au moins une rencontre" % id)

func test_l_entree_en_campagne_evite_les_sacs_a_pv(v: Verif) -> void:
	var pire_miniboss := 0.0
	for id in CatalogueEnnemis.ids_miniboss():
		pire_miniboss = maxf(pire_miniboss, float(CatalogueEnnemis.par_id(id)["pv"]))
	v.vrai(pire_miniboss * Chapitres.facteur_pv(0, 5) < 550.0,
		"le premier palier tient dans un combat bref sans build avance")
	var premier_boss := CatalogueEnnemis.par_id(Chapitres.par_index(2)["boss"])
	v.vrai(float(premier_boss["pv"]) * Chapitres.facteur_pv(2, 20) < 7000.0,
		"le premier boss signature reste sous la cible de PV du debut")

func test_les_rencontres_sont_des_templates_ecrits(v: Verif) -> void:
	v.egal(Vagues.RENCONTRES.size(), 20, "les vingt salles ont chacune un template")
	for numero in [1, 4, 12, 18, 19]:
		v.vrai(not Vagues.RENCONTRES[numero - 1].is_empty(),
			"le template de la salle %d est explicite" % numero)

func test_les_archétypes_imposent_chacun_une_contrainte(v: Verif) -> void:
	var rampant := CatalogueEnnemis.par_id("encrier_rampant")
	var sentinelle := CatalogueEnnemis.par_id("plume_sentinelle")
	var veloce := CatalogueEnnemis.par_id("tache_veloce")
	var essaimeur := CatalogueEnnemis.par_id("scribe_essaimeur")
	v.vrai(rampant.has("vitesse_projectile"), "le rampant crache des projectiles")
	v.vrai(int(sentinelle.get("projectiles", 0)) >= 3, "la sentinelle tire une salve")
	v.vrai(float(veloce.get("duree_charge", 0.0)) > 0.0, "la veloce charge")
	v.vrai(int(essaimeur.get("projectiles_cercle", 0)) >= 6, "l'essaimeur tire une onde")

func test_les_invocations_pointent_vers_un_ennemi_connu(v: Verif) -> void:
	for id in CatalogueEnnemis.TOUS:
		var e: Dictionary = CatalogueEnnemis.TOUS[id]
		if e.has("invoque"):
			v.vrai(CatalogueEnnemis.TOUS.has(e["invoque"]), "%s invoque un ennemi inconnu" % id)

func _ennemis(numero: int, chapitre: int) -> int:
	var total := 0
	for vague in Vagues.pour_salle(numero, chapitre, 1):
		total += vague.size()
	return total
