class_name Recompenses
extends RefCounted

const GOUTTES_COFFRE_COMPLET_MIN := 250
const GOUTTES_COFFRE_COMPLET_MAX := 350
const GOUTTES_EPREUVE_MIN := 6
const GOUTTES_EPREUVE_MAX := 12

# 1..5 ultime, 6..15 actif, 16..25 passif, puis gouttes : exactement les
# probabilités annoncées, sans pourcentages cachés.
static func type_epreuve_pour_jet(jet: int) -> String:
	if jet <= 5:
		return "ultime"
	if jet <= 15:
		return "actif"
	if jet <= 25:
		return "passif"
	return "gouttes"

static func tirer_epreuve(rng: RandomNumberGenerator, rangs: Dictionary, niveau_heros: int) -> Dictionary:
	var type := type_epreuve_pour_jet(rng.randi_range(1, 100))
	if type == "gouttes":
		return {"type": "gouttes", "quantite": rng.randi_range(GOUTTES_EPREUVE_MIN, GOUTTES_EPREUVE_MAX)}
	var catalogue: Dictionary
	match type:
		"ultime": catalogue = Sorts.ULTIMES
		"actif": catalogue = Sorts.ACTIFS
		_: catalogue = Sorts.PASSIFS
	var candidats: Array[String] = []
	for id in catalogue:
		# Le niveau du heros revele le sort au rang 0. Les defis fournissent
		# ensuite les cinq exemplaires qui le rendent utilisable et l'ameliorent.
		if int(catalogue[id]["niveau"]) <= niveau_heros and int(rangs.get(id, 0)) < 5:
			candidats.append(id)
	if candidats.is_empty():
		return {"type": "gouttes", "quantite": rng.randi_range(GOUTTES_EPREUVE_MIN, GOUTTES_EPREUVE_MAX)}
	return {"type": type, "id": candidats[rng.randi_range(0, candidats.size() - 1)]}
