class_name DraftLogique
extends RefCounted

# Un niveau propose trois Augments distincts parmi ceux que la run ne possede
# pas encore. Les six decisions restent ainsi comportementales et lisibles.

static func candidats(inventaire: Array) -> Array[String]:
	var liste: Array[String] = []
	for id in CatalogueReactifs.ids():
		if id not in inventaire:
			liste.append(id)
	return liste

static func proposer(inventaire: Array, rng: RandomNumberGenerator, nb := 3) -> Array[String]:
	var restants := candidats(inventaire)
	var tirage: Array[String] = []
	while tirage.size() < nb and not restants.is_empty():
		var index := rng.randi_range(0, restants.size() - 1)
		tirage.append(restants.pop_at(index))
	return tirage

static func copies(inventaire: Array, id: String) -> int:
	return inventaire.count(id)
