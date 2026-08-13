class_name PrioriteProjectile
extends RefCounted

# Ordre explicite des interactions apres un impact. Un ricochet doit changer la
# trajectoire des le premier ennemi ; les perforations restantes prennent le
# relais seulement quand il n'y a plus de ricochet a consommer.
static func apres_impact(rebonds_restants: int, perforations_restantes: int) -> String:
	if rebonds_restants > 0:
		return "rebond"
	if perforations_restantes > 0:
		return "perforation"
	return "fin"

static func apres_mur(_rebonds_restants: int) -> String:
	# Les murs terminent toujours le tir. Les rebonds ne se consomment que sur
	# les ennemis, sinon le projectile peut repartir depuis l'interieur du mur.
	return "fin"
