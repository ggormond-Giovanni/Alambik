extends CharacterBody2D

const TEXTURE_RAMPANT := preload("res://assets/characters/enemy_crawler.png")
const TEXTURE_SENTINELLE := preload("res://assets/characters/enemy_sentinel.png")
const TEXTURE_VELOCE := preload("res://assets/characters/enemy_charger.png")
const TEXTURE_ESSAIMEUR := preload("res://assets/characters/enemy_summoner.png")

# Base commune des quatre archetypes. Les decisions viennent de Cerveaux, qui
# est pur et testable ; ce fichier ne fait que les traduire en mouvement, en
# tir ou en invocation.

signal mort(qui: Node, position: Vector2, couleur: Color)
signal tir_demande(tir_ennemi: Tir, origine: Vector2, direction: Vector2)
signal invocation_demandee(id: String, position: Vector2)
signal touche(position: Vector2, couleur: Color)

var donnees: Dictionary
var pv := 0.0
var pv_max := 1.0
var limites := Rect2(Vector2(80, 300), Vector2(920, 1400))

var _cible: Node2D
var _recharge := 0.0
var _braise := 0.0
var _givre := 0.0
var _acide := 0.0
var _gel := 0.0
var _etat := "repos"
var _minuterie := 0.0
var _direction_charge := Vector2.ZERO
var _anim := 0.0
var _flash := 0.0
var _apparition := 0.0
var _graine := 0
var _invocations := 0
var _contournement := 0.0
var _sens_contournement := 1.0

func configurer(donnees_: Dictionary) -> void:
	donnees = donnees_
	pv = donnees["pv"]
	pv_max = donnees["pv"]

func _ready() -> void:
	add_to_group("ennemis")
	collision_layer = 2
	collision_mask = 4
	_graine = randi() % 1000
	_cible = get_tree().get_first_node_in_group("heros")
	var forme := $CollisionShape2D.shape as CircleShape2D
	forme.radius = donnees["rayon"]
	_recharge = float(donnees.get("recharge", 1.0)) * 0.5

func _physics_process(delta: float) -> void:
	_anim += delta
	_flash = maxf(0.0, _flash - delta * 6.0)
	_apparition = minf(1.0, _apparition + delta * 3.5)
	_appliquer_effets(delta)
	_contournement = maxf(0.0, _contournement - delta)
	queue_redraw()
	if _cible == null or not is_instance_valid(_cible):
		_cible = get_tree().get_first_node_in_group("heros")
		return
	_recharge = maxf(0.0, _recharge - delta)
	_minuterie = maxf(0.0, _minuterie - delta)
	if _gel > 0.0:
		velocity = Vector2.ZERO
		return
	velocity = Vector2.ZERO
	match donnees["cerveau"]:
		"rampant": _agir_rampant(delta)
		"sentinelle": _agir_sentinelle()
		"veloce": _agir_veloce(delta)
		"essaimeur": _agir_essaimeur(delta)

func _facteur_vitesse() -> float:
	return Reglages.GIVRE_RALENTISSEMENT if _givre > 0.0 else 1.0

func _avancer_vers(cible: Vector2, vitesse: float) -> void:
	var direction := global_position.direction_to(cible)
	# Sans ca, un ennemi pousse indefiniment contre un bloc d'encre sechee et la
	# salle ne se vide jamais : c'est un blocage, pas une difficulte.
	if _contournement > 0.0:
		direction = direction.rotated(_sens_contournement * PI * 0.5).lerp(direction, 0.25).normalized()
	var avant := global_position
	velocity = direction * vitesse * _facteur_vitesse()
	move_and_slide()
	global_position.x = clampf(global_position.x, limites.position.x, limites.end.x)
	global_position.y = clampf(global_position.y, limites.position.y, limites.end.y)
	var attendu := vitesse * _facteur_vitesse() * get_physics_process_delta_time()
	if _contournement <= 0.0 and avant.distance_to(global_position) < attendu * 0.35:
		_contournement = 0.8
		_sens_contournement = 1.0 if randf() < 0.5 else -1.0

func _agir_rampant(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	if Cerveaux.rampant(distance, donnees["portee"]) == "avancer":
		_avancer_vers(_cible.global_position, donnees["vitesse"])
	elif _recharge <= 0.0:
		_recharge = 1.0
		_cible.recevoir_degats(donnees["degats"])

func _agir_sentinelle() -> void:
	var distance := global_position.distance_to(_cible.global_position)
	if Cerveaux.sentinelle(distance, donnees["portee"], _recharge) != "tirer":
		return
	_recharge = donnees.get("recharge", 1.8)
	# Le tir est telegraphie : la sentinelle vise avant de lacher son trait.
	_etat = "vise"
	_minuterie = donnees.get("telegraphe", 0.6)
	var attente := _minuterie
	await get_tree().create_timer(attente).timeout
	if not is_instance_valid(self) or _cible == null or not is_instance_valid(_cible) or _gel > 0.0:
		return
	_etat = "repos"
	_tirer_vers(_cible.global_position)

func _tirer_vers(cible: Vector2) -> void:
	var t := Tir.new()
	t.degats = donnees["degats"]
	t.vitesse = donnees.get("vitesse_projectile", 420.0)
	t.portee = donnees["portee"] * 1.4
	t.cadence = 1.0
	tir_demande.emit(t, global_position, global_position.direction_to(cible))

func _agir_veloce(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	var decision := Cerveaux.veloce(distance, _etat, _minuterie)
	match decision:
		"preparer":
			if _etat != "preparer":
				_etat = "preparer"
				_minuterie = donnees.get("preparation", 0.7)
			_direction_charge = global_position.direction_to(_cible.global_position)
		"charger":
			if _etat != "charger":
				_etat = "charger"
				_minuterie = donnees.get("duree_charge", 0.5)
			velocity = _direction_charge * donnees["vitesse"] * _facteur_vitesse()
			move_and_slide()
			global_position.x = clampf(global_position.x, limites.position.x, limites.end.x)
			global_position.y = clampf(global_position.y, limites.position.y, limites.end.y)
			if distance <= donnees["portee"] and _recharge <= 0.0:
				_recharge = 1.0
				_cible.recevoir_degats(donnees["degats"])
		"repos":
			if _etat != "repos":
				_etat = "repos"
				_minuterie = donnees.get("repos", 0.8)
			elif _minuterie <= 0.0:
				_etat = "repos"
	if decision == "repos" and _minuterie <= 0.0 and distance < 900.0:
		_etat = "preparer"
		_minuterie = donnees.get("preparation", 0.7)
		_direction_charge = global_position.direction_to(_cible.global_position)

func _agir_essaimeur(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	match Cerveaux.essaimeur(distance, donnees["portee"], _recharge):
		"reculer":
			_avancer_vers(global_position * 2.0 - _cible.global_position, donnees["vitesse"])
		"avancer":
			_avancer_vers(_cible.global_position, donnees["vitesse"])
		"invoquer":
			_recharge = donnees.get("recharge", 3.5)
			# Reserve d'encre finie : sans ce plafond, un scribe qu'on ne prend
			# jamais pour cible rend la salle litteralement infinie.
			if _invocations >= int(donnees.get("max_invocations", 6)):
				return
			if get_tree().get_nodes_in_group("ennemis").size() >= Reglages.PLAFOND_ENNEMIS:
				return
			_invocations += int(donnees.get("nb_invoques", 2))
			for i in int(donnees.get("nb_invoques", 2)):
				var ecart := Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0))
				invocation_demandee.emit(donnees.get("invoque", "encrier_rampant"), global_position + ecart)

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
	_gel = maxf(_gel, duree)
	_givre = maxf(_givre, duree)

func _appliquer_effets(delta: float) -> void:
	_gel = maxf(0.0, _gel - delta)
	_givre = maxf(0.0, _givre - delta)
	_acide = maxf(0.0, _acide - delta)
	if _braise > 0.0:
		_braise -= delta
		pv -= Reglages.BRAISE_DEGATS_PAR_SECONDE * delta
		if pv <= 0.0:
			_mourir()

func _mourir() -> void:
	if not is_inside_tree():
		return
	remove_from_group("ennemis")
	mort.emit(self, global_position, donnees["couleur"])
	Sons.jouer("mort", -14.0, randf_range(0.85, 1.15))
	queue_free()

func _draw() -> void:
	var r: float = donnees["rayon"] * (0.4 + 0.6 * _apparition)
	var base: Color = donnees["couleur"]
	var couleur := base
	if _givre > 0.0:
		couleur = couleur.lerp(Palette.GIVRE, 0.45)
	if _acide > 0.0:
		couleur = couleur.lerp(Palette.ACIDE, 0.30)
	if _flash > 0.0:
		couleur = couleur.lerp(Color.WHITE, _flash * 0.8)

	draw_set_transform(Vector2(0, r * 0.85), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, r * 0.9, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# La menace est plus claire et plus saturee que le fond. Les telegraphes
	# restent proceduraux, mais les silhouettes sont maintenant peintes.
	Dessin.halo(self, Vector2.ZERO, r * 2.2, couleur, 4)
	_dessiner_telegraphe(r)
	var texture := _texture_pour_forme(donnees.get("forme", "goutte"))
	var taille := r * (6.8 if donnees.get("forme", "goutte") == "masque" else 6.25)
	var modulation := Color.WHITE.lerp(couleur, 0.18)
	draw_texture_rect(texture, Rect2(Vector2.ONE * -taille * 0.5, Vector2.ONE * taille), false, modulation)

	if _braise > 0.0:
		for i in 3:
			var a := _anim * 4.0 + float(i) * TAU / 3.0
			var p := Vector2(cos(a), sin(a * 1.3)) * r * 0.8 - Vector2(0, r * 0.6 + sin(_anim * 6.0 + i) * 6.0)
			draw_circle(p, r * 0.16, Palette.BRAISE)
	if _gel > 0.0:
		Dessin.contour(self, Dessin.etoile(Vector2.ZERO, r * 1.5, r * 0.7, 6, _anim * 0.4), Palette.GIVRE, 2.5)
	_dessiner_barre_de_vie(r)

func _texture_pour_forme(forme: String) -> Texture2D:
	match forme:
		"plume": return TEXTURE_SENTINELLE
		"dard": return TEXTURE_VELOCE
		"masque": return TEXTURE_ESSAIMEUR
		_: return TEXTURE_RAMPANT

func _dessiner_telegraphe(r: float) -> void:
	if _cible == null:
		return
	var vers := global_position.direction_to(_cible.global_position)
	if donnees.get("forme", "") == "plume" and _etat == "vise":
		draw_line(vers * r, vers * float(donnees["portee"]), Color(Palette.DANGER, 0.35 + 0.25 * sin(_anim * 30.0)), 3.0, true)
	elif donnees.get("forme", "") == "dard" and _etat == "preparer":
		var intensite := 0.4 + 0.6 * sin(_anim * 24.0)
		draw_line(vers * r, vers * 620.0, Color(Palette.DANGER, 0.25 * intensite), 8.0, true)
		Dessin.contour(self, Dessin.polygone_regulier(Vector2.ZERO, r * (1.6 + 0.3 * intensite), 3, vers.angle()), Palette.DANGER, 3.0)

func _dessiner_barre_de_vie(r: float) -> void:
	if pv >= pv_max:
		return
	var largeur := r * 2.0
	var haut := -r - 16.0
	draw_rect(Rect2(-largeur / 2.0, haut, largeur, 6.0), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-largeur / 2.0, haut, largeur * clampf(pv / pv_max, 0.0, 1.0), 6.0), Palette.DANGER)

func _dessiner_rampant(r: float, couleur: Color) -> void:
	var vers := Vector2.DOWN if _cible == null else global_position.direction_to(_cible.global_position)
	var corps := Dessin.blob(Vector2.ZERO, r, _graine, 0.18, _anim * 3.0)
	draw_colored_polygon(corps, couleur)
	Dessin.contour(self, corps, couleur.lightened(0.35), 2.0)
	# Deux yeux d'encre claire : c'est ce qui distingue une creature d'une tache.
	for cote in [-1.0, 1.0]:
		draw_circle(vers.rotated(cote * 0.5) * r * 0.45, r * 0.16, Color(0.95, 0.95, 1.0, 0.9))
	# Gouttes qui perlent derriere lui.
	draw_circle(-vers * r * (1.1 + 0.2 * sin(_anim * 5.0)), r * 0.22, couleur * Color(1, 1, 1, 0.6))

func _dessiner_sentinelle(r: float, couleur: Color) -> void:
	var vers := Vector2.DOWN if _cible == null else global_position.direction_to(_cible.global_position)
	draw_set_transform(Vector2.ZERO, vers.angle(), Vector2.ONE)
	var forme := Dessin.plume(r * 3.0, r * 0.9)
	draw_colored_polygon(forme, couleur)
	Dessin.contour(self, forme, couleur.lightened(0.4), 2.0)
	draw_line(Vector2(-r * 1.5, 0), Vector2(r * 1.5, 0), couleur.darkened(0.4), 2.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, r * 0.42, Color(0.95, 0.95, 1.0, 0.9))
	draw_circle(vers * r * 0.12, r * 0.20, Color(0.10, 0.08, 0.14))
	if _etat == "vise":
		# Trait de visee : la spec veut un tir telegraphie, donc visible avant.
		var portee: float = donnees["portee"]
		draw_line(vers * r, vers * portee, Color(Palette.DANGER, 0.35 + 0.25 * sin(_anim * 30.0)), 3.0, true)

func _dessiner_veloce(r: float, couleur: Color) -> void:
	var vers := _direction_charge if _direction_charge != Vector2.ZERO else Vector2.DOWN
	draw_set_transform(Vector2.ZERO, vers.angle(), Vector2.ONE)
	var etire := 1.0 + (0.8 if _etat == "charger" else 0.0)
	var forme := Dessin.dard(r * 1.9 * etire, r * 0.95)
	draw_colored_polygon(forme, couleur)
	Dessin.contour(self, forme, couleur.lightened(0.4), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(vers * r * 0.5, r * 0.22, Color(1, 1, 1, 0.85))
	if _etat == "preparer":
		# Preparation visible : le joueur apprend a se decaler perpendiculairement.
		var intensite := 0.4 + 0.6 * sin(_anim * 24.0)
		draw_line(vers * r, vers * 620.0, Color(Palette.DANGER, 0.25 * intensite), 8.0, true)
		Dessin.contour(self, Dessin.polygone_regulier(Vector2.ZERO, r * (1.6 + 0.3 * intensite), 3, vers.angle()), Palette.DANGER, 3.0)

func _dessiner_essaimeur(r: float, couleur: Color) -> void:
	var corps := Dessin.blob(Vector2.ZERO, r, _graine, 0.10, _anim * 1.4)
	draw_colored_polygon(corps, couleur.darkened(0.25))
	Dessin.contour(self, corps, couleur.lightened(0.3), 2.5)
	# Un masque de scribe : bandeau clair et trois encoches.
	draw_rect(Rect2(-r * 0.7, -r * 0.25, r * 1.4, r * 0.5), Color(0.94, 0.92, 0.86, 0.92))
	for i in 3:
		var x := (float(i) - 1.0) * r * 0.45
		draw_rect(Rect2(x - r * 0.07, -r * 0.25, r * 0.14, r * 0.5), couleur.darkened(0.5))
	# Plumes d'invocation qui tournent : on voit qu'il prepare quelque chose.
	var pret := 1.0 - clampf(_recharge / maxf(0.1, float(donnees.get("recharge", 3.5))), 0.0, 1.0)
	for i in 3:
		var a := _anim * 1.8 + float(i) * TAU / 3.0
		var p := Vector2(cos(a), sin(a)) * r * (1.5 + 0.3 * pret)
		draw_circle(p, r * 0.16 * (0.5 + pret), Palette.ACIDE.lerp(couleur, 0.3))
