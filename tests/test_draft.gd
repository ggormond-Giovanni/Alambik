extends RefCounted

func _rng() -> RandomNumberGenerator:
	var resultat := RandomNumberGenerator.new()
	resultat.seed = 7
	return resultat

func test_trois_augments_distincts(v: Verif) -> void:
	var propositions := DraftLogique.proposer([], _rng())
	v.egal(propositions.size(), 3, "le niveau propose trois Augments")
	v.vrai(propositions[0] != propositions[1] and propositions[1] != propositions[2] \
		and propositions[0] != propositions[2], "les trois Augments sont distincts")

func test_un_augment_acquis_ne_revient_pas(v: Verif) -> void:
	var acquis: Array[String] = ["tir_multiple", "egide", "meteores"]
	for essai in 20:
		var rng := RandomNumberGenerator.new()
		rng.seed = essai
		for id in DraftLogique.proposer(acquis, rng):
			v.vrai(id not in acquis, "%s ne revient pas une fois acquis" % id)

func test_le_pool_epuise_ne_cree_aucun_bonus_de_remplacement(v: Verif) -> void:
	v.egal(DraftLogique.proposer(CatalogueReactifs.ids(), _rng()), [],
		"aucun ancien bonus ou repos n'est invente quand le pool est epuise")

func test_reproductible(v: Verif) -> void:
	v.egal(DraftLogique.proposer([], _rng()), DraftLogique.proposer([], _rng()),
		"une meme graine produit les memes propositions")

func test_copies_comptees(v: Verif) -> void:
	v.egal(DraftLogique.copies(["egide", "salve", "egide"], "egide"), 2,
		"la compatibilite d'affichage compte correctement")
