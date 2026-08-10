class_name DraftLogique
extends RefCounted

# Les choix viennent des niveaux d'experience. Reprendre un reactif deja possede
# reste possible, avec des rendements decroissants et un plafond de copies.

const REPOS := "repos"
const BONUS_BASIQUES := {
	"bonus_attaque": {"nom": "Attaque", "description": "+6 % de dégâts pour cette descente.", "couleur": Color(1.00, 0.60, 0.32), "glyphe": "lance"},
	"bonus_vitalite": {"nom": "Vitalité", "description": "+8 PV maximum et soin immédiat.", "couleur": Color(0.98, 0.42, 0.52), "glyphe": "fiole"},
	"bonus_defense": {"nom": "Défense", "description": "4 % de dégâts subis en moins pour cette descente.", "couleur": Color(0.66, 0.82, 1.00), "glyphe": "hexagone"},
	"bonus_soin": {"nom": "Soin", "description": "Rend 22 % des points de vie maximum.", "couleur": Color(0.55, 0.92, 0.62), "glyphe": "goutte"},
}

static func est_page_de_reactif(niveau: int) -> bool:
	return niveau % 3 == 0

static func proposer_basiques(rng: RandomNumberGenerator, nb := 3) -> Array[String]:
	var restants: Array[String] = []
	for id in BONUS_BASIQUES:
		restants.append(id)
	var tirage: Array[String] = []
	while tirage.size() < nb and not restants.is_empty():
		var index := rng.randi_range(0, restants.size() - 1)
		tirage.append(restants.pop_at(index))
	return tirage

static func bonus_basique(id: String) -> Reactif:
	if not BONUS_BASIQUES.has(id):
		return null
	var donnees: Dictionary = BONUS_BASIQUES[id]
	return Reactif.creer(id, donnees["nom"], donnees["description"], {}, false,
		donnees["couleur"], donnees["glyphe"])

static func copies(inventaire: Array, id: String) -> int:
	var total := 0
	for possede in inventaire:
		if possede == id:
			total += 1
	return total

static func candidats(inventaire: Array) -> Array[String]:
	var liste: Array[String] = []
	for id in CatalogueReactifs.ids():
		var reactif := CatalogueReactifs.par_id(id)
		if copies(inventaire, id) < reactif.copies_permises():
			liste.append(id)
	return liste

static func proposer(inventaire: Array, rng: RandomNumberGenerator, nb := 3) -> Array[String]:
	var restants := candidats(inventaire)
	var tirage: Array[String] = []
	while tirage.size() < nb and not restants.is_empty():
		var index := rng.randi_range(0, restants.size() - 1)
		tirage.append(restants[index])
		restants.remove_at(index)
	if tirage.is_empty():
		# Tout est au plafond : on ne laisse pas une page sans recompense.
		tirage.append(REPOS)
	return tirage

# Tous les trois niveaux, un heros blesse peut sacrifier une proposition pour
# recuperer des PV. Le soin reste un choix, pas une regeneration gratuite.
static func avec_repos(propositions: Array[String], niveau: int, est_blesse: bool) -> Array[String]:
	var resultat: Array[String] = propositions.duplicate()
	if not est_blesse or niveau % 3 != 0:
		return resultat
	if resultat.is_empty():
		resultat.append(REPOS)
	else:
		resultat[resultat.size() - 1] = REPOS
	return resultat

# Second chemin vers les fusions : si le joueur possede deja les deux
# composants d'une recette, le draft peut proposer l'essence elle-meme. Elle
# consomme ses composants comme a l'alambic — la decision reste entiere.
static func proposer_avec_essence(inventaire: Array, rng: RandomNumberGenerator, nb := 3) -> Array[String]:
	var propositions := proposer(inventaire, rng, nb)
	var paires := AlambicLogique.paires_possibles(inventaire)
	if paires.is_empty() or propositions.is_empty() or propositions[0] == REPOS:
		return propositions
	var choisie: Array = paires[rng.randi_range(0, paires.size() - 1)]
	var essence: String = choisie[2]
	if essence in inventaire or essence in propositions:
		return propositions
	propositions[rng.randi_range(0, propositions.size() - 1)] = essence
	return propositions
