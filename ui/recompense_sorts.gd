extends Control

const FOND_PREMIUM := preload("res://assets/visual/recompense_sort_premium.png")

signal termine

var etage_recompense := 1
var _recompense := {}
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_recompense = Recompenses.tirer_epreuve(Jeu.rng, ReglagesJoueur.rangs_sorts)
	if _recompense["type"] == "gouttes":
		ReglagesJoueur.ajouter_gouttes(int(_recompense["quantite"]))
	else:
		ReglagesJoueur.debloquer_sort(str(_recompense["id"]))
	_construire()
	StyleInterface.animer_entree(self)
	if Jeu.mode_auto:
		await get_tree().create_timer(0.15).timeout
		_quitter()

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 104)
	marge.add_theme_constant_override("margin_right", 104)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 78)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_END
	marge.add_child(colonne)
	var continuer := Button.new()
	continuer.text = "CONTINUER LE DÉFI" if etage_recompense < Jeu.salles_du_chapitre() else "TERMINER LE DÉFI"
	continuer.custom_minimum_size = Vector2(0, 174)
	continuer.add_theme_font_size_override("font_size", 31)
	continuer.flat = true
	continuer.add_theme_color_override("font_color", Palette.TEXTE)
	continuer.add_theme_color_override("font_hover_color", Color.WHITE)
	continuer.pressed.connect(_quitter)
	colonne.add_child(continuer)

func _quitter() -> void:
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	FondAdaptatif.dessiner_premium(self, FOND_PREMIUM, size, 1120.0, 800.0)
	var police := Polices.CORPS
	draw_string(police, Vector2(72.0, size.y * 0.105), "RÉCOMPENSE DU MINIBOSS", HORIZONTAL_ALIGNMENT_CENTER,
		size.x - 144.0, 37, Palette.TEXTE)
	draw_string(police, Vector2(72.0, size.y * 0.145), "VICTOIRE %d / 5" % etage_recompense,
		HORIZONTAL_ALIGNMENT_CENTER, size.x - 144.0, 24, Palette.TEXTE_ATTENUE)
	if _recompense["type"] == "gouttes":
		draw_string(police, Vector2(82.0, size.y * 0.675), "+%d GOUTTES D'ESSENCE" % int(_recompense["quantite"]),
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 164.0, 42, Palette.ESSENCE)
		draw_string(police, Vector2(92.0, size.y * 0.742), "La récompense a été ajoutée à votre réserve.",
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 184.0, 24, Palette.TEXTE_ATTENUE)
	else:
		var donnees := Sorts.donnees(str(_recompense["id"]))
		draw_string(police, Vector2(82.0, size.y * 0.675), str(donnees["nom"]).to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 164.0, 42, Palette.OR)
		draw_string(police, Vector2(92.0, size.y * 0.742), str(donnees["description"]),
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 184.0, 24, Palette.TEXTE_ATTENUE)
		draw_string(police, Vector2(82.0, size.y * 0.806), "%s • RANG %d / %d • %d %%" % [
			str(_recompense["type"]).to_upper(), ReglagesJoueur.rang_sort(str(_recompense["id"])),
			Reglages.CAPACITE_RANG_MAX, roundi(ReglagesJoueur.efficacite_sort(str(_recompense["id"])) * 100.0)],
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 164.0, 25, Palette.ESSENCE)
