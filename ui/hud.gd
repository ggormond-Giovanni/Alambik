extends Control

signal pause_demandee
signal sort_actif_demande
signal ultime_demande

var _secousse := 0.0
var _flash_degats := 0.0
var _anim := 0.0
var _bouton_pause: Button
var _bouton_actif: Button
var _bouton_ultime: Button
var _recharge_active := 0.0
var _charge_ultime := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Jeu.inventaire_change.connect(rafraichir)
	Jeu.experience_run_change.connect(rafraichir)
	ReglagesJoueur.maitrise_changee.connect(rafraichir)
	_bouton_pause = _creer_zone(func() -> void: pause_demandee.emit())
	_bouton_actif = _creer_zone(func() -> void: sort_actif_demande.emit())
	_bouton_ultime = _creer_zone(func() -> void: ultime_demande.emit())
	_replacer_boutons()
	get_viewport().size_changed.connect(_replacer_boutons)

func _creer_zone(action: Callable) -> Button:
	var bouton := StyleInterface.zone_tactile(action)
	add_child(bouton)
	return bouton

func _replacer_boutons() -> void:
	var taille := get_viewport_rect().size
	var haut := Ecran.marge_haute() + 12.0
	_bouton_pause.position = Vector2(18, haut)
	_bouton_pause.size = Vector2(130, 130)
	_bouton_actif.position = Vector2(taille.x - 164, taille.y - Ecran.marge_basse() - 365)
	_bouton_actif.size = Vector2(146, 146)
	_bouton_ultime.position = Vector2(taille.x - 164, taille.y - Ecran.marge_basse() - 535)
	_bouton_ultime.size = Vector2(146, 146)

func rafraichir_sorts(recharge_active: float, charge_ultime: int) -> void:
	_recharge_active = maxf(0.0, recharge_active)
	_charge_ultime = maxi(0, charge_ultime)
	var actif := ReglagesJoueur.sort_actif_effectif()
	var ultime := ReglagesJoueur.ultime_effectif()
	_bouton_actif.visible = Sorts.ACTIFS.has(actif)
	_bouton_ultime.visible = Sorts.ULTIMES.has(ultime)
	_bouton_actif.disabled = _recharge_active > 0.0
	if _bouton_ultime.visible:
		var d: Dictionary = Sorts.ULTIMES[ultime]
		var requis := ceili(float(d["charge"]) * Sorts.multiplicateur_charge_ultime(ReglagesJoueur.passifs_equipes_effectifs()))
		_bouton_ultime.disabled = _charge_ultime < requis
	queue_redraw()

func rafraichir() -> void:
	queue_redraw()

func secouer() -> void:
	if ReglagesJoueur.secousses_ecran:
		_secousse = 1.0

func impact_degats() -> void:
	_flash_degats = 1.0
	secouer()

func _process(delta: float) -> void:
	_anim += delta
	_secousse = maxf(0.0, _secousse - delta * 3.0)
	_flash_degats = maxf(0.0, _flash_degats - delta * 7.5)
	queue_redraw()

func _draw() -> void:
	var police := Polices.CORPS
	var taille := get_viewport_rect().size
	var haut := Ecran.marge_haute() + 12.0
	var tremble := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _secousse * 4.0
	_dessiner_flash(taille)
	_dessiner_pause(police, Rect2(Vector2(18, haut) + tremble, Vector2(130, 130)))
	_dessiner_progression(police, Rect2(Vector2(170, haut) + tremble, Vector2(710, 130)))
	_dessiner_points(police, Rect2(Vector2(taille.x - 178, haut) + tremble, Vector2(160, 130)))
	var boss := get_tree().get_first_node_in_group("boss")
	var boss_visible := boss != null and is_instance_valid(boss) and float(boss.pv_max) > 0.0
	if boss_visible:
		_dessiner_barre_boss(boss, police, Rect2(Vector2(130, haut + 154) + tremble, Vector2(taille.x - 260, 92)))
	_dessiner_ameliorations(police, haut + (276.0 if boss_visible else 158.0), taille.x)
	_dessiner_bouton_sort(police, _bouton_actif, false)
	_dessiner_bouton_sort(police, _bouton_ultime, true)

func _dessiner_flash(taille: Vector2) -> void:
	if _flash_degats <= 0.0:
		return
	var alpha := _flash_degats * (0.10 if ReglagesJoueur.effets_reduits else 0.17)
	var e := 34.0 + _flash_degats * 22.0
	draw_rect(Rect2(0, 0, taille.x, e), Color(Palette.DANGER, alpha))
	draw_rect(Rect2(0, taille.y - e, taille.x, e), Color(Palette.DANGER, alpha))
	draw_rect(Rect2(0, 0, e, taille.y), Color(Palette.DANGER, alpha))
	draw_rect(Rect2(taille.x - e, 0, e, taille.y), Color(Palette.DANGER, alpha))

func _dessiner_pause(police: Font, rect: Rect2) -> void:
	_cadre_decoupe(rect, Color(0.52, 0.67, 0.78), Color(0.025, 0.055, 0.085, 0.94), 17.0)
	Retro16.dessiner_icone_interface(self, 10, rect.grow(-29.0))
	_draw_centre(police, Vector2(rect.position.x, rect.end.y - 11), rect.size.x, "PAUSE", 15, Palette.TEXTE_ATTENUE)

func _dessiner_progression(police: Font, rect: Rect2) -> void:
	_cadre_decoupe(rect, Palette.OR, Color(0.025, 0.050, 0.080, 0.95), 18.0)
	var salle := "MINE %02d:%02d" % [ceili(Jeu.temps_mine_restant) / 60, ceili(Jeu.temps_mine_restant) % 60] if Jeu.mode_run == "mine" else "SALLE %02d / %02d" % [Jeu.salle_courante, Jeu.salles_du_chapitre()]
	if Jeu.est_retro(): salle = "VISION ENCHANTÉE"
	_draw_centre(police, rect.position + Vector2(20, 42), rect.size.x - 40, salle, 25, Palette.TEXTE)
	_draw_centre(police, rect.position + Vector2(20, 73), rect.size.x - 40, "NIVEAU %d" % Jeu.niveau_run, 18, Palette.OR)
	var xp := Jeu.experience_vers_prochain_niveau()
	var barre := Rect2(rect.position + Vector2(32, 91), Vector2(rect.size.x - 64, 18))
	_barre_premium(barre, clampf(float(xp["actuelle"]) / maxf(1.0, float(xp["requise"])), 0.0, 1.0), Palette.ESSENCE)

func _dessiner_points(police: Font, rect: Rect2) -> void:
	_cadre_decoupe(rect, Palette.ESSENCE, Color(0.025, 0.050, 0.080, 0.95), 17.0)
	Retro16.dessiner_icone_interface(self, 7, Rect2(rect.position + Vector2(12, 16), Vector2(45, 45)))
	draw_string(police, rect.position + Vector2(59, 29), "ESSENCE", HORIZONTAL_ALIGNMENT_LEFT, 84, 12, Palette.TEXTE_ATTENUE)
	draw_string(police, rect.position + Vector2(59, 55), ReglagesJoueur.gouttes_affichees(), HORIZONTAL_ALIGNMENT_LEFT, 84, 22, Palette.TEXTE)
	Retro16.dessiner_icone_interface(self, 8, Rect2(rect.position + Vector2(12, 71), Vector2(42, 42)))
	draw_string(police, rect.position + Vector2(59, 84), "AMÉLIOR.", HORIZONTAL_ALIGNMENT_LEFT, 84, 12, Palette.TEXTE_ATTENUE)
	draw_string(police, rect.position + Vector2(59, 110), str(Jeu.inventaire.size()), HORIZONTAL_ALIGNMENT_LEFT, 80, 22, Palette.TEXTE)

func _dessiner_ameliorations(police: Font, y: float, largeur: float) -> void:
	var groupe := Jeu.inventaire_groupe()
	if groupe.is_empty():
		return
	var total := groupe.size()
	var espace := 66.0
	var x := largeur * 0.5 - float(total - 1) * espace * 0.5
	for entree in groupe:
		var id: String = entree[0]
		var reactif := Jeu.reactif(id)
		if reactif == null: continue
		var rect := Rect2(Vector2(x - 28, y - 28), Vector2(56, 56))
		_cadre_decoupe(rect, reactif.teinte, Color(0.025, 0.035, 0.065, 0.92), 8.0, 2.0)
		Dessin.glyphe(self, reactif.glyphe, Vector2(x, y), 14.0, reactif.teinte)
		if int(entree[1]) > 1:
			draw_string(police, Vector2(x + 13, y + 27), "×%d" % int(entree[1]), HORIZONTAL_ALIGNMENT_LEFT, 38, 17, Palette.OR)
		x += espace

func _dessiner_barre_boss(boss: Node, police: Font, rect: Rect2) -> void:
	var ratio := clampf(float(boss.pv) / maxf(1.0, float(boss.pv_max)), 0.0, 1.0)
	var nom := str(boss.donnees.get("nom", "BOSS")).to_upper()
	_cadre_decoupe(rect, Palette.OR, Color(0.035, 0.025, 0.050, 0.96), 18.0)
	_draw_centre(police, rect.position + Vector2(22, 33), rect.size.x - 44, nom, 24, Palette.TEXTE)
	var barre := Rect2(rect.position + Vector2(28, 48), Vector2(rect.size.x - 56, 25))
	_barre_premium(barre, ratio, Palette.DANGER.lerp(Palette.OR, ratio))
	_draw_centre(police, rect.position + Vector2(20, 72), rect.size.x - 40, "%d / %d" % [maxi(0, ceili(float(boss.pv))), ceili(float(boss.pv_max))], 16, Color.WHITE)

func _dessiner_bouton_sort(police: Font, bouton: Button, ultime: bool) -> void:
	if bouton == null or not bouton.visible:
		return
	var rect := Rect2(bouton.position, bouton.size)
	var accent := Palette.ESSENCE if ultime else Palette.OR
	_cadre_decoupe(rect, accent, Color(0.025, 0.030, 0.065, 0.95), 22.0)
	var id := ReglagesJoueur.ultime_effectif() if ultime else ReglagesJoueur.sort_actif_effectif()
	var icone := posmod(_icone_sort(id) + (5 if ultime else 0), 15)
	Retro16.dessiner_icone_interface(self, icone, rect.grow(-28.0), Color.WHITE if not bouton.disabled else Color(0.48, 0.50, 0.58))
	var ratio := 0.0
	var texte := "PRÊT"
	if ultime:
		var d: Dictionary = Sorts.ULTIMES.get(id, {})
		var requis := ceili(float(d.get("charge", 1)) * Sorts.multiplicateur_charge_ultime(ReglagesJoueur.passifs_equipes_effectifs()))
		ratio = clampf(float(_charge_ultime) / maxf(1.0, float(requis)), 0.0, 1.0)
		texte = "%d / %d" % [mini(_charge_ultime, requis), requis]
	else:
		var d: Dictionary = Sorts.ACTIFS.get(id, {})
		var recharge_max := float(d.get("recharge", 1.0)) * Sorts.multiplicateur_recharge_active(ReglagesJoueur.passifs_equipes_effectifs())
		ratio = 1.0 - clampf(_recharge_active / maxf(0.01, recharge_max), 0.0, 1.0)
		texte = "%.1f s" % _recharge_active if _recharge_active > 0.0 else "PRÊT"
	var jauge := Rect2(rect.position + Vector2(17, rect.size.y - 24), Vector2(rect.size.x - 34, 10))
	_barre_premium(jauge, ratio, accent)
	_draw_centre(police, Vector2(rect.position.x, rect.end.y + 22), rect.size.x, texte, 18, Palette.TEXTE)
	# Un raccourci invisible n'est jamais utilise : l'icone rappelle le geste
	# choisi dans les Réglages tant qu'il en existe un.
	if not ultime and RaccourciTactile.tapes_requises(ReglagesJoueur.raccourci_sort) > 0:
		_draw_centre(police, Vector2(rect.position.x - 20, rect.end.y + 44), rect.size.x + 40,
			"TAPE ×%d" % RaccourciTactile.tapes_requises(ReglagesJoueur.raccourci_sort),
			14, Palette.TEXTE_ATTENUE)

func _icone_sort(id: String) -> int:
	var clefs: Array[String] = []
	for catalogue in [Sorts.ACTIFS, Sorts.PASSIFS, Sorts.ULTIMES]:
		for cle in catalogue:
			if cle not in clefs: clefs.append(cle)
	return posmod(clefs.find(id) + 8, 15)

func _barre_premium(rect: Rect2, ratio: float, couleur: Color) -> void:
	draw_rect(rect.grow(5.0), Color(0.01, 0.015, 0.028, 0.96))
	draw_rect(rect, Color(0.08, 0.075, 0.10, 0.96))
	var pleine := rect.grow(-3.0)
	pleine.size.x *= clampf(ratio, 0.0, 1.0)
	draw_rect(pleine, couleur.darkened(0.20))
	if pleine.size.x > 5.0:
		draw_rect(Rect2(pleine.position, Vector2(pleine.size.x, maxf(2.0, pleine.size.y * 0.32))), couleur.lightened(0.22))
	draw_rect(rect, Color(Palette.OR, 0.68), false, 3.0)

func _cadre_decoupe(rect: Rect2, accent: Color, fond: Color, coupe: float, epaisseur := 4.0) -> void:
	var points := _points_coupes(rect, coupe)
	draw_colored_polygon(points, Color(0.008, 0.014, 0.026, 0.96))
	Dessin.contour(self, points, Color(accent, 0.92), epaisseur)
	var interieur := rect.grow(-6.0)
	var dedans := _points_coupes(interieur, maxf(3.0, coupe - 5.0))
	draw_colored_polygon(dedans, fond)
	Dessin.contour(self, dedans, Color(accent, 0.32), 2.0)

func _points_coupes(rect: Rect2, coupe: float) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position + Vector2(coupe, 0), Vector2(rect.end.x - coupe, rect.position.y),
		Vector2(rect.end.x, rect.position.y + coupe), Vector2(rect.end.x, rect.end.y - coupe),
		Vector2(rect.end.x - coupe, rect.end.y), Vector2(rect.position.x + coupe, rect.end.y),
		Vector2(rect.position.x, rect.end.y - coupe), Vector2(rect.position.x, rect.position.y + coupe),
	])

func _draw_centre(police: Font, position: Vector2, largeur: float, texte: String,
		taille_police: int, couleur: Color) -> void:
	draw_string(police, position, texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille_police, couleur)
