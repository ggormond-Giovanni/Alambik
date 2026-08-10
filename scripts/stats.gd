class_name Stats
extends RefCounted

var pv_max: float
var pv: float
var vitesse: float
var cadence: float          # tirs par seconde
var degats: float
var vitesse_projectile: float
var portee: float

static func depuis_reglages(rangs: Dictionary = {}, bonus_niveau_pv := 0.0,
		mult_niveau_degats := 1.0, mult_niveau_vitesse := 1.0, passifs: Dictionary = {}) -> Stats:
	var s := Stats.new()
	s.pv_max = (Reglages.HEROS_PV + bonus_niveau_pv + ArbreCompetences.bonus_pv(rangs)) * Sorts.multiplicateur_pv(passifs)
	s.pv = s.pv_max
	s.vitesse = Reglages.HEROS_VITESSE * mult_niveau_vitesse * ArbreCompetences.multiplicateur_vitesse(rangs) * Sorts.multiplicateur_vitesse(passifs)
	s.cadence = Reglages.HEROS_CADENCE * ArbreCompetences.multiplicateur_cadence(rangs) * Sorts.multiplicateur_cadence(passifs)
	s.degats = Reglages.TIR_DEGATS * mult_niveau_degats * ArbreCompetences.multiplicateur_degats(rangs) * Sorts.multiplicateur_degats(passifs)
	s.vitesse_projectile = Reglages.TIR_VITESSE * ArbreCompetences.multiplicateur_projectile(rangs) * Sorts.multiplicateur_projectile(passifs)
	s.portee = Reglages.TIR_PORTEE * ArbreCompetences.multiplicateur_projectile(rangs) * Sorts.multiplicateur_projectile(passifs)
	return s

func blesser(montant: float) -> void:
	pv = maxf(0.0, pv - montant)

func soigner(montant: float) -> void:
	pv = minf(pv_max, pv + montant)

func est_mort() -> bool:
	return pv <= 0.0
