extends Node2D

# Retours visuels ephemeres : impacts, eclats, eclairs, textes. Un seul noeud
# les dessine tous, ce qui evite de creer et detruire des dizaines de scenes
# par seconde sur un telephone.

const GRAVITE := 220.0

var _particules: Array[Dictionary] = []
var _eclairs: Array[Dictionary] = []
var _ondes: Array[Dictionary] = []
var _textes: Array[Dictionary] = []

func _process(delta: float) -> void:
	# On itere a rebours : la liste se vide pendant qu'on la parcourt.
	for i in range(_particules.size() - 1, -1, -1):
		var p := _particules[i]
		p["vie"] -= delta
		if p["vie"] <= 0.0:
			_particules.remove_at(i)
			continue
		p["vitesse"] = p["vitesse"] * (1.0 - 2.2 * delta) + Vector2(0, GRAVITE * delta * p["poids"])
		p["position"] += p["vitesse"] * delta
	for liste in [_eclairs, _ondes, _textes]:
		for i in range(liste.size() - 1, -1, -1):
			liste[i]["vie"] -= delta
			if liste[i]["vie"] <= 0.0:
				liste.remove_at(i)
	for t in _textes:
		t["position"] += Vector2(0, -60.0 * delta)
	queue_redraw()

func eclats(position: Vector2, couleur: Color, nombre := 8, force := 260.0, poids := 1.0) -> void:
	if ReglagesJoueur.effets_reduits:
		nombre = maxi(2, ceili(float(nombre) * 0.45))
	for i in nombre:
		var angle := randf() * TAU
		_particules.append({
			"position": position,
			"vitesse": Vector2(cos(angle), sin(angle)) * force * randf_range(0.35, 1.0),
			"vie": randf_range(0.25, 0.55),
			"vie_max": 0.55,
			"taille": randf_range(3.0, 7.0),
			"couleur": couleur,
			"poids": poids,
		})

func impact(position: Vector2, couleur: Color, ampleur := 1.0) -> void:
	eclats(position, couleur, int(5 * ampleur) + 3, 240.0 * ampleur, 0.6)
	_ondes.append({"position": position, "vie": 0.22, "vie_max": 0.22,
		"rayon": 22.0 * ampleur, "couleur": couleur})

func mort(position: Vector2, couleur: Color) -> void:
	eclats(position, couleur, 18, 340.0, 1.0)
	eclats(position, couleur.lightened(0.4), 8, 180.0, 0.4)
	_ondes.append({"position": position, "vie": 0.4, "vie_max": 0.4, "rayon": 70.0, "couleur": couleur})

func onde(position: Vector2, rayon: float, couleur: Color, duree := 0.45) -> void:
	_ondes.append({"position": position, "vie": duree, "vie_max": duree, "rayon": rayon, "couleur": couleur})

func eclair(depuis: Vector2, vers: Vector2, couleur := Palette.FOUDRE) -> void:
	_eclairs.append({"points": Dessin.eclair(depuis, vers, 26.0, randi()),
		"vie": 0.18, "vie_max": 0.18, "couleur": couleur})

func texte(position: Vector2, contenu: String, couleur := Palette.TEXTE) -> void:
	_textes.append({"position": position, "contenu": contenu, "vie": 0.9, "vie_max": 0.9, "couleur": couleur})

func _draw() -> void:
	for o in _ondes:
		var t: float = 1.0 - o["vie"] / o["vie_max"]
		var c: Color = o["couleur"]
		c.a = (1.0 - t) * 0.7
		draw_arc(o["position"], o["rayon"] * (0.3 + t), 0.0, TAU, 24, c, 4.0 * (1.0 - t) + 1.0, true)
	for e in _eclairs:
		var t: float = e["vie"] / e["vie_max"]
		var c: Color = e["couleur"]
		c.a = t
		draw_polyline(e["points"], c, 5.0 * t + 1.0, true)
		draw_polyline(e["points"], Color(1, 1, 1, t * 0.8), 2.0, true)
	for p in _particules:
		var t: float = clampf(p["vie"] / p["vie_max"], 0.0, 1.0)
		var c: Color = p["couleur"]
		c.a = t
		draw_circle(p["position"], p["taille"] * t, c)
	var police := ThemeDB.fallback_font
	for t in _textes:
		var f: float = t["vie"] / t["vie_max"]
		var c: Color = t["couleur"]
		c.a = f
		draw_string(police, t["position"], t["contenu"], HORIZONTAL_ALIGNMENT_CENTER, -1, 34, c)
