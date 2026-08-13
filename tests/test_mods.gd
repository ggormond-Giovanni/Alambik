extends RefCounted

func _base() -> Tir:
	return Tir.de_base(Stats.depuis_reglages())

func test_sans_mods_rien_ne_change(v: Verif) -> void:
	var t := Mods.appliquer(_base(), [])
	v.egal(t.nb_projectiles, 1, "aucun mod, un projectile")
	v.presque(t.degats, Reglages.TIR_DEGATS, "aucun mod, degats de base")

func test_addition(v: Verif) -> void:
	var t := Mods.appliquer(_base(), [{"nb_projectiles_add": 1}, {"nb_projectiles_add": 1}])
	v.egal(t.nb_projectiles, 3, "deux ajouts sur une base de 1")

func test_multiplicateurs_additifs(v: Verif) -> void:
	# +100 % et +50 % font +150 %, pas +200 % : en produit, empiler quatre
	# reactifs de degats fabriquait une main six fois au-dessus de la moyenne.
	var t := Mods.appliquer(_base(), [{"degats_mult": 2.0}, {"degats_mult": 1.5}])
	v.presque(t.degats, Reglages.TIR_DEGATS * 2.5, "les multiplicateurs s'additionnent")

func test_malus_ne_peut_pas_annuler_le_tir(v: Verif) -> void:
	var t := Mods.appliquer(_base(), [{"degats_mult": 0.5}, {"degats_mult": 0.5}, {"degats_mult": 0.5}])
	v.vrai(t.degats > 0.0, "un empilement de malus laisse toujours un tir")

func test_effets_reunis_sans_doublon(v: Verif) -> void:
	var t := Mods.appliquer(_base(), [{"effets": ["braise"]}, {"effets": ["braise", "givre"]}])
	v.egal(t.effets.size(), 2, "braise n'est comptee qu'une fois")
	v.vrai("givre" in t.effets, "givre est present")

func test_ordre_sans_importance(v: Verif) -> void:
	var a := Mods.appliquer(_base(), [{"degats_mult": 2.0}, {"nb_projectiles_add": 1}])
	var b := Mods.appliquer(_base(), [{"nb_projectiles_add": 1}, {"degats_mult": 2.0}])
	v.presque(a.degats, b.degats, "l'ordre ne change pas les degats")
	v.egal(a.nb_projectiles, b.nb_projectiles, "l'ordre ne change pas le nombre")

func test_base_non_modifiee(v: Verif) -> void:
	var base := _base()
	Mods.appliquer(base, [{"degats_mult": 5.0}, {"effets": ["braise"]}])
	v.presque(base.degats, Reglages.TIR_DEGATS, "le Tir de base n'est jamais mute")
	v.egal(base.effets.size(), 0, "les effets du Tir de base non plus")

func test_drapeaux(v: Verif) -> void:
	var t := Mods.appliquer(_base(), [{"drapeaux": ["homing"]}])
	v.vrai("homing" in t.drapeaux, "le drapeau est transmis")
