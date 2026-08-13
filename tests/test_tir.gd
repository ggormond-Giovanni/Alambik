extends RefCounted

func test_tir_de_base(v: Verif) -> void:
	var t := Tir.de_base(Stats.depuis_reglages())
	v.egal(t.nb_projectiles, 1, "un seul projectile par defaut")
	v.egal(t.rebonds, 0, "aucun rebond par defaut")
	v.presque(t.degats, Reglages.TIR_DEGATS, "degats lus dans les reglages")

func test_un_seul_projectile_va_tout_droit(v: Verif) -> void:
	var t := Tir.de_base(Stats.depuis_reglages())
	var angles := t.angles()
	v.egal(angles.size(), 1, "un projectile, un angle")
	v.presque(angles[0], 0.0, "il part droit devant")

func test_eventail_symetrique(v: Verif) -> void:
	var t := Tir.de_base(Stats.depuis_reglages())
	t.nb_projectiles = 3
	t.angle_eventail = deg_to_rad(30.0)
	var angles := t.angles()
	v.egal(angles.size(), 3, "trois projectiles, trois angles")
	v.presque(angles[1], 0.0, "celui du milieu part droit")
	v.presque(angles[0], -angles[2], "l'eventail est symetrique")

func test_eventail_pair(v: Verif) -> void:
	var t := Tir.de_base(Stats.depuis_reglages())
	t.nb_projectiles = 2
	t.angle_eventail = deg_to_rad(20.0)
	var angles := t.angles()
	v.presque(angles[0], -angles[1], "deux projectiles s'ecartent symetriquement")
	v.vrai(angles[0] < 0.0, "le premier part a gauche")

func test_decalages_centres(v: Verif) -> void:
	var t := Tir.de_base(Stats.depuis_reglages())
	t.nb_projectiles = 2
	t.ecart_lateral = 30.0
	var d := t.decalages()
	v.presque(d[0], -15.0, "le premier projectile part a gauche de l'axe")
	v.presque(d[1], 15.0, "le second a droite, symetriquement")

func test_un_projectile_sans_decalage(v: Verif) -> void:
	var t := Tir.de_base(Stats.depuis_reglages())
	t.ecart_lateral = 30.0
	v.presque(t.decalages()[0], 0.0, "seul, un projectile part sur l'axe")

func test_eventail_reste_serre(v: Verif) -> void:
	# Un eventail large fait rater les deux projectiles a distance : la sonde a
	# vu une sentinelle survivre a trois cents tirs pour cette raison.
	var t := Mods.appliquer(Tir.de_base(Stats.depuis_reglages()), [CatalogueReactifs.par_id("tir_multiple").mods])
	var ecart_a_600 := tan(t.angle_eventail / 2.0) * 600.0 + t.ecart_lateral / 2.0
	v.vrai(ecart_a_600 < 45.0, "a 600 px, chaque projectile reste a portee du rayon d'un ennemi")

func test_copie_independante(v: Verif) -> void:
	var t := Tir.de_base(Stats.depuis_reglages())
	var c := t.copie()
	c.effets.append("feu")
	c.degats = 999.0
	v.egal(t.effets.size(), 0, "la copie ne partage pas la liste d'effets")
	v.presque(t.degats, Reglages.TIR_DEGATS, "la copie ne modifie pas l'original")
