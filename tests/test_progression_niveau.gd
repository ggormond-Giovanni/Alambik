extends RefCounted

func test_le_niveau_de_run_vient_de_l_experience(v: Verif) -> void:
	Jeu.demarrer_run(1)
	v.egal(Jeu.niveau_run, 0, "la run commence sans Amélioration")
	v.egal(Jeu.gagner_experience_run(Reglages.XP_RUN_SEUILS[0]), 1,
		"atteindre le seuil ouvre un level-up immediat")

func test_la_courbe_place_les_six_choix_avant_les_boss(v: Verif) -> void:
	Jeu.demarrer_run(42, 1, 0, "grimoire")
	var cibles := {5: 2, 10: 4, 15: 5, 20: 6}
	for salle in range(1, Reglages.SALLES_PAR_RUN + 1):
		if cibles.has(salle):
			v.egal(Jeu.niveau_run, cibles[salle],
				"%d Améliorations sont disponibles avant la salle %d" % [cibles[salle], salle])
		for vague in Vagues.pour_salle(salle, 0, 42, "grimoire"):
			for id in vague:
				Jeu.gagner_experience_run(int(CatalogueEnnemis.par_id(id)["experience"]))

func test_les_modes_ont_la_bonne_longueur(v: Verif) -> void:
	Jeu.demarrer_run(1, 1, 0, "grimoire")
	v.egal(Jeu.salles_du_chapitre(), 20, "un chapitre contient vingt salles")
	Jeu.demarrer_run(1, 1, 7, "epreuve_sorts")
	v.egal(Jeu.salles_du_chapitre(), 5, "l'Epreuve enchaine cinq miniboss")
	v.egal(Jeu.chapitre, 0, "le defi garde sa propre difficulte quel que soit le livre consulte")
	for numero in range(1, 6):
		var vagues := Vagues.pour_salle(numero, 0, 1, "epreuve_sorts")
		v.egal(vagues.size(), 1, "le miniboss %d arrive seul" % numero)
		v.egal(vagues[0].size(), 1, "une rencontre teste un seul pattern majeur")
		v.egal(CatalogueEnnemis.par_id(vagues[0][0])["cerveau"], "boss", "la cible est un miniboss")
	Jeu.demarrer_run(1, 1, 7, "mine")
	v.egal(Jeu.salles_du_chapitre(), 1, "la Mine est une arene unique")
	v.presque(Jeu.temps_mine_restant, 300.0, "la survie dure cinq minutes")
	v.vrai(Reglages.MINE_SOIN_NIVEAU > 0.0,
		"chaque niveau remplace une partie des respirations absentes de l'arene unique")
	v.vrai(Vagues.pour_salle(1, 0, 1, "mine").is_empty(),
		"les ennemis de la Mine apparaissent progressivement")
	var alea := RandomNumberGenerator.new()
	alea.seed = 1
	for tirage in 50:
		v.vrai(CatalogueEnnemis.par_id(Vagues.ennemi_mine(alea, 0.75))["cerveau"] != "boss",
			"la horde ne contient pas son boss final")
	v.vrai(not "scribe_essaimeur" in Vagues.pool_mine(0.0),
		"les invocateurs ne saturent pas le debut de la Mine")
	v.vrai("scribe_essaimeur" in Vagues.pool_mine(0.75),
		"la composition se renforce dans la seconde moitie")
	v.egal(CatalogueEnnemis.par_id(Vagues.boss_mine(1))["cerveau"], "boss",
		"un boss conclut la survie")
	Jeu.demarrer_run(1, 1, 7, "retro")
	v.egal(Jeu.salles_du_chapitre(), 1, "le prototype retro tient dans une salle")
	v.vrai(Jeu.est_retro(), "le rendu peut reconnaitre explicitement le prototype")
	v.egal(Jeu.nom_run(), "Vision enchantée", "la vision est identifiee dans le HUD")

func test_chaque_boss_d_epreuve_recoit_une_fusion_aleatoire(v: Verif) -> void:
	Jeu.demarrer_run(31415, 1, 0, "epreuve_sorts")
	var augments := {}
	var elements := {}
	for rituel in 5:
		var avant := Jeu.inventaire.size()
		var resultat := Jeu.ajouter_fusion_aleatoire_epreuve()
		v.vrai(not resultat.is_empty(), "le rituel %d produit une fusion" % (rituel + 1))
		v.egal(Jeu.inventaire.size(), avant + 2,
			"le rituel ajoute l'Amelioration et sa transformation")
		v.vrai(CatalogueReactifs.par_id(str(resultat["augment"])) != null,
			"l'Amelioration tiree existe")
		v.vrai(CatalogueElements.est_fusion(str(resultat["fusion"])),
			"le second gain est une fusion elementaire")
		augments[resultat["augment"]] = true
		elements[resultat["element"]] = true
	v.egal(augments.size(), 5, "les cinq boss recoivent cinq Ameliorations differentes")
	v.egal(elements.size(), 5, "les cinq premiers Alambics tirent cinq Elements differents")

func test_chaque_miniboss_recompense_par_une_capacite(v: Verif) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for tirage in 100:
		var recompense := Recompenses.tirer_epreuve(rng, {})
		v.vrai(recompense["type"] in ["ultime", "actif", "passif"],
			"un arsenal incomplet ne recoit pas de monnaie a la place d'une capacite")
		v.vrai(Sorts.contient(str(recompense["id"])), "la capacite tiree existe")

func test_un_arsenal_complet_recoit_un_repli(v: Verif) -> void:
	var rangs := {}
	for catalogue in [Sorts.ACTIFS, Sorts.PASSIFS, Sorts.ULTIMES]:
		for id in catalogue:
			rangs[id] = Reglages.CAPACITE_RANG_MAX
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var recompense := Recompenses.tirer_epreuve(rng, rangs)
	v.egal(recompense["type"], "gouttes", "un arsenal entierement ameliore garde une recompense")
