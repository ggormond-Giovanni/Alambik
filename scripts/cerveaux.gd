class_name Cerveaux
extends RefCounted

# Les decisions sont des fonctions pures : elles se testent sans scene, et le
# bot headless peut les rejouer a l'identique.

static func rampant(distance: float, portee_contact: float) -> String:
	return "frapper" if distance <= portee_contact else "avancer"

static func sentinelle(distance: float, portee: float, recharge: float) -> String:
	if distance <= portee and recharge <= 0.0:
		return "tirer"
	return "attendre"

# La charge est telegraphiee : le joueur doit avoir le temps de se decaler.
static func veloce(distance: float, etat: String, minuterie: float) -> String:
	if etat == "preparer":
		return "preparer" if minuterie > 0.0 else "charger"
	if etat == "charger":
		return "charger" if minuterie > 0.0 else "repos"
	return "preparer" if distance < 900.0 else "repos"

static func essaimeur(distance: float, distance_voulue: float, recharge: float) -> String:
	if distance < distance_voulue * 0.6:
		return "reculer"
	if distance > distance_voulue * 1.6:
		return "avancer"
	return "invoquer" if recharge <= 0.0 else "attendre"
