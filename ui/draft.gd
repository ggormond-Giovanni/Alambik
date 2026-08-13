extends Control

# Le level-up interrompt le combat au moment exact ou l'XP franchit un seuil.
# Une Maitrise peut renouveler les trois propositions sans changer le niveau.

signal termine

var _colonne: VBoxContainer
var _choisi := false
var _propositions: Array[String] = []
var _bouton_reroll: Button
var _anim := 0.0
var etage_recompense := 1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	_nouveau_tirage()
	StyleInterface.animer_entree(self)
	if Jeu.mode_auto:
		_choisir_automatiquement()

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 50)
	marge.add_theme_constant_override("margin_right", 50)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 210)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 55)
	add_child(marge)
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", 22)
	marge.add_child(contenu)
	_colonne = VBoxContainer.new()
	_colonne.add_theme_constant_override("separation", 22)
	_colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	_colonne.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenu.add_child(_colonne)
	_bouton_reroll = Button.new()
	_bouton_reroll.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	_bouton_reroll.add_theme_font_size_override("font_size", 27)
	StyleInterface.styliser_bouton(_bouton_reroll, Palette.ESSENCE, true)
	_bouton_reroll.pressed.connect(_sur_reroll)
	contenu.add_child(_bouton_reroll)
	_rafraichir_reroll()

func _nouveau_tirage() -> void:
	_propositions = DraftLogique.proposer(Jeu.inventaire, Jeu.rng)
	for enfant in _colonne.get_children():
		enfant.queue_free()
	for id in _propositions:
		var carte := CarteReactif.new()
		carte.configurer(CatalogueReactifs.par_id(id))
		carte.choisie.connect(_sur_choix)
		_colonne.add_child(carte)
	call_deferred("_animer_propositions")

func _animer_propositions() -> void:
	if is_instance_valid(_colonne):
		StyleInterface.animer_liste(_colonne)

func _sur_reroll() -> void:
	if _choisi or Jeu.rerolls_restants <= 0:
		return
	_bouton_reroll.disabled = true
	var sortie := create_tween()
	sortie.tween_property(_colonne, "modulate:a", 0.0,
		0.08 if ReglagesJoueur.effets_reduits else 0.16)
	await sortie.finished
	Jeu.rerolls_restants -= 1
	_nouveau_tirage()
	_colonne.modulate.a = 1.0
	_rafraichir_reroll()
	_bouton_reroll.disabled = false

func _rafraichir_reroll() -> void:
	_bouton_reroll.visible = Jeu.rerolls_restants > 0
	_bouton_reroll.text = "NOUVEAU TIRAGE  •  %d" % Jeu.rerolls_restants

func _sur_choix(id: String) -> void:
	if _choisi:
		return
	_choisi = true
	Jeu.ajouter_reactif(id)
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _choisir_automatiquement() -> void:
	await get_tree().create_timer(0.12).timeout
	if not _choisi and not _propositions.is_empty():
		_sur_choix(_propositions[0])

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	var police := ThemeDB.fallback_font
	StyleInterface.dessiner_fond(self, size, Palette.ESSENCE, _anim, 0.97)
	Dessin.halo(self, Vector2(size.x * 0.5, 0.0), 430.0, Color(Palette.ESSENCE, 0.20), 7)
	var haut := Ecran.marge_haute() + 92.0
	draw_string(police, Vector2(58.0, haut - 38.0), "NIVEAU DE RUN %d / 6" % etage_recompense,
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 116.0, 22, Palette.OR)
	draw_string(police, Vector2(58.0, haut + 16.0), "Choisissez un Augment",
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 116.0, 46, Palette.TEXTE)
	draw_string(police, Vector2(0.0, haut + 70.0), "Le combat reprendra immédiatement après votre choix.",
		HORIZONTAL_ALIGNMENT_RIGHT, size.x - 58.0, 24, Palette.TEXTE_ATTENUE)
	var trace := PackedVector2Array()
	for i in 41:
		var t := float(i) / 40.0
		trace.append(Vector2(lerpf(60.0, size.x - 60.0, t), haut + 94.0 + sin(t * 8.0 + _anim * 1.5) * 5.0))
	draw_polyline(trace, Color(Palette.OR, 0.35), 2.0, true)
