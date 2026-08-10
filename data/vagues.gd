class_name Vagues
extends RefCounted

# Composition des pages. Écrire trente listes à la main par chapitre serait
# illisible et diverge au premier reglage : on decrit des paliers, et la
# composition se deduit du numero de page. C'est toujours de la donnee — ajuster
# la difficulte ne demande jamais de toucher au code de la salle.
#
# Le tirage est deterministe : meme graine et meme page donnent la meme vague,
# sinon la sonde ne pourrait pas rejouer un blocage.

# `jusqu_a` est une fraction de la longueur du chapitre.
const PALIERS := [
	{"jusqu_a": 0.10, "vagues": 2, "par_vague": 2, "pool": ["encrier_rampant", "plume_sentinelle"], "distance": ["plume_sentinelle"]},
	{"jusqu_a": 0.20, "vagues": 2, "par_vague": 3, "pool": ["encrier_rampant", "plume_sentinelle", "tache_veloce"], "distance": ["plume_sentinelle"]},
	{"jusqu_a": 0.32, "vagues": 2, "par_vague": 3, "pool": ["encrier_rampant", "plume_sentinelle", "tache_veloce"], "distance": ["plume_sentinelle"]},
	{"jusqu_a": 0.46, "vagues": 2, "par_vague": 4, "pool": ["encrier_rampant", "plume_sentinelle", "tache_veloce", "scribe_essaimeur"], "distance": ["plume_sentinelle", "scribe_essaimeur"]},
	{"jusqu_a": 0.62, "vagues": 2, "par_vague": 4, "pool": ["encrier_rampant", "plume_sentinelle", "tache_veloce", "scribe_essaimeur"], "distance": ["plume_sentinelle", "scribe_essaimeur"]},
	{"jusqu_a": 0.80, "vagues": 2, "par_vague": 5, "pool": ["plume_sentinelle", "tache_veloce", "scribe_essaimeur", "encrier_rampant"], "distance": ["plume_sentinelle", "scribe_essaimeur"]},
	{"jusqu_a": 1.01, "vagues": 2, "par_vague": 5, "pool": ["tache_veloce", "scribe_essaimeur", "plume_sentinelle", "encrier_rampant"], "distance": ["plume_sentinelle", "scribe_essaimeur"]},
]

static func palier_pour(progression: float) -> Dictionary:
	for palier in PALIERS:
		if progression <= palier["jusqu_a"]:
			return palier
	return PALIERS[PALIERS.size() - 1]

static func pour_salle(numero: int, chapitre := 0, graine := 0, mode := "grimoire") -> Array:
	var donnees := Chapitres.par_index(chapitre)
	var longueur := 12 if mode == "epreuve_sorts" else int(donnees["salles"])
	if mode == "grimoire" and Chapitres.est_boss(chapitre, numero):
		return [[donnees["boss"]]]
	if mode == "epreuve_sorts" and numero % 4 == 0:
		return [[donnees["boss"]]]
	var progression := float(numero) / float(longueur)
	var palier := palier_pour(progression)
	var alea := RandomNumberGenerator.new()
	# La graine melange chapitre et page : deux pages voisines ne se ressemblent
	# pas, et la meme page rejouee est identique.
	alea.seed = graine * 7919 + chapitre * 104729 + numero * 31
	if mode == "epreuve_sorts":
		# Trois grandes rencontres puis un boss. Chaque rencontre tient en une
		# seule vague dense : le defi est plus nerveux, sans attente de repop.
		var vague_defi: Array = []
		var nombre_defi := 7 + int((numero - 1) / 4)
		var pool_defi := ["encrier_rampant", "plume_sentinelle", "tache_veloce", "scribe_essaimeur"]
		for j in nombre_defi:
			var choix_defi: Array = ["plume_sentinelle", "scribe_essaimeur"] if j == 0 else pool_defi
			vague_defi.append(choix_defi[alea.randi_range(0, choix_defi.size() - 1)])
		return [vague_defi]

	var pool: Array = palier["pool"]
	var vagues: Array = []
	for i in int(palier["vagues"]):
		var vague: Array = []
		# La derniere vague d'une page est la plus fournie : la page monte.
		var nombre := int(palier["par_vague"]) + (1 if i == int(palier["vagues"]) - 1 else 0)
		for j in nombre:
			# Chaque vague contient au moins un ennemi qui force a lire et
			# esquiver des projectiles, y compris les toutes premieres pages.
			var choix: Array = palier["distance"] if j == 0 else pool
			vague.append(choix[alea.randi_range(0, choix.size() - 1)])
		vagues.append(vague)
	return vagues
