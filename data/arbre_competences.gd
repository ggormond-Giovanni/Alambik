class_name ArbreCompetences
extends RefCounted

# Trois chemins permanents sans rangs repetitifs. Ils ne contiennent que de la
# progression generale; les choix de build et de sorts vivent dans l'arsenal.
const MAX_RANG := 1
const MULTIPLICATEUR_COUT := 4.0
const FACTEURS_EFFET := {
	"degats": 3.0, "cadence": 3.0, "projectile": 3.0,
	"pv": 4.0, "reduction": 2.0, "soin": 3.0, "soin_page": 2.0,
	"vitesse": 3.0, "experience": 2.0, "collecte": 2.0, "coffre": 2.0,
}
const NOEUDS := {
	"force": {"nom": "Force", "description": "+4 % dégâts", "cout": 12, "categorie": "Offensif", "degats": 0.04},
	"cadence": {"nom": "Cadence", "description": "+4 % cadence de tir", "cout": 18, "categorie": "Offensif", "requis": "force", "cadence": 0.04},
	"precision": {"nom": "Précision", "description": "+5 % vitesse et portée des projectiles", "cout": 25, "categorie": "Offensif", "requis": "cadence", "projectile": 0.05},
	"puissance": {"nom": "Puissance", "description": "+6 % dégâts supplémentaires", "cout": 38, "categorie": "Offensif", "requis": "precision", "fort": true, "degats": 0.06},
	"arsenal": {"nom": "Arsenal", "description": "+6 % cadence supplémentaire", "cout": 52, "categorie": "Offensif", "requis": "puissance", "cadence": 0.06},
	"impact": {"nom": "Impact", "description": "+3 % dégâts", "cout": 70, "categorie": "Offensif", "requis": "arsenal", "degats": 0.03},
	"vivacite": {"nom": "Vivacité", "description": "+3 % cadence de tir", "cout": 88, "categorie": "Offensif", "requis": "impact", "cadence": 0.03},
	"trajectoire": {"nom": "Trajectoire", "description": "+4 % vitesse et portée des projectiles", "cout": 108, "categorie": "Offensif", "requis": "vivacite", "projectile": 0.04},
	"combustion": {"nom": "Combustion", "description": "+4 % dégâts", "cout": 130, "categorie": "Offensif", "requis": "trajectoire", "degats": 0.04},
	"rythme": {"nom": "Rythme de guerre", "description": "+4 % cadence de tir", "cout": 155, "categorie": "Offensif", "requis": "combustion", "fort": true, "cadence": 0.04},
	"transpercement": {"nom": "Transpercement", "description": "+5 % vitesse et portée des projectiles", "cout": 183, "categorie": "Offensif", "requis": "rythme", "projectile": 0.05},
	"catalyse": {"nom": "Catalyse", "description": "+5 % dégâts", "cout": 214, "categorie": "Offensif", "requis": "transpercement", "degats": 0.05},
	"pluie_arcanique": {"nom": "Pluie arcanique", "description": "+5 % cadence de tir", "cout": 248, "categorie": "Offensif", "requis": "catalyse", "cadence": 0.05},
	"visee_absolue": {"nom": "Visée absolue", "description": "+5 % vitesse et portée des projectiles", "cout": 285, "categorie": "Offensif", "requis": "pluie_arcanique", "projectile": 0.05},
	"domination": {"nom": "Domination", "description": "+6 % dégâts", "cout": 325, "categorie": "Offensif", "requis": "visee_absolue", "fort": true, "degats": 0.06},
	"tempete": {"nom": "Tempête", "description": "+6 % cadence de tir", "cout": 368, "categorie": "Offensif", "requis": "domination", "cadence": 0.06},
	"horizon": {"nom": "Horizon", "description": "+6 % vitesse et portée des projectiles", "cout": 414, "categorie": "Offensif", "requis": "tempete", "projectile": 0.06},
	"quintessence": {"nom": "Quintessence", "description": "+7 % dégâts", "cout": 463, "categorie": "Offensif", "requis": "horizon", "degats": 0.07},
	"deluge": {"nom": "Déluge", "description": "+7 % cadence de tir", "cout": 515, "categorie": "Offensif", "requis": "quintessence", "cadence": 0.07},
	"grand_arcane": {"nom": "Grand arcane", "description": "+8 % dégâts", "cout": 570, "categorie": "Offensif", "requis": "deluge", "fort": true, "degats": 0.08},

	"constitution": {"nom": "Constitution", "description": "+8 PV maximum", "cout": 12, "categorie": "Défensif", "pv": 8.0},
	"armure": {"nom": "Armure", "description": "-3 % dégâts reçus", "cout": 18, "categorie": "Défensif", "requis": "constitution", "reduction": 0.03},
	"robustesse": {"nom": "Robustesse", "description": "+12 PV maximum supplémentaires", "cout": 26, "categorie": "Défensif", "requis": "armure", "pv": 12.0},
	"regeneration": {"nom": "Régénération", "description": "+20 % à tous les soins", "cout": 38, "categorie": "Défensif", "requis": "robustesse", "fort": true, "soin": 0.20},
	"rempart": {"nom": "Rempart alchimique", "description": "Un bouclier gratuit par page", "cout": 55, "categorie": "Défensif", "requis": "regeneration", "bouclier": true},
	"vitalite": {"nom": "Vitalité", "description": "+10 PV maximum", "cout": 70, "categorie": "Défensif", "requis": "rempart", "pv": 10.0},
	"garde": {"nom": "Garde", "description": "-2 % dégâts reçus", "cout": 88, "categorie": "Défensif", "requis": "vitalite", "reduction": 0.02},
	"baume": {"nom": "Baume", "description": "+10 % à tous les soins", "cout": 108, "categorie": "Défensif", "requis": "garde", "soin": 0.10},
	"refuge": {"nom": "Refuge", "description": "+12 PV maximum", "cout": 130, "categorie": "Défensif", "requis": "baume", "pv": 12.0},
	"carapace": {"nom": "Carapace", "description": "-2 % dégâts reçus", "cout": 155, "categorie": "Défensif", "requis": "refuge", "fort": true, "reduction": 0.02},
	"source": {"nom": "Source", "description": "Soigne 2 % des PV à chaque page", "cout": 183, "categorie": "Défensif", "requis": "carapace", "soin_page": 0.02},
	"endurance": {"nom": "Endurance", "description": "+15 PV maximum", "cout": 214, "categorie": "Défensif", "requis": "source", "pv": 15.0},
	"egide": {"nom": "Égide", "description": "-3 % dégâts reçus", "cout": 248, "categorie": "Défensif", "requis": "endurance", "reduction": 0.03},
	"fontaine": {"nom": "Fontaine", "description": "+10 % à tous les soins", "cout": 285, "categorie": "Défensif", "requis": "egide", "soin": 0.10},
	"bastion": {"nom": "Bastion", "description": "+18 PV maximum", "cout": 325, "categorie": "Défensif", "requis": "fontaine", "fort": true, "pv": 18.0},
	"inviolable": {"nom": "Inviolable", "description": "-3 % dégâts reçus", "cout": 368, "categorie": "Défensif", "requis": "bastion", "reduction": 0.03},
	"renaissance": {"nom": "Renaissance", "description": "Soigne 2 % des PV à chaque page", "cout": 414, "categorie": "Défensif", "requis": "inviolable", "soin_page": 0.02},
	"colosse": {"nom": "Colosse", "description": "+20 PV maximum", "cout": 463, "categorie": "Défensif", "requis": "renaissance", "pv": 20.0},
	"sanctuaire": {"nom": "Sanctuaire", "description": "-4 % dégâts reçus", "cout": 515, "categorie": "Défensif", "requis": "colosse", "reduction": 0.04},
	"immortel": {"nom": "Immortel", "description": "+25 PV maximum", "cout": 570, "categorie": "Défensif", "requis": "sanctuaire", "fort": true, "pv": 25.0},

	"celerite": {"nom": "Célérité", "description": "+3 % déplacement", "cout": 12, "categorie": "Passif", "vitesse": 0.03},
	"sagesse": {"nom": "Sagesse", "description": "+8 % XP permanente", "cout": 18, "categorie": "Passif", "requis": "celerite", "experience": 0.08},
	"collecte": {"nom": "Collecte", "description": "+15 % gouttes gagnées", "cout": 26, "categorie": "Passif", "requis": "sagesse", "collecte": 0.15},
	"pierre_philosophale": {"nom": "Pierre philosophale", "description": "Soigne 6 % des PV à chaque nouvelle page", "cout": 40, "categorie": "Passif", "requis": "collecte", "fort": true, "soin_page": 0.06},
	"fortune": {"nom": "Fortune", "description": "+25 % de gouttes dans les coffres de fin", "cout": 54, "categorie": "Passif", "requis": "pierre_philosophale", "coffre": 0.25},
	"elan": {"nom": "Élan", "description": "+2 % déplacement", "cout": 70, "categorie": "Passif", "requis": "fortune", "vitesse": 0.02},
	"etude": {"nom": "Étude", "description": "+5 % XP permanente", "cout": 88, "categorie": "Passif", "requis": "elan", "experience": 0.05},
	"butin": {"nom": "Butin", "description": "+8 % gouttes gagnées", "cout": 108, "categorie": "Passif", "requis": "etude", "collecte": 0.08},
	"chance": {"nom": "Chance", "description": "+10 % de gouttes dans les coffres", "cout": 130, "categorie": "Passif", "requis": "butin", "coffre": 0.10},
	"souffle": {"nom": "Souffle", "description": "+2 % déplacement", "cout": 155, "categorie": "Passif", "requis": "chance", "fort": true, "vitesse": 0.02},
	"memoire": {"nom": "Mémoire", "description": "+5 % XP permanente", "cout": 183, "categorie": "Passif", "requis": "souffle", "experience": 0.05},
	"magnetisme": {"nom": "Magnétisme", "description": "+8 % gouttes gagnées", "cout": 214, "categorie": "Passif", "requis": "memoire", "collecte": 0.08},
	"abondance": {"nom": "Abondance", "description": "+10 % de gouttes dans les coffres", "cout": 248, "categorie": "Passif", "requis": "magnetisme", "coffre": 0.10},
	"foulee": {"nom": "Foulée", "description": "+3 % déplacement", "cout": 285, "categorie": "Passif", "requis": "abondance", "vitesse": 0.03},
	"savoir": {"nom": "Savoir", "description": "+6 % XP permanente", "cout": 325, "categorie": "Passif", "requis": "foulee", "fort": true, "experience": 0.06},
	"moisson": {"nom": "Moisson", "description": "+10 % gouttes gagnées", "cout": 368, "categorie": "Passif", "requis": "savoir", "collecte": 0.10},
	"tresor": {"nom": "Trésor", "description": "+15 % de gouttes dans les coffres", "cout": 414, "categorie": "Passif", "requis": "moisson", "coffre": 0.15},
	"transcendance": {"nom": "Transcendance", "description": "+4 % déplacement", "cout": 463, "categorie": "Passif", "requis": "tresor", "vitesse": 0.04},
	"illumination": {"nom": "Illumination", "description": "+8 % XP permanente", "cout": 515, "categorie": "Passif", "requis": "transcendance", "experience": 0.08},
	"legende": {"nom": "Légende", "description": "+15 % gouttes gagnées", "cout": 570, "categorie": "Passif", "requis": "illumination", "fort": true, "collecte": 0.15},
}

const BRANCHES := {
	"Offensif": ["force", "cadence", "precision", "puissance", "arsenal", "impact", "vivacite", "trajectoire", "combustion", "rythme", "transpercement", "catalyse", "pluie_arcanique", "visee_absolue", "domination", "tempete", "horizon", "quintessence", "deluge", "grand_arcane"],
	"Défensif": ["constitution", "armure", "robustesse", "regeneration", "rempart", "vitalite", "garde", "baume", "refuge", "carapace", "source", "endurance", "egide", "fontaine", "bastion", "inviolable", "renaissance", "colosse", "sanctuaire", "immortel"],
	"Passif": ["celerite", "sagesse", "collecte", "pierre_philosophale", "fortune", "elan", "etude", "butin", "chance", "souffle", "memoire", "magnetisme", "abondance", "foulee", "savoir", "moisson", "tresor", "transcendance", "illumination", "legende"],
}

static func cout(id: String, _rang := 0) -> int:
	return roundi(float(NOEUDS[id]["cout"]) * MULTIPLICATEUR_COUT)

static func prerequis_atteint(id: String, rangs: Dictionary) -> bool:
	var noeud: Dictionary = NOEUDS.get(id, {})
	return not noeud.has("requis") or int(rangs.get(noeud["requis"], 0)) >= 1

static func _a(r: Dictionary, id: String) -> bool:
	return int(r.get(id, 0)) > 0

static func _somme(r: Dictionary, champ: String) -> float:
	var total := 0.0
	for id in r:
		if int(r[id]) > 0 and NOEUDS.has(id):
			total += float(NOEUDS[id].get(champ, 0.0)) * float(FACTEURS_EFFET.get(champ, 1.0))
	return total

static func description_effective(id: String) -> String:
	var n: Dictionary = NOEUDS[id]
	if bool(n.get("bouclier", false)):
		return "Un bouclier gratuit au début de chaque page"
	for champ in ["degats", "cadence", "projectile", "reduction", "soin", "soin_page", "vitesse", "experience", "collecte", "coffre"]:
		if n.has(champ):
			var valeur := roundi(float(n[champ]) * float(FACTEURS_EFFET.get(champ, 1.0)) * 100.0)
			match champ:
				"degats": return "+%d %% dégâts" % valeur
				"cadence": return "+%d %% cadence de tir" % valeur
				"projectile": return "+%d %% vitesse et portée des projectiles" % valeur
				"reduction": return "-%d %% dégâts reçus" % valeur
				"soin": return "+%d %% à tous les soins" % valeur
				"soin_page": return "Soigne %d %% des PV à chaque page" % valeur
				"vitesse": return "+%d %% vitesse de déplacement" % valeur
				"experience": return "+%d %% XP permanente" % valeur
				"collecte": return "+%d %% gouttes gagnées" % valeur
				"coffre": return "+%d %% gouttes dans les coffres" % valeur
	if n.has("pv"):
		return "+%d PV maximum" % roundi(float(n["pv"]) * float(FACTEURS_EFFET["pv"]))
	return str(n["description"])

static func bonus_pv(r: Dictionary) -> float:
	return _somme(r, "pv")

static func reduction_degats(r: Dictionary) -> float:
	return clampf(_somme(r, "reduction"), 0.0, 0.60)

static func multiplicateur_soin(r: Dictionary) -> float:
	return 1.0 + _somme(r, "soin")

static func soin_par_page(r: Dictionary) -> float:
	return _somme(r, "soin_page")

static func donne_bouclier(r: Dictionary) -> bool:
	for id in r:
		if int(r[id]) > 0 and NOEUDS.has(id) and bool(NOEUDS[id].get("bouclier", false)):
			return true
	return false

static func multiplicateur_degats(r: Dictionary) -> float:
	return 1.0 + _somme(r, "degats")

static func multiplicateur_cadence(r: Dictionary) -> float:
	return 1.0 + _somme(r, "cadence")

static func multiplicateur_projectile(r: Dictionary) -> float:
	return 1.0 + _somme(r, "projectile")

static func multiplicateur_vitesse(r: Dictionary) -> float:
	return 1.0 + _somme(r, "vitesse")

static func multiplicateur_collecte(r: Dictionary) -> float:
	return 1.0 + _somme(r, "collecte")

static func multiplicateur_experience(r: Dictionary) -> float:
	return 1.0 + _somme(r, "experience")

static func multiplicateur_coffre(r: Dictionary) -> float:
	return 1.0 + _somme(r, "coffre")
