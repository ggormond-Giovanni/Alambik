extends RefCounted

func _rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 7
	return r

func test_trois_propositions(v: Verif) -> void:
	var propositions := DraftLogique.proposer([], _rng())
	v.egal(propositions.size(), 3, "le draft propose trois reactifs")

func test_propositions_distinctes(v: Verif) -> void:
	var propositions := DraftLogique.proposer([], _rng())
	v.vrai(propositions[0] != propositions[1] and propositions[1] != propositions[2] \
		and propositions[0] != propositions[2], "les trois propositions different")

func test_ne_propose_pas_ce_qu_on_a_deja(v: Verif) -> void:
	var possedes: Array[String] = ["braise", "givre", "ricochet"]
	for essai in 20:
		var r := RandomNumberGenerator.new()
		r.seed = essai
		for id in DraftLogique.proposer(possedes, r):
			v.vrai(not id in possedes, "le draft ne repropose pas %s" % id)

func test_reproductible(v: Verif) -> void:
	v.egal(DraftLogique.proposer([], _rng()), DraftLogique.proposer([], _rng()), "meme graine, meme tirage")

func test_inventaire_presque_complet(v: Verif) -> void:
	# Quand il reste moins de trois candidats, on propose ce qui reste
	# plutot que de planter ou de boucler.
	var possedes := CatalogueReactifs.ids().slice(0, 13)
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
