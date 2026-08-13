class_name Stats
extends RefCounted

var pv_max: float
var pv: float
var vitesse: float
var cadence: float          # tirs par seconde
var degats: float
var vitesse_projectile: float
var portee: float

static func depuis_reglages(rangs: Dictionary = {}, passifs: Dictionary = {}, objets: Dictionary = {}) -> Stats:
	var s := Stats.new()
	s.pv_max = (Reglages.HEROS_PV + ArbreCompetences.bonus_pv(rangs) + float(objets.get("pv", 0.0))) \
		* ArbreCompetences.multiplicateur_pv(rangs) * Sorts.multiplicateur_pv(passifs)
	s.pv = s.pv_max
	s.vitesse = Reglages.HEROS_VITESSE * ArbreCompetences.multiplicateur_vitesse(rangs) * Sorts.multiplicateur_vitesse(passifs) * (1.0 + float(objets.get("vitesse", 0.0)))
	s.cadence = Reglages.HEROS_CADENCE * ArbreCompetences.multiplicateur_cadence(rangs) * Sorts.multiplicateur_cadence(passifs) * (1.0 + float(objets.get("cadence", 0.0)))
	s.degats = Reglages.TIR_DEGATS * ArbreCompetences.multiplicateur_degats(rangs) * Sorts.multiplicateur_degats(passifs) * (1.0 + float(objets.get("degats", 0.0)))
	s.vitesse_projectile = Reglages.TIR_VITESSE * ArbreCompetences.multiplicateur_projectile(rangs) * Sorts.multiplicateur_projectile(passifs)
	s.portee = Reglages.TIR_PORTEE * ArbreCompetences.multiplicateur_projectile(rangs) * Sorts.multiplicateur_projectile(passifs)
	return s

func blesser(montant: float) -> void:
	pv = maxf(0.0, pv - montant)

func soigner(montant: float) -> void:
	pv = minf(pv_max, pv + montant)

func est_mort() -> bool:
	return pv <= 0.0
