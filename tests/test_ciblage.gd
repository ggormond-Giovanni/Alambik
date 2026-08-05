extends RefCounted

func test_liste_vide(v: Verif) -> void:
	var vide: Array[Vector2] = []
	v.egal(Ciblage.plus_proche(Vector2.ZERO, vide), -1, "sans cible, pas d'index")

func test_choisit_la_plus_proche(v: Verif) -> void:
	var cibles: Array[Vector2] = [Vector2(500, 0), Vector2(120, 0), Vector2(300, 0)]
	v.egal(Ciblage.plus_proche(Vector2.ZERO, cibles), 1, "la cible a 120 est la plus proche")

func test_distance_diagonale(v: Verif) -> void:
	var cibles: Array[Vector2] = [Vector2(100, 100), Vector2(0, 130)]
	v.egal(Ciblage.plus_proche(Vector2.ZERO, cibles), 1, "130 contre 141 : la diagonale perd")
