class_name Stats
extends RefCounted

var pv_max: float
var pv: float
var vitesse: float
var cadence: float          # tirs par seconde
var degats: float
var vitesse_projectile: float
var portee: float

static func depuis_reglages() -> Stats:
	var s := Stats.new()
	s.pv_max = Reglages.HEROS_PV
	s.pv = Reglages.HEROS_PV
	s.vitesse = Reglages.HEROS_VITESSE
	s.cadence = Reglages.HEROS_CADENCE
	s.degats = Reglages.TIR_DEGATS
	s.vitesse_projectile = Reglages.TIR_VITESSE
	s.portee = Reglages.TIR_PORTEE
	return s

func blesser(montant: float) -> void:
	pv = maxf(0.0, pv - montant)

func soigner(montant: float) -> void:
	pv = minf(pv_max, pv + montant)

func est_mort() -> bool:
	return pv <= 0.0
