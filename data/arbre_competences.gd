class_name ArbreCompetences
extends RefCounted

const MAX_RANG := 5
const NOEUDS := {
	"vitalite": {"nom": "Vitalité", "description": "+5 PV max/niv.", "cout": 8, "branche": "Défense", "tier": 0},
	"armure": {"nom": "Armure d’encre", "description": "-2 % dégâts reçus/niv.", "cout": 16, "branche": "Défense", "tier": 1, "requis": "vitalite"},
	"regeneration": {"nom": "Régénération", "description": "+5 % aux soins/niv.", "cout": 28, "branche": "Défense", "tier": 2, "requis": "armure"},
	"rempart": {"nom": "Rempart", "description": "+10 PV max/niv.", "cout": 45, "branche": "Défense", "tier": 3, "requis": "regeneration"},
	"puissance": {"nom": "Puissance", "description": "+3 % dégâts/niv.", "cout": 8, "branche": "Offense", "tier": 0},
	"cadence": {"nom": "Cadence", "description": "+2,5 % cadence/niv.", "cout": 16, "branche": "Offense", "tier": 1, "requis": "puissance"},
	"precision": {"nom": "Précision", "description": "+4 % vitesse et portée/niv.", "cout": 28, "branche": "Offense", "tier": 2, "requis": "cadence"},
	"surcharge": {"nom": "Surcharge", "description": "+5 % dégâts/niv.", "cout": 45, "branche": "Offense", "tier": 3, "requis": "precision"},
	"mobilite": {"nom": "Mobilité", "description": "+2,5 % déplacement/niv.", "cout": 8, "branche": "Utilitaire", "tier": 0},
	"collecte": {"nom": "Aimant mystique", "description": "+12 % vitesse de collecte/niv.", "cout": 16, "branche": "Utilitaire", "tier": 1, "requis": "mobilite"},
	"sagesse": {"nom": "Sagesse", "description": "+5 % XP héros/niv.", "cout": 28, "branche": "Utilitaire", "tier": 2, "requis": "collecte"},
	"fortune": {"nom": "Fortune", "description": "+8 % au coffre/niv.", "cout": 45, "branche": "Utilitaire", "tier": 3, "requis": "sagesse"},
}

const BRANCHES := {
	"Défense": ["vitalite", "armure", "regeneration", "rempart"],
	"Offense": ["puissance", "cadence", "precision", "surcharge"],
	"Utilitaire": ["mobilite", "collecte", "sagesse", "fortune"],
}

static func cout(id: String, rang: int) -> int:
	return int(NOEUDS[id]["cout"]) + rang * (4 + int(NOEUDS[id]["tier"]) * 2)

static func prerequis_atteint(id: String, rangs: Dictionary) -> bool:
	var noeud: Dictionary = NOEUDS.get(id, {})
	return not noeud.has("requis") or int(rangs.get(noeud["requis"], 0)) >= MAX_RANG

static func bonus_pv(r: Dictionary) -> float:
	return float(r.get("vitalite", 0)) * 5.0 + float(r.get("rempart", 0)) * 10.0

static func reduction_degats(r: Dictionary) -> float:
	return minf(0.35, float(r.get("armure", 0)) * 0.02)

static func multiplicateur_soin(r: Dictionary) -> float:
	return 1.0 + float(r.get("regeneration", 0)) * 0.05

static func multiplicateur_degats(r: Dictionary) -> float:
	return 1.0 + float(r.get("puissance", 0)) * 0.03 + float(r.get("surcharge", 0)) * 0.05

static func multiplicateur_cadence(r: Dictionary) -> float:
	return 1.0 + float(r.get("cadence", 0)) * 0.025

static func multiplicateur_projectile(r: Dictionary) -> float:
	return 1.0 + float(r.get("precision", 0)) * 0.04

static func multiplicateur_vitesse(r: Dictionary) -> float:
	return 1.0 + float(r.get("mobilite", 0)) * 0.025

static func multiplicateur_collecte(r: Dictionary) -> float:
	return 1.0 + float(r.get("collecte", 0)) * 0.12

static func multiplicateur_experience(r: Dictionary) -> float:
	return 1.0 + float(r.get("sagesse", 0)) * 0.05

static func multiplicateur_coffre(r: Dictionary) -> float:
	return 1.0 + float(r.get("fortune", 0)) * 0.08
