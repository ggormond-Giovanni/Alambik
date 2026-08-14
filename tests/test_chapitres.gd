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
	var dernier := Chapitres.nombre() - 1
	v.vrai(Chapitres.facteur_pv(dernier, Reglages.SALLES_PAR_RUN) < 200.0,
		"la fin reste sous x200 PV au lieu d'exploser a x512 des l'entree")
	v.vrai(Chapitres.facteur_degats(dernier, Reglages.SALLES_PAR_RUN) < 10.0,
		"les degats finaux restent esquivables avec une defense developpee")

# La marche d'entree de Monde etait le vrai mur : un chapitre 1 valait +50 % de
# PV d'un coup, contre +12 % entre deux chapitres du meme Monde.
func test_la_montee_est_lissee_sur_chaque_chapitre(v: Verif) -> void:
	# Passe la phase d'adoucissement du debut, ou la montee est volontairement
	# plus vive puisqu'elle part de bien plus bas.
	for index in range(Reglages.COURBE_PALIERS_DOUCEUR + 1, Chapitres.nombre()):
		var ratio := float(Chapitres.par_index(index)["pv_mult"]) \
			/ float(Chapitres.par_index(index - 1)["pv_mult"])
		v.presque(ratio, Reglages.COURBE_PV_PAR_PALIER,
			"aucun passage de chapitre n'est une marche plus haute que les autres")
	var par_monde := pow(Reglages.COURBE_PV_PAR_PALIER, Chapitres.CHAPITRES_PAR_MONDE)
	v.vrai(par_monde >= 1.40 and par_monde <= 1.50,
		"un Monde entier reste une montee franche, repartie sur ses trois chapitres")

# Un compte neuf n'a ni Maitrise ni objet. Mesure faite, sans cet adoucissement
# il mourait salle 3 du premier chapitre, donc avant le coffre de la salle 5 :
# la campagne ne financait jamais sa propre progression.
func test_les_premiers_paliers_sont_adoucis(v: Verif) -> void:
	v.presque(Chapitres.douceur_du_palier(0), Reglages.COURBE_DOUCEUR_DEBUT,
		"le tout premier chapitre est nettement en dessous de la courbe")
	v.presque(Chapitres.douceur_du_palier(Reglages.COURBE_PALIERS_DOUCEUR), 1.0,
		"l'adoucissement a disparu apres les premiers Mondes")
	v.presque(Chapitres.douceur_du_palier(Chapitres.nombre() - 1), 1.0,
		"la fin de campagne n'est pas touchee")
	for palier in range(1, Chapitres.nombre()):
		v.vrai(Chapitres.pv_du_palier(palier) > Chapitres.pv_du_palier(palier - 1),
			"la difficulte monte a chaque palier, adoucissement compris")
		v.vrai(Chapitres.degats_du_palier(palier) > Chapitres.degats_du_palier(palier - 1),
			"les degats montent aussi a chaque palier")

func test_la_courbe_reste_definie_au_dela_du_dernier_monde(v: Verif) -> void:
	var dernier := Chapitres.nombre() - 1
	v.presque(Chapitres.pv_du_palier(dernier), float(Chapitres.par_index(dernier)["pv_mult"]),
		"la table et la formule donnent le meme resultat")
	v.vrai(Chapitres.pv_du_palier(dernier + 3) > Chapitres.pv_du_palier(dernier),
		"un onzieme Monde aurait deja sa difficulte, sans nouvelle table")
	v.vrai(Chapitres.degats_du_palier(dernier + 3) > Chapitres.degats_du_palier(dernier),
		"les degats suivent la meme extension")
	v.presque(Chapitres.pv_du_palier(-4), Chapitres.pv_du_palier(0),
		"un palier negatif retombe sur le premier")

func test_index_hors_bornes_ne_plante_pas(v: Verif) -> void:
	v.egal(Chapitres.par_index(-5)["id"], Chapitres.TOUS[0]["id"], "un index negatif retombe sur le premier")
	v.egal(Chapitres.par_index(999)["id"], Chapitres.TOUS[Chapitres.nombre() - 1]["id"], "un index trop grand sur le dernier")
