extends Control

signal terminee

const CHEMIN_SPRITES_HEROS := "res://assets/characters/sheets/hero_alchemist_sheet.png"
const DUREE := 0.95

var _livre := {}
var _texture_heros: Texture2D
var _temps := 0.0
var _terminee := false

func configurer(livre: Dictionary) -> void:
	_livre = livre

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists(CHEMIN_SPRITES_HEROS):
		_texture_heros = load(CHEMIN_SPRITES_HEROS)
	queue_redraw()
	Capture.programmer(self)

func _process(delta: float) -> void:
	_temps += delta
	queue_redraw()
	if not _terminee and _temps >= DUREE:
		_terminee = true
		terminee.emit()

func _draw() -> void:
	var taille := size
	var progression := clampf(_temps / DUREE, 0.0, 1.0)
	for i in 9:
		var part := float(i) / 8.0
		var couleur := Palette.FOND.lerp(Color(0.18, 0.10, 0.30), part)
		draw_rect(Rect2(0.0, taille.y * part, taille.x, taille.y / 8.0 + 2.0), couleur)
	var centre := Vector2(taille.x * 0.5, taille.y * 0.53)
	var ouverture := sin(PI * clampf(progression * 1.25, 0.0, 1.0))
	Dessin.halo(self, centre, 330.0 * (0.65 + ouverture * 0.35), Color(Palette.ESSENCE, 0.72), 8)
	Dessin.halo(self, centre, 220.0, Color(Palette.OR, 0.46), 6)
	for i in 3:
		draw_arc(centre, 150.0 + float(i) * 44.0, -PI * 0.82 + _temps * (0.7 + i * 0.15),
			PI * 0.82 + _temps * (0.7 + i * 0.15), 48, Color(Palette.OR.lerp(Palette.ESSENCE, float(i) / 2.0), 0.72), 4.0, true)
	var position_heros := centre + Vector2(0.0, lerpf(120.0, 18.0, ease(progression, 0.35)))
	_dessiner_heros(position_heros, 0.82 + progression * 0.18)
	var police := ThemeDB.fallback_font
	var nom := str(_livre.get("nom", "GRIMOIRE"))
	draw_string(police, Vector2(0.0, taille.y * 0.18), "OUVERTURE DU GRIMOIRE",
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 42, Palette.TEXTE)
	draw_string(police, Vector2(0.0, taille.y * 0.18 + 62.0), nom.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 31, Palette.OR)
	draw_string(police, Vector2(0.0, taille.y * 0.82), "L’alchimiste entre dans la page…",
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 25, Palette.TEXTE_ATTENUE)

func _dessiner_heros(position: Vector2, echelle: float) -> void:
	if _texture_heros == null:
		Dessin.halo(self, position, 105.0, Color(Palette.HEROS_ACCENT, 0.75), 5)
		draw_colored_polygon(Dessin.goutte(position, 72.0, PI, 1.25), Palette.HEROS_ROBE)
		return
	var cadre := int(_temps * 10.0) % 4
	var cellule := Vector2(_texture_heros.get_width() / 4.0, _texture_heros.get_height() / 2.0)
	var source := Rect2(Vector2(float(cadre) * cellule.x, 0.0), cellule)
	var dimensions := Vector2(178.0, 390.0) * echelle
	var destination := Rect2(position + Vector2(-dimensions.x * 0.5, -dimensions.y * 0.62), dimensions)
	draw_texture_rect_region(_texture_heros, destination, source)
