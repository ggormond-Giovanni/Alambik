extends RefCounted

func test_dix_mondes_de_trois_chapitres(v: Verif) -> void:
	v.egal(Chapitres.MONDES.size(), 10, "la campagne compte dix mondes")
	v.egal(Chapitres.nombre(), 30, "chaque monde contient trois chapitres")
	for monde in 10:
		for acte in 3:
			var chapitre := Chapitres.par_index(monde * 3 + acte)
			v.egal(chapitre["monde"], monde, "le chapitre appartient au bon monde")
			v.egal(chapitre["chapitre_monde"], acte + 1, "les chapitres sont numerotes 1 a 3")

func test_vingt_salles(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		v.egal(Chapitres.salles(chapitre), 20, "un chapitre fait vingt salles")

func test_chaque_chapitre_a_les_champs_requis(v: Verif) -> void:
	var ids: Array[String] = []
	for chapitre in Chapitres.TOUS:
		for champ in ["id", "nom", "monde", "chapitre_monde", "salles", "alambics", "bosses", "boss", "boss_signature", "pv_mult", "degats_mult"]:
			v.vrai(chapitre.has(champ), "le chapitre %s doit definir %s" % [chapitre.get("nom", "?"), champ])
		v.vrai(chapitre["id"] not in ids, "l'id %s est unique" % chapitre["id"])
		ids.append(chapitre["id"])

func test_chaque_boss_existe(v: Verif) -> void:
	for chapitre in Chapitres.TOUS:
		v.vrai(CatalogueEnnemis.TOUS.has(chapitre["boss"]),
			"le boss %s doit etre catalogue" % chapitre["boss"])

func test_roster_de_dix_miniboss_et_dix_signatures(v: Verif) -> void:
	v.egal(CatalogueEnnemis.ids_miniboss().size(), 10, "le jeu possede dix miniboss")
	v.egal(CatalogueEnnemis.ids_boss_signatures().size(), 10, "le jeu possede dix boss signatures")

func test_alambics_avant_5_10_15(v: Verif) -> void:
	for index in Chapitres.nombre():
		v.egal(Chapitres.par_index(index)["alambics"], [4, 9, 14],
			"les trois Alambics arrivent avant les salles 5, 10 et 15")

func test_trois_miniboss_et_un_boss_final(v: Verif) -> void:
	for index in Chapitres.nombre():
		v.egal(Chapitres.par_index(index)["bosses"], [5, 10, 15, 20],
			"le chapitre place trois miniboss puis un boss final")
		for salle in [5, 10, 15, 20]:
			v.vrai(Chapitres.est_boss(index, salle), "la salle %d est un combat de boss" % salle)

func test_seul_le_troisieme_boss_est_signature(v: Verif) -> void:
	var signatures_vues := {}
	for monde in 10:
		var premier := Chapitres.par_index(monde * 3)
		var second := Chapitres.par_index(monde * 3 + 1)
		var troisieme := Chapitres.par_index(monde * 3 + 2)
		v.vrai(not premier["boss_signature"], "le chapitre 1 utilise un miniboss")
		v.vrai(not second["boss_signature"], "le chapitre 2 utilise un miniboss")
		v.vrai(troisieme["boss_signature"], "le chapitre 3 porte le boss signature")
		v.egal(CatalogueEnnemis.par_id(premier["boss"])["rang_boss"], "miniboss", "finale chapitre 1")
		v.egal(CatalogueEnnemis.par_id(second["boss"])["rang_boss"], "miniboss", "finale chapitre 2")
		v.egal(CatalogueEnnemis.par_id(troisieme["boss"])["rang_boss"], "signature", "finale chapitre 3")
		v.vrai(not signatures_vues.has(troisieme["boss"]), "chaque monde a un boss signature unique")
		signatures_vues[troisieme["boss"]] = true
	v.egal(signatures_vues.size(), 10, "les dix signatures sont distribuees")

func test_difficulte_croissante(v: Verif) -> void:
	for index in range(1, Chapitres.nombre()):
		v.vrai(float(Chapitres.par_index(index)["pv_mult"]) > float(Chapitres.par_index(index - 1)["pv_mult"]),
			"le chapitre %d est plus dur que le precedent" % index)

func test_index_hors_bornes_ne_plante_pas(v: Verif) -> void:
	v.egal(Chapitres.par_index(-5)["id"], Chapitres.TOUS[0]["id"], "un index negatif retombe sur le premier")
	v.egal(Chapitres.par_index(999)["id"], Chapitres.TOUS[Chapitres.nombre() - 1]["id"], "un index trop grand sur le dernier")
