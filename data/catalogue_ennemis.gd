class_name CatalogueEnnemis
extends RefCounted

# Quatre archetypes, chacun posant un probleme different, plus le boss.
# La couleur et la forme sont des donnees : le rendu est dessine, pas importe.
# Contrainte de lisibilite de la spec : le fond est sombre, les menaces claires.

static var TOUS := {
	"encrier_rampant": {
		"nom": "Encrier rampant",
		"pv": 30.0, "vitesse": 150.0, "degats": 8.0, "portee": 60.0,
		"cerveau": "rampant", "couleur": Color(0.70, 0.62, 1.00), "rayon": 30.0,
		"forme": "goutte", "experience": 1, "chance_point": 0.07, "recharge": 1.95, "portee_tir": 680.0,
		"vitesse_projectile": 420.0, "portee_projectile": 780.0, "part_degats_projectile": 0.60,
	},
	"plume_sentinelle": {
		"nom": "Plume-sentinelle",
		"pv": 24.0, "vitesse": 0.0, "degats": 10.0, "portee": 2100.0,
		"cerveau": "sentinelle", "couleur": Color(0.84, 0.78, 1.00), "rayon": 28.0,
		"forme": "plume", "experience": 2, "chance_point": 0.10, "recharge": 1.15, "vitesse_projectile": 620.0,
		"portee_projectile": 2200.0, "telegraphe": 0.40,
		"projectiles": 3, "angle_eventail": 0.30, "part_degats_projectile": 0.72,
	},
	"tache_veloce": {
		"nom": "Tache véloce",
		"pv": 18.0, "vitesse": 640.0, "degats": 12.0, "portee": 70.0,
		"cerveau": "veloce", "couleur": Color(1.00, 0.48, 0.56), "rayon": 26.0,
		"forme": "dard", "experience": 2, "chance_point": 0.10, "preparation": 0.7, "duree_charge": 0.5, "repos": 0.8,
	},
	"scribe_essaimeur": {
		"nom": "Scribe essaimeur",
		"pv": 46.0, "vitesse": 190.0, "degats": 10.0, "portee": 500.0,
		"cerveau": "essaimeur", "couleur": Color(0.54, 1.00, 0.80), "rayon": 38.0,
		"forme": "masque", "experience": 3, "chance_point": 0.16, "recharge": 2.95, "invoque": "encrier_rampant", "nb_invoques": 2, "max_invocations": 6,
		"projectiles_cercle": 7, "vitesse_projectile": 460.0, "portee_projectile": 1000.0,
		"part_degats_projectile": 0.45,
	},
	"la_rature": {
		"nom": "La Rature",
		"pv": 1500.0, "vitesse": 260.0, "degats": 18.0, "portee": 1200.0,
		"cerveau": "boss", "couleur": Color(0.95, 0.55, 0.30), "rayon": 104.0,
		"forme": "correcteur", "experience": 12, "points_garantis": 5, "recharge": 1.2, "vitesse_projectile": 430.0,
	},
	"l_errata": {
		"nom": "La Faute vive",
		"pv": 2400.0, "vitesse": 300.0, "degats": 22.0, "portee": 1300.0,
		"cerveau": "boss", "couleur": Color(0.98, 0.34, 0.46), "rayon": 112.0,
		"forme": "correcteur", "experience": 12, "points_garantis": 5, "recharge": 1.0, "vitesse_projectile": 480.0,
	},
	"le_correcteur": {
		"nom": "Le Correcteur",
		"pv": 900.0, "vitesse": 220.0, "degats": 14.0, "portee": 1200.0,
		"cerveau": "boss", "couleur": Color(0.46, 0.36, 0.78), "rayon": 104.0,
		"forme": "correcteur", "experience": 12, "points_garantis": 5, "recharge": 1.4, "vitesse_projectile": 380.0,
	},
}

static func par_id(id: String) -> Dictionary:
	return TOUS.get(id, {})
