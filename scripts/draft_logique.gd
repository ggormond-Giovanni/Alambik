class_name DraftLogique
extends RefCounted

static func proposer(inventaire: Array, rng: RandomNumberGenerator, nb := 3) -> Array[String]:
	var candidats: Array[String] = []
	for id in CatalogueReactifs.ids():
		if not id in inventaire:
			candidats.append(id)
	var tirage: Array[String] = []
	while tirage.size() < nb and not candidats.is_empty():
		var index := rng.randi_range(0, candidats.size() - 1)
		tirage.append(candidats[index])
		candidats.remove_at(index)
	return tirage

# Second chemin vers les fusions : si le joueur possede deja les deux
# composants d'une recette, le draft peut proposer l'essence elle-meme.
# La decision de l'alambic reste entiere : elle porte sur d'autres paires.
static func proposer_avec_essence(inventaire: Array, rng: RandomNumberGenerator, nb := 3) -> Array[String]:
	var propositions := proposer(inventaire, rng, nb)
	var paires := AlambicLogique.paires_possibles(inventaire)
	if paires.is_empty() or propositions.is_empty():
		return propositions
	var choisie: Array = paires[rng.randi_range(0, paires.size() - 1)]
	var essence: String = choisie[2]
	if essence in inventaire or essence in propositions:
		return propositions
	propositions[rng.randi_range(0, propositions.size() - 1)] = essence
	return propositions
