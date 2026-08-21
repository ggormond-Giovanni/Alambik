class_name Cerveaux
extends RefCounted

# Les decisions sont des fonctions pures : elles se testent sans scene, et le
# bot headless peut les rejouer a l'identique.

static func rampant(distance: float, portee_contact: float) -> String:
	return "frapper" if distance <= portee_contact else "avancer"

static func sentinelle(_distance: float, _portee: float, recharge: float) -> String:
	# Un tireur present a l'ecran est toujours une menace. La portee physique du
	# projectile couvre l'arene ; seule sa recharge cadence ses attaques.
	return "tirer" if recharge <= 0.0 else "attendre"

# La charge est telegraphiee : le joueur doit avoir le temps de se decaler.
static func veloce(distance: float, etat: String, minuterie: float,
		distance_charge := 900.0) -> String:
	if etat == "preparer":
		return "preparer" if minuterie > 0.0 else "charger"
	if etat == "charger":
		return "charger" if minuterie > 0.0 else "repos"
	if etat == "repos" and minuterie > 0.0:
		return "repos"
	return "preparer" if distance <= distance_charge else "avancer"

static func essaimeur(distance: float, distance_voulue: float, recharge: float) -> String:
	if distance < distance_voulue * 0.6:
		return "reculer"
	if distance > distance_voulue * 1.6:
		return "avancer"
	return "invoquer" if recharge <= 0.0 else "attendre"

static func harceleur(distance: float, distance_voulue: float, recharge: float) -> String:
	if distance < distance_voulue * 0.72:
		return "reculer"
	if distance > distance_voulue * 1.28:
		return "avancer"
	return "tirer" if recharge <= 0.0 else "tourner"

static func orbiteur(distance: float, distance_voulue: float, recharge: float) -> String:
	if distance < distance_voulue * 0.70:
		return "reculer"
	if distance > distance_voulue * 1.35:
		return "avancer"
	return "tirer" if recharge <= 0.0 else "orbiter"

static func miroir(distance: float, distance_voulue: float, recharge: float) -> String:
	if distance > distance_voulue * 1.45:
		return "avancer"
	return "pulser" if recharge <= 0.0 else "attendre"

static func phaseur(distance: float, distance_voulue: float, recharge: float,
		etat: String, minuterie: float) -> String:
	if etat == "phase":
		return "disparaitre" if minuterie > 0.0 else "reapparaitre"
	if distance > distance_voulue * 1.45:
		return "avancer"
	return "phase" if recharge <= 0.0 else "tourner"

static func tisseur(distance: float, distance_voulue: float, recharge: float) -> String:
	if distance < distance_voulue * 0.62:
		return "reculer"
	if distance > distance_voulue * 1.38:
		return "avancer"
	return "tisser" if recharge <= 0.0 else "croiser"

static func volatile(distance: float, distance_explosion: float, etat: String,
		minuterie: float) -> String:
	if etat == "gonfler":
		return "gonfler" if minuterie > 0.0 else "exploser"
	return "gonfler" if distance <= distance_explosion else "avancer"
