extends Control

signal termine

var etage_recompense := 1
var _recompense := {}
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_recompense = Recompenses.tirer_epreuve(Jeu.rng, ReglagesJoueur.rangs_sorts, ReglagesJoueur.niveau_heros_effectif())
	if _recompense["type"] == "gouttes":
		ReglagesJoueur.ajouter_gouttes(int(_recompense["quantite"]))
	else:
		ReglagesJoueur.debloquer_sort(str(_recompense["id"]))
	_construire()
	StyleInterface.animer_entree(self)
	if Jeu.mode_auto:
		await get_tree().create_timer(0.15).timeout
		termine.emit()

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 62)
	marge.add_theme_constant_override("margin_right", 62)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 90)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_END
	marge.add_child(colonne)
	var continuer := Button.new()
	continuer.text = "CONTINUER LE DÉFI" if etage_recompense < Jeu.salles_du_chapitre() else "TERMINER LE DÉFI"
	continuer.custom_minimum_size = Vector2(0, 132)
	continuer.add_theme_font_size_override("font_size", 31)
	StyleInterface.styliser_bouton(continuer, Palette.ESSENCE)
	continuer.pressed.connect(func() -> void: termine.emit())
	colonne.add_child(continuer)

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.045, 0.96))
	var police := ThemeDB.fallback_font
	var centre := Vector2(size.x * 0.5, size.y * 0.43)
	Dessin.halo(self, centre, 300.0, Color(Palette.ESSENCE, 0.36), 7)
	draw_string(police, Vector2(0, centre.y - 210.0), "BOSS %d / 3 VAINCU" % int(etage_recompense / 4),
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Palette.TEXTE_ATTENUE)
	if _recompense["type"] == "gouttes":
		draw_colored_polygon(Dessin.goutte(centre, 92.0 + sin(_anim * 3.0) * 4.0, PI, 1.2), Palette.ESSENCE)
		draw_string(police, Vector2(0, centre.y + 155.0), "+%d GOUTTES" % int(_recompense["quantite"]),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 46, Palette.ESSENCE)
	else:
		var donnees := Sorts.donnees(str(_recompense["id"]))
		draw_colored_polygon(Dessin.etoile(centre, 96.0, 42.0, 7, _anim * 0.25), Palette.OR)
		draw_string(police, Vector2(0, centre.y + 146.0), str(donnees["nom"]).to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 42, Palette.OR)
		draw_string(police, Vector2(90.0, centre.y + 202.0), str(donnees["description"]),
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 180.0, 25, Palette.TEXTE_ATTENUE)
		draw_string(police, Vector2(0, centre.y + 262.0), "%s • NIVEAU %d / 5 • %d %%" % [
			str(_recompense["type"]).to_upper(), ReglagesJoueur.rang_sort(str(_recompense["id"])),
			roundi(ReglagesJoueur.efficacite_sort(str(_recompense["id"])) * 100.0)],
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 25, Palette.ESSENCE)
