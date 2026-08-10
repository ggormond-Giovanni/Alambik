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
