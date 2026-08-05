extends RefCounted

# Cinquante pages par chapitre : on ne peut plus verifier chaque page a la main,
# on verifie les proprietes qui doivent tenir sur toutes.

func test_chaque_page_de_combat_a_des_vagues(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in range(1, Chapitres.salles(chapitre) + 1):
			if Chapitres.est_alambic(chapitre, numero):
				continue
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

func test_les_alambics_n_ont_pas_de_vagues(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in Chapitres.par_index(chapitre)["alambics"]:
			v.vrai(Vagues.pour_salle(numero, chapitre, 1).is_empty(),
				"un alambic n'est pas une arene (page %d)" % numero)

func test_la_derniere_page_est_le_boss(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		var derniere := Chapitres.salles(chapitre)
		var vagues := Vagues.pour_salle(derniere, chapitre, 1)
		v.egal(vagues.size(), 1, "le boss arrive seul, en une vague")
		v.egal(vagues[0], [Chapitres.par_index(chapitre)["boss"]], "et c'est le boss du chapitre")

func test_le_mi_chapitre_annonce_le_boss(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		var milieu: int = Chapitres.par_index(chapitre)["mi_boss"]
		var vagues := Vagues.pour_salle(milieu, chapitre, 1)
		v.egal(vagues[0], [Chapitres.par_index(chapitre)["boss"]], "le mi-chapitre montre le boss")
	v.vrai(Vagues.facteur_mi_boss() < 1.0, "mais en version entamee")

func test_difficulte_croissante(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		var debut := _ennemis(1, chapitre)
		var fin := _ennemis(Chapitres.salles(chapitre) - 5, chapitre)
		v.vrai(fin > debut, "le chapitre %d envoie plus d'ennemis a la fin qu'au debut" % chapitre)

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
