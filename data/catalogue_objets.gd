class_name CatalogueObjets
extends RefCounted

# Un objet precis par chapitre : deux Anneaux puis un Collier dans chaque
# monde. Les anciens ids sont conserves uniquement pour migrer les sauvegardes.
# Les effets speciaux restent volontairement absents tant que leur pool n'est
# pas concu dans le document de design.

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

static func bonus_effectifs(equipements: Dictionary, forge_niveaux: Dictionary) -> Dictionary:
	var bonus := {"degats": 0.0, "cadence": 0.0, "pv": 0.0, "vitesse": 0.0, "collecte": 0.0}
	for slot in ["anneau_gauche", "anneau_droit", "collier"]:
		if not compatible(slot, str(equipements.get(slot, ""))):
			continue
		var niveau := maxi(0, int(forge_niveaux.get(slot, 0)))
		bonus["degats"] += float(niveau) * Reglages.FORGE_DEGATS_PAR_NIVEAU
		bonus["pv"] += float(niveau) * Reglages.FORGE_PV_PAR_NIVEAU
	return bonus
