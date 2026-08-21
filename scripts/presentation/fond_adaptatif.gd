class_name FondAdaptatif
extends RefCounted

const LARGEUR_REFERENCE := 1080.0
const FOND_EXTENSION := preload("res://assets/visual/fond_interface_scriptorium.png")
const FOND_ACCUEIL := preload("res://assets/visual/menu_vallee_alambics.png")

# Les chassis restent intacts. Seule la bande comprise entre les deux coupures
# absorbe la difference de hauteur d'un telephone a l'autre.
static func dessiner(canvas: CanvasItem, texture: Texture2D, taille: Vector2,
		haut_fixe: float, bas_fixe: float, modulation := Color.WHITE) -> void:
	if texture == null or taille.x <= 0.0 or taille.y <= 0.0:
		return
	# L'accueil contient des cadres et ornements peints : etirer sa bande centrale
	# deforme visiblement ces formes sur les telephones tres hauts. On conserve
	# donc les tranches haut/bas a leur echelle native et on laisse un decor
	# recadre remplir l'espace variable entre les deux.
	if texture.resource_path.ends_with("/menu_futur.png"):
		_dessiner_chassis_accueil(canvas, texture, taille, haut_fixe, bas_fixe, modulation)
		return
	var echelle := taille.x / LARGEUR_REFERENCE
	var hauteur_source := float(texture.get_height()) / float(texture.get_width()) * LARGEUR_REFERENCE
	var hauteur_cible := taille.y / echelle
	var milieu_source := maxf(4.0, hauteur_source - haut_fixe - bas_fixe)
	var milieu_cible := maxf(4.0, hauteur_cible - haut_fixe - bas_fixe)
	var facteur_pixels := float(texture.get_height()) / hauteur_source
	var largeur_pixels := float(texture.get_width())
	var haut_pixels := haut_fixe * facteur_pixels
	var bas_pixels := bas_fixe * facteur_pixels
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, 0.0, taille.x, haut_fixe * echelle),
		Rect2(0.0, 0.0, largeur_pixels, haut_pixels), modulation, false, true)
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, haut_fixe * echelle, taille.x, milieu_cible * echelle),
		Rect2(0.0, haut_pixels, largeur_pixels, milieu_source * facteur_pixels),
		modulation, false, true)
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, taille.y - bas_fixe * echelle, taille.x, bas_fixe * echelle),
		Rect2(0.0, float(texture.get_height()) - bas_pixels, largeur_pixels, bas_pixels),
		modulation, false, true)

# Remplit tout l'ecran sans changer le rapport largeur/hauteur de l'image.
# Le surplus est recadre au centre, comme un background-size: cover.
static func dessiner_cover(canvas: CanvasItem, texture: Texture2D, taille: Vector2,
		modulation := Color.WHITE, ancre_y := 0.5) -> void:
	if texture == null or taille.x <= 0.0 or taille.y <= 0.0:
		return
	var source := Vector2(float(texture.get_width()), float(texture.get_height()))
	if source.x <= 0.0 or source.y <= 0.0:
		return
	var echelle := maxf(taille.x / source.x, taille.y / source.y)
	var visible := taille / echelle
	var origine := Vector2(
		(source.x - visible.x) * 0.5,
		(source.y - visible.y) * clampf(ancre_y, 0.0, 1.0))
	canvas.draw_texture_rect_region(texture, Rect2(Vector2.ZERO, taille),
		Rect2(origine, visible), modulation, false, true)

# Cas de l'accueil : le decor peut etre recadre, mais le chassis UI ne doit
# jamais etre etire. Les controles interactifs utilisent la meme transformation
# via y()/point()/rect(), donc ils restent alignes aux tranches peintes.
static func _dessiner_chassis_accueil(canvas: CanvasItem, texture: Texture2D,
		taille: Vector2, haut_fixe: float, bas_fixe: float,
		modulation := Color.WHITE) -> void:
	dessiner_cover(canvas, FOND_ACCUEIL, taille, modulation, 0.46)
	var echelle := taille.x / LARGEUR_REFERENCE
	var hauteur_source := hauteur_reference(texture)
	var facteur_pixels := float(texture.get_height()) / hauteur_source
	var largeur_pixels := float(texture.get_width())
	var haut_reference := minf(haut_fixe, hauteur_source)
	var bas_reference := minf(bas_fixe, maxf(0.0, hauteur_source - haut_reference))
	var haut_pixels := haut_reference * facteur_pixels
	var bas_pixels := bas_reference * facteur_pixels
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, 0.0, taille.x, haut_reference * echelle),
		Rect2(0.0, 0.0, largeur_pixels, haut_pixels), modulation, false, true)
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, taille.y - bas_reference * echelle,
			taille.x, bas_reference * echelle),
		Rect2(0.0, float(texture.get_height()) - bas_pixels,
			largeur_pixels, bas_pixels), modulation, false, true)

# Les anciens fonds premium partagent deja le bon langage de formes. Cette
# correction calme leur or et leur apporte le bleu mineral de l'accueil valide.
static func dessiner_premium(canvas: CanvasItem, texture: Texture2D, taille: Vector2,
		haut_fixe: float, bas_fixe: float, opacite := 1.0) -> void:
	# Un fond continu occupe l'espace gagne sur les ecrans hauts. Les morceaux
	# peints du chassis sont ensuite reposes sans aucune deformation verticale.
	dessiner(canvas, FOND_EXTENSION, taille, 620.0, 520.0,
		Color(0.88, 0.97, 1.0, opacite))
	var echelle := taille.x / LARGEUR_REFERENCE
	var hauteur_source := hauteur_reference(texture)
	var facteur_pixels := float(texture.get_height()) / hauteur_source
	var largeur_pixels := float(texture.get_width())
	var haut_pixels := minf(haut_fixe, hauteur_source) * facteur_pixels
	var bas_pixels := minf(bas_fixe, hauteur_source) * facteur_pixels
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, 0.0, taille.x, haut_fixe * echelle),
		Rect2(0.0, 0.0, largeur_pixels, haut_pixels),
		Color(0.92, 0.97, 1.0, opacite), false, true)
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, taille.y - bas_fixe * echelle, taille.x, bas_fixe * echelle),
		Rect2(0.0, float(texture.get_height()) - bas_pixels, largeur_pixels, bas_pixels),
		Color(0.92, 0.97, 1.0, opacite), false, true)
	canvas.draw_rect(Rect2(Vector2.ZERO, taille), Color(0.035, 0.22, 0.30, 0.055 * opacite))

static func hauteur_reference(texture: Texture2D) -> float:
	return float(texture.get_height()) / float(texture.get_width()) * LARGEUR_REFERENCE

static func y(taille: Vector2, texture: Texture2D, valeur: float,
		haut_fixe: float, bas_fixe: float) -> float:
	var echelle := taille.x / LARGEUR_REFERENCE
	var hauteur_source := hauteur_reference(texture)
	var hauteur_cible := taille.y / echelle
	if valeur <= haut_fixe:
		return valeur * echelle
	if valeur >= hauteur_source - bas_fixe:
		return (hauteur_cible - (hauteur_source - valeur)) * echelle
	var milieu_source := maxf(4.0, hauteur_source - haut_fixe - bas_fixe)
	var milieu_cible := maxf(4.0, hauteur_cible - haut_fixe - bas_fixe)
	return (haut_fixe + (valeur - haut_fixe) * milieu_cible / milieu_source) * echelle

static func point(taille: Vector2, texture: Texture2D, valeur: Vector2,
		haut_fixe: float, bas_fixe: float) -> Vector2:
	return Vector2(valeur.x * taille.x / LARGEUR_REFERENCE,
		y(taille, texture, valeur.y, haut_fixe, bas_fixe))

static func rect(taille: Vector2, texture: Texture2D, valeur: Rect2,
		haut_fixe: float, bas_fixe: float) -> Rect2:
	var debut := point(taille, texture, valeur.position, haut_fixe, bas_fixe)
	var fin := point(taille, texture, valeur.end, haut_fixe, bas_fixe)
	return Rect2(debut, fin - debut)
