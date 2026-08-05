extends RefCounted

func test_sans_appui_pas_de_direction(v: Verif) -> void:
	var j := JoystickLogique.new()
	v.egal(j.direction(), Vector2.ZERO, "au repos la direction est nulle")

func test_appui_seul_ne_bouge_pas(v: Verif) -> void:
	var j := JoystickLogique.new()
	j.appuyer(Vector2(200, 900))
	v.egal(j.direction(), Vector2.ZERO, "poser le pouce ne deplace pas")

func test_zone_morte(v: Verif) -> void:
	var j := JoystickLogique.new()
	j.appuyer(Vector2(200, 900))
	j.deplacer(Vector2(205, 900))
	v.egal(j.direction(), Vector2.ZERO, "sous la zone morte, rien")

func test_direction_et_intensite(v: Verif) -> void:
	var j := JoystickLogique.new()
	j.appuyer(Vector2(200, 900))
	j.deplacer(Vector2(200 + JoystickLogique.RAYON / 2.0, 900))
	v.presque(j.direction().x, 1.0, "direction vers la droite")
	v.presque(j.intensite(), 0.5, "mi-course donne une demi-intensite")

func test_intensite_plafonnee(v: Verif) -> void:
	var j := JoystickLogique.new()
	j.appuyer(Vector2(200, 900))
	j.deplacer(Vector2(200 + JoystickLogique.RAYON * 4.0, 900))
	v.presque(j.intensite(), 1.0, "au-dela du rayon l'intensite plafonne")

func test_relacher_annule(v: Verif) -> void:
	var j := JoystickLogique.new()
	j.appuyer(Vector2(200, 900))
	j.deplacer(Vector2(400, 900))
	j.relacher()
	v.egal(j.direction(), Vector2.ZERO, "relacher rend la direction nulle")

func test_origine_flottante(v: Verif) -> void:
	# Le joystick nait sous le pouce, ou qu'il se pose : deux appuis
	# eloignes suivis du meme decalage donnent la meme direction.
	var a := JoystickLogique.new()
	a.appuyer(Vector2(100, 1500))
	a.deplacer(Vector2(100, 1500 - JoystickLogique.RAYON))
	var b := JoystickLogique.new()
	b.appuyer(Vector2(900, 800))
	b.deplacer(Vector2(900, 800 - JoystickLogique.RAYON))
	v.egal(a.direction(), b.direction(), "l'origine ne change pas la direction")
