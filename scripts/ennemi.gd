extends CharacterBody2D

# Base commune des huit archetypes. Les decisions viennent de Cerveaux, qui
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
var _brulure_dps := 0.0
var _givre := 0.0
var _acide := 0.0
var _terre_declenchee := false
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
	if _apparition < 1.0:
		velocity = Vector2.ZERO
		return
	_cible = _cible_la_plus_proche()
	if _cible == null:
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
		"orbiteur": _agir_orbiteur(delta)
		"harceleur": _agir_harceleur(delta)
		"miroir": _agir_miroir(delta)
		"phaseur": _agir_phaseur(delta)
		"tisseur": _agir_tisseur(delta)
		"volatile": _agir_volatile(delta)

func _cible_la_plus_proche() -> Node2D:
	var meilleure: Node2D = null
	var distance := INF
	for cible in get_tree().get_nodes_in_group("cibles_ennemis"):
		if not is_instance_valid(cible) or not cible.visible:
			continue
		var d := global_position.distance_squared_to(cible.global_position)
		if d < distance:
			distance = d
			meilleure = cible
	return meilleure

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
	# Il ne sert plus seulement de sac de PV de melee : son crachat lent coupe
	# regulierement la trajectoire du joueur, sans punir une esquive tardive.
	if distance <= float(donnees.get("portee_tir", 0.0)) and distance > donnees["portee"] and _recharge <= 0.0:
		_recharge = donnees.get("recharge", 2.3)
		_tirer_vers(_cible.global_position)

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
	t.degats = donnees["degats"] * float(donnees.get("part_degats_projectile", 1.0))
	t.vitesse = donnees.get("vitesse_projectile", 420.0)
	t.portee = donnees.get("portee_projectile", donnees["portee"] * 1.4)
	t.cadence = 1.0
	t.nb_projectiles = int(donnees.get("projectiles", 1))
	t.angle_eventail = float(donnees.get("angle_eventail", 0.0))
	t.ecart_lateral = float(donnees.get("ecart_lateral", 0.0))
	tir_demande.emit(t, global_position, global_position.direction_to(cible))

func _tirer_cercle(nombre: int) -> void:
	var t := Tir.new()
	t.degats = donnees["degats"] * float(donnees.get("part_degats_projectile", 1.0))
	t.vitesse = donnees.get("vitesse_projectile", 320.0)
	t.portee = donnees.get("portee_projectile", 900.0)
	t.cadence = 1.0
	for i in nombre:
		var direction := Vector2.RIGHT.rotated(TAU * float(i) / float(nombre))
		tir_demande.emit(t, global_position, direction)

func _agir_veloce(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	var decision := Cerveaux.veloce(distance, _etat, _minuterie,
		float(donnees.get("distance_charge", 900.0)))
	match decision:
		"avancer":
			_avancer_vers(_cible.global_position,
				float(donnees["vitesse"]) * float(donnees.get("vitesse_approche_mult", 0.45)))
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
			_tirer_cercle(int(donnees.get("projectiles_cercle", 0)))

func _agir_orbiteur(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	match Cerveaux.orbiteur(distance, donnees["portee"], _recharge):
		"reculer": _avancer_vers(global_position * 2.0 - _cible.global_position, donnees["vitesse"])
		"avancer": _avancer_vers(_cible.global_position, donnees["vitesse"])
		"orbiter":
			var radial := _cible.global_position.direction_to(global_position)
			var tangente := radial.rotated(float(donnees.get("sens_orbite", 1.0)) * PI * 0.5)
			velocity = tangente * donnees["vitesse"] * _facteur_vitesse()
			move_and_slide()
		"tirer":
			_recharge = donnees.get("recharge", 1.65)
			_tirer_vers(_cible.global_position)

func _agir_harceleur(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	match Cerveaux.harceleur(distance, donnees["portee"], _recharge):
		"reculer": _avancer_vers(global_position * 2.0 - _cible.global_position, donnees["vitesse"])
		"avancer": _avancer_vers(_cible.global_position, donnees["vitesse"])
		"tourner":
			var tangente := global_position.direction_to(_cible.global_position).rotated(PI * 0.5 * _sens_contournement)
			velocity = tangente * donnees["vitesse"] * 0.55 * _facteur_vitesse()
			move_and_slide()
		"tirer":
			_recharge = donnees.get("recharge", 1.45)
			_etat = "vise"
			_minuterie = donnees.get("telegraphe", 0.48)
			var attente := _minuterie
			await get_tree().create_timer(attente).timeout
			if not is_instance_valid(self) or _cible == null or not is_instance_valid(_cible) or _gel > 0.0:
				return
			_etat = "repos"
			_tirer_vers(_cible.global_position)

func _agir_miroir(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	match Cerveaux.miroir(distance, donnees["portee"], _recharge):
		"avancer": _avancer_vers(_cible.global_position, donnees["vitesse"])
		"pulser":
			_recharge = donnees.get("recharge", 2.35)
			_etat = "pulse"
			_minuterie = donnees.get("telegraphe", 0.65)
			var attente := _minuterie
			await get_tree().create_timer(attente).timeout
			if not is_instance_valid(self) or _gel > 0.0:
				return
			_etat = "repos"
			_tirer_cercle(int(donnees.get("projectiles_cercle", 8)))

func _agir_phaseur(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	match Cerveaux.phaseur(distance, donnees["portee"], _recharge, _etat, _minuterie):
		"avancer": _avancer_vers(_cible.global_position, donnees["vitesse"])
		"tourner":
			var radial := _cible.global_position.direction_to(global_position)
			velocity = radial.rotated(PI * 0.5 * _sens_contournement) * donnees["vitesse"] * 0.55
			move_and_slide()
		"phase":
			_etat = "phase"
			_minuterie = donnees.get("telegraphe", 0.62)
			_recharge = donnees.get("recharge", 2.55)
		"disparaitre":
			velocity = Vector2.ZERO
		"reapparaitre":
			# Il traverse le centre plutot que de se teleporter sur le joueur : le
			# changement de cote surprend, mais la distance reste previsible.
			var radial := _cible.global_position.direction_to(global_position)
			var destination := _cible.global_position - radial * float(donnees["portee"])
			global_position.x = clampf(destination.x, limites.position.x, limites.end.x)
			global_position.y = clampf(destination.y, limites.position.y, limites.end.y)
			_etat = "repos"
			_tirer_cercle(int(donnees.get("projectiles_cercle", 6)))
			_tirer_vers(_cible.global_position)

func _agir_tisseur(_delta: float) -> void:
	if _etat == "tisser":
		velocity = Vector2.ZERO
		if _minuterie <= 0.0:
			_etat = "repos"
			_tirer_vers(_cible.global_position)
		return
	var distance := global_position.distance_to(_cible.global_position)
	match Cerveaux.tisseur(distance, donnees["portee"], _recharge):
		"reculer": _avancer_vers(global_position * 2.0 - _cible.global_position, donnees["vitesse"])
		"avancer": _avancer_vers(_cible.global_position, donnees["vitesse"])
		"croiser":
			var tangente := global_position.direction_to(_cible.global_position).rotated(PI * 0.5 * _sens_contournement)
			velocity = tangente * donnees["vitesse"] * _facteur_vitesse()
			move_and_slide()
		"tisser":
			_etat = "tisser"
			_minuterie = donnees.get("telegraphe", 0.52)
			_recharge = donnees.get("recharge", 1.85)

func _agir_volatile(_delta: float) -> void:
	var distance := global_position.distance_to(_cible.global_position)
	match Cerveaux.volatile(distance, donnees.get("rayon_explosion", donnees["portee"]),
			_etat, _minuterie):
		"avancer": _avancer_vers(_cible.global_position, donnees["vitesse"])
		"gonfler":
			velocity = Vector2.ZERO
			if _etat != "gonfler":
				_etat = "gonfler"
				_minuterie = donnees.get("preparation", 0.88)
		"exploser":
			_tirer_cercle(int(donnees.get("projectiles_cercle", 9)))
			if distance <= float(donnees.get("rayon_explosion", donnees["portee"])):
				_cible.recevoir_degats(donnees["degats"])
			pv = 0.0
			_mourir()

func recevoir_degats(montant: float, effets: Array = []) -> void:
	if pv <= 0.0:
		return
	var facteur := Reglages.ACIDE_VULNERABILITE if _acide > 0.0 else 1.0
	pv -= montant * facteur
	_flash = 1.0
	touche.emit(global_position, donnees["couleur"])
	for effet in effets:
		match effet:
			"braise":
				_braise = Reglages.BRAISE_DUREE
				_brulure_dps += Reglages.BRAISE_DEGATS_PAR_SECONDE
			"feu":
				_braise = Reglages.BRAISE_DUREE
				_brulure_dps += montant * Reglages.FEU_DOT_PART_PAR_SECONDE
			"givre": _givre = Reglages.GIVRE_DUREE
			"acide": _acide = Reglages.ACIDE_DUREE
			"eau":
				_givre = Reglages.GIVRE_DUREE
				_acide = Reglages.ACIDE_DUREE
			"terre":
				if not _terre_declenchee:
					_terre_declenchee = true
					_recharge = maxf(_recharge, Reglages.TERRE_RETARD_ATTAQUE)
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
		pv -= _brulure_dps * delta
		if pv <= 0.0:
			_mourir()
	elif _brulure_dps > 0.0:
		_brulure_dps = 0.0

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
	draw_circle(Vector2.ZERO, r * 0.9, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# La menace est plus claire et plus saturee que le fond. Les telegraphes
	# restent proceduraux, mais les silhouettes sont maintenant peintes.
	Dessin.halo(self, Vector2.ZERO, r * 2.2, couleur, 4)
	_dessiner_telegraphe(r)
	var vers_retro := Vector2.DOWN if _cible == null else global_position.direction_to(_cible.global_position)
	Retro16.dessiner_ennemi(self, donnees, _anim, _etat, vers_retro)

	if _braise > 0.0:
		for i in 3:
			var a := _anim * 4.0 + float(i) * TAU / 3.0
			var p := Vector2(cos(a), sin(a * 1.3)) * r * 0.8 - Vector2(0, r * 0.6 + sin(_anim * 6.0 + i) * 6.0)
			draw_circle(p, r * 0.16, Palette.BRAISE)
	if _gel > 0.0:
		Dessin.contour(self, Dessin.etoile(Vector2.ZERO, r * 1.5, r * 0.7, 6, _anim * 0.4), Palette.GIVRE, 2.5)
	_dessiner_barre_de_vie(r)

func _dessiner_repli(r: float, couleur: Color) -> void:
	match donnees.get("forme", "goutte"):
		"plume", "ruban": _dessiner_sentinelle(r, couleur)
		"dard", "belier": _dessiner_veloce(r, couleur)
		"masque", "miroir": _dessiner_essaimeur(r, couleur)
		"phaseur": _dessiner_phaseur(r, couleur)
		"fuseau": _dessiner_tisseur(r, couleur)
		"fiole": _dessiner_volatile(r, couleur)
		_: _dessiner_rampant(r, couleur)

func _dessiner_telegraphe(r: float) -> void:
	if _cible == null:
		return
	var vers := global_position.direction_to(_cible.global_position)
	if donnees.get("cerveau", "") in ["sentinelle", "harceleur"] and _etat == "vise":
		var distance_cible := global_position.distance_to(_cible.global_position)
		draw_line(vers * r, vers * distance_cible, Color(Palette.DANGER, 0.35 + 0.25 * sin(_anim * 30.0)), 3.0, true)
	elif donnees.get("cerveau", "") == "veloce" and _etat == "preparer":
		var intensite := 0.4 + 0.6 * sin(_anim * 24.0)
		draw_line(vers * r, vers * 620.0, Color(Palette.DANGER, 0.25 * intensite), 8.0, true)
		Dessin.contour(self, Dessin.polygone_regulier(Vector2.ZERO, r * (1.6 + 0.3 * intensite), 3, vers.angle()), Palette.DANGER, 3.0)
	elif donnees.get("cerveau", "") == "miroir" and _etat == "pulse":
		var avancee := 1.0 - clampf(_minuterie / maxf(0.1, float(donnees.get("telegraphe", 0.65))), 0.0, 1.0)
		draw_arc(Vector2.ZERO, r * (1.25 + avancee * 0.55), 0.0, TAU, 32,
			Color(Palette.DANGER, 0.25 + avancee * 0.55), 3.0 + avancee * 3.0, true)
	elif donnees.get("cerveau", "") == "orbiteur":
		draw_arc(Vector2.ZERO, r * 1.35, _anim, _anim + PI * 1.35, 20,
			Color(donnees["couleur"], 0.65), 2.5, true)
	elif donnees.get("cerveau", "") == "phaseur" and _etat == "phase":
		var avancee := 1.0 - clampf(_minuterie / maxf(0.1, float(donnees.get("telegraphe", 0.62))), 0.0, 1.0)
		for index in 3:
			draw_arc(Vector2.ZERO, r * (1.25 + avancee + index * 0.18), _anim + index,
				_anim + index + PI * 0.9, 20, Color(donnees["couleur"], 0.72 - avancee * 0.35), 3.0, true)
	elif donnees.get("cerveau", "") == "tisseur" and _etat == "tisser":
		var distance_cible := global_position.distance_to(_cible.global_position)
		for decalage in [-1.0, 0.0, 1.0]:
			var travers: Vector2 = vers.orthogonal() * float(decalage) * float(donnees.get("ecart_lateral", 82.0))
			draw_line(vers * r + travers, vers * distance_cible + travers,
				Color(donnees["couleur"], 0.48), 2.5, true)
	elif donnees.get("cerveau", "") == "volatile" and _etat == "gonfler":
		var avancee := 1.0 - clampf(_minuterie / maxf(0.1, float(donnees.get("preparation", 0.88))), 0.0, 1.0)
		draw_arc(Vector2.ZERO, float(donnees.get("rayon_explosion", 205.0)), 0.0, TAU, 40,
			Color(Palette.DANGER, 0.18 + avancee * 0.45), 3.0 + avancee * 4.0, true)

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
	draw_circle(vers * r * 0.12, r * 0.20, Color(0.18, 0.14, 0.25))
	if _etat == "vise":
		# Trait de visee : la spec veut un tir telegraphie, donc visible avant.
		var distance_cible := global_position.distance_to(_cible.global_position)
		draw_line(vers * r, vers * distance_cible, Color(Palette.DANGER, 0.35 + 0.25 * sin(_anim * 30.0)), 3.0, true)

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
	draw_colored_polygon(corps, couleur.darkened(0.08))
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

func _dessiner_phaseur(r: float, couleur: Color) -> void:
	var effacement := 1.0
	if _etat == "phase":
		effacement = 0.35 + 0.65 * clampf(_minuterie / maxf(0.1,
			float(donnees.get("telegraphe", 0.62))), 0.0, 1.0)
	var teinte := Color(couleur, effacement)
	for index in 4:
		var debut := _anim * (0.7 if index % 2 == 0 else -0.55) + float(index) * PI * 0.5
		draw_arc(Vector2.ZERO, r * (0.78 + index * 0.16), debut, debut + PI * 0.68,
			18, teinte.lightened(float(index) * 0.06), 5.0, true)
	draw_circle(Vector2.ZERO, r * 0.48, Color(0.06, 0.03, 0.12, effacement))
	draw_colored_polygon(Dessin.polygone_regulier(Vector2.ZERO, r * 0.32, 6,
		_anim * 0.45), teinte.lightened(0.35))

func _dessiner_tisseur(r: float, couleur: Color) -> void:
	var angle := _anim * 0.7
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	var fuseau := PackedVector2Array([
		Vector2(0.0, -r * 1.25), Vector2(r * 0.58, -r * 0.38),
		Vector2(r * 0.48, r * 0.52), Vector2(0.0, r * 1.25),
		Vector2(-r * 0.48, r * 0.52), Vector2(-r * 0.58, -r * 0.38)])
	draw_colored_polygon(fuseau, couleur.darkened(0.12))
	Dessin.contour(self, fuseau, couleur.lightened(0.42), 3.0)
	for cote in [-1.0, 1.0]:
		draw_line(Vector2(0.0, -r), Vector2(cote * r * 1.1, 0.0),
			Color(couleur, 0.62), 2.0, true)
		draw_line(Vector2(cote * r * 1.1, 0.0), Vector2(0.0, r),
			Color(couleur, 0.62), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, r * 0.24, Color(0.95, 1.0, 0.94, 0.92))

func _dessiner_volatile(r: float, couleur: Color) -> void:
	var gonflement := 1.0
	if _etat == "gonfler":
		var avancee := 1.0 - clampf(_minuterie / maxf(0.1,
			float(donnees.get("preparation", 0.88))), 0.0, 1.0)
		gonflement = 1.0 + avancee * 0.38 + sin(_anim * 28.0) * 0.05
	var corps := Dessin.goutte(Vector2(0.0, r * 0.12), r * gonflement, PI, 1.16)
	draw_colored_polygon(corps, Color(couleur, 0.82))
	Dessin.contour(self, corps, couleur.lightened(0.35), 3.0)
	draw_rect(Rect2(-r * 0.34, -r * 1.18, r * 0.68, r * 0.36),
		Color(0.78, 0.70, 0.52))
	for index in 3:
		var bulle := Vector2(sin(_anim * (2.2 + index * 0.3) + index) * r * 0.42,
			r * 0.62 - fmod(_anim * (18.0 + index * 4.0) + index * 13.0, r * 1.15))
		draw_circle(bulle, r * (0.08 + index * 0.025), Color.WHITE * Color(1, 1, 1, 0.58))
