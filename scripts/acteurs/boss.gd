class_name Boss
extends CharacterBody2D

# Moteur commun des identites majeures. Chaque profil choisit ses motifs dans
# le catalogue ; le moteur garantit les memes telegraphes et limites de densite.

signal mort(qui: Node, position: Vector2, couleur: Color)
signal tir_demande(tir_ennemi: Tir, origine: Vector2, direction: Vector2)
signal invocation_demandee(id: String, position: Vector2)
signal touche(position: Vector2, couleur: Color)
signal phase_changee(phase: int)

const MOTIFS_PHASE_1: Array[String] = ["barrage_horizontal", "eventail_lent", "pause"]
const MOTIFS_PHASE_2: Array[String] = ["barrage_croise", "invocation", "charge", "pause"]
const MOTIFS_CONNUS: Array[String] = ["barrage_horizontal", "eventail_lent", "barrage_croise",
	"invocation", "charge", "spirale", "anneau_breche", "pluie", "poursuite", "pause",
	"griffure", "echo_errata", "quadrillage", "machoire", "calligraphie", "indexation",
	"onde_marge", "rosace", "estampille", "copie_double"]
const MOTIFS_SIGNATURE: Array[String] = ["griffure", "echo_errata", "quadrillage", "machoire",
	"calligraphie", "indexation", "onde_marge", "rosace", "estampille", "copie_double"]
const GLYPHES_ORNEMENTS: Array[String] = ["eclats", "oeil", "hexagone", "eclair", "goutte",
	"vague", "nuage", "cristal", "zigzag", "fiole"]

static func phase_pour(pv_restants: float, pv_max: float) -> int:
	return 2 if pv_restants < pv_max * 0.5 else 1

static func motifs_pour(id: String, phase: int) -> Array:
	var profil := CatalogueEnnemis.par_id(id)
	var cle := "motifs_phase_1" if phase == 1 else "motifs_phase_2"
	return profil.get(cle, MOTIFS_PHASE_1 if phase == 1 else MOTIFS_PHASE_2)

static func motif_suivant(phase: int, index: int, id := "le_correcteur") -> String:
	var motifs := motifs_pour(id, phase)
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
var _brulure_dps := 0.0
var _givre := 0.0
var _acide := 0.0
var _terre_declenchee := false
var _gel := 0.0
var _ancre := Vector2.ZERO
var _direction_charge := Vector2.ZERO
var _apparition := 0.0
var _eclat_phase := 0.0
var _telegraphe_signature := 0.0
var _alternance := 0

func configurer(donnees_: Dictionary) -> void:
	donnees = donnees_
	pv = donnees["pv"]
	pv_max = donnees["pv"]

func _ready() -> void:
	add_to_group("ennemis")
	add_to_group("boss")
	collision_layer = 2
	collision_mask = 4
	_cible = get_tree().get_first_node_in_group("cibles_ennemis")
	($CollisionShape2D.shape as CircleShape2D).radius = float(donnees["rayon"]) \
		* Reglages.BOSS_HITBOX_MULT
	# Il tient le haut de la salle : le joueur garde toute la profondeur pour
	# esquiver. Sans ancre fixe, il derivait dans un coin et devenait illisible.
	_ancre = Vector2((limites.position.x + limites.end.x) / 2.0, limites.position.y + 240.0)
	global_position = _ancre
	Sons.jouer("boss", -8.0)

func _physics_process(delta: float) -> void:
	_anim += delta
	_apparition = minf(1.0, _apparition + delta / Reglages.BOSS_APPARITION_DUREE)
	_eclat_phase = maxf(0.0, _eclat_phase - delta)
	_flash = maxf(0.0, _flash - delta * 6.0)
	_gel = maxf(0.0, _gel - delta)
	_givre = maxf(0.0, _givre - delta)
	_acide = maxf(0.0, _acide - delta)
	if _braise > 0.0:
		_braise -= delta
		pv -= _brulure_dps * delta
		if pv <= 0.0:
			_mourir()
			return
	elif _brulure_dps > 0.0:
		_brulure_dps = 0.0
	queue_redraw()
	if _cible == null or not is_instance_valid(_cible) or not _cible.visible:
		_cible = get_tree().get_first_node_in_group("cibles_ennemis")
		return
	if _apparition < 1.0:
		velocity = Vector2.ZERO
		return
	if _gel > 0.0:
		return

	var phase := phase_pour(pv, pv_max)
	if phase != _phase:
		_phase = phase
		_index_motif = 0
		_minuterie = 0.0
		_eclat_phase = 1.0
		phase_changee.emit(_phase)
		Sons.jouer("boss", -6.0, 0.8)

	_minuterie -= delta
	if _minuterie <= 0.0:
		_motif = motif_suivant(_phase, _index_motif, str(donnees.get("id", "le_correcteur")))
		_index_motif += 1
		_minuterie = _duree_du_motif(_motif)
		_cadence_motif = 0.0
		_telegraphe_signature = Reglages.BOSS_TELEGRAPHE_SIGNATURE if _motif in MOTIFS_SIGNATURE else 0.0
		_commencer_motif(_motif)
	_executer_motif(_motif, delta)
	global_position = Geometrie.contraindre_dans_rect(global_position, limites,
		($CollisionShape2D.shape as CircleShape2D).radius)

func _duree_du_motif(motif: String) -> float:
	if Reglages.BOSS_DUREES_MOTIFS.has(motif):
		return float(Reglages.BOSS_DUREES_MOTIFS[motif])
	return float(Reglages.BOSS_DUREES_MOTIFS["pause_phase_2" if _phase == 2 else "pause_phase_1"])

func _commencer_motif(motif: String) -> void:
	if motif == "invocation":
		var places := Reglages.PLAFOND_ENNEMIS - get_tree().get_nodes_in_group("ennemis").size()
		if places <= 0:
			return
		for i in mini(places, int(donnees.get("nb_invocations_boss", 3))):
			var ecart := Vector2(randf_range(-200.0, 200.0), randf_range(-60.0, 160.0))
			invocation_demandee.emit("encrier_rampant", global_position + ecart)
	elif motif == "charge":
		_direction_charge = global_position.direction_to(_cible.global_position)

func _executer_motif(motif: String, delta: float) -> void:
	if _telegraphe_signature > 0.0:
		_telegraphe_signature = maxf(0.0, _telegraphe_signature - delta)
		_flotter(delta)
		return
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
		"spirale":
			_flotter(delta)
			if _cadence_motif <= 0.0:
				_cadence_motif = 0.13 if _phase == 2 else 0.17
				_lancer(global_position, Vector2.RIGHT.rotated(_anim * 2.65), 0.62)
		"anneau_breche":
			_flotter(delta)
			if _cadence_motif <= 0.0:
				_cadence_motif = 0.95
				var nombre := 14
				var angle_cible := global_position.direction_to(_cible.global_position).angle()
				var breche := posmod(roundi(angle_cible / TAU * nombre), nombre)
				for k in nombre:
					if absi(k - breche) <= 1 or absi(k - breche) >= nombre - 1:
						continue
					_lancer(global_position, Vector2.RIGHT.rotated(TAU * float(k) / nombre), 0.68)
		"pluie":
			_flotter(delta)
			if _cadence_motif <= 0.0:
				_cadence_motif = 0.52
				var voie_sure := int(fmod(_anim * 1.7, 7.0))
				for k in 7:
					if k == voie_sure or k == (voie_sure + 1) % 7:
						continue
					var origine := Vector2(140.0 + float(k) * 125.0, limites.position.y + 15.0)
					_lancer(origine, Vector2.DOWN, 0.58)
		"poursuite":
			_flotter(delta)
			if _cadence_motif <= 0.0:
				_cadence_motif = 0.48
				var vers := global_position.direction_to(_cible.global_position)
				_lancer(global_position, vers, 0.76)
				_lancer(global_position, vers.rotated(sin(_anim * 3.0) * 0.16), 0.55)
		"griffure":
			_flotter(delta)
			if _signature_prete(motif):
				_alternance += 1
				var sens := 1.0 if _alternance % 2 == 0 else -1.0
				var breche := posmod(_alternance, 5)
				for k in 5:
					if k == breche:
						continue
					var origine := Vector2(limites.position.x + limites.size.x * (float(k) + 0.5) / 5.0,
						limites.position.y + 10.0)
					_lancer(origine, Vector2.DOWN.rotated(sens * 0.24), 0.72)
		"echo_errata":
			_flotter(delta)
			if _signature_prete(motif):
				_alternance += 1
				var vers := global_position.direction_to(_cible.global_position)
				for cote in [-1.0, 1.0]:
					var fantome := global_position + vers.orthogonal() * float(cote) * (125.0 + _phase * 22.0)
					_lancer(fantome, fantome.direction_to(_cible.global_position).rotated(float(cote) * 0.10), 0.66)
				_lancer(global_position, vers, 0.82)
		"quadrillage":
			_flotter(delta)
			if _signature_prete(motif):
				_alternance += 1
				var breche := posmod(_alternance * 2, 6)
				if _alternance % 2 == 0:
					for k in 6:
						if k == breche or k == (breche + 1) % 6:
							continue
						_lancer(Vector2(limites.position.x + 8.0, limites.position.y + limites.size.y * (float(k) + 0.5) / 6.0), Vector2.RIGHT, 0.66)
				else:
					for k in 6:
						if k == breche or k == (breche + 1) % 6:
							continue
						_lancer(Vector2(limites.position.x + limites.size.x * (float(k) + 0.5) / 6.0, limites.position.y + 8.0), Vector2.DOWN, 0.66)
		"machoire":
			_flotter(delta)
			if _signature_prete(motif):
				_alternance += 1
				var hauteur := _cible.global_position.y + sin(float(_alternance)) * 150.0
				for cote in [-1.0, 1.0]:
					var x := limites.position.x + 8.0 if cote < 0.0 else limites.end.x - 8.0
					for dent in [-1.0, 0.0, 1.0]:
						var origine := Vector2(x, clampf(hauteur + float(dent) * 95.0, limites.position.y, limites.end.y))
						_lancer(origine, Vector2(float(cote), 0.0) * -1.0, 0.62)
		"calligraphie":
			_flotter(delta)
			if _signature_prete(motif):
				var angle := _anim * 2.4 + sin(_anim * 5.0) * 0.46
				_lancer(global_position, Vector2.RIGHT.rotated(angle), 0.48)
				_lancer(global_position, Vector2.RIGHT.rotated(angle + PI), 0.48)
		"indexation":
			_flotter(delta)
			if _signature_prete(motif):
				var prediction := _cible.global_position
				if _cible is CharacterBody2D:
					prediction += (_cible as CharacterBody2D).velocity * (0.28 if _phase == 1 else 0.40)
				var vers := global_position.direction_to(prediction)
				for angle in [-0.13, 0.0, 0.13]:
					_lancer(global_position, vers.rotated(float(angle)), 0.62)
		"onde_marge":
			_flotter(delta)
			if _signature_prete(motif):
				_alternance += 1
				var voie := posmod(_alternance, 7)
				for k in 7:
					if k == voie or k == (voie + 1) % 7:
						continue
					var y := limites.position.y + limites.size.y * (float(k) + 0.5) / 7.0
					_lancer(Vector2(limites.position.x + 6.0, y), Vector2.RIGHT, 0.52)
					_lancer(Vector2(limites.end.x - 6.0, y + 34.0), Vector2.LEFT, 0.52)
		"rosace":
			_flotter(delta)
			if _signature_prete(motif):
				_alternance += 1
				var nombre := 10 if _phase == 1 else 14
				for k in nombre:
					var angle := TAU * float(k) / float(nombre) + float(_alternance) * 0.19
					_lancer(global_position, Vector2.RIGHT.rotated(angle + sin(angle * 3.0) * 0.12), 0.54)
		"estampille":
			_flotter(delta)
			if _signature_prete(motif):
				_alternance += 1
				var nombre := 12
				var breche := posmod(_alternance * 3, nombre)
				for k in nombre:
					if k == breche or k == (breche + 1) % nombre:
						continue
					_lancer(global_position, Vector2.RIGHT.rotated(TAU * float(k) / nombre), 0.58)
				_lancer(global_position, global_position.direction_to(_cible.global_position), 0.84)
		"copie_double":
			_flotter(delta)
			if _signature_prete(motif):
				var vers := global_position.direction_to(_cible.global_position)
				for cote in [-1.0, 1.0]:
					var origine := global_position + vers.orthogonal() * float(cote) * 175.0
					_lancer(origine, origine.direction_to(_cible.global_position), 0.64)
					if _phase == 2:
						_lancer(origine, origine.direction_to(_cible.global_position).rotated(float(cote) * 0.18), 0.48)
		"charge":
			# Six dixiemes de seconde de visee avant le mouvement : une charge
			# puissante doit tester l'esquive, pas surprendre hors ecran.
			if _minuterie > 2.0:
				velocity = Vector2.ZERO
			else:
				velocity = _direction_charge * donnees["vitesse"] * 2.2 * Reglages.ENNEMI_VITESSE_MULT
				move_and_slide()
				global_position = Geometrie.contraindre_dans_rect(global_position, limites,
					($CollisionShape2D.shape as CircleShape2D).radius)
				if global_position.distance_to(_cible.global_position) < donnees["rayon"] + 40.0:
					_cible.recevoir_degats(donnees["degats"])
					_direction_charge = -_direction_charge
		_:
			_flotter(delta)

func _signature_prete(motif: String) -> bool:
	if _cadence_motif > 0.0:
		return false
	_cadence_motif = float(Reglages.BOSS_CADENCES_SIGNATURE[motif])
	return true

func _flotter(_delta: float) -> void:
	# Il revient toujours vers le haut de l'arene : le joueur garde de la place.
	var vise := Vector2(_ancre.x + sin(_anim * 0.7) * 260.0, _ancre.y)
	velocity = global_position.direction_to(vise) * donnees["vitesse"] * 0.6 \
		* Reglages.ENNEMI_VITESSE_MULT
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
					_minuterie = maxf(_minuterie, Reglages.TERRE_RETARD_ATTAQUE)
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
	var entree := ease(_apparition, 0.35)
	var r: float = donnees["rayon"] * (0.28 + entree * 0.72)
	var couleur: Color = donnees["couleur"]
	couleur.a = 0.18 + entree * 0.82
	if _givre > 0.0:
		couleur = couleur.lerp(Palette.GIVRE, 0.35)
	if _flash > 0.0:
		couleur = couleur.lerp(Color.WHITE, _flash * 0.7)

	draw_set_transform(Vector2(0, r * 0.8), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	Dessin.halo(self, Vector2.ZERO, r * 2.4, couleur, 5)
	if _telegraphe_signature > 0.0:
		var avancee := 1.0 - _telegraphe_signature / Reglages.BOSS_TELEGRAPHE_SIGNATURE
		draw_arc(Vector2.ZERO, r * (2.1 - avancee * 0.72), 0.0, TAU, 42,
			Color(Palette.DANGER, 0.28 + avancee * 0.52), 4.0 + avancee * 4.0, true)
	if _eclat_phase > 0.0:
		var expansion := 1.0 - _eclat_phase
		draw_arc(Vector2.ZERO, r * (1.35 + expansion * 1.25), 0.0, TAU, 42,
			Color(Palette.DANGER, _eclat_phase * 0.72), 7.0 * _eclat_phase + 2.0, true)
	match int(donnees.get("ornement", 0)):
		0:
			Dessin.contour(self, Dessin.etoile(Vector2.ZERO, r * 1.72, r * 1.30, 7,
				-_anim * 0.34), Color(couleur, 0.46), 4.0)
		1:
			for index in 3:
				draw_arc(Vector2.ZERO, r * (1.35 + float(index) * 0.18), _anim * 0.45 + index,
					_anim * 0.45 + index + PI * 1.18, 32, Color(couleur, 0.42), 3.0, true)
		2:
			Dessin.contour(self, Dessin.polygone_regulier(Vector2.ZERO, r * 1.48, 6,
				PI / 6.0 + _anim * 0.16), Color(couleur, 0.38), 3.0)
		3:
			for index in 4:
				draw_line(Vector2.LEFT.rotated(_anim * 0.22 + index * PI * 0.5) * r * 1.25,
					Vector2.RIGHT.rotated(_anim * 0.22 + index * PI * 0.5) * r * 1.7,
					Color(couleur, 0.42), 3.0, true)
		4:
			Dessin.contour(self, Dessin.etoile(Vector2.ZERO, r * 1.75, r * 1.52, 11,
				_anim * 0.28), Color(couleur, 0.42), 3.0)
		5:
			for index in 3:
				var p := Vector2.RIGHT.rotated(_anim * (0.4 + index * 0.12) + index * TAU / 3.0) * r * 1.55
				draw_circle(p, r * 0.16, Color(couleur, 0.65))
		6:
			draw_arc(Vector2.ZERO, r * 1.58, -PI * 0.85, PI * 0.85, 36, Color(couleur, 0.5), 7.0, true)
		7:
			for index in 6:
				var a := _anim * 0.18 + float(index) * TAU / 6.0
				draw_circle(Vector2.RIGHT.rotated(a) * r * 1.55, r * 0.11, Color(couleur, 0.62))
		8:
			Dessin.contour(self, Dessin.polygone_regulier(Vector2.ZERO, r * 1.62, 4,
				PI * 0.25 - _anim * 0.20), Color(couleur, 0.45), 5.0)
		_:
			Dessin.contour(self, Dessin.etoile(Vector2.ZERO, r * 1.82, r * 1.36, 10,
				_anim * 0.14), Color(couleur, 0.48), 4.0)
	if _motif == "charge" and _minuterie > 2.0:
		draw_line(_direction_charge * r, _direction_charge * 1050.0,
			Color(Palette.DANGER, 0.30 + 0.20 * sin(_anim * 26.0)), 7.0, true)
	if _phase == 2:
		Dessin.contour(self, Dessin.etoile(Vector2.ZERO, r * 1.6, r * 1.25, 9, _anim * 0.9), Color(Palette.DANGER, 0.5), 3.0)
	Retro16.dessiner_boss(self, donnees, _anim, _phase, _motif)
	# Le sigil reste devant la planche peinte : couleur, couronne et repertoire
	# donnent ainsi trois niveaux d'identification a chaque adversaire majeur.
	var ornement := posmod(int(donnees.get("ornement", 0)), GLYPHES_ORNEMENTS.size())
	var centre_sigil := Vector2(0, r * 0.06)
	draw_circle(centre_sigil, r * 0.25, Color(0.035, 0.018, 0.065, 0.78))
	Dessin.glyphe(self, GLYPHES_ORNEMENTS[ornement], centre_sigil, r * 0.15,
		couleur.lightened(0.42))

func _dessiner_corps_miniboss(r: float, couleur: Color) -> void:
	var clair := couleur.lightened(0.38)
	var sombre := couleur.darkened(0.48)
	match str(donnees.get("silhouette", "correcteur")):
		"rature":
			var corps := PackedVector2Array([
				Vector2(-r * 1.28, -r * 0.58), Vector2(-r * 0.18, -r * 0.34),
				Vector2(r * 1.22, -r * 0.78), Vector2(r * 0.34, r * 0.08),
				Vector2(r * 1.02, r * 0.58), Vector2(-r * 0.20, r * 0.32),
				Vector2(-r * 1.18, r * 0.74), Vector2(-r * 0.56, 0.0)])
			draw_colored_polygon(corps, couleur)
			Dessin.contour(self, corps, clair, 5.0)
			for barre in [-0.34, 0.0, 0.34]:
				draw_line(Vector2(-r * 0.72, r * float(barre)),
					Vector2(r * 0.74, r * (float(barre) - 0.28)), sombre, 6.0, true)
		"errata":
			for index in 3:
				var centre := Vector2.RIGHT.rotated(_anim * (0.38 + index * 0.08) + index * TAU / 3.0) * r * 0.48
				var tache := Dessin.blob(centre, r * (0.66 - index * 0.06), index * 97 + 11, 0.18, _anim * 1.5)
				draw_colored_polygon(tache, couleur.lightened(index * 0.07))
				Dessin.contour(self, tache, clair, 3.0)
				draw_circle(centre, r * 0.13, sombre)
		"correcteur":
			var masque := Dessin.polygone_regulier(Vector2.ZERO, r * 1.15, 6, PI / 6.0)
			draw_colored_polygon(masque, couleur)
			Dessin.contour(self, masque, clair, 6.0)
			draw_rect(Rect2(-r * 0.74, -r * 0.23, r * 1.48, r * 0.46), Color(clair, 0.86))
			for x in [-0.46, 0.0, 0.46]:
				draw_rect(Rect2(r * float(x) - r * 0.07, -r * 0.23, r * 0.14, r * 0.46), sombre)
		"reliure":
			for cote in [-1.0, 1.0]:
				draw_set_transform(Vector2(0.0, float(cote) * r * 0.12), float(cote) * -0.22, Vector2.ONE)
				var page := Rect2(-r * 1.05, -r * 0.58, r * 2.1, r * 0.52)
				draw_rect(page, couleur)
				draw_rect(page, clair, false, 5.0)
				for dent in 5:
					var x := -r * 0.82 + float(dent) * r * 0.41
					draw_colored_polygon(PackedVector2Array([Vector2(x, -r * 0.06),
						Vector2(x + r * 0.18, r * 0.24), Vector2(x + r * 0.34, -r * 0.06)]), clair)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(Vector2.ZERO, r * 0.32, sombre)
		"virgule":
			var tete := Dessin.goutte(Vector2(-r * 0.12, -r * 0.18), r * 0.92, PI * 0.84, 1.34)
			draw_colored_polygon(tete, couleur)
			Dessin.contour(self, tete, clair, 5.0)
			for index in 4:
				var p := Vector2(r * (0.36 + index * 0.19), r * (0.35 + index * 0.17))
				draw_circle(p, r * (0.27 - index * 0.045), couleur.lerp(clair, index * 0.16))
			draw_circle(Vector2(-r * 0.28, -r * 0.28), r * 0.19, sombre)
		"index":
			draw_circle(Vector2(0.0, r * 0.20), r * 0.66, couleur)
			for doigt in 5:
				var x := (float(doigt) - 2.0) * r * 0.30
				var longueur := r * (0.86 + (2 - absi(doigt - 2)) * 0.13)
				draw_line(Vector2(x, r * 0.08), Vector2(x * 1.10, -longueur), clair, r * 0.20, true)
			draw_arc(Vector2(0.0, r * 0.20), r * 0.66, 0.0, TAU, 30, clair, 5.0, true)
			draw_circle(Vector2.ZERO, r * 0.18, sombre)
		"marge":
			var coeur := Rect2(-r * 0.28, -r * 1.02, r * 0.56, r * 2.04)
			draw_rect(coeur, couleur)
			draw_rect(coeur, clair, false, 5.0)
			for cote in [-1.0, 1.0]:
				var x := float(cote) * r * 0.92
				draw_line(Vector2(x, -r), Vector2(x, r), clair, 8.0, true)
				draw_line(Vector2(x, -r), Vector2(float(cote) * r * 0.54, -r), clair, 8.0, true)
				draw_line(Vector2(x, r), Vector2(float(cote) * r * 0.54, r), clair, 8.0, true)
			draw_circle(Vector2.ZERO, r * 0.17, sombre)
		"enlumineur":
			var rayons := Dessin.etoile(Vector2.ZERO, r * 1.25, r * 0.72, 12, _anim * 0.16)
			draw_colored_polygon(rayons, couleur)
			Dessin.contour(self, rayons, clair, 5.0)
			draw_circle(Vector2.ZERO, r * 0.60, clair)
			draw_colored_polygon(Dessin.etoile(Vector2.ZERO, r * 0.42, r * 0.20, 8,
				-_anim * 0.38), sombre)
		"signet":
			draw_set_transform(Vector2.ZERO, PI * 0.25 + sin(_anim * 0.8) * 0.04, Vector2.ONE)
			var sceau := Rect2(-r * 0.78, -r * 0.78, r * 1.56, r * 1.56)
			draw_rect(sceau, couleur)
			draw_rect(sceau, clair, false, 7.0)
			draw_rect(sceau.grow(-r * 0.22), sombre, false, 5.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for index in 3:
				draw_circle(Vector2(0.0, r * (0.70 + index * 0.18)), r * (0.22 - index * 0.04), couleur)
		"copiste":
			for cote in [-1.0, 1.0]:
				var centre := Vector2(float(cote) * r * 0.48, sin(_anim * 1.6 + float(cote)) * r * 0.12)
				var visage := Dessin.polygone_regulier(centre, r * 0.70, 5,
					-PI / 2.0 + float(cote) * 0.12)
				draw_colored_polygon(visage, couleur.lightened(0.08 if cote > 0.0 else 0.0))
				Dessin.contour(self, visage, clair, 4.0)
				draw_circle(centre + Vector2(float(cote) * r * 0.14, -r * 0.08), r * 0.13, sombre)
		_:
			draw_circle(Vector2.ZERO, r * 1.12, couleur)
			draw_arc(Vector2.ZERO, r * 1.12, 0.0, TAU, 36, clair, 5.0, true)
