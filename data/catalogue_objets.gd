class_name CatalogueObjets
extends RefCounted

# Un objet precis par chapitre : deux Anneaux puis un Collier dans chaque
# monde. Les anciens ids sont conserves uniquement pour migrer les sauvegardes.
#
# Chaque emplacement porte un profil de statistiques, et la valeur d'un objet
# croit avec le Monde dont il provient. Auparavant les trente objets etaient
# rigoureusement identiques : seul le niveau de Forge comptait, donc trouver
# l'Anneau du Monde X n'apportait rien de plus que celui du Monde I. La Forge
# multiplie desormais le profil de l'objet au lieu de le remplacer.
const PROFILS := [
	{"degats": 0.11, "cadence": 0.010},                   # Anneau I  — offensif
	{"degats": 0.03, "cadence": 0.015, "collecte": 0.05}, # Anneau II — soutien
	{"pv": 0.20, "degats": 0.03},                         # Collier   — defensif
]

const IDS_PAR_MONDE := [
	["plume_encres", "robe_enluminee", "sceau_scribe"],
	["sceptre_braises", "manteau_cendre", "charbon_eternel"],
	["baguette_givre", "cape_givre", "cristal_hiver"],
	["paratonnerre", "habit_orages", "eclair_fiole"],
	["aiguille_venin", "peau_antidote", "crochet_basilic"],
	["diapason_echos", "robe_resonance", "cloche_muette"],
	["lame_ombres", "voile_nocturne", "lune_noire"],
	["burin_runique", "armure_runes", "tablette_ancienne"],
	["orbe_neant", "manteau_vide", "fragment_neant"],
	["alambic_royal", "robe_grand_oeuvre", "pierre_philosophale"],
]

static var OBJETS := _construire()

static func _construire() -> Dictionary:
	var resultat := {}
	for monde in IDS_PAR_MONDE.size():
		var donnees_monde: Dictionary = Chapitres.MONDES[monde]
		for index in 3:
			var slot := "anneau" if index < 2 else "collier"
			var nom_slot := "Anneau %s" % ("I" if index == 0 else "II") if slot == "anneau" else "Collier"
			resultat[IDS_PAR_MONDE[monde][index]] = {
				"nom": "%s · %s" % [nom_slot, donnees_monde["nom"]],
				"slot": slot,
				"monde": monde,
				"chapitre_monde": index + 1,
				"chapitre": monde * 3 + index,
				"profil": PROFILS[index],
				"teinte": donnees_monde["teinte"],
			}
	return resultat

static func du_chapitre(chapitre: int) -> Array[String]:
	var resultat: Array[String] = []
	for id in OBJETS:
		if int(OBJETS[id]["chapitre"]) == chapitre:
			resultat.append(id)
	return resultat

static func objet_du_chapitre(chapitre: int) -> String:
	var candidats := du_chapitre(chapitre)
	return "" if candidats.is_empty() else candidats[0]

static func manquants(chapitre: int, inventaire: Array[String]) -> Array[String]:
	var resultat := du_chapitre(chapitre)
	return resultat.filter(func(id: String) -> bool: return id not in inventaire)

static func tirer_manquant(chapitre: int, inventaire: Array[String], _rng: RandomNumberGenerator) -> String:
	var candidats := manquants(chapitre, inventaire)
	return "" if candidats.is_empty() else candidats[0]

static func compatible(slot: String, id: String) -> bool:
	if not OBJETS.has(id):
		return false
	return (slot in ["anneau_gauche", "anneau_droit"] and OBJETS[id]["slot"] == "anneau") \
		or (slot == "collier" and OBJETS[id]["slot"] == "collier")

# Ce que vaut un objet a un niveau de Forge donne. La Forge multiplie le profil
# plutot que de s'y ajouter : forger un objet tardif rapporte donc davantage que
# forger un objet du premier Monde, ce qui donne enfin un ordre de priorite.
static func bonus_objet(id: String, niveau: int) -> Dictionary:
	var resultat := {}
	if not OBJETS.has(id):
		return resultat
	var donnees: Dictionary = OBJETS[id]
	var facteur := pow(Reglages.OBJET_CROISSANCE_PAR_MONDE, float(int(donnees["monde"]))) \
		* (1.0 + float(maxi(0, niveau)) * Reglages.FORGE_BONUS_PAR_NIVEAU)
	var profil: Dictionary = donnees["profil"]
	for champ in profil:
		resultat[champ] = float(profil[champ]) * facteur
	return resultat

static func bonus_effectifs(equipements: Dictionary, forge_niveaux: Dictionary) -> Dictionary:
	var bonus := {"degats": 0.0, "cadence": 0.0, "pv": 0.0, "vitesse": 0.0, "collecte": 0.0}
	for slot in ["anneau_gauche", "anneau_droit", "collier"]:
		var id := str(equipements.get(slot, ""))
		if not compatible(slot, id):
			continue
		var part := bonus_objet(id, int(forge_niveaux.get(id, 0)))
		for champ in part:
			bonus[champ] = float(bonus.get(champ, 0.0)) + float(part[champ])
	return bonus
