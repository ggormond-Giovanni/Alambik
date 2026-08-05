class_name JoystickLogique
extends RefCounted

# Le joystick est flottant : son origine nait sous le pouce, ou qu'il se pose.
# C'est ce qui rend le jeu jouable d'une main sans viser une zone precise.

const RAYON := 140.0
const ZONE_MORTE := 14.0

var actif := false
var origine := Vector2.ZERO
var courant := Vector2.ZERO

func appuyer(position: Vector2) -> void:
	actif = true
	origine = position
	courant = position

func deplacer(position: Vector2) -> void:
	if actif:
		courant = position

func relacher() -> void:
	actif = false
	origine = Vector2.ZERO
	courant = Vector2.ZERO

func direction() -> Vector2:
	var ecart := courant - origine
	if not actif or ecart.length() < ZONE_MORTE:
		return Vector2.ZERO
	return ecart.normalized()

func intensite() -> float:
	var ecart := courant - origine
	if not actif or ecart.length() < ZONE_MORTE:
		return 0.0
	return minf(ecart.length() / RAYON, 1.0)
