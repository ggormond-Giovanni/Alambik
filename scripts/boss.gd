class_name Boss
extends CharacterBody2D

const TEXTURE_CORRECTEUR := preload("res://assets/characters/boss_corrector.png")

# Le Correcteur. Il n'introduit aucune mecanique que le joueur n'a pas deja
# rencontree : les barrages reutilisent le projectile des ennemis, l'invocation
# celle du scribe, la charge la preparation telegraphiee de la tache veloce.

signal mort(qui: Node, position: Vector2, couleur: Color)
signal tir_demande(tir_ennemi: Tir, origine: Vector2, direction: Vector2)
signal invocation_demandee(id: String, position: Vector2)
signal touche(position: Vector2, couleur: Color)
signal phase_changee(phase: int)

const MOTIFS_PHASE_1: Array[String] = ["barrage_horizontal", "eventail_lent", "pause"]
const MOTIFS_PHASE_2: Array[String] = ["barrage_croise", "invocation", "charge", "pause"]

static func phase_pour(pv_restants: float, pv_max: float) -> int:
	return 2 if pv_restants < pv_max * 0.5 else 1

static func motif_suivant(phase: int, index: int) -> String:
	var motifs := MOTIFS_PHASE_1 if phase == 1 else MOTIFS_PHASE_2
	return motifs[index % motifs.size()]

var donnees: Dictionary
var pv := 0.0
var pv_max := 1.0
var limites := Rect2(Vector2(80, 300), Vector2(920, 1400))

var _cible: Node2D
var _phase := 1
var _index_motif := 0
var _motif := "pause"
var _minuterie := 0.0
var _cadence_motif := 0.0
var _anim := 0.0
var _flash := 0.0
var _braise := 0.0
var _givre := 0.0
var _acide := 0.0
var _gel := 0.0
var _ancre := Vector2.ZERO
var _direction_charge := Vector2.ZERO

func configurer(donnees_: Dictionary) -> void:
	donnees = donnees_
	pv = donnees["pv"]
	pv_max = donnees["pv"]

func _ready() -> void:
	add_to_group("ennemis")
	add_to_group("boss")
	collision_layer = 2
	collision_mask = 4
	_cible = get_tree().get_first_node_in_group("heros")
	($CollisionShape2D.shape as CircleShape2D).radius = donnees["rayon"]
	# Il tient le haut de la page : le joueur garde toute la profondeur pour
	# esquiver. Sans ancre fixe, il derivait dans un coin et devenait illisible.
	_ancre = Vector2((limites.position.x + limites.end.x) / 2.0, limites.position.y + 240.0)
	global_position = _ancre
	Sons.jouer("boss", -8.0)

func _physics_process(delta: float) -> void:
	_anim += delta
	_flash = maxf(0.0, _flash - delta * 6.0)
	_gel = maxf(0.0, _gel - delta)
	_givre = maxf(0.0, _givre - delta)
	_acide = maxf(0.0, _acide - delta)
	if _braise > 0.0:
		_braise -= delta
		pv -= Reglages.BRAISE_DEGATS_PAR_SECONDE * delta
		if pv <= 0.0:
			_mourir()
			return
	queue_redraw()
	if _cible == null or not is_instance_valid(_cible):
		_cible = get_tree().get_first_node_in_group("heros")
		return
	if _gel > 0.0:
		return

	var phase := phase_pour(pv, pv_max)
	if phase != _phase:
		_phase = phase
		_index_motif = 0
		_minuterie = 0.0
		phase_changee.emit(_phase)
		Sons.jouer("boss", -6.0, 0.8)

	_minuterie -= delta
	if _minuterie <= 0.0:
		_motif = motif_suivant(_phase, _index_motif)
		_index_motif += 1
		_minuterie = _duree_du_motif(_motif)
		_cadence_motif = 0.0
		_commencer_motif(_motif)
	_executer_motif(_motif, delta)

func _duree_du_motif(motif: String) -> float:
	match motif:
		"barrage_horizontal": return 3.0
		"eventail_lent": return 3.2
		"barrage_croise": return 3.4
		"invocation": return 1.2
		"charge": return 2.6
	return 1.4 if _phase == 2 else 1.8

func _commencer_motif(motif: String) -> void:
	if motif == "invocation":
		if get_tree().get_nodes_in_group("ennemis").size() >= Reglages.PLAFOND_ENNEMIS:
			return
		for i in 3:
			var ecart := Vector2(randf_range(-200.0, 200.0), randf_range(-60.0, 160.0))
			invocation_demandee.emit("encrier_rampant", global_position + ecart)
	elif motif == "charge":
		_direction_charge = global_position.direction_to(_cible.global_position)

func _executer_motif(motif: String, delta: float) -> void:
	_cadence_motif -= delta
	match motif:
		"barrage_horizontal":
			_flotter(delta)
			if _cadence_motif <= 0.0:
				_cadence_motif = 0.55
				# Un mur de traits avec une breche : lisible, evitable en marchant.
				var breche := randi_range(0, 6)
				for i in 7:
					if i == breche:
						continue
					var origine := global_position + Vector2((float(i) - 3.0) * 90.0, 60.0)
					_lancer(origine, Vector2.DOWN, 1.0)
		"eventail_lent":
			_flotter(delta)
			if _cadence_motif <= 0.0:
				_cadence_motif = 0.85
				var vers := global_position.direction_to(_cible.global_position)
				for k in [-0.5, -0.25, 0.0, 0.25, 0.5]:
					_lancer(global_position, vers.rotated(k), 0.8)
		"barrage_croise":
			_flotter(delta)
			if _cadence_motif <= 0.0:
				_cadence_motif = 0.32
				var base := _anim * 2.2
				for k in 3:
					_lancer(global_position, Vector2.RIGHT.rotated(base + float(k) * TAU / 3.0), 0.9)
		"charge":
			velocity = _direction_charge * donnees["vitesse"] * 2.2
			move_and_slide()
			global_position.x = clampf(global_position.x, limites.position.x, limites.end.x)
			global_position.y = clampf(global_position.y, limites.position.y, limites.end.y)
			if global_position.distance_to(_cible.global_position) < donnees["rayon"] + 40.0:
				_cible.recevoir_degats(donnees["degats"])
				_direction_charge = -_direction_charge
		_:
			_flotter(delta)

func _flotter(_delta: float) -> void:
	# Il revient toujours vers le haut de l'arene : le joueur garde de la place.
	var vise := Vector2(_ancre.x + sin(_anim * 0.7) * 260.0, _ancre.y)
	velocity = global_position.direction_to(vise) * donnees["vitesse"] * 0.6
	if global_position.distance_to(vise) < 20.0:
		velocity = Vector2.ZERO
	move_and_slide()

func _lancer(origine: Vector2, direction: Vector2, part_degats: float) -> void:
	var t := Tir.new()
	t.degats = donnees["degats"] * part_degats
	t.vitesse = donnees.get("vitesse_projectile", 380.0)
	t.portee = 2200.0
	t.cadence = 1.0
	tir_demande.emit(t, origine, direction)

func recevoir_degats(montant: float, effets: Array = []) -> void:
	if pv <= 0.0:
		return
	var facteur := Reglages.ACIDE_VULNERABILITE if _acide > 0.0 else 1.0
	pv -= montant * facteur
	_flash = 1.0
	touche.emit(global_position, donnees["couleur"])
	for effet in effets:
		match effet:
			"braise": _braise = Reglages.BRAISE_DUREE
			"givre": _givre = Reglages.GIVRE_DUREE
			"acide": _acide = Reglages.ACIDE_DUREE
	if pv <= 0.0:
		_mourir()

func geler(duree: float) -> void:
	# Un boss ne se fige pas comme un rampant, sinon il suffit de le geler.
	_gel = maxf(_gel, duree * 0.4)

func _mourir() -> void:
	if not is_inside_tree():
		return
	remove_from_group("ennemis")
	mort.emit(self, global_position, donnees["couleur"])
	Sons.jouer("mort", -4.0, 0.6)
	queue_free()

func _draw() -> void:
	var r: float = donnees["rayon"]
	var couleur: Color = donnees["couleur"]
	if _givre > 0.0:
		couleur = couleur.lerp(Palette.GIVRE, 0.35)
	if _flash > 0.0:
		couleur = couleur.lerp(Color.WHITE, _flash * 0.7)

	draw_set_transform(Vector2(0, r * 0.8), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	Dessin.halo(self, Vector2.ZERO, r * 2.4, couleur, 5)
	if _phase == 2:
		Dessin.contour(self, Dessin.etoile(Vector2.ZERO, r * 1.6, r * 1.25, 9, _anim * 0.9), Color(Palette.DANGER, 0.5), 3.0)
	var taille := r * 4.5
	var modulation := Color.WHITE.lerp(couleur, 0.12)
	draw_texture_rect(TEXTURE_CORRECTEUR, Rect2(Vector2.ONE * -taille * 0.5, Vector2.ONE * taille), false, modulation)
