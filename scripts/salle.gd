extends Node2D

# Une salle est une page du grimoire : arene fermee, deux ou trois vagues,
# puis une porte. Les compositions sont des donnees (data/vagues.gd), jamais
# du code.

signal terminee
signal ennemi_abattu

const PROJECTILE := preload("res://scenes/projectile.tscn")
const ENNEMI := preload("res://scenes/ennemi.tscn")
const BOSS := preload("res://scenes/boss.tscn")
const PORTE_DISTANCE_MARCHE := 110.0
const PORTE_DISTANCE_APPUI := 165.0

var effets: Node2D
var zones: Node2D
var limites := Rect2()
var numero := 1

var _vagues: Array = []
var _vague_courante := -1
var _porte_ouverte := false
var _porte_position := Vector2.ZERO
var _finie := false
var _obstacles: Array[Rect2] = []
var _anim := 0.0
var _attente_vague := 0.0

func _ready() -> void:
	add_to_group("salle")

func position_de_la_porte() -> Vector2:
	return _porte_position

func obstacles() -> Array[Rect2]:
	return _obstacles

func demarrer(numero_: int, limites_: Rect2) -> void:
	numero = numero_
	limites = limites_
	_porte_position = Vector2((limites.position.x + limites.end.x) / 2.0, limites.position.y - 70.0)
	_vagues = Vagues.pour_salle(numero, Jeu.chapitre, Jeu.graine, Jeu.mode_run)
	_vague_courante = -1
	_porte_ouverte = false
	_finie = false
	_construire_obstacles()
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
		or (Jeu.mode_run == "epreuve_sorts" and numero % 4 == 0)
	var nombre := 0 if combat_de_boss else alea.randi_range(0, 2)
	for i in nombre:
		var taille := Vector2(alea.randf_range(90.0, 200.0), alea.randf_range(50.0, 110.0))
		var centre := Vector2(
			alea.randf_range(limites.position.x + taille.x, limites.end.x - taille.x),
			alea.randf_range(limites.position.y + 300.0, limites.end.y - 520.0))
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

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()
	if _attente_vague > 0.0:
		_attente_vague -= delta
		if _attente_vague <= 0.0:
			_vague_suivante()
	if not _porte_ouverte or _finie:
		return
	var heros := get_tree().get_first_node_in_group("heros")
	if heros != null and heros.global_position.distance_to(_porte_position) < PORTE_DISTANCE_MARCHE:
		_franchir_porte()

func _unhandled_input(evenement: InputEvent) -> void:
	if not _porte_ouverte or _finie:
		return
	var position_appui := Vector2.ZERO
	var appui := false
	if evenement is InputEventScreenTouch:
		appui = (evenement as InputEventScreenTouch).pressed
		position_appui = (evenement as InputEventScreenTouch).position
	elif evenement is InputEventMouseButton:
		var souris := evenement as InputEventMouseButton
		appui = souris.pressed and souris.button_index == MOUSE_BUTTON_LEFT
		position_appui = souris.position
	var fleche := Vector2(_porte_position.x, limites.position.y + 118.0)
	if appui and (position_appui.distance_to(_porte_position) <= PORTE_DISTANCE_APPUI \
			or position_appui.distance_to(fleche) <= PORTE_DISTANCE_APPUI):
		get_viewport().set_input_as_handled()
		_franchir_porte()

func _franchir_porte() -> void:
	if _finie or not _porte_ouverte:
		return
	_finie = true
	Sons.jouer("porte", -12.0)
	terminee.emit()

func _vague_suivante() -> void:
	_vague_courante += 1
	if _vague_courante >= _vagues.size():
		_ouvrir_la_porte()
		return
	for id in _vagues[_vague_courante]:
		faire_apparaitre(id, _position_d_apparition())

func _ouvrir_la_porte() -> void:
	_porte_ouverte = true
	Sons.jouer("porte", -16.0, 1.2)
	if effets != null:
		effets.onde(_porte_position, 180.0, Palette.OR, 0.8)

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
		effets.onde(position, donnees["rayon"] * 2.5, donnees["couleur"], 0.5)

# La creature d'une page 45 est plus lourde que celle d'une page 5, et celle du
# troisieme chapitre plus que celle du premier. Le catalogue reste la reference :
# on n'y touche pas, on met a l'echelle une copie.
func _mis_a_l_echelle(donnees: Dictionary, _id: String) -> Dictionary:
	var copie := donnees.duplicate(true)
	if Jeu.mode_run == "epreuve_sorts":
		var progression_defi := clampf(float(numero - 1) / 11.0, 0.0, 1.0)
		copie["pv"] = float(donnees["pv"]) * Reglages.DEFI_PV_BASE * pow(1.0 + Reglages.DEFI_MONTEE_PV, progression_defi)
		copie["degats"] = float(donnees["degats"]) * Reglages.DEFI_DEGATS_BASE * pow(1.0 + Reglages.DEFI_MONTEE_DEGATS, progression_defi)
	else:
		copie["pv"] = float(donnees["pv"]) * Chapitres.facteur_pv(Jeu.chapitre, numero)
		copie["degats"] = float(donnees["degats"]) * Chapitres.facteur_degats(Jeu.chapitre, numero)
	return copie

func _sur_ennemi_touche(position: Vector2, couleur: Color) -> void:
	if effets != null:
		effets.eclats(position, couleur.lightened(0.3), 3, 140.0, 0.5)

func _sur_mort_ennemi(qui: Node, position: Vector2, couleur: Color) -> void:
	Jeu.ennemis_abattus += 1
	# Les éliminations ne sont plus une monnaie ni une jauge cachée : la
	# récompense arrive une fois, clairement, à la fin de chaque étage.
	ennemi_abattu.emit()
	if effets != null:
		effets.mort(position, couleur)
	# Le noeud mort est encore dans l'arbre a cet instant : on attend une frame
	# avant de compter, sinon la vague ne se termine jamais.
	await get_tree().process_frame
	if _finie or not is_inside_tree():
		return
	if get_tree().get_nodes_in_group("ennemis").is_empty() and _attente_vague <= 0.0:
		_attente_vague = Reglages.DELAI_ENTRE_VAGUES

func _sur_invocation(id: String, position: Vector2) -> void:
	var p := position
	p.x = clampf(p.x, limites.position.x, limites.end.x)
	p.y = clampf(p.y, limites.position.y, limites.end.y)
	if not _place_libre(p):
		p = _position_d_apparition()
	faire_apparaitre(id, p)

func _position_d_apparition() -> Vector2:
	var marge := 120.0
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

func tirer(tir_source: Tir, origine: Vector2, direction: Vector2, hostile := false) -> void:
	var angles := tir_source.angles()
	var decalages := tir_source.decalages()
	for i in angles.size():
		var p := PROJECTILE.instantiate()
		p.tir = tir_source
		p.hostile = hostile
		p.direction = direction.rotated(angles[i])
		p.global_position = origine + direction.orthogonal() * decalages[i]
		p.fragments_demandes.connect(_sur_fragments)
		p.chaine_demandee.connect(_sur_chaine)
		p.zone_demandee.connect(_sur_zone)
		p.impact_visuel.connect(_sur_impact)
		add_child(p)

func _sur_tir_ennemi(tir_ennemi: Tir, origine: Vector2, direction: Vector2) -> void:
	tirer(tir_ennemi, origine, direction, true)

func _sur_impact(position: Vector2, couleur: Color, ampleur: float) -> void:
	if effets != null:
		effets.impact(position, couleur, ampleur)

func _sur_zone(position: Vector2, genre: String) -> void:
	if zones != null:
		zones.ajouter(position, genre)

func _sur_fragments(origine: Vector2, direction: Vector2, tir_source: Tir, hostile: bool) -> void:
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
	call_deferred("_tirer_fragments", eclat, tir_source.fragments, origine, direction, hostile)

func _tirer_fragments(eclat: Tir, nombre: int, origine: Vector2, direction: Vector2, hostile: bool) -> void:
	if not is_inside_tree():
		return
	for i in nombre:
		var angle := TAU * float(i) / float(nombre) + randf() * 0.3
		tirer(eclat, origine, direction.rotated(angle), hostile)

func _sur_chaine(depuis: Vector2, cible: Node, tir_source: Tir) -> void:
	var portee := Reglages.FOUDRE_PORTEE_CHAINE
	if "chaine_longue" in tir_source.drapeaux:
		portee *= 2.0
	var positions: Array[Vector2] = []
	var noeuds: Array[Node] = []
	for noeud in get_tree().get_nodes_in_group("ennemis"):
		if not is_instance_valid(noeud) or noeud == cible:
			continue
		if noeud.global_position.distance_to(depuis) > portee:
			continue
		noeuds.append(noeud)
		positions.append(noeud.global_position)
	var index := Ciblage.plus_proche(depuis, positions)
	if index == -1:
		return
	var voisin := noeuds[index]
	var effets_chaine: Array[String] = ["foudre"]
	if "acide" in tir_source.effets:
		effets_chaine.append("acide")
	voisin.recevoir_degats(tir_source.degats * Reglages.FOUDRE_PART_DEGATS, effets_chaine)
	if effets != null:
		effets.eclair(depuis, voisin.global_position)

func _draw() -> void:
	# Le fond de page est dessine par le noeud Fond, sous les zones au sol ;
	# ici on ne dessine que ce qui doit passer par-dessus.
	for index in _obstacles.size():
		var rect: Rect2 = _obstacles[index]
		match (numero + index) % 3:
			0: _dessiner_muret(rect)
			1: _dessiner_bosquet(rect, index)
			_: _dessiner_rochers(rect, index)

	if _porte_ouverte and not _finie:
		var pulsation := 0.6 + 0.4 * sin(_anim * 3.0)
		var fleche := Vector2(_porte_position.x, limites.position.y + 118.0)
		Dessin.halo(self, fleche, 150.0 * pulsation, Palette.OR, 5)
		var arc := Dessin.polygone_regulier(fleche, 74.0, 8, _anim * 0.5)
		Dessin.contour(self, arc, Color(Palette.OR, 0.9), 4.0)
		draw_colored_polygon(Dessin.polygone_regulier(fleche, 52.0, 8, -_anim * 0.7),
			Color(Palette.OR, 0.25))
		# Flèche vers le haut : toute la forme et son halo constituent la cible
		# tactile, pas seulement quelques pixels du glyphe.
		var pointe := PackedVector2Array([
			fleche + Vector2(0.0, -48.0), fleche + Vector2(42.0, -4.0),
			fleche + Vector2(18.0, -4.0), fleche + Vector2(18.0, 42.0),
			fleche + Vector2(-18.0, 42.0), fleche + Vector2(-18.0, -4.0),
			fleche + Vector2(-42.0, -4.0)])
		draw_colored_polygon(pointe, Color(Palette.OR, 0.92))
		var police := ThemeDB.fallback_font
		draw_string(police, fleche + Vector2(-180, 120), "TOUCHER — PAGE SUIVANTE",
			HORIZONTAL_ALIGNMENT_CENTER, 360, 29, Color(Palette.TEXTE, 0.90))

func _dessiner_muret(rect: Rect2) -> void:
	draw_rect(rect.grow(7.0), Color(0.05, 0.07, 0.08, 0.24))
	var hauteur_pierre := maxf(22.0, rect.size.y / 3.0)
	var lignes := ceili(rect.size.y / hauteur_pierre)
	for ligne in lignes:
		var decalage := 22.0 if ligne % 2 == 1 else 0.0
		var largeur_pierre := 52.0
		var colonnes := ceili((rect.size.x + decalage) / largeur_pierre)
		for colonne in colonnes:
			var pierre := Rect2(rect.position + Vector2(float(colonne) * largeur_pierre - decalage,
				float(ligne) * hauteur_pierre), Vector2(largeur_pierre - 3.0, hauteur_pierre - 3.0)).intersection(rect)
			var variation := float((colonne + ligne * 3 + numero) % 4) * 0.025
			draw_rect(pierre, Color(0.38 + variation, 0.43 + variation, 0.40 + variation))
			draw_rect(pierre, Color(0.68, 0.76, 0.68, 0.72), false, 2.0)
	draw_line(rect.position + Vector2(0.0, 3.0), Vector2(rect.end.x, rect.position.y + 3.0),
		Color(Palette.MOUSSE_MAGIQUE, 0.85), 5.0)

func _dessiner_bosquet(rect: Rect2, graine: int) -> void:
	var centre := rect.get_center()
	draw_colored_polygon(Dessin.blob(centre, maxf(rect.size.x, rect.size.y) * 0.53,
		numero * 41 + graine, 0.18), Color(Palette.MOUSSE_MAGIQUE, 0.30))
	var arbres := maxi(3, ceili(rect.size.x / 54.0))
	for i in arbres:
		var part := (float(i) + 0.5) / float(arbres)
		var x := lerpf(rect.position.x + 18.0, rect.end.x - 18.0, part)
		var y := rect.get_center().y + sin(float(i * 5 + graine)) * rect.size.y * 0.16
		var tronc := Rect2(Vector2(x - 7.0, y - 2.0), Vector2(14.0, rect.end.y - y + 4.0))
		draw_rect(tronc, Color(0.38, 0.24, 0.16))
		draw_circle(Vector2(x + 3.0, y + 2.0), 30.0, Color(0.16, 0.42, 0.25))
		draw_circle(Vector2(x - 9.0, y - 10.0), 24.0, Color(0.25, 0.58, 0.32))
		draw_circle(Vector2(x + 10.0, y - 12.0), 19.0, Color(0.42, 0.72, 0.38))
		draw_circle(Vector2(x + 13.0, y - 17.0), 4.0, Color(Palette.OR, 0.82))

func _dessiner_rochers(rect: Rect2, graine: int) -> void:
	draw_colored_polygon(Dessin.blob(rect.get_center() + Vector2(0.0, 8.0), rect.size.x * 0.52,
		numero * 59 + graine, 0.16), Color(0.08, 0.10, 0.12, 0.24))
	var rochers := maxi(3, ceili(rect.size.x / 58.0))
	for i in rochers:
		var part := (float(i) + 0.5) / float(rochers)
		var position := Vector2(lerpf(rect.position.x + 16.0, rect.end.x - 16.0, part),
			rect.get_center().y + sin(float(i * 7 + graine)) * rect.size.y * 0.12)
		var rayon := minf(rect.size.y * 0.48, 31.0 + float((i + graine) % 3) * 7.0)
		var roche := Dessin.blob(position, rayon, numero * 73 + i + graine, 0.14)
		draw_colored_polygon(roche, Color(0.34, 0.40, 0.46))
		Dessin.contour(self, roche, Color(0.62, 0.70, 0.76), 2.5)
		var cristal := Dessin.polygone_regulier(position + Vector2(rayon * 0.28, -rayon * 0.35), rayon * 0.22, 5, -PI / 2.0)
		draw_colored_polygon(cristal, Color(Palette.ESSENCE, 0.82))
