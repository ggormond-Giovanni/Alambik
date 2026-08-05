class_name CatalogueEnnemis
extends RefCounted

# Quatre archetypes, chacun posant un probleme different, plus le boss.
# La couleur et la forme sont des donnees : le rendu est dessine, pas importe.
# Contrainte de lisibilite de la spec : le fond est sombre, les menaces claires.

static var TOUS := {
	"encrier_rampant": {
		"nom": "Encrier rampant",
		"pv": 30.0, "vitesse": 150.0, "degats": 8.0, "portee": 60.0,
		"cerveau": "rampant", "couleur": Color(0.60, 0.50, 0.92), "rayon": 30.0,
		"forme": "goutte",
	},
	"plume_sentinelle": {
		"nom": "Plume-sentinelle",
		"pv": 24.0, "vitesse": 0.0, "degats": 10.0, "portee": 700.0,
		"cerveau": "sentinelle", "couleur": Color(0.74, 0.68, 1.00), "rayon": 28.0,
		"forme": "plume", "recharge": 1.8, "vitesse_projectile": 420.0, "telegraphe": 0.6,
	},
	"tache_veloce": {
		"nom": "Tache véloce",
		"pv": 18.0, "vitesse": 640.0, "degats": 12.0, "portee": 70.0,
		"cerveau": "veloce", "couleur": Color(0.92, 0.38, 0.46), "rayon": 26.0,
		"forme": "dard", "preparation": 0.7, "duree_charge": 0.5, "repos": 0.8,
	},
	"scribe_essaimeur": {
		"nom": "Scribe essaimeur",
		"pv": 46.0, "vitesse": 190.0, "degats": 0.0, "portee": 500.0,
		"cerveau": "essaimeur", "couleur": Color(0.44, 0.94, 0.74), "rayon": 38.0,
		"forme": "masque", "recharge": 3.5, "invoque": "encrier_rampant", "nb_invoques": 2, "max_invocations": 6,
	},
	"le_correcteur": {
		"nom": "Le Correcteur",
		"pv": 900.0, "vitesse": 220.0, "degats": 14.0, "portee": 1200.0,
		"cerveau": "boss", "couleur": Color(0.46, 0.36, 0.78), "rayon": 104.0,
		"forme": "correcteur", "recharge": 1.4, "vitesse_projectile": 380.0,
	},
}

static func par_id(id: String) -> Dictionary:
	return TOUS.get(id, {})
