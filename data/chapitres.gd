class_name Chapitres
extends RefCounted

# Les dix identites de monde existantes sont declinees en trois chapitres. Les
# contenus sont reutilises entre les trois, tandis que densite et statistiques
# montent. Le troisieme porte le boss signature du monde.

const MONDES := [
	{"id": "encres", "numero": "I", "nom": "Encres", "sous_titre": "Les créatures quittent leurs lignes.", "boss_signature": "archiscribe_encres", "pv_mult": 1.00, "degats_mult": 1.00, "teinte": Color(0.60, 0.50, 0.92)},
	{"id": "braises", "numero": "II", "nom": "Braises", "sous_titre": "Chaque salle conserve une étincelle.", "boss_signature": "roi_braises", "pv_mult": 1.35, "degats_mult": 1.15, "teinte": Color(1.00, 0.55, 0.28)},
	{"id": "givre", "numero": "III", "nom": "Givre", "sous_titre": "Le papier craque sous le froid.", "boss_signature": "reine_givre", "pv_mult": 1.82, "degats_mult": 1.32, "teinte": Color(0.52, 0.86, 1.00)},
	{"id": "orages", "numero": "IV", "nom": "Orages", "sous_titre": "Les phrases grondent avant de frapper.", "boss_signature": "maitre_orages", "pv_mult": 2.46, "degats_mult": 1.52, "teinte": Color(0.98, 0.90, 0.35)},
	{"id": "venins", "numero": "V", "nom": "Venins", "sous_titre": "L’encre ronge ceux qui la lisent.", "boss_signature": "hydre_venins", "pv_mult": 3.32, "degats_mult": 1.75, "teinte": Color(0.52, 0.94, 0.38)},
	{"id": "echos", "numero": "VI", "nom": "Échos", "sous_titre": "Chaque attaque revient une seconde fois.", "boss_signature": "choeur_infini", "pv_mult": 4.48, "degats_mult": 2.01, "teinte": Color(0.70, 0.56, 0.98)},
	{"id": "ombres", "numero": "VII", "nom": "Ombres", "sous_titre": "Les mots se déplacent quand on détourne les yeux.", "boss_signature": "souverain_ombres", "pv_mult": 6.05, "degats_mult": 2.31, "teinte": Color(0.46, 0.42, 0.68)},
	{"id": "runes", "numero": "VIII", "nom": "Runes", "sous_titre": "Des signes anciens défendent leurs secrets.", "boss_signature": "gardien_runes", "pv_mult": 8.17, "degats_mult": 2.66, "teinte": Color(0.35, 0.92, 0.76)},
	{"id": "neant", "numero": "IX", "nom": "Néant", "sous_titre": "Certaines salles auraient dû rester scellées.", "boss_signature": "devoreur_neant", "pv_mult": 11.03, "degats_mult": 3.06, "teinte": Color(0.82, 0.38, 0.82)},
	{"id": "alambic", "numero": "X", "nom": "Alambic", "sous_titre": "Toutes les formules convergent ici.", "boss_signature": "grand_alambic", "pv_mult": 14.89, "degats_mult": 3.52, "teinte": Color(1.00, 0.74, 0.24)},
]

const MINIBOSS_FINAUX := ["la_rature", "l_errata", "le_correcteur", "reliure_affamee",
	"virgule_noire", "index_brise", "marge_hurlante", "enlumineur_fou",
	"signet_sanglant", "copiste_aveugle"]

static var TOUS: Array[Dictionary] = _construire_chapitres()

static func _construire_chapitres() -> Array[Dictionary]:
	var resultat: Array[Dictionary] = []
	for index_monde in MONDES.size():
		var monde: Dictionary = MONDES[index_monde]
		for index_chapitre in 3:
			var chapitre_monde := index_chapitre + 1
			var est_signature := chapitre_monde == 3
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
				"pv_mult": float(monde["pv_mult"]) * pow(1.10, index_chapitre),
				"degats_mult": float(monde["degats_mult"]) * pow(1.05, index_chapitre),
				"teinte": monde["teinte"],
			})
	return resultat

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
