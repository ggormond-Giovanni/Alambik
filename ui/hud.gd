extends Control

# Barre de vie, salle courante, inventaire. Dessine, jamais compose de sprites,
# et pose sous la safe area : sur telephone, l'encoche mange le haut.

var _secousse := 0.0
var _flash_degats := 0.0
var _anim := 0.0
signal pause_demandee
signal sort_actif_demande
signal ultime_demande

var _style_compact: StyleBoxFlat
var _bouton_pause: Button
var _bouton_actif: Button
var _bouton_ultime: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Jeu.inventaire_change.connect(rafraichir)
	Jeu.experience_run_change.connect(rafraichir)
	ReglagesJoueur.maitrise_changee.connect(rafraichir)
	_style_compact = StyleInterface.panneau(Color(0.035, 0.045, 0.060, 0.94), Color(Palette.BORD_PAGE, 0.42), 20, 7)
	_bouton_pause = Button.new()
	_bouton_pause.text = "Ⅱ"
	_bouton_pause.custom_minimum_size = Vector2(Ecran.CIBLE_TACTILE, Ecran.CIBLE_TACTILE)
	_bouton_pause.size = Vector2(Ecran.CIBLE_TACTILE, Ecran.CIBLE_TACTILE)
	_bouton_pause.add_theme_font_size_override("font_size", 30)
	StyleInterface.styliser_bouton(_bouton_pause, Palette.TEXTE_ATTENUE, true)
	_bouton_pause.pressed.connect(func() -> void: pause_demandee.emit())
	add_child(_bouton_pause)
	_bouton_actif = _creer_bouton_sort(Palette.OR)
	_bouton_actif.pressed.connect(func() -> void: sort_actif_demande.emit())
	add_child(_bouton_actif)
	_bouton_ultime = _creer_bouton_sort(Palette.ESSENCE)
	_bouton_ultime.pressed.connect(func() -> void: ultime_demande.emit())
	add_child(_bouton_ultime)
	_replacer_bouton()
	get_viewport().size_changed.connect(_replacer_bouton)

func _replacer_bouton() -> void:
	if _bouton_pause != null:
		_bouton_pause.position = Vector2(12.0, Ecran.marge_haute() + 4.0)
	var taille := get_viewport_rect().size
	if _bouton_actif != null:
		_bouton_actif.position = Vector2(taille.x - 142.0, taille.y - Ecran.marge_basse() - 350.0)
	if _bouton_ultime != null:
		_bouton_ultime.position = Vector2(taille.x - 142.0, taille.y - Ecran.marge_basse() - 494.0)

func _creer_bouton_sort(couleur: Color) -> Button:
	var bouton := Button.new()
	bouton.custom_minimum_size = Vector2(128, 128)
	bouton.size = Vector2(128, 128)
	bouton.add_theme_font_size_override("font_size", 21)
	StyleInterface.styliser_bouton(bouton, couleur)
	return bouton

func rafraichir_sorts(recharge_active: float, charge_ultime: int) -> void:
	var actif := ReglagesJoueur.sort_actif_effectif()
	var ultime := ReglagesJoueur.ultime_effectif()
	_bouton_actif.visible = Sorts.ACTIFS.has(actif)
	_bouton_ultime.visible = Sorts.ULTIMES.has(ultime)
	if _bouton_actif.visible:
		var donnees: Dictionary = Sorts.ACTIFS[actif]
		_bouton_actif.text = "%s\n%s" % [donnees["nom"], "%.1f s" % recharge_active if recharge_active > 0.0 else "PRÊT"]
		_bouton_actif.disabled = recharge_active > 0.0
	if _bouton_ultime.visible:
		var donnees: Dictionary = Sorts.ULTIMES[ultime]
		var requis := ceili(float(donnees["charge"]) * Sorts.multiplicateur_charge_ultime(ReglagesJoueur.passifs_equipes_effectifs()))
		_bouton_ultime.text = "%s\n%d/%d" % [donnees["nom"], mini(charge_ultime, requis), requis]
		_bouton_ultime.disabled = charge_ultime < requis

func rafraichir() -> void:
	queue_redraw()

func secouer() -> void:
	if not ReglagesJoueur.secousses_ecran:
		return
	_secousse = 1.0

func impact_degats() -> void:
	# Le flash est volontairement très bref : il confirme le coup sans retirer
	# la visibilité nécessaire pour esquiver le suivant.
	_flash_degats = 1.0
	secouer()

func _process(delta: float) -> void:
	_anim += delta
	_secousse = maxf(0.0, _secousse - delta * 3.0)
	_flash_degats = maxf(0.0, _flash_degats - delta * 7.5)
	queue_redraw()

func _draw() -> void:
	var police := ThemeDB.fallback_font
	var largeur := get_viewport_rect().size.x
	var haut := Ecran.marge_haute() + 16.0
	var tremble := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _secousse * 4.0
	var centre_x := largeur * 0.5
	if _flash_degats > 0.0:
		var alpha := _flash_degats * (0.10 if ReglagesJoueur.effets_reduits else 0.17)
		var epaisseur := 34.0 + _flash_degats * 22.0
		var hauteur_ecran := get_viewport_rect().size.y
		# Une vignette sur les quatre bords reste visible sous les pouces et ne
		# masque jamais le héros ou les projectiles au centre.
		draw_rect(Rect2(0.0, 0.0, largeur, epaisseur), Color(Palette.DANGER, alpha))
		draw_rect(Rect2(0.0, hauteur_ecran - epaisseur, largeur, epaisseur), Color(Palette.DANGER, alpha))
		draw_rect(Rect2(0.0, 0.0, epaisseur, hauteur_ecran), Color(Palette.DANGER, alpha))
		draw_rect(Rect2(largeur - epaisseur, 0.0, epaisseur, hauteur_ecran), Color(Palette.DANGER, alpha))
	# La progression de run tient dans une capsule compacte : niveau, XP et salle
	# restent visibles sans prendre l'espace d'esquive.
	var panneau_progression := Rect2(Vector2(largeur * 0.5 - 105.0, haut - 8.0) + tremble, Vector2(210.0, 70.0))
	draw_style_box(_style_compact, panneau_progression)
	var texte_progression := "SALLE %02d / %02d  •  NIV %d" % [Jeu.salle_courante, Jeu.salles_du_chapitre(), Jeu.niveau_run]
	if Jeu.est_retro():
		texte_progression = "STAGE 1  •  16-BIT"
	if Jeu.mode_run == "mine":
		var secondes := ceili(Jeu.temps_mine_restant)
		texte_progression = "MINE %02d:%02d  •  NIV %d" % [secondes / 60, secondes % 60, Jeu.niveau_run]
	draw_string(police, Vector2(panneau_progression.position.x, haut + 24.0), texte_progression,
		HORIZONTAL_ALIGNMENT_CENTER, panneau_progression.size.x, 20, Palette.TEXTE)
	var xp := Jeu.experience_vers_prochain_niveau()
	var barre_xp := Rect2(panneau_progression.position + Vector2(14.0, 46.0), Vector2(panneau_progression.size.x - 28.0, 8.0))
	draw_rect(barre_xp, Color(0.02, 0.02, 0.04, 0.8))
	var remplie := barre_xp
	remplie.size.x *= clampf(float(xp["actuelle"]) / maxf(1.0, float(xp["requise"])), 0.0, 1.0)
	draw_rect(remplie, Palette.ESSENCE)

	# Deux symboles alchimiques remplacent l'ancien compteur carre : la fiole
	# compte le build de la run, la goutte la monnaie permanente.
	var centre_fiole := Vector2(largeur - 142.0, haut + 25.0) + tremble
	Dessin.halo(self, centre_fiole, 34.0, Color(Palette.ESSENCE, 0.55), 3)
	Dessin.glyphe(self, "fiole", centre_fiole, 17.0, Palette.ESSENCE)
	draw_string(police, centre_fiole + Vector2(25.0, 10.0), str(Jeu.inventaire.size()),
		HORIZONTAL_ALIGNMENT_LEFT, 32.0, 25, Palette.TEXTE)
	var centre_goutte := Vector2(largeur - 78.0, haut + 25.0) + tremble
	draw_colored_polygon(Dessin.goutte(centre_goutte, 18.0, PI, 1.2), Palette.ESSENCE)
	draw_string(police, centre_goutte + Vector2(23.0, 10.0), ReglagesJoueur.gouttes_affichees(),
		HORIZONTAL_ALIGNMENT_LEFT, 42.0, 24, Palette.TEXTE)

	var boss := get_tree().get_first_node_in_group("boss")
	var boss_visible := boss != null and is_instance_valid(boss) and float(boss.pv_max) > 0.0
	if boss_visible:
		_dessiner_barre_boss(boss, police, largeur, haut, tremble)

	# Inventaire : une pastille par reactif, teintee et glyphee. C'est la seule
	# trace visible de ce que le joueur a construit pendant la run.
	var x := centre_x - float(Jeu.inventaire_groupe().size() - 1) * 29.0
	var y := haut + (194.0 if boss_visible else 88.0)
	for entree in Jeu.inventaire_groupe():
		var id: String = entree[0]
		var r := Jeu.reactif(id)
		if r == null:
			continue
		var centre := Vector2(x, y)
		if r.est_transformation:
			Dessin.halo(self, centre, 34.0, Palette.ESSENCE, 3)
			Dessin.contour(self, Dessin.polygone_regulier(centre, 26.0, 6, _anim * 0.4), Palette.ESSENCE, 2.5)
		else:
			draw_circle(centre, 24.0, Color(0.14, 0.12, 0.18))
			draw_arc(centre, 24.0, 0.0, TAU, 20, Color(r.teinte, 0.7), 2.0, true)
		Dessin.glyphe(self, r.glyphe, centre, 13.0, r.teinte)
		if int(entree[1]) > 1:
			draw_string(police, centre + Vector2(12.0, 22.0), "x%d" % int(entree[1]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.OR)
		x += 58.0

func _dessiner_barre_boss(boss: Node, police: Font, largeur: float, haut: float, tremble: Vector2) -> void:
	var ratio := clampf(float(boss.pv) / maxf(1.0, float(boss.pv_max)), 0.0, 1.0)
	var nom := str(boss.donnees.get("nom", "BOSS")).to_upper()
	var cadre := Rect2(Vector2(150.0, haut + 88.0) + tremble, Vector2(largeur - 300.0, 54.0))
	# Une ombre épaisse garde la barre lisible sur tous les décors, même sous un
	# barrage très lumineux.
	draw_rect(cadre.grow(7.0), Color(0.01, 0.008, 0.018, 0.90))
	draw_rect(cadre, Color(0.16, 0.035, 0.055, 0.94))
	var remplie := cadre.grow(-5.0)
	remplie.size.x *= ratio
	var couleur := Palette.DANGER.lerp(Palette.OR, ratio)
	draw_rect(remplie, couleur)
	draw_rect(cadre, Color(Palette.OR, 0.82), false, 4.0)
	draw_string(police, Vector2(cadre.position.x, cadre.position.y - 13.0), nom,
		HORIZONTAL_ALIGNMENT_CENTER, cadre.size.x, 26, Palette.TEXTE)
	draw_string(police, Vector2(cadre.position.x, cadre.position.y + 37.0), "%d / %d" % [
		maxi(0, ceili(float(boss.pv))), ceili(float(boss.pv_max))],
		HORIZONTAL_ALIGNMENT_CENTER, cadre.size.x, 24, Color.WHITE)
