class_name Chapitres
extends RefCounted

# Les dix identites de monde existantes sont declinees en trois chapitres. Les
# contenus sont reutilises entre les trois, tandis que densite et statistiques
# montent. Le troisieme porte le boss signature du monde.
#
# Les Mondes ne portent plus leurs multiplicateurs : la difficulte est une
# fonction du palier, c'est-a-dire du rang du chapitre dans la campagne. Une
# table figee obligeait a recalculer dix lignes a chaque retouche et rendait
# l'entree d'un Monde deux fois plus dure que ses propres chapitres.

const CHAPITRES_PAR_MONDE := 3

const MONDES := [
	{"id": "encres", "numero": "I", "nom": "Encres", "sous_titre": "Les créatures quittent leurs lignes.", "boss_signature": "archiscribe_encres", "teinte": Color(0.60, 0.50, 0.92)},
	{"id": "braises", "numero": "II", "nom": "Braises", "sous_titre": "Chaque salle conserve une étincelle.", "boss_signature": "roi_braises", "teinte": Color(1.00, 0.55, 0.28)},
	{"id": "givre", "numero": "III", "nom": "Givre", "sous_titre": "Le papier craque sous le froid.", "boss_signature": "reine_givre", "teinte": Color(0.52, 0.86, 1.00)},
	{"id": "orages", "numero": "IV", "nom": "Orages", "sous_titre": "Les phrases grondent avant de frapper.", "boss_signature": "maitre_orages", "teinte": Color(0.98, 0.90, 0.35)},
	{"id": "venins", "numero": "V", "nom": "Venins", "sous_titre": "L’encre ronge ceux qui la lisent.", "boss_signature": "hydre_venins", "teinte": Color(0.52, 0.94, 0.38)},
	{"id": "echos", "numero": "VI", "nom": "Échos", "sous_titre": "Chaque attaque revient une seconde fois.", "boss_signature": "choeur_infini", "teinte": Color(0.70, 0.56, 0.98)},
	{"id": "ombres", "numero": "VII", "nom": "Ombres", "sous_titre": "Les mots se déplacent quand on détourne les yeux.", "boss_signature": "souverain_ombres", "teinte": Color(0.46, 0.42, 0.68)},
	{"id": "runes", "numero": "VIII", "nom": "Runes", "sous_titre": "Des signes anciens défendent leurs secrets.", "boss_signature": "gardien_runes", "teinte": Color(0.35, 0.92, 0.76)},
	{"id": "neant", "numero": "IX", "nom": "Néant", "sous_titre": "Certaines salles auraient dû rester scellées.", "boss_signature": "devoreur_neant", "teinte": Color(0.82, 0.38, 0.82)},
	{"id": "alambic", "numero": "X", "nom": "Alambic", "sous_titre": "Toutes les formules convergent ici.", "boss_signature": "grand_alambic", "teinte": Color(1.00, 0.74, 0.24)},
]

const MINIBOSS_FINAUX := ["la_rature", "l_errata", "le_correcteur", "reliure_affamee",
	"virgule_noire", "index_brise", "marge_hurlante", "enlumineur_fou",
	"signet_sanglant", "copiste_aveugle"]

static var TOUS: Array[Dictionary] = _construire_chapitres()

static func _construire_chapitres() -> Array[Dictionary]:
	var resultat: Array[Dictionary] = []
	for index_monde in MONDES.size():
		var monde: Dictionary = MONDES[index_monde]
		for index_chapitre in CHAPITRES_PAR_MONDE:
			var chapitre_monde := index_chapitre + 1
			var est_signature := chapitre_monde == CHAPITRES_PAR_MONDE
			var palier := index_monde * CHAPITRES_PAR_MONDE + index_chapitre
			var boss_final: String = str(monde["boss_signature"]) if est_signature \
				else MINIBOSS_FINAUX[(index_monde * 2 + index_chapitre) % MINIBOSS_FINAUX.size()]
			resultat.append({
				"id": "%s_%d" % [monde["id"], chapitre_monde],
				"nom": "Monde %s — %s · Chapitre %d" % [monde["numero"], monde["nom"], chapitre_monde],
				"sous_titre": monde["sous_titre"],
				"monde": index_monde,
				"chapitre_monde": chapitre_monde,
				"salles": Reglages.SALLES_PAR_RUN,
				"alambics": [4, 9, 14],
				"bosses": [5, 10, 15, 20],
				"boss": boss_final,
				"boss_signature": est_signature,
				"palier": palier,
				"pv_mult": pv_du_palier(palier),
				"degats_mult": degats_du_palier(palier),
				"teinte": monde["teinte"],
			})
	return resultat

# Definies pour tout palier positif, y compris au-dela du trentieme : ajouter
# un onzieme Monde ne demande qu'une entree dans MONDES.
static func douceur_du_palier(palier: int) -> float:
	return lerpf(Reglages.COURBE_DOUCEUR_DEBUT, 1.0,
		clampf(float(maxi(0, palier)) / float(Reglages.COURBE_PALIERS_DOUCEUR), 0.0, 1.0))

static func pv_du_palier(palier: int) -> float:
	var p := maxi(0, palier)
	return pow(Reglages.COURBE_PV_PAR_PALIER, float(p)) * douceur_du_palier(p)

static func degats_du_palier(palier: int) -> float:
	var p := maxi(0, palier)
	return pow(Reglages.COURBE_DEGATS_PAR_PALIER, float(p)) * douceur_du_palier(p)

static func palier(index: int) -> int:
	return int(par_index(index)["palier"])

static func nombre() -> int:
	return TOUS.size()

static func par_index(index: int) -> Dictionary:
	return TOUS[clampi(index, 0, TOUS.size() - 1)]

static func par_id(id: String) -> Dictionary:
	for chapitre in TOUS:
		if chapitre["id"] == id:
			return chapitre
	return TOUS[0]

static func salles(index: int) -> int:
	return par_index(index)["salles"]

static func est_alambic(index: int, salle: int) -> bool:
	return salle in par_index(index)["alambics"]

static func est_boss(index: int, salle: int) -> bool:
	return salle in par_index(index)["bosses"]

static func progression(index: int, salle: int) -> float:
	var chapitre := par_index(index)
	return clampf(float(salle - 1) / maxf(1.0, float(chapitre["salles"] - 1)), 0.0, 1.0)

static func facteur_pv(index: int, salle: int) -> float:
	return par_index(index)["pv_mult"] * pow(1.0 + Reglages.MONTEE_PV, progression(index, salle))

static func facteur_degats(index: int, salle: int) -> float:
	return par_index(index)["degats_mult"] * pow(1.0 + Reglages.MONTEE_DEGATS, progression(index, salle))
