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

func test_contrainte_tient_compte_du_rayon(v: Verif) -> void:
	var rect := Rect2(100, 200, 500, 700)
	v.egal(Geometrie.contraindre_dans_rect(Vector2(40, 960), rect, 24.0), Vector2(124, 876),
		"le centre reste a un rayon entier des murs")
	v.egal(Geometrie.contraindre_dans_rect(Vector2(300, 500), rect, 24.0), Vector2(300, 500),
		"une position deja jouable ne bouge pas")

# Le familier tire depuis un point decale du heros. Sa visee etait pourtant
# calculee depuis le heros : le trait partait donc de cote et manquait la cible
# de tout l'angle separant les deux points, d'autant plus nettement de pres.
func test_la_visee_part_du_point_de_tir(v: Verif) -> void:
	var cible := Vector2(400.0, 0.0)
	var heros := Vector2.ZERO
	var familier := heros + Reglages.FAMILIER_DECALAGE
	var vise := Geometrie.point_anticipe(cible, Vector2.ZERO, familier, 900.0)
	var depuis_le_familier := familier.direction_to(vise)
	var depuis_le_heros := heros.direction_to(vise)
	v.vrai(depuis_le_familier.angle_to(depuis_le_heros) != 0.0,
		"les deux origines ne donnent pas la meme direction")
	var arrivee := familier + depuis_le_familier * familier.distance_to(cible)
	v.vrai(arrivee.distance_to(cible) < 1.0,
		"vise depuis le point de tir, le trait arrive sur la cible")
	var arrivee_fautive := familier + depuis_le_heros * familier.distance_to(cible)
	v.vrai(arrivee_fautive.distance_to(cible) > 20.0,
		"vise depuis le heros, il passe nettement a cote")

func test_l_anticipation_devance_une_cible_qui_fuit(v: Verif) -> void:
	var cible := Vector2(600.0, 0.0)
	var immobile := Geometrie.point_anticipe(cible, Vector2.ZERO, Vector2.ZERO, 900.0)
	v.egal(immobile, cible, "une cible immobile se vise la ou elle est")
	var fuyante := Geometrie.point_anticipe(cible, Vector2(0.0, 300.0), Vector2.ZERO, 900.0)
	v.vrai(fuyante.y > cible.y, "une cible qui fuit se vise devant elle")

func test_l_anticipation_reste_bornee(v: Verif) -> void:
	# Sans borne, une cible lointaine et rapide se vise si loin devant qu'aucun
	# tir ne touche plus.
	var lointaine := Geometrie.point_anticipe(Vector2(99999.0, 0.0), Vector2(0.0, 400.0),
		Vector2.ZERO, 900.0)
	var maximum := 400.0 * Reglages.ANTICIPATION_DUREE_MAX * Reglages.ANTICIPATION_PART
	v.vrai(lointaine.y <= maximum + 0.1, "l'avance visee ne depasse jamais son plafond")
