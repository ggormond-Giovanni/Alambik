extends Control

# Barre de vie, salle courante, inventaire. Dessine, jamais compose de sprites,
# et pose sous la safe area : sur telephone, l'encoche mange le haut.

var _secousse := 0.0
var _anim := 0.0
signal pause_demandee
signal sort_actif_demande
signal ultime_demande

var _style_compact: StyleBoxFlat
var _style_progression: StyleBoxFlat
var _style_remplissage: StyleBoxFlat
var _bouton_pause: Button
var _bouton_actif: Button
var _bouton_ultime: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Jeu.inventaire_change.connect(rafraichir)
	Jeu.experience_changee.connect(rafraichir)
	ReglagesJoueur.maitrise_changee.connect(rafraichir)
	_style_compact = StyleInterface.panneau(Color(0.035, 0.045, 0.060, 0.94), Color(Palette.BORD_PAGE, 0.42), 20, 7)
	_style_progression = StyleInterface.panneau(Color(0.018, 0.026, 0.038, 0.94), Color(0.0, 0.0, 0.0, 0.55), 13, 3)
	_style_remplissage = StyleInterface.panneau(Color(0.84, 0.58, 0.18), Color(1.0, 0.82, 0.38, 0.75), 10, 0)
	_bouton_pause = Button.new()
	_bouton_pause.text = "Ⅱ"
	_bouton_pause.custom_minimum_size = Vector2(82.0, 82.0)
	_bouton_pause.size = Vector2(82.0, 82.0)
	_bouton_pause.add_theme_font_size_override("font_size", 34)
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
		_bouton_pause.position = Vector2(28.0, Ecran.marge_haute() + 14.0)
	var taille := get_viewport_rect().size
	if _bouton_actif != null:
		_bouton_actif.position = Vector2(taille.x - 142.0, taille.y - Ecran.marge_basse() - 350.0)
	if _bouton_ultime != null:
		_bouton_ultime.position = Vector2(taille.x - 142.0, taille.y - Ecran.marge_basse() - 494.0)

func _creer_bouton_sort(couleur: Color) -> Button:
	var bouton := Button.new()
	bouton.custom_minimum_size = Vector2(116, 116)
	bouton.size = Vector2(116, 116)
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

func _process(delta: float) -> void:
	_anim += delta
	_secousse = maxf(0.0, _secousse - delta * 3.0)
	queue_redraw()

func _draw() -> void:
	var police := ThemeDB.fallback_font
	var largeur := get_viewport_rect().size.x
	var haut := Ecran.marge_haute() + 28.0
	var tremble := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _secousse * 4.0
	var centre_x := largeur * 0.5
	var panneau_progression := Rect2(Vector2(142.0, haut - 12.0) + tremble, Vector2(largeur - 294.0, 102.0))
	draw_style_box(_style_compact, panneau_progression)
	draw_string(police, Vector2(panneau_progression.position.x, haut + 25.0), "NIV %02d  •  PAGE %02d" % [Jeu.niveau, Jeu.salle_courante],
		HORIZONTAL_ALIGNMENT_CENTER, panneau_progression.size.x, 31, Palette.TEXTE)
	draw_string(police, Vector2(panneau_progression.position.x, haut + 48.0), "%s  —  XP %d / %d" % [Jeu.chapitre_courant()["nom"], Jeu.experience, Jeu.experience_requise()],
		HORIZONTAL_ALIGNMENT_CENTER, panneau_progression.size.x, 19, Palette.TEXTE_ATTENUE)
	var barre := Rect2(panneau_progression.position + Vector2(24.0, 69.0), Vector2(panneau_progression.size.x - 48.0, 18.0))
	draw_style_box(_style_progression, barre)
	var progression := clampf(float(Jeu.experience) / float(maxi(1, Jeu.experience_requise())), 0.02, 1.0)
	var remplie := Rect2(barre.position + Vector2(3.0, 3.0), Vector2((barre.size.x - 6.0) * progression, barre.size.y - 6.0))
	draw_style_box(_style_remplissage, remplie)

	var compteur := Rect2(largeur - 126.0, haut - 12.0, 98.0, 82.0)
	draw_style_box(_style_compact, compteur)
	var gemme := Dessin.polygone_regulier(Vector2(compteur.position.x + 29.0, compteur.position.y + 41.0), 14.0, 4, PI * 0.25)
	draw_colored_polygon(gemme, Palette.ESSENCE)
	draw_string(police, Vector2(compteur.position.x + 48.0, compteur.position.y + 52.0), str(Jeu.inventaire.size()),
		HORIZONTAL_ALIGNMENT_LEFT, 42.0, 28, Palette.TEXTE)
	draw_string(police, Vector2(compteur.position.x - 8.0, compteur.position.y + 104.0), "✦ %s" % ReglagesJoueur.points_maitrise_affiches(),
		HORIZONTAL_ALIGNMENT_CENTER, compteur.size.x + 16.0, 22, Palette.ESSENCE)

	# Inventaire : une pastille par reactif, teintee et glyphee. C'est la seule
	# trace visible de ce que le joueur a construit pendant la run.
	var x := centre_x - float(Jeu.inventaire_groupe().size() - 1) * 29.0
	var y := haut + 124.0
	for entree in Jeu.inventaire_groupe():
		var id: String = entree[0]
		var r := Jeu.reactif(id)
		if r == null:
			continue
		var centre := Vector2(x, y)
		if r.est_essence:
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
