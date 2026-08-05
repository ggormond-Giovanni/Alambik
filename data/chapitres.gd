class_name Chapitres
extends RefCounted

# Un chapitre est une descente de cinquante pages. Tout ce qui le distingue est
# ici : sa longueur, ou se trouvent ses alambics, son boss, et de combien ses
# creatures sont plus dures que celles du chapitre precedent.
#
# Ajouter un chapitre, c'est ajouter une entree dans cette liste. Aucun code
# n'a besoin de connaitre leur nombre.

const TOUS := [
	{
		"id": "grimoire",
		"nom": "Le Grimoire",
		"sous_titre": "Les premières pages, celles qu'on lit encore sans crainte.",
		"salles": 50,
		"alambics": [10, 20, 30, 40],
		"mi_boss": 25,
		"boss": "le_correcteur",
		"pv_mult": 1.0,
		"degats_mult": 1.0,
		"teinte": Color(0.60, 0.50, 0.92),
	},
	{
		"id": "marges",
		"nom": "Les Marges",
		"sous_titre": "Ce qui a été griffonné à côté du texte, et qui a pris vie.",
		"salles": 50,
		"alambics": [10, 20, 30, 40],
		"mi_boss": 25,
		"boss": "la_rature",
		"pv_mult": 1.35,
		"degats_mult": 1.15,
		"teinte": Color(0.95, 0.62, 0.35),
	},
	{
		"id": "errata",
		"nom": "L'Errata",
		"sous_titre": "La page des fautes. Elle vous compte parmi elles.",
		"salles": 50,
		"alambics": [10, 20, 30, 40],
		"mi_boss": 25,
		"boss": "l_errata",
		"pv_mult": 1.55,
		"degats_mult": 1.25,
		"teinte": Color(0.98, 0.36, 0.48),
	},
]

static func nombre() -> int:
	return TOUS.size()

static func par_index(index: int) -> Dictionary:
	return TOUS[clampi(index, 0, TOUS.size() - 1)]

static func par_id(id: String) -> Dictionary:
	for chapitre in TOUS:
		if chapitre["id"] == id:
			return chapitre
	return TOUS[0]

static func salles(index: int) -> int:
	return par_index(index)["salles"]

static func est_alambic(index: int, salle: int) -> bool:
	return salle in par_index(index)["alambics"]

static func est_boss(index: int, salle: int) -> bool:
	var chapitre := par_index(index)
	return salle == chapitre["boss_salle"] if chapitre.has("boss_salle") else salle == chapitre["salles"]

static func est_mi_boss(index: int, salle: int) -> bool:
	return salle == par_index(index).get("mi_boss", -1)

# Montee en puissance des creatures : leur chapitre, puis leur profondeur dans
# ce chapitre. La courbe est geometrique, pas lineaire — la puissance du heros
# l'est aussi, et une montee lineaire donnait un debut infernal suivi d'une fin
# ou plus rien ne le menacait (mesure : rapport 0,5 page 10, 16 page 50).
static func progression(index: int, salle: int) -> float:
	var chapitre := par_index(index)
	return clampf(float(salle - 1) / maxf(1.0, float(chapitre["salles"] - 1)), 0.0, 1.0)

static func facteur_pv(index: int, salle: int) -> float:
	return par_index(index)["pv_mult"] * pow(1.0 + Reglages.MONTEE_PV, progression(index, salle))

static func facteur_degats(index: int, salle: int) -> float:
	return par_index(index)["degats_mult"] * pow(1.0 + Reglages.MONTEE_DEGATS, progression(index, salle))
