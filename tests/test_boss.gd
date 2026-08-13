extends RefCounted

func test_premiere_phase(v: Verif) -> void:
	v.egal(Boss.phase_pour(100.0, 100.0), 1, "a pleine vie, phase 1")
	v.egal(Boss.phase_pour(60.0, 100.0), 1, "au-dessus de la moitie, phase 1")

func test_seconde_phase(v: Verif) -> void:
	v.egal(Boss.phase_pour(40.0, 100.0), 2, "sous la moitie, phase 2")

func test_motifs_cycliques(v: Verif) -> void:
	v.egal(Boss.motif_suivant(1, 0), Boss.motif_suivant(1, Boss.MOTIFS_PHASE_1.size()),
		"les motifs bouclent")

func test_motifs_connus(v: Verif) -> void:
	for id in CatalogueEnnemis.ids_miniboss() + CatalogueEnnemis.ids_boss_signatures():
		for phase in [1, 2]:
			for motif in Boss.motifs_pour(id, phase):
				v.vrai(motif in Boss.MOTIFS_CONNUS, "motif %s de %s inconnu" % [motif, id])

func test_la_seconde_phase_change_de_repertoire(v: Verif) -> void:
	# Une phase 2 qui rejoue les memes motifs n'est pas une seconde phase.
	v.vrai("invocation" in Boss.MOTIFS_PHASE_2, "la phase 2 invoque")
	v.vrai(not "invocation" in Boss.MOTIFS_PHASE_1, "la phase 1 n'invoque pas")

func test_les_dix_miniboss_ont_des_patterns_distincts(v: Verif) -> void:
	var profils := {}
	var silhouettes := {}
	var signatures := ["griffure", "echo_errata", "quadrillage", "machoire", "calligraphie",
		"indexation", "onde_marge", "rosace", "estampille", "copie_double"]
	for id in CatalogueEnnemis.ids_miniboss():
		var signature := str(Boss.motifs_pour(id, 1)) + str(Boss.motifs_pour(id, 2))
		v.vrai(not profils.has(signature), "%s ne reutilise pas le profil d'un autre miniboss" % id)
		profils[signature] = true
		var silhouette: String = CatalogueEnnemis.par_id(id).get("silhouette", "")
		v.vrai(not silhouette.is_empty() and not silhouettes.has(silhouette),
			"%s possede une silhouette propre" % id)
		silhouettes[silhouette] = true
		var motif_propre := false
		for motif in Boss.motifs_pour(id, 1):
			if motif in signatures:
				motif_propre = true
		v.vrai(motif_propre, "%s montre son attaque signature des la phase un" % id)
	v.vrai("charge" in Boss.motifs_pour("la_rature", 1), "La Rature charge des la phase un")
	v.vrai("invocation" in Boss.motifs_pour("l_errata", 1), "La Faute vive invoque des la phase un")

func test_les_dix_boss_signatures_ont_des_repertoires_distincts(v: Verif) -> void:
	var profils := {}
	for id in CatalogueEnnemis.ids_boss_signatures():
		var signature := str(Boss.motifs_pour(id, 1)) + str(Boss.motifs_pour(id, 2))
		v.vrai(not profils.has(signature), "%s possede son propre repertoire" % id)
		profils[signature] = true
		v.vrai(Boss.motifs_pour(id, 1).size() >= 3, "%s a au moins trois temps en phase un" % id)
		v.vrai(Boss.motifs_pour(id, 2).size() >= 4, "%s enrichit sa seconde phase" % id)
