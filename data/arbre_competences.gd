class_name ArbreCompetences
extends RefCounted

# Premier arbre long volontairement genereux. Chaque branche accompagne dix
# paliers de campagne et pourra etre retouchee sans changer la logique.
const MAX_RANG := 1
const NOEUDS := {
	"force": {"nom": "Force", "description": "+12 % dégâts", "cout": Reglages.MAITRISE_COUTS[0], "categorie": "Offensif", "degats": 0.12},
	"cadence": {"nom": "Cadence", "description": "+10 % cadence", "cout": Reglages.MAITRISE_COUTS[1], "categorie": "Offensif", "requis": "force", "cadence": 0.10},
	"precision": {"nom": "Précision", "description": "+15 % vitesse et portée des tirs", "cout": Reglages.MAITRISE_COUTS[2], "categorie": "Offensif", "requis": "cadence", "projectile": 0.15},
	"puissance": {"nom": "Puissance", "description": "+25 % dégâts", "cout": Reglages.MAITRISE_COUTS[3], "categorie": "Offensif", "requis": "precision", "degats": 0.25, "fort": true},
	"rythme": {"nom": "Rythme de guerre", "description": "+15 % cadence", "cout": Reglages.MAITRISE_COUTS[4], "categorie": "Offensif", "requis": "puissance", "cadence": 0.15},
	"catalyse": {"nom": "Catalyse", "description": "+45 % dégâts", "cout": Reglages.MAITRISE_COUTS[5], "categorie": "Offensif", "requis": "rythme", "degats": 0.45},
	"trajectoire": {"nom": "Trajectoire absolue", "description": "+25 % vitesse et portée des tirs", "cout": Reglages.MAITRISE_COUTS[6], "categorie": "Offensif", "requis": "catalyse", "projectile": 0.25},
	"tempete": {"nom": "Tempête", "description": "+30 % cadence", "cout": Reglages.MAITRISE_COUTS[7], "categorie": "Offensif", "requis": "trajectoire", "cadence": 0.30, "fort": true},
	"domination": {"nom": "Domination", "description": "+100 % dégâts", "cout": Reglages.MAITRISE_COUTS[8], "categorie": "Offensif", "requis": "tempete", "degats": 1.00},
	"grand_oeuvre": {"nom": "Grand Œuvre", "description": "+250 % dégâts", "cout": Reglages.MAITRISE_COUTS[9], "categorie": "Offensif", "requis": "domination", "degats": 2.50, "fort": true},

	"constitution": {"nom": "Constitution", "description": "+15 % PV maximum", "cout": Reglages.MAITRISE_COUTS[0], "categorie": "Défensif", "pv_mult": 0.15},
	"armure": {"nom": "Armure", "description": "-4 % dégâts reçus", "cout": Reglages.MAITRISE_COUTS[1], "categorie": "Défensif", "requis": "constitution", "reduction": 0.04},
	"vitalite": {"nom": "Vitalité", "description": "+25 % PV maximum", "cout": Reglages.MAITRISE_COUTS[2], "categorie": "Défensif", "requis": "armure", "pv_mult": 0.25},
	"rempart": {"nom": "Rempart", "description": "-5 % dégâts reçus", "cout": Reglages.MAITRISE_COUTS[3], "categorie": "Défensif", "requis": "vitalite", "reduction": 0.05, "fort": true},
	"robustesse": {"nom": "Robustesse", "description": "+40 % PV maximum", "cout": Reglages.MAITRISE_COUTS[4], "categorie": "Défensif", "requis": "rempart", "pv_mult": 0.40},
	"carapace": {"nom": "Carapace", "description": "-7 % dégâts reçus", "cout": Reglages.MAITRISE_COUTS[5], "categorie": "Défensif", "requis": "robustesse", "reduction": 0.07},
	"endurance": {"nom": "Endurance", "description": "+75 % PV maximum", "cout": Reglages.MAITRISE_COUTS[6], "categorie": "Défensif", "requis": "carapace", "pv_mult": 0.75},
	"bastion": {"nom": "Bastion", "description": "-9 % dégâts reçus", "cout": Reglages.MAITRISE_COUTS[7], "categorie": "Défensif", "requis": "endurance", "reduction": 0.09, "fort": true},
	"colosse": {"nom": "Colosse", "description": "+125 % PV maximum", "cout": Reglages.MAITRISE_COUTS[8], "categorie": "Défensif", "requis": "bastion", "pv_mult": 1.25},
	"immortel": {"nom": "Immortel", "description": "-12 % dégâts reçus", "cout": Reglages.MAITRISE_COUTS[9], "categorie": "Défensif", "requis": "colosse", "reduction": 0.12, "fort": true},

	"celerite": {"nom": "Célérité", "description": "+5 % déplacement", "cout": Reglages.MAITRISE_COUTS[0], "categorie": "Utilitaire", "vitesse": 0.05},
	"collecte": {"nom": "Collecte", "description": "+20 % Gouttes", "cout": Reglages.MAITRISE_COUTS[1], "categorie": "Utilitaire", "requis": "celerite", "collecte": 0.20},
	"distillation": {"nom": "Distillation", "description": "+1 nouveau tirage d’Augments", "cout": Reglages.MAITRISE_COUTS[2], "categorie": "Utilitaire", "requis": "collecte", "rerolls": 1, "fort": true},
	"fortune": {"nom": "Fortune", "description": "+25 % Gouttes des coffres", "cout": Reglages.MAITRISE_COUTS[3], "categorie": "Utilitaire", "requis": "distillation", "coffre": 0.25},
	"sagesse": {"nom": "Sagesse", "description": "+20 % XP de compte", "cout": Reglages.MAITRISE_COUTS[4], "categorie": "Utilitaire", "requis": "fortune", "experience": 0.20},
	"abondance": {"nom": "Abondance", "description": "+40 % Gouttes", "cout": Reglages.MAITRISE_COUTS[5], "categorie": "Utilitaire", "requis": "sagesse", "collecte": 0.40},
	"savoir": {"nom": "Double discipline", "description": "Permet d’équiper un second Passif", "cout": Reglages.MAITRISE_COUTS[6], "categorie": "Utilitaire", "requis": "abondance", "second_passif": true, "fort": true},
	"elan": {"nom": "Élan", "description": "+10 % déplacement", "cout": Reglages.MAITRISE_COUTS[7], "categorie": "Utilitaire", "requis": "savoir", "vitesse": 0.10},
	"prescience": {"nom": "Prescience", "description": "+1 nouveau tirage d’Augments", "cout": Reglages.MAITRISE_COUTS[8], "categorie": "Utilitaire", "requis": "elan", "rerolls": 1},
	"philosophe": {"nom": "Pierre philosophale", "description": "+75 % coffres et +100 % Pierres de forge", "cout": Reglages.MAITRISE_COUTS[9], "categorie": "Utilitaire", "requis": "prescience", "coffre": 0.75, "pierres": 1.00, "fort": true},
}

const BRANCHES := {
	"Offensif": ["force", "cadence", "precision", "puissance", "rythme", "catalyse", "trajectoire", "tempete", "domination", "grand_oeuvre"],
	"Défensif": ["constitution", "armure", "vitalite", "rempart", "robustesse", "carapace", "endurance", "bastion", "colosse", "immortel"],
	"Utilitaire": ["celerite", "collecte", "distillation", "fortune", "sagesse", "abondance", "savoir", "elan", "prescience", "philosophe"],
}

static func cout(id: String, _rang := 0) -> int:
	return int(NOEUDS[id]["cout"])

static func prerequis_atteint(id: String, rangs: Dictionary) -> bool:
	var noeud: Dictionary = NOEUDS.get(id, {})
	return not noeud.has("requis") or int(rangs.get(noeud["requis"], 0)) >= 1

static func _somme(rangs: Dictionary, champ: String) -> float:
	var total := 0.0
	for id in rangs:
		if int(rangs[id]) > 0 and NOEUDS.has(id):
			total += float(NOEUDS[id].get(champ, 0.0))
	return total

static func description_effective(id: String) -> String:
	return str(NOEUDS[id]["description"])

static func bonus_pv(rangs: Dictionary) -> float:
	return _somme(rangs, "pv")

static func multiplicateur_pv(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "pv_mult")

static func reduction_degats(rangs: Dictionary) -> float:
	return clampf(_somme(rangs, "reduction"), 0.0, 0.60)

static func multiplicateur_soin(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "soin")

static func soin_par_salle(rangs: Dictionary) -> float:
	return _somme(rangs, "soin_salle")

static func donne_bouclier(rangs: Dictionary) -> bool:
	return _somme(rangs, "bouclier") > 0.0

static func multiplicateur_degats(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "degats")

static func multiplicateur_cadence(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "cadence")

static func multiplicateur_projectile(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "projectile")

static func multiplicateur_vitesse(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "vitesse")

static func multiplicateur_collecte(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "collecte")

static func multiplicateur_experience(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "experience")

static func multiplicateur_coffre(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "coffre")

static func multiplicateur_pierres(rangs: Dictionary) -> float:
	return 1.0 + _somme(rangs, "pierres")

static func nombre_rerolls(rangs: Dictionary) -> int:
	return roundi(_somme(rangs, "rerolls"))

static func donne_second_passif(rangs: Dictionary) -> bool:
	return _somme(rangs, "second_passif") > 0.0
