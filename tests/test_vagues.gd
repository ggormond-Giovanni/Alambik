extends RefCounted

# Trente pages par chapitre : on vérifie les propriétés sur chacune.
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

func test_un_boss_tous_les_dix_paliers(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in [10, 20, 30]:
			var vagues := Vagues.pour_salle(numero, chapitre, 1)
			v.egal(vagues.size(), 1, "le boss page %d arrive en une vague" % numero)
			v.egal(vagues[0], [Chapitres.par_index(chapitre)["boss"]], "et c'est le boss du chapitre")

func test_difficulte_croissante(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		var debut := _ennemis(1, chapitre)
		var fin := _ennemis(Chapitres.salles(chapitre) - 1, chapitre)
		v.vrai(fin > debut, "le chapitre %d envoie plus d'ennemis a la fin qu'au debut" % chapitre)

func test_le_mid_et_la_fin_ne_repopent_pas_sans_fin(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in [12, 15, 18, 22, 25, 29]:
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

func test_chaque_vague_normale_force_une_esquive(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		for numero in [1, 4, 12, 24, 29]:
			for vague in Vagues.pour_salle(numero, chapitre, 17):
				var menace_distance := false
				for id in vague:
					var ennemi := CatalogueEnnemis.par_id(id)
					menace_distance = menace_distance or ennemi["cerveau"] in ["sentinelle", "essaimeur"]
				v.vrai(menace_distance, "chaque vague de la page %d contient une menace a distance" % numero)

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
