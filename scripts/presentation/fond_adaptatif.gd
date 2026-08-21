class_name FondAdaptatif
extends RefCounted

const LARGEUR_REFERENCE := 1080.0
const FOND_EXTENSION := preload("res://assets/visual/fond_interface_scriptorium.png")
const FOND_ACCUEIL := preload("res://assets/visual/menu_vallee_alambics.png")

# Utilise uniquement pour les terrains dont une zone centrale est volontairement
# extensible. Les interfaces ne passent plus par cette méthode : un élément UI
# ne doit jamais être déformé pour remplir un téléphone plus haut.
static func dessiner(canvas: CanvasItem, texture: Texture2D, taille: Vector2,
		haut_fixe: float, bas_fixe: float, modulation := Color.WHITE) -> void:
	if texture == null or taille.x <= 0.0 or taille.y <= 0.0:
		return
	var echelle := taille.x / LARGEUR_REFERENCE
	var hauteur_source := hauteur_reference(texture)
	var hauteur_cible := taille.y / echelle
	var milieu_source := maxf(4.0, hauteur_source - haut_fixe - bas_fixe)
	var milieu_cible := maxf(4.0, hauteur_cible - haut_fixe - bas_fixe)
	var facteur_pixels := float(texture.get_height()) / hauteur_source
	var largeur_pixels := float(texture.get_width())
	var haut_pixels := minf(haut_fixe, hauteur_source) * facteur_pixels
	var bas_pixels := minf(bas_fixe, hauteur_source) * facteur_pixels
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, 0.0, taille.x, haut_fixe * echelle),
		Rect2(0.0, 0.0, largeur_pixels, haut_pixels), modulation, false, true)
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, haut_fixe * echelle, taille.x, milieu_cible * echelle),
		Rect2(0.0, haut_pixels, largeur_pixels,
			maxf(1.0, float(texture.get_height()) - haut_pixels - bas_pixels)),
		modulation, false, true)
	canvas.draw_texture_rect_region(texture,
		Rect2(0.0, taille.y - bas_fixe * echelle, taille.x, bas_fixe * echelle),
		Rect2(0.0, float(texture.get_height()) - bas_pixels, largeur_pixels, bas_pixels),
		modulation, false, true)

# Équivalent d'un background-size: cover : aucun étirement anisotrope, donc une
# peinture garde toujours ses proportions. Seul le surplus est recadré.
static func dessiner_cover(canvas: CanvasItem, texture: Texture2D, taille: Vector2,
		modulation := Color.WHITE, ancre_y := 0.5) -> void:
	if texture == null or taille.x <= 0.0 or taille.y <= 0.0:
		return
	var source := Vector2(float(texture.get_width()), float(texture.get_height()))
	if source.x <= 0.0 or source.y <= 0.0:
		return
	var echelle := maxf(taille.x / source.x, taille.y / source.y)
	var visible := taille / echelle
	visible.x = minf(visible.x, source.x)
	visible.y = minf(visible.y, source.y)
	var origine := Vector2((source.x - visible.x) * 0.5,
		(source.y - visible.y) * clampf(ancre_y, 0.0, 1.0))
	canvas.draw_texture_rect_region(texture, Rect2(Vector2.ZERO, taille),
		Rect2(origine, visible), modulation, false, true)

# Les écrans secondaires sont désormais composés en couches :
# 1. un décor continu commun ;
# 2. seulement des fragments décoratifs de l'ancienne maquette, fondus dans le
#    décor et jamais étirés ;
# 3. les vrais Control Godot dessinés par l'écran au-dessus.
# Cela supprime la couture franche et conserve les anciennes pages pendant leur
# migration vers des composants 100 % indépendants.
static func dessiner_premium(canvas: CanvasItem, texture: Texture2D, taille: Vector2,
		haut_fixe: float, bas_fixe: float, opacite := 1.0) -> void:
	if taille.x <= 0.0 or taille.y <= 0.0:
		return
	dessiner_cover(canvas, FOND_EXTENSION, taille,
		Color(0.93, 0.98, 1.0, opacite), 0.50)
	canvas.draw_rect(Rect2(Vector2.ZERO, taille),
		Color(0.020, 0.050, 0.120, 0.22 * opacite))
	if texture != null:
		_dessiner_ornements_fondus(canvas, texture, taille, haut_fixe, bas_fixe, opacite)
	# Les bords appartiennent à la couche décorative, pas à l'image de fond.
	canvas.draw_rect(Rect2(18.0, 18.0, maxf(0.0, taille.x - 36.0), maxf(0.0, taille.y - 36.0)),
		Color(Palette.BORD_PAGE, 0.20 * opacite), false, 2.0)

static func _dessiner_ornements_fondus(canvas: CanvasItem, texture: Texture2D,
		taille: Vector2, haut_fixe: float, bas_fixe: float, opacite: float) -> void:
	var echelle := taille.x / LARGEUR_REFERENCE
	var hauteur_source := hauteur_reference(texture)
	var facteur_pixels := float(texture.get_height()) / maxf(1.0, hauteur_source)
	var largeur_pixels := float(texture.get_width())
	var haut := minf(haut_fixe, hauteur_source * 0.42)
	var bas := minf(bas_fixe, hauteur_source * 0.30)
	# Huit bandes dont l'alpha décroît vers le centre rendent la transition
	# imperceptible même quand la peinture source n'a pas exactement la même teinte.
	var bandes := 8
	if haut > 4.0:
		for i in bandes:
			var t0 := float(i) / float(bandes)
			var t1 := float(i + 1) / float(bandes)
			var src_y := haut * t0 * facteur_pixels
			var src_h := haut * (t1 - t0) * facteur_pixels + 1.0
			var dst_y := haut * t0 * echelle
			var dst_h := haut * (t1 - t0) * echelle + 1.0
			var alpha := lerpf(0.34, 0.0, t0) * opacite
			canvas.draw_texture_rect_region(texture,
				Rect2(0.0, dst_y, taille.x, dst_h),
				Rect2(0.0, src_y, largeur_pixels, src_h),
				Color(0.94, 0.98, 1.0, alpha), false, true)
	if bas > 4.0:
		for i in bandes:
			var t0 := float(i) / float(bandes)
			var t1 := float(i + 1) / float(bandes)
			var distance_bas := bas * t1
			var src_y := (hauteur_source - distance_bas) * facteur_pixels
			var src_h := bas * (t1 - t0) * facteur_pixels + 1.0
			var dst_y := taille.y - distance_bas * echelle
			var dst_h := bas * (t1 - t0) * echelle + 1.0
			var alpha := lerpf(0.0, 0.34, t1) * opacite
			canvas.draw_texture_rect_region(texture,
				Rect2(0.0, dst_y, taille.x, dst_h),
				Rect2(0.0, src_y, largeur_pixels, src_h),
				Color(0.94, 0.98, 1.0, alpha), false, true)

static func hauteur_reference(texture: Texture2D) -> float:
	if texture == null or texture.get_width() <= 0:
		return 1920.0
	return float(texture.get_height()) / float(texture.get_width()) * LARGEUR_REFERENCE

# Compatibilité avec les anciens écrans encore repérés sur leur maquette. Cette
# transformation ne déforme aucun bitmap : elle sert uniquement à replacer les
# zones tactiles jusqu'à ce que chaque page ait fini sa migration vers Containers.
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
