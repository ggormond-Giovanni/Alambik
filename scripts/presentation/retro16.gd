class_name Retro16
extends RefCounted

# Pont unique entre le moteur et les planches peintes. Le gameplay continue
# d'appeler les memes fonctions, mais aucune creature n'est reconstruite avec
# des rectangles : les silhouettes viennent des assets de production.

const PAS := 4.0
const ENCRE := Color("17234a")
const OMBRE := Color("303d72")
const PAPIER := Color("fff0bd")
const OR := Color("ffb52e")
const ROSE := Color("ef476f")
const CYAN := Color("42d9c8")
const VIOLET := Color("aa86ff")
const VERT := Color("65d47b")
const BLEU_NUIT := Color("28526b")

const FOND_MENU := preload("res://assets/visual/menu_vallee_alambics.png")
# menu_premium_v3_classique.png et menu_premium_v3_adaptatif.png restent dans le
# depot : repointer cette constante suffit a revenir a une ancienne peinture
# d'accueil. Elles ne sont plus prechargees, une seule composition servant
# desormais toutes les proportions d'ecran.
const MENU_PREMIUM_CLASSIQUE := preload("res://assets/visual/menu_futur.png")
const HEROS_MENU_PREMIUM := preload("res://assets/visual/heros_menu_premium.png")
const FOND_INTERFACE := preload("res://assets/visual/fond_interface_scriptorium.png")
const ICONES_INTERFACE := preload("res://assets/visual/icones_interface_normalisees.png")
const PLANCHE_HEROS := preload("res://assets/visual/hero_alchimiste.png")
const PLANCHE_ENNEMIS := preload("res://assets/visual/ennemis.png")
const PLANCHE_MINIBOSS := preload("res://assets/visual/miniboss.png")
const PLANCHE_BOSS := preload("res://assets/visual/boss.png")
const PLANCHE_PROJECTILE := preload("res://assets/visual/projectile.png")

const RECTS_HEROS := [
	Rect2(57, 176, 257, 391), Rect2(314, 178, 313, 389),
	Rect2(627, 178, 301, 392), Rect2(964, 178, 270, 392),
	Rect2(20, 662, 294, 372), Rect2(314, 665, 313, 369),
	Rect2(627, 683, 313, 366), Rect2(940, 766, 277, 310),
]

const IDS_ENNEMIS := [
	"encrier_rampant", "plume_sentinelle", "tache_veloce", "scribe_essaimeur",
	"folio_orbiteur", "sceau_belier", "marge_harceleuse", "miroir_encre",
	"cachet_phaseur", "fuseau_tisseur", "fiole_volatile",
]
const RECTS_ENNEMIS := [
	Rect2(66, 134, 207, 245), Rect2(373, 59, 209, 340),
	Rect2(660, 134, 227, 260), Rect2(944, 83, 254, 302),
	Rect2(25, 468, 274, 368), Rect2(341, 503, 259, 333),
	Rect2(661, 488, 211, 234), Rect2(952, 440, 187, 310),
	Rect2(42, 836, 249, 277), Rect2(370, 836, 162, 282),
	Rect2(644, 843, 203, 275),
]

const RECTS_MINIBOSS := [
	Rect2(21, 177, 230, 368), Rect2(251, 203, 251, 318),
	Rect2(502, 191, 248, 335), Rect2(758, 197, 245, 343),
	Rect2(1003, 218, 230, 290), Rect2(12, 677, 239, 342),
	Rect2(251, 673, 251, 344), Rect2(502, 688, 250, 333),
	Rect2(752, 694, 251, 326), Rect2(1003, 703, 236, 315),
]

const RECTS_BOSS := [
	Rect2(19, 177, 232, 381), Rect2(251, 181, 251, 374),
	Rect2(502, 163, 250, 391), Rect2(752, 193, 251, 365),
	Rect2(1003, 191, 238, 367), Rect2(17, 657, 234, 396),
	Rect2(251, 670, 251, 381), Rect2(502, 673, 250, 378),
	Rect2(752, 673, 251, 378), Rect2(1003, 671, 235, 380),
]

const RECTS_PROJECTILE := [
	Rect2(63, 326, 222, 221), Rect2(360, 325, 225, 220),
	Rect2(660, 323, 224, 226), Rect2(963, 321, 228, 222),
	Rect2(64, 702, 220, 223), Rect2(359, 701, 226, 225),
	Rect2(659, 701, 226, 225), Rect2(963, 697, 228, 229),
]

static func pixel(position: Vector2) -> Vector2:
	return (position / PAS).round() * PAS

static func rectangle(canvas: CanvasItem, rect: Rect2, couleur: Color) -> void:
	var position := pixel(rect.position)
	var taille := (rect.size / PAS).round() * PAS
	canvas.draw_rect(Rect2(position, taille), couleur)

static func contour_rectangle(canvas: CanvasItem, rect: Rect2, fond: Color,
		bord: Color, epaisseur := 4.0) -> void:
	rectangle(canvas, rect, bord)
	rectangle(canvas, rect.grow(-epaisseur), fond)

static func polygone(canvas: CanvasItem, points: Array[Vector2], couleur: Color) -> void:
	var ajustes := PackedVector2Array()
	for point in points:
		ajustes.append(pixel(point))
	canvas.draw_colored_polygon(ajustes, couleur)

static func dessiner_fond_interface(canvas: CanvasItem, taille: Vector2,
		accent: Color, temps := 0.0, opacite := 1.0) -> void:
	FondAdaptatif.dessiner_premium(canvas, FOND_INTERFACE, taille, 500.0, 420.0, opacite)
	# Deux voiles continus reservent du contraste au bandeau et a la navigation,
	# sans casser la peinture en bandes visibles.
	canvas.draw_rect(Rect2(0.0, 0.0, taille.x, taille.y * 0.16),
		Color(0.018, 0.035, 0.090, 0.24 * opacite))
	canvas.draw_rect(Rect2(0.0, taille.y * 0.78, taille.x, taille.y * 0.22),
		Color(0.012, 0.025, 0.070, 0.20 * opacite))
	for etoile in 18:
		var p := Vector2(fmod(float(etoile * 173), taille.x),
			fmod(float(etoile * 101), taille.y * 0.72))
		var pulse := 0.22 + 0.16 * sin(temps * 1.7 + etoile)
		canvas.draw_circle(p, 2.0 + float(etoile % 3), Color(accent, pulse * opacite))
	dessiner_coins(canvas, taille, Color(accent, 0.44 * opacite), 18.0)

static func dessiner_fond_accueil(canvas: CanvasItem, taille: Vector2,
		temps := 0.0, opacite := 1.0) -> void:
	FondAdaptatif.dessiner(canvas, FOND_MENU, taille, 620.0, 430.0,
		Color(1.0, 1.0, 1.0, opacite))
	canvas.draw_rect(Rect2(0.0, 0.0, taille.x, taille.y * 0.15),
		Color(0.012, 0.025, 0.070, 0.35 * opacite))
	canvas.draw_rect(Rect2(0.0, taille.y * 0.76, taille.x, taille.y * 0.24),
		Color(0.008, 0.018, 0.050, 0.38 * opacite))
	for index in 12:
		var p := Vector2(fmod(float(index * 197 + 63), taille.x),
			fmod(float(index * 137 + 210), taille.y * 0.72))
		canvas.draw_circle(p, 2.0 + float(index % 2) * 2.0,
			Color(CYAN.lerp(VIOLET, float(index % 3) * 0.34),
			(0.20 + 0.14 * sin(temps * 1.8 + index)) * opacite))

# Chassis et bandes fixes de la peinture d'accueil. Une seule source pour le
# dessin ET pour le placement des zones : sans cela, les libelles flottaient
# au-dessus de leur plaque des que l'ecran changeait de proportions.
const MENU_HAUT_FIXE := 1040.0
const MENU_BAS_FIXE := 650.0

# Repere de la peinture (reference 1080 de large) vers l'ecran reel.
static func rect_menu(taille: Vector2, reference: Rect2) -> Rect2:
	return FondAdaptatif.rect(taille, texture_menu(taille), reference,
		MENU_HAUT_FIXE, MENU_BAS_FIXE)

static func dessiner_menu_premium(canvas: CanvasItem, taille: Vector2,
		temps := 0.0, opacite := 1.0) -> void:
	var texture := texture_menu(taille)
	var haut_fixe := MENU_HAUT_FIXE
	var bas_fixe := MENU_BAS_FIXE
	FondAdaptatif.dessiner(canvas, texture, taille, haut_fixe, bas_fixe,
		Color(1.0, 1.0, 1.0, opacite))
	# Le personnage est un calque distinct : une respiration tres legere suffit
	# a donner vie a l'accueil sans transformer le menu en animation agitee.
	var souffle := sin(temps * 1.75)
	var centre_plateforme := FondAdaptatif.point(taille, texture,
		Vector2(540.0, 1025.0), haut_fixe, bas_fixe)
	var centre := centre_plateforme + Vector2(0.0, souffle * 1.8)
	var dimensions := Vector2(taille.x * 0.47, taille.x * 0.59)
	var echelle := Vector2(1.0 + souffle * 0.003, 1.0 + souffle * 0.007)
	canvas.draw_set_transform(centre, 0.0, echelle)
	canvas.draw_texture_rect(HEROS_MENU_PREMIUM,
		Rect2(-dimensions * 0.5, dimensions), false,
		Color(1.0, 1.0, 1.0, opacite))
	canvas.draw_set_transform(Vector2.ZERO)

# Une seule peinture d'accueil, quelle que soit la proportion de l'ecran : sa
# bande centrale absorbe la hauteur supplementaire. Deux compositions
# demandaient deux jeux de reperes, donc deux occasions de les desaccorder.
static func texture_menu(_taille: Vector2) -> Texture2D:
	return MENU_PREMIUM_CLASSIQUE

static func icone_interface(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONES_INTERFACE
	atlas.region = Rect2(float(posmod(index, 5) * 256), float(posmod(index / 5, 3) * 256), 256.0, 256.0)
	return atlas

static func dessiner_icone_interface(canvas: CanvasItem, index: int, rect: Rect2,
		modulation := Color.WHITE) -> void:
	var source := Rect2(float(posmod(index, 5) * 256), float(posmod(index / 5, 3) * 256), 256.0, 256.0)
	canvas.draw_texture_rect_region(ICONES_INTERFACE, rect, source, modulation, false, true)

static func dessiner_coins(canvas: CanvasItem, taille: Vector2, couleur: Color,
		marge := 10.0) -> void:
	for coin in [Vector2(marge, marge), Vector2(taille.x - marge, marge),
			Vector2(marge, taille.y - marge), Vector2(taille.x - marge, taille.y - marge)]:
		var sx := 1.0 if coin.x < taille.x * 0.5 else -1.0
		var sy := 1.0 if coin.y < taille.y * 0.5 else -1.0
		rectangle(canvas, Rect2(coin, Vector2(sx * 38.0, sy * 4.0)), couleur)
		rectangle(canvas, Rect2(coin, Vector2(sx * 4.0, sy * 38.0)), couleur)

static func _sprite_ancre_bas(canvas: CanvasItem, texture: Texture2D, source: Rect2,
		hauteur: float, pied_y: float, modulation := Color.WHITE) -> void:
	var largeur := hauteur * source.size.x / source.size.y
	var destination := Rect2(-largeur * 0.5, pied_y - hauteur, largeur, hauteur)
	canvas.draw_texture_rect_region(texture, destination, source, modulation, false, true)

static func dessiner_heros(canvas: CanvasItem, anim: float, attaque: bool,
		_direction: Vector2, _teinte: Color) -> void:
	var frame := 4 + int(anim * 8.0) % 2 if attaque else int(anim * 5.0) % 4
	var bob := sin(anim * 6.0) * 2.0
	_sprite_ancre_bas(canvas, PLANCHE_HEROS, RECTS_HEROS[frame],
		150.0 * Reglages.ECHELLE_VISUELLE_COMBAT, 48.0 + bob)

static func dessiner_ennemi(canvas: CanvasItem, donnees: Dictionary, anim: float,
		etat: String, _direction: Vector2) -> void:
	var index := IDS_ENNEMIS.find(str(donnees.get("id", "encrier_rampant")))
	if index < 0:
		index = 0
	var r := float(donnees.get("rayon", 30.0))
	var facteur: float = float([3.15, 3.55, 2.85, 3.35, 3.05, 3.15, 2.85,
		3.40, 3.35, 3.55, 3.15][index])
	var hauteur: float = r * facteur * Reglages.ECHELLE_VISUELLE_COMBAT
	if etat in ["charger", "gonfler", "pulse"]:
		hauteur *= 1.08 + 0.04 * sin(anim * 18.0)
	var alpha := 0.55 if etat == "phase" else 1.0
	var bob := sin(anim * (5.0 + float(index % 3))) * 3.0
	_sprite_ancre_bas(canvas, PLANCHE_ENNEMIS, RECTS_ENNEMIS[index], hauteur,
		r * 0.82 + bob, Color(1.0, 1.0, 1.0, alpha))

static func dessiner_boss(canvas: CanvasItem, donnees: Dictionary, anim: float,
		phase: int, motif: String) -> void:
	var index := posmod(int(donnees.get("ornement", 0)), 10)
	var miniboss := str(donnees.get("rang_boss", "")) == "miniboss"
	var texture: Texture2D = PLANCHE_MINIBOSS if miniboss else PLANCHE_BOSS
	var source: Rect2 = RECTS_MINIBOSS[index] if miniboss else RECTS_BOSS[index]
	var r := float(donnees.get("rayon", 104.0))
	var hauteur := r * (2.55 if miniboss else 2.90) * Reglages.ECHELLE_VISUELLE_COMBAT
	if motif != "pause":
		hauteur *= 1.0 + 0.025 * sin(anim * 10.0)
	var bob := sin(anim * (3.2 if miniboss else 2.4)) * 4.0
	_sprite_ancre_bas(canvas, texture, source, hauteur, r * 0.68 + bob)
	if phase == 2:
		for eclat in 4:
			var p := Vector2.RIGHT.rotated(anim * 0.9 + eclat * PI * 0.5) * r * 1.30
			canvas.draw_circle(pixel(p), 5.0 + float(eclat % 2) * 3.0,
				Color(ROSE, 0.72))

static func dessiner_projectile(canvas: CanvasItem, trainee: Array[Vector2], position: Vector2,
		couleur: Color, hostile: bool, familier := false) -> void:
	for index in range(trainee.size() - 1, -1, -2):
		var relatif := pixel(trainee[index] - position)
		var taille_trainee := maxf(3.0, 14.0 - float(index))
		canvas.draw_circle(relatif, taille_trainee * (0.62 if familier else 1.0),
			Color(couleur, 0.07 + 0.03 * index))
	var frame := int(Time.get_ticks_msec() / 75) % RECTS_PROJECTILE.size()
	var source: Rect2 = RECTS_PROJECTILE[frame]
	var teinte := couleur.lerp(Color.WHITE, 0.38)
	if hostile:
		teinte = teinte.lerp(ROSE, 0.32)
	var taille := 54.0 if hostile else 58.0
	# Le trait du familier ne vient pas de l'arme du heros : plus petit, plus
	# froid et cercle d'un halo, il se distingue au premier coup d'oeil dans une
	# salle chargee sans changer de planche.
	if familier:
		teinte = teinte.lerp(CYAN, 0.55)
		taille *= 0.66
		canvas.draw_arc(Vector2.ZERO, taille * 0.62, 0.0, TAU, 16,
			Color(CYAN, 0.55), 2.0, true)
	canvas.draw_texture_rect_region(PLANCHE_PROJECTILE,
		Rect2(-taille * 0.5, -taille * 0.5, taille, taille),
		source, teinte, false, true)

static func dessiner_cadre(canvas: CanvasItem, taille: Vector2, anim: float) -> void:
	dessiner_coins(canvas, taille, Color("7e5ab5"))
	var police := ThemeDB.fallback_font
	var pulse := 0.72 + sin(anim * 3.0) * 0.18
	canvas.draw_string(police, Vector2(0.0, taille.y - 24.0),
		"ALAMBIC  ·  GRIMOIRE VIVANT", HORIZONTAL_ALIGNMENT_CENTER,
		taille.x, 18, Color(OR, pulse))
