extends RefCounted

func test_chaque_salle_de_combat_a_des_vagues(v: Verif) -> void:
	for numero in range(1, Reglages.SALLES_PAR_RUN + 1):
		if numero in [Reglages.SALLE_ALAMBIC_A, Reglages.SALLE_ALAMBIC_B, Reglages.SALLE_BOSS]:
			continue
		var vagues := Vagues.pour_salle(numero)
		v.vrai(vagues.size() >= 2, "la salle %d doit avoir au moins deux vagues" % numero)
		for vague in vagues:
			v.vrai(not vague.is_empty(), "aucune vague vide en salle %d" % numero)

func test_les_ennemis_cites_existent(v: Verif) -> void:
	for numero in range(1, Reglages.SALLES_PAR_RUN + 1):
		for vague in Vagues.pour_salle(numero):
			for id in vague:
				v.vrai(CatalogueEnnemis.TOUS.has(id), "l'ennemi %s de la salle %d doit exister" % [id, numero])

func test_salles_speciales_sans_vagues(v: Verif) -> void:
	v.vrai(Vagues.pour_salle(Reglages.SALLE_ALAMBIC_A).is_empty(), "un alambic n'a pas de vagues")
	v.vrai(Vagues.pour_salle(Reglages.SALLE_ALAMBIC_B).is_empty(), "un alambic n'a pas de vagues")

func test_la_salle_du_boss_ne_contient_que_lui(v: Verif) -> void:
	var vagues := Vagues.pour_salle(Reglages.SALLE_BOSS)
	v.egal(vagues.size(), 1, "le boss arrive seul, en une vague")
	v.egal(vagues[0], ["le_correcteur"], "et c'est Le Correcteur")

func test_difficulte_croissante(v: Verif) -> void:
	var premiere := 0
	for vague in Vagues.pour_salle(1):
		premiere += vague.size()
	var derniere := 0
	for vague in Vagues.pour_salle(8):
		derniere += vague.size()
	v.vrai(derniere > premiere, "la salle 8 envoie plus d'ennemis que la salle 1")

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
