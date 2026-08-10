class_name CatalogueObjets
extends RefCounted

# Chaque grimoire possède son trio complet : une arme, une robe et un
# talisman. Le coffre final choisit uniquement parmi les pièces encore
# absentes du stuff permanent.
const OBJETS := {
	"plume_encres": {"nom": "Plume des encres", "slot": "arme", "chapitre": 0, "rarete": "Commun", "teinte": Color(0.60, 0.50, 0.92), "bonus": "+3 % dégâts"},
	"robe_enluminee": {"nom": "Robe enluminée", "slot": "robe", "chapitre": 0, "rarete": "Commun", "teinte": Color(0.60, 0.50, 0.92), "bonus": "+8 PV"},
	"sceau_scribe": {"nom": "Sceau du scribe", "slot": "talisman", "chapitre": 0, "rarete": "Commun", "teinte": Color(0.60, 0.50, 0.92), "bonus": "+5 % gouttes"},
	"sceptre_braises": {"nom": "Sceptre des braises", "slot": "arme", "chapitre": 1, "rarete": "Rare", "teinte": Color(1.00, 0.55, 0.28), "bonus": "+5 % dégâts"},
	"manteau_cendre": {"nom": "Manteau de cendre", "slot": "robe", "chapitre": 1, "rarete": "Rare", "teinte": Color(1.00, 0.55, 0.28), "bonus": "+12 PV"},
	"charbon_eternel": {"nom": "Charbon éternel", "slot": "talisman", "chapitre": 1, "rarete": "Rare", "teinte": Color(1.00, 0.55, 0.28), "bonus": "+7 % gouttes"},
	"baguette_givre": {"nom": "Baguette de givre", "slot": "arme", "chapitre": 2, "rarete": "Rare", "teinte": Color(0.52, 0.86, 1.00), "bonus": "+5 % cadence"},
	"cape_givre": {"nom": "Cape de givre", "slot": "robe", "chapitre": 2, "rarete": "Rare", "teinte": Color(0.52, 0.86, 1.00), "bonus": "+14 PV"},
	"cristal_hiver": {"nom": "Cristal d'hiver", "slot": "talisman", "chapitre": 2, "rarete": "Rare", "teinte": Color(0.52, 0.86, 1.00), "bonus": "+3 % vitesse"},
	"paratonnerre": {"nom": "Paratonnerre runique", "slot": "arme", "chapitre": 3, "rarete": "Rare", "teinte": Color(0.98, 0.90, 0.35), "bonus": "+7 % dégâts"},
	"habit_orages": {"nom": "Habit des orages", "slot": "robe", "chapitre": 3, "rarete": "Rare", "teinte": Color(0.98, 0.90, 0.35), "bonus": "+16 PV"},
	"eclair_fiole": {"nom": "Éclair en fiole", "slot": "talisman", "chapitre": 3, "rarete": "Rare", "teinte": Color(0.98, 0.90, 0.35), "bonus": "+8 % gouttes"},
	"aiguille_venin": {"nom": "Aiguille de venin", "slot": "arme", "chapitre": 4, "rarete": "Épique", "teinte": Color(0.52, 0.94, 0.38), "bonus": "+8 % dégâts"},
	"peau_antidote": {"nom": "Peau d'antidote", "slot": "robe", "chapitre": 4, "rarete": "Épique", "teinte": Color(0.52, 0.94, 0.38), "bonus": "+18 PV"},
	"crochet_basilic": {"nom": "Crochet de basilic", "slot": "talisman", "chapitre": 4, "rarete": "Épique", "teinte": Color(0.52, 0.94, 0.38), "bonus": "+4 % vitesse"},
	"diapason_echos": {"nom": "Diapason des échos", "slot": "arme", "chapitre": 5, "rarete": "Épique", "teinte": Color(0.70, 0.56, 0.98), "bonus": "+9 % cadence"},
	"robe_resonance": {"nom": "Robe de résonance", "slot": "robe", "chapitre": 5, "rarete": "Épique", "teinte": Color(0.70, 0.56, 0.98), "bonus": "+20 PV"},
	"cloche_muette": {"nom": "Cloche muette", "slot": "talisman", "chapitre": 5, "rarete": "Épique", "teinte": Color(0.70, 0.56, 0.98), "bonus": "+10 % gouttes"},
	"lame_ombres": {"nom": "Lame des ombres", "slot": "arme", "chapitre": 6, "rarete": "Épique", "teinte": Color(0.46, 0.42, 0.68), "bonus": "+10 % dégâts"},
	"voile_nocturne": {"nom": "Voile nocturne", "slot": "robe", "chapitre": 6, "rarete": "Épique", "teinte": Color(0.46, 0.42, 0.68), "bonus": "+22 PV"},
	"lune_noire": {"nom": "Lune noire", "slot": "talisman", "chapitre": 6, "rarete": "Épique", "teinte": Color(0.46, 0.42, 0.68), "bonus": "+5 % vitesse"},
	"burin_runique": {"nom": "Burin runique", "slot": "arme", "chapitre": 7, "rarete": "Mythique", "teinte": Color(0.35, 0.92, 0.76), "bonus": "+11 % dégâts"},
	"armure_runes": {"nom": "Armure de runes", "slot": "robe", "chapitre": 7, "rarete": "Mythique", "teinte": Color(0.35, 0.92, 0.76), "bonus": "+25 PV"},
	"tablette_ancienne": {"nom": "Tablette ancienne", "slot": "talisman", "chapitre": 7, "rarete": "Mythique", "teinte": Color(0.35, 0.92, 0.76), "bonus": "+12 % gouttes"},
	"orbe_neant": {"nom": "Orbe du néant", "slot": "arme", "chapitre": 8, "rarete": "Mythique", "teinte": Color(0.82, 0.38, 0.82), "bonus": "+12 % dégâts"},
	"manteau_vide": {"nom": "Manteau du vide", "slot": "robe", "chapitre": 8, "rarete": "Mythique", "teinte": Color(0.82, 0.38, 0.82), "bonus": "+28 PV"},
	"fragment_neant": {"nom": "Fragment de néant", "slot": "talisman", "chapitre": 8, "rarete": "Mythique", "teinte": Color(0.82, 0.38, 0.82), "bonus": "+6 % vitesse"},
	"alambic_royal": {"nom": "Alambic royal", "slot": "arme", "chapitre": 9, "rarete": "Légendaire", "teinte": Color(1.00, 0.74, 0.24), "bonus": "+15 % dégâts"},
	"robe_grand_oeuvre": {"nom": "Robe du Grand Œuvre", "slot": "robe", "chapitre": 9, "rarete": "Légendaire", "teinte": Color(1.00, 0.74, 0.24), "bonus": "+35 PV"},
	"pierre_philosophale": {"nom": "Pierre philosophale", "slot": "talisman", "chapitre": 9, "rarete": "Légendaire", "teinte": Color(1.00, 0.74, 0.24), "bonus": "+15 % gouttes"},
}

const MULTIPLICATEUR_PUISSANCE := 4.0

static func meilleurs(inventaire: Array[String]) -> Array[String]:
	var resultat: Array[String] = []
	for slot in ["arme", "robe", "talisman"]:
		var meilleur := ""
		for id in inventaire:
			if not OBJETS.has(id) or OBJETS[id]["slot"] != slot:
				continue
			if meilleur.is_empty() or int(OBJETS[id]["chapitre"]) > int(OBJETS[meilleur]["chapitre"]):
				meilleur = id
		if not meilleur.is_empty():
			resultat.append(meilleur)
	return resultat

static func bonus_effectifs(inventaire: Array[String]) -> Dictionary:
	var bonus := {"degats": 0.0, "cadence": 0.0, "pv": 0.0, "vitesse": 0.0, "collecte": 0.0}
	for id in meilleurs(inventaire):
		var texte := str(OBJETS[id]["bonus"])
		var valeur := float(texte.trim_prefix("+").get_slice(" ", 0)) * MULTIPLICATEUR_PUISSANCE
		if "dégâts" in texte:
			bonus["degats"] += valeur / 100.0
		elif "cadence" in texte:
			bonus["cadence"] += valeur / 100.0
		elif "PV" in texte:
			bonus["pv"] += valeur
		elif "vitesse" in texte:
			bonus["vitesse"] += valeur / 100.0
		elif "gouttes" in texte:
			bonus["collecte"] += valeur / 100.0
	return bonus

static func bonus_effectif_texte(id: String) -> String:
	if not OBJETS.has(id):
		return ""
	var texte := str(OBJETS[id]["bonus"])
	var valeur := roundi(float(texte.trim_prefix("+").get_slice(" ", 0)) * MULTIPLICATEUR_PUISSANCE)
	return "+%d%s" % [valeur, texte.substr(texte.find(" "))]

static func du_chapitre(chapitre: int) -> Array[String]:
	var resultat: Array[String] = []
	for id in OBJETS:
		if int(OBJETS[id]["chapitre"]) == chapitre:
			resultat.append(id)
	return resultat

static func manquants(chapitre: int, inventaire: Array[String]) -> Array[String]:
	var resultat := du_chapitre(chapitre)
	resultat = resultat.filter(func(id: String) -> bool: return not id in inventaire)
	return resultat

static func tirer_manquant(chapitre: int, inventaire: Array[String], rng: RandomNumberGenerator) -> String:
	var candidats := manquants(chapitre, inventaire)
	return "" if candidats.is_empty() else candidats[rng.randi_range(0, candidats.size() - 1)]

static func nombre_possede(inventaire: Array[String], id: String) -> int:
	return inventaire.count(id)
