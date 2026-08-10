extends RefCounted

func test_le_repos_arrive_tous_les_trois_niveaux_si_blesse(v: Verif) -> void:
	var propositions: Array[String] = ["braise", "givre", "foudre"]
	v.vrai(DraftLogique.REPOS in DraftLogique.avec_repos(propositions, 3, true),
		"un niveau de repos propose de se soigner")
	v.vrai(not DraftLogique.REPOS in DraftLogique.avec_repos(propositions, 2, true),
		"le soin n'envahit pas chaque niveau")
	v.vrai(not DraftLogique.REPOS in DraftLogique.avec_repos(propositions, 3, false),
		"le soin n'est pas propose a pleine vie")

func _rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 7
	return r

func test_trois_propositions(v: Verif) -> void:
	var propositions := DraftLogique.proposer([], _rng())
	v.egal(propositions.size(), 3, "le draft propose trois reactifs")

func test_copies_comptees(v: Verif) -> void:
	v.egal(DraftLogique.copies(["braise", "main_leste", "braise"], "braise"), 2, "deux exemplaires comptes")
	v.egal(DraftLogique.copies([], "braise"), 0, "aucun exemplaire dans un inventaire vide")

func test_propositions_distinctes(v: Verif) -> void:
	var propositions := DraftLogique.proposer([], _rng())
	v.vrai(propositions[0] != propositions[1] and propositions[1] != propositions[2] \
		and propositions[0] != propositions[2], "les trois propositions different")

func test_ne_repropose_pas_un_reactif_au_plafond(v: Verif) -> void:
	# Braise n'apporte rien deux fois : les effets ne s'empilent pas.
	var possedes: Array[String] = ["braise", "givre", "foudre"]
	for essai in 20:
		var r := RandomNumberGenerator.new()
		r.seed = essai
		for id in DraftLogique.proposer(possedes, r):
			v.vrai(not id in possedes, "le draft ne repropose pas %s, deja au plafond" % id)

func test_un_reactif_empilable_revient(v: Verif) -> void:
	# Sur cinquante pages, il faut pouvoir renforcer ce qu'on a deja.
	var trouve := false
	for essai in 40:
		var r := RandomNumberGenerator.new()
		r.seed = essai
		if "main_leste" in DraftLogique.proposer(["main_leste"], r):
			trouve = true
			break
	v.vrai(trouve, "un reactif empilable peut etre repropose")

func test_le_plafond_de_copies_est_tenu(v: Verif) -> void:
	var plein: Array[String] = []
	var plafond := CatalogueReactifs.par_id("main_leste").copies_permises()
	for i in plafond:
		plein.append("main_leste")
	for essai in 20:
		var r := RandomNumberGenerator.new()
		r.seed = essai
		v.vrai(not "main_leste" in DraftLogique.proposer(plein, r),
			"au plafond de %d copies, le reactif ne revient plus" % plafond)

func test_une_page_de_repos_quand_tout_est_au_plafond(v: Verif) -> void:
	var tout: Array[String] = []
	for id in CatalogueReactifs.ids():
		for i in CatalogueReactifs.par_id(id).copies_permises():
			tout.append(id)
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var propositions := DraftLogique.proposer(tout, r)
	v.egal(propositions.size(), 1, "il ne reste qu'une carte a offrir")
	v.egal(propositions[0], DraftLogique.REPOS, "et c'est une page de repos, pas un panneau vide")

func test_reproductible(v: Verif) -> void:
	v.egal(DraftLogique.proposer([], _rng()), DraftLogique.proposer([], _rng()), "meme graine, meme tirage")

func test_presque_tout_au_plafond(v: Verif) -> void:
	# Quand il reste moins de trois candidats, on propose ce qui reste
	# plutot que de planter ou de boucler.
	var possedes: Array[String] = []
	for id in CatalogueReactifs.ids().slice(0, 13):
		for i in CatalogueReactifs.par_id(id).copies_permises():
			possedes.append(id)
	var propositions := DraftLogique.proposer(possedes, _rng())
	v.egal(propositions.size(), 2, "il ne reste que deux candidats")

func test_essence_proposee_quand_les_composants_sont_la(v: Verif) -> void:
	var possedes: Array[String] = ["braise", "ricochet"]
	var propositions := DraftLogique.proposer_avec_essence(possedes, _rng())
	v.vrai("trainee_etincelles" in propositions, "l'essence accessible est proposee")
	v.egal(propositions.size(), 3, "elle remplace une proposition, elle n'en ajoute pas")

func test_pas_d_essence_sans_composants(v: Verif) -> void:
	for essai in 10:
		var r := RandomNumberGenerator.new()
		r.seed = essai
		for id in DraftLogique.proposer_avec_essence(["braise", "perforation"], r):
			v.vrai(not CatalogueEssences.TOUS.has(id), "aucune essence sans recette complete")
