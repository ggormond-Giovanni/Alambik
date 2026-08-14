class_name ArbreCompetences
extends RefCounted

# Trois branches de dix paliers. Chaque palier se rachete plusieurs fois : le
# premier rang accompagne la campagne, les suivants sont ce que le farm pousse
# au maximum. Les valeurs sont donc exprimees PAR RANG, jamais en total.
#
# Budget vise a l'arbre complet : environ x11 en DPS pour la branche offensive
# et une survie effective comparable pour la defensive, afin qu'aucune des deux
# ne devienne le seul chemin viable.
const MAX_RANG := Reglages.MAITRISE_RANG_MAX
const NOEUDS := {
	"force": {"nom": "Force", "description": "+6 % dégâts par rang", "cout": Reglages.MAITRISE_COUTS[0], "categorie": "Offensif", "degats": 0.06},
	"cadence": {"nom": "Cadence", "description": "+4 % cadence par rang", "cout": Reglages.MAITRISE_COUTS[1], "categorie": "Offensif", "requis": "force", "cadence": 0.04},
	"precision": {"nom": "Précision", "description": "+6 % vitesse et portée des tirs par rang", "cout": Reglages.MAITRISE_COUTS[2], "categorie": "Offensif", "requis": "cadence", "projectile": 0.06},
	"puissance": {"nom": "Puissance", "description": "+10 % dégâts par rang", "cout": Reglages.MAITRISE_COUTS[3], "categorie": "Offensif", "requis": "precision", "degats": 0.10, "fort": true},
	"rythme": {"nom": "Rythme de guerre", "description": "+5 % cadence par rang", "cout": Reglages.MAITRISE_COUTS[4], "categorie": "Offensif", "requis": "puissance", "cadence": 0.05},
	"catalyse": {"nom": "Catalyse", "description": "+16 % dégâts par rang", "cout": Reglages.MAITRISE_COUTS[5], "categorie": "Offensif", "requis": "rythme", "degats": 0.16},
	"trajectoire": {"nom": "Trajectoire absolue", "description": "+9 % vitesse et portée des tirs par rang", "cout": Reglages.MAITRISE_COUTS[6], "categorie": "Offensif", "requis": "catalyse", "projectile": 0.09},
	"tempete": {"nom": "Tempête", "description": "+7 % cadence par rang", "cout": Reglages.MAITRISE_COUTS[7], "categorie": "Offensif", "requis": "trajectoire", "cadence": 0.07, "fort": true},
	"domination": {"nom": "Domination", "description": "+26 % dégâts par rang", "cout": Reglages.MAITRISE_COUTS[8], "categorie": "Offensif", "requis": "tempete", "degats": 0.26},
	"grand_oeuvre": {"nom": "Grand Œuvre", "description": "+45 % dégâts par rang", "cout": Reglages.MAITRISE_COUTS[9], "categorie": "Offensif", "requis": "domination", "degats": 0.45, "fort": true},

	"constitution": {"nom": "Constitution", "description": "+8 % PV maximum par rang", "cout": Reglages.MAITRISE_COUTS[0], "categorie": "Défensif", "pv_mult": 0.08},
	"armure": {"nom": "Armure", "description": "-1 % dégâts reçus par rang", "cout": Reglages.MAITRISE_COUTS[1], "categorie": "Défensif", "requis": "constitution", "reduction": 0.010},
	"vitalite": {"nom": "Vitalité", "description": "+12 % PV maximum par rang", "cout": Reglages.MAITRISE_COUTS[2], "categorie": "Défensif", "requis": "armure", "pv_mult": 0.12},
	"rempart": {"nom": "Rempart", "description": "-1,4 % dégâts reçus par rang", "cout": Reglages.MAITRISE_COUTS[3], "categorie": "Défensif", "requis": "vitalite", "reduction": 0.014, "fort": true},
	"robustesse": {"nom": "Robustesse", "description": "+16 % PV maximum par rang", "cout": Reglages.MAITRISE_COUTS[4], "categorie": "Défensif", "requis": "rempart", "pv_mult": 0.16},
	"carapace": {"nom": "Carapace", "description": "-1,8 % dégâts reçus par rang", "cout": Reglages.MAITRISE_COUTS[5], "categorie": "Défensif", "requis": "robustesse", "reduction": 0.018},
	"endurance": {"nom": "Endurance", "description": "+24 % PV maximum par rang", "cout": Reglages.MAITRISE_COUTS[6], "categorie": "Défensif", "requis": "carapace", "pv_mult": 0.24},
	"bastion": {"nom": "Bastion", "description": "-2,2 % dégâts reçus par rang", "cout": Reglages.MAITRISE_COUTS[7], "categorie": "Défensif", "requis": "endurance", "reduction": 0.022, "fort": true},
	"colosse": {"nom": "Colosse", "description": "+36 % PV maximum par rang", "cout": Reglages.MAITRISE_COUTS[8], "categorie": "Défensif", "requis": "bastion", "pv_mult": 0.36},
	"immortel": {"nom": "Immortel", "description": "-3 % dégâts reçus par rang", "cout": Reglages.MAITRISE_COUTS[9], "categorie": "Défensif", "requis": "colosse", "reduction": 0.030, "fort": true},

	"celerite": {"nom": "Célérité", "description": "+2 % déplacement par rang", "cout": Reglages.MAITRISE_COUTS[0], "categorie": "Utilitaire", "vitesse": 0.02},
	"collecte": {"nom": "Collecte", "description": "+8 % Gouttes par rang", "cout": Reglages.MAITRISE_COUTS[1], "categorie": "Utilitaire", "requis": "celerite", "collecte": 0.08},
	# Un nouveau tirage change une regle du draft : deux rangs suffisent, cinq
	# rendraient le pool d'Ameliorations entierement choisissable.
	"distillation": {"nom": "Distillation", "description": "+1 nouveau tirage d’Améliorations par rang", "cout": Reglages.MAITRISE_COUTS[2], "categorie": "Utilitaire", "requis": "collecte", "rerolls": 1, "rangs": 2, "fort": true},
	"fortune": {"nom": "Fortune", "description": "+10 % Gouttes des coffres par rang", "cout": Reglages.MAITRISE_COUTS[3], "categorie": "Utilitaire", "requis": "distillation", "coffre": 0.10},
	"sagesse": {"nom": "Sagesse", "description": "+8 % XP de compte par rang", "cout": Reglages.MAITRISE_COUTS[4], "categorie": "Utilitaire", "requis": "fortune", "experience": 0.08},
	"abondance": {"nom": "Abondance", "description": "+14 % Gouttes par rang", "cout": Reglages.MAITRISE_COUTS[5], "categorie": "Utilitaire", "requis": "sagesse", "collecte": 0.14},
	"savoir": {"nom": "Double discipline", "description": "Permet d’équiper un second Passif", "cout": Reglages.MAITRISE_COUTS[6], "categorie": "Utilitaire", "requis": "abondance", "second_passif": true, "rangs": 1, "fort": true},
	"elan": {"nom": "Élan", "description": "+3 % déplacement par rang", "cout": Reglages.MAITRISE_COUTS[7], "categorie": "Utilitaire", "requis": "savoir", "vitesse": 0.03},
	"prescience": {"nom": "Prescience", "description": "+1 nouveau tirage d’Améliorations par rang", "cout": Reglages.MAITRISE_COUTS[8], "categorie": "Utilitaire", "requis": "elan", "rerolls": 1, "rangs": 2},
	"philosophe": {"nom": "Pierre philosophale", "description": "+18 % coffres et +25 % Pierres de forge par rang", "cout": Reglages.MAITRISE_COUTS[9], "categorie": "Utilitaire", "requis": "prescience", "coffre": 0.18, "pierres": 0.25, "fort": true},
}

const BRANCHES := {
	"Offensif": ["force", "cadence", "precision", "puissance", "rythme", "catalyse", "trajectoire", "tempete", "domination", "grand_oeuvre"],
	"Défensif": ["constitution", "armure", "vitalite", "rempart", "robustesse", "carapace", "endurance", "bastion", "colosse", "immortel"],
	"Utilitaire": ["celerite", "collecte", "distillation", "fortune", "sagesse", "abondance", "savoir", "elan", "prescience", "philosophe"],
}

static func rangs(id: String) -> int:
	return clampi(int(NOEUDS.get(id, {}).get("rangs", MAX_RANG)), 1, MAX_RANG)

# rang_acquis est le nombre de rangs deja payes : c'est le prochain achat qui
# est chiffre, pas celui qui vient d'etre fait.
static func cout(id: String, rang_acquis := 0) -> int:
	return Reglages.cout_maitrise(int(NOEUDS[id]["cout"]), maxi(0, rang_acquis))

static func cout_total(id: String) -> int:
	var total := 0
	for rang in rangs(id):
		total += cout(id, rang)
	return total

static func prerequis_atteint(id: String, rangs_joueur: Dictionary) -> bool:
	var noeud: Dictionary = NOEUDS.get(id, {})
	return not noeud.has("requis") or int(rangs_joueur.get(noeud["requis"], 0)) >= 1

static func _somme(rangs_joueur: Dictionary, champ: String) -> float:
	var total := 0.0
	for id in rangs_joueur:
		if not NOEUDS.has(id):
			continue
		var rang := clampi(int(rangs_joueur[id]), 0, rangs(id))
		total += float(rang) * float(NOEUDS[id].get(champ, 0.0))
	return total

static func description_effective(id: String) -> String:
	return str(NOEUDS[id]["description"])

const CHAMPS_LISIBLES := ["degats", "pv_mult", "cadence", "projectile", "reduction",
	"vitesse", "collecte", "coffre", "experience", "pierres"]

static func _nombre(valeur: float) -> String:
	return String.num(valeur, 1).trim_suffix(".0").replace(".", ",")

# Ce qu'un noeud vaut a un rang donne, sans le prefixe « Rang N ». Sert a
# comparer l'etat actuel au rang suivant : une valeur « par rang » oblige sinon
# le joueur a faire la multiplication de tete avant de depenser ses Gouttes.
static func valeur_au_rang(id: String, rang: int) -> String:
	var noeud: Dictionary = NOEUDS.get(id, {})
	var acquis := clampi(rang, 0, rangs(id))
	for champ in CHAMPS_LISIBLES:
		if noeud.has(champ):
			return "%s%s %%" % ["-" if champ == "reduction" else "+",
				_nombre(float(acquis) * float(noeud[champ]) * 100.0)]
	if noeud.has("rerolls"):
		var tirages := acquis * int(noeud["rerolls"])
		return "+%d tirage%s" % [tirages, "s" if tirages > 1 else ""]
	return "acquis" if acquis > 0 else "aucun"

static func resume_rang(id: String, rang: int) -> String:
	var acquis := clampi(rang, 0, rangs(id))
	if acquis <= 0:
		return "Aucun rang acquis"
	return "Rang %d : %s" % [acquis, valeur_au_rang(id, acquis)]

static func bonus_pv(rangs_joueur: Dictionary) -> float:
	return _somme(rangs_joueur, "pv")

static func multiplicateur_pv(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "pv_mult")

static func reduction_degats(rangs_joueur: Dictionary) -> float:
	return clampf(_somme(rangs_joueur, "reduction"), 0.0, 0.60)

static func multiplicateur_soin(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "soin")

static func soin_par_salle(rangs_joueur: Dictionary) -> float:
	return _somme(rangs_joueur, "soin_salle")

static func donne_bouclier(rangs_joueur: Dictionary) -> bool:
	return _somme(rangs_joueur, "bouclier") > 0.0

static func multiplicateur_degats(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "degats")

static func multiplicateur_cadence(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "cadence")

static func multiplicateur_projectile(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "projectile")

static func multiplicateur_vitesse(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "vitesse")

static func multiplicateur_collecte(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "collecte")

static func multiplicateur_experience(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "experience")

static func multiplicateur_coffre(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "coffre")

static func multiplicateur_pierres(rangs_joueur: Dictionary) -> float:
	return 1.0 + _somme(rangs_joueur, "pierres")

static func nombre_rerolls(rangs_joueur: Dictionary) -> int:
	return roundi(_somme(rangs_joueur, "rerolls"))

static func donne_second_passif(rangs_joueur: Dictionary) -> bool:
	return _somme(rangs_joueur, "second_passif") > 0.0
