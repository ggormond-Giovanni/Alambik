class_name DetailsReactif
extends RefCounted

# Traduit les donnees de combat en chiffres destines au joueur. Cette couche
# evite d'afficher les noms techniques des mods ("cadence_mult", etc.) dans
# les interfaces et garde les valeurs affichees liees aux reglages reels.

static func lignes(reactif: Reactif, copies := 1) -> Array[String]:
	if reactif == null:
		return []
	var resultat: Array[String] = []
	var poids := _poids_copies(maxi(1, copies))
	var mods := reactif.mods
	_ajouter_multiplicateur(resultat, mods, "degats_mult", "Dégâts", poids)
	_ajouter_multiplicateur(resultat, mods, "cadence_mult", "Cadence de tir", poids)
	_ajouter_multiplicateur(resultat, mods, "vitesse_mult", "Vitesse des projectiles", poids)
	_ajouter_multiplicateur(resultat, mods, "portee_mult", "Portée", poids)
	_ajouter_entier(resultat, mods, "nb_projectiles_add", "projectile", copies)
	_ajouter_entier(resultat, mods, "rebonds_add", "rebond", copies)
	_ajouter_entier(resultat, mods, "perforations_add", "ennemi traversé", copies)
	_ajouter_entier(resultat, mods, "fragments_add", "fragment à l'impact", copies)
	if mods.has("angle_eventail_add"):
		resultat.append("Angle de l’éventail +%s°" % _nombre(rad_to_deg(float(mods["angle_eventail_add"])) * poids))
	if mods.has("ecart_lateral_add"):
		resultat.append("Écart latéral +%s" % _nombre(float(mods["ecart_lateral_add"]) * poids))
	for effet in mods.get("effets", []):
		resultat.append(_detail_effet(effet))
	for drapeau in mods.get("drapeaux", []):
		resultat.append(_detail_drapeau(drapeau))
	return resultat

static func texte(reactif: Reactif, copies := 1) -> String:
	return "\n".join(lignes(reactif, copies))

static func _poids_copies(copies: int) -> float:
	var total := 0.0
	for index in copies:
		total += Mods.rendement(index)
	return total

static func _ajouter_multiplicateur(resultat: Array[String], mods: Dictionary,
		cle: String, nom: String, poids: float) -> void:
	if not mods.has(cle):
		return
	var pourcentage := (float(mods[cle]) - 1.0) * poids * 100.0
	resultat.append("%s %s%s %%" % [nom, "+" if pourcentage >= 0.0 else "", _nombre(pourcentage)])

static func _ajouter_entier(resultat: Array[String], mods: Dictionary,
		cle: String, singulier: String, copies: int) -> void:
	if not mods.has(cle):
		return
	var valeur := int(mods[cle]) * maxi(1, copies)
	resultat.append("+%d %s%s" % [valeur, singulier, "s" if valeur > 1 else ""])

static func _detail_effet(effet: String) -> String:
	match effet:
		"feu": return "Brûlures cumulatives proportionnelles aux dégâts"
		"eau": return "Mouillé : cible ralentie et vulnérable"
		"terre": return "Impact lourd : retarde la prochaine attaque"
		"lumiere": return "Rend une part des dégâts sous forme de vie"
	return effet.capitalize()

static func _detail_drapeau(drapeau: String) -> String:
	match drapeau:
		"rafale": return "Rafale de %d tirs, intervalle %s s" % [Reglages.RAFALE_NOMBRE, _nombre(Reglages.RAFALE_INTERVALLE)]
		"egide": return "Annule la première attaque de chaque salle"
		"regeneration": return "Récupère des PV entre les salles"
		"avidite": return "Augmente l'XP de run et les Gouttes de la tentative"
		"courageux": return "Plus puissant à mesure que les PV diminuent"
		"mannequin": return "Puissance et cadence après une immobilité prolongée"
	return drapeau.replace("_", " ").capitalize()

static func _nombre(valeur: float) -> String:
	if is_equal_approx(valeur, roundf(valeur)):
		return str(roundi(valeur))
	return ("%.2f" % valeur).trim_suffix("0").trim_suffix("0").trim_suffix(".")
