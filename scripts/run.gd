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

func _ready() -> void:
	var arguments := OS.get_cmdline_user_args()
	Jeu.mode_auto = "--auto" in arguments
	Jeu.demarrer_run(_valeur_argument(arguments, "--graine="), maxi(1, _valeur_argument(arguments, "--salle=")),
		maxi(0, _valeur_argument(arguments, "--chapitre=") - 1) if _valeur_argument(arguments, "--chapitre=") > 0 else ReglagesJoueur.chapitre_choisi)
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
	_joystick = JOYSTICK.instantiate()
	_couche.add_child(_joystick)
	_joystick.intention_changee.connect(_sur_intention)

	if Jeu.mode_auto:
		var bot := Node.new()
		bot.set_script(BOT)
		bot.bavard = "--bavard" in arguments
		add_child(bot)

	_entrer_dans_la_salle()
	Capture.programmer(self)

# En mode auto, une salle qui ne se termine pas est un blocage, pas une
# difficulte. On veut le savoir avec l'etat de la salle, pas par un silence.
func _process(delta: float) -> void:
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
		Vector2(Reglages.ARENE_MARGE_LATERALE + 40.0, haut),
		Vector2(taille.x - 2.0 * (Reglages.ARENE_MARGE_LATERALE + 40.0), maxf(600.0, taille.y - haut - bas)))
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
	_heros.recalculer()
	_hud.rafraichir()
	_temps_dans_la_salle = 0.0
	if Jeu.mode_auto:
		print("salle %d/%d (%s) : inventaire=%d pv=%d" % [Jeu.salle_courante, Jeu.salles_du_chapitre(),
			Jeu.chapitre_courant()["nom"], Jeu.inventaire.size(), roundi(_heros.stats.pv)])
	_salle.demarrer(Jeu.salle_courante, _limites)

func _sur_salle_terminee() -> void:
	if _terminee:
		return
	if Jeu.salle_courante >= Jeu.salles_du_chapitre():
		Jeu.terminer_run(true)
		return
	Jeu.salle_courante += 1
	if Chapitres.est_alambic(Jeu.chapitre, Jeu.salle_courante):
		_ouvrir(ALAMBIC)
	else:
		_ouvrir(DRAFT)

func _ouvrir(scene: PackedScene) -> void:
	get_tree().paused = true
	_panneau = scene.instantiate()
	_panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(_panneau)
	_panneau.termine.connect(func() -> void:
		_panneau.queue_free()
		_panneau = null
		get_tree().paused = false
		_entrer_dans_la_salle())

func _sur_intention(direction: Vector2, intensite: float) -> void:
	if _heros != null and not Jeu.mode_auto:
		_heros.definir_intention(direction, intensite)

func _sur_tir_heros(tir_courant: Tir, origine: Vector2, direction: Vector2) -> void:
	_salle.tirer(tir_courant, origine, direction, false)

func _sur_heros_touche(position: Vector2) -> void:
	_effets.impact(position, Palette.DANGER, 1.6)
	_hud.secouer()

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

func _sur_run_terminee(victoire: bool) -> void:
	if _terminee:
		return
	_terminee = true
	get_tree().paused = true
	var fin := FIN.instantiate()
	fin.process_mode = Node.PROCESS_MODE_ALWAYS
	_couche.add_child(fin)
	fin.afficher(victoire, Jeu.salle_courante)
	print("run terminee : victoire=%s chapitre=%d salle atteinte=%d/%d graine=%d abattus=%d" % [
		victoire, Jeu.chapitre + 1, Jeu.salle_courante, Jeu.salles_du_chapitre(),
		Jeu.graine, Jeu.ennemis_abattus])
