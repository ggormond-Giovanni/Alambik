extends Control

# Les multiples de trois offrent un reactif capable d'entrer dans une fusion.
# Les autres pages donnent de petits bonus de run qui ne polluent pas l'alambic.

signal termine

var _colonne: VBoxContainer
var _anim := 0.0
var _choisi := false
var etage_recompense := 1
var forcer_reactif := false
var forcer_basique := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	StyleInterface.animer_entree(self)
	if Jeu.mode_auto:
		_choisir_automatiquement()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 50)
	marge.add_theme_constant_override("margin_right", 50)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 200)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 60)
	add_child(marge)

	_colonne = VBoxContainer.new()
	_colonne.add_theme_constant_override("separation", 26)
	_colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	marge.add_child(_colonne)

	var heros := get_tree().get_first_node_in_group("heros")
	var est_blesse: bool = heros != null and heros.stats.pv < heros.stats.pv_max
	var page_reactif := forcer_reactif or (not forcer_basique and DraftLogique.est_page_de_reactif(etage_recompense))
	var propositions := DraftLogique.avec_repos(DraftLogique.proposer(Jeu.inventaire, Jeu.rng), etage_recompense, est_blesse) \
		if page_reactif else DraftLogique.proposer_basiques(Jeu.rng)
	for id in propositions:
		var reactif := Jeu.reactif(id) if page_reactif else DraftLogique.bonus_basique(id)
		if id == DraftLogique.REPOS:
			reactif = Reactif.creer(DraftLogique.REPOS, "Page de repos",
				"Le grimoire vous laisse souffler : %d %% des points de vie rendus." % roundi(Reglages.SOIN_REPOS * 100.0),
				{}, false, Color(0.55, 0.92, 0.62), "fiole")
		if reactif == null:
			continue
		var carte := CarteReactif.new()
		carte.configurer(reactif)
		carte.montrer_composants = true
		carte.choisie.connect(_sur_choix)
		_colonne.add_child(carte)

func _sur_choix(id: String) -> void:
	if _choisi:
		return
	_choisi = true
	if id == DraftLogique.REPOS:
		var heros := get_tree().get_first_node_in_group("heros")
		if heros != null:
			heros.stats.soigner(heros.stats.pv_max * Reglages.SOIN_REPOS \
				* ArbreCompetences.multiplicateur_soin(ReglagesJoueur.rangs_competences_effectifs()))
		termine.emit()
		return
	if DraftLogique.BONUS_BASIQUES.has(id):
		_appliquer_bonus_basique(id)
		termine.emit()
		return
	# Une essence prise au draft consomme ses deux composants, exactement comme
	# a l'alambic : sinon fusionner serait un cadeau, et le choix disparaitrait.
	var essence := CatalogueEssences.par_id(id)
	if essence != null:
		Jeu.retirer_reactifs(Recettes.composants_de(id))
	Jeu.ajouter_reactif(id)
	termine.emit()

func _appliquer_bonus_basique(id: String) -> void:
	var heros := get_tree().get_first_node_in_group("heros")
	match id:
		"bonus_attaque":
			Jeu.bonus_run["degats"] = float(Jeu.bonus_run["degats"]) + Reglages.BONUS_SIMPLE_DEGATS
		"bonus_defense":
			Jeu.bonus_run["reduction"] = float(Jeu.bonus_run["reduction"]) + Reglages.BONUS_SIMPLE_REDUCTION
		"bonus_vitalite":
			if heros != null:
				heros.stats.pv_max += Reglages.BONUS_SIMPLE_PV
				heros.stats.soigner(Reglages.BONUS_SIMPLE_PV)
		"bonus_soin":
			if heros != null:
				heros.stats.soigner(heros.stats.pv_max * Reglages.BONUS_SIMPLE_SOIN \
					* ArbreCompetences.multiplicateur_soin(ReglagesJoueur.rangs_competences_effectifs()))

func _choisir_automatiquement() -> void:
	# Le bot prend la premiere proposition : il ne joue pas bien, il traverse.
	await get_tree().create_timer(0.2).timeout
	if _choisi or _colonne.get_child_count() == 0:
		return
	_sur_choix(_colonne.get_child(0).reactif.id)

func _draw() -> void:
	var police := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.018, 0.014, 0.034, 0.94))
	Dessin.halo(self, Vector2(size.x * 0.5, 0.0), 430.0, Color(Palette.ESSENCE, 0.18), 7)
	var haut := Ecran.marge_haute() + 90.0
	draw_string(police, Vector2(58.0, haut - 38.0), "ÉTAGE %d TERMINÉ — RÉCOMPENSE" % etage_recompense,
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 116.0, 22, Color(Palette.OR, 0.9))
	var reactif := forcer_reactif or (not forcer_basique and DraftLogique.est_page_de_reactif(etage_recompense))
	var titre := "Choisissez un réactif" if reactif else "Choisissez un petit renfort"
	draw_string(police, Vector2(58.0, haut + 16.0), titre,
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 116.0, 46, Palette.TEXTE)
	draw_string(police, Vector2(0, haut + 70.0), "%s — page %d / %d" % [
		Jeu.chapitre_courant()["nom"], Jeu.salle_courante, Jeu.salles_du_chapitre()],
		HORIZONTAL_ALIGNMENT_RIGHT, size.x - 58.0, 25, Palette.TEXTE_ATTENUE)
	# Un filet d'encre anime en haut de page : la pause reste vivante.
	var y := haut + 92.0
	var trace := PackedVector2Array()
	for i in 41:
		var t := float(i) / 40.0
		trace.append(Vector2(lerpf(60.0, size.x - 60.0, t), y + sin(t * 8.0 + _anim * 1.5) * 5.0))
	draw_polyline(trace, Color(Palette.OR, 0.35), 2.0, true)
