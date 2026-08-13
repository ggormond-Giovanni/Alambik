extends Node

# Orchestrateur : enchaine vingt salles, six niveaux et trois alambics,
# et pose le boss a la derniere. Le heros lui appartient, pas a la salle : ses
# PV et son inventaire traversent la run.

const SALLE := preload("res://scenes/salle.tscn")
const HEROS := preload("res://scenes/heros.tscn")
const DRAFT := preload("res://ui/draft.tscn")
const ALAMBIC := preload("res://ui/alambic.tscn")
const FIN := preload("res://ui/fin_de_run.tscn")
const HUD := preload("res://ui/hud.tscn")
const JOYSTICK := preload("res://ui/joystick.tscn")
const PAUSE := preload("res://ui/pause.tscn")
const RECOMPENSE_SORTS := preload("res://ui/recompense_sorts.tscn")
const BOT := preload("res://sondes/bot.gd")
const VOILE_TRANSITION := preload("res://scripts/voile_transition.gd")

var _fond: Node2D
var _salle: Node2D
var _heros: CharacterBody2D
var _effets: Node2D
var _hud: Control
var _joystick: Control
var _couche: CanvasLayer
var _panneau: Control
var _limites := Rect2()
var _terminee := false
var _temps_dans_la_salle := 0.0
var _musique_minuterie := 0.0
var _recharge_sort_actif := 0.0
var _charge_ultime := 0
var _compteur_moisson := 0
var _compteur_sang_froid := 0
var _niveaux_en_attente := 0
var _familier_minuterie := 0.0
var _meteore_minuterie := 0.0
var _zone_minuterie := 0.0
var _orbe_minuterie := 0.0
var _orbes_chargees := 0
var _gardien: Gardien
var _fin_salle_en_attente := false
var _camera: Camera2D
var _voile_salle: Control
var _titre_voile: Label
var _sous_titre_voile: Label
var _transition_salle := false

func _ready() -> void:
	if OS.get_name() == "Android":
		get_tree().set_auto_accept_quit(false)
	var arguments := OS.get_cmdline_user_args()
	Jeu.mode_auto = "--auto" in arguments
	var mode_argument := _texte_argument(arguments, "--mode=")
	Jeu.demarrer_run(_valeur_argument(arguments, "--graine="), maxi(1, _valeur_argument(arguments, "--salle=")),
		maxi(0, _valeur_argument(arguments, "--chapitre=") - 1) if _valeur_argument(arguments, "--chapitre=") > 0 else ReglagesJoueur.chapitre_choisi,
		mode_argument if not mode_argument.is_empty() else ReglagesJoueur.mode_run_choisi)
	# --dote=N remplit l'inventaire : c'est ce qui permet d'aller regarder
	# l'alambic ou le boss sans rejouer huit salles a chaque essai.
	var dote := _valeur_argument(arguments, "--dote=")
	if dote > 0:
		# Sans remise : l'inventaire d'une vraie run ne contient jamais deux fois
		# le meme reactif, et un outil qui ment sur l'etat teste ne sert a rien.
		var candidats := CatalogueReactifs.ids()
		for i in mini(dote, candidats.size()):
			var index := Jeu.rng.randi_range(0, candidats.size() - 1)
			Jeu.ajouter_reactif(candidats[index])
			candidats.remove_at(index)
	if ReglagesJoueur.passifs_equipes_effectifs().has("heritage_reactif"):
		var heritage := CatalogueReactifs.ids()
		if not heritage.is_empty():
			Jeu.ajouter_reactif(heritage[Jeu.rng.randi_range(0, heritage.size() - 1)])
	Jeu.run_terminee.connect(_sur_run_terminee)

	_camera = Camera2D.new()
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.enabled = Jeu.mode_run == "mine"
	add_child(_camera)
	_calculer_limites()
	get_tree().get_root().size_changed.connect(_calculer_limites)

	_fond = Node2D.new()
	_fond.set_script(load("res://scripts/fond.gd"))
	add_child(_fond)

	_salle = SALLE.instantiate()
	add_child(_salle)
	_salle.ennemi_abattu.connect(_sur_ennemi_abattu)

	_heros = HEROS.instantiate()
	add_child(_heros)
	_heros.limites = _limites
	_heros.tir_demande.connect(_sur_tir_heros)
	_heros.touchee.connect(_sur_heros_touche)
	_heros.bouclier_brise.connect(_sur_bouclier_brise)
	_heros.morte.connect(func(): Jeu.terminer_run(false))

	_effets = Node2D.new()
	_effets.set_script(load("res://scripts/effets.gd"))
	add_child(_effets)

	_couche = CanvasLayer.new()
	add_child(_couche)
	_hud = HUD.instantiate()
	_couche.add_child(_hud)
	_hud.pause_demandee.connect(func() -> void:
		if not _terminee and _panneau == null:
			_ouvrir_pause())
	_hud.sort_actif_demande.connect(_lancer_sort_actif)
	_hud.ultime_demande.connect(_lancer_ultime)
	_hud.rafraichir_sorts(_recharge_sort_actif, _charge_ultime)
	_joystick = JOYSTICK.instantiate()
	_couche.add_child(_joystick)
	_joystick.intention_changee.connect(_sur_intention)
	var cadre_retro := Control.new()
	cadre_retro.set_script(load("res://scripts/cadre_retro.gd"))
	_couche.add_child(cadre_retro)
	_construire_voile_salle()

	if Jeu.mode_auto:
		var bot := Node.new()
		bot.set_script(BOT)
		bot.bavard = "--bavard" in arguments
		add_child(bot)

	_entrer_dans_la_salle()
	_animer_entree_salle()
	Capture.programmer(self)

# En mode auto, une salle qui ne se termine pas est un blocage, pas une
# difficulte. On veut le savoir avec l'etat de la salle, pas par un silence.
func _physics_process(_delta: float) -> void:
	if not _terminee and _panneau == null:
		Jeu.images_de_jeu += 1

func _process(delta: float) -> void:
	_recharge_sort_actif = maxf(0.0, _recharge_sort_actif - delta)
	if _hud != null:
		_hud.rafraichir_sorts(_recharge_sort_actif, _charge_ultime)
	_avancer_phenomenes(delta)
	_musique_minuterie -= delta
	if _musique_minuterie <= 0.0 and not _terminee and _panneau == null:
		_musique_minuterie = 0.35
		if Jeu.est_boss_courant():
			Sons.musique_boss()
		else:
			var menaces := get_tree().get_nodes_in_group("ennemis").size()
			Sons.musique_combat(clampf(float(menaces) / 7.0, 0.25, 1.0))
	if not Jeu.mode_auto or _terminee or _panneau != null:
		return
	_temps_dans_la_salle += delta
	var delai_blocage := Reglages.MINE_DUREE + 120.0 if Jeu.mode_run == "mine" else 120.0
	if _temps_dans_la_salle < delai_blocage:
		return
	var restants := get_tree().get_nodes_in_group("ennemis")
	var ou := ""
	for e in restants:
		if is_instance_valid(e):
			ou += "%s(pv=%d) " % [str(e.global_position.round()), roundi(e.pv)]
	print("BLOCAGE salle %d apres %ds : ennemis restants=%d %s heros=%s tirs=%d touches=%d murs=%d perdus=%d" % [
		Jeu.salle_courante, roundi(_temps_dans_la_salle), restants.size(), ou,
		str(_heros.global_position.round()), Jeu.tirs_emis, Jeu.tirs_touches,
		Jeu.tirs_dans_un_mur, Jeu.tirs_perdus])
	Jeu.terminer_run(false)

func _valeur_argument(arguments: PackedStringArray, prefixe: String) -> int:
	for argument in arguments:
		if argument.begins_with(prefixe):
			return int(argument.substr(prefixe.length()))
	return 0

func _texte_argument(arguments: PackedStringArray, prefixe: String) -> String:
	for argument in arguments:
		if argument.begins_with(prefixe):
			return argument.substr(prefixe.length())
	return ""

func _calculer_limites() -> void:
	var taille := get_viewport().get_visible_rect().size
	if Jeu.mode_run == "mine":
		var zoom := Reglages.MINE_CAMERA_ZOOM
		var taille_monde := taille / zoom
		var haut_mine := (Reglages.ARENE_HAUT + Ecran.marge_haute()) / zoom
		var bas_mine := (Reglages.ARENE_BAS + Ecran.marge_basse()) / zoom
		_limites = Rect2(
			Vector2(Reglages.ARENE_MARGE_LATERALE / zoom, haut_mine),
			Vector2(taille_monde.x - 2.0 * Reglages.ARENE_MARGE_LATERALE / zoom,
				maxf(850.0, taille_monde.y - haut_mine - bas_mine)))
		if _camera != null:
			_camera.zoom = Vector2.ONE * zoom
			_camera.global_position = taille_monde / 2.0
		if _heros != null:
			_heros.limites = _limites
		return
	var haut := Reglages.ARENE_HAUT + Ecran.marge_haute()
	var bas := Reglages.ARENE_BAS + Ecran.marge_basse()
	_limites = Rect2(
		Vector2(Reglages.ARENE_MARGE_LATERALE, haut),
		Vector2(taille.x - 2.0 * Reglages.ARENE_MARGE_LATERALE, maxf(600.0, taille.y - haut - bas)))
	if _heros != null:
		_heros.limites = _limites

func _entrer_dans_la_salle() -> void:
	for enfant in _salle.get_children():
		enfant.queue_free()
	_calculer_limites()
	_fond.preparer(_limites, Jeu.salle_courante)
	_salle.effets = _effets
	if not _salle.terminee.is_connected(_sur_salle_terminee):
		_salle.terminee.connect(_sur_salle_terminee)
	_heros.global_position = Vector2((_limites.position.x + _limites.end.x) / 2.0, _limites.end.y - 120.0)
	_heros.preparer_nouvelle_salle()
	if ReglagesJoueur.passifs_equipes_effectifs().has("reserve_ultime"):
		_charge_ultime += maxi(1, roundi(5.0 * float(ReglagesJoueur.passifs_equipes_effectifs()["reserve_ultime"])))
	_hud.rafraichir()
	_temps_dans_la_salle = 0.0
	if Jeu.mode_auto:
		print("salle %d/%d (%s) : inventaire=%d pv=%d" % [Jeu.salle_courante, Jeu.salles_du_chapitre(),
			Jeu.nom_run(), Jeu.inventaire.size(), roundi(_heros.stats.pv)])
	_salle.demarrer(Jeu.salle_courante, _limites)

func _sur_salle_terminee() -> void:
	if _terminee:
		return
	_heros.definir_intention(Vector2.ZERO, 0.0)
	_joystick.annuler()
	# Le dernier ennemi peut donner un niveau. Le choix immediat a priorite sur
	# l'Alambic ou la salle suivante, sinon deux panneaux se volent leur etat.
	if _panneau != null or _niveaux_en_attente > 0:
		_fin_salle_en_attente = true
		return
	_traiter_fin_salle()

func _traiter_fin_salle() -> void:
	if Jeu.mode_run == "epreuve_sorts":
		_sur_palier_defi_termine()
		return
	if Jeu.salle_courante >= Jeu.salles_du_chapitre():
		Jeu.terminer_run(true)
		return
	if Chapitres.est_alambic(Jeu.chapitre, Jeu.salle_courante):
		_ouvrir_alambic_apres_salle()
	else:
		_avancer_salle()

func _avancer_salle() -> void:
	if _transition_salle:
		return
	_transition_salle = true
	_heros.definir_intention(Vector2.ZERO, 0.0)
	_joystick.annuler()
	_voile_salle.visible = true
	_voile_salle.mouse_filter = Control.MOUSE_FILTER_STOP
	_titre_voile.text = "SALLE %02d" % (Jeu.salle_courante + 1)
	_sous_titre_voile.text = Jeu.nom_run().to_upper()
	var fermeture := create_tween()
	fermeture.set_trans(Tween.TRANS_QUINT)
	fermeture.set_ease(Tween.EASE_IN)
	fermeture.tween_property(_voile_salle, "modulate:a", 1.0,
		0.12 if ReglagesJoueur.effets_reduits else 0.26)
	await fermeture.finished
	Jeu.salle_courante += 1
	_entrer_dans_la_salle()
	await get_tree().create_timer(0.04 if ReglagesJoueur.effets_reduits else 0.16).timeout
	var ouverture := create_tween()
	ouverture.set_trans(Tween.TRANS_QUINT)
	ouverture.set_ease(Tween.EASE_OUT)
	ouverture.tween_property(_voile_salle, "modulate:a", 0.0,
		0.16 if ReglagesJoueur.effets_reduits else 0.42)
	await ouverture.finished
	_voile_salle.visible = false
	_voile_salle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_salle = false

func _construire_voile_salle() -> void:
	_voile_salle = VOILE_TRANSITION.new()
	_voile_salle.mouse_filter = Control.MOUSE_FILTER_STOP
	_voile_salle.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(_voile_salle)
	_voile_salle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_titre_voile = Label.new()
	_titre_voile.set_anchors_preset(Control.PRESET_CENTER)
	_titre_voile.position = Vector2(-260.0, -62.0)
	_titre_voile.size = Vector2(520.0, 76.0)
	_titre_voile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titre_voile.add_theme_font_size_override("font_size", 54)
	_titre_voile.add_theme_color_override("font_color", Palette.TEXTE)
	_voile_salle.add_child(_titre_voile)
	_sous_titre_voile = Label.new()
	_sous_titre_voile.set_anchors_preset(Control.PRESET_CENTER)
	_sous_titre_voile.position = Vector2(-300.0, 18.0)
	_sous_titre_voile.size = Vector2(600.0, 48.0)
	_sous_titre_voile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sous_titre_voile.add_theme_font_size_override("font_size", 24)
	_sous_titre_voile.add_theme_color_override("font_color", Palette.OR)
	_voile_salle.add_child(_sous_titre_voile)

func _animer_entree_salle() -> void:
	_titre_voile.text = "SALLE %02d" % Jeu.salle_courante if Jeu.mode_run == "grimoire" else Jeu.nom_run().to_upper()
	_sous_titre_voile.text = Jeu.nom_run().to_upper() if Jeu.mode_run == "grimoire" else (
			"SURVIVEZ 5 MINUTES" if Jeu.mode_run == "mine" else "UNE SALLE D'ESSAI" if Jeu.mode_run == "retro" else "CINQ RITUELS")
	_voile_salle.visible = true
	_voile_salle.modulate.a = 1.0
	await get_tree().create_timer(0.10 if ReglagesJoueur.effets_reduits else 0.38).timeout
	var ouverture := create_tween()
	ouverture.set_trans(Tween.TRANS_QUINT)
	ouverture.set_ease(Tween.EASE_OUT)
	ouverture.tween_property(_voile_salle, "modulate:a", 0.0,
		0.16 if ReglagesJoueur.effets_reduits else 0.52)
	await ouverture.finished
	_voile_salle.visible = false
	_voile_salle.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ouvrir_recompense_etage() -> void:
	if _terminee or _panneau != null:
		return
	get_tree().paused = true
	Sons.musique_calme()
	_panneau = DRAFT.instantiate()
	_panneau.etage_recompense = Jeu.niveau_run
	_panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(_panneau)
	_panneau.termine.connect(func() -> void:
		_panneau.queue_free()
		_panneau = null
		_heros.recalculer()
		if Jeu.mode_run == "mine":
			_heros.stats.soigner(_heros.stats.pv_max * Reglages.MINE_SOIN_NIVEAU)
			_effets.onde(_heros.global_position, 150.0, Color(0.42, 1.0, 0.66), 0.45)
		_hud.rafraichir()
		get_tree().paused = false
		_niveaux_en_attente = maxi(0, _niveaux_en_attente - 1)
		if _niveaux_en_attente > 0:
			_ouvrir_recompense_etage()
		elif _fin_salle_en_attente:
			_fin_salle_en_attente = false
			_traiter_fin_salle())

func _sur_palier_defi_termine() -> void:
	var dernier := Jeu.salle_courante >= Jeu.salles_du_chapitre()
	_ouvrir_recompense_sorts(dernier)

func _ouvrir_recompense_sorts(derniere: bool) -> void:
	get_tree().paused = true
	Sons.musique_calme()
	_panneau = RECOMPENSE_SORTS.instantiate()
	_panneau.etage_recompense = Jeu.salle_courante
	_panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(_panneau)
	_panneau.termine.connect(func() -> void:
		_panneau.queue_free()
		_panneau = null
		get_tree().paused = false
		if derniere:
			Jeu.terminer_run(true)
		else:
			_avancer_salle())

func _ouvrir_alambic_apres_salle() -> void:
	if _panneau != null:
		return
	get_tree().paused = true
	Sons.musique_calme()
	_heros.stats.soigner(_heros.stats.pv_max * Reglages.SOIN_ALAMBIC \
		* ArbreCompetences.multiplicateur_soin(ReglagesJoueur.rangs_competences_effectifs()))
	_panneau = ALAMBIC.instantiate()
	_panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(_panneau)
	_panneau.termine.connect(func() -> void:
		_panneau.queue_free()
		_panneau = null
		get_tree().paused = false
		Sons.musique_combat(0.35)
		_avancer_salle())

func _ouvrir_pause() -> void:
	get_tree().paused = true
	Sons.musique_calme()
	_panneau = PAUSE.instantiate()
	_panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(_panneau)
	_panneau.termine.connect(_fermer_pause)

func _fermer_pause() -> void:
	if _panneau == null:
		return
	_panneau.queue_free()
	_panneau = null
	get_tree().paused = false
	if Jeu.est_boss_courant():
		Sons.musique_boss()
	else:
		Sons.musique_combat(0.5)

func _notification(quoi: int) -> void:
	if quoi != NOTIFICATION_WM_GO_BACK_REQUEST or _terminee:
		return
	if _panneau != null and _panneau.scene_file_path == "res://ui/pause.tscn":
		_fermer_pause()
	elif _panneau == null:
		_ouvrir_pause()

func _sur_intention(direction: Vector2, intensite: float) -> void:
	if _heros != null and not Jeu.mode_auto:
		_heros.definir_intention(direction, intensite)

func _sur_tir_heros(tir_courant: Tir, origine: Vector2, direction: Vector2) -> void:
	var tir_effectif := tir_courant.copie()
	tir_effectif.degats *= _heros.multiplicateur_degats_passif()
	_salle.tirer(tir_effectif, origine, direction, false)
	if _orbes_chargees > 0 and "orbes_chargees" in tir_courant.drapeaux:
		for i in _orbes_chargees:
			var angle := (float(i) - float(_orbes_chargees - 1) * 0.5) * 0.13
			_tirer_phenomene("orbes_chargees", Reglages.ORBE_PART_DEGATS, origine,
				direction.rotated(angle))
		_orbes_chargees = 0

func _avancer_phenomenes(delta: float) -> void:
	if _heros == null or _terminee or _panneau != null or _heros.tir_courant == null:
		return
	var drapeaux: Array[String] = _heros.tir_courant.drapeaux
	if "familier_tireur" in drapeaux:
		_familier_minuterie -= delta
		if _familier_minuterie <= 0.0:
			_familier_minuterie = _intervalle_phenomene(Reglages.FAMILIER_TIR_INTERVALLE, "familier_tireur")
			var cible := _ennemi_plus_proche(_heros.global_position)
			if cible != null:
				_tirer_phenomene("familier_tireur", Reglages.FAMILIER_TIR_PART_DEGATS,
					_heros.global_position + Vector2(72.0, -36.0),
					_heros.global_position.direction_to(cible.global_position))
	if "meteores" in drapeaux:
		_meteore_minuterie -= delta
		if _meteore_minuterie <= 0.0:
			_meteore_minuterie = _intervalle_phenomene(Reglages.METEORE_INTERVALLE, "meteores")
			_declencher_meteore()
	if "zone_heros" in drapeaux:
		_zone_minuterie -= delta
		if _zone_minuterie <= 0.0:
			_zone_minuterie = _intervalle_phenomene(Reglages.ZONE_HEROS_INTERVALLE, "zone_heros")
			_frapper_zone_heros()
	if "orbes_chargees" in drapeaux:
		_orbe_minuterie -= delta
		if _orbe_minuterie <= 0.0:
			_orbe_minuterie = _intervalle_phenomene(Reglages.ORBE_INTERVALLE, "orbes_chargees")
			_orbes_chargees = mini(Reglages.ORBE_MAX, _orbes_chargees + 1)
	if "familier_gardien" in drapeaux and (_gardien == null or not is_instance_valid(_gardien)):
		_gardien = Gardien.new()
		_gardien.heros = _heros
		_gardien.global_position = _heros.global_position + Vector2(-70.0, -25.0)
		add_child(_gardien)

func _tirer_phenomene(id: String, part_degats: float, origine: Vector2, direction: Vector2) -> void:
	var tir := Tir.de_base(_heros.stats)
	tir.degats *= part_degats
	_appliquer_element_phenomene(tir, id)
	_salle.tirer(tir, origine, direction, false)

func _intervalle_phenomene(base: float, id: String) -> float:
	return base * (Reglages.PHENOMENE_AIR_INTERVALLE_MULT \
		if "air" in Jeu.elements_de_augment(id) else 1.0)

func _appliquer_element_phenomene(tir: Tir, id: String) -> void:
	for element in Jeu.elements_de_augment(id):
		match element:
			"feu": tir.effets.append("feu")
			"eau": tir.effets.append("eau")
			"air": tir.vitesse *= 1.35
			"terre":
				tir.effets.append("terre")
				tir.degats *= Reglages.TERRE_DEGATS_MULT
				tir.vitesse *= Reglages.TERRE_VITESSE_MULT
			"lumiere": tir.effets.append("lumiere")
			"tenebres": tir.drapeaux.append("tenebres")

func _declencher_meteore() -> void:
	var cible := _ennemi_plus_proche(_heros.global_position)
	if cible == null:
		return
	var tir := Tir.de_base(_heros.stats)
	tir.degats *= Reglages.METEORE_PART_DEGATS
	_appliquer_element_phenomene(tir, "meteores")
	_effets.onde(cible.global_position, Reglages.METEORE_RAYON, Palette.BRAISE, 0.65)
	for ennemi in get_tree().get_nodes_in_group("ennemis"):
		if is_instance_valid(ennemi) and ennemi.global_position.distance_to(cible.global_position) <= Reglages.METEORE_RAYON:
			_infliger_phenomene(ennemi, tir)

func _frapper_zone_heros() -> void:
	var tir := Tir.de_base(_heros.stats)
	tir.degats *= Reglages.ZONE_HEROS_PART_DEGATS
	_appliquer_element_phenomene(tir, "zone_heros")
	_effets.onde(_heros.global_position, Reglages.ZONE_HEROS_RAYON, Palette.MOUSSE_MAGIQUE, 0.32)
	for ennemi in get_tree().get_nodes_in_group("ennemis"):
		if is_instance_valid(ennemi) and ennemi.global_position.distance_to(_heros.global_position) <= Reglages.ZONE_HEROS_RAYON:
			_infliger_phenomene(ennemi, tir)

func _infliger_phenomene(ennemi: Node, tir: Tir) -> void:
	var degats := tir.degats
	if "tenebres" in tir.drapeaux and Jeu.rng.randf() < Reglages.TENEBRES_CHANCE_SURCHARGE:
		degats *= Reglages.TENEBRES_SURCHARGE_MULT
	ennemi.recevoir_degats(degats, tir.effets)
	if "lumiere" in tir.effets:
		_heros.stats.soigner(degats * Reglages.LUMIERE_VOL_DE_VIE)

func _ennemi_plus_proche(origine: Vector2) -> Node2D:
	var resultat: Node2D = null
	var distance := INF
	for ennemi in get_tree().get_nodes_in_group("ennemis"):
		if not is_instance_valid(ennemi):
			continue
		var d := origine.distance_squared_to(ennemi.global_position)
		if d < distance:
			distance = d
			resultat = ennemi
	return resultat

func _sur_heros_touche(position: Vector2) -> void:
	_effets.impact(position, Palette.DANGER, 1.6)
	_hud.impact_degats()
	if ReglagesJoueur.passifs_equipes_effectifs().has("riposte_alchimique"):
		_effets.onde(position, 270.0, Palette.OR, 0.45)
		for ennemi in get_tree().get_nodes_in_group("ennemis"):
			if is_instance_valid(ennemi) and ennemi.global_position.distance_to(position) <= 270.0:
				ennemi.recevoir_degats(_heros.tir_courant.degats * 1.5 \
					* float(ReglagesJoueur.passifs_equipes_effectifs()["riposte_alchimique"]), [])

func _sur_bouclier_brise(position: Vector2) -> void:
	_effets.onde(position, 200.0, Color(0.85, 0.92, 1.0), 0.5)

func _sur_ennemi_abattu(experience: int) -> void:
	_charge_ultime += 1
	if Jeu.mode_run in ["grimoire", "mine"]:
		_niveaux_en_attente += Jeu.gagner_experience_run(experience)
		if _niveaux_en_attente > 0 and _panneau == null and not _terminee:
			_ouvrir_recompense_etage()
	var passifs := ReglagesJoueur.passifs_equipes_effectifs()
	if passifs.has("moisson_vitale"):
		_compteur_moisson += 1
		if _compteur_moisson >= 10:
			_compteur_moisson = 0
			_heros.stats.soigner(_heros.stats.pv_max * 0.08 * float(passifs["moisson_vitale"]))
			_effets.onde(_heros.global_position, 150.0, Color(0.35, 1.0, 0.58), 0.5)
	if passifs.has("sang_froid"):
		_compteur_sang_froid += 1
		if _compteur_sang_froid >= ceili(12.0 / maxf(0.25, float(passifs["sang_froid"]))):
			_compteur_sang_froid = 0
			_recharge_sort_actif = 0.0

func _lancer_sort_actif() -> void:
	var id := ReglagesJoueur.sort_actif_effectif()
	if _recharge_sort_actif > 0.0 or not Sorts.ACTIFS.has(id):
		return
	var sort: Dictionary = Sorts.ACTIFS[id]
	var efficacite := ReglagesJoueur.efficacite_sort(id)
	_recharge_sort_actif = float(sort["recharge"]) * Sorts.multiplicateur_recharge_active(ReglagesJoueur.passifs_equipes_effectifs())
	_appliquer_sort(float(sort["rayon"]), float(sort["degats"]) * efficacite, str(sort["effet"]), false)
	var passifs := ReglagesJoueur.passifs_equipes_effectifs()
	if passifs.has("echo_alchimique") and Jeu.rng.randf() < 0.30 * float(passifs["echo_alchimique"]):
		_appliquer_sort(float(sort["rayon"]), float(sort["degats"]) * efficacite * 0.50, str(sort["effet"]), false)

func _lancer_ultime() -> void:
	var id := ReglagesJoueur.ultime_effectif()
	if not Sorts.ULTIMES.has(id):
		return
	var sort: Dictionary = Sorts.ULTIMES[id]
	var charge_requise := ceili(float(sort["charge"]) * Sorts.multiplicateur_charge_ultime(ReglagesJoueur.passifs_equipes_effectifs()))
	if _charge_ultime < charge_requise:
		return
	_charge_ultime -= charge_requise
	_appliquer_sort(INF, float(sort["degats"]) * ReglagesJoueur.efficacite_sort(id), str(sort["effet"]), true)

func _appliquer_sort(rayon: float, multiplicateur: float, effet: String, ultime: bool) -> void:
	var couleur := Palette.ESSENCE if ultime else (Palette.GIVRE if effet == "givre" else Palette.ACIDE if effet == "acide" else Palette.OR)
	_effets.onde(_heros.global_position, 620.0 if is_inf(rayon) else rayon, couleur, 0.85)
	for ennemi in get_tree().get_nodes_in_group("ennemis"):
		if not is_instance_valid(ennemi) or (not is_inf(rayon) and ennemi.global_position.distance_to(_heros.global_position) > rayon):
			continue
		var effets_sort: Array[String] = []
		if effet in ["braise", "givre", "acide"]:
			effets_sort.append(effet)
		ennemi.recevoir_degats(_heros.tir_courant.degats * multiplicateur * _heros.multiplicateur_degats_passif(), effets_sort)
		if effet == "givre" and ennemi.has_method("geler"):
			ennemi.geler(2.2 if ultime else 1.2)
		elif effet == "repousse":
			var direction := _heros.global_position.direction_to(ennemi.global_position)
			ennemi.global_position += direction * 120.0
	Sons.jouer("fusion" if ultime else "choix", -9.0)

func _sur_run_terminee(victoire: bool) -> void:
	if _terminee:
		return
	_terminee = true
	Sons.musique_calme()
	get_tree().paused = true
	var fin := FIN.instantiate()
	fin.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(fin)
	fin.afficher(victoire, Jeu.salle_courante)
	print("run terminee : victoire=%s chapitre=%d salle atteinte=%d/%d graine=%d abattus=%d duree=%d min %02d s" % [
		victoire, Jeu.chapitre + 1, Jeu.salle_courante, Jeu.salles_du_chapitre(),
		Jeu.graine, Jeu.ennemis_abattus, int(Jeu.duree_run() / 60.0), int(Jeu.duree_run()) % 60])
