class_name BalayagePages
extends RefCounted

# Balayage horizontal pour parcourir une liste paginee.
#
# Les inventaires n'offraient que deux fleches de cent pixels posees sur les
# bords : rien n'indiquait au pouce qu'une seconde page existait, et viser une
# fleche de cette taille en jeu n'est pas raisonnable sur telephone. Le geste
# attendu sur mobile est le balayage ; les fleches restent en secours.
#
# La logique est pure pour rester verifiable en headless : elle ne connait ni
# les evenements d'entree ni l'arbre de scene.

const PART_LARGEUR := 0.08        # fraction de la largeur a parcourir
const DISTANCE_MINIMALE := 24.0   # garde-fou sur les tres petits ecrans
# Un geste plus vertical qu'horizontal vise autre chose qu'un changement de page.
const PART_VERTICALE_MAX := 1.0

var _actif := false
var _origine := Vector2.ZERO
var _balaye := false

func appuyer(position: Vector2) -> void:
	_actif = true
	_origine = position
	_balaye = false

# Renvoie -1 pour la page precedente, 1 pour la suivante, 0 tant que le seuil
# n'est pas franchi. Un meme appui ne tourne jamais plus d'une page.
func deplacer(position: Vector2, largeur: float) -> int:
	if not _actif or _balaye:
		return 0
	var ecart := position - _origine
	if absf(ecart.y) > absf(ecart.x) * PART_VERTICALE_MAX:
		return 0
	if absf(ecart.x) < maxf(DISTANCE_MINIMALE, largeur * PART_LARGEUR):
		return 0
	_balaye = true
	return -1 if ecart.x > 0.0 else 1

func relacher() -> void:
	_actif = false

# Vrai tant que le geste en cours a tourne une page. L'ecran doit alors ignorer
# le bouton relache sous le doigt : un balayage ne doit pas aussi selectionner
# la case ou le pouce s'arrete.
func a_balaye() -> bool:
	return _balaye
