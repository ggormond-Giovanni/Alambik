extends RefCounted

func _bloc() -> Rect2:
	return Rect2(Vector2(100, 100), Vector2(200, 100))

func test_segment_qui_traverse(v: Verif) -> void:
	v.vrai(Geometrie.segment_coupe_rect(Vector2(0, 150), Vector2(400, 150), _bloc()),
		"un segment horizontal en plein milieu coupe le bloc")

func test_segment_au_dessus(v: Verif) -> void:
	v.vrai(not Geometrie.segment_coupe_rect(Vector2(0, 50), Vector2(400, 50), _bloc()),
		"un segment qui passe au-dessus ne coupe rien")

func test_segment_trop_court(v: Verif) -> void:
	v.vrai(not Geometrie.segment_coupe_rect(Vector2(0, 150), Vector2(80, 150), _bloc()),
		"un segment qui s'arrete avant le bloc ne le coupe pas")

func test_segment_diagonal(v: Verif) -> void:
	v.vrai(Geometrie.segment_coupe_rect(Vector2(0, 0), Vector2(400, 300), _bloc()),
		"une diagonale qui traverse le bloc est detectee")

func test_segment_qui_frole(v: Verif) -> void:
	v.vrai(not Geometrie.segment_coupe_rect(Vector2(0, 260), Vector2(400, 260), _bloc()),
		"un segment qui passe dessous ne coupe rien")

func test_depuis_l_interieur(v: Verif) -> void:
	# Cas qui faisait echouer le raycast du moteur : partir de l'interieur.
	v.vrai(Geometrie.segment_coupe_rect(Vector2(150, 150), Vector2(400, 150), _bloc()),
		"un segment qui part de l'interieur du bloc le coupe")

func test_cas_reel_de_la_sonde(v: Verif) -> void:
	# Le blocage observe en salle 2, graine 4 : le heros tirait dans ce bloc.
	var bloc := Rect2(Vector2(499, 971), Vector2(200, 110))
	v.vrai(not Geometrie.ligne_libre(Vector2(602, 1228), Vector2(813, 780), [bloc]),
		"la ligne du heros vers la sentinelle etait bel et bien bouchee")

func test_marge_du_projectile(v: Verif) -> void:
	# Cas reel : la ligne passait a 4 px du bloc, donc "libre" pour un point,
	# mais un projectile de rayon 10 heurtait le bloc a coup sur.
	var bloc := Rect2(Vector2(517.7, 994.9), Vector2(163.0, 62.8))
	var depart := Vector2(602, 1228)
	var cible := Vector2(813, 780)
	v.vrai(Geometrie.ligne_libre(depart, cible, [bloc]), "sans marge, la ligne parait libre")
	v.vrai(not Geometrie.ligne_libre(depart, cible, [bloc], 16.0), "avec la marge du projectile, elle est bouchee")

func test_ligne_libre_sans_obstacle(v: Verif) -> void:
	v.vrai(Geometrie.ligne_libre(Vector2(0, 0), Vector2(500, 500), []),
		"sans obstacle, toute ligne est libre")
