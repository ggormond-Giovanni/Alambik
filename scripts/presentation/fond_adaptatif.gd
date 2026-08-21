class_name FondAdaptatif
extends RefCounted

const LARGEUR_REFERENCE := 1080.0
const FOND_EXTENSION := preload("res://assets/visual/fond_interface_scriptorium.png")
const FOND_ACCUEIL := preload("res://assets/visual/menu_vallee_alambics.png")

# Réservé aux terrains dont une bande centrale peut réellement être étirée.
# Les interfaces n'utilisent plus ce comportement.
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

# Équivalent de background-size: cover : rapport largeur/hauteur toujours intact.
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

# Écrans premium en cours de migration :
# - décor continu indépendant sur tout le téléphone ;
# - ancienne maquette conservée entière et sans déformation ;
# - fondu sur ses limites pour ne jamais voir une coupure franche ;
# - vrais Controls Godot au-dessus.
# Les pages déjà migrées (accueil, pause, réglages) n'ont plus besoin de cette
# maquette, mais les autres restent parfaitement utilisables pendant la refonte.
static func dessiner_premium(canvas: CanvasItem, texture: Texture2D, taille: Vector2,
		_haut_fixe: float, _bas_fixe: float, opacite := 1.0) -> void:
	if taille.x <= 0.0 or taille.y <= 0.0:
		return
	dessiner_cover(canvas, FOND_EXTENSION, taille,
		Color(0.94, 0.98, 1.0, opacite), 0.50)
	canvas.draw_rect(Rect2(Vector2.ZERO, taille), Color(0.018, 0.045, 0.110, 0.16 * opacite))
	if texture != null:
		_dessiner_maquette_fondue(canvas, texture, taille, opacite)
	canvas.draw_rect(Rect2(18.0, 18.0, maxf(0.0, taille.x - 36.0), maxf(0.0, taille.y - 36.0)),
		Color(Palette.BORD_PAGE, 0.18 * opacite), false, 2.0)

static func _dessiner_maquette_fondue(canvas: CanvasItem, texture: Texture2D,
		taille: Vector2, opacite: float) -> void:
	var echelle := taille.x / LARGEUR_REFERENCE
	var hauteur_ref := hauteur_reference(texture)
	var hauteur_dst := hauteur_ref * echelle
	var origine_y := (taille.y - hauteur_dst) * 0.5
	var facteur_pixels := float(texture.get_height()) / maxf(1.0, hauteur_ref)
	var largeur_pixels := float(texture.get_width())
	var fondu_ref := minf(120.0, hauteur_ref * 0.10)
	var centre_debut := fondu_ref
	var centre_fin := hauteur_ref - fondu_ref
	# Centre intact : les textes/ornements de transition restent lisibles.
	if centre_fin > centre_debut:
		canvas.draw_texture_rect_region(texture,
			Rect2(0.0, origine_y + centre_debut * echelle,
				taille.x, (centre_fin - centre_debut) * echelle),
			Rect2(0.0, centre_debut * facteur_pixels, largeur_pixels,
				(centre_fin - centre_debut) * facteur_pixels),
			Color(1.0, 1.0, 1.0, 0.92 * opacite), false, true)
	var bandes := 8
	for i in bandes:
		var t0 := float(i) / float(bandes)
		var t1 := float(i + 1) / float(bandes)
		var ref_h := fondu_ref * (t1 - t0)
		var alpha_haut := lerpf(0.0, 0.92, t1) * opacite
		canvas.draw_texture_rect_region(texture,
			Rect2(0.0, origine_y + fondu_ref * t0 * echelle, taille.x, ref_h * echelle + 1.0),
			Rect2(0.0, fondu_ref * t0 * facteur_pixels, largeur_pixels, ref_h * facteur_pixels + 1.0),
			Color(1.0, 1.0, 1.0, alpha_haut), false, true)
		var bas_ref_y := hauteur_ref - fondu_ref + fondu_ref * t0
		var alpha_bas := lerpf(0.92, 0.0, t1) * opacite
		canvas.draw_texture_rect_region(texture,
			Rect2(0.0, origine_y + bas_ref_y * echelle, taille.x, ref_h * echelle + 1.0),
			Rect2(0.0, bas_ref_y * facteur_pixels, largeur_pixels, ref_h * facteur_pixels + 1.0),
			Color(1.0, 1.0, 1.0, alpha_bas), false, true)

static func hauteur_reference(texture: Texture2D) -> float:
	if texture == null or texture.get_width() <= 0:
		return 1920.0
	return float(texture.get_height()) / float(texture.get_width()) * LARGEUR_REFERENCE

# Les anciennes zones tactiles suivent désormais exactement la maquette intacte
# centrée. Aucun bitmap n'est étiré et aucune hitbox ne dérive avec le ratio.
static func y(taille: Vector2, texture: Texture2D, valeur: float,
		_haut_fixe: float, _bas_fixe: float) -> float:
	var echelle := taille.x / LARGEUR_REFERENCE
	var hauteur_dst := hauteur_reference(texture) * echelle
	var origine_y := (taille.y - hauteur_dst) * 0.5
	return origine_y + valeur * echelle

static func point(taille: Vector2, texture: Texture2D, valeur: Vector2,
		haut_fixe: float, bas_fixe: float) -> Vector2:
	return Vector2(valeur.x * taille.x / LARGEUR_REFERENCE,
		y(taille, texture, valeur.y, haut_fixe, bas_fixe))

static func rect(taille: Vector2, texture: Texture2D, valeur: Rect2,
		haut_fixe: float, bas_fixe: float) -> Rect2:
	var debut := point(taille, texture, valeur.position, haut_fixe, bas_fixe)
	var fin := point(taille, texture, valeur.end, haut_fixe, bas_fixe)
	return Rect2(debut, fin - debut)
