extends Node

# Orchestrateur : enchaine les dix salles, ouvre draft ou alambic entre elles,
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

var _fond: Node2D
var _zones: Node2D
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

func _ready() -> void:
	if OS.get_name() == "Android":
		get_tree().set_auto_accept_quit(false)
	var arguments := OS.get_cmdline_user_args()
	Jeu.mode_auto = "--auto" in arguments
	Jeu.demarrer_run(_valeur_argument(arguments, "--graine="), maxi(1, _valeur_argument(arguments, "--salle=")),
		maxi(0, _valeur_argument(arguments, "--chapitre=") - 1) if _valeur_argument(arguments, "--chapitre=") > 0 else ReglagesJoueur.chapitre_choisi,
		ReglagesJoueur.mode_run_choisi)
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

	_calculer_limites()
	get_tree().get_root().size_changed.connect(_calculer_limites)

	_fond = Node2D.new()
	_fond.set_script(load("res://scripts/fond.gd"))
	add_child(_fond)

	_zones = Node2D.new()
	_zones.set_script(load("res://scripts/zones.gd"))
	add_child(_zones)

	_salle = SALLE.instantiate()
	add_child(_salle)
	_salle.ennemi_abattu.connect(_sur_ennemi_abattu)

	_heros = HEROS.instantiate()
	add_child(_heros)
	_heros.limites = _limites
	_heros.tir_demande.connect(_sur_tir_heros)
	_heros.touchee.connect(_sur_heros_touche)
	_heros.bouclier_brise.connect(_sur_bouclier_brise)
	_heros.sillage_depose.connect(_sur_sillage)
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

	if Jeu.mode_auto:
		var bot := Node.new()
		bot.set_script(BOT)
		bot.bavard = "--bavard" in arguments
		add_child(bot)

	_entrer_dans_la_salle()
	if Jeu.mode_run == "epreuve_sorts" and Jeu.salle_courante == 1:
		_ouvrir_serie_reactifs(3, func() -> void: pass)
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
	if _temps_dans_la_salle < 120.0:
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

func _calculer_limites() -> void:
	var taille := get_viewport().get_visible_rect().size
	var haut := Reglages.ARENE_HAUT + Ecran.marge_haute()
	var bas := Reglages.ARENE_BAS + Ecran.marge_basse()
	_limites = Rect2(
		Vector2(Reglages.ARENE_MARGE_LATERALE, haut),
		Vector2(taille.x - 2.0 * Reglages.ARENE_MARGE_LATERALE, maxf(600.0, taille.y - haut - bas)))
	if _heros != null:
		_heros.limites = _limites

func _entrer_dans_la_salle() -> void:
	_zones.vider()
	for enfant in _salle.get_children():
		enfant.queue_free()
	_calculer_limites()
	_fond.preparer(_limites, Jeu.salle_courante)
	_salle.effets = _effets
	_salle.zones = _zones
	if not _salle.terminee.is_connected(_sur_salle_terminee):
		_salle.terminee.connect(_sur_salle_terminee)
	_heros.global_position = Vector2((_limites.position.x + _limites.end.x) / 2.0, _limites.end.y - 120.0)
	_heros.preparer_nouvelle_page()
	if ReglagesJoueur.passifs_equipes_effectifs().has("reserve_ultime"):
		_charge_ultime += maxi(1, roundi(5.0 * float(ReglagesJoueur.passifs_equipes_effectifs()["reserve_ultime"])))
	_hud.rafraichir()
	_temps_dans_la_salle = 0.0
	if Jeu.mode_auto:
		print("salle %d/%d (%s) : inventaire=%d pv=%d" % [Jeu.salle_courante, Jeu.salles_du_chapitre(),
			Jeu.chapitre_courant()["nom"], Jeu.inventaire.size(), roundi(_heros.stats.pv)])
	_salle.demarrer(Jeu.salle_courante, _limites)

func _sur_salle_terminee() -> void:
	if _terminee:
		return
	_heros.definir_intention(Vector2.ZERO, 0.0)
	_joystick.annuler()
	if Jeu.mode_run == "epreuve_sorts":
		_sur_palier_defi_termine()
		return
	if Jeu.salle_courante >= Jeu.salles_du_chapitre():
		Jeu.terminer_run(true)
		return
	_ouvrir_recompense_etage()

func _avancer_page() -> void:
	Jeu.salle_courante += 1
	_continuer_apres_porte()

func _continuer_apres_porte() -> void:
	_entrer_dans_la_salle()

func _ouvrir_recompense_etage() -> void:
	if _terminee or _panneau != null:
		return
	get_tree().paused = true
	Sons.musique_calme()
	_panneau = DRAFT.instantiate()
	_panneau.etage_recompense = Jeu.salle_courante
	_panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(_panneau)
	_panneau.termine.connect(func() -> void:
		_panneau.queue_free()
		_panneau = null
		_heros.recalculer()
		_hud.rafraichir()
		get_tree().paused = false
		if Chapitres.est_alambic(Jeu.chapitre, Jeu.salle_courante):
			_ouvrir_alambic_apres_page()
		else:
			_avancer_page())

func _sur_palier_defi_termine() -> void:
	var boss := Jeu.est_boss_courant()
	var dernier := Jeu.salle_courante >= Jeu.salles_du_chapitre()
	if boss:
		if dernier:
			_ouvrir_recompense_sorts(true)
		else:
			# Le boss ouvre immediatement trois choix capables d'alimenter la
			# prochaine fusion, puis livre sa recompense permanente.
			_ouvrir_serie_reactifs(3, func() -> void: _ouvrir_recompense_sorts(false))
		return
	_ouvrir_bonus_defi()

func _ouvrir_bonus_defi() -> void:
	_ouvrir_draft_force(false, func() -> void:
		if Jeu.salle_courante in [3, 7, 11]:
			_ouvrir_alambic_apres_page()
		else:
			_avancer_page())

func _ouvrir_serie_reactifs(nombre: int, suite: Callable) -> void:
	if nombre <= 0:
		suite.call()
		return
	_ouvrir_draft_force(true, func() -> void:
		_ouvrir_serie_reactifs(nombre - 1, suite))

func _ouvrir_draft_force(reactif: bool, suite: Callable) -> void:
	if _terminee or _panneau != null:
		return
	get_tree().paused = true
	Sons.musique_calme()
	_panneau = DRAFT.instantiate()
	_panneau.etage_recompense = Jeu.salle_courante
	_panneau.forcer_reactif = reactif
	_panneau.forcer_basique = not reactif
	_panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(_panneau)
	_panneau.termine.connect(func() -> void:
		_panneau.queue_free()
		_panneau = null
		_heros.recalculer()
		_hud.rafraichir()
		get_tree().paused = false
		suite.call())

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
			_avancer_page())

func _ouvrir_alambic_apres_page() -> void:
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
		_avancer_page())

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

func _sur_heros_touche(position: Vector2) -> void:
	_effets.impact(position, Palette.DANGER, 1.6)
	_hud.impact_degats()
	if ReglagesJoueur.passifs_equipes_effectifs().has("riposte_alchimique"):
		_effets.onde(position, 270.0, Palette.OR, 0.45)
		for ennemi in get_tree().get_nodes_in_group("ennemis"):
			if is_instance_valid(ennemi) and ennemi.global_position.distance_to(position) <= 270.0:
				ennemi.recevoir_degats(_heros.tir_courant.degats * 1.5 \
					* float(ReglagesJoueur.passifs_equipes_effectifs()["riposte_alchimique"]), [])

func _sur_bouclier_brise(position: Vector2, explosif: bool) -> void:
	_effets.onde(position, 200.0, Color(0.85, 0.92, 1.0), 0.5)
	if not explosif:
		return
	# Aura de cristal : le bouclier brise explose en eclats gelants.
	_effets.onde(position, Reglages.BOUCLIER_EXPLOSION_RAYON, Palette.GIVRE, 0.7)
	_effets.eclats(position, Palette.GIVRE, 22, 420.0, 0.5)
	for ennemi in get_tree().get_nodes_in_group("ennemis"):
		if not is_instance_valid(ennemi):
			continue
		if ennemi.global_position.distance_to(position) > Reglages.BOUCLIER_EXPLOSION_RAYON:
			continue
		ennemi.recevoir_degats(_heros.tir_courant.degats * 1.5, ["givre"])
		if ennemi.has_method("geler"):
			ennemi.geler(Reglages.GEL_BREF_DUREE)

func _sur_sillage(position: Vector2, gelant: bool) -> void:
	_zones.ajouter(position, "sillage_gelant" if gelant else "sillage")

func _sur_ennemi_abattu() -> void:
	_charge_ultime += 1
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
