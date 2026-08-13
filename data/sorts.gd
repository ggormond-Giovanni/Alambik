class_name Sorts
extends RefCounted

const ACTIFS := {
	"onde_alchimique": {"nom": "Onde alchimique", "description": "Repousse autour de vous • rapide, courte portée", "recharge": 10.0, "rayon": 290.0, "degats": 2.0, "effet": "repousse"},
	"nova_de_givre": {"nom": "Nova de givre", "description": "Gèle une large zone • dégâts modérés", "recharge": 14.0, "rayon": 380.0, "degats": 1.7, "effet": "givre"},
	"barrage_de_braise": {"nom": "Barrage de braise", "description": "Brûle une très large zone • recharge lente", "recharge": 15.0, "rayon": 480.0, "degats": 2.2, "effet": "braise"},
	"impulsion_foudroyante": {"nom": "Impulsion foudroyante", "description": "Portée immense • aucune altération", "recharge": 17.0, "rayon": 560.0, "degats": 2.7, "effet": ""},
	"explosion_corrosive": {"nom": "Explosion corrosive", "description": "Très violente et acide • portée moyenne", "recharge": 18.0, "rayon": 440.0, "degats": 3.2, "effet": "acide"},
}

const ULTIMES := {
	"grand_oeuvre": {"nom": "Le Grand Œuvre", "description": "Frappe toute la salle • charge rapide", "charge": 25, "degats": 5.0, "effet": ""},
	"temps_suspendu": {"nom": "Temps suspendu", "description": "Gèle toute la salle • dégâts plus faibles", "charge": 30, "degats": 3.5, "effet": "givre"},
	"transmutation_totale": {"nom": "Transmutation totale", "description": "Dégâts massifs et acide • charge lente", "charge": 40, "degats": 8.0, "effet": "acide"},
}

const PASSIFS := {
	"rempart_initial": {"nom": "Rempart initial", "description": "Commence chaque salle avec un bouclier"},
	"heritage_reactif": {"nom": "Héritage réactif", "description": "Commence chaque grimoire avec un Augment aléatoire"},
	"moisson_vitale": {"nom": "Moisson vitale", "description": "Toutes les 10 éliminations, récupère 8 % des PV"},
	"riposte_alchimique": {"nom": "Riposte alchimique", "description": "Subir un coup déclenche une explosion autour de vous"},
	"seconde_chance": {"nom": "Seconde chance", "description": "Une fois par grimoire, survit avec 35 % des PV"},
	"reserve_ultime": {"nom": "Réserve d’ultime", "description": "Commence chaque salle avec 5 charges d’ultime en plus"},
	"sang_froid": {"nom": "Sang-froid", "description": "Toutes les 12 éliminations, réinitialise le sort actif"},
	"dernier_rempart": {"nom": "Dernier rempart", "description": "Sous 30 % de PV, subit 35 % de dégâts en moins"},
	"audace": {"nom": "Audace", "description": "Sous 50 % de PV, inflige 30 % de dégâts en plus"},
	"echo_alchimique": {"nom": "Écho alchimique", "description": "30 % de chance que le sort actif frappe une seconde fois"},
}

static func contient(id: String) -> bool:
	return ACTIFS.has(id) or PASSIFS.has(id) or ULTIMES.has(id)

static func donnees(id: String) -> Dictionary:
	for catalogue in [ACTIFS, PASSIFS, ULTIMES]:
		if catalogue.has(id):
			return catalogue[id]
	return {}

static func _a(passifs: Dictionary, id: String) -> bool:
	return passifs.has(id)

static func multiplicateur_degats(passifs: Dictionary) -> float:
	return 1.0

static func multiplicateur_degats_recus(passifs: Dictionary) -> float:
	return 1.0

static func multiplicateur_vitesse(passifs: Dictionary) -> float:
	return 1.0

static func multiplicateur_cadence(passifs: Dictionary) -> float:
	return 1.0

static func multiplicateur_projectile(passifs: Dictionary) -> float:
	return 1.0

static func multiplicateur_pv(passifs: Dictionary) -> float:
	return 1.0

static func soin_par_salle(passifs: Dictionary) -> float:
	return 0.0

static func donne_bouclier(passifs: Dictionary) -> bool:
	return _a(passifs, "rempart_initial")

static func multiplicateur_recharge_active(passifs: Dictionary) -> float:
	return 1.0

static func multiplicateur_charge_ultime(passifs: Dictionary) -> float:
	return 1.0

static func multiplicateur_degats_conditionnel(passifs: Dictionary, ratio_pv: float) -> float:
	return 1.0 + 0.30 * float(passifs.get("audace", 0.0)) if ratio_pv < 0.50 else 1.0

static func multiplicateur_degats_recus_conditionnel(passifs: Dictionary, ratio_pv: float) -> float:
	return 1.0 - 0.35 * float(passifs.get("dernier_rempart", 0.0)) if ratio_pv < 0.30 else 1.0
