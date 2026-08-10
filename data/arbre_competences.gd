class_name ArbreCompetences
extends RefCounted

# Trois chemins permanents sans rangs repetitifs. Ils ne contiennent que de la
# progression generale; les choix de build et de sorts vivent dans l'arsenal.
const MAX_RANG := 1
const NOEUDS := {
	"force": {"nom": "Force", "description": "+4 % dégâts", "cout": 12, "categorie": "Offensif"},
	"cadence": {"nom": "Cadence", "description": "+4 % cadence de tir", "cout": 18, "categorie": "Offensif", "requis": "force"},
	"precision": {"nom": "Précision", "description": "+5 % vitesse et portée des projectiles", "cout": 25, "categorie": "Offensif", "requis": "cadence"},
	"puissance": {"nom": "Puissance", "description": "+6 % dégâts supplémentaires", "cout": 38, "categorie": "Offensif", "requis": "precision", "fort": true},
	"arsenal": {"nom": "Arsenal", "description": "+6 % cadence supplémentaire", "cout": 52, "categorie": "Offensif", "requis": "puissance"},

	"constitution": {"nom": "Constitution", "description": "+8 PV maximum", "cout": 12, "categorie": "Défensif"},
	"armure": {"nom": "Armure", "description": "-3 % dégâts reçus", "cout": 18, "categorie": "Défensif", "requis": "constitution"},
	"robustesse": {"nom": "Robustesse", "description": "+12 PV maximum supplémentaires", "cout": 26, "categorie": "Défensif", "requis": "armure"},
	"regeneration": {"nom": "Régénération", "description": "+20 % à tous les soins", "cout": 38, "categorie": "Défensif", "requis": "robustesse", "fort": true},
	"rempart": {"nom": "Rempart alchimique", "description": "Un bouclier gratuit par page", "cout": 55, "categorie": "Défensif", "requis": "regeneration"},

	"celerite": {"nom": "Célérité", "description": "+3 % déplacement", "cout": 12, "categorie": "Passif"},
	"sagesse": {"nom": "Sagesse", "description": "+8 % XP permanente", "cout": 18, "categorie": "Passif", "requis": "celerite"},
	"collecte": {"nom": "Collecte", "description": "+15 % points de maîtrise gagnés", "cout": 26, "categorie": "Passif", "requis": "sagesse"},
	"pierre_philosophale": {"nom": "Pierre philosophale", "description": "Soigne 6 % des PV à chaque nouvelle page", "cout": 40, "categorie": "Passif", "requis": "collecte", "fort": true},
	"fortune": {"nom": "Fortune", "description": "+25 % de points dans les coffres de fin", "cout": 54, "categorie": "Passif", "requis": "pierre_philosophale"},
}

const BRANCHES := {
	"Offensif": ["force", "cadence", "precision", "puissance", "arsenal"],
	"Défensif": ["constitution", "armure", "robustesse", "regeneration", "rempart"],
	"Passif": ["celerite", "sagesse", "collecte", "pierre_philosophale", "fortune"],
}

static func cout(id: String, _rang := 0) -> int:
	return int(NOEUDS[id]["cout"])

static func prerequis_atteint(id: String, rangs: Dictionary) -> bool:
	var noeud: Dictionary = NOEUDS.get(id, {})
	return not noeud.has("requis") or int(rangs.get(noeud["requis"], 0)) >= 1

static func _a(r: Dictionary, id: String) -> bool:
	return int(r.get(id, 0)) > 0

static func bonus_pv(r: Dictionary) -> float:
	return (8.0 if _a(r, "constitution") else 0.0) + (12.0 if _a(r, "robustesse") else 0.0)

static func reduction_degats(r: Dictionary) -> float:
	return 0.03 if _a(r, "armure") else 0.0

static func multiplicateur_soin(r: Dictionary) -> float:
	return 1.20 if _a(r, "regeneration") else 1.0

static func soin_par_page(r: Dictionary) -> float:
	return 0.06 if _a(r, "pierre_philosophale") else 0.0

static func donne_bouclier(r: Dictionary) -> bool:
	return _a(r, "rempart")

static func multiplicateur_degats(r: Dictionary) -> float:
	return 1.0 + (0.04 if _a(r, "force") else 0.0) + (0.06 if _a(r, "puissance") else 0.0)

static func multiplicateur_cadence(r: Dictionary) -> float:
	return 1.0 + (0.04 if _a(r, "cadence") else 0.0) + (0.06 if _a(r, "arsenal") else 0.0)

static func multiplicateur_projectile(r: Dictionary) -> float:
	return 1.05 if _a(r, "precision") else 1.0

static func multiplicateur_vitesse(r: Dictionary) -> float:
	return 1.0 + (0.03 if _a(r, "celerite") else 0.0)

static func multiplicateur_collecte(r: Dictionary) -> float:
	return 1.15 if _a(r, "collecte") else 1.0

static func multiplicateur_experience(r: Dictionary) -> float:
	return 1.08 if _a(r, "sagesse") else 1.0

static func multiplicateur_coffre(r: Dictionary) -> float:
	return 1.25 if _a(r, "fortune") else 1.0
