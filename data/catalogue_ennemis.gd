class_name CatalogueEnnemis
extends RefCounted

# Onze creatures communes, dix miniboss de palier et dix boss signatures.
# Les profils de motifs vivent avec leurs statistiques : ajouter une identite
# majeure ne demande pas de modifier le moteur de Boss.

static var TOUS := _construire()

static func _construire() -> Dictionary:
	var tous := {
		"encrier_rampant": {
			"nom": "Encrier rampant",
			"pv": 30.0, "vitesse": 150.0, "degats": 8.0, "portee": 60.0,
			"cerveau": "rampant", "couleur": Color(0.70, 0.62, 1.00), "rayon": 30.0,
			"forme": "goutte", "experience": 1, "recharge": 1.95, "portee_tir": 680.0,
			"vitesse_projectile": 420.0, "portee_projectile": 780.0, "part_degats_projectile": 0.60,
		},
		"plume_sentinelle": {
			"nom": "Plume-sentinelle",
			"pv": 24.0, "vitesse": 0.0, "degats": 10.0, "portee": 2100.0,
			"cerveau": "sentinelle", "couleur": Color(0.84, 0.78, 1.00), "rayon": 28.0,
			"forme": "plume", "experience": 2, "recharge": 1.15, "vitesse_projectile": 620.0,
			"portee_projectile": 2200.0, "telegraphe": 0.40,
			"projectiles": 3, "angle_eventail": 0.30, "part_degats_projectile": 0.72,
		},
		"tache_veloce": {
			"nom": "Tache véloce",
			"pv": 18.0, "vitesse": 640.0, "degats": 12.0, "portee": 70.0,
			"cerveau": "veloce", "couleur": Color(1.00, 0.48, 0.56), "rayon": 26.0,
			"forme": "dard", "experience": 2, "preparation": 0.7, "duree_charge": 0.5, "repos": 0.8,
			"distance_charge": 900.0, "vitesse_approche_mult": 0.45,
		},
		"scribe_essaimeur": {
			"nom": "Scribe essaimeur",
			"pv": 46.0, "vitesse": 190.0, "degats": 10.0, "portee": 500.0,
			"cerveau": "essaimeur", "couleur": Color(0.54, 1.00, 0.80), "rayon": 38.0,
			"forme": "masque", "experience": 3, "recharge": 2.95,
			"invoque": "encrier_rampant", "nb_invoques": 2, "max_invocations": 6,
			"projectiles_cercle": 7, "vitesse_projectile": 460.0, "portee_projectile": 1000.0,
			"part_degats_projectile": 0.45,
		},
		"folio_orbiteur": {
			"nom": "Folio orbiteur",
			"pv": 28.0, "vitesse": 255.0, "degats": 9.0, "portee": 430.0,
			"cerveau": "orbiteur", "couleur": Color(0.32, 0.84, 1.00), "rayon": 27.0,
			"forme": "orbite", "experience": 2, "recharge": 1.65,
			"vitesse_projectile": 500.0, "portee_projectile": 1300.0,
			"part_degats_projectile": 0.62, "sens_orbite": 1.0,
		},
		"sceau_belier": {
			"nom": "Sceau-bélier",
			"pv": 58.0, "vitesse": 500.0, "degats": 16.0, "portee": 82.0,
			"cerveau": "veloce", "couleur": Color(0.96, 0.68, 0.28), "rayon": 40.0,
			"forme": "belier", "experience": 3, "preparation": 1.05,
			"duree_charge": 0.58, "repos": 1.25, "distance_charge": 780.0,
			"vitesse_approche_mult": 0.30,
		},
		"marge_harceleuse": {
			"nom": "Marge harceleuse",
			"pv": 34.0, "vitesse": 285.0, "degats": 9.0, "portee": 620.0,
			"cerveau": "harceleur", "couleur": Color(1.00, 0.42, 0.72), "rayon": 29.0,
			"forme": "ruban", "experience": 3, "recharge": 1.45, "telegraphe": 0.48,
			"vitesse_projectile": 560.0, "portee_projectile": 1700.0,
			"projectiles": 2, "angle_eventail": 0.18, "part_degats_projectile": 0.58,
		},
		"miroir_encre": {
			"nom": "Miroir d’encre",
			"pv": 52.0, "vitesse": 175.0, "degats": 11.0, "portee": 520.0,
			"cerveau": "miroir", "couleur": Color(0.54, 0.92, 0.78), "rayon": 36.0,
			"forme": "miroir", "experience": 4, "recharge": 2.35, "telegraphe": 0.65,
			"projectiles_cercle": 8, "vitesse_projectile": 390.0,
			"portee_projectile": 1200.0, "part_degats_projectile": 0.52,
		},
		"cachet_phaseur": {
			"nom": "Cachet phaseur",
			"pv": 38.0, "vitesse": 230.0, "degats": 12.0, "portee": 470.0,
			"cerveau": "phaseur", "couleur": Color(0.66, 0.48, 1.00), "rayon": 31.0,
			"forme": "phaseur", "dessin_procedural": true, "experience": 3,
			"recharge": 2.55, "telegraphe": 0.62, "projectiles_cercle": 6,
			"vitesse_projectile": 520.0, "portee_projectile": 1450.0,
			"part_degats_projectile": 0.56,
		},
		"fuseau_tisseur": {
			"nom": "Fuseau tisseur",
			"pv": 42.0, "vitesse": 245.0, "degats": 10.0, "portee": 560.0,
			"cerveau": "tisseur", "couleur": Color(0.30, 0.92, 0.86), "rayon": 33.0,
			"forme": "fuseau", "dessin_procedural": true, "experience": 3,
			"recharge": 1.85, "telegraphe": 0.52, "projectiles": 3,
			"angle_eventail": 0.0, "ecart_lateral": 82.0, "vitesse_projectile": 470.0,
			"portee_projectile": 1500.0, "part_degats_projectile": 0.62,
		},
		"fiole_volatile": {
			"nom": "Fiole volatile",
			"pv": 26.0, "vitesse": 205.0, "degats": 15.0, "portee": 205.0,
			"cerveau": "volatile", "couleur": Color(0.92, 0.82, 0.26), "rayon": 29.0,
			"forme": "fiole", "dessin_procedural": true, "experience": 2,
			"preparation": 0.88, "rayon_explosion": 205.0, "projectiles_cercle": 9,
			"vitesse_projectile": 360.0, "portee_projectile": 720.0,
			"part_degats_projectile": 0.45,
		},
	}

	var miniboss := [
		["la_rature", "La Rature", 270.0, 260.0, 18.0, Color(0.95, 0.55, 0.30), 0,
			["griffure", "charge", "pause"], ["griffure", "barrage_croise", "charge", "pause"]],
		["l_errata", "La Faute vive", 280.0, 285.0, 19.0, Color(0.98, 0.34, 0.46), 1,
			["echo_errata", "invocation", "pause"], ["echo_errata", "eventail_lent", "invocation", "pause"]],
		["le_correcteur", "Le Correcteur", 300.0, 220.0, 15.0, Color(0.46, 0.36, 0.78), 2,
			["quadrillage", "eventail_lent", "pause"], ["quadrillage", "barrage_croise", "charge", "pause"]],
		["reliure_affamee", "La Reliure affamée", 285.0, 245.0, 18.0, Color(0.66, 0.28, 0.76), 3,
			["machoire", "charge", "pause"], ["machoire", "invocation", "poursuite", "charge", "pause"]],
		["virgule_noire", "La Virgule noire", 260.0, 300.0, 17.0, Color(0.38, 0.72, 0.92), 4,
			["calligraphie", "eventail_lent", "pause"], ["calligraphie", "anneau_breche", "spirale", "pause"]],
		["index_brise", "L’Index brisé", 320.0, 235.0, 20.0, Color(0.90, 0.68, 0.26), 5,
			["indexation", "pluie", "pause"], ["indexation", "charge", "pluie", "pause"]],
		["marge_hurlante", "La Marge hurlante", 275.0, 275.0, 18.0, Color(0.42, 0.92, 0.64), 6,
			["onde_marge", "invocation", "pause"], ["onde_marge", "eventail_lent", "anneau_breche", "pause"]],
		["enlumineur_fou", "L’Enlumineur fou", 305.0, 230.0, 19.0, Color(1.00, 0.78, 0.36), 7,
			["rosace", "spirale", "pause"], ["rosace", "pluie", "barrage_croise", "pause"]],
		["signet_sanglant", "Le Signet sanglant", 295.0, 310.0, 21.0, Color(0.86, 0.18, 0.34), 8,
			["estampille", "charge", "pause"], ["estampille", "charge", "anneau_breche", "pause"]],
		["copiste_aveugle", "Le Copiste aveugle", 330.0, 210.0, 16.0, Color(0.74, 0.70, 0.96), 9,
			["copie_double", "pluie", "pause"], ["copie_double", "invocation", "spirale", "poursuite", "pause"]],
	]
	for definition in miniboss:
		tous[definition[0]] = _creer_boss(definition, "miniboss")

	var signatures := [
		["archiscribe_encres", "L’Archiscribe des Encres", 360.0, 235.0, 18.0, Color(0.62, 0.50, 0.96), 0,
			["barrage_horizontal", "pluie", "poursuite", "pause"], ["spirale", "invocation", "barrage_croise", "pause"]],
		["roi_braises", "Le Roi des Braises", 380.0, 295.0, 22.0, Color(1.00, 0.38, 0.14), 1,
			["charge", "spirale", "poursuite", "pause"], ["anneau_breche", "charge", "pluie", "pause"]],
		["reine_givre", "La Reine du Givre", 400.0, 215.0, 19.0, Color(0.42, 0.82, 1.00), 2,
			["pluie", "eventail_lent", "anneau_breche", "pause"], ["barrage_croise", "pluie", "poursuite", "pause"]],
		["maitre_orages", "Le Maître des Orages", 390.0, 270.0, 23.0, Color(0.98, 0.88, 0.28), 3,
			["spirale", "barrage_croise", "pause"], ["poursuite", "anneau_breche", "spirale", "pause"]],
		["hydre_venins", "L’Hydre des Venins", 420.0, 225.0, 21.0, Color(0.48, 0.92, 0.30), 4,
			["invocation", "eventail_lent", "pluie", "pause"], ["anneau_breche", "invocation", "poursuite", "pause"]],
		["choeur_infini", "Le Chœur infini", 410.0, 250.0, 22.0, Color(0.72, 0.52, 1.00), 5,
			["poursuite", "barrage_horizontal", "spirale", "pause"], ["barrage_croise", "poursuite", "anneau_breche", "pause"]],
		["souverain_ombres", "Le Souverain des Ombres", 440.0, 285.0, 24.0, Color(0.42, 0.24, 0.62), 6,
			["charge", "pluie", "invocation", "pause"], ["spirale", "charge", "anneau_breche", "pause"]],
		["gardien_runes", "Le Gardien des Runes", 460.0, 205.0, 23.0, Color(0.24, 0.88, 0.70), 7,
			["anneau_breche", "barrage_horizontal", "eventail_lent", "pause"], ["pluie", "barrage_croise", "invocation", "pause"]],
		["devoreur_neant", "Le Dévoreur du Néant", 490.0, 275.0, 25.0, Color(0.76, 0.24, 0.82), 8,
			["spirale", "poursuite", "charge", "pause"], ["invocation", "anneau_breche", "barrage_croise", "pause"]],
		["grand_alambic", "Le Grand Alambic", 520.0, 240.0, 25.0, Color(1.00, 0.70, 0.20), 9,
			["pluie", "spirale", "anneau_breche", "pause"], ["charge", "poursuite", "invocation", "barrage_croise", "pause"]],
	]
	for definition in signatures:
		tous[definition[0]] = _creer_boss(definition, "signature")
	return tous

static func _creer_boss(definition: Array, rang: String) -> Dictionary:
	var profil := {
		"nom": definition[1],
		"pv": definition[2], "vitesse": definition[3], "degats": definition[4], "portee": 1400.0,
		"cerveau": "boss", "rang_boss": rang, "couleur": definition[5],
		"rayon": 104.0 + float(int(definition[6]) % 3) * 5.0,
		"forme": "correcteur", "ornement": definition[6],
		"experience": 12 if rang == "miniboss" else 25,
		"recharge": 1.2, "vitesse_projectile": 400.0 + float(int(definition[6]) % 4) * 25.0,
		"motifs_phase_1": definition[7], "motifs_phase_2": definition[8],
		"nb_invocations_boss": 3 if rang == "miniboss" else 4,
	}
	if rang == "miniboss":
		var silhouettes := ["rature", "errata", "correcteur", "reliure", "virgule",
			"index", "marge", "enlumineur", "signet", "copiste"]
		profil["silhouette"] = silhouettes[posmod(int(definition[6]), silhouettes.size())]
	return profil

static func par_id(id: String) -> Dictionary:
	return TOUS.get(id, {})

static func ids_miniboss() -> Array[String]:
	return _ids_boss_de_rang("miniboss")

static func ids_boss_signatures() -> Array[String]:
	return _ids_boss_de_rang("signature")

static func _ids_boss_de_rang(rang: String) -> Array[String]:
	var resultat: Array[String] = []
	for id in TOUS:
		if TOUS[id].get("rang_boss", "") == rang:
			resultat.append(id)
	resultat.sort()
	return resultat
