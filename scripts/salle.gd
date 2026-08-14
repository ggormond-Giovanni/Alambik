extends Node2D

# Une salle est une arene fermee a plusieurs vagues. Les compositions sont des donnees
# (data/vagues.gd), jamais
# du code.

signal terminee
signal ennemi_abattu(experience: int)

const PROJECTILE := preload("res://scenes/projectile.tscn")
const ENNEMI := preload("res://scenes/ennemi.tscn")
const BOSS := preload("res://scenes/boss.tscn")
const PLANCHE_OBSTACLES := preload("res://assets/visual/obstacles.png")
const PORTAIL_PREMIUM := preload("res://assets/visual/portail_sortie_premium.png")
const RECTS_OBSTACLES := [
	Rect2(79, 317, 546, 248),
	Rect2(707, 266, 498, 300),
	Rect2(1297, 302, 494, 259),
]

var effets: Node2D
var limites := Rect2()
var numero := 1

var _vagues: Array = []
var _vague_courante := -1
var _finie := false
var _portail_ouvert := false
var _portail: Area2D
var _obstacles: Array[Rect2] = []
var _anim := 0.0
var _attente_vague := 0.0
var _mine_active := false
var _mine_temps := 0.0
var _mine_prochain_spawn := 0.0
var _mine_boss_apparu := false

func _ready() -> void:
	add_to_group("salle")

func obstacles() -> Array[Rect2]:
	return _obstacles

func portail_ouvert() -> bool:
	return _portail_ouvert

func position_portail() -> Vector2:
	return Vector2(limites.get_center().x, limites.position.y + 180.0)

func demarrer(numero_: int, limites_: Rect2) -> void:
	numero = numero_
	limites = limites_
	_vagues = Vagues.pour_salle(numero, Jeu.chapitre, Jeu.graine, Jeu.mode_run)
	_vague_courante = -1
	_finie = false
	_portail_ouvert = false
	_portail = null
	_mine_active = false
	_mine_temps = 0.0
	_mine_prochain_spawn = 0.0
	_mine_boss_apparu = false
	_construire_obstacles()
	if Jeu.mode_run == "mine":
		_demarrer_mine()
		return
	if _vagues.is_empty():
		# Un alambic n'est pas une arene : la salle se termine aussitot et
		# l'orchestrateur ouvre le panneau.
		_finie = true
		terminee.emit()
		return
	_vague_suivante()

func _construire_obstacles() -> void:
	for enfant in get_children():
		if enfant is StaticBody2D:
			enfant.queue_free()
	_obstacles.clear()
	_construire_murs_perimetre()
	# Quelques blocs d'encre sechee, disposes selon le numero de salle : ils
	# arretent les projectiles et forcent a se replacer.
	var alea := RandomNumberGenerator.new()
	alea.seed = Jeu.graine * 31 + numero
	# Les blocs restent dans la bande mediane : trop bas, ils bouchent la ligne de
	# tir des le depart et le joueur ne comprend pas pourquoi rien ne touche.
	# Les motifs du boss supposent une arene ouverte. Un bloc protegerait le boss
	# de nos tirs tout en laissant le heros se cacher de ses barrages, ce qui
	# neutraliserait le combat ; la regle vaut pour chacun des trois boss.
	var combat_de_boss := Jeu.mode_run == "grimoire" and Chapitres.est_boss(Jeu.chapitre, numero) \
		or Jeu.mode_run in ["epreuve_sorts", "retro"]
	# Une seule pièce de décor jouable au maximum. Le décor de bord suffit à
	# donner de la richesse ; le centre doit rester une vraie zone d'esquive.
	var nombre := 0 if combat_de_boss else alea.randi_range(0, 1)
	for i in nombre:
		var taille_visuelle := Vector2(alea.randf_range(78.0, 138.0), alea.randf_range(44.0, 76.0))
		var taille := Vector2(taille_visuelle.x * 0.76, taille_visuelle.y * 0.42)
		var centre := Vector2(
			alea.randf_range(limites.position.x + taille_visuelle.x, limites.end.x - taille_visuelle.x),
			alea.randf_range(limites.position.y + 260.0, limites.end.y - 430.0))
		var rect := Rect2(centre - taille / 2.0, taille)
		_obstacles.append(rect)
		var corps := StaticBody2D.new()
		corps.collision_layer = 4
		corps.collision_mask = 0
		corps.global_position = centre
		var forme := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = taille
		forme.shape = rectangle
		corps.add_child(forme)
		add_child(corps)

func _construire_murs_perimetre() -> void:
	var e := Reglages.ARENE_MUR_EPAISSEUR
	var bandes := [
		Rect2(limites.position.x - e, limites.position.y - e, e, limites.size.y + e * 2.0),
		Rect2(limites.end.x, limites.position.y - e, e, limites.size.y + e * 2.0),
		Rect2(limites.position.x, limites.position.y - e, limites.size.x, e),
		Rect2(limites.position.x, limites.end.y, limites.size.x, e),
	]
	for rect in bandes:
		var corps := StaticBody2D.new()
		corps.name = "MurPerimetre"
		corps.collision_layer = 4
		corps.collision_mask = 0
		corps.global_position = (rect as Rect2).get_center()
		var forme := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = (rect as Rect2).size
		forme.shape = rectangle
		corps.add_child(forme)
		add_child(corps)

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()
	if _mine_active:
		_avancer_mine(delta)
		return
	if _attente_vague > 0.0:
		_attente_vague -= delta
		if _attente_vague <= 0.0:
			_vague_suivante()

func _demarrer_mine() -> void:
	_mine_active = true
	Jeu.temps_mine_restant = Reglages.MINE_DUREE
	# Quelques adversaires installent immediatement la boucle de combat, sans
	# transformer le depart en mur compact.
	for i in Reglages.MINE_PLAFOND_DEBUT:
		faire_apparaitre(Vagues.ennemi_mine(Jeu.rng, 0.0), _position_d_apparition())
	_mine_prochain_spawn = Reglages.MINE_INTERVALLE_DEBUT

func _avancer_mine(delta: float) -> void:
	if _mine_boss_apparu:
		return
	_mine_temps = minf(Reglages.MINE_DUREE, _mine_temps + delta)
	Jeu.temps_mine_restant = maxf(0.0, Reglages.MINE_DUREE - _mine_temps)
	var progression := clampf(_mine_temps / Reglages.MINE_DUREE, 0.0, 1.0)
	if _mine_temps >= Reglages.MINE_DUREE:
		# A 0:00, la horde cesse. Le boss obtient ensuite sa propre phase lisible,
		# des que les derniers survivants ont ete nettoyes.
		if get_tree().get_nodes_in_group("ennemis").is_empty():
			_apparaitre_boss_mine()
		return
	_mine_prochain_spawn -= delta
	if _mine_prochain_spawn > 0.0:
		return
	var plafond := _plafond_mine()
	if get_tree().get_nodes_in_group("ennemis").size() < plafond:
		faire_apparaitre(Vagues.ennemi_mine(Jeu.rng, progression), _position_d_apparition())
	_mine_prochain_spawn = lerpf(Reglages.MINE_INTERVALLE_DEBUT,
		Reglages.MINE_INTERVALLE_FIN, progression)

func _apparaitre_boss_mine() -> void:
	if _mine_boss_apparu:
		return
	_mine_boss_apparu = true
	Jeu.temps_mine_restant = 0.0
	var id := Vagues.boss_mine(Jeu.graine)
	faire_apparaitre(id,
		Vector2(limites.get_center().x, limites.position.y + 180.0))
	if Jeu.mode_auto:
		print("mine : boss final %s" % id)
	Sons.musique_boss()

func _vague_suivante() -> void:
	_vague_courante += 1
	if _vague_courante >= _vagues.size():
		_attente_vague = -1.0
		if get_tree().get_nodes_in_group("ennemis").is_empty():
			_ouvrir_portail()
		return
	for id in _vagues[_vague_courante]:
		faire_apparaitre(id, _position_d_apparition())
	_attente_vague = -1.0 if Jeu.est_retro() else (
		Reglages.DELAI_VAGUE_FORCE if _vague_courante < _vagues.size() - 1 else -1.0)

func _ouvrir_portail() -> void:
	if _finie or _portail_ouvert:
		return
	_portail_ouvert = true
	if Jeu.mode_auto:
		print("salle %d nettoyee : portail ouvert" % numero)
	_portail = Area2D.new()
	_portail.name = "PortailSortie"
	_portail.collision_layer = 0
	_portail.collision_mask = 1
	_portail.global_position = position_portail()
	var collision := CollisionShape2D.new()
	var cercle := CircleShape2D.new()
	cercle.radius = Reglages.PORTAIL_RAYON
	collision.shape = cercle
	_portail.add_child(collision)
	_portail.body_entered.connect(_sur_corps_dans_portail)
	add_child(_portail)
	if effets != null:
		effets.onde(position_portail(), 180.0, Palette.OR, 0.35)
	Sons.jouer("portail", -14.0, 1.1)
	queue_redraw()

func _sur_corps_dans_portail(corps: Node) -> void:
	if _finie or not corps.is_in_group("heros"):
		return
	_finie = true
	terminee.emit()

func faire_apparaitre(id: String, position: Vector2) -> void:
	var donnees: Dictionary = CatalogueEnnemis.par_id(id)
	if donnees.is_empty():
		push_error("Ennemi inconnu : " + id)
		return
	donnees = _mis_a_l_echelle(donnees, id)
	var noeud: Node2D
	if donnees["cerveau"] == "boss":
		noeud = BOSS.instantiate()
	else:
		noeud = ENNEMI.instantiate()
	noeud.configurer(donnees)
	noeud.limites = limites
	noeud.global_position = position
	noeud.mort.connect(_sur_mort_ennemi)
	noeud.tir_demande.connect(_sur_tir_ennemi)
	noeud.invocation_demandee.connect(_sur_invocation)
	noeud.touche.connect(_sur_ennemi_touche)
	add_child(noeud)
	if effets != null:
		effets.apparition(noeud.global_position, donnees["couleur"], donnees["rayon"],
			donnees["cerveau"] == "boss")

# La creature d'une salle avancee est plus lourde que celle d'une salle 5, et celle du
# troisieme chapitre plus que celle du premier. Le catalogue reste la reference :
# on n'y touche pas, on met a l'echelle une copie.
func _mis_a_l_echelle(donnees: Dictionary, id: String) -> Dictionary:
	var copie := donnees.duplicate(true)
	copie["id"] = id
	if Jeu.mode_run == "epreuve_sorts":
		var progression_defi := clampf(float(numero - 1) / 4.0, 0.0, 1.0)
		copie["pv"] = float(donnees["pv"]) * Reglages.DEFI_PV_BASE * pow(1.0 + Reglages.DEFI_MONTEE_PV, progression_defi)
		copie["degats"] = float(donnees["degats"]) * Reglages.DEFI_DEGATS_BASE * pow(1.0 + Reglages.DEFI_MONTEE_DEGATS, progression_defi)
	elif Jeu.mode_run == "mine":
		var progression_mine := clampf(_mine_temps / Reglages.MINE_DUREE, 0.0, 1.0)
		copie["pv"] = float(donnees["pv"]) * Reglages.MINE_PV_MULT \
			* pow(1.0 + Reglages.MINE_MONTEE_PV, progression_mine)
		copie["degats"] = float(donnees["degats"]) * Reglages.MINE_DEGATS_MULT \
			* pow(1.0 + Reglages.MINE_MONTEE_DEGATS, progression_mine)
		if donnees["cerveau"] == "boss":
			copie["pv"] *= Reglages.MINE_BOSS_PV_MULT
			copie["degats"] *= Reglages.MINE_BOSS_DEGATS_MULT
	elif Jeu.est_retro():
		copie["pv"] = float(donnees["pv"]) * Reglages.RETRO_PV_MULT
		copie["degats"] = float(donnees["degats"]) * Reglages.RETRO_DEGATS_MULT
	else:
		copie["pv"] = float(donnees["pv"]) * Chapitres.facteur_pv(Jeu.chapitre, numero)
		copie["degats"] = float(donnees["degats"]) * Chapitres.facteur_degats(Jeu.chapitre, numero)
	return copie

func _sur_ennemi_touche(position: Vector2, couleur: Color) -> void:
	if effets != null:
		effets.eclats(position, couleur.lightened(0.3), 3, 140.0, 0.5)

func _sur_mort_ennemi(qui: Node, position: Vector2, couleur: Color) -> void:
	Jeu.ennemis_abattus += 1
	ennemi_abattu.emit(int(qui.donnees.get("experience", 1)))
	if effets != null:
		effets.mort(position, couleur)
	# Le noeud mort est encore dans l'arbre a cet instant : on attend une frame
	# avant de compter, sinon la vague ne se termine jamais.
	await get_tree().process_frame
	if _finie or not is_inside_tree():
		return
	if Jeu.mode_run == "mine":
		if _mine_boss_apparu and get_tree().get_nodes_in_group("ennemis").is_empty():
			_mine_active = false
			_ouvrir_portail()
		elif not _mine_boss_apparu and _mine_temps >= Reglages.MINE_DUREE \
				and get_tree().get_nodes_in_group("ennemis").is_empty():
			_apparaitre_boss_mine()
		return
	if get_tree().get_nodes_in_group("ennemis").is_empty():
		if Jeu.mode_auto:
			print("derniere creature retiree salle %d vague %d/%d" % [numero,
				_vague_courante + 1, _vagues.size()])
		if _vague_courante < _vagues.size() - 1:
			_attente_vague = 0.0
			_vague_suivante()
		else:
			_ouvrir_portail()

func _sur_invocation(id: String, position: Vector2) -> void:
	if Jeu.mode_run == "mine" and _mine_temps >= Reglages.MINE_DUREE:
		return
	if Jeu.mode_run == "mine" and get_tree().get_nodes_in_group("ennemis").size() >= _plafond_mine():
		return
	var p := position
	p.x = clampf(p.x, limites.position.x, limites.end.x)
	p.y = clampf(p.y, limites.position.y, limites.end.y)
	if not _place_libre(p):
		p = _position_d_apparition()
	faire_apparaitre(id, p)

func _plafond_mine() -> int:
	var progression := clampf(_mine_temps / Reglages.MINE_DUREE, 0.0, 1.0)
	return roundi(lerpf(float(Reglages.MINE_PLAFOND_DEBUT),
		float(Reglages.MINE_PLAFOND_FIN), progression))

func _position_d_apparition() -> Vector2:
	var marge := 120.0
	if Jeu.mode_run == "mine":
		var cote := Jeu.rng.randi_range(0, 3)
		match cote:
			0: return Vector2(Jeu.rng.randf_range(limites.position.x + marge, limites.end.x - marge), limites.position.y + marge)
			1: return Vector2(Jeu.rng.randf_range(limites.position.x + marge, limites.end.x - marge), limites.end.y - marge)
			2: return Vector2(limites.position.x + marge, Jeu.rng.randf_range(limites.position.y + marge, limites.end.y - marge))
			_: return Vector2(limites.end.x - marge, Jeu.rng.randf_range(limites.position.y + marge, limites.end.y - marge))
	var candidate := Vector2.ZERO
	# Un ennemi apparu dans un bloc d'encre est intouchable : les projectiles
	# heurtent le bloc avant lui, et la salle ne se vide jamais.
	for essai in 12:
		candidate = Vector2(
			Jeu.rng.randf_range(limites.position.x + marge, limites.end.x - marge),
			Jeu.rng.randf_range(limites.position.y + marge, limites.position.y + limites.size.y * 0.45))
		if _place_libre(candidate):
			return candidate
	return candidate

func _place_libre(position: Vector2) -> bool:
	for rect in _obstacles:
		if rect.grow(70.0).has_point(position):
			return false
	return true

func tirer(tir_source: Tir, origine: Vector2, direction: Vector2, hostile := false,
		cible_exclue := 0) -> void:
	var angles := tir_source.angles()
	var decalages := tir_source.decalages()
	for i in angles.size():
		var p := PROJECTILE.instantiate()
		p.tir = tir_source
		p.hostile = hostile
		p.cible_exclue = cible_exclue
		p.direction = direction.rotated(angles[i])
		p.global_position = origine + direction.orthogonal() * decalages[i]
		p.fragments_demandes.connect(_sur_fragments)
		p.impact_visuel.connect(_sur_impact)
		p.soin_demande.connect(_sur_soin_demande)
		add_child(p)

func _sur_tir_ennemi(tir_ennemi: Tir, origine: Vector2, direction: Vector2) -> void:
	tirer(tir_ennemi, origine, direction, true)

func _sur_impact(position: Vector2, couleur: Color, ampleur: float) -> void:
	if effets != null:
		effets.impact(position, couleur, ampleur)

func _sur_soin_demande(montant: float) -> void:
	var heros := get_tree().get_first_node_in_group("heros")
	if heros != null:
		heros.stats.soigner(montant)

func _sur_fragments(origine: Vector2, direction: Vector2, tir_source: Tir, hostile: bool,
		cible_exclue: int) -> void:
	# Un fragment ne se refragmente pas : sinon un seul tir peut saturer la scene.
	var eclat := tir_source.copie()
	eclat.fragments = 0
	eclat.rebonds = 0
	eclat.perforations = 0
	eclat.nb_projectiles = 1
	eclat.angle_eventail = 0.0
	eclat.degats = tir_source.degats * Reglages.FRAGMENT_PART_DEGATS
	eclat.portee = Reglages.FRAGMENT_PORTEE
	# Le signal part d'un contact physique : ajouter des Area2D pendant que le
	# moteur vide ses collisions produit une erreur et une saccade visible.
	call_deferred("_tirer_fragments", eclat, tir_source.fragments, origine, direction, hostile,
		cible_exclue)

func _tirer_fragments(eclat: Tir, nombre: int, origine: Vector2, direction: Vector2, hostile: bool,
		cible_exclue: int) -> void:
	if not is_inside_tree():
		return
	for i in nombre:
		var angle := TAU * float(i) / float(nombre) + randf() * 0.3
		tirer(eclat, origine, direction.rotated(angle), hostile, cible_exclue)

func _draw() -> void:
	# Le fond de l'arene est dessine par le noeud Fond ; ici on ne dessine que ce
	# qui doit passer par-dessus.
	for index in _obstacles.size():
		var rect: Rect2 = _obstacles[index]
		_dessiner_obstacle_peint(rect, (numero + index) % 3)
	if _portail_ouvert:
		_dessiner_portail()

func _dessiner_portail() -> void:
	var centre := position_portail()
	var pulsation := 1.0 + sin(_anim * 3.6) * 0.025
	Dessin.halo(self, centre + Vector2(0, -18), 165.0 * pulsation, Color(Palette.ESSENCE, 0.58), 7)
	var taille := Vector2(350, 350) * pulsation
	var destination := Rect2(centre + Vector2(-taille.x * 0.5, -taille.y * 0.55), taille)
	draw_texture_rect(PORTAIL_PREMIUM, destination, false)
	for i in 8:
		var a := _anim * (0.55 + i * 0.025) + float(i) * TAU / 8.0
		var p := centre + Vector2(cos(a) * 112.0, sin(a) * 92.0 - 22.0)
		draw_circle(Retro16.pixel(p), 3.0 + float(i % 2) * 2.0, Color(Palette.TEXTE, 0.72))
	var police := ThemeDB.fallback_font
	draw_string(police, centre + Vector2(-105, 158), "SORTIE", HORIZONTAL_ALIGNMENT_CENTER, 210, 23, Palette.TEXTE)

func _dessiner_obstacle_peint(rect: Rect2, type: int) -> void:
	var source: Rect2 = RECTS_OBSTACLES[type]
	# L'image depasse legerement la collision vers le haut, comme un vrai objet
	# vu en trois-quarts, mais sa base correspond exactement a l'obstacle.
	var largeur := rect.size.x / 0.76 * 1.08
	var hauteur := largeur * source.size.y / source.size.x
	var destination := Rect2(rect.get_center().x - largeur * 0.5,
		rect.end.y - hauteur, largeur, hauteur)
	draw_texture_rect_region(PLANCHE_OBSTACLES, destination, source)
