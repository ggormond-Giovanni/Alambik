class_name FondAdaptatif
extends RefCounted

const LARGEUR_REFERENCE := 1080.0
const FOND_EXTENSION := preload("res://assets/visual/fond_interface_scriptorium.png")

# Les chassis restent intacts. Seule la bande comprise entre les deux coupures
# absorbe la difference de hauteur d'un telephone a l'autre.
static func dessiner(canvas: CanvasItem, texture: Texture2D, taille: Vector2,
		haut_fixe: float, bas_fixe: float, modulation := Color.WHITE) -> void:
	if texture == null or taille.x <= 0.0 or taille.y <= 0.0:
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
