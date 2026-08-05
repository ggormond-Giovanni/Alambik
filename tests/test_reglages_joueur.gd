extends RefCounted

func test_meilleur_resultat_progresse(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.meilleure_salle = 0
	r.enregistrer_resultat(4, false)
	v.egal(r.meilleure_salle, 4, "un premier resultat s'enregistre")
	r.enregistrer_resultat(2, false)
	v.egal(r.meilleure_salle, 4, "un resultat moins bon ne remplace pas le meilleur")
	r.enregistrer_resultat(9, false)
	v.egal(r.meilleure_salle, 9, "un meilleur resultat remplace")
	r.free()

func test_victoires_comptees(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.victoires = 0
	r.runs = 0
	r.enregistrer_resultat(10, true)
	r.enregistrer_resultat(3, false)
	v.egal(r.victoires, 1, "une seule victoire sur deux runs")
	v.egal(r.runs, 2, "les deux runs sont comptees")
	r.free()
