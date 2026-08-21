class_name Tir
extends RefCounted

# Description d'un tir, pas un comportement : le projectile lit ces champs et
# les execute. Une fusion n'est donc qu'une composition de valeurs.

var degats: float
var vitesse: float
var portee: float
var cadence: float
var nb_projectiles := 1
var angle_eventail := 0.0
var ecart_lateral := 0.0
var rebonds := 0
var perforations := 0
var fragments := 0
var effets: Array[String] = []
var drapeaux: Array[String] = []

static func de_base(stats: Stats) -> Tir:
	var t := Tir.new()
	t.degats = stats.degats
	t.vitesse = stats.vitesse_projectile
	t.portee = stats.portee
	t.cadence = stats.cadence
	return t

# Decalages angulaires, centres sur la visee, quel que soit le nombre.
func angles() -> Array[float]:
	var resultat: Array[float] = []
	if nb_projectiles <= 1:
		resultat.append(0.0)
		return resultat
	var pas := angle_eventail / float(nb_projectiles - 1)
	var depart := -angle_eventail / 2.0
	for i in nb_projectiles:
		resultat.append(depart + pas * i)
	return resultat

# Decalages perpendiculaires, centres comme les angles. Un eventail large fait
# rater les deux projectiles a distance moyenne : des tirs presque paralleles,
# simplement ecartes, touchent la ou l'eventail passait de chaque cote.
func decalages() -> Array[float]:
	var resultat: Array[float] = []
	if nb_projectiles <= 1:
		resultat.append(0.0)
		return resultat
	var largeur := ecart_lateral * float(nb_projectiles - 1)
	var pas := largeur / float(nb_projectiles - 1)
	for i in nb_projectiles:
		resultat.append(-largeur / 2.0 + pas * i)
	return resultat

func copie() -> Tir:
	var t := Tir.new()
	t.degats = degats
	t.vitesse = vitesse
	t.portee = portee
	t.cadence = cadence
	t.nb_projectiles = nb_projectiles
	t.angle_eventail = angle_eventail
	t.ecart_lateral = ecart_lateral
	t.rebonds = rebonds
	t.perforations = perforations
	t.fragments = fragments
	t.effets = effets.duplicate()
	t.drapeaux = drapeaux.duplicate()
	return t
