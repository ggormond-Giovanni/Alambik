extends RefCounted

func test_plusieurs_chapitres(v: Verif) -> void:
	v.egal(Chapitres.nombre(), 10, "la bibliotheque compte dix grimoires")

func test_trente_pages(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		v.egal(Chapitres.salles(chapitre), 30, "un grimoire fait trente pages")

func test_chaque_chapitre_a_les_champs_requis(v: Verif) -> void:
	var ids: Array[String] = []
	for chapitre in Chapitres.TOUS:
		for champ in ["id", "nom", "salles", "alambics", "bosses", "boss", "pv_mult", "degats_mult"]:
			v.vrai(chapitre.has(champ), "le chapitre %s doit definir %s" % [chapitre.get("nom", "?"), champ])
		v.vrai(not chapitre["id"] in ids, "l'id de chapitre %s doit etre unique" % chapitre["id"])
		ids.append(chapitre["id"])

func test_chaque_boss_existe(v: Verif) -> void:
	for chapitre in Chapitres.TOUS:
		v.vrai(CatalogueEnnemis.TOUS.has(chapitre["boss"]),
			"le boss %s du chapitre %s doit etre catalogue" % [chapitre["boss"], chapitre["nom"]])

func test_les_dix_grimoires_sont_distincts(v: Verif) -> void:
	var vus: Array[String] = []
	for chapitre in Chapitres.TOUS:
		v.vrai(not chapitre["id"] in vus, "le grimoire %s est unique" % chapitre["id"])
		vus.append(chapitre["id"])

func test_les_alambics_tombent_dans_le_chapitre(v: Verif) -> void:
	for index in Chapitres.nombre():
		var chapitre := Chapitres.par_index(index)
		for salle in chapitre["alambics"]:
			v.vrai(salle >= 1 and salle < int(chapitre["salles"]),
				"l'alambic page %d doit tomber avant le boss" % salle)
		v.egal(chapitre["alambics"], [9, 19, 29], "la fusion arrive juste avant chaque boss")

func test_un_boss_tous_les_dix_paliers(v: Verif) -> void:
	for index in Chapitres.nombre():
		var chapitre := Chapitres.par_index(index)
		v.egal(chapitre["bosses"], [10, 20, 30], "les boss rythment chaque tiers du grimoire")
		for salle in [10, 20, 30]:
			v.vrai(Chapitres.est_boss(index, salle), "la page %d est un boss" % salle)

func test_les_chapitres_montent_en_difficulte(v: Verif) -> void:
	for index in range(1, Chapitres.nombre()):
		v.vrai(float(Chapitres.par_index(index)["pv_mult"]) > float(Chapitres.par_index(index - 1)["pv_mult"]),
			"le chapitre %d est plus dur que le precedent" % index)
		v.vrai(float(Chapitres.par_index(index)["pv_mult"]) >= float(Chapitres.par_index(index - 1)["pv_mult"]) * 1.50,
			"le grimoire suivant impose un vrai mur de puissance")

func test_index_hors_bornes_ne_plante_pas(v: Verif) -> void:
	v.egal(Chapitres.par_index(-5)["id"], Chapitres.TOUS[0]["id"], "un index negatif retombe sur le premier")
	v.egal(Chapitres.par_index(999)["id"], Chapitres.TOUS[Chapitres.nombre() - 1]["id"], "et un index trop grand sur le dernier")
