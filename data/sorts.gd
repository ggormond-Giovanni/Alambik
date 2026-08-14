class_name Sorts
extends RefCounted

# Les Sorts sont chiffres au rendement : degats rapportes a la recharge. Un sort
# long doit frapper plus fort qu'un sort court, mais l'alteration qu'il pose
# fait partie du prix — geler une salle vaut plus que quelques degats de plus.
# Un Sort frappait pour deux a cinq fois un tir, la ou le heros en place plus de
# quatre par seconde : il pesait moins qu'une seconde de tir automatique et ne
# valait donc jamais son emplacement. Les degats sont maintenant cales pour
# qu'un Sort ajoute environ un quart de la puissance soutenue.
const ACTIFS := {
	"onde_alchimique": {"nom": "Onde alchimique", "description": "Repousse autour de vous • recharge très courte", "recharge": 8.0, "rayon": 340.0, "degats": 9.0, "effet": "repousse"},
	"nova_de_givre": {"nom": "Nova de givre", "description": "Gèle une large zone • contrôle total", "recharge": 13.0, "rayon": 440.0, "degats": 12.0, "effet": "givre"},
	"barrage_de_braise": {"nom": "Barrage de braise", "description": "Embrase une très large zone • brûlure prolongée", "recharge": 15.0, "rayon": 540.0, "degats": 16.0, "effet": "braise"},
	"impulsion_foudroyante": {"nom": "Impulsion foudroyante", "description": "Portée immense • frappe pure", "recharge": 16.0, "rayon": 640.0, "degats": 20.0, "effet": ""},
	"explosion_corrosive": {"nom": "Explosion corrosive", "description": "Dévastatrice et corrosive • portée moyenne", "recharge": 18.0, "rayon": 480.0, "degats": 26.0, "effet": "acide"},
}

# Les Ultimes frappent toute la salle : leur prix est le nombre d'eliminations.
# Ils doivent effacer une rencontre, sinon rien ne justifie de les charger.
const ULTIMES := {
	"grand_oeuvre": {"nom": "Le Grand Œuvre", "description": "Efface toute la salle • charge rapide", "charge": 24, "degats": 30.0, "effet": ""},
	"temps_suspendu": {"nom": "Temps suspendu", "description": "Gèle toute la salle • dégâts plus faibles", "charge": 28, "degats": 22.0, "effet": "givre"},
	"transmutation_totale": {"nom": "Transmutation totale", "description": "Dégâts colossaux et corrosifs • charge lente", "charge": 38, "degats": 55.0, "effet": "acide"},
}

const PASSIFS := {
	"rempart_initial": {"nom": "Rempart initial", "description": "Bouclier à chaque salle • -18 % de dégâts subis en permanence"},
	"heritage_reactif": {"nom": "Héritage réactif", "description": "Commence chaque grimoire avec 2 Améliorations aléatoires"},
	"moisson_vitale": {"nom": "Moisson vitale", "description": "Toutes les 6 éliminations, récupère 12 % des PV"},
	"riposte_alchimique": {"nom": "Riposte alchimique", "description": "Être touché déclenche une déflagration massive qui repousse"},
	"seconde_chance": {"nom": "Seconde chance", "description": "Une fois par salle, survit à la mort avec 50 % des PV"},
	"reserve_ultime": {"nom": "Réserve d’ultime", "description": "+8 charges par salle • l’ultime coûte 20 % de charge en moins"},
	"sang_froid": {"nom": "Sang-froid", "description": "-30 % de recharge du Sort • réinitialisé toutes les 8 éliminations"},
	"dernier_rempart": {"nom": "Dernier rempart", "description": "Sous 40 % de PV, subit 45 % de dégâts en moins"},
	"audace": {"nom": "Audace", "description": "Sous 60 % de PV, inflige 45 % de dégâts en plus"},
	"echo_alchimique": {"nom": "Écho alchimique", "description": "40 % de chance que le Sort frappe une seconde fois à 70 %"},
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

# Rempart initial ne valait qu'un bouclier par salle, soit un coup encaisse
# toutes les deux minutes. Il porte maintenant une reduction permanente.
static func multiplicateur_degats_recus(passifs: Dictionary) -> float:
	return maxf(0.30, 1.0 - Reglages.REMPART_REDUCTION * float(passifs.get("rempart_initial", 0.0)))

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
	return maxf(0.25, 1.0 - Reglages.SANG_FROID_RECHARGE * float(passifs.get("sang_froid", 0.0)))

static func multiplicateur_charge_ultime(passifs: Dictionary) -> float:
	return maxf(0.35, 1.0 - Reglages.RESERVE_ULTIME_REMISE * float(passifs.get("reserve_ultime", 0.0)))

static func multiplicateur_degats_conditionnel(passifs: Dictionary, ratio_pv: float) -> float:
	return (1.0 + Reglages.AUDACE_BONUS * float(passifs.get("audace", 0.0))) \
		if ratio_pv < Reglages.AUDACE_SEUIL_PV else 1.0

static func multiplicateur_degats_recus_conditionnel(passifs: Dictionary, ratio_pv: float) -> float:
	return (1.0 - Reglages.DERNIER_REMPART_REDUCTION * float(passifs.get("dernier_rempart", 0.0))) \
		if ratio_pv < Reglages.DERNIER_REMPART_SEUIL_PV else 1.0
