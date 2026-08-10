class_name Chapitres
extends RefCounted

# Un chapitre est une descente de trente pages. Tout ce qui le distingue est
# ici : sa longueur, ou se trouvent ses alambics, son boss, et de combien ses
# creatures sont plus dures que celles du chapitre precedent.
#
# Ajouter un chapitre, c'est ajouter une entree dans cette liste. Aucun code
# n'a besoin de connaitre leur nombre.

const TOUS := [
	{"id": "encres", "nom": "I — Grimoire des Encres", "sous_titre": "Les créatures quittent leurs lignes.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "le_correcteur", "pv_mult": 1.00, "degats_mult": 1.00, "teinte": Color(0.60, 0.50, 0.92)},
	{"id": "braises", "nom": "II — Grimoire des Braises", "sous_titre": "Chaque page conserve une étincelle.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "la_rature", "pv_mult": 1.55, "degats_mult": 1.22, "teinte": Color(1.00, 0.55, 0.28)},
	{"id": "givre", "nom": "III — Grimoire du Givre", "sous_titre": "Le papier craque sous le froid.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "l_errata", "pv_mult": 2.40, "degats_mult": 1.49, "teinte": Color(0.52, 0.86, 1.00)},
	{"id": "orages", "nom": "IV — Grimoire des Orages", "sous_titre": "Les phrases grondent avant de frapper.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "le_correcteur", "pv_mult": 3.72, "degats_mult": 1.82, "teinte": Color(0.98, 0.90, 0.35)},
	{"id": "venins", "nom": "V — Grimoire des Venins", "sous_titre": "L’encre ronge ceux qui la lisent.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "la_rature", "pv_mult": 5.77, "degats_mult": 2.22, "teinte": Color(0.52, 0.94, 0.38)},
	{"id": "echos", "nom": "VI — Grimoire des Échos", "sous_titre": "Chaque attaque revient une seconde fois.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "l_errata", "pv_mult": 8.94, "degats_mult": 2.71, "teinte": Color(0.70, 0.56, 0.98)},
	{"id": "ombres", "nom": "VII — Grimoire des Ombres", "sous_titre": "Les mots se déplacent quand on détourne les yeux.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "le_correcteur", "pv_mult": 13.86, "degats_mult": 3.31, "teinte": Color(0.46, 0.42, 0.68)},
	{"id": "runes", "nom": "VIII — Grimoire des Runes", "sous_titre": "Des signes anciens défendent leurs secrets.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "la_rature", "pv_mult": 21.48, "degats_mult": 4.04, "teinte": Color(0.35, 0.92, 0.76)},
	{"id": "neant", "nom": "IX — Grimoire du Néant", "sous_titre": "Certaines pages auraient dû rester blanches.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "l_errata", "pv_mult": 33.30, "degats_mult": 4.93, "teinte": Color(0.82, 0.38, 0.82)},
	{"id": "alambic", "nom": "X — Grimoire de l’Alambic", "sous_titre": "Toutes les formules convergent ici.", "salles": 30, "alambics": [9, 19, 29], "bosses": [10, 20, 30], "boss": "le_correcteur", "pv_mult": 51.62, "degats_mult": 6.01, "teinte": Color(1.00, 0.74, 0.24)},
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
	return salle in par_index(index)["bosses"]

# Montee en puissance des creatures : leur chapitre, puis leur profondeur dans
# ce chapitre. La courbe est geometrique, pas lineaire — la puissance du heros
# l'est aussi, et une montee lineaire donnait un debut infernal suivi d'une fin
# ou plus rien ne le menacait.
static func progression(index: int, salle: int) -> float:
	var chapitre := par_index(index)
	return clampf(float(salle - 1) / maxf(1.0, float(chapitre["salles"] - 1)), 0.0, 1.0)

static func facteur_pv(index: int, salle: int) -> float:
	return par_index(index)["pv_mult"] * pow(1.0 + Reglages.MONTEE_PV, progression(index, salle))

static func facteur_degats(index: int, salle: int) -> float:
	return par_index(index)["degats_mult"] * pow(1.0 + Reglages.MONTEE_DEGATS, progression(index, salle))
